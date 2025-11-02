import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:week06_patterns/review.dart';
import 'package:week06_patterns/src/adapter/adapter_example.dart';
import 'package:week06_patterns/src/review/integration_example.dart';

void main() {
  test('SupportReviewFacade builds report with articles', () async {
    const LegacyChatTranscript transcript = LegacyChatTranscript(
      ticketId: 'ticket-77',
      messages: <LegacyChatMessage>[
        LegacyChatMessage(
          sender: 'client',
          body: 'VPN 이슈',
          epochSeconds: 1,
        ),
        LegacyChatMessage(
          sender: 'agent_yi',
          body: '진단중입니다.',
          epochSeconds: 30,
        ),
      ],
    );

    final ProviderContainer container = ProviderContainer();
    final ReviewRequest request = ReviewRequest(
      transcript: transcript,
      relatedArticles: const <String>['vpn', 'network'],
    );

    final ReviewReport report =
        await container.read(reviewReportProvider(request).future);

    expect(report.thread.messages.length, 2);
    expect(report.articles.length, 2);
    expect(report.totalLatency, isNotNull);

    container.dispose();
  });
}
