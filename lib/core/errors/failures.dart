import 'package:equatable/equatable.dart';

/// Erreurs vues par les couches domain et presentation.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Réseau lent ou indisponible.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Le réseau est trop lent ou indisponible.']);
}

/// Erreur renvoyée par le serveur.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Une erreur est survenue. Réessayez plus tard.']);
}

/// Identifiants invalides, code OTP incorrect, etc.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Session expirée : l'utilisateur doit se reconnecter.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message = 'Session expirée.']);
}

/// Données saisies refusées (note hors barème, champ manquant…).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Aucune donnée en cache.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Aucune donnée disponible hors connexion.']);
}
