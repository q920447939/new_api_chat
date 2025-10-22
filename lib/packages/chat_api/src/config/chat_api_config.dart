/// Base configuration shared by chat API providers.
class ChatApiConfig {
  ChatApiConfig({
    required this.providerId,
    this.baseUrl,
    this.apiKey,
    this.requestTimeout,
    Map<String, String>? defaultHeaders,
    Map<String, dynamic>? extras,
  })  : defaultHeaders = Map.unmodifiable(defaultHeaders ?? const {}),
        extras = Map.unmodifiable(extras ?? const {});

  /// Unique identifier for the target provider (e.g. `openai`).
  final String providerId;

  /// Optional base URL for the provider. Implementations can fallback to their
  /// own defaults when this value is null.
  final String? baseUrl;

  /// Common API key or bearer token used for authentication.
  final String? apiKey;

  /// Default timeout applied to individual requests if not overridden.
  final Duration? requestTimeout;

  /// Headers injected into every HTTP call.
  final Map<String, String> defaultHeaders;

  /// Additional provider-specific configuration payload.
  final Map<String, dynamic> extras;

  /// Returns a copy with overridden values.
  ChatApiConfig copyWith({
    String? providerId,
    String? baseUrl,
    String? apiKey,
    Duration? requestTimeout,
    Map<String, String>? defaultHeaders,
    Map<String, dynamic>? extras,
  }) {
    return ChatApiConfig(
      providerId: providerId ?? this.providerId,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      extras: extras ?? this.extras,
    );
  }
}
