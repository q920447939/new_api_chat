import 'dart:async';

import 'models/chat_completion.dart';
import 'models/chat_stream_event.dart';

/// Defines the primary contract every chat API client should follow.
abstract interface class ChatApiClient {
  /// Identifier of the provider implementation (e.g. `openai`).
  String get providerId;

  /// Performs a single response chat completion request.
  Future<ChatCompletionResult> createChatCompletion(
    ChatCompletionRequest request, {
    ChatRequestOptions? options,
  });

  /// Performs a streaming chat completion request.
  Stream<ChatStreamEvent> createChatCompletionStream(
    ChatCompletionRequest request, {
    ChatRequestOptions? options,
  });
}
