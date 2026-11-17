import '../utils/result.dart';

/// Contrat commun à tous les cas d'utilisation.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Paramètre vide pour les cas d'utilisation sans argument.
class NoParams {
  const NoParams();
}
