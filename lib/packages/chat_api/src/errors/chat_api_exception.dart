/// Base exception for chat API failures.
class ChatApiException implements Exception {
  ChatApiException(this.message, {this.code, this.statusCode, this.details});

  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  @override
  String toString() {
    final buffer = StringBuffer('ChatApiException: $message');
    if (code != null) {
      buffer.write(' (code: $code)');
    }
    if (statusCode != null) {
      buffer.write(' [status: $statusCode]');
    }
    if (details != null && details!.isNotEmpty) {
      buffer.write(' details: $details');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a provider is not registered or misconfigured.
class ChatProviderNotFoundException extends ChatApiException {
  ChatProviderNotFoundException(String providerId)
      : super('Chat provider "$providerId" is not registered.');
}

/// Exception thrown when request payloads fail validation.
class ChatValidationException extends ChatApiException {
  ChatValidationException(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
