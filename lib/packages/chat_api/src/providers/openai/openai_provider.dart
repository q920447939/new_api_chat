import '../../chat_api_client.dart';
import '../../chat_api_registry.dart';
import '../../config/chat_api_config.dart';
import '../../errors/chat_api_exception.dart';
import '../../http/chat_http_client.dart';
import '../../providers/chat_provider.dart';
import 'openai_client.dart';
import 'openai_config.dart';

/// OpenAI chat completion provider.
class OpenAIChatProvider implements ChatProvider {
  OpenAIChatProvider();

  static const String providerId = 'openai';

  /// Convenience helper to register the provider with the global registry.
  static void register({bool overrideExisting = false}) {
    ChatApiRegistry.registerProvider(
      OpenAIChatProvider(),
      overrideExisting: overrideExisting,
    );
  }

  @override
  String get id => OpenAIChatProvider.providerId;

  @override
  bool supports(ChatApiConfig config) => config.providerId == id;

  @override
  ChatApiClient createClient(ChatApiConfig config) {
    final normalized = _normalizeConfig(config);
    return OpenAIChatClient(
      httpClient: ChatHttpClient(config: normalized),
    );
  }

  ChatApiConfig _normalizeConfig(ChatApiConfig config) {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      throw ChatValidationException('OpenAI provider requires a non-empty apiKey.');
    }

    if (config is OpenAIConfig) {
      return config;
    }

    return OpenAIConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl ?? OpenAIConfig.defaultBaseUrl,
      requestTimeout: config.requestTimeout,
      defaultHeaders: config.defaultHeaders,
      extras: config.extras,
    );
  }
}
