import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/data_refresh.dart';
import '../../features/children/presentation/state/children_cubit.dart';
import '../../features/sync/presentation/state/sync_cubit.dart';
import '../di/injection.dart';
import '../settings/permission_prompts.dart';
import '../theme/app_colors.dart';

typedef _Tab = ({IconData icon, IconData selected, String label});

/// À la première arrivée dans un espace (première connexion ou fin d'inscription),
/// demande l'autorisation d'envoyer des notifications push.
class _ShellScaffold extends StatefulWidget {
  const _ShellScaffold({required this.shell, required this.tabs});

  final StatefulNavigationShell shell;
  final List<_Tab> tabs;

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> with WidgetsBindingObserver {
  /// Actualisation régulière tant que l'application est ouverte (nouvelles notifications,
  /// absences signalées par le surveillant, paiements validés…).
  static const _period = Duration(seconds: 60);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) promptNotificationsFirstTime(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_period, (_) => DataRefresh.instance.request());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DataRefresh.instance.request();
      _startTimer();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          // Un second appui sur l'onglet courant revient à sa racine.
          onDestinationSelected: (i) {
            shell.goBranch(i, initialLocation: i == shell.currentIndex);
            DataRefresh.instance.request();
          },
          destinations: [
            for (final t in widget.tabs)
              NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selected), label: t.label),
          ],
        ),
      ),
    );
  }
}

/// Espace Parent : Accueil · Suivi · Alertes · Profil.
/// Fournit [ChildrenCubit] à tous les écrans de l'espace.
class ParentShell extends StatelessWidget {
  const ParentShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _childrenWithRefresh(),
      child: _ShellScaffold(
        shell: shell,
        tabs: const [
          (icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Accueil'),
          (icon: Icons.bar_chart_rounded, selected: Icons.bar_chart_rounded, label: 'Suivi'),
          (icon: Icons.notifications_none_rounded, selected: Icons.notifications_rounded, label: 'Alertes'),
          (icon: Icons.person_outline_rounded, selected: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }
}

/// Liste des enfants rechargée à chaque actualisation (liaison acceptée par le secrétariat…).
ChildrenCubit _childrenWithRefresh() {
  final cubit = sl<ChildrenCubit>()..load();
  void reload() {
    if (!cubit.isClosed) cubit.load(silent: true);
  }

  DataRefresh.instance.addListener(reload);
  cubit.stream.listen(null, onDone: () => DataRefresh.instance.removeListener(reload));
  return cubit;
}

/// Espace Enseignant : Accueil · Notes · Appel · Profil.
/// Fournit [SyncCubit] à tous les écrans de l'espace.
class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SyncCubit>()..load(),
      child: _ShellScaffold(
        shell: shell,
        tabs: const [
          (icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Accueil'),
          (icon: Icons.view_column_outlined, selected: Icons.view_column_rounded, label: 'Notes'),
          (icon: Icons.check_rounded, selected: Icons.check_rounded, label: 'Appel'),
          (icon: Icons.person_outline_rounded, selected: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }
}
