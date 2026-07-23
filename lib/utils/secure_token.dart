import 'dart:math';

const _tokenCharacters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Generates a cryptographically secure, URL-safe random token (alphanumeric
/// only, so it can be embedded directly in a `user:password@host` URL or used
/// as an HTTP Basic Auth credential without escaping).
String generateSecureToken(int length) {
  final random = Random.secure();
  return List.generate(length, (_) => _tokenCharacters[random.nextInt(_tokenCharacters.length)]).join();
}
