import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/attendance.dart';
import '../state/attendance_cubits.dart';

/// Onglet « Présences » du suivi de l'enfant (CU-PAR-05).
class ChildAttendanceView extends StatelessWidget {
  const ChildAttendanceView({super.key, required this.canJustify});

  final bool canJustify;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChildAttendanceCubit>().state;
    return DataStateBuilder(
      state: state,
      onRetry: context.read<ChildAttendanceCubit>().reload,
      builder: (context, summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatTile(
            value: '${summary.absences}',
            label: summary.absences > 1 ? 'Absences' : 'Absence',
            tone: StatusTone.danger,
          ),
          gap12,
          if (summary.records.isEmpty)
            AppCard(
              child: Text(
                'Aucune absence ce mois-ci.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            )
          else
            AppCard(
              child: DividedColumn(
                children: [for (final r in summary.records) _RecordTile(record: r, canJustify: canJustify)],
              ),
            ),
          gap12,
          AppButton.secondary(label: 'Signaler une erreur', onPressed: () => _reportError(context)),
        ],
      ),
    );
  }

  Future<void> _reportError(BuildContext context) async {
    final controller = TextEditingController();
    final cubit = context.read<ChildAttendanceCubit>();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler une erreur'),
        content: AppTextField(controller: controller, hint: 'Ex. présente le 09 nov. à 8 h', maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Envoyer')),
        ],
      ),
    );
    controller.dispose();
    if (message == null) return;
    final error = await cubit.reportError(message);
    if (context.mounted) {
      context.showMessage(error ?? 'Signalement envoyé à la vie scolaire.', error: error != null);
    }
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.canJustify});

  final AttendanceRecord record;
  final bool canJustify;

  @override
  Widget build(BuildContext context) {
    final when = record.end == null
        ? '${Formatters.dayMonthUpper(record.start)} · ${Formatters.hour(record.start)}'
        : '${Formatters.dayMonthUpper(record.start)} · ${Formatters.slot(record.start, record.end!)}';
    final tone = switch (record.status) {
      JustificationStatus.aJustifier || JustificationStatus.refuse => StatusTone.danger,
      JustificationStatus.enAttente => StatusTone.warning,
      JustificationStatus.justifie => StatusTone.success,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          when,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(record.title, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        StatusChip(record.status.label, tone: tone),
        if (record.status == JustificationStatus.aJustifier && canJustify) ...[
          gap12,
          AppButton(
            label: 'Justifier l’absence',
            onPressed: () async {
              final sent = await context.push<bool>(Routes.parentJustify, extra: record);
              if (sent == true && context.mounted) await context.read<ChildAttendanceCubit>().reload();
            },
          ),
        ],
      ],
    );
  }
}
