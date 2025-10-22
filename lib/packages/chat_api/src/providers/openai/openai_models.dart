import 'dart:convert';

import '../../errors/chat_api_exception.dart';
import '../../models/chat_completion.dart';
import '../../models/chat_message.dart';
import '../../models/chat_stream_event.dart';

/// OpenAI specific chat completion request payload.
class OpenAIChatCompletionRequest extends ChatCompletionRequest {
  OpenAIChatCompletionRequest({
    required super.model,
    required super.messages,
    super.maxOutputTokens,
    super.temperature,
    super.topP,
    super.metadata,
    this.stop,
    this.frequencyPenalty,
    this.presencePenalty,
    this.logitBias,
    this.responseFormat,
    this.stream = false,
    this.additionalParams,
  });

  final List<String>? stop;
  final double? frequencyPenalty;
  final double? presencePenalty;
  final Map<String, dynamic>? logitBias;
  final Map<String, dynamic>? responseFormat;
  final bool stream;
  final Map<String, dynamic>? additionalParams;

  OpenAIChatCompletionRequest copyWith({
    String? model,
    List<ChatMessage>? messages,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    Map<String, dynamic>? metadata,
    List<String>? stop,
    double? frequencyPenalty,
    double? presencePenalty,
    Map<String, dynamic>? logitBias,
    Map<String, dynamic>? responseFormat,
    bool? stream,
    Map<String, dynamic>? additionalParams,
  }) {
    return OpenAIChatCompletionRequest(
      model: model ?? this.model,
      messages: messages ?? this.messages,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      metadata: metadata ?? this.metadata,
      stop: stop ?? this.stop,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      logitBias: logitBias ?? this.logitBias,
      responseFormat: responseFormat ?? this.responseFormat,
      stream: stream ?? this.stream,
      additionalParams: additionalParams ?? this.additionalParams,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map(OpenAIMessageMapper.toRequestJson).toList(),
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (maxOutputTokens != null) 'max_tokens': maxOutputTokens,
      if (stop != null) 'stop': stop,
      if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
      if (presencePenalty != null) 'presence_penalty': presencePenalty,
      if (logitBias != null) 'logit_bias': logitBias,
      if (responseFormat != null) 'response_format': responseFormat,
      'stream': stream,
      if (metadata != null) 'metadata': metadata,
      if (additionalParams != null) ...additionalParams!,
    };
  }
}

class OpenAIChatCompletionResponse {
  OpenAIChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.systemFingerprint,
    this.usage,
    Map<String, dynamic>? raw,
  }) : raw = raw ?? const {};

  factory OpenAIChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return OpenAIChatCompletionResponse(
      id: json['id'] as String,
      object: json['object'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? '',
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map((choice) => OpenAIChatChoice.fromJson(choice as Map<String, dynamic>))
          .toList(),
      systemFingerprint: json['system_fingerprint'] as String?,
      usage: json['usage'] != null
          ? OpenAIUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      raw: json,
    );
  }

  final String id;
  final String object;
  final int created;
  final String model;
  final List<OpenAIChatChoice> choices;
  final String? systemFingerprint;
  final OpenAIUsage? usage;
  final Map<String, dynamic> raw;

  ChatCompletionResult toChatCompletionResult() {
    return ChatCompletionResult(
      messages: choices
          .map((choice) => choice.message.toChatMessage())
          .toList(),
      finishReason: choices.isNotEmpty ? choices.first.finishReason : null,
      usage: usage?.toUsage(),
      rawResponse: raw,
    );
  }
}

class OpenAIChatChoice {
  OpenAIChatChoice({
    required this.index,
    required this.message,
    this.finishReason,
    this.logprobs,
  });

  factory OpenAIChatChoice.fromJson(Map<String, dynamic> json) {
    return OpenAIChatChoice(
      index: json['index'] as int? ?? 0,
      message: OpenAIChatMessage.fromJson(json['message'] as Map<String, dynamic>),
      finishReason: json['finish_reason'] as String?,
      logprobs: json['logprobs'],
    );
  }

  final int index;
  final OpenAIChatMessage message;
  final String? finishReason;
  final dynamic logprobs;
}

class OpenAIChatMessage {
  OpenAIChatMessage({
    required this.role,
    required this.contentParts,
    this.name,
    this.toolCalls,
  });

  factory OpenAIChatMessage.fromJson(Map<String, dynamic> json) {
    final dynamic content = json['content'];
    final List<ChatContentPart> parts = switch (content) {
      final String text => [ChatTextContent(text)],
      final List list => list
          .whereType<Map<String, dynamic>>()
          .map(OpenAIMessageMapper.toContentPart)
          .toList(),
      _ => const [],
    };
    return OpenAIChatMessage(
      role: OpenAIMessageMapper.roleFromString(json['role'] as String?),
      contentParts: parts,
      name: json['name'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map(
            (e) => OpenAIToolCall.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final ChatMessageRole role;
  final List<ChatContentPart> contentParts;
  final String? name;
  final List<OpenAIToolCall>? toolCalls;

  ChatMessage toChatMessage() {
    return ChatMessage(
      role: role,
      contentParts: contentParts,
      name: name,
      metadata: {
        if (toolCalls != null)
          'tool_calls': toolCalls!.map((e) => e.toJson()).toList(),
      },
    );
  }
}

class OpenAIToolCall {
  OpenAIToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  factory OpenAIToolCall.fromJson(Map<String, dynamic> json) {
    return OpenAIToolCall(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'function',
      function: OpenAIFunctionCall.fromJson(
        json['function'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final String id;
  final String type;
  final OpenAIFunctionCall function;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'function': function.toJson(),
    };
  }
}

class OpenAIFunctionCall {
  OpenAIFunctionCall({
    required this.name,
    required this.arguments,
  });

  factory OpenAIFunctionCall.fromJson(Map<String, dynamic> json) {
    return OpenAIFunctionCall(
      name: json['name'] as String? ?? '',
      arguments: json['arguments'] as String? ?? '',
    );
  }

  final String name;
  final String arguments;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'arguments': arguments,
    };
  }
}

class OpenAIUsage {
  OpenAIUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory OpenAIUsage.fromJson(Map<String, dynamic> json) {
    return OpenAIUsage(
      promptTokens: json['prompt_tokens'] as int? ?? 0,
      completionTokens: json['completion_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
    );
  }

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  ChatUsage toUsage() {
    return ChatUsage(
      inputTokens: promptTokens,
      outputTokens: completionTokens,
      totalTokens: totalTokens,
    );
  }
}

/// Streaming response chunk.
class OpenAIChatCompletionChunk {
  OpenAIChatCompletionChunk({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.systemFingerprint,
    this.usage,
    Map<String, dynamic>? raw,
  }) : raw = raw ?? const {};

  factory OpenAIChatCompletionChunk.fromJson(Map<String, dynamic> json) {
    return OpenAIChatCompletionChunk(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      created: json['created'] as int? ?? 0,
      model: json['model'] as String? ?? '',
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map(
            (choice) => OpenAIChatCompletionDeltaChoice.fromJson(
              choice as Map<String, dynamic>,
            ),
          )
          .toList(),
      systemFingerprint: json['system_fingerprint'] as String?,
      usage: json['usage'] != null
          ? OpenAIUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      raw: json,
    );
  }

  final String id;
  final String object;
  final int created;
  final String model;
  final List<OpenAIChatCompletionDeltaChoice> choices;
  final String? systemFingerprint;
  final OpenAIUsage? usage;
  final Map<String, dynamic> raw;
}

class OpenAIChatCompletionDeltaChoice {
  OpenAIChatCompletionDeltaChoice({
    required this.index,
    required this.delta,
    this.finishReason,
    this.logprobs,
  });

  factory OpenAIChatCompletionDeltaChoice.fromJson(Map<String, dynamic> json) {
    return OpenAIChatCompletionDeltaChoice(
      index: json['index'] as int? ?? 0,
      delta: OpenAIDelta.fromJson(json['delta'] as Map<String, dynamic>? ?? const {}),
      finishReason: json['finish_reason'] as String?,
      logprobs: json['logprobs'],
    );
  }

  final int index;
  final OpenAIDelta delta;
  final String? finishReason;
  final dynamic logprobs;
}

class OpenAIDelta {
  OpenAIDelta({
    this.role,
    this.content,
    this.toolCalls,
  });

  factory OpenAIDelta.fromJson(Map<String, dynamic> json) {
    return OpenAIDelta(
      role: json['role'] as String?,
      content: json['content'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map(
            (e) => OpenAIToolCallDelta.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String? role;
  final String? content;
  final List<OpenAIToolCallDelta>? toolCalls;
}

class OpenAIToolCallDelta {
  OpenAIToolCallDelta({
    required this.index,
    this.id,
    this.type,
    this.function,
  });

  factory OpenAIToolCallDelta.fromJson(Map<String, dynamic> json) {
    return OpenAIToolCallDelta(
      index: json['index'] as int? ?? 0,
      id: json['id'] as String?,
      type: json['type'] as String?,
      function: json['function'] != null
          ? OpenAIFunctionCallDelta.fromJson(
              json['function'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int index;
  final String? id;
  final String? type;
  final OpenAIFunctionCallDelta? function;
}

class OpenAIFunctionCallDelta {
  OpenAIFunctionCallDelta({
    this.name,
    this.arguments,
  });

  factory OpenAIFunctionCallDelta.fromJson(Map<String, dynamic> json) {
    return OpenAIFunctionCallDelta(
      name: json['name'] as String?,
      arguments: json['arguments'] as String? ?? '',
    );
  }

  final String? name;
  final String? arguments;
}

/// Helper responsible for translating between domain `ChatMessage` structures
/// and OpenAI specific payloads.
class OpenAIMessageMapper {
  static Map<String, dynamic> toRequestJson(ChatMessage message) {
    final List<Map<String, dynamic>> serializedContent = message.contentParts
        .map((part) {
          if (part is ChatTextContent) {
            return {
              'type': part.kind,
              'text': part.text,
            };
          }
          return part.toJson();
        })
        .toList();

    // Fall back to legacy representation when only a single text segment is present.
    dynamic contentPayload;
    if (serializedContent.length == 1 && serializedContent.first['type'] == 'text') {
      contentPayload = serializedContent.first['text'];
    } else {
      contentPayload = serializedContent;
    }

    return {
      'role': message.role.name,
      if (message.name != null) 'name': message.name,
      'content': contentPayload,
      if (message.metadata != null) 'metadata': message.metadata,
    };
  }

  static ChatContentPart toContentPart(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'text';
    if (type == 'text') {
      return ChatTextContent(json['text'] as String? ?? '');
    }
    return _OpenAIUnsupportedContentPart(type, json);
  }

  static ChatMessageRole roleFromString(String? role) {
    return switch (role) {
      'system' => ChatMessageRole.system,
      'assistant' => ChatMessageRole.assistant,
      'tool' => ChatMessageRole.tool,
      _ => ChatMessageRole.user,
    };
  }
}

class _OpenAIUnsupportedContentPart extends ChatContentPart {
  _OpenAIUnsupportedContentPart(this.typeName, this.raw)
      : super(kind: typeName);

  final String typeName;
  final Map<String, dynamic> raw;

  @override
  Map<String, dynamic> toJson() => raw;
}

/// Parses a single SSE payload into a [OpenAIChatCompletionChunk]. Returns null
/// when the payload signals the end of the stream.
OpenAIChatCompletionChunk? parseOpenAIStreamEvent(String payload) {
  final trimmed = payload.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed == '[DONE]') {
    return null;
  }

  try {
    final decoded = json.decode(trimmed) as Map<String, dynamic>;
    return OpenAIChatCompletionChunk.fromJson(decoded);
  } on FormatException catch (error) {
    throw ChatApiException(
      'Failed to decode OpenAI stream payload: $trimmed',
      details: {'error': error.message},
    );
  }
}
