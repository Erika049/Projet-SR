import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/grades.dart';
import '../state/grades_cubits.dart';

/// « Appréciations » (CU-ENS-06).
class AppreciationsPage extends StatelessWidget {
  const AppreciationsPage({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AppreciationsCubit>()..load(classId),
    child: _AppreciationsView(classId: classId),
  );
}

class _AppreciationsView extends StatefulWidget {
  const _AppreciationsView({required this.classId});
  final String classId;

  @override
  State<_AppreciationsView> createState() => _AppreciationsViewState();
}

class _AppreciationsViewState extends State<_AppreciationsView> {
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  TextEditingController _controllerFor(Appreciation a) =>
      _controllers.putIfAbsent(a.studentId, () => TextEditingController(text: a.text));

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(List<Appreciation> items) async {
    setState(() => _saving = true);
    final updated = [
      for (final a in items)
        Appreciation(studentId: a.studentId, studentName: a.studentName, text: _controllerFor(a).text.trim()),
    ];
    final msg = await context.read<AppreciationsCubit>().save(widget.classId, updated);
    if (!mounted) return;
    setState(() => _saving = false);
    context.showMessage(msg);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppreciationsCubit>().state;
    return AppPage(
      title: 'Appréciations',
      body: DataStateBuilder(
        state: state,
        onRetry: () => context.read<AppreciationsCubit>().load(widget.classId),
        builder: (context, items) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Mathématiques · Séquence 1', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            gap12,
            for (final a in items) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(a.studentName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    AppTextField(controller: _controllerFor(a), hint: 'Appréciation', maxLines: 2),
                  ],
                ),
              ),
              gap12,
            ],
            AppButton(label: 'Enregistrer les appréciations', loading: _saving, onPressed: () => _save(items)),
          ],
        ),
      ),
    );
  }
}
