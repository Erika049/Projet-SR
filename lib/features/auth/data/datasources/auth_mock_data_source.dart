import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/mock_delay.dart';
import '../../domain/entities/app_user.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// Compte de démonstration utilisable tant que `USE_MOCK` vaut `true`.
class DemoAccount {
  const DemoAccount({required this.phone, required this.password, required this.user, this.establishments = const []});

  /// Numéro à 9 chiffres, saisi avec ou sans « +237 » et espaces.
  final String phone;
  final String password;
  final UserModel user;

  /// Établissements de l'enseignant (plusieurs → écran « Choisir un établissement »).
  final List<EstablishmentModel> establishments;
}

/// Comptes de test de l'authentification (voir aussi COMPTES_DE_TEST.md).
///
/// | Profil      | Téléphone   | Mot de passe | Particularité                         |
/// |-------------|-------------|--------------|---------------------------------------|
/// | Parent      | 690000001   | parent123    | Madeleine Etame                       |
/// | Parent      | 690000002   | parent123    | Jean Nkoulou                          |
/// | Enseignant  | 670000001   | prof123      | 2 établissements → choix au démarrage |
/// | Enseignant  | 670000002   | prof123      | 1 seul établissement → accès direct   |
///
/// Code OTP (inscription) : `123456`.
abstract final class DemoAccounts {
  static const otp = '123456';
  static const parentPassword = 'parent123';
  static const teacherPassword = 'prof123';

  static const _bafoussam = EstablishmentModel(
    id: 'etab-1',
    nom: 'Lycée bilingue de Bafoussam',
    classesCount: 3,
    matiere: 'Mathématiques',
  );
  static const _dschang = EstablishmentModel(
    id: 'etab-2',
    nom: 'Collège Saint-Joseph de Dschang',
    classesCount: 2,
    matiere: 'Mathématiques',
  );
  static const _yaounde = EstablishmentModel(
    id: 'etab-3',
    nom: 'Lycée général Leclerc de Yaoundé',
    classesCount: 4,
    matiere: 'Physique-Chimie',
  );

  static const all = [
    DemoAccount(
      phone: '690000001',
      password: parentPassword,
      user: UserModel(
        id: 'u-parent-1',
        nom: 'Etame',
        prenom: 'Madeleine',
        civilite: 'Mme',
        role: UserRole.parent,
        telephone: '+237 690 000 001',
        email: 'parent@schoolconnect.cm',
      ),
    ),
    DemoAccount(
      phone: '690000002',
      password: parentPassword,
      user: UserModel(
        id: 'u-parent-2',
        nom: 'Nkoulou',
        prenom: 'Jean',
        civilite: 'M.',
        role: UserRole.parent,
        telephone: '+237 690 000 002',
        email: 'jean.nkoulou@schoolconnect.cm',
      ),
    ),
    DemoAccount(
      phone: '670000001',
      password: teacherPassword,
      user: UserModel(
        id: 'u-ens-1',
        nom: 'Kamga',
        prenom: 'Paul',
        civilite: 'M.',
        role: UserRole.enseignant,
        telephone: '+237 670 000 001',
        email: 'prof@schoolconnect.cm',
        specialite: 'Mathématiques',
      ),
      establishments: [_bafoussam, _dschang],
    ),
    DemoAccount(
      phone: '670000002',
      password: teacherPassword,
      user: UserModel(
        id: 'u-ens-2',
        nom: 'Bello',
        prenom: 'Aïcha',
        civilite: 'Mme',
        role: UserRole.enseignant,
        telephone: '+237 670 000 002',
        email: 'aicha.bello@schoolconnect.cm',
        specialite: 'Physique-Chimie',
      ),
      establishments: [_yaounde],
    ),
  ];
}

class AuthMockDataSource implements AuthRemoteDataSource {
  /// Comptes créés par inscription pendant l'exécution (perdus au redémarrage).
  final List<DemoAccount> _registered = [];
  ({String fullName, String phone, String? email, String password})? _pending;
  DemoAccount? _current;

  /// Mots de passe modifiés par « Mot de passe oublié » (téléphone → mot de passe).
  final Map<String, String> _changedPasswords = {};

  /// Jetons de réinitialisation en cours (jeton → téléphone), à usage unique.
  final Map<String, String> _resetTokens = {};

  /// Garde les 9 derniers chiffres : « +237 690 00 00 01 » → « 690000001 ».
  static String _normalize(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }

  DemoAccount? _find(String phone) {
    final key = _normalize(phone);
    for (final a in [...DemoAccounts.all, ..._registered]) {
      if (a.phone == key) return a;
    }
    return null;
  }

  @override
  Future<AuthSession> login(String identifier, String password) async {
    await mockDelay();
    final account = _find(identifier);
    if (account == null || (_changedPasswords[account.phone] ?? account.password) != password) {
      throw const AuthException('Numéro ou mot de passe incorrect.');
    }
    _current = account;
    return (token: 'mock-${account.user.id}', user: account.user);
  }

  @override
  Future<void> registerParent(String fullName, String phone, String? email, String password) async {
    await mockDelay();
    if (_find(phone) != null) throw const AuthException('Un compte existe déjà avec ce numéro.');
    _pending = (fullName: fullName.trim(), phone: phone, email: email, password: password);
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    await mockDelay();
    if (code != DemoAccounts.otp) throw const AuthException('Code incorrect. Vérifiez le SMS reçu.');
    final p = _pending;
    final parts = (p?.fullName.isNotEmpty ?? false) ? p!.fullName.split(RegExp(r'\s+')) : ['Nouveau', 'Parent'];
    final account = DemoAccount(
      phone: _normalize(phone),
      password: p?.password ?? '',
      user: UserModel(
        id: 'u-parent-${_registered.length + 100}',
        prenom: parts.first,
        nom: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        role: UserRole.parent,
        telephone: phone,
        email: (p?.email?.isEmpty ?? true) ? null : p!.email,
      ),
    );
    _registered.add(account);
    _pending = null;
    _current = account;
    return (token: 'mock-${account.user.id}', user: account.user);
  }

  @override
  Future<void> resendOtp(String phone) => mockDelay(300);

  @override
  Future<void> requestPasswordReset(String identifier) async {
    // Même réponse que le compte existe ou non : on ne révèle pas qui est inscrit.
    await mockDelay();
  }

  @override
  Future<String> verifyResetCode(String phone, String code) async {
    await mockDelay();
    final account = _find(phone);
    if (account == null || code != DemoAccounts.otp) throw const AuthException('Code incorrect ou expiré.');
    final token = 'reset-${account.phone}-${DateTime.now().microsecondsSinceEpoch}';
    _resetTokens[token] = account.phone;
    return token;
  }

  @override
  Future<void> resetPassword(String resetToken, String newPassword) async {
    await mockDelay();
    final phone = _resetTokens.remove(resetToken);
    if (phone == null) throw const AuthException('La demande a expiré. Recommencez depuis « Mot de passe oublié ».');
    _changedPasswords[phone] = newPassword;
  }

  @override
  Future<List<EstablishmentModel>> getEstablishments() async {
    await mockDelay(300);
    // Après un redémarrage, la session est restaurée sans repasser par login() :
    // on retombe alors sur les établissements du premier enseignant.
    return (_current ?? DemoAccounts.all[2]).establishments;
  }
}
