import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/state/session_cubit.dart';
import '../../../sync/presentation/state/sync_cubit.dart';
import '../widgets/profile_widgets.dart';

/// « Profil et paramètres » de l'enseignant.
class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final user = session.user;
    final pending = context.watch<SyncCubit>().state.data?.pendingCount ?? 0;

    return AppPage(
      title: 'Profil et paramètres',
      children: [
        if (user != null)
          IdentityCard(
            name: user.greetingName,
            subtitle: 'Enseignant${user.specialite == null ? '' : ' · ${user.specialite}'}',
            phone: user.telephone,
          ),
        gap12,
        AppCard(
          child: DividedColumn(
            children: [
              NavRow(
                'Établissement',
                value: session.establishment?.nom,
                onTap: context.read<SessionCubit>().switchEstablishment,
              ),
              NavRow(
                'État de synchronisation',
                value: pending == 0 ? 'À jour' : '$pending en attente',
                onTap: () => context.push(Routes.teacherSync),
              ),
              const NotificationsRow(),
              const LowDataRow(),
              const LanguageRow(),
            ],
          ),
        ),
        gap12,
        AppCard(
          child: DividedColumn(
            children: [
              NavRow('Ma présence', onTap: () => context.push(Routes.teacherPresence)),
              NavRow('Aide et confidentialité', onTap: () => showHelp(context)),
            ],
          ),
        ),
        gap12,
        const LogoutButton(),
      ],
    );
  }
}
