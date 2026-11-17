import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendance/domain/entities/attendance.dart';
import '../../features/attendance/presentation/pages/justify_absence_page.dart';
import '../../features/attendance/presentation/pages/my_attendance_page.dart';
import '../../features/attendance/presentation/pages/roll_call_page.dart';
import '../../features/auth/presentation/pages/choose_establishment_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/new_password_page.dart';
import '../../features/auth/presentation/pages/reset_code_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/session_expired_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/state/session_cubit.dart';
import '../../features/children/presentation/pages/child_profile_page.dart';
import '../../features/children/presentation/pages/link_child_page.dart';
import '../../features/children/presentation/pages/my_children_page.dart';
import '../../features/grades/domain/entities/grades.dart';
import '../../features/grades/presentation/pages/appreciations_page.dart';
import '../../features/grades/presentation/pages/class_stats_page.dart';
import '../../features/grades/presentation/pages/grade_correction_page.dart';
import '../../features/grades/presentation/pages/grade_entry_page.dart';
import '../../features/grades/presentation/pages/report_cards_page.dart';
import '../../features/home/presentation/pages/parent_home_page.dart';
import '../../features/home/presentation/pages/teacher_home_page.dart';
import '../../features/notifications/presentation/pages/announcements_page.dart';
import '../../features/notifications/presentation/pages/notification_preferences_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/payments/presentation/pages/declare_payment_page.dart';
import '../../features/payments/presentation/pages/receipts_page.dart';
import '../../features/profile/presentation/pages/parent_profile_page.dart';
import '../../features/profile/presentation/pages/teacher_profile_page.dart';
import '../../features/sync/presentation/pages/sync_page.dart';
import '../../features/timetable/presentation/pages/timetable_page.dart';
import '../shell/app_shells.dart';
import '../shell/parent_tracking_page.dart';
import 'routes.dart';

/// Rafraîchit le routeur à chaque changement de session.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Stream<SessionState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<SessionState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter(SessionCubit session) {
  String classOf(GoRouterState s) => s.uri.queryParameters['classe'] ?? Routes.defaultClassId;

  return GoRouter(
    initialLocation: Routes.welcome,
    refreshListenable: _SessionListenable(session.stream),
    redirect: (context, state) {
      final s = session.state;
      final loc = state.matchedLocation;
      switch (s.status) {
        case SessionStatus.unknown:
          return loc == Routes.welcome ? null : Routes.welcome;
        case SessionStatus.unauthenticated:
          return Routes.publicRoutes.contains(loc) ? null : Routes.login;
        case SessionStatus.expired:
          return Routes.sessionExpired;
        case SessionStatus.choosingEstablishment:
          return Routes.chooseEstablishment;
        case SessionStatus.authenticated:
          final home = s.user!.isParent ? Routes.parentHome : Routes.teacherHome;
          final otherSpace = s.user!.isParent ? Routes.teacherHome : Routes.parentHome;
          final isAuthScreen =
              loc == Routes.welcome ||
              loc == Routes.sessionExpired ||
              loc == Routes.chooseEstablishment ||
              Routes.publicRoutes.contains(loc);
          if (isAuthScreen || loc.startsWith(otherSpace)) return home;
          return null;
      }
    },
    routes: [
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: Routes.otp,
        builder: (_, s) => OtpPage(phone: s.extra as String? ?? ''),
      ),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordPage()),
      GoRoute(
        path: Routes.resetCode,
        builder: (_, s) => ResetCodePage(phone: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: Routes.newPassword,
        builder: (_, s) => NewPasswordPage(resetToken: s.extra as String? ?? ''),
      ),
      GoRoute(path: Routes.sessionExpired, builder: (_, _) => const SessionExpiredPage()),
      GoRoute(path: Routes.chooseEstablishment, builder: (_, _) => const ChooseEstablishmentPage()),

      // ─────────────── Espace Parent ───────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ParentShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.parentHome,
                builder: (_, _) => const ParentHomePage(),
                routes: [
                  GoRoute(
                    path: 'enfant/:id',
                    builder: (_, s) => ChildProfilePage(childId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.parentTracking,
                builder: (_, s) =>
                    ParentTrackingPage(initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0),
                routes: [
                  GoRoute(path: 'bulletins', builder: (_, _) => const ReportCardsPage()),
                  GoRoute(
                    path: 'justifier',
                    builder: (_, s) => JustifyAbsencePage(record: s.extra! as AttendanceRecord),
                  ),
                  GoRoute(path: 'declarer', builder: (_, _) => const DeclarePaymentPage()),
                  GoRoute(path: 'recus', builder: (_, _) => const ReceiptsPage()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.parentNotifications,
                builder: (_, _) => const NotificationsPage(),
                routes: [GoRoute(path: 'annonces', builder: (_, _) => const AnnouncementsPage())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.parentProfile,
                builder: (_, _) => const ParentProfilePage(),
                routes: [
                  GoRoute(path: 'enfants', builder: (_, _) => const MyChildrenPage()),
                  GoRoute(path: 'lier', builder: (_, _) => const LinkChildPage()),
                  GoRoute(path: 'preferences', builder: (_, _) => const NotificationPreferencesPage()),
                ],
              ),
            ],
          ),
        ],
      ),

      // ─────────────── Espace Enseignant ───────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => TeacherShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.teacherHome,
                builder: (_, _) => const TeacherHomePage(),
                routes: [
                  GoRoute(path: 'emploi-du-temps', builder: (_, _) => const TimetablePage()),
                  GoRoute(path: 'synchronisation', builder: (_, _) => const SyncPage()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.teacherGradesBase,
                builder: (_, s) => GradeEntryPage(classId: classOf(s)),
                routes: [
                  GoRoute(
                    path: 'corriger',
                    builder: (_, s) {
                      final args = s.extra! as ({GradeSheet sheet, StudentGrade grade});
                      return GradeCorrectionPage(sheet: args.sheet, grade: args.grade);
                    },
                  ),
                  GoRoute(
                    path: 'appreciations',
                    builder: (_, s) => AppreciationsPage(classId: classOf(s)),
                  ),
                  GoRoute(
                    path: 'statistiques',
                    builder: (_, s) => ClassStatsPage(classId: classOf(s)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.teacherRollCallBase,
                builder: (_, s) => RollCallPage(classId: classOf(s)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.teacherProfile,
                builder: (_, _) => const TeacherProfilePage(),
                routes: [GoRoute(path: 'presence', builder: (_, _) => const MyAttendancePage())],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
