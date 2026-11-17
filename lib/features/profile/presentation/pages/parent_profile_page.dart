import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/state/session_cubit.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../widgets/profile_widgets.dart';

/// « Profil et paramètres » du parent (CU-PAR-16).
class ParentProfilePage extends StatelessWidget {
  const ParentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state.user;
    final count = context.watch<ChildrenCubit>().state.children.length;

    return AppPage(
      title: 'Profil et paramètres',
      children: [
        if (user != null)
          IdentityCard(
            name: user.fullName,
            subtitle: 'Parent · $count enfant${count > 1 ? 's' : ''} rattaché${count > 1 ? 's' : ''}',
            phone: user.telephone,
          ),
        gap20,
        const SectionTitle('Préférences'),
        AppCard(
          child: DividedColumn(
            children: [
              const NotificationsRow(),
              InkWell(
                onTap: () => context.push(Routes.parentPreferences),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(child: Text('Canaux de notification', style: TextStyle(fontSize: 17))),
                        Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    gap12,
                    const Wrap(
                      spacing: 8,
                      children: [
                        StatusChip('Push · par défaut'),
                        StatusChip('SMS', tone: StatusTone.neutral),
                        StatusChip('Email', tone: StatusTone.neutral),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Réglable pour chaque enfant.',
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const DarkModeRow(),
              const LanguageRow(),
              const LowDataRow(),
            ],
          ),
        ),
        gap12,
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: NavRow('Mes enfants et droits', onTap: () => context.push(Routes.parentChildren)),
        ),
        gap12,
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: NavRow('Aide et confidentialité', onTap: () => showHelp(context)),
        ),
        gap12,
        const LogoutButton(),
      ],
    );
  }
}
