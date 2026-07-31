"""无需运行 Web 服务的可执行业务示例：自由写 → 可选自问 → 可选收束。

python scripts/demo_review_flow.py
"""

from __future__ import annotations

from datetime import date
from pathlib import Path
import sys

# 允许从项目根目录直接运行 `python scripts/demo_review_flow.py`。
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.database import Base
from app.llm.providers import ChatMessage
from app.services.review_service import (
    FREE_WRITE_QUESTION,
    answer_followup,
    create_session_if_needed,
    save_answers,
    start_followup,
    summarize_session,
)


class DemoProvider:
    def chat(self, messages: list[ChatMessage]) -> str:
        system = next((item["content"] for item in messages if item["role"] == "system"), "")
        if "把今晚没说清的话问回自己" in system:
            return "你说『搭好了项目骨架』——明天要验证的第一个可运行路径是什么？"
        return (
            '{"overview":"完成了演示夜记骨架",'
            '"attribution":"容易停在搭架子，缺少可验证的下一步",'
            '"next_action":"明天跑通一次提交并完成可选自问流程并截图",'
            '"lesson":"骨架完成不等于价值交付，要立刻接上可验证动作"}'
        )


def main() -> None:
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    db: Session = sessionmaker(bind=engine)()
    provider = DemoProvider()
    session = create_session_if_needed(db, date.today(), provider)
    assert session.qas[0].question == FREE_WRITE_QUESTION
    session = save_answers(db, session, {session.qas[0].id: "搭好了项目骨架"})
    session = start_followup(db, session, provider)
    pending = next(qa for qa in session.qas if qa.qa_type == "followup")
    session = answer_followup(db, session, pending.id, "先把自问接口用 FakeProvider 跑通")
    session = summarize_session(db, session, provider, skip=False)
    print(session.summary.raw_markdown if session.summary else "未生成收束")


if __name__ == "__main__":
    main()
