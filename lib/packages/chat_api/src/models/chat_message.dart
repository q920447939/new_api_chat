/// Role of the message within a chat completion request/response.
enum ChatMessageRole {
  system,
  user,
  assistant,
  tool,
}

/// Base class for chat message content segments.
abstract class ChatContentPart {
  const ChatContentPart({required this.kind});

  /// Semantic identifier of the content (e.g. `text`, `image`, `tool_call`).
  final String kind;

  Map<String, dynamic> toJson();
}

/// Text content segment.
class ChatTextContent extends ChatContentPart {
  const ChatTextContent(this.text) : super(kind: 'text');

  final String text;

  @override
  Map<String, dynamic> toJson() => {'type': kind, 'text': text};
}

/// A single message within the conversation.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.contentParts,
    this.name,
    this.metadata,
  });

  ChatMessage.text({
    required ChatMessageRole role,
    required String text,
    String? name,
    Map<String, dynamic>? metadata,
  }) : this(
          role: role,
          contentParts: [ChatTextContent(text)],
          name: name,
          metadata: metadata,
        );

  final ChatMessageRole role;
  final String? name;
  final List<ChatContentPart> contentParts;
  final Map<String, dynamic>? metadata;

  /// Converts the message to a JSON payload. Providers can adapt or extend
  /// this representation as needed.
  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      if (name != null) 'name': name,
      'content': contentParts.map((part) => part.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    ChatMessageRole? role,
    String? name,
    List<ChatContentPart>? contentParts,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      name: name ?? this.name,
      contentParts: contentParts ?? this.contentParts,
      metadata: metadata ?? this.metadata,
    );
  }
}
