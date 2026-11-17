import 'package:flutter/material.dart';
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

class _SchoolConnectAppState extends State<SchoolConnectApp> {
  late final SessionCubit _session = sl<SessionCubit>()..restore();
  late final GoRouter _router = createRouter(_session);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: sl<SettingsCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (a, b) => a.locale != b.locale,
        builder: (context, settings) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          locale: settings.locale,
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
  }
}
