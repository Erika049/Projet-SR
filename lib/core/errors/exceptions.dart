/// Exceptions levées par la couche data, converties en [Failure]
/// dans les implémentations de repository.
class ServerException implements Exception {
  const ServerException([this.message]);
  final String? message;
}

class NetworkException implements Exception {
  const NetworkException([this.message]);

  /// Message à afficher (serveur injoignable, réponse trop lente…) ; message générique si null.
  final String? message;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class CacheException implements Exception {
  const CacheException();
}
