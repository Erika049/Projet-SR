import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../children/presentation/state/children_cubit.dart';
import '../../domain/entities/attendance.dart';
import '../state/attendance_cubits.dart';

/// « Justifier l'absence » (CU-PAR-06).
class JustifyAbsencePage extends StatelessWidget {
  const JustifyAbsencePage({super.key, required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<JustifyCubit>(),
    child: _JustifyView(record: record),
  );
}

class _JustifyView extends StatefulWidget {
  const _JustifyView({required this.record});
  final AttendanceRecord record;

  @override
  State<_JustifyView> createState() => _JustifyViewState();
}

class _JustifyViewState extends State<_JustifyView> {
  final _reason = TextEditingController();
  PlatformFile? _file;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (files.isNotEmpty) setState(() => _file = files.first);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final child = context.read<ChildrenCubit>().state.selected;
    final state = context.watch<JustifyCubit>().state;
    final allDay = r.end == null && r.start.hour == 0 && r.start.minute == 0;
    final when = allDay
        ? Formatters.shortDate(r.start)
        : r.end == null
        ? '${Formatters.shortDate(r.start)}, ${Formatters.hour(r.start).toLowerCase()}'
        : '${Formatters.shortDate(r.start)}, ${Formatters.slot(r.start, r.end!).toLowerCase()}';

    return BlocListener<JustifyCubit, SubmitState>(
      listener: (context, s) {
        if (s.status == ViewStatus.failure) context.showMessage(s.error!, error: true);
        if (s.isDone) {
          context.showMessage('Justificatif envoyé. Vous serez notifié de la décision.');
          context.pop(true);
        }
      },
      child: AppPage(
        title: 'Justifier l’absence',
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (child != null) Text(child.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${r.title} · $when', style: context.text.bodySmall?.copyWith(fontSize: 15)),
              ],
            ),
          ),
          gap12,
          AppTextField(controller: _reason, hint: 'Motif (ex. consultation médicale)', maxLines: 2),
          gap12,
          AppButton.secondary(label: 'Ajouter une photo ou un fichier', onPressed: _pickFile),
          if (_file != null) ...[
            gap12,
            Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(_file!.name, onTap: () => setState(() => _file = null)),
            ),
          ],
          gap12,
          AppButton(
            label: 'Envoyer',
            loading: state.isSubmitting,
            onPressed: () =>
                context.read<JustifyCubit>().submit((record: r, reason: _reason.text, attachmentPath: _file?.path)),
          ),
          const HelpText('Le surveillant général vérifie le justificatif. Vous serez notifié de sa décision.'),
        ],
      ),
    );
  }
}
