import 'package:dio/dio.dart';

import 'chat_message.dart';

/// Base request object shared by provider specific implementations.
abstract class ChatCompletionRequest {
  const ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.maxOutputTokens,
    this.temperature,
    this.topP,
    this.metadata,
  });

  /// Target model identifier (e.g. `gpt-4.1`).
  final String model;

  /// Ordered list of conversation messages used as context.
  final List<ChatMessage> messages;

  /// Optional output limiting configuration.
  final int? maxOutputTokens;

  /// Optional randomness controls.
  final double? temperature;
  final double? topP;

  /// Arbitrary metadata passed through to provider specific payloads.
  final Map<String, dynamic>? metadata;

  /// Converts the request into a provider compatible JSON payload.
  Map<String, dynamic> toJson();
}

/// Additional configuration applied to a single API invocation.
class ChatRequestOptions {
  ChatRequestOptions({
    this.timeout,
    this.cancelToken,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  })  : headers = Map.unmodifiable(headers ?? const {}),
        queryParameters = Map.unmodifiable(queryParameters ?? const {});

  /// Optional per-request timeout overriding the client defaults.
  final Duration? timeout;

  /// Cancel token forwarded to Dio to support aborting requests and streams.
  final CancelToken? cancelToken;

  /// Headers merged into the default set.
  final Map<String, String> headers;

  /// Additional query parameters appended to the request.
  final Map<String, dynamic> queryParameters;

  ChatRequestOptions copyWith({
    Duration? timeout,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return ChatRequestOptions(
      timeout: timeout ?? this.timeout,
      cancelToken: cancelToken ?? this.cancelToken,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
    );
  }
}

/// Unified representation of a chat completion response.
class ChatCompletionResult {
  const ChatCompletionResult({
    required this.messages,
    this.finishReason,
    this.usage,
    this.rawResponse,
  });

  /// Final set of assistant messages returned by the provider.
  final List<ChatMessage> messages;

  /// Provider specific termination reason (e.g. `stop`, `length`).
  final String? finishReason;

  /// Token usage information when available.
  final ChatUsage? usage;

  /// Raw payload returned by the provider.
  final Map<String, dynamic>? rawResponse;
}

/// Token usage metadata.
class ChatUsage {
  const ChatUsage({
    required this.inputTokens,
    required this.outputTokens,
    this.totalTokens,
  });

  final int inputTokens;
  final int outputTokens;
  final int? totalTokens;

  factory ChatUsage.fromJson(Map<String, dynamic> json) {
    return ChatUsage(
      inputTokens: json['prompt_tokens'] as int? ?? json['input_tokens'] as int? ?? 0,
      outputTokens: json['completion_tokens'] as int? ?? json['output_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int?,
    );
  }
}
