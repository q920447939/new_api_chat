import '../chat_api_client.dart';
import '../config/chat_api_config.dart';

/// Factory contract for registering and instantiating provider specific
/// chat API clients.
abstract interface class ChatProvider {
  /// Unique identifier used to resolve this provider at runtime.
  String get id;

  /// Returns true if the provider can handle the supplied configuration.
  bool supports(ChatApiConfig config) => config.providerId == id;

  /// Creates a new [ChatApiClient] based on the provided configuration.
  ChatApiClient createClient(ChatApiConfig config);
}
