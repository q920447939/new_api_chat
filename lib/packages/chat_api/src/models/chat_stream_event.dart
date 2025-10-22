import 'chat_completion.dart';
import 'chat_message.dart';

/// Event emitted from a streaming chat completion request.
class ChatStreamEvent {
  const ChatStreamEvent._({
    required this.type,
    this.delta,
    this.result,
    this.error,
  });

  /// Creates a delta event representing incremental content.
  factory ChatStreamEvent.delta(ChatDelta delta) {
    return ChatStreamEvent._(type: ChatStreamEventType.delta, delta: delta);
  }

  /// Creates a terminal event carrying the final aggregated result.
  factory ChatStreamEvent.done(ChatCompletionResult result) {
    return ChatStreamEvent._(type: ChatStreamEventType.done, result: result);
  }

  /// Creates an error event.
  factory ChatStreamEvent.error(Object error) {
    return ChatStreamEvent._(type: ChatStreamEventType.error, error: error);
  }

  final ChatStreamEventType type;
  final ChatDelta? delta;
  final ChatCompletionResult? result;
  final Object? error;

  bool get isDelta => type == ChatStreamEventType.delta;
  bool get isDone => type == ChatStreamEventType.done;
  bool get isError => type == ChatStreamEventType.error;
}

/// Type of the stream event.
enum ChatStreamEventType {
  delta,
  done,
  error,
}

/// Delta payload emitted during streaming calls.
class ChatDelta {
  const ChatDelta({
    this.role,
    this.content,
    this.toolCalls,
    this.finishReason,
    this.metadata,
  });

  final ChatMessageRole? role;
  final String? content;
  final List<ChatToolCallDelta>? toolCalls;
  final String? finishReason;
  final Map<String, dynamic>? metadata;
}

/// Partial tool call information emitted during streaming.
class ChatToolCallDelta {
  const ChatToolCallDelta({
    required this.id,
    required this.type,
    this.name,
    this.argumentsDelta,
  });

  final String id;
  final String type;
  final String? name;
  final String? argumentsDelta;
}
