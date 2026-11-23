import '../errors/exceptions.dart';
import '../errors/failures.dart';

/// Résultat d'une opération : succès ([Ok]) ou échec ([Err]).
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onError, R Function(T value) onOk) => switch (this) {
    Ok<T>(:final value) => onOk(value),
    Err<T>(:final failure) => onError(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Exécute un appel de la couche data et convertit les exceptions en [Failure].
/// Utilisé par toutes les implémentations de repository.
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on NetworkException catch (e) {
    return Err(e.message == null ? const NetworkFailure() : NetworkFailure(e.message!));
  } on UnauthorizedException {
    return const Err(SessionExpiredFailure());
  } on AuthException catch (e) {
    return Err(AuthFailure(e.message));
  } on CacheException {
    return const Err(CacheFailure());
  } on ServerException catch (e) {
    return Err(e.message == null ? const ServerFailure() : ServerFailure(e.message!));
  }
}
