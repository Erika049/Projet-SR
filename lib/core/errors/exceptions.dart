/// Exceptions levées par la couche data, converties en [Failure]
/// dans les implémentations de repository.
class ServerException implements Exception {
  const ServerException([this.message]);
  final String? message;
}

class NetworkException implements Exception {
  const NetworkException();
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
