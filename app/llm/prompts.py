"""自问 / 收束 / 周场 Prompt 组装。业务层只取消息列表，不内联长文案。"""

from __future__ import annotations

from app.llm.providers import ChatMessage

MAX_FOLLOWUP_ROUNDS = 2

FOLLOWUP_SYSTEM = """你在帮用户把今晚没说清的话问回自己，不是教练课，不是总结。
用户刚写下今晚的自由记录（不是答题卷）。任务：只挑【一个】最值得问回自己的点，提一个短问题。

挑选优先级：
1. 最含糊、最像正确废话（如「继续推进」「多做测试」——无具体动作）。
2. 明确卡住/焦虑/没做成，但没说清卡在哪或自己怎么看。
3. 问法往「具体是什么」或「你此刻真实感受/顾虑是什么」；不开新话题。

要求：只输出一个问题；可轻带用户原词；语气像夜里对自己说话——直接、短、不说教、不灌鸡汤、不审讯；不做总结、不给建议。
输出：仅问题一句，无前缀无客套。"""

REVIEW_SYSTEM = """用户今晚已自由写过，也可能刚答过一句自问。生成短【收束】，非流水账、非训话。
只返回 JSON，键严格为 overview、attribution、next_action、lesson：
- overview：1-2 句今晚最要紧的事实。
- attribution：若有卡住，区分认知未定/决策没做/行动没开始；信息不足则写「今晚说得不多，先不硬猜」。
- next_action：一个【30 分钟内可启动】的具体动作（动词+可检查结果）；禁止「继续推进X」。
- lesson：一句像他自己留下的话；不名人名言。
语气私密具体，禁止「你应该」。不要 Markdown 代码块或其它键。"""

# 旧周报四键主路径已停用；勿再作为 close 主路径。
WEEK_REVIEW_SYSTEM = """（已停用）旧周报式收周 prompt，勿再作为主路径。"""

WEEK_FOLLOWUP_SYSTEM = """你在帮用户做每周一次的「和自己谈谈」：私密、短、清醒。不是周报作者，不是考官，不是犀利教练。
根据【近七日痕迹】、【可选提纲（可空）】和【上周信号（可空）】，只产出【一个】值得坐下来回答的问题。

目的：打捞【当时】对要事的感受与分量（事后极难回忆），并让这句回答能用来校正方向、少走弯路。

选点优先级：
1. 这周占心力的具体事/项目/卡住（如某个 App、发布、副业、某次配置）。
2. 问「这件事与他自身的关系」：感受、分量、期待还是负担、想靠近还是想逃——不要进度汇报，不要「做了什么」清单题。
3. 有效日痕迹很少（如不足 3 天）：问题更轻更窄，承认材料有限；禁止硬造「反复主题」。
4. 若用户已写出明确感受，则加深一层，不重复结论。
5. 若有上周信号，优先承接「分量有没有变化」或「上周留下的下一步现在还成立吗」，不要做完成/未完成对账。

要求：只输出一个问题；点名痕迹里的具体事；语气温柔、具体、不咄咄逼人、不说教、不给答案。
禁止：周总结、复盘列表、「你应该」、鸡汤、一次问两件事。
输出：仅问题本身，无前缀无客套。"""

WEEK_TOPICS_SYSTEM = """你在帮用户为每周一次的自我校准挑选谈话主题。
根据近七日痕迹和有限的上周信号，提炼 2～3 个用户可能真正想谈的具体线程。
主题不是问题，不是总结，也不是任务清单；可以是一个项目、一件选择、一次卡住或一种反复出现的分量。
优先保留用户原话，避免心理诊断、宏大人生结论和凭空补全。
只返回 JSON 字符串数组，例如：["准备发布的小 App", "想继续还是停下"]。
不要 Markdown 代码块，不要其它文字。"""

WEEK_CLOSE_SYSTEM = """用户刚回答了本周那一个周问。做极短收束，不要重写一篇周总结。
只返回 JSON，键严格为 echo、next_focus、note：
- echo：1-2 句如实反映他刚才的回答（可点出感受），不评价、不借机摘要整周流水。
- next_focus：若回答里已露出方向/下一步，收成【一件】可动手的事；若没有，写「本周先不硬定下一件」——禁止替他发明宏大计划。
- note：一句留给自己的话，短，像他自己写的。
禁止鸡汤、禁止「你应该」、禁止整周做了什么的清单体。不要 Markdown 代码块或其它键。"""


def build_followup_messages(
    *,
    fixed_qa_lines: list[str],
    prior_followups: list[tuple[str, str]],
    round_number: int,
) -> list[ChatMessage]:
    parts = ["【今晚写下的】", *fixed_qa_lines]
    if prior_followups:
        parts.append("\n【已进行的自问】")
        for index, (question, answer) in enumerate(prior_followups, 1):
            parts.append(f"第{index}轮问：{question}")
            parts.append(f"第{index}轮答：{answer}")
        parts.append(f"\n请基于以上内容生成第 {round_number} 轮问自己一句（仍只问一个问题）。")
    else:
        parts.append(f"\n请生成第 {round_number} 轮问自己一句（仍只问一个问题）。")
    return [
        {"role": "system", "content": FOLLOWUP_SYSTEM},
        {"role": "user", "content": "\n".join(parts)},
    ]


def build_review_messages(
    *,
    fixed_qa_lines: list[str],
    answered_followups: list[tuple[int, str, str]],
    skipped: bool,
    skip_note: str,
) -> list[ChatMessage]:
    parts = ["【今晚写下的】", *fixed_qa_lines]
    if answered_followups:
        parts.append("\n【自问问答】")
        for round_no, question, answer in answered_followups:
            parts.append(f"第{round_no}轮问：{question}")
            parts.append(f"第{round_no}轮答：{answer}")
    if skipped:
        parts.append(f"\n用户本次跳过了自问。{skip_note}".rstrip())
    return [
        {"role": "system", "content": REVIEW_SYSTEM},
        {"role": "user", "content": "\n".join(parts)},
    ]


def build_week_followup_messages(
    *,
    week_start: str,
    week_end: str,
    outline_lines: list[str],
    traces: str,
    trace_days: int,
    prior_signal: str = "",
    bootstrap_topic: str = "",
    selected_topic: str = "",
    followup_emotion: str = "",
) -> list[ChatMessage]:
    parts = [
        f"【周区间】{week_start} 至 {week_end}，有痕迹 {trace_days} 天。",
        "【近七日痕迹】",
        traces.strip() or "（几乎没有日痕迹）",
        "\n【可选提纲（可空）】",
        *(outline_lines or ["（未写提纲）"]),
        "\n【上周信号（可空）】",
        prior_signal.strip() or "（没有上周可承接内容）",
        "\n【起步模式（可空）】",
        bootstrap_topic.strip() or "（不是起步模式）",
        "\n【用户选定的谈话主题】",
        selected_topic.strip() or "（尚未选择，需从痕迹中挑一件）",
        "\n【用户此刻可选的情绪】",
        followup_emotion.strip() or "（未选择）",
        "\n请只输出一个温柔的周问。",
    ]
    return [
        {"role": "system", "content": WEEK_FOLLOWUP_SYSTEM},
        {"role": "user", "content": "\n".join(parts)},
    ]


def build_week_topics_messages(
    *,
    week_start: str,
    week_end: str,
    traces: str,
    trace_days: int,
    prior_signal: str = "",
    bootstrap_topic: str = "",
) -> list[ChatMessage]:
    parts = [
        f"【周区间】{week_start} 至 {week_end}，有痕迹 {trace_days} 天。",
        "【近七日痕迹】",
        traces.strip() or "（几乎没有日痕迹）",
        "\n【上周信号（可空）】",
        prior_signal.strip() or "（没有上周可承接内容）",
        "\n【起步主题（可空）】",
        bootstrap_topic.strip() or "（不是起步模式）",
        "\n请只返回 2～3 个具体谈话主题的 JSON 字符串数组。",
    ]
    return [
        {"role": "system", "content": WEEK_TOPICS_SYSTEM},
        {"role": "user", "content": "\n".join(parts)},
    ]


def build_week_close_messages(
    *,
    week_start: str,
    week_end: str,
    followup_question: str,
    followup_answer: str,
    traces: str,
    trace_days: int,
    selected_topic: str = "",
    followup_emotion: str = "",
) -> list[ChatMessage]:
    parts = [
        f"【周区间】{week_start} 至 {week_end}，有痕迹 {trace_days} 天。",
        f"【选定主题】{selected_topic.strip() or '（未选择）'}",
        f"【周场情绪】{followup_emotion.strip() or '（未选择）'}",
        f"【本周问句】{followup_question.strip() or '（无）'}",
        f"【我的回答】{followup_answer.strip() or '（未写）'}",
        "\n【近七日痕迹（仅供参考，勿据此重写周流水）】",
        traces.strip() or "（几乎没有日痕迹）",
        "\n请返回 echo / next_focus / note 的 JSON。",
    ]
    return [
        {"role": "system", "content": WEEK_CLOSE_SYSTEM},
        {"role": "user", "content": "\n".join(parts)},
    ]


def build_week_review_messages(
    *,
    week_start: str,
    week_end: str,
    outline_lines: list[str],
    traces: str,
    trace_days: int,
) -> list[ChatMessage]:
    """兼容旧调用名；已不再作为周场主路径。"""
    return build_week_followup_messages(
        week_start=week_start,
        week_end=week_end,
        outline_lines=outline_lines,
        traces=traces,
        trace_days=trace_days,
    )
