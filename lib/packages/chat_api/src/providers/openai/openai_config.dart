import '../../config/chat_api_config.dart';
import 'openai_provider.dart';

/// Configuration parameters specific to OpenAI chat completions.
class OpenAIConfig extends ChatApiConfig {
  OpenAIConfig({
    required String apiKey,
    String? baseUrl,
    Duration? requestTimeout,
    Map<String, String>? defaultHeaders,
    Map<String, dynamic>? extras,
  }) : super(
          providerId: OpenAIChatProvider.providerId,
          apiKey: apiKey,
          baseUrl: baseUrl ?? defaultBaseUrl,
          requestTimeout: requestTimeout,
          defaultHeaders: {
            'Content-Type': 'application/json',
            if (defaultHeaders != null) ...defaultHeaders,
          },
          extras: extras,
        );

  static const String defaultBaseUrl = 'https://api.openai.com/v1';
}
