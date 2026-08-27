# 夜记 Android 试用版

Flutter Android local-first trial of Night Notes.

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
