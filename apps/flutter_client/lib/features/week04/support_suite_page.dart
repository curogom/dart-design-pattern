import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week04_patterns/abstract_factory.dart';

class SupportSuitePage extends ConsumerStatefulWidget {
  const SupportSuitePage({super.key});

  @override
  ConsumerState<SupportSuitePage> createState() => _SupportSuitePageState();
}

class _SupportSuitePageState extends ConsumerState<SupportSuitePage> {
  SupportTier _tier = SupportTier.standard;
  String _locale = 'ko';
  bool _concierge = false;
  SupportSession? _session;
  Object? _error;

  late final TextEditingController _customerController;
  late final TextEditingController _topicController;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController(text: 'cust-demo');
    _topicController = TextEditingController(text: 'billing');
  }

  @override
  void dispose() {
    _customerController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _updateTier(SupportTier tier) {
    setState(() {
      _tier = tier;
      if (_tier == SupportTier.standard) {
        _concierge = false;
      }
      _session = null;
      _error = null;
    });
  }

  void _updateLocale(String locale) {
    setState(() {
      _locale = locale;
      _session = null;
      _error = null;
    });
  }

  void _toggleConcierge(bool value) {
    setState(() {
      _concierge = value;
      _session = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // tier/locale을 Provider override로 교체해 추상 팩토리 흐름을 시각화.
    final overrides = [
      supportConfigProvider.overrideWithValue(
        SupportConfig(
          tier: _tier,
          locale: _locale,
          enableConcierge: _concierge,
        ),
      ),
    ];

    return ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          final SupportExperience experience =
              ref.watch(supportExperienceProvider);

          Future<void> openSession() async {
            final String customerId = _customerController.text.trim();
            final String topic = _topicController.text.trim();
            if (customerId.isEmpty || topic.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('고객 ID와 토픽을 모두 입력해 주세요.'),
                ),
              );
              return;
            }
            try {
              final SupportSession session = experience.openSession(
                customerId: customerId,
                topic: topic,
              );
              setState(() {
                _session = session;
                _error = null;
              });
            } on UnsupportedError catch (error) {
              setState(() {
                _error = error;
                _session = null;
              });
            }
          }

          return _SupportSuiteView(
            tier: _tier,
            locale: _locale,
            concierge: _concierge,
            session: _session,
            error: _error,
            customerController: _customerController,
            topicController: _topicController,
            onTierChanged: _updateTier,
            onLocaleChanged: _updateLocale,
            onConciergeChanged: _toggleConcierge,
            onGenerate: openSession,
          );
        },
      ),
    );
  }
}

class _SupportSuiteView extends StatelessWidget {
  const _SupportSuiteView({
    required this.tier,
    required this.locale,
    required this.concierge,
    required this.session,
    required this.error,
    required this.customerController,
    required this.topicController,
    required this.onTierChanged,
    required this.onLocaleChanged,
    required this.onConciergeChanged,
    required this.onGenerate,
  });

  final SupportTier tier;
  final String locale;
  final bool concierge;
  final SupportSession? session;
  final Object? error;
  final TextEditingController customerController;
  final TextEditingController topicController;
  final ValueChanged<SupportTier> onTierChanged;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<bool> onConciergeChanged;
  final Future<void> Function() onGenerate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abstract Factory · Support Suite'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            'Tier와 Locale에 따라 에이전트 & 워크플로우 제품군이 한꺼번에 교체됩니다.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SegmentedButton<SupportTier>(
            segments: const <ButtonSegment<SupportTier>>[
              ButtonSegment<SupportTier>(
                value: SupportTier.standard,
                label: Text('Standard'),
                icon: Icon(Icons.support_agent_outlined),
              ),
              ButtonSegment<SupportTier>(
                value: SupportTier.premium,
                label: Text('Premium'),
                icon: Icon(Icons.workspace_premium),
              ),
            ],
            selected: <SupportTier>{tier},
            onSelectionChanged: (Set<SupportTier> values) {
              onTierChanged(values.first);
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Locale 선택',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: locale,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'ko',
                        child: Text('한국어 (ko)'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'en',
                        child: Text('영어 (en)'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'ja',
                        child: Text('일본어 (ja)'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'fr',
                        child: Text('프랑스어 (fr)'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        onLocaleChanged(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedOpacity(
                  opacity: tier == SupportTier.premium ? 1 : 0.2,
                  duration: const Duration(milliseconds: 250),
                  child: SwitchListTile.adaptive(
                    value: concierge,
                    onChanged:
                        tier == SupportTier.premium ? onConciergeChanged : null,
                    title: const Text('컨시어지 연결'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: customerController,
            decoration: const InputDecoration(
              labelText: '고객 ID',
              hintText: '예: cust-123',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: topicController,
            decoration: const InputDecoration(
              labelText: '토픽',
              hintText: '예: billing, incident-response',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.play_arrow),
            label: const Text('세션 생성'),
          ),
          const SizedBox(height: 24),
          if (session != null) _SessionCard(session: session!),
          if (error != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '생성 실패: $error',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final SupportSession session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Greeting',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(session.greeting),
            const Divider(height: 32),
            Text(
              'Channels · SLA',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${session.channels.join(', ')}\nSLA: ${session.estimatedResponse.inMinutes}분',
            ),
            const Divider(height: 32),
            Text(
              '추천 문서',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(session.recommendedArticlePath),
            const Divider(height: 32),
            Row(
              children: <Widget>[
                const Icon(Icons.local_fire_department_outlined),
                const SizedBox(width: 8),
                Text(session.topic),
                const Spacer(),
                Chip(
                  label: Text(
                    session.priorityLane ? 'Priority' : 'Standard',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
