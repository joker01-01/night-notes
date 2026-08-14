import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_database.dart';

const _ink = Color(0xffeee9df);
const _muted = Color(0xffa9aaa5);
const _background = Color(0xff1d2021);
const _surface = Color(0xff272b2d);
const _line = Color(0xff4b5150);
const _accent = Color(0xffb7c8b5);
const _accentDeep = Color(0xff28372f);
const _buttonRadius = 14.0;
const _buttonHeight = 52.0;

const emotions = ['轻松', '期待', '犹豫', '负担', '烦躁', '想靠近', '想逃开', '说不清'];

void main() => runApp(const NightApp());

class NightApp extends StatelessWidget {
  const NightApp({super.key, this.databaseOverride, this.prefsOverride});

  final AppDatabase? databaseOverride;
  final SharedPreferences? prefsOverride;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '夜记',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.dark,
          surface: _background,
        ),
        fontFamily: 'sans',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'serif',
            color: _ink,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
          titleLarge: TextStyle(
            fontFamily: 'serif',
            color: _ink,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(color: _ink, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: _ink, height: 1.7),
          bodyMedium: TextStyle(color: _muted, height: 1.55),
          labelMedium: TextStyle(
            color: _muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          hintStyle: const TextStyle(color: Color(0xff777d7a)),
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: const Color(0xff1d2721),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            minimumSize: const Size(0, _buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            minimumSize: const Size(0, _buttonHeight),
            side: const BorderSide(color: _line, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xff181b1c),
          indicatorColor: _accentDeep,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
      ),
      home: AppRoot(
        databaseOverride: databaseOverride,
        prefsOverride: prefsOverride,
      ),
    );
  }
}

// 保留旧模板测试使用的入口名。
class MyApp extends NightApp {
  const MyApp({super.key, super.databaseOverride, super.prefsOverride});
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, this.databaseOverride, this.prefsOverride});

  final AppDatabase? databaseOverride;
  final SharedPreferences? prefsOverride;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppDatabase? database;
  SharedPreferences? prefs;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final loadedPrefs =
          widget.prefsOverride ?? await SharedPreferences.getInstance();
      final loadedDatabase = widget.databaseOverride ?? AppDatabase();
      await loadedDatabase.migrateLegacyIfNeeded(loadedPrefs);
      if (!mounted) {
        await loadedDatabase.close();
        return;
      }
      setState(() {
        prefs = loadedPrefs;
        database = loadedDatabase;
        loading = false;
      });
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.toString();
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (database == null || prefs == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              '夜记还没有准备好。\n\n$error',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return AppShell(database: database!, prefs: prefs!);
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.database, required this.prefs});

  final AppDatabase database;
  final SharedPreferences prefs;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  int revision = 0;

  void refresh() => setState(() => revision++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(
        database: widget.database,
        prefs: widget.prefs,
        onChanged: refresh,
      ),
      WeekPage(
        database: widget.database,
        prefs: widget.prefs,
        onChanged: refresh,
      ),
      HistoryPage(
        key: ValueKey('history-$revision'),
        database: widget.database,
      ),
      SettingsPage(key: ValueKey('settings-$revision'), prefs: widget.prefs),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() {
          tab = value;
          revision++;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            selectedIcon: Icon(Icons.nightlight),
            label: '今晚',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '本周',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '历史',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.database,
    required this.prefs,
    required this.onChanged,
  });

  final AppDatabase database;
  final SharedPreferences prefs;
  final VoidCallback onChanged;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final bodyController = TextEditingController();
  final answerController = TextEditingController();
  DailyRecord? record;
  String emotion = '';
  bool loading = true;
  bool asking = false;
  bool closing = false;
  int mutationVersion = 0;

  String get today => dateKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadVersion = mutationVersion;
    final loaded = await widget.database.getDaily(today);
    if (!mounted || loadVersion != mutationVersion) return;
    setState(() {
      record = loaded;
      emotion = loaded?.emotion ?? '';
      bodyController.text = loaded?.body ?? '';
      answerController.text = loaded?.followupAnswer ?? '';
      loading = false;
    });
  }

  @override
  void dispose() {
    bodyController.dispose();
    answerController.dispose();
    super.dispose();
  }

  Future<void> _saveTrace() async {
    final body = bodyController.text.trim();
    if (body.isEmpty && emotion.isEmpty) {
      _notice('写一点，或只留下此刻的情绪。');
      return;
    }
    await _persist(
      body: body,
      emotion: emotion,
      status: body.isEmpty ? 'trace' : (record?.status ?? 'draft'),
    );
    _notice(body.isEmpty ? '情绪留下了，今晚到这里就好。' : '已留在今晚。');
  }

  Future<void> _ask() async {
    final body = bodyController.text.trim();
    if (body.isEmpty) {
      _notice('只留下情绪时，不需要追问；想被问一句，可以再写一点。');
      return;
    }
    final current = record;
    final currentAnswer = answerController.text.trim();
    if (current != null && current.hasFollowup && currentAnswer.isEmpty) {
      _notice('先写下对上一句的回答，再继续问。');
      return;
    }
    setState(() => asking = true);
    final apiKey = widget.prefs.getString('apiKey') ?? '';
    final oldQuestion = current?.followupQuestion ?? '';
    final depth = current?.followupDepth ?? 0;
    try {
      if (current != null && current.hasFollowup && currentAnswer.isNotEmpty) {
        await _persist(
          body: body,
          emotion: emotion,
          followupQuestion: oldQuestion,
          followupAnswer: currentAnswer,
          followupDepth: depth,
          status: 'answered',
        );
      }
      final question = await DeepSeekClient.dailyQuestion(
        apiKey: apiKey,
        body: body,
        emotion: emotion,
        previousQuestion: oldQuestion,
        previousAnswer: currentAnswer,
        depth: depth,
      );
      await _persist(
        body: body,
        emotion: emotion,
        followupQuestion: question,
        followupAnswer: '',
        followupEcho: '',
        followupNextFocus: '',
        followupNote: '',
        followupDepth: depth + 1,
        status: 'asked',
      );
    } catch (_) {
      final fallback = depth == 0
          ? localDailyQuestion(body, emotion)
          : localDailyDeeperQuestion(body, current?.followupAnswer ?? '');
      await _persist(
        body: body,
        emotion: emotion,
        followupQuestion: fallback,
        followupAnswer: '',
        followupDepth: depth + 1,
        status: 'asked',
      );
      _notice('AI 暂时没有响应，已换成本地问题。');
    } finally {
      if (mounted) setState(() => asking = false);
    }
  }

  Future<void> _close() async {
    final current = record;
    if (current == null || !current.hasFollowup) return;
    final body = bodyController.text.trim();
    final answer = answerController.text.trim();
    setState(() => closing = true);
    AiClose close;
    try {
      close = await DeepSeekClient.close(
        apiKey: widget.prefs.getString('apiKey') ?? '',
        context:
            '每日记录：$body\n情绪：$emotion\n问题：${current.followupQuestion}\n回答：$answer',
      );
    } catch (_) {
      close = localClose(answer);
      _notice('AI 暂时没有响应，已用本地方式收好这条。');
    }
    await _persist(
      body: body,
      emotion: emotion,
      followupQuestion: current.followupQuestion,
      followupAnswer: answer,
      followupEcho: close.echo,
      followupNextFocus: close.nextFocus,
      followupNote: close.note,
      followupDepth: current.followupDepth,
      status: 'closed',
    );
    if (mounted) setState(() => closing = false);
  }

  Future<void> _persist({
    required String body,
    required String emotion,
    String? followupQuestion,
    String? followupAnswer,
    String? followupEcho,
    String? followupNextFocus,
    String? followupNote,
    int? followupDepth,
    String? status,
  }) async {
    mutationVersion++;
    final current = record;
    await widget.database.saveDaily(
      day: today,
      body: body,
      emotion: emotion,
      followupQuestion: followupQuestion ?? current?.followupQuestion ?? '',
      followupAnswer: followupAnswer ?? current?.followupAnswer ?? '',
      followupEcho: followupEcho ?? current?.followupEcho ?? '',
      followupNextFocus: followupNextFocus ?? current?.followupNextFocus ?? '',
      followupNote: followupNote ?? current?.followupNote ?? '',
      followupDepth: followupDepth ?? current?.followupDepth ?? 0,
      status: status ?? current?.status ?? 'draft',
    );
    record = await widget.database.getDaily(today);
    if (mounted) {
      setState(() {});
    }
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final current = record;
    final closed = current?.status == 'closed';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Eyebrow(text: formatDate(today)),
        const SizedBox(height: 9),
        Text('今晚，留一点给自己', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('随手记一点，不需要完整，也没有正确答案。'),
        const SizedBox(height: 24),
        TextField(
          controller: bodyController,
          minLines: 6,
          maxLines: 12,
          readOnly: closed,
          decoration: const InputDecoration(hintText: '今天有什么事，偶尔又回到你心里？'),
        ),
        const SizedBox(height: 18),
        Text('此刻更像哪一种？', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 9),
        EmotionPicker(
          value: emotion,
          onChanged: closed ? null : (value) => setState(() => emotion = value),
        ),
        const SizedBox(height: 18),
        if (!closed)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saveTrace,
                  child: const Text('留下这一点'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: asking ? null : _ask,
                  child: Text(asking ? '想一想…' : '问自己一句'),
                ),
              ),
            ],
          ),
        if (current?.hasFollowup == true) ...[
          const SizedBox(height: 26),
          SectionRule(label: closed ? '这条记录' : '问自己一句'),
          const SizedBox(height: 14),
          QuoteCard(text: current!.followupQuestion),
          const SizedBox(height: 14),
          if (!closed) ...[
            TextField(
              controller: answerController,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(hintText: '把当时的感受写下来。'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: asking ? null : _ask,
                    child: const Text('再问一句'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: closing ? null : _close,
                    child: Text(closing ? '正在收好…' : '收好这条'),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (current.followupAnswer.isNotEmpty)
              Text(
                current.followupAnswer,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (current.followupEcho.isNotEmpty) ...[
              const SizedBox(height: 15),
              QuoteCard(text: current.followupEcho, soft: true),
            ],
            if (current.followupNextFocus.isNotEmpty) ...[
              const SizedBox(height: 15),
              LabeledText(label: '可以留意', value: current.followupNextFocus),
            ],
          ],
        ],
      ],
    );
  }
}

class WeekPage extends StatefulWidget {
  const WeekPage({
    super.key,
    required this.database,
    required this.prefs,
    required this.onChanged,
  });

  final AppDatabase database;
  final SharedPreferences prefs;
  final VoidCallback onChanged;

  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  final customTopicController = TextEditingController();
  final answerController = TextEditingController();
  WeekRecord? record;
  List<DailyRecord> daily = const [];
  String emotion = '';
  bool loading = true;
  bool generating = false;
  bool asking = false;
  bool closing = false;
  int mutationVersion = 0;

  String get weekStart => dateKey(sunday(DateTime.now()));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadVersion = mutationVersion;
    final loaded = await widget.database.getWeek(weekStart);
    final traces = await widget.database.listDaily();
    if (!mounted || loadVersion != mutationVersion) {
      return;
    }
    final current =
        loaded ??
        WeekRecord(
          weekStart: weekStart,
          status: 'draft',
          candidateTopics: const [],
          selectedTopic: '',
          followupEmotion: '',
          followupQuestion: '',
          followupAnswer: '',
          echo: '',
          nextFocus: '',
          note: '',
          closedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    if (!mounted) return;
    setState(() {
      record = current;
      daily = traces;
      emotion = current.followupEmotion;
      customTopicController.text = current.selectedTopic;
      answerController.text = current.followupAnswer;
      loading = false;
    });
    if (!current.isClosed &&
        current.candidateTopics.isEmpty &&
        _traceDays > 0) {
      await _generateTopics();
    }
  }

  int get _traceDays {
    final days = <String>{};
    final start = sunday(DateTime.now());
    for (var i = 0; i < 7; i++) {
      final key = dateKey(start.add(Duration(days: i)));
      if (daily.any((entry) => entry.day == key && entry.hasTrace)) {
        days.add(key);
      }
    }
    return days.length;
  }

  List<DailyRecord> get _weekDaily {
    final start = sunday(DateTime.now());
    final keys = List.generate(7, (i) => dateKey(start.add(Duration(days: i))));
    return daily.where((entry) => keys.contains(entry.day)).toList();
  }

  @override
  void dispose() {
    customTopicController.dispose();
    answerController.dispose();
    super.dispose();
  }

  Future<void> _generateTopics() async {
    final current = record;
    if (current == null || current.isClosed) return;
    setState(() => generating = true);
    final local = localCandidateTopics(_weekDaily);
    var topics = local;
    try {
      final remote = await DeepSeekClient.candidateTopics(
        apiKey: widget.prefs.getString('apiKey') ?? '',
        traces: weeklyTraceText(_weekDaily),
      );
      if (remote.isNotEmpty) topics = remote;
    } catch (_) {}
    await _persist(candidateTopics: topics);
    if (mounted) setState(() => generating = false);
  }

  Future<void> _selectTopic(String value) async {
    await _persist(selectedTopic: value.trim());
  }

  Future<void> _ask() async {
    final current = record;
    final selected = (current?.selectedTopic.trim().isNotEmpty == true
            ? current!.selectedTopic
            : customTopicController.text)
        .trim();
    if (selected.isEmpty) {
      _notice('先选一件，或写下这周最想看清的事。');
      return;
    }
    setState(() => asking = true);
    String question;
    try {
      question = await DeepSeekClient.weekQuestion(
        apiKey: widget.prefs.getString('apiKey') ?? '',
        topic: selected,
        emotion: emotion,
        traces: weeklyTraceText(_weekDaily),
      );
    } catch (_) {
      question = localWeekQuestion(selected, emotion);
      _notice('AI 暂时没有响应，已换成本地问题。');
    }
    await _persist(
      selectedTopic: selected,
      followupQuestion: question,
      followupAnswer: '',
      echo: '',
      nextFocus: '',
      note: '',
    );
    if (mounted) setState(() => asking = false);
  }

  Future<void> _close() async {
    final current = record;
    if (current == null || !current.hasQuestion) return;
    setState(() => closing = true);
    final answer = answerController.text.trim();
    AiClose close;
    try {
      close = await DeepSeekClient.close(
        apiKey: widget.prefs.getString('apiKey') ?? '',
        context:
            '本周主题：${current.selectedTopic}\n周情绪：$emotion\n本周问题：${current.followupQuestion}\n我的回答：$answer',
      );
    } catch (_) {
      close = localClose(answer);
      _notice('AI 暂时没有响应，已用本地方式收好这一周。');
    }
    await _persist(
      followupAnswer: answer,
      echo: close.echo,
      nextFocus: close.nextFocus,
      note: close.note,
      status: 'closed',
      closedAt: DateTime.now(),
    );
    if (mounted) setState(() => closing = false);
  }

  Future<void> _persist({
    String? status,
    List<String>? candidateTopics,
    String? selectedTopic,
    String? followupEmotion,
    String? followupQuestion,
    String? followupAnswer,
    String? echo,
    String? nextFocus,
    String? note,
    DateTime? closedAt,
  }) async {
    mutationVersion++;
    final current = record;
    await widget.database.saveWeek(
      weekStart: weekStart,
      status: status ?? current?.status ?? 'draft',
      candidateTopics: candidateTopics ?? current?.candidateTopics ?? const [],
      selectedTopic: selectedTopic ?? current?.selectedTopic ?? '',
      followupEmotion: followupEmotion ?? emotion,
      followupQuestion: followupQuestion ?? current?.followupQuestion ?? '',
      followupAnswer: followupAnswer ?? current?.followupAnswer ?? '',
      echo: echo ?? current?.echo ?? '',
      nextFocus: nextFocus ?? current?.nextFocus ?? '',
      note: note ?? current?.note ?? '',
      closedAt: closedAt ?? current?.closedAt,
    );
    record = await widget.database.getWeek(weekStart);
    if (mounted) {
      setState(() {});
    }
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading || record == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final current = record!;
    final closed = current.isClosed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Eyebrow(text: '周日 / 周一推荐 · 没有截止时间'),
        const SizedBox(height: 9),
        Text('这一周，坐下来看看', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('有痕迹 $_traceDays 天。少一点总结，多一点看清。'),
        const SizedBox(height: 24),
        if (!closed) ...[
          if (current.candidateTopics.isNotEmpty) ...[
            SectionRule(label: '可以从这里开始'),
            const SizedBox(height: 12),
            ...current.candidateTopics.map(
              (topic) => TopicTile(
                text: topic,
                selected: current.selectedTopic == topic,
                onTap: () => _selectTopic(topic),
              ),
            ),
          ],
          if (current.candidateTopics.isEmpty && _traceDays == 0)
            const Text('还没有本周记录，也可以直接写下此刻最想看清的一件事。'),
          const SizedBox(height: 12),
          TextField(
            controller: customTopicController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '自己的主题',
              hintText: '例如：我到底还想不想继续做这件事？',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: generating ? null : _generateTopics,
            icon: generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(generating ? '正在整理…' : '换一组候选'),
          ),
          const SizedBox(height: 20),
          SectionRule(label: '这周的感觉（可跳过）'),
          const SizedBox(height: 10),
          EmotionPicker(
            value: emotion,
            onChanged: (value) async {
              setState(() => emotion = value);
              await _persist(followupEmotion: value);
            },
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: asking ? null : _ask,
            icon: asking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.question_mark),
            label: Text(asking ? '正在想一句…' : '问自己一句（本周）'),
          ),
        ],
        if (current.hasQuestion) ...[
          const SizedBox(height: 26),
          SectionRule(label: closed ? '这周留下的东西' : '问自己一句'),
          const SizedBox(height: 14),
          if (current.selectedTopic.isNotEmpty)
            LabeledText(label: '主题', value: current.selectedTopic),
          if (current.followupEmotion.isNotEmpty) ...[
            const SizedBox(height: 12),
            LabeledText(label: '感觉', value: current.followupEmotion),
          ],
          const SizedBox(height: 14),
          QuoteCard(text: current.followupQuestion),
          const SizedBox(height: 14),
          if (!closed) ...[
            TextField(
              controller: answerController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(hintText: '把你的回答留在这里。'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: closing ? null : _close,
              child: Text(closing ? '正在收好…' : '收好这一周'),
            ),
          ] else ...[
            if (current.followupAnswer.isNotEmpty)
              Text(
                current.followupAnswer,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (current.echo.isNotEmpty) ...[
              const SizedBox(height: 16),
              QuoteCard(text: current.echo, soft: true),
            ],
            if (current.nextFocus.isNotEmpty) ...[
              const SizedBox(height: 15),
              LabeledText(label: '可以留意', value: current.nextFocus),
            ],
            const SizedBox(height: 16),
            const Text('没有截止时间。问过自己，就已经完成了一点。'),
          ],
        ],
      ],
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<DailyRecord> daily = const [];
  List<WeekRecord> weeks = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadedDaily = await widget.database.listDaily();
    final loadedWeeks = await widget.database.listWeeks();
    if (!mounted) return;
    setState(() {
      daily = loadedDaily;
      weeks = loadedWeeks;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Eyebrow(text: '只给自己看的记录'),
        const SizedBox(height: 9),
        Text('慢慢回看', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 26),
        SectionRule(label: '每周'),
        const SizedBox(height: 12),
        if (weeks.isEmpty)
          const EmptyHint(text: '还没有收好的周场。')
        else
          ...weeks.map((week) => WeekHistoryCard(week: week)),
        const SizedBox(height: 26),
        SectionRule(label: '每天'),
        const SizedBox(height: 12),
        if (daily.isEmpty)
          const EmptyHint(text: '还没有留下每日记录。')
        else
          ...daily.map((entry) => DailyHistoryCard(entry: entry)),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController keyController;

  @override
  void initState() {
    super.initState();
    keyController = TextEditingController(
      text: widget.prefs.getString('apiKey') ?? '',
    );
  }

  @override
  void dispose() {
    keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.prefs.setString('apiKey', keyController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API Key 已保存在本机。')));
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    children: [
      const Eyebrow(text: '按你的节奏来'),
      const SizedBox(height: 9),
      Text('设置', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      const Text('DeepSeek API Key'),
      const SizedBox(height: 8),
      TextField(
        controller: keyController,
        obscureText: true,
        decoration: const InputDecoration(hintText: '可留空，应用仍能使用本地问题'),
      ),
      const SizedBox(height: 10),
      const Text('只有你主动点击 AI 相关按钮时才会联网。Key 只保存在这台手机。'),
      const SizedBox(height: 13),
      FilledButton(onPressed: _save, child: const Text('保存设置')),
      const SizedBox(height: 18),
      const Text('记录只保存在这台手机。'),
    ],
  );
}

class DeepSeekClient {
  static Future<String> _complete({
    required String apiKey,
    required String system,
    required String user,
  }) async {
    if (apiKey.trim().isEmpty) throw const FormatException('没有配置 API Key');
    final client = HttpClient();
    try {
      final request = await client
          .postUrl(Uri.parse('https://api.deepseek.com/chat/completions'))
          .timeout(const Duration(seconds: 30));
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
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
          ],
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('DeepSeek 返回 ${response.statusCode}');
      }
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final content = decoded['choices']?[0]?['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const FormatException('AI 返回为空');
      }
      return content.trim();
    } finally {
      client.close(force: true);
    }
  }

  static Future<String> dailyQuestion({
    required String apiKey,
    required String body,
    required String emotion,
    required String previousQuestion,
    required String previousAnswer,
    required int depth,
  }) async {
    return _complete(
      apiKey: apiKey,
      system:
          '你是夜记，一个帮助用户做自我反思与方向校准的温和镜子。只输出一个具体、克制、值得回答的中文问题。不要诊断、治疗、评判或给长篇建议。',
      user: [
        '这是第 $depth 次追问。',
        '今日记录：${body.trim()}',
        '今日情绪：${emotion.trim().isEmpty ? '未选择' : emotion.trim()}',
        if (previousQuestion.isNotEmpty) '上一问：$previousQuestion',
        if (previousAnswer.isNotEmpty) '上一答：$previousAnswer',
        '请只输出一个问题。',
      ].join('\n'),
    );
  }

  static Future<List<String>> candidateTopics({
    required String apiKey,
    required String traces,
  }) async {
    final raw = await _complete(
      apiKey: apiKey,
      system:
          '你是夜记。根据用户一周的真实记录，提出 2 到 3 个值得自我反思的候选主题。只返回 JSON：{"topics":["主题1","主题2"]}。不要诊断，不要总结流水账。',
      user: traces,
    );
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) throw const FormatException('候选主题格式不正确');
    final decoded = jsonDecode(raw.substring(start, end + 1));
    final topics = decoded is Map ? decoded['topics'] : null;
    if (topics is! List) throw const FormatException('候选主题为空');
    return topics
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList();
  }

  static Future<String> weekQuestion({
    required String apiKey,
    required String topic,
    required String emotion,
    required String traces,
  }) async {
    return _complete(
      apiKey: apiKey,
      system:
          '你是夜记，一个帮助用户做自我反思与方向校准的温和镜子。只输出一个具体、温和、值得回答的中文问题。不要诊断、治疗、评判或给长篇建议。',
      user: [
        '本周主题：$topic',
        '本周情绪：${emotion.trim().isEmpty ? '未选择' : emotion.trim()}',
        '本周记录：$traces',
        '请只输出一个问题。',
      ].join('\n'),
    );
  }

  static Future<AiClose> close({
    required String apiKey,
    required String context,
  }) async {
    final raw = await _complete(
      apiKey: apiKey,
      system:
          '你是夜记。请如实、简短地收束用户刚才的一次自我反思。只返回 JSON：{"echo":"1到2句回声","next_focus":"可选的一个留意方向","note":"一句不施压的备注"}。不诊断、不评判、不编造行动要求；next_focus 没有必要时返回空字符串。',
      user: context,
    );
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) throw const FormatException('收束格式不正确');
    final decoded = jsonDecode(raw.substring(start, end + 1));
    if (decoded is! Map) throw const FormatException('收束为空');
    return AiClose(
      echo: decoded['echo']?.toString() ?? '',
      nextFocus: decoded['next_focus']?.toString() ?? '',
      note: decoded['note']?.toString() ?? '',
    );
  }
}

class AiClose {
  const AiClose({
    required this.echo,
    required this.nextFocus,
    required this.note,
  });

  final String echo;
  final String nextFocus;
  final String note;
}

String localDailyQuestion(String body, String emotion) {
  if (emotion.isNotEmpty) return '这件事里，哪一部分最值得你先承认，而不是马上解决？';
  return '如果先不急着解决，这件事现在最想让你看见什么？';
}

String localDailyDeeperQuestion(String body, String answer) {
  return '你的回答里，哪一个词最接近你真正想要的方向？';
}

String localWeekQuestion(String topic, String emotion) {
  if (emotion.isNotEmpty) return '关于“$topic”，这份$emotion更像是在提醒你什么？';
  return '关于“$topic”，你现在最想对自己诚实的一句话是什么？';
}

AiClose localClose(String answer) {
  final trimmed = answer.trim();
  final echo = trimmed.isEmpty
      ? '你给这段经历留了一个位置。'
      : (trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed);
  return const AiClose(
    echo: '你给这段经历留了一个位置。',
    nextFocus: '',
    note: '先放在这里，不需要马上得出结论。',
  ).copyWithEcho(echo);
}

extension on AiClose {
  AiClose copyWithEcho(String value) =>
      AiClose(echo: value, nextFocus: nextFocus, note: note);
}

List<String> localCandidateTopics(List<DailyRecord> entries) {
  final topics = <String>[];
  for (final entry in entries) {
    final lines = entry.body
        .split(RegExp(r'[\n。！？!?]'))
        .map((line) => line.trim())
        .where((line) => line.length >= 4);
    for (final line in lines) {
      final topic = line.length > 42 ? '${line.substring(0, 42)}…' : line;
      if (!topics.contains(topic)) topics.add(topic);
      if (topics.length == 3) return topics;
    }
  }
  return topics;
}

String weeklyTraceText(List<DailyRecord> entries) {
  return entries
      .where((entry) => entry.hasTrace)
      .map(
        (entry) =>
            '${entry.day}｜${entry.body.trim().isEmpty ? '情绪：${entry.emotion}' : entry.body.trim()}',
      )
      .join('\n');
}

DateTime sunday(DateTime value) {
  final date = DateTime(value.year, value.month, value.day);
  return date.subtract(Duration(days: date.weekday % 7));
}

String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String formatDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  return '${parts[0]} 年 ${int.parse(parts[1])} 月 ${int.parse(parts[2])} 日';
}

class Eyebrow extends StatelessWidget {
  const Eyebrow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelMedium);
}

class SectionRule extends StatelessWidget {
  const SectionRule({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Divider(color: _line.withValues(alpha: 0.8))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
      Expanded(child: Divider(color: _line.withValues(alpha: 0.8))),
    ],
  );
}

class EmotionPicker extends StatelessWidget {
  const EmotionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: emotions
        .map(
          (emotion) => ChoiceChip(
            label: Text(emotion),
            selected: value == emotion,
            onSelected: onChanged == null
                ? null
                : (_) => onChanged!(value == emotion ? '' : emotion),
            selectedColor: _accentDeep,
            side: BorderSide(color: value == emotion ? _accent : _line),
            labelStyle: TextStyle(
              color: value == emotion ? _accent : _muted,
              fontSize: 13,
            ),
          ),
        )
        .toList(),
  );
}

class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: selected ? _accentDeep : _surface,
    margin: const EdgeInsets.only(bottom: 9),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: selected ? _accent : _line),
      borderRadius: BorderRadius.circular(3),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Icon(
              selected ? Icons.check : Icons.arrow_forward,
              size: 18,
              color: selected ? _accent : _muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.text, this.soft = false});

  final String text;
  final bool soft;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: soft ? _accentDeep.withValues(alpha: 0.65) : _surface,
      border: Border(left: BorderSide(color: _accent, width: 2)),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
  );
}

class LabeledText extends StatelessWidget {
  const LabeledText({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    color: _surface,
    child: Text(text),
  );
}

class DailyHistoryCard extends StatelessWidget {
  const DailyHistoryCard({super.key, required this.entry});

  final DailyRecord entry;

  @override
  Widget build(BuildContext context) => Card(
    color: _surface,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(entry.day),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (entry.emotion.isNotEmpty)
                Text(
                  entry.emotion,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
          if (entry.body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(entry.body, style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (entry.followupQuestion.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: _line),
            const SizedBox(height: 10),
            Text('问：${entry.followupQuestion}'),
            if (entry.followupAnswer.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text('答：${entry.followupAnswer}'),
            ],
            if (entry.followupEcho.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(entry.followupEcho, style: const TextStyle(color: _muted)),
            ],
          ],
        ],
      ),
    ),
  );
}

class WeekHistoryCard extends StatelessWidget {
  const WeekHistoryCard({super.key, required this.week});

  final WeekRecord week;

  @override
  Widget build(BuildContext context) => Card(
    color: _surface,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatDate(week.weekStart)} 起',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                week.isClosed ? '已收好' : '草稿',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          if (week.selectedTopic.isNotEmpty) ...[
            const SizedBox(height: 10),
            LabeledText(label: '主题', value: week.selectedTopic),
          ],
          if (week.followupEmotion.isNotEmpty) ...[
            const SizedBox(height: 10),
            LabeledText(label: '感觉', value: week.followupEmotion),
          ],
          if (week.followupQuestion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('问：${week.followupQuestion}'),
          ],
          if (week.followupAnswer.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text('答：${week.followupAnswer}'),
          ],
          if (week.echo.isNotEmpty) ...[
            const SizedBox(height: 10),
            QuoteCard(text: week.echo, soft: true),
          ],
        ],
      ),
    ),
  );
}
