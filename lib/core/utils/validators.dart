/// Validateurs de formulaires. Retournent `null` si la valeur est valide.
abstract final class Validators {
  static final _phone = RegExp(r'^(\+?237)?\s?6[\d\s]{8,11}$');
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');

  static String? required(String? v, [String label = 'Ce champ']) =>
      (v == null || v.trim().isEmpty) ? '$label est obligatoire' : null;

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le numéro est obligatoire';
    return _phone.hasMatch(v.trim()) ? null : 'Numéro camerounais invalide (6XX XXX XXX)';
  }

  static String? email(String? v, {bool optional = false}) {
    if (v == null || v.trim().isEmpty) return optional ? null : 'L’email est obligatoire';
    return _email.hasMatch(v.trim()) ? null : 'Email invalide';
  }

  static String? phoneOrEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Saisissez votre téléphone ou votre email';
    return v.contains('@') ? email(v) : phone(v);
  }

  /// Connexion : le mot de passe doit simplement être saisi.
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est obligatoire';
    return null;
  }

  /// Nouveau mot de passe (inscription, réinitialisation) : 8 caractères minimum, règle du serveur.
  static const newPasswordMinLength = 8;

  static String? newPassword(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est obligatoire';
    return v.length < newPasswordMinLength ? 'Au moins $newPasswordMinLength caractères' : null;
  }

  /// « Prénom Nom » : le serveur exige un prénom et un nom.
  static String? fullName(String? v) {
    final parts = (v ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'Le nom est obligatoire';
    return parts.length < 2 ? 'Saisissez le prénom et le nom' : null;
  }
}
