import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week06_patterns/adapter.dart';
import 'package:week06_patterns/review.dart';

class SupportReviewPage extends ConsumerWidget {
  const SupportReviewPage({super.key});

  static final ReviewRequest _request = ReviewRequest(
    transcript: const LegacyChatTranscript(
      ticketId: 'ticket-virtual',
      messages: <LegacyChatMessage>[
        LegacyChatMessage(
          sender: 'customer_lee',
          body: '지연된 알림을 해결하고 싶어요.',
          epochSeconds: 1,
        ),
        LegacyChatMessage(
          sender: 'agent_han',
          body: '알림 채널 설정을 확인해 보겠습니다.',
          epochSeconds: 45,
        ),
        LegacyChatMessage(
          sender: 'agent_han',
          body: ' 내부 메모: 모바일 푸시 지연 참고 ',
          epochSeconds: 52,
          internal: true,
        ),
      ],
    ),
    relatedArticles: <String>['notification-delay', 'push-debug'],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ReviewReport> report =
        ref.watch(reviewReportProvider(_request));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adapter & Proxy Review Demo'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              ref.invalidate(reviewReportProvider(_request));
            },
            icon: const Icon(Icons.refresh),
            tooltip: '리뷰 다시 불러오기',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: report.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Text('오류 발생: $error'),
          ),
          data: (ReviewReport report) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('티켓: ${report.thread.ticketId}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('참여자: ${report.thread.participants.join(', ')}'),
                Text('대화 길이: ${report.thread.duration.inSeconds}초'),
                const SizedBox(height: 16),
                Text('메시지', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: report.thread.messages.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      final ConversationMessage message =
                          report.thread.messages[index];
                      return ListTile(
                        leading: Icon(
                          message.visibility == MessageVisibility.internal
                              ? Icons.lock
                              : Icons.chat_bubble_outline,
                        ),
                        title: Text('${message.author}'),
                        subtitle: Text(message.content),
                        trailing: Text(
                          message.timestamp.toIso8601String(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('추천 문서', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: report.articles
                      .map(
                        (article) => Chip(
                          label: Text(article.slug),
                          avatar: const Icon(Icons.menu_book_outlined),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text('총 지연: ${report.totalLatency.inMilliseconds} ms'),
              ],
            );
          },
        ),
      ),
    );
  }
}
