import 'chat_api_client.dart';
import 'config/chat_api_config.dart';
import 'errors/chat_api_exception.dart';
import 'providers/chat_provider.dart';

/// Global registry used to manage chat API providers.
class ChatApiRegistry {
  ChatApiRegistry._();

  static final Map<String, ChatProvider> _providers = {};

  /// Registers a provider. Passing [overrideExisting] overwrites an existing
  /// provider with the same identifier.
  static void registerProvider(
    ChatProvider provider, {
    bool overrideExisting = false,
  }) {
    if (!overrideExisting && _providers.containsKey(provider.id)) {
      throw ArgumentError.value(
        provider.id,
        'provider.id',
        'Provider already registered. Pass `overrideExisting: true` to replace.',
      );
    }
    _providers[provider.id] = provider;
  }

  /// Removes a provider from the registry.
  static void unregisterProvider(String providerId) {
    _providers.remove(providerId);
  }

  /// Clears the provider registry (primarily for testing).
  static void clear() {
    _providers.clear();
  }

  /// Returns true when a provider with the supplied identifier exists.
  static bool isRegistered(String providerId) {
    return _providers.containsKey(providerId);
  }

  /// Creates a [ChatApiClient] using the provider that matches the supplied
  /// configuration.
  static ChatApiClientFactoryResult resolveClient(ChatApiConfig config) {
    final provider = _providers[config.providerId];
    if (provider == null) {
      throw ChatProviderNotFoundException(config.providerId);
    }
    return ChatApiClientFactoryResult(
      provider: provider,
      client: provider.createClient(config),
    );
  }

  /// Returns the registered provider for inspection.
  static ChatProvider? getProvider(String providerId) {
    return _providers[providerId];
  }
}

/// Encapsulates the provider and client returned during resolution.
class ChatApiClientFactoryResult {
  ChatApiClientFactoryResult({
    required this.provider,
    required this.client,
  });

  final ChatProvider provider;
  final ChatApiClient client;
}
