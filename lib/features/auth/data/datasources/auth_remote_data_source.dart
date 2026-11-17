import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> login(String identifier, String password);
  Future<void> registerParent(String fullName, String phone, String? email, String password);
  Future<AuthSession> verifyOtp(String phone, String code);
  Future<void> resendOtp(String phone);
  Future<void> requestPasswordReset(String identifier);

  /// Vérifie le code SMS de réinitialisation et renvoie un jeton à usage unique.
  Future<String> verifyResetCode(String phone, String code);

  /// Enregistre le nouveau mot de passe avec le jeton obtenu par [verifyResetCode].
  Future<void> resetPassword(String resetToken, String newPassword);
  Future<List<EstablishmentModel>> getEstablishments();
}

/// Implémentation HTTP. Les chemins sont à aligner avec l'API du backend.
class AuthApiDataSource implements AuthRemoteDataSource {
  const AuthApiDataSource(this._api);
  final ApiClient _api;

  AuthSession _session(dynamic json) =>
      (token: json['access_token'] as String, user: UserModel.fromJson(json['utilisateur'] as Map<String, dynamic>));

  @override
  Future<AuthSession> login(String identifier, String password) async =>
      _session(await _api.post('/auth/login', data: {'identifiant': identifier, 'mot_de_passe': password}));

  @override
  Future<void> registerParent(String fullName, String phone, String? email, String password) => _api.post(
    '/auth/register',
    data: {'nom_complet': fullName, 'telephone': phone, 'email': email, 'mot_de_passe': password},
  );

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async =>
      _session(await _api.post('/auth/otp/verify', data: {'telephone': phone, 'code': code}));

  @override
  Future<void> resendOtp(String phone) => _api.post('/auth/otp/resend', data: {'telephone': phone});

  @override
  Future<void> requestPasswordReset(String identifier) =>
      _api.post('/auth/password/forgot', data: {'identifiant': identifier});

  @override
  Future<String> verifyResetCode(String phone, String code) async {
    final json = await _api.post('/auth/password/verify', data: {'telephone': phone, 'code': code});
    return json['reset_token'] as String;
  }

  @override
  Future<void> resetPassword(String resetToken, String newPassword) =>
      _api.post('/auth/password/reset', data: {'reset_token': resetToken, 'mot_de_passe': newPassword});

  @override
  Future<List<EstablishmentModel>> getEstablishments() async {
    final list = await _api.get('/me/etablissements') as List;
    return list.map((e) => EstablishmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
