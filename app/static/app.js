function localDateText(value = new Date()) {
  const year = value.getFullYear();
  const month = String(value.getMonth() + 1).padStart(2, "0");
  const day = String(value.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

const state = {
  today: localDateText(),
  current: new Date(),
  session: null,
  selectedArchiveDay: null,
  nightDraft: "",
  nightEmotion: "",
  weekLoaded: false,
  week: null,
};
const $ = (selector) => document.querySelector(selector);
const EMOTIONS = ["轻松", "期待", "犹豫", "负担", "烦躁", "想靠近", "想逃开", "说不清"];
const REMINDER_KEY = "night-weekly-reminder";
const AUTH_TOKEN_KEY = "night-api-token";

function renderEmotionPicker(selector, current, onChange, disabled = false) {
  const picker = $(selector);
  if (!picker) return;
  picker.replaceChildren(
    ...EMOTIONS.map((emotion) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "emotion-choice" + (emotion === current ? " is-selected" : "");
      button.textContent = emotion;
      button.setAttribute("aria-pressed", emotion === current ? "true" : "false");
      button.disabled = disabled;
      button.onclick = () => onChange(emotion);
      return button;
    })
  );
}

function updateEmotionCaption(selector, value, emptyText = "不选也可以") {
  const target = $(selector);
  if (target) target.textContent = value || emptyText;
}

function readWeeklyReminder() {
  try {
    return {
      enabled: false,
      time: "20:00",
      lastWeek: "",
      ...JSON.parse(localStorage.getItem(REMINDER_KEY) || "{}"),
    };
  } catch (_) {
    return { enabled: false, time: "20:00", lastWeek: "" };
  }
}

function writeWeeklyReminder(settings) {
  localStorage.setItem(REMINDER_KEY, JSON.stringify(settings));
}

function reminderWeekKey(value = new Date()) {
  return localDateText(startOfWeek(value));
}

function checkWeeklyReminder() {
  const settings = readWeeklyReminder();
  if (!settings.enabled) return;
  const now = new Date();
  if (![0, 1].includes(now.getDay())) return;
  const [hour, minute] = String(settings.time || "20:00").split(":").map(Number);
  if (now.getHours() < hour || (now.getHours() === hour && now.getMinutes() < minute)) return;
  const weekKey = reminderWeekKey(now);
  if (settings.lastWeek === weekKey) return;
  settings.lastWeek = weekKey;
  writeWeeklyReminder(settings);
  const message = "周日 / 周一推荐看一眼本周。没有截止时间，想晚一点也可以。";
  if ("Notification" in window && Notification.permission === "granted") {
    new Notification("夜记", { body: message });
  }
  const reminderMessage = $("#reminder-message");
  if (reminderMessage) reminderMessage.textContent = message;
}

function loadWeeklyReminder() {
  const settings = readWeeklyReminder();
  $("#weekly-reminder-enabled").checked = Boolean(settings.enabled);
  $("#weekly-reminder-time").value = settings.time || "20:00";
  checkWeeklyReminder();
}

async function saveWeeklyReminder() {
  const enabled = $("#weekly-reminder-enabled").checked;
  const time = $("#weekly-reminder-time").value || "20:00";
  if (enabled && "Notification" in window && Notification.permission === "default") {
    await Notification.requestPermission();
  }
  const previous = readWeeklyReminder();
  writeWeeklyReminder({ enabled, time, lastWeek: previous.lastWeek || "" });
  $("#reminder-message").textContent = enabled
    ? "已保存。每周最多提醒一次，错过也不用补。"
    : "提醒已关闭。";
}

function formatApiError(detail, fallback = "请求失败，请稍后重试。") {
  if (!detail) return fallback;
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail)) {
    return detail.map((item) => item.msg || JSON.stringify(item)).join("；") || fallback;
  }
  if (typeof detail === "object" && detail.msg) return detail.msg;
  return fallback;
}

async function api(path, options = {}) {
  let token = sessionStorage.getItem(AUTH_TOKEN_KEY);
  if (!token && path !== "/bootstrap-token") {
    const bootstrap = await fetch("/api/bootstrap-token", { cache: "no-store" });
    const bootstrapBody = await bootstrap.json().catch(() => ({}));
    if (!bootstrap.ok || !bootstrapBody.token) {
      throw new Error("本机访问令牌不可用。请使用初次打开夜记的浏览器会话。")
    }
    token = bootstrapBody.token;
    sessionStorage.setItem(AUTH_TOKEN_KEY, token);
  }
  const headers = new Headers(options.headers || {});
  headers.set("Content-Type", "application/json");
  if (token) headers.set("Authorization", `Bearer ${token}`);
  const response = await fetch(`/api${path}`, { ...options, headers });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(formatApiError(body.detail));
  return body;
}

function showNotice(message) {
  const box = $("#tonight-notice");
  if (!box) return;
  box.textContent = message;
  box.classList.remove("hidden");
}
function clearNotice() {
  $("#tonight-notice")?.classList.add("hidden");
}
function setLoadingRail(on) {
  $("#loading-rail")?.classList.toggle("hidden", !on);
}

function fixedQas(session) {
  return (session?.qas || []).filter((qa) => (qa.qa_type || "fixed") === "fixed");
}
function followupQas(session) {
  return (session?.qas || [])
    .filter((qa) => qa.qa_type === "followup")
    .sort((a, b) => a.round - b.round);
}
function pendingFollowup(session) {
  return followupQas(session).find((qa) => !String(qa.answer || "").trim()) || null;
}

function statusLabel(status) {
  if (status === "summarized") return "已收好";
  if (status === "following_up") return "问自己中";
  if (status === "answered") return "已写下";
  return "正在写";
}

function formatKicker(dateText, status) {
  const [year, month, day] = String(dateText).split("-").map(Number);
  if (!year) return statusLabel(status);
  return `${year}年${month}月${day}日 · ${statusLabel(status)}`;
}

function padFromSession(session) {
  const items = fixedQas(session);
  if (!items.length) return "";
  const first = String(items[0].answer || "").trim();
  if (first) return first;
  // 兼容旧「四问」会话：拼成一段轻记
  return items
    .map((qa) => String(qa.answer || "").trim())
    .filter(Boolean)
    .join("\n\n");
}

function hasNightText(session, draft = state.nightDraft) {
  if (String(draft || "").trim()) return true;
  return fixedQas(session).some((qa) => String(qa.answer || "").trim());
}

function summarySections(summary) {
  if (!summary) return [];
  if (summary.attribution || summary.next_action || summary.lesson) {
    return [
      ["今晚概要", summary.overview, ""],
      ["怎么回事", summary.attribution, ""],
      ["下一步", summary.next_action, ""],
      ["留给明天的一句话", summary.lesson, "lesson"],
    ];
  }
  return [
    ["今晚概要", summary.overview, ""],
    ["学到的", summary.learnings, ""],
    ["卡住的地方", summary.blockers, ""],
    ["明天想做的", summary.next_plan, ""],
  ];
}

function buildSummaryNodes(summary) {
  return summarySections(summary).map(([title, content, extra]) => {
    const section = document.createElement("div");
    section.className = "summary-section" + (extra ? ` ${extra}` : "");
    const h = document.createElement("h3");
    h.textContent = title;
    const p = document.createElement("div");
    p.textContent = content || "";
    section.append(h, p);
    return section;
  });
}

function renderSummary(target, summary) {
  if (!summary) {
    target.classList.add("hidden");
    target.replaceChildren();
    return;
  }
  target.replaceChildren(...buildSummaryNodes(summary));
  target.classList.remove("hidden");
}

function collectAnswersPayload() {
  const items = fixedQas(state.session);
  const text = String(state.nightDraft || "").trim();
  if (!items.length) return [];
  // 自由写写入「今晚正文」（或旧会话首条）；旧多题会话其余题原样保留
  return items.map((qa, index) => ({
    qa_id: qa.id,
    answer: index === 0 ? text : qa.answer || "",
  }));
}

function appendLegacyNightNodes(container, session) {
  const items = fixedQas(session).filter((qa) => String(qa.answer || "").trim());
  const emotion = String(session?.emotion || "").trim();
  if (emotion) {
    const section = document.createElement("div");
    section.className = "summary-section";
    const h = document.createElement("h3");
    h.textContent = "当时的分量";
    const text = document.createElement("div");
    text.textContent = emotion;
    section.append(h, text);
    container.append(section);
  }
  if (!items.length) {
    const p = document.createElement("p");
    p.className = "muted";
    p.textContent = emotion ? "只留下了一个情绪，没有触发 AI。" : "写下过，还没收一收。";
    container.append(p);
    return;
  }
  if (items.length === 1) {
    const section = document.createElement("div");
    section.className = "summary-section";
    const h = document.createElement("h3");
    h.textContent = "当晚写下的";
    const text = document.createElement("div");
    text.textContent = items[0].answer;
    section.append(h, text);
    container.append(section);
    return;
  }
  // 旧四问废案数据：逐条可读，不再当主路径
  items.forEach((qa) => {
    const section = document.createElement("div");
    section.className = "summary-section";
    const h = document.createElement("h3");
    h.textContent = qa.question || "当晚写下的";
    const text = document.createElement("div");
    text.textContent = qa.answer;
    section.append(h, text);
    container.append(section);
  });
}

async function withLoading(buttonOrNull, loadingText, work) {
  const previous = buttonOrNull ? buttonOrNull.textContent : "";
  if (buttonOrNull) {
    buttonOrNull.disabled = true;
    buttonOrNull.textContent = loadingText;
  }
  setLoadingRail(true);
  showNotice(loadingText);
  try {
    return await work();
  } finally {
    setLoadingRail(false);
    if (buttonOrNull) {
      buttonOrNull.disabled = false;
      buttonOrNull.textContent = previous;
    }
  }
}

function renderTonight(session) {
  state.session = session;
  state.nightEmotion = session.emotion || "";
  clearNotice();
  $("#tonight-kicker").textContent = formatKicker(session.date, session.status);

  const writing = session.status === "pending" || session.status === "answered";
  const asking = session.status === "following_up";
  const done = session.status === "summarized";

  const pad = $("#night-pad");
  const writeBlock = $("#tonight-write");
  const askPanel = $("#ask-panel");
  const doneBlock = $("#tonight-done");

  if (writing || asking) {
    writeBlock.classList.remove("hidden");
    if (!state.nightDraft) state.nightDraft = padFromSession(session);
    pad.value = state.nightDraft;
    pad.disabled = asking || done;
    renderEmotionPicker(
      "#tonight-emotions",
      state.nightEmotion,
      (emotion) => {
        state.nightEmotion = emotion;
        updateEmotionCaption("#tonight-emotion-value", emotion);
      },
      asking
    );
    updateEmotionCaption("#tonight-emotion-value", state.nightEmotion);
  }

  if (done) {
    writeBlock.classList.add("hidden");
    askPanel.classList.add("hidden");
    doneBlock.classList.remove("hidden");
    const summaryEl = $("#tonight-summary");
    summaryEl.replaceChildren(...buildSummaryNodes(session.summary));
    summaryEl.classList.remove("hidden");
    return;
  }

  doneBlock.classList.add("hidden");

  const showAskBtn = writing && hasNightText(session, pad.value);
  $("#btn-ask").classList.toggle("hidden", !showAskBtn);
  $("#btn-save").classList.toggle("hidden", asking);
  $("#btn-done").classList.toggle("hidden", asking);

  if (asking) {
    askPanel.classList.remove("hidden");
    renderAskPanel(session);
  } else {
    askPanel.classList.add("hidden");
  }
}

function renderAskPanel(session) {
  const thread = $("#ask-thread");
  const compose = $("#ask-compose");
  const actions = $("#ask-actions");
  const followups = followupQas(session);
  const pending = pendingFollowup(session);
  const answered = followups.filter((qa) => String(qa.answer || "").trim());
  const maxRounds = session.max_followup_rounds || 2;
  const currentRound = answered.length ? Math.max(...answered.map((qa) => qa.round)) : 0;

  thread.replaceChildren(
    ...answered.map((qa) => {
      const turn = document.createElement("article");
      turn.className = "ask-turn";
      const label = document.createElement("p");
      label.className = "round-label";
      label.textContent = `第 ${qa.round} 问`;
      const q = document.createElement("p");
      q.className = "q";
      q.textContent = qa.question;
      const a = document.createElement("p");
      a.className = "a";
      a.textContent = qa.answer;
      turn.append(label, q, a);
      return turn;
    })
  );

  actions.replaceChildren();
  if (pending) {
    compose.classList.remove("hidden");
    $("#ask-question").textContent = pending.question;
    $("#ask-answer").value = "";
    $("#ask-answer").dataset.qaId = pending.id;
    const submit = document.createElement("button");
    submit.className = "primary";
    submit.type = "button";
    submit.textContent = "记下这一句";
    submit.onclick = () => submitAskAnswer();
    const skip = document.createElement("button");
    skip.className = "ghost";
    skip.type = "button";
    skip.textContent = "今晚先到这";
    skip.onclick = () => runSummarize(true, "正在帮你收一收…");
    actions.append(submit, skip);
  } else {
    compose.classList.add("hidden");
    if (currentRound < maxRounds) {
      const deeper = document.createElement("button");
      deeper.className = "secondary";
      deeper.type = "button";
      deeper.textContent = "再想一层";
      deeper.onclick = () => runDeeper();
      actions.append(deeper);
    }
    const done = document.createElement("button");
    done.className = "primary";
    done.type = "button";
    done.textContent = "可以了，收一收";
    done.onclick = () => runSummarize(false, "正在帮你收一收…");
    actions.append(done);
  }
}

async function openToday() {
  try {
    renderTonight(await api("/sessions/today/open", { method: "POST" }));
  } catch (error) {
    showNotice(error.message);
  }
}

async function saveNight(quiet = false) {
  if (!state.session) return;
  if (state.session.status === "following_up" || state.session.status === "summarized") {
    showNotice("问自己或已收好时，今晚正文先不动了。");
    return;
  }
  state.nightDraft = $("#night-pad").value;
  state.nightEmotion = state.nightEmotion || state.session.emotion || "";
  if (!String(state.nightDraft).trim() && !state.nightEmotion) {
    showNotice("写一句，或只标一个情绪。也可以直接离开，不必完成。");
    return;
  }
  try {
    const saved = await api(`/sessions/${state.session.date}/answers`, {
      method: "PUT",
      body: JSON.stringify({
        answers: collectAnswersPayload(),
        emotion: state.nightEmotion,
      }),
    });
    const draft = state.nightDraft;
    renderTonight(saved);
    state.nightDraft = draft;
    $("#night-pad").value = draft;
    $("#btn-ask").classList.remove("hidden");
    state.weekLoaded = false;
    if (!quiet) showNotice("已存到本机。今晚这样就够了。");
  } catch (error) {
    showNotice(error.message);
    throw error;
  }
}

async function finishNight() {
  try {
    if (String($("#night-pad").value || "").trim() || state.nightEmotion) {
      await saveNight(true);
    }
    clearNotice();
    showNotice("先这样。今晚成立。");
  } catch (_) {
    /* saveNight 已提示 */
  }
}

async function startAsk() {
  const button = $("#btn-ask");
  if (!hasNightText(state.session, $("#night-pad").value)) {
    showNotice("只标了情绪，今晚不触发 AI。想问自己一句时，再写一点文字。");
    return;
  }
  try {
    await saveNight(true);
    await withLoading(button, "正想着怎么问自己…", async () => {
      renderTonight(await api(`/sessions/${state.session.date}/followup/start`, { method: "POST" }));
      showNotice("又问回自己一句。慢慢答，或今晚先到这。");
    });
  } catch (error) {
    showNotice(`${error.message} 可再试一次，或点「今晚先到这」。`);
  }
}

async function submitAskAnswer() {
  const area = $("#ask-answer");
  const qaId = Number(area.dataset.qaId);
  try {
    renderTonight(
      await api(`/sessions/${state.session.date}/followup/answer`, {
        method: "POST",
        body: JSON.stringify({ qa_id: qaId, answer: area.value }),
      })
    );
    showNotice("这一句记下了。可以再想一层，或收一收。");
  } catch (error) {
    showNotice(error.message);
  }
}

async function runDeeper() {
  try {
    await withLoading(null, "正想着怎么问自己…", async () => {
      renderTonight(await api(`/sessions/${state.session.date}/followup/deeper`, { method: "POST" }));
      showNotice("又问回自己一句。");
    });
  } catch (error) {
    showNotice(error.message);
  }
}

async function runSummarize(skip, loadingText) {
  try {
    await withLoading(null, loadingText || "正在帮你收一收…", async () => {
      renderTonight(
        await api(`/sessions/${state.session.date}/summarize`, {
          method: "POST",
          body: JSON.stringify({ skip: Boolean(skip) }),
        })
      );
      showNotice("今晚的夜记已收好。");
      renderCalendar();
      state.weekLoaded = false;
    });
  } catch (error) {
    showNotice(error.message);
  }
}

async function rewriteNight() {
  if (!confirm("会清掉今晚的收束和后来问自己的话，保留已写正文。确定再写一遍？")) return;
  try {
    state.nightDraft = "";
    renderTonight(await api(`/sessions/${state.session.date}/recoach`, { method: "POST" }));
    showNotice("已回到书写。");
  } catch (error) {
    showNotice(error.message);
  }
}

/* —— 本周 —— */
function startOfWeek(dateObj) {
  const d = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate());
  const day = d.getDay(); // 0 Sun
  d.setDate(d.getDate() - day);
  return d;
}

function collectWeekAnswersFromDom() {
  return [...document.querySelectorAll("#week-outline-list .outline-pad")].map((area) => ({
    question: area.dataset.question || "",
    answer: area.value || "",
  }));
}

function renderWeekOutline(week) {
  const list = $("#week-outline-list");
  const closed = week.status === "closed";
  list.replaceChildren(
    ...(week.answers || []).filter((item) => !item.question.startsWith("最近最想搞清楚")).map((item) => {
      const li = document.createElement("li");
      const h = document.createElement("h3");
      h.textContent = item.question;
      const area = document.createElement("textarea");
      area.className = "outline-pad";
      area.rows = 3;
      area.dataset.question = item.question;
      area.value = item.answer || "";
      area.disabled = closed;
      area.placeholder = closed ? "" : "可选热身，不是主菜。";
      if (!closed) {
        area.addEventListener("blur", () => {
          saveWeekAnswers(true).catch(() => {});
        });
      }
      li.append(h, area);
      return li;
    })
  );
}

function renderWeekTopics(week) {
  const list = $("#week-topic-list");
  const closed = week.status === "closed";
  const locked = closed || Boolean(String(week.followup_question || "").trim());
  const selected = String(week.selected_topic || "").trim();
  list.replaceChildren(
    ...(week.candidate_topics || []).map((topic) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "topic-choice" + (topic === selected ? " is-selected" : "");
      button.textContent = topic;
      button.disabled = locked;
      button.setAttribute("aria-pressed", topic === selected ? "true" : "false");
      button.onclick = () => {
        $("#week-topic-custom").value = topic;
        state.week.selected_topic = topic;
        renderWeekTopics(state.week);
        $("#btn-week-ask").classList.remove("hidden");
      };
      return button;
    })
  );
  const custom = $("#week-topic-custom");
  custom.value = selected;
  custom.disabled = locked;
  $("#btn-week-topics").classList.toggle(
    "hidden",
    closed || locked || Boolean((week.candidate_topics || []).length)
  );
  renderEmotionPicker(
    "#week-emotions",
    week.followup_emotion || "",
    (emotion) => {
      state.week.followup_emotion = emotion;
      updateEmotionCaption("#week-emotion-value", emotion, "可跳过");
    },
    locked
  );
  updateEmotionCaption("#week-emotion-value", week.followup_emotion || "", "可跳过");
  $("#week-topic-section").classList.toggle("is-locked", locked);
}

function applyWeekView(week) {
  state.week = week;
  const closed = week.status === "closed";
  const n = week.trace_days || 0;
  const empty = week.empty_days || 0;
  const hasQ = Boolean(String(week.followup_question || "").trim());
  const bootstrapMode = Boolean(week.bootstrap_mode);
  let stats = `近 7 日有痕迹 ${n} 天`;
  if (bootstrapMode && !closed) stats = "起步模式：还没有日痕迹，也可以先从自己写的主题开始";
  else if (empty > 0 && !closed) stats += `，另有 ${empty} 天空着——缺几天也没关系。`;
  $("#week-stats").textContent = stats;

  const hint = $("#week-empty-hint");
  if (closed) {
    hint.textContent = "";
  } else if (n === 0) {
    hint.textContent = "还没有日痕迹时，也可以自己写一件最近想搞清楚的事。";
  } else if (!String(week.selected_topic || "").trim()) {
    hint.textContent = "先选一件，再问自己一句。周日/周一推荐，没有截止时间。";
  } else if (!hasQ) {
    hint.textContent = "主题选好了。情绪可跳过，接着只问自己一句。";
  } else {
    hint.textContent = "把当时的感觉写下来，再点「收这一周」。";
  }

  renderWeekOutline(week);
  renderWeekTopics(week);
  $("#week-traces-body").textContent =
    String(week.traces || "").trim() || "近七日还没有可汇总的夜记。先去「今晚」写一点。";

  const qEl = $("#week-followup-q");
  const aEl = $("#week-followup-a");
  qEl.textContent = week.followup_question || "";
  qEl.classList.toggle("hidden", !hasQ || closed);
  aEl.value = week.followup_answer || "";
  aEl.classList.toggle("hidden", !hasQ || closed);
  aEl.disabled = closed;

  $("#week-followup-section").classList.toggle("hidden", closed);
  $("#week-traces").classList.toggle("hidden", closed);
  $("#week-outline-section").classList.toggle("hidden", closed);
  $("#week-topic-section").classList.toggle("hidden", closed);
  $("#btn-week-ask").classList.toggle(
    "hidden",
    closed || hasQ || !String(week.selected_topic || "").trim()
  );
  $("#btn-week-save-answer").classList.toggle("hidden", closed || !hasQ);
  $("#btn-week-close").classList.toggle("hidden", closed || !hasQ);
  $("#week-closed").classList.toggle("hidden", !closed);

  if (closed) {
    $("#week-closed-topic").textContent = week.selected_topic || "（没有单独选主题）";
    $("#week-closed-emotion").textContent = week.followup_emotion || "（跳过）";
    $("#week-closed-q").textContent = week.followup_question || "（当时没有留下问句）";
    $("#week-closed-a").textContent = week.followup_answer || "（当时没有留下回答）";
    $("#week-overview").textContent = week.echo || week.overview || "";
    const nf = week.next_focus || "";
    const note = week.note || "";
    $("#week-next-focus").textContent = nf ? `下一步：${nf}` : "";
    $("#week-note").textContent = note ? `留给自己：${note}` : "";
    $("#week-archive-body").textContent = week.raw_markdown || "";
  }
  $("#week-shell-note").classList.add("hidden");
}

async function renderWeekStrip(week) {
  const strip = $("#week-strip");
  const labels = ["日", "一", "二", "三", "四", "五", "六"];
  const start = new Date(`${week.week_start}T00:00:00`);
  const end = new Date(`${week.week_end}T00:00:00`);
  const monthQueries = [[start.getFullYear(), start.getMonth() + 1]];
  if (end.getMonth() !== start.getMonth() || end.getFullYear() !== start.getFullYear()) {
    monthQueries.push([end.getFullYear(), end.getMonth() + 1]);
  }
  const records = new Map();
  for (const [y, m] of monthQueries) {
    const items = await api(`/calendar?year=${y}&month=${m}`);
    items.forEach((item) => {
      const dateText = `${y}-${String(m).padStart(2, "0")}-${String(item.day).padStart(2, "0")}`;
      records.set(dateText, item);
    });
  }
  const traceDates = new Set();
  String(week.traces || "")
    .split("\n")
    .forEach((line) => {
      const m = line.match(/^##\s+(\d{4}-\d{2}-\d{2})/);
      if (m) traceDates.add(m[1]);
    });

  strip.replaceChildren(
    ...labels.map((wd, index) => {
      const cellDate = new Date(start.getFullYear(), start.getMonth(), start.getDate() + index);
      const dateText = localDateText(cellDate);
      const info = records.get(dateText);
      const hasTrace = traceDates.has(dateText) || Boolean(info);
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "week-cell";
      if (hasTrace) btn.classList.add("has-trace");
      if (dateText === state.today) btn.classList.add("is-today");
      btn.innerHTML = `<span class="wd">${wd}</span><span class="dm">${cellDate.getDate()}</span>`;
      btn.title = dateText + (hasTrace ? " · 有痕迹" : " · 空着");
      btn.onclick = () => {
        strip.querySelectorAll(".week-cell").forEach((el) => el.classList.remove("is-selected"));
        btn.classList.add("is-selected");
        if (info) {
          switchView("archive");
          state.current = new Date(cellDate.getFullYear(), cellDate.getMonth(), 1);
          loadArchive(dateText, true);
          renderCalendar();
        } else {
          $("#week-shell-note").textContent = `${dateText.replace(/-/g, "·")} 这一天还没有痕迹。`;
          $("#week-shell-note").classList.remove("hidden");
        }
      };
      return btn;
    })
  );
}

async function renderWeekShell(force = false) {
  if (state.weekLoaded && !force && state.week) {
    applyWeekView(state.week);
    await renderWeekStrip(state.week);
    return;
  }
  const week = await api("/weeks/current");
  applyWeekView(week);
  if (
    (week.trace_days || 0) > 0 &&
    !(week.candidate_topics || []).length &&
    !String(week.selected_topic || "").trim() &&
    !String(week.followup_question || "").trim()
  ) {
    const withTopics = await api("/weeks/" + week.week_start + "/topics", {
      method: "POST",
      body: JSON.stringify({ use_llm: true }),
    });
    applyWeekView(withTopics);
  }
  await renderWeekStrip(state.week || week);
  state.weekLoaded = true;
}

async function saveWeekAnswers(quiet = false) {
  if (!state.week || state.week.status === "closed") return;
  const weekStart = state.week.week_start;
  const saved = await api(`/weeks/${weekStart}/answers`, {
    method: "PUT",
    body: JSON.stringify({ answers: collectWeekAnswersFromDom() }),
  });
  applyWeekView(saved);
  if (!quiet) {
    const note = $("#week-shell-note");
    note.textContent = "提纲已存到本机。";
    note.classList.remove("hidden");
  }
}

async function saveWeekTopicChoice(quiet = false) {
  if (!state.week || state.week.status === "closed") return state.week;
  const topic = String($("#week-topic-custom").value || "").trim();
  if (!topic) throw new Error("先选一件事，或自己写一个想谈的主题。");
  const saved = await api("/weeks/" + state.week.week_start + "/topic", {
    method: "PUT",
    body: JSON.stringify({
      topic,
      emotion: state.week.followup_emotion || "",
    }),
  });
  applyWeekView(saved);
  if (!quiet) {
    const note = $("#week-shell-note");
    note.textContent = "这件事已选好。";
    note.classList.remove("hidden");
  }
  return saved;
}

async function requestWeekTopics() {
  if (!state.week) return;
  const note = $("#week-shell-note");
  note.classList.remove("hidden");
  if ((state.week.trace_days || 0) === 0) {
    note.textContent = "还没有日痕迹。先自己写一件最近想搞清楚的事。";
    $("#week-topic-custom").focus();
    return;
  }
  try {
    const topics = await withLoading($("#btn-week-topics"), "正在捞几条线索…", async () =>
      api("/weeks/" + state.week.week_start + "/topics", {
        method: "POST",
        body: JSON.stringify({ use_llm: true }),
      })
    );
    applyWeekView(topics);
    note.textContent = "从这周留下的痕迹里，捞出几件可能值得谈的事。";
  } catch (error) {
    note.textContent = error.message || "这次没捞出来，可以自己写一件。";
  }
}

async function askWeekFollowup() {
  if (!state.week) return;
  const note = $("#week-shell-note");
  note.classList.remove("hidden");
  if (!String($("#week-topic-custom").value || "").trim()) {
    note.textContent = "先选一件，或自己写一个想谈的主题。";
    $("#week-topic-custom").focus();
    return;
  }
  note.textContent = "正在想一句值得问自己的话…";
  try {
    await saveWeekTopicChoice(true);
    await saveWeekAnswers(true);
    const week = await api(`/weeks/${state.week.week_start}/followup`, {
      method: "POST",
      body: JSON.stringify({ use_llm: true }),
    });
    applyWeekView(week);
    await renderWeekStrip(week);
    note.textContent = "下面是本周那一句。写完回答再收周。";
  } catch (error) {
    note.textContent = error.message || "这次没问成，请稍后再试。";
  }
}

async function saveWeekFollowupAnswer(quiet = false) {
  if (!state.week || state.week.status === "closed") return;
  const answer = $("#week-followup-a").value || "";
  const week = await api(`/weeks/${state.week.week_start}/followup`, {
    method: "PUT",
    body: JSON.stringify({ answer }),
  });
  applyWeekView(week);
  if (!quiet) {
    const note = $("#week-shell-note");
    note.textContent = "回答已存到本机。";
    note.classList.remove("hidden");
  }
}

async function closeCurrentWeek() {
  if (!state.week) return;
  const note = $("#week-shell-note");
  note.classList.remove("hidden");
  if (!String(state.week.selected_topic || "").trim()) {
    if (!String($("#week-topic-custom").value || "").trim()) {
      note.textContent = "先选一件，或自己写一个想谈的主题。";
      return;
    }
    await saveWeekTopicChoice(true);
  }
  if (!String(state.week.followup_question || "").trim()) {
    note.textContent = "先问自己一句，再收这一周。";
    return;
  }
  try {
    await saveWeekFollowupAnswer(true);
    note.textContent = "正在收这一周…";
    const closed = await api(`/weeks/${state.week.week_start}/close`, {
      method: "POST",
      body: JSON.stringify({ use_llm: true }),
    });
    applyWeekView(closed);
    await renderWeekStrip(closed);
    note.textContent = "这一周已收好。问句和回答留在了本机。";
  } catch (error) {
    note.textContent = error.message || "收周没有成功，请稍后再试。";
  }
}

async function resummarizeWeek() {
  if (!state.week) return;
  const note = $("#week-shell-note");
  note.classList.remove("hidden");
  note.textContent = "正在再收一下…";
  try {
    const week = await api(`/weeks/${state.week.week_start}/summarize`, { method: "POST" });
    applyWeekView(week);
    await renderWeekStrip(week);
    note.textContent = "收束已更新。问句和回答没有改。";
  } catch (error) {
    note.textContent = error.message || "这次没收成，请稍后再试。";
  }
}

/* —— 回看 —— */
function daysInMonth(year, month) {
  return new Date(year, month + 1, 0).getDate();
}

async function renderCalendar() {
  const year = state.current.getFullYear();
  const month = state.current.getMonth();
  $("#month-label").textContent = `${year} 年 ${month + 1} 月`;
  const items = await api(`/calendar?year=${year}&month=${month + 1}`);
  const records = new Map(items.map((item) => [item.day, item]));
  const grid = $("#calendar-grid");
  grid.replaceChildren();
  for (let i = 0; i < new Date(year, month, 1).getDay(); i++) {
    const empty = document.createElement("button");
    empty.disabled = true;
    empty.className = "calendar-day";
    grid.append(empty);
  }
  for (let day = 1; day <= daysInMonth(year, month); day++) {
    const info = records.get(day);
    const button = document.createElement("button");
    button.className = "calendar-day" + (info ? " recorded" : "");
    button.textContent = day;
    const dateText = `${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
    if (dateText === state.today) button.classList.add("today");
    if (dateText === state.selectedArchiveDay) button.classList.add("is-selected");
    button.onclick = () => loadArchive(dateText, Boolean(info));
    grid.append(button);
  }
}

function formatArchiveTitle(dateText) {
  const [year, month, day] = String(dateText).split("-").map(Number);
  if (!year) return dateText;
  return `${year}年${month}月${day}日`;
}

function revealArchiveDetail() {
  const detail = $("#archive-detail");
  detail.classList.remove("hidden");
  requestAnimationFrame(() => {
    detail.scrollIntoView({ behavior: "smooth", block: "start" });
  });
}

async function loadArchive(day, hasRecord) {
  const detail = $("#archive-detail");
  const title = $("#archive-detail-title");
  const body = $("#archive-detail-body");
  state.selectedArchiveDay = day;
  renderCalendar().catch(() => {});
  title.textContent = formatArchiveTitle(day);

  if (!hasRecord) {
    body.replaceChildren();
    const p = document.createElement("p");
    p.className = "muted";
    p.textContent = "这一天还没有夜记。";
    body.append(p);
    revealArchiveDetail();
    return;
  }
  try {
    const session = await api(`/sessions/${day}`);
    body.replaceChildren();
    if (!session.summary) {
      appendLegacyNightNodes(body, session);
      revealArchiveDetail();
      return;
    }
    const written = document.createElement("div");
    written.className = "summary-section";
    const wh = document.createElement("h3");
    wh.textContent = "当晚写下的";
    const wt = document.createElement("div");
    wt.textContent = padFromSession(session) || "（正文已收进收束）";
    written.append(wh, wt);
    const pieces = [written];
    if (String(session.emotion || "").trim()) {
      const emotion = document.createElement("div");
      emotion.className = "summary-section";
      const eh = document.createElement("h3");
      eh.textContent = "当时的分量";
      const et = document.createElement("div");
      et.textContent = session.emotion;
      emotion.append(eh, et);
      pieces.push(emotion);
    }
    body.append(...pieces, ...buildSummaryNodes(session.summary));
    revealArchiveDetail();
  } catch (error) {
    body.replaceChildren();
    const p = document.createElement("p");
    p.className = "muted";
    p.textContent = error.message.includes("尚无") ? "这一天还没有夜记。" : error.message;
    body.append(p);
    revealArchiveDetail();
  }
}

async function loadSettings() {
  const s = await api("/settings");
  loadWeeklyReminder();
  const form = $("#settings-form");
  for (const [key, value] of Object.entries(s)) {
    if (!form.elements[key]) continue;
    if (key === "question_templates") form.elements[key].value = value.join("\n");
    else form.elements[key].value = value;
  }
  $("#key-status").textContent = s.api_key_configured
    ? "已配置本地密钥（不会回显）"
    : "尚未配置密钥：仍可保存模板回答";
}

async function saveSettings(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const data = Object.fromEntries(new FormData(form));
  data.context_days = Number(data.context_days);
  data.question_templates = String(data.question_templates || "")
    .split("\n")
    .map((value) => value.trim())
    .filter(Boolean);
  try {
    const s = await api("/settings", { method: "PUT", body: JSON.stringify(data) });
    $("#settings-message").textContent = "已保存到本机，定时任务已更新。";
    $("#key-status").textContent = s.api_key_configured ? "已配置本地密钥（不会回显）" : "尚未配置密钥";
    form.elements.llm_api_key.value = "";
  } catch (error) {
    $("#settings-message").textContent = error.message;
  }
}

function switchView(name) {
  document.querySelectorAll(".nav,.view").forEach((item) => item.classList.remove("active"));
  document.querySelector(`.nav[data-view="${name}"]`)?.classList.add("active");
  $(`#${name}`)?.classList.add("active");
  if (name === "week") {
    renderWeekShell(true).catch((error) => {
      $("#week-traces-body").textContent = error.message;
    });
  }
  if (name === "archive") renderCalendar().catch(() => {});
}

document.querySelectorAll(".nav").forEach((button) =>
  button.addEventListener("click", () => switchView(button.dataset.view))
);

$("#night-pad").addEventListener("input", () => {
  state.nightDraft = $("#night-pad").value;
  const show = hasNightText(state.session, state.nightDraft);
  if (state.session?.status === "pending" || state.session?.status === "answered") {
    $("#btn-ask").classList.toggle("hidden", !show);
  }
});

$("#btn-save").onclick = () => saveNight().catch(() => {});
$("#btn-done").onclick = () => finishNight();
$("#btn-ask").onclick = () => startAsk().catch(() => {});
$("#btn-rewrite").onclick = () => rewriteNight();
$("#btn-week-save").onclick = () => saveWeekAnswers(false).catch((error) => {
  const note = $("#week-shell-note");
  note.textContent = error.message;
  note.classList.remove("hidden");
});
$("#btn-week-topics").onclick = () => requestWeekTopics();
$("#week-topic-custom").addEventListener("input", () => {
  if (!state.week || state.week.status === "closed" || state.week.followup_question) return;
  state.week.selected_topic = String($("#week-topic-custom").value || "").trim();
  $("#btn-week-ask").classList.toggle("hidden", !state.week.selected_topic);
});
$("#btn-week-ask").onclick = () => askWeekFollowup();
$("#btn-week-save-answer").onclick = () =>
  saveWeekFollowupAnswer(false).catch((error) => {
    const note = $("#week-shell-note");
    note.textContent = error.message;
    note.classList.remove("hidden");
  });
$("#btn-week-close").onclick = () => closeCurrentWeek();
$("#btn-week-ai").onclick = () => resummarizeWeek();
$("#week-followup-a").addEventListener("blur", () => {
  if (state.week?.followup_question && state.week.status !== "closed") {
    saveWeekFollowupAnswer(true).catch(() => {});
  }
});
$("#settings-form").onsubmit = saveSettings;
$("#btn-reminder-save").onclick = () => saveWeeklyReminder().catch(() => {});
$("#prev-month").onclick = () => {
  state.current.setMonth(state.current.getMonth() - 1);
  renderCalendar();
};
$("#next-month").onclick = () => {
  state.current.setMonth(state.current.getMonth() + 1);
  renderCalendar();
};

Promise.all([openToday(), renderCalendar(), loadSettings()]).catch((error) => showNotice(error.message));
