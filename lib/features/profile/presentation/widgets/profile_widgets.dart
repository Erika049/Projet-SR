import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    const muted = TextStyle(fontSize: 15, color: AppColors.textSecondary);
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

/// « Mode faible consommation  Activé ».
class LowDataRow extends StatelessWidget {
  const LowDataRow({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>();
    final on = settings.state.lowDataMode;
    return Row(
      children: [
        const Expanded(child: Text('Mode faible consommation', style: TextStyle(fontSize: 17))),
        Text(
          on ? 'Activé' : 'Désactivé',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: on ? AppColors.green : AppColors.textSecondary),
        ),
        Switch(value: on, activeTrackColor: AppColors.green, onChanged: settings.setLowDataMode),
      ],
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
