/// Chemins de navigation de l'application.
abstract final class Routes {
  // Authentification
  /// Page de bienvenue, premier écran affiché au lancement.
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/register/otp';
  static const forgotPassword = '/forgot-password';
  static const sessionExpired = '/session-expired';
  static const chooseEstablishment = '/establishment';

  static const publicRoutes = {welcome, login, register, otp, forgotPassword};

  // Espace Parent
  static const parentHome = '/parent';
  static String parentChild(String id) => '/parent/enfant/$id';
  static const parentTracking = '/parent/suivi';
  static const parentReportCards = '/parent/suivi/bulletins';
  static const parentJustify = '/parent/suivi/justifier';
  static const parentDeclarePayment = '/parent/suivi/declarer';
  static const parentReceipts = '/parent/suivi/recus';
  static const parentNotifications = '/parent/alertes';
  static const parentAnnouncements = '/parent/alertes/annonces';
  static const parentProfile = '/parent/profil';
  static const parentChildren = '/parent/profil/enfants';
  static const parentLinkChild = '/parent/profil/lier';
  static const parentPreferences = '/parent/profil/preferences';

  // Espace Enseignant
  static const teacherHome = '/enseignant';
  static const teacherTimetable = '/enseignant/emploi-du-temps';
  static const teacherSync = '/enseignant/synchronisation';
  static const teacherGradesBase = '/enseignant/notes';
  static String teacherGrades(String classId) => '$teacherGradesBase?classe=$classId';
  static const teacherGradeCorrection = '/enseignant/notes/corriger';
  static String teacherAppreciations(String classId) => '/enseignant/notes/appreciations?classe=$classId';
  static String teacherStats(String classId) => '/enseignant/notes/statistiques?classe=$classId';
  static const teacherRollCallBase = '/enseignant/appel';
  static String teacherRollCall(String classId) => '$teacherRollCallBase?classe=$classId';
  static const teacherProfile = '/enseignant/profil';
  static const teacherPresence = '/enseignant/profil/presence';

  /// Classe affichée par défaut dans les onglets Notes / Appel.
  static const defaultClassId = '3eA';
}
