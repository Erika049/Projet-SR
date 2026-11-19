import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../entities/establishment.dart';
import '../repositories/auth_repository.dart';

class Login implements UseCase<AppUser, ({String identifier, String password})> {
  const Login(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<AppUser>> call(({String identifier, String password}) p) =>
      _repo.login(identifier: p.identifier.trim(), password: p.password);
}

typedef RegisterParams = ({String fullName, String phone, String? email, String password});

class RegisterParent implements UseCase<AppUser?, RegisterParams> {
  const RegisterParent(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<AppUser?>> call(RegisterParams p) => _repo.registerParent(
    fullName: p.fullName.trim(),
    phone: p.phone.trim(),
    email: (p.email?.trim().isEmpty ?? true) ? null : p.email!.trim(),
    password: p.password,
  );
}

class VerifyOtp implements UseCase<AppUser, ({String phone, String code})> {
  const VerifyOtp(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<AppUser>> call(({String phone, String code}) p) => _repo.verifyOtp(phone: p.phone, code: p.code);
}

class ResendOtp implements UseCase<void, String> {
  const ResendOtp(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<void>> call(String phone) => _repo.resendOtp(phone);
}

class RequestPasswordReset implements UseCase<void, String> {
  const RequestPasswordReset(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<void>> call(String identifier) => _repo.requestPasswordReset(identifier.trim());
}

class VerifyResetCode implements UseCase<String, ({String phone, String code})> {
  const VerifyResetCode(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<String>> call(({String phone, String code}) p) =>
      _repo.verifyResetCode(phone: p.phone.trim(), code: p.code.trim());
}

typedef ResetPasswordParams = ({String resetToken, String password, String confirmation});

/// Choix du nouveau mot de passe : au moins 8 caractères (règle du serveur), saisi deux fois à l'identique.
class ResetPassword implements UseCase<void, ResetPasswordParams> {
  const ResetPassword(this._repo);
  final AuthRepository _repo;

  static const minLength = 8;

  @override
  Future<Result<void>> call(ResetPasswordParams p) async {
    if (p.password.length < minLength) {
      return const Err(ValidationFailure('Le mot de passe doit contenir au moins $minLength caractères.'));
    }
    if (p.password != p.confirmation) {
      return const Err(ValidationFailure('Les deux mots de passe ne correspondent pas.'));
    }
    return _repo.resetPassword(resetToken: p.resetToken, newPassword: p.password);
  }
}

class RestoreSession implements UseCase<AppUser?, NoParams> {
  const RestoreSession(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<AppUser?>> call(NoParams _) => _repo.restoreSession();
}

class GetEstablishments implements UseCase<List<Establishment>, NoParams> {
  const GetEstablishments(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<List<Establishment>>> call(NoParams _) => _repo.getEstablishments();
}

class SelectEstablishment {
  const SelectEstablishment(this._repo);
  final AuthRepository _repo;

  Future<void> call(Establishment e) => _repo.selectEstablishment(e);
}

class GetSelectedEstablishment {
  const GetSelectedEstablishment(this._repo);
  final AuthRepository _repo;

  Future<Establishment?> call() => _repo.getSelectedEstablishment();
}

class Logout {
  const Logout(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.logout();
}
