import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/attendance.dart';
import '../state/attendance_cubits.dart';

/// « Ma présence » (CU-ENS-08).
class MyAttendancePage extends StatelessWidget {
  const MyAttendancePage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<MyAttendanceCubit>()..load(), child: const _MyAttendanceView());
}

class _MyAttendanceView extends StatelessWidget {
  const _MyAttendanceView();

  Future<void> _absence(BuildContext context) async {
    final controller = TextEditingController();
    final cubit = context.read<MyAttendanceCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler une absence'),
        content: AppTextField(controller: controller, hint: 'Motif', maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Envoyer')),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    final msg = await cubit.signalAbsence(reason);
    if (context.mounted) context.showMessage(msg);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyAttendanceCubit>().state;
    final cubit = context.read<MyAttendanceCubit>();
    return AppPage(
      title: 'Ma présence',
      onRefresh: cubit.load,
      body: DataStateBuilder(
        state: state,
        onRetry: cubit.load,
        builder: (context, me) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.longDate(me.today, withYear: false),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  if (me.firstCourse != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Premier cours : ${DateFormat("HH 'h' mm").format(me.firstCourse!)}',
                      style: context.text.bodySmall?.copyWith(fontSize: 15),
                    ),
                  ],
                  if (me.todayStatus != null) ...[
                    gap12,
                    StatusChip(
                      'Aujourd’hui : ${me.todayStatus!.label}',
                      tone: me.todayStatus == StaffStatus.present ? StatusTone.success : StatusTone.danger,
                    ),
                  ],
                ],
              ),
            ),
            gap12,
            AppButton(
              label: 'Signaler ma présence',
              onPressed: me.todayStatus == null
                  ? () async {
                      final msg = await cubit.signalPresence();
                      if (context.mounted) context.showMessage(msg);
                    }
                  : null,
            ),
            gap12,
            AppButton.secondary(
              label: 'Signaler une absence',
              onPressed: me.todayStatus == null ? () => _absence(context) : null,
            ),
            gap20,
            const SectionTitle('Historique'),
            AppCard(
              child: DividedColumn(
                children: [
                  for (final d in me.history)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM', 'fr_FR').format(d.date),
                            style: const TextStyle(fontSize: 17),
                          ),
                        ),
                        StatusChip(
                          d.status == StaffStatus.retard ? 'Retard · ${d.minutesLate} min' : d.status.label,
                          tone: switch (d.status) {
                            StaffStatus.present => StatusTone.success,
                            StaffStatus.retard => StatusTone.warning,
                            StaffStatus.absent => StatusTone.danger,
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
