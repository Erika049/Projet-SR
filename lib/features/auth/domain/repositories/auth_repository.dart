import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../entities/establishment.dart';

abstract interface class AuthRepository {
  /// Connexion par téléphone ou email (CU-PAR-01, CU-ENS-01).
  Future<Result<AppUser>> login({required String identifier, required String password});

  /// Étape 1 de la création d'un compte parent : envoie un code OTP par SMS.
  Future<Result<void>> registerParent({
    required String fullName,
    required String phone,
    String? email,
    required String password,
  });

  /// Étape 2 : vérifie le code OTP et ouvre la session.
  Future<Result<AppUser>> verifyOtp({required String phone, required String code});

  Future<Result<void>> resendOtp(String phone);

  Future<Result<void>> requestPasswordReset(String identifier);

  /// Relit la session enregistrée sur le téléphone (null si aucune).
  Future<Result<AppUser?>> restoreSession();

  /// Établissements de l'enseignant connecté.
  Future<Result<List<Establishment>>> getEstablishments();

  Future<Establishment?> getSelectedEstablishment();

  Future<void> selectEstablishment(Establishment establishment);

  Future<void> logout();
}
