import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/widgets.dart';
import '../../features/attendance/presentation/state/attendance_cubits.dart';
import '../../features/attendance/presentation/widgets/child_attendance_view.dart';
import '../../features/children/presentation/state/children_cubit.dart';
import '../../features/children/presentation/widgets/child_selector.dart';
import '../../features/grades/presentation/state/grades_cubits.dart';
import '../../features/grades/presentation/widgets/child_grades_view.dart';
import '../../core/utils/formatters.dart';
import '../../features/payments/presentation/state/payments_cubits.dart';
import '../../features/payments/presentation/widgets/financial_situation_view.dart';
import '../di/injection.dart';

/// Onglet « Suivi » du parent : Notes · Présences · Paiements.
/// Assemble les vues de trois fonctionnalités (rôle de la couche app).
class ParentTrackingPage extends StatefulWidget {
  const ParentTrackingPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ParentTrackingPage> createState() => _ParentTrackingPageState();
}

class _ParentTrackingPageState extends State<ParentTrackingPage> {
  static const _titles = ['Suivi de l’enfant', 'Présences', 'Paiements'];

  late int _tab = widget.initialTab;
  final _grades = sl<ChildGradesCubit>();
  final _attendance = sl<ChildAttendanceCubit>();
  final _payments = sl<FinancialSituationCubit>();
  String? _loadedFor;

  @override
  void didUpdateWidget(covariant ParentTrackingPage old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _grades.close();
    _attendance.close();
    _payments.close();
    super.dispose();
  }

  void _loadFor(String childId) {
    if (_loadedFor == childId) return;
    _loadedFor = childId;
    _grades.load(childId);
    _attendance.load(childId);
    _payments.load(childId);
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = context.watch<ChildrenCubit>().state;
    final child = childrenState.selected;
    if (child != null) _loadFor(child.id);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _grades),
        BlocProvider.value(value: _attendance),
        BlocProvider.value(value: _payments),
      ],
      child: AppPage(
        title: _titles[_tab],
        onRefresh: child == null
            ? null
            : () async {
                _loadedFor = null;
                _loadFor(child.id);
              },
        children: [
          PillSelector(
            labels: const ['Notes', 'Présences', 'Paiements'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          gap12,
          if (child == null)
            const Padding(padding: EdgeInsets.all(40), child: LoadingView())
          else ...[
            ChildSelector(
              suffix: switch (_tab) {
                1 => (_) => Formatters.monthYear(_attendance.month),
                2 => (c) => 'Année ${c.anneeScolaire}',
                _ => null,
              },
            ),
            gap12,
            switch (_tab) {
              0 => const ChildGradesView(),
              1 => ChildAttendanceView(canJustify: child.rights.canJustify),
              _ => FinancialSituationView(canPay: child.rights.canPay),
            },
          ],
        ],
      ),
    );
  }
}
