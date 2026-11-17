import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/establishment.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<AppUser>> login({required String identifier, required String password}) => guard(() async {
    final session = await _remote.login(identifier, password);
    await _local.saveSession(session);
    return session.user;
  });

  @override
  Future<Result<void>> registerParent({
    required String fullName,
    required String phone,
    String? email,
    required String password,
  }) => guard(() => _remote.registerParent(fullName, phone, email, password));

  @override
  Future<Result<AppUser>> verifyOtp({required String phone, required String code}) => guard(() async {
    final session = await _remote.verifyOtp(phone, code);
    await _local.saveSession(session);
    return session.user;
  });

  @override
  Future<Result<void>> resendOtp(String phone) => guard(() => _remote.resendOtp(phone));

  @override
  Future<Result<void>> requestPasswordReset(String identifier) => guard(() => _remote.requestPasswordReset(identifier));

  @override
  Future<Result<String>> verifyResetCode({required String phone, required String code}) =>
      guard(() => _remote.verifyResetCode(phone, code));

  @override
  Future<Result<void>> resetPassword({required String resetToken, required String newPassword}) =>
      guard(() => _remote.resetPassword(resetToken, newPassword));

  @override
  Future<Result<AppUser?>> restoreSession() async => Ok(_local.readUser());

  @override
  Future<Result<List<Establishment>>> getEstablishments() => guard(_remote.getEstablishments);

  @override
  Future<Establishment?> getSelectedEstablishment() async => _local.readEstablishment();

  @override
  Future<void> selectEstablishment(Establishment establishment) =>
      _local.saveEstablishment(EstablishmentModel.fromEntity(establishment));

  @override
  Future<void> logout() => _local.clear();
}
