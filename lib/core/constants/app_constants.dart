abstract final class AppConstants {
  static const appName = 'SchoolConnect';
  static const tagline = 'L’école, plus proche de vous.';

  /// URL de l'API. À remplacer quand le backend sera disponible.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.schoolconnect.cm/v1',
  );

  /// `true` : l'application utilise les données fictives des datasources « mock ».
  /// Lancer avec `--dart-define=USE_MOCK=false` pour brancher l'API réelle.
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  static const otpLength = 6;
  static const otpResendDelay = Duration(seconds: 45);
  static const gradeScale = 20.0;
}
