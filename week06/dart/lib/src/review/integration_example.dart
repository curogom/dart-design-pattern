import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../adapter/adapter_example.dart';
import '../proxy/proxy_example.dart';

class ReviewRequest {
  const ReviewRequest({
    required this.transcript,
    required this.relatedArticles,
  });

  final LegacyChatTranscript transcript;
  final List<String> relatedArticles;
}

class ReviewReport {
  const ReviewReport({
    required this.thread,
    required this.articles,
    required this.totalLatency,
  });

  final ConversationThread thread;
  final List<Article> articles;
  final Duration totalLatency;
}

class SupportReviewFacade {
  SupportReviewFacade({
    required this.adapter,
    required this.knowledgeBase,
  });

  final ChatTranscriptAdapter adapter;
  final KnowledgeBaseClient knowledgeBase;

  Future<ReviewReport> buildReview(ReviewRequest request) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final ConversationThread thread = adapter.toThread(request.transcript);

    final List<Article> articles = <Article>[];
    for (final String slug in request.relatedArticles) {
      final Article article = await knowledgeBase.fetch(slug);
      articles.add(article);
    }
    stopwatch.stop();

    return ReviewReport(
      thread: thread,
      articles: articles,
      totalLatency: stopwatch.elapsed,
    );
  }
}

/// 어댑터+프록시 조합으로 리뷰 보고서를 만든다.
final reviewFacadeProvider = Provider<SupportReviewFacade>((ref) {
  final ChatTranscriptAdapter adapter = const SupportChatAdapter();
  final KnowledgeBaseClient client = ref.watch(knowledgeBaseClientProvider);
  return SupportReviewFacade(
    adapter: adapter,
    knowledgeBase: client,
  );
});

final reviewReportProvider = FutureProvider.autoDispose
    .family<ReviewReport, ReviewRequest>((ref, request) async {
  final SupportReviewFacade facade = ref.watch(reviewFacadeProvider);
  return facade.buildReview(request);
});

Future<void> main() async {
  const LegacyChatTranscript transcript = LegacyChatTranscript(
    ticketId: 'ticket-9000',
    messages: <LegacyChatMessage>[
      LegacyChatMessage(
        sender: 'customer',
        body: 'VPN 연결이 안 됩니다.',
        epochSeconds: 1,
      ),
      LegacyChatMessage(
        sender: 'agent',
        body: '네트워크 진단 로그를 보내주세요.',
        epochSeconds: 30,
      ),
    ],
  );

  final ProviderContainer container = ProviderContainer();
  final ReviewRequest request = ReviewRequest(
    transcript: transcript,
    relatedArticles: const <String>['vpn-troubleshooting', 'network-checklist'],
  );

  final ReviewReport report =
      await container.read(reviewReportProvider(request).future);

  print('Participants: ${report.thread.participants.join(', ')}');
  print('Messages: ${report.thread.messages.length}');
  print('Articles: ${report.articles.map((Article a) => a.slug).join(', ')}');
  print('Total latency: ${report.totalLatency.inMilliseconds} ms');

  container.dispose();
}
