<p>
  <a href="#english"><kbd>&nbsp;English&nbsp;</kbd></a>
  &nbsp;
  <a href="#zhong-wen"><kbd>&nbsp;中文&nbsp;</kbd></a>
</p>

<a id="english"></a>

# Night Notes Android trial

Flutter Android local-first trial of Night Notes. Small private trial — not a store release and not a user-count claim.

## Included

- Tonight: text or emotion only; AI follow-up only when there is text
- This week: 2–3 candidate topics, custom topic, weekly question, answer, echo, next step
- History: read-only daily and weekly records
- Settings: optional DeepSeek API key; local questions if the key is missing
- Data: Drift SQLite on device; legacy JSON migrates only when old data is found
- Key: `FlutterSecureStorage` (Android Keystore), with a one-time move off plaintext `SharedPreferences`

## Run

```bash
flutter pub get
dart run build_runner build
flutter run
```

## Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

No accounts, cloud sync, notifications, or import/export in this trial. The mobile client talks to DeepSeek only — no Ollama / OpenAI-compatible switch.

---

<a id="zhong-wen"></a>

# 中文

<p>
  <a href="#english"><kbd>&nbsp;English&nbsp;</kbd></a>
  &nbsp;
  <a href="#zhong-wen"><kbd>&nbsp;中文&nbsp;</kbd></a>
</p>

# 夜记 Android 试用版

这是夜记的 Flutter Android 本地优先试用版，用于小范围朋友试用。不要把它读成已发布的商店产品或已验证的用户规模。

## 已包含

- 今晚：文字或情绪记录；只有文字才触发可选 AI 追问、深化和短收束。
- 本周：2～3 个候选主题、自定义主题、周情绪、周问、回答、回声与下一步。
- 历史：每日记录与周场结果按时间回看，默认只读。
- 设置：可选填写 DeepSeek API Key；没有 Key 也能使用本地问题和本地收束。
- 数据：完整记录保存在设备 Drift SQLite；首次启动只在检测到旧数据时迁移旧版 JSON。
- Key：`FlutterSecureStorage`（Android Keystore）。旧版明文 `SharedPreferences` 会在读取时迁走并删除。

## 本地运行

```bash
flutter pub get
dart run build_runner build
flutter run
```

## 构建 APK

```bash
flutter build apk --release
```

产物位于 `build/app/outputs/flutter-apk/app-release.apk`。

本轮不包含账号、云同步、自动通知、导出/导入。移动端当前只对接 DeepSeek，没有 Ollama / OpenAI-compatible 切换。
