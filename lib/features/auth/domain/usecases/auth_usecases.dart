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

class RegisterParent implements UseCase<void, RegisterParams> {
  const RegisterParent(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<void>> call(RegisterParams p) => _repo.registerParent(
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
