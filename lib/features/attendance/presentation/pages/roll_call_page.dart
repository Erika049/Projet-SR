import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/attendance.dart';
import '../state/attendance_cubits.dart';

/// « Faire l'appel » (CU-ENS-03). Fonctionne hors connexion.
class RollCallPage extends StatelessWidget {
  const RollCallPage({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(classId),
    create: (_) => sl<RollCallCubit>()..load(classId),
    child: _RollCallView(classId: classId),
  );
}

class _RollCallView extends StatelessWidget {
  const _RollCallView({required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RollCallCubit>().state;
    final cubit = context.read<RollCallCubit>();

    return BlocListener<RollCallCubit, RollCallState>(
      listenWhen: (a, b) => b.message != null && a.message != b.message,
      listener: (context, s) => context.showMessage(s.message!),
      child: AppPage(
        eyebrow: 'SCHOOLCONNECT · ENSEIGNANT',
        title: 'Faire l’appel',
        body: DataStateBuilder(
          state: state.rollCall,
          onRetry: () => cubit.load(classId),
          builder: (context, rc) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              FutureBuilder<bool>(
                future: sl<NetworkInfo>().isConnected,
                builder: (context, snap) => snap.data == false
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: InfoBanner.offline('Hors connexion · enregistré sur ce téléphone'),
                      )
                    : const SizedBox.shrink(),
              ),
              Text(
                '${rc.className} · ${rc.subject}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                '${DateFormat('dd MMM', 'fr_FR').format(rc.start)} · '
                '${Formatters.slot(rc.start, rc.end).toLowerCase()} · ${rc.entries.length} élèves',
                style: context.text.bodySmall?.copyWith(fontSize: 15),
              ),
              gap12,
              Row(
                children: [
                  StatusChip('${rc.count(RollCallStatus.present)} P'),
                  const SizedBox(width: 8),
                  StatusChip('${rc.count(RollCallStatus.absent)} A', tone: StatusTone.danger),
                  const SizedBox(width: 8),
                  StatusChip('${rc.count(RollCallStatus.retard)} R', tone: StatusTone.warning),
                  const Spacer(),
                  StatusChip('Tous présents', onTap: cubit.allPresent),
                ],
              ),
              gap12,
              AppTextField(
                hint: 'Rechercher un élève',
                onChanged: cubit.search,
                textInputAction: TextInputAction.search,
              ),
              gap12,
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: DividedColumn(
                  spacing: 10,
                  children: [
                    for (final e in state.visible) _StudentRow(entry: e, onMark: (s) => cubit.mark(e.studentId, s)),
                  ],
                ),
              ),
              HelpText('${state.visible.length} élèves affichés sur ${rc.entries.length}'),
              AppButton(label: 'Enregistrer l’appel', loading: state.saving, onPressed: cubit.save),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.entry, required this.onMark});

  final RollCallEntry entry;
  final ValueChanged<RollCallStatus> onMark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(entry.studentName, style: const TextStyle(fontSize: 17))),
        for (final (status, label, color) in [
          (RollCallStatus.present, 'P', AppColors.green),
          (RollCallStatus.absent, 'A', AppColors.red),
          (RollCallStatus.retard, 'R', AppColors.amber),
        ]) ...[
          const SizedBox(width: 8),
          _StatusButton(
            label: label,
            color: color,
            active: entry.status == status,
            onTap: () => onMark(status),
            semantics: '${entry.studentName} : ${status.name}',
          ),
        ],
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
    required this.semantics,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      selected: active,
      button: true,
      child: Material(
        color: active ? color : AppColors.greySoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
