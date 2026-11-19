import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../entities/establishment.dart';

abstract interface class AuthRepository {
  /// Connexion par téléphone ou email (CU-PAR-01, CU-ENS-01).
  Future<Result<AppUser>> login({required String identifier, required String password});

  /// Création d'un compte parent. Retourne l'utilisateur si le serveur ouvre directement
  /// la session (backend actuel), ou `null` si un code SMS doit d'abord être vérifié.
  Future<Result<AppUser?>> registerParent({
    required String fullName,
    required String phone,
    String? email,
    required String password,
  });

  /// Étape 2 : vérifie le code OTP et ouvre la session.
  Future<Result<AppUser>> verifyOtp({required String phone, required String code});

  Future<Result<void>> resendOtp(String phone);

  /// Mot de passe oublié, étape 1 : demande l'envoi d'un code par SMS.
  Future<Result<void>> requestPasswordReset(String identifier);

  /// Étape 2 : vérifie le code et renvoie un jeton de réinitialisation.
  Future<Result<String>> verifyResetCode({required String phone, required String code});

  /// Étape 3 : enregistre le nouveau mot de passe.
  Future<Result<void>> resetPassword({required String resetToken, required String newPassword});

  /// Relit la session enregistrée sur le téléphone (null si aucune).
  Future<Result<AppUser?>> restoreSession();

  /// Établissements de l'enseignant connecté.
  Future<Result<List<Establishment>>> getEstablishments();

  Future<Establishment?> getSelectedEstablishment();

  Future<void> selectEstablishment(Establishment establishment);

  Future<void> logout();
}
