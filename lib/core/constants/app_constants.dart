abstract final class AppConstants {
  static const appName = 'SchoolConnect';
  static const tagline = 'L’école, plus proche de vous.';

  /// URL de l'API SchoolConnect (documentation : `<serveur>/swagger-ui/index.html`).
  /// Modifiable au lancement : `--dart-define=API_BASE_URL=https://…/api/v1`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://school-connect-backend-production-d24122f4.up.railway.app/api/v1',
  );

  static const otpLength = 6;
  static const otpResendDelay = Duration(seconds: 45);
  static const gradeScale = 20.0;
}
