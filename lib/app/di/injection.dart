import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/permissions/app_permissions.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/sync_queue.dart';
import '../../features/attendance/data/datasources/attendance_remote_data_source.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/attendance_usecases.dart';
import '../../features/attendance/presentation/state/attendance_cubits.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_mock_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/state/auth_form_cubits.dart';
import '../../features/auth/presentation/state/session_cubit.dart';
import '../../features/children/data/datasources/children_remote_data_source.dart';
import '../../features/children/data/repositories/children_repository_impl.dart';
import '../../features/children/domain/repositories/children_repository.dart';
import '../../features/children/domain/usecases/children_usecases.dart';
import '../../features/children/presentation/state/children_cubit.dart';
import '../../features/grades/data/datasources/grades_remote_data_source.dart';
import '../../features/grades/data/repositories/grades_repository_impl.dart';
import '../../features/grades/domain/repositories/grades_repository.dart';
import '../../features/grades/domain/usecases/grades_usecases.dart';
import '../../features/grades/presentation/state/grades_cubits.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/home_usecases.dart';
import '../../features/home/presentation/state/home_cubits.dart';
import '../../features/notifications/data/datasources/notifications_data_sources.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
import '../../features/notifications/presentation/state/notifications_cubits.dart';
import '../../features/payments/data/datasources/payments_remote_data_source.dart';
import '../../features/payments/data/repositories/payments_repository_impl.dart';
import '../../features/payments/domain/repositories/payments_repository.dart';
import '../../features/payments/domain/usecases/payments_usecases.dart';
import '../../features/payments/presentation/state/payments_cubits.dart';
import '../../features/sync/data/repositories/sync_repository_impl.dart';
import '../../features/sync/domain/repositories/sync_repository.dart';
import '../../features/sync/domain/usecases/sync_usecases.dart';
import '../../features/sync/presentation/state/sync_cubit.dart';
import '../../features/timetable/data/datasources/timetable_remote_data_source.dart';
import '../../features/timetable/data/repositories/timetable_repository_impl.dart';
import '../../features/timetable/domain/repositories/timetable_repository.dart';
import '../../features/timetable/domain/usecases/timetable_usecases.dart';
import '../../features/timetable/presentation/state/timetable_cubit.dart';
import '../settings/settings_cubit.dart';

/// Localisateur de services global.
final sl = GetIt.instance;

/// Enregistre toutes les dépendances. Ordre : core → data → domain → presentation.
/// Les datasources « mock » sont utilisées tant que `USE_MOCK` vaut `true`
/// (voir [AppConstants.useMock]).
Future<void> configureDependencies() async {
  // ───────── Core ─────────
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerSingleton(LocalStorage(prefs))
    ..registerLazySingleton(() => ApiClient(sl()))
    ..registerLazySingleton<NetworkInfo>(SimulatedNetworkInfo.new)
    ..registerLazySingleton(() => SyncQueue(sl()))
    ..registerLazySingleton<AppPermissions>(() => const DeviceAppPermissions())
    ..registerLazySingleton(() => SettingsCubit(sl(), sl()));

  // ───────── Data : datasources ─────────
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AppConstants.useMock ? AuthMockDataSource() : AuthApiDataSource(sl()),
    )
    ..registerLazySingleton(() => AuthLocalDataSource(sl()))
    // TODO(backend) : remplacer chaque *MockDataSource par son implémentation HTTP.
    ..registerLazySingleton<ChildrenRemoteDataSource>(ChildrenMockDataSource.new)
    ..registerLazySingleton<GradesRemoteDataSource>(GradesMockDataSource.new)
    ..registerLazySingleton<AttendanceRemoteDataSource>(AttendanceMockDataSource.new)
    ..registerLazySingleton<PaymentsRemoteDataSource>(PaymentsMockDataSource.new)
    ..registerLazySingleton<NotificationsRemoteDataSource>(NotificationsMockDataSource.new)
    ..registerLazySingleton(() => NotificationsLocalDataSource(sl()))
    ..registerLazySingleton<TimetableRemoteDataSource>(TimetableMockDataSource.new)
    ..registerLazySingleton<HomeRemoteDataSource>(HomeMockDataSource.new);

  // ───────── Data : repositories ─────────
  sl
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<ChildrenRepository>(() => ChildrenRepositoryImpl(sl()))
    ..registerLazySingleton<GradesRepository>(() => GradesRepositoryImpl(sl(), sl(), sl()))
    ..registerLazySingleton<AttendanceRepository>(() => AttendanceRepositoryImpl(sl(), sl(), sl()))
    ..registerLazySingleton<PaymentsRepository>(() => PaymentsRepositoryImpl(sl()))
    ..registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(sl(), sl(), sl()))
    ..registerLazySingleton<TimetableRepository>(() => TimetableRepositoryImpl(sl()))
    ..registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()))
    ..registerLazySingleton<SyncRepository>(() => SyncRepositoryImpl(sl(), sl()));

  // ───────── Domain : use cases ─────────
  sl
    // auth
    ..registerFactory(() => Login(sl()))
    ..registerFactory(() => RegisterParent(sl()))
    ..registerFactory(() => VerifyOtp(sl()))
    ..registerFactory(() => ResendOtp(sl()))
    ..registerFactory(() => RequestPasswordReset(sl()))
    ..registerFactory(() => VerifyResetCode(sl()))
    ..registerFactory(() => ResetPassword(sl()))
    ..registerFactory(() => RestoreSession(sl()))
    ..registerFactory(() => GetEstablishments(sl()))
    ..registerFactory(() => SelectEstablishment(sl()))
    ..registerFactory(() => GetSelectedEstablishment(sl()))
    ..registerFactory(() => Logout(sl()))
    // children
    ..registerFactory(() => GetChildren(sl()))
    ..registerFactory(() => GetLinkRequests(sl()))
    ..registerFactory(() => LinkChild(sl()))
    ..registerFactory(() => UnlinkChild(sl()))
    ..registerFactory(() => RequestCorrection(sl()))
    // grades
    ..registerFactory(() => GetPeriods(sl()))
    ..registerFactory(() => GetChildGrades(sl()))
    ..registerFactory(() => GetReportCards(sl()))
    ..registerFactory(() => DownloadReportCard(sl()))
    ..registerFactory(() => GetGradeSheet(sl()))
    ..registerFactory(() => SaveGradeSheet(sl()))
    ..registerFactory(() => CorrectGrade(sl()))
    ..registerFactory(() => GetAppreciations(sl()))
    ..registerFactory(() => SaveAppreciations(sl()))
    ..registerFactory(() => GetClassStats(sl()))
    // attendance
    ..registerFactory(() => GetChildAttendance(sl()))
    ..registerFactory(() => JustifyAbsence(sl()))
    ..registerFactory(() => ReportAttendanceError(sl()))
    ..registerFactory(() => GetRollCall(sl()))
    ..registerFactory(() => SaveRollCall(sl()))
    ..registerFactory(() => GetMyAttendance(sl()))
    ..registerFactory(() => SignalMyPresence(sl()))
    ..registerFactory(() => SignalMyAbsence(sl()))
    // payments
    ..registerFactory(() => GetFinancialSituation(sl()))
    ..registerFactory(() => GetPaymentHistory(sl()))
    ..registerFactory(() => DeclarePayment(sl()))
    ..registerFactory(() => DownloadReceipt(sl()))
    // notifications
    ..registerFactory(() => GetNotifications(sl()))
    ..registerFactory(() => MarkNotificationsRead(sl()))
    ..registerFactory(() => GetNotificationPreferences(sl()))
    ..registerFactory(() => SaveNotificationPreferences(sl()))
    ..registerFactory(() => GetAnnouncements(sl()))
    // timetable / home / sync
    ..registerFactory(() => GetWeekTimetable(sl()))
    ..registerFactory(() => GetTeacherClasses(sl()))
    ..registerFactory(() => GetParentOverview(sl()))
    ..registerFactory(() => GetSyncOverview(sl()))
    ..registerFactory(() => SyncNow(sl()))
    ..registerFactory(() => ResolveConflict(sl()));

  // ───────── Presentation : cubits ─────────
  sl
    ..registerLazySingleton(
      () => SessionCubit(
        restoreSession: sl(),
        getEstablishments: sl(),
        getSelectedEstablishment: sl(),
        selectEstablishment: sl(),
        logout: sl(),
      ),
    )
    ..registerFactory(() => LoginCubit(sl()))
    ..registerFactory(() => RegisterCubit(sl()))
    ..registerFactory(() => ForgotPasswordCubit(sl()))
    ..registerFactory(() => NewPasswordCubit(sl()))
    ..registerFactory(() => EstablishmentsCubit(sl()))
    ..registerFactory(
      () => ChildrenCubit(
        getChildren: sl(),
        getLinkRequests: sl(),
        linkChild: sl(),
        unlinkChild: sl(),
        requestCorrection: sl(),
      ),
    )
    ..registerFactory(() => ParentHomeCubit(sl()))
    ..registerFactory(() => TeacherHomeCubit(sl(), sl()))
    ..registerFactory(() => ChildGradesCubit(sl(), sl()))
    ..registerFactory(() => ReportCardsCubit(sl(), sl()))
    ..registerFactory(() => GradeSheetCubit(sl(), sl()))
    ..registerFactory(() => CorrectionCubit(sl()))
    ..registerFactory(() => AppreciationsCubit(sl(), sl()))
    ..registerFactory(() => ClassStatsCubit(sl()))
    ..registerFactory(() => ChildAttendanceCubit(sl(), sl()))
    ..registerFactory(() => JustifyCubit(sl()))
    ..registerFactory(() => RollCallCubit(sl(), sl()))
    ..registerFactory(() => MyAttendanceCubit(sl(), sl(), sl()))
    ..registerFactory(() => FinancialSituationCubit(sl()))
    ..registerFactory(() => PaymentHistoryCubit(sl(), sl()))
    ..registerFactory(() => DeclarePaymentCubit(sl()))
    ..registerFactory(() => NotificationsCubit(sl(), sl()))
    ..registerFactory(() => PreferencesCubit(sl(), sl()))
    ..registerFactory(() => AnnouncementsCubit(sl()))
    ..registerFactory(() => TimetableCubit(sl()))
    ..registerFactory(() => SyncCubit(sl(), sl(), sl()));

  // Jeton refusé par le serveur → écran « Session expirée ».
  sl<ApiClient>().onUnauthorized = sl<SessionCubit>().expire;
}
