import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_json.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> login(String identifier, String password);

  /// Retourne la session si le serveur l'ouvre directement, `null` si un code SMS doit être vérifié.
  Future<AuthSession?> registerParent(String fullName, String phone, String? email, String password);
  Future<AuthSession> verifyOtp(String phone, String code);
  Future<void> resendOtp(String phone);
  Future<void> requestPasswordReset(String identifier);

  /// Vérifie le code SMS de réinitialisation et renvoie un jeton à usage unique.
  Future<String> verifyResetCode(String phone, String code);

  /// Enregistre le nouveau mot de passe avec le jeton obtenu par [verifyResetCode].
  Future<void> resetPassword(String resetToken, String newPassword);
  Future<List<EstablishmentModel>> getEstablishments();
}

/// Backend SchoolConnect (`/api/v1/auth/*`, voir Swagger).
class AuthApiDataSource implements AuthRemoteDataSource {
  const AuthApiDataSource(this._api);
  final ApiClient _api;

  /// `AuthResponse` : `{token, tokenType, expiresIn, user: UserView}`.
  AuthSession _session(dynamic json) {
    final j = ApiJson.map(json);
    return (token: j['token'] as String, user: UserModel.fromApi(ApiJson.map(j['user'])));
  }

  /// Numéro camerounais sous une forme unique (+2376XXXXXXXX), à l'inscription comme à la connexion.
  /// Un email est envoyé tel quel.
  static String normalizeIdentifier(String value) {
    final v = value.trim();
    if (v.contains('@')) return v;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    final local = digits.length > 9 ? digits.substring(digits.length - 9) : digits;
    return local.length == 9 ? '+237$local' : v;
  }

  @override
  Future<AuthSession> login(String identifier, String password) async => _session(
    await _api.post('/auth/login', data: {'identifiant': normalizeIdentifier(identifier), 'motDePasse': password}),
  );

  @override
  Future<AuthSession?> registerParent(String fullName, String phone, String? email, String password) async {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final json = await _api.post(
      '/auth/register',
      data: {
        'prenom': parts.first,
        'nom': parts.skip(1).join(' '),
        'telephone': normalizeIdentifier(phone),
        if (email != null && email.isNotEmpty) 'email': email,
        'motDePasse': password,
        'langue': 'fr',
      },
    );
    return _session(json);
  }

  // Le backend ouvre la session dès l'inscription : pas de code SMS.
  @override
  Future<AuthSession> verifyOtp(String phone, String code) => notAvailableOnServer('La vérification par SMS');

  @override
  Future<void> resendOtp(String phone) => notAvailableOnServer('L’envoi de code par SMS');

  /// `POST /auth/mot-de-passe-oublie` : le serveur répond de la même façon que le numéro soit inscrit
  /// ou non, et envoie un code à 6 chiffres par SMS s'il l'est.
  @override
  Future<void> requestPasswordReset(String identifier) =>
      _api.post('/auth/mot-de-passe-oublie', data: {'identifiant': normalizeIdentifier(identifier)});

  /// `POST /auth/mot-de-passe-oublie/verifier` → jeton à usage unique (15 min).
  @override
  Future<String> verifyResetCode(String phone, String code) async {
    final json = ApiJson.map(
      await _api.post('/auth/mot-de-passe-oublie/verifier', data: {'identifiant': normalizeIdentifier(phone), 'code': code}),
    );
    final token = json['jeton'] as String?;
    if (token == null || token.isEmpty) throw const ServerException('Code incorrect ou expiré.');
    return token;
  }

  @override
  Future<void> resetPassword(String resetToken, String newPassword) =>
      _api.post('/auth/mot-de-passe-oublie/reinitialiser', data: {'jeton': resetToken, 'motDePasse': newPassword});

  /// Établissements où l'utilisateur a le rôle ENSEIGNANT (`GET /auth/me`),
  /// avec leur nom, le nombre de classes et la matière enseignée.
  @override
  Future<List<EstablishmentModel>> getEstablishments() async {
    final me = ApiJson.map(await _api.get('/auth/me'));
    final ids = <String>{
      for (final r in ApiJson.list(me['roles']))
        if (r['role'] == 'ENSEIGNANT' && r['etablissementId'] is String) r['etablissementId'] as String,
    };
    return [for (final id in ids) await _establishment(id)];
  }

  Future<EstablishmentModel> _establishment(String id) async {
    Future<dynamic> tryGet(String path) async {
      try {
        return await _api.get(path);
      } on ServerException {
        return null; // Accès refusé ou introuvable : on affiche ce qu'on a.
      }
    }

    final etab = ApiJson.map(await tryGet('/etablissements/$id'));
    final assignments = ApiJson.list(await tryGet('/etablissements/$id/mes-affectations'));
    final subjects = {for (final m in ApiJson.list(await tryGet('/etablissements/$id/matieres'))) m['id']: m['nom']};
    final subjectNames = {for (final a in assignments) subjects[a['matiereId']]}.whereType<String>();
    return EstablishmentModel(
      id: id,
      nom: etab['nom'] as String? ?? 'Établissement',
      classesCount: {for (final a in assignments) a['classeId']}.length,
      matiere: subjectNames.isEmpty ? null : subjectNames.join(', '),
    );
  }
}
