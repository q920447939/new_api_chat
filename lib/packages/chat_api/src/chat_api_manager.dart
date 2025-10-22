import 'chat_api_client.dart';
import 'chat_api_registry.dart';
import 'config/chat_api_config.dart';
import 'models/chat_completion.dart';
import 'models/chat_stream_event.dart';

/// High level facade that resolves the correct client using the registry and
/// exposes a simple API surface to the rest of the application.
class ChatApiManager {
  ChatApiManager(this._config)
      : _resolved = ChatApiRegistry.resolveClient(_config);

  final ChatApiConfig _config;
  final ChatApiClientFactoryResult _resolved;

  ChatApiClient get client => _resolved.client;
  String get providerId => _resolved.provider.id;

  Future<ChatCompletionResult> createChatCompletion(
    ChatCompletionRequest request, {
    ChatRequestOptions? options,
  }) {
    return client.createChatCompletion(request, options: options);
  }

  Stream<ChatStreamEvent> createChatCompletionStream(
    ChatCompletionRequest request, {
    ChatRequestOptions? options,
  }) {
    return client.createChatCompletionStream(request, options: options);
  }
}
