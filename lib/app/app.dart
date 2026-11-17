import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/auth/presentation/state/session_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'settings/settings_cubit.dart';
import 'theme/app_theme.dart';

class SchoolConnectApp extends StatefulWidget {
  const SchoolConnectApp({super.key});

  @override
  State<SchoolConnectApp> createState() => _SchoolConnectAppState();
}

class _SchoolConnectAppState extends State<SchoolConnectApp> with WidgetsBindingObserver {
  late final SessionCubit _session = sl<SessionCubit>()..restore();
  late final GoRouter _router = createRouter(_session);
  final _settings = sl<SettingsCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.refreshNotificationPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // L'utilisateur a pu changer l'autorisation dans les paramètres du téléphone.
    if (state == AppLifecycleState.resumed) _settings.refreshNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  /// L'application est toujours en thème clair.
  static final _theme = AppTheme.build(dark: false);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: _settings),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (a, b) => a.locale != b.locale,
        builder: (context, settings) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: _theme,
              themeMode: ThemeMode.light,
              routerConfig: _router,
              locale: settings.locale,
              supportedLocales: const [Locale('fr'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
            ),
          );
        },
      ),
    );
  }
}
