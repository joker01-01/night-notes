import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NightApp());

class NightApp extends StatelessWidget {
  const NightApp({super.key});
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xffe8e5df);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '夜记',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff202426),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffaab8aa),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'serif',
            color: ink,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontFamily: 'serif',
            color: ink,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: ink, height: 1.7),
          bodyMedium: TextStyle(color: Color(0xffb7b8b2), height: 1.6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xff292d2f),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xff555b59)),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// 保留模板测试所使用的入口名。
class MyApp extends NightApp {
  const MyApp({super.key});
}

class LocalData {
  LocalData(this.prefs);
  final SharedPreferences prefs;
  Map<String, String> get nights => Map<String, String>.from(
    jsonDecode(prefs.getString('nights') ?? '{}') as Map,
  );
  Map<String, Map<String, dynamic>> get weeks {
    final raw = jsonDecode(prefs.getString('weeks') ?? '{}') as Map;
    return raw.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  }

  Future<void> saveNight(String day, String text) async {
    final value = nights..[day] = text;
    await prefs.setString('nights', jsonEncode(value));
  }

  Future<void> saveWeek(String key, Map<String, dynamic> value) async {
    final all = weeks..[key] = value;
    await prefs.setString('weeks', jsonEncode(all));
  }
}

class DeepSeekClient {
  static Future<String> askQuestion({
    required String apiKey,
    required String topic,
    required String traces,
    required int traceDays,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const FormatException('未配置 DeepSeek API Key');
    }
    final client = HttpClient();
    try {
      final request = await client
          .postUrl(Uri.parse('https://api.deepseek.com/chat/completions'))
          .timeout(const Duration(seconds: 60));
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${apiKey.trim()}',
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'model': 'deepseek-chat',
          'temperature': 0.4,
          'messages': [
            {
              'role': 'system',
              'content': '你在帮用户做每周一次的自我反思。只输出一个温柔、具体、值得回答的问题，不要写解释，不要写编号。',
            },
            {
              'role': 'user',
              'content': [
                '近七日有痕迹 $traceDays 天。',
                '起步主题：${topic.trim().isEmpty ? '无' : topic.trim()}',
                '近七日痕迹：${traces.trim().isEmpty ? '无' : traces.trim()}',
                '请只输出一个中文问题，关注感受、分量和真实在意的事。',
              ].join('\n'),
            },
          ],
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('DeepSeek 返回 ${response.statusCode}');
      }
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final content = decoded['choices']?[0]?['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const FormatException('DeepSeek 返回为空');
      }
      return content.trim();
    } finally {
      client.close(force: true);
    }
  }
}

DateTime sunday(DateTime value) {
  final d = DateTime(value.year, value.month, value.day);
  return d.subtract(Duration(days: d.weekday % 7));
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  LocalData? data;
  bool loading = true;
  final day = dateKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        data = LocalData(prefs);
        loading = false;
      });
    });
  }

  Future<void> refresh() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (loading || data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      TonightPage(data: data!, day: day, onSaved: refresh),
      WeekPage(data: data!, onSaved: refresh),
      SettingsPage(data: data!),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            label: '今晚',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: '本周',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: '设置'),
        ],
      ),
    );
  }
}

class TonightPage extends StatefulWidget {
  const TonightPage({
    super.key,
    required this.data,
    required this.day,
    required this.onSaved,
  });
  final LocalData data;
  final String day;
  final VoidCallback onSaved;
  @override
  State<TonightPage> createState() => _TonightPageState();
}

class _TonightPageState extends State<TonightPage> {
  late final TextEditingController controller;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.data.nights[widget.day] ?? '',
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (controller.text.trim().isEmpty) return;
    await widget.data.saveNight(widget.day, controller.text.trim());
    widget.onSaved();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已存到本机。今晚这样就够了。')));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
    children: [
      Text(
        '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 10),
      Text('把今天，留给自己五分钟。', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 28),
      TextField(
        controller: controller,
        minLines: 10,
        maxLines: 16,
        decoration: const InputDecoration(hintText: '写下今天最想留下的一点，不用完整。'),
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: save, child: const Text('存一下')),
      TextButton(
        onPressed: () => FocusScope.of(context).unfocus(),
        child: const Text('先这样'),
      ),
    ],
  );
}

class WeekPage extends StatefulWidget {
  const WeekPage({super.key, required this.data, required this.onSaved});
  final LocalData data;
  final VoidCallback onSaved;
  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  late final TextEditingController topic;
  late final TextEditingController answer;
  String question = '';
  bool closed = false;
  bool asking = false;
  late String key;
  @override
  void initState() {
    super.initState();
    key = dateKey(sunday(DateTime.now()));
    final record = widget.data.weeks[key] ?? {};
    topic = TextEditingController(text: record['topic'] as String? ?? '');
    answer = TextEditingController(text: record['answer'] as String? ?? '');
    question = record['question'] as String? ?? '';
    closed = record['closed'] == true;
  }

  @override
  void dispose() {
    topic.dispose();
    answer.dispose();
    super.dispose();
  }

  int traceDays() {
    final all = widget.data.nights;
    final start = sunday(DateTime.now());
    return List.generate(
      7,
      (i) => dateKey(start.add(Duration(days: i))),
    ).where(all.containsKey).length;
  }

  Future<void> save({bool close = false}) async {
    await widget.data.saveWeek(key, {
      'topic': topic.text.trim(),
      'question': question,
      'answer': answer.text.trim(),
      'closed': close,
      'nextFocus': close ? '下周先保留一点空间' : '',
    });
    setState(() => closed = close);
    widget.onSaved();
  }

  Future<void> ask() async {
    if (traceDays() == 0 && topic.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先写一件最近最想搞清楚的事。')));
      return;
    }
    setState(() => asking = true);
    final start = sunday(DateTime.now());
    final traces = List.generate(7, (i) {
      final day = dateKey(start.add(Duration(days: i)));
      final text = widget.data.nights[day];
      return text == null ? '' : '$day：$text';
    }).where((item) => item.isNotEmpty).join('\n');
    try {
      question = await DeepSeekClient.askQuestion(
        apiKey: widget.data.prefs.getString('apiKey') ?? '',
        topic: topic.text,
        traces: traces,
        traceDays: traceDays(),
      );
    } catch (_) {
      question = '这件事现在对你更像期待、负担，还是别的什么分量？';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 暂时没有响应，已使用本地问题。请检查 Key 和网络。')),
        );
      }
    } finally {
      if (mounted) setState(() => asking = false);
    }
    await save();
  }

  @override
  Widget build(BuildContext context) {
    final traces = traceDays();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      children: [
        Text('本周', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text('这一周，坐下来谈谈。', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          closed ? '这一周已收好' : '近 7 日有痕迹 $traces 天',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (!closed && traces == 0) ...[
          Text('第一次来，也可以从这里开始', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            '最近最想搞清楚的一件事',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: topic,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: '例如：我到底还想不想继续做这件事？'),
          ),
          const SizedBox(height: 24),
        ],
        if (!closed && question.isEmpty)
          FilledButton.icon(
            onPressed: asking ? null : ask,
            icon: asking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.question_mark),
            label: Text(asking ? '正在请 AI 想一句…' : '问自己一句（本周）'),
          ),
        if (question.isNotEmpty) ...[
          Text('问自己一句', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(question, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          if (!closed) ...[
            TextField(
              controller: answer,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(hintText: '把当时的感觉/分量写下来。'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => save(close: true),
              child: const Text('收这一周'),
            ),
          ] else ...[
            Text(answer.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            const Text('问过自己，就算过完了。'),
          ],
        ],
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.data});
  final LocalData data;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController keyController;
  @override
  void initState() {
    super.initState();
    keyController = TextEditingController(
      text: widget.data.prefs.getString('apiKey') ?? '',
    );
  }

  @override
  void dispose() {
    keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
    children: [
      Text('设置', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      Text('按你的节奏来。', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 28),
      const Text('DeepSeek API Key'),
      const SizedBox(height: 8),
      TextField(
        controller: keyController,
        obscureText: true,
        decoration: const InputDecoration(hintText: '仅保存在本机'),
      ),
      const SizedBox(height: 12),
      const Text('保存后，「本周」会用它请求 DeepSeek 生成真实周问。Key 只保存在本机。'),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () async {
          await widget.data.prefs.setString(
            'apiKey',
            keyController.text.trim(),
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('设置已保存在本机。')));
        },
        child: const Text('保存设置'),
      ),
      const SizedBox(height: 24),
      const Text('当前版本先做本地优先 MVP。同步、账号和订阅暂不加入。'),
    ],
  );
}
