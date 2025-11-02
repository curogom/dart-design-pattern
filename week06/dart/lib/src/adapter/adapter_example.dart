import 'package:collection/collection.dart';

class LegacyChatMessage {
  const LegacyChatMessage({
    required this.sender,
    required this.body,
    required this.epochSeconds,
    this.internal = false,
  });

  final String sender;
  final String body;
  final int epochSeconds;
  final bool internal;
}

class LegacyChatTranscript {
  const LegacyChatTranscript({
    required this.ticketId,
    required this.messages,
  });

  final String ticketId;
  final List<LegacyChatMessage> messages;
}

class ConversationMessage {
  const ConversationMessage({
    required this.author,
    required this.content,
    required this.timestamp,
    required this.visibility,
  });

  final String author;
  final String content;
  final DateTime timestamp;
  final MessageVisibility visibility;
}

enum MessageVisibility { public, internal }

class ConversationThread {
  const ConversationThread({
    required this.ticketId,
    required this.messages,
    required this.participants,
    required this.duration,
  });

  final String ticketId;
  final List<ConversationMessage> messages;
  final Set<String> participants;
  final Duration duration;
}

abstract class ChatTranscriptAdapter {
  ConversationThread toThread(LegacyChatTranscript transcript);
}

class SupportChatAdapter implements ChatTranscriptAdapter {
  const SupportChatAdapter();

  @override
  ConversationThread toThread(LegacyChatTranscript transcript) {
    if (transcript.messages.isEmpty) {
      return ConversationThread(
        ticketId: transcript.ticketId,
        messages: const <ConversationMessage>[],
        participants: const <String>{},
        duration: Duration.zero,
      );
    }

    final List<ConversationMessage> converted =
        transcript.messages.map(_convertMessage).toList(growable: false);
    final Set<String> participants = converted
        .map((ConversationMessage message) => message.author)
        .toSet();
    final DateTime minTimestamp =
        converted.map((message) => message.timestamp).minOrNull ??
            converted.first.timestamp;
    final DateTime maxTimestamp =
        converted.map((message) => message.timestamp).maxOrNull ??
            converted.last.timestamp;

    return ConversationThread(
      ticketId: transcript.ticketId,
      messages: converted,
      participants: participants,
      duration: maxTimestamp.difference(minTimestamp),
    );
  }

  ConversationMessage _convertMessage(LegacyChatMessage message) {
    return ConversationMessage(
      author: _normalizeAuthor(message.sender),
      content: message.body.trim(),
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(message.epochSeconds * 1000),
      visibility:
          message.internal ? MessageVisibility.internal : MessageVisibility.public,
    );
  }

  String _normalizeAuthor(String sender) {
    return sender.replaceAll('_', ' ').trim();
  }
}

void main() {
  const LegacyChatTranscript rawTranscript = LegacyChatTranscript(
    ticketId: 'ticket-4242',
    messages: <LegacyChatMessage>[
      LegacyChatMessage(
        sender: 'customer_jane',
        body: ' 결제가 안 돼요 ',
        epochSeconds: 1,
      ),
      LegacyChatMessage(
        sender: 'agent_park',
        body: '임시 비밀번호를 발급해 드렸습니다.',
        epochSeconds: 120,
      ),
      LegacyChatMessage(
        sender: 'agent_park',
        body: ' 내부 메모: 재발 시 전담팀 알림 ',
        epochSeconds: 130,
        internal: true,
      ),
    ],
  );

  const SupportChatAdapter adapter = SupportChatAdapter();
  final ConversationThread thread = adapter.toThread(rawTranscript);

  print('Ticket: ${thread.ticketId}, participants: ${thread.participants}');
  for (final ConversationMessage message in thread.messages) {
    print(
      '[${message.visibility.name}] ${message.author}: ${message.content}',
    );
  }
  print('Duration: ${thread.duration.inMinutes} minutes');
}
