import 'package:test/test.dart';
import 'package:week06_patterns/adapter.dart';

void main() {
  group('SupportChatAdapter', () {
    test('converts legacy transcript to conversation thread', () {
      const LegacyChatTranscript transcript = LegacyChatTranscript(
        ticketId: 'ticket-1',
        messages: <LegacyChatMessage>[
          LegacyChatMessage(
            sender: 'user_a',
            body: 'Hello',
            epochSeconds: 1,
          ),
          LegacyChatMessage(
            sender: 'agent_kim',
            body: '안녕하세요!',
            epochSeconds: 120,
          ),
          LegacyChatMessage(
            sender: 'agent_kim',
            body: ' 내부 메모 ',
            epochSeconds: 130,
            internal: true,
          ),
        ],
      );

      const SupportChatAdapter adapter = SupportChatAdapter();
      final ConversationThread thread = adapter.toThread(transcript);

      expect(thread.ticketId, 'ticket-1');
      expect(thread.participants, containsAll(<String>{'user a', 'agent kim'}));
      expect(thread.messages.length, 3);
      expect(thread.duration.inSeconds, 129);
      expect(thread.messages.last.visibility, MessageVisibility.internal);
    });

    test('handles empty transcript', () {
      const LegacyChatTranscript transcript = LegacyChatTranscript(
        ticketId: 'ticket-empty',
        messages: <LegacyChatMessage>[],
      );

      const SupportChatAdapter adapter = SupportChatAdapter();
      final ConversationThread thread = adapter.toThread(transcript);

      expect(thread.messages, isEmpty);
      expect(thread.participants, isEmpty);
      expect(thread.duration, Duration.zero);
    });
  });
}
