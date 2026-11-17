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

  /// Les couleurs [AppColors] ne passent pas par `Theme.of` : après un changement
  /// de thème, on redessine tout l'arbre (l'état des écrans est conservé).
  void _repaintAll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void rebuild(Element e) {
        e.markNeedsBuild();
        e.visitChildren(rebuild);
      }

      if (mounted) (context as Element).visitChildren(rebuild);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: _settings),
      ],
      child: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (a, b) => a.darkMode != b.darkMode,
        listener: (_, _) => _repaintAll(),
        buildWhen: (a, b) => a.locale != b.locale || a.darkMode != b.darkMode,
        builder: (context, settings) {
          final theme = AppTheme.build(dark: settings.darkMode);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: settings.darkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: theme,
              themeAnimationDuration: Duration.zero,
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
