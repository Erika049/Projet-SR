import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/settings/permission_prompts.dart';
import '../../../../app/settings/settings_cubit.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/state/session_cubit.dart';

/// Carte d'identité en tête du profil.
class IdentityCard extends StatelessWidget {
  const IdentityCard({super.key, required this.name, required this.subtitle, this.phone});

  final String name;
  final String subtitle;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 15, color: AppColors.textSecondary);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: muted),
          if (phone != null) ...[const SizedBox(height: 6), Text(phone!, style: muted)],
        ],
      ),
    );
  }
}

/// « Langue  Français · EN » — bascule FR/EN.
class LanguageRow extends StatelessWidget {
  const LanguageRow({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>();
    return NavRow(
      'Langue',
      value: settings.isFrench ? 'Français · EN' : 'English · FR',
      valueColor: AppColors.green,
      onTap: () => settings.setLocale(settings.isFrench ? 'en' : 'fr'),
    );
  }
}

/// Ligne de réglage avec interrupteur : « Libellé   Activé  [◉] ».
class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Icon(icon, color: value ? AppColors.green : AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          Text(
            value ? 'Activé' : 'Désactivé',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: value ? AppColors.green : AppColors.textSecondary,
            ),
          ),
          Switch(value: value, activeTrackColor: AppColors.green, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// « Notifications push » : relié à l'autorisation du téléphone.
class NotificationsRow extends StatelessWidget {
  const NotificationsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsCubit>().state;
    final blocked = state.notificationsWanted && !state.notificationsAllowed;
    return SettingSwitchRow(
      icon: state.notificationsOn ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
      title: 'Notifications',
      subtitle: blocked ? 'Non autorisées par le téléphone' : 'Absences, notes, bulletins, paiements',
      value: state.notificationsOn,
      onChanged: (on) => on ? enableNotifications(context) : context.read<SettingsCubit>().disableNotifications(),
    );
  }
}

/// « Mode faible consommation  Activé ».
class LowDataRow extends StatelessWidget {
  const LowDataRow({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>();
    return SettingSwitchRow(
      icon: Icons.data_saver_on_outlined,
      title: 'Mode faible consommation',
      value: settings.state.lowDataMode,
      onChanged: settings.setLowDataMode,
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppButton.secondary(
      label: 'Se déconnecter',
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Se déconnecter ?'),
            content: const Text('Les brouillons non envoyés restent sur ce téléphone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Se déconnecter')),
            ],
          ),
        );
        if (ok == true && context.mounted) await context.read<SessionCubit>().logout();
      },
    );
  }
}

/// « Aide et confidentialité ».
void showHelp(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aide et confidentialité', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            gap12,
            Text(
              '• Vos données sont visibles uniquement par vous et par l’établissement.\n'
              '• Un parent ne voit que les enfants liés à son compte.\n'
              '• Hors connexion, les données déjà chargées restent consultables.\n'
              '• Pour toute question, contactez le secrétariat de votre établissement.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
