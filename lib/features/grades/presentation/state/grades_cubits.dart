import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/view_status.dart';
import '../../domain/entities/grades.dart';
import '../../domain/usecases/grades_usecases.dart';

// ───────────────────────────── Parent : notes ─────────────────────────────

class ChildGradesState extends Equatable {
  const ChildGradesState({
    this.periods = const [],
    this.kind = PeriodKind.sequence,
    this.periodId,
    this.report = const DataState(),
  });

  final List<Period> periods;
  final PeriodKind kind;
  final String? periodId;
  final DataState<GradesReport> report;

  List<Period> get visiblePeriods => periods.where((p) => p.kind == kind).toList();
  Period? get period => periods.where((p) => p.id == periodId).firstOrNull;

  ChildGradesState copyWith({
    List<Period>? periods,
    PeriodKind? kind,
    String? periodId,
    DataState<GradesReport>? report,
  }) =>
      ChildGradesState(
        periods: periods ?? this.periods,
        kind: kind ?? this.kind,
        periodId: periodId ?? this.periodId,
        report: report ?? this.report,
      );

  @override
  List<Object?> get props => [periods, kind, periodId, report];
}

class ChildGradesCubit extends Cubit<ChildGradesState> {
  ChildGradesCubit(this._getPeriods, this._getGrades) : super(const ChildGradesState());

  final GetPeriods _getPeriods;
  final GetChildGrades _getGrades;
  String? _childId;

  Future<void> load(String childId) async {
    _childId = childId;
    emit(state.copyWith(report: state.report.loading()));
    final result = await _getPeriods(childId);
    await result.fold(
      (f) async => emit(state.copyWith(report: state.report.error(f))),
      (periods) async {
        final first = periods.where((p) => p.kind == state.kind).firstOrNull ?? periods.firstOrNull;
        emit(state.copyWith(periods: periods, periodId: state.period?.id ?? first?.id));
        await _loadReport();
      },
    );
  }

  Future<void> selectKind(PeriodKind kind) async {
    final first = state.periods.where((p) => p.kind == kind).firstOrNull;
    emit(state.copyWith(kind: kind, periodId: first?.id));
    await _loadReport();
  }

  Future<void> selectPeriod(String periodId) async {
    emit(state.copyWith(periodId: periodId));
    await _loadReport();
  }

  Future<void> _loadReport() async {
    final childId = _childId;
    final periodId = state.periodId;
    if (childId == null || periodId == null) return;
    emit(state.copyWith(report: const DataState(status: ViewStatus.loading)));
    final result = await _getGrades((childId: childId, periodId: periodId));
    emit(state.copyWith(report: result.fold(state.report.error, state.report.success)));
  }
}

// ───────────────────────────── Parent : bulletins ─────────────────────────────

class ReportCardsCubit extends Cubit<DataState<List<ReportCard>>> {
  ReportCardsCubit(this._get, this._download) : super(const DataState());

  final GetReportCards _get;
  final DownloadReportCard _download;

  Future<void> load(String childId) async {
    emit(const DataState(status: ViewStatus.loading));
    final result = await _get(childId);
    emit(result.fold(state.error, state.success));
  }

  /// Retourne le message à afficher.
  Future<String> download(ReportCard card) async {
    final result = await _download(card);
    return result.fold((f) => f.message, (file) => 'Bulletin téléchargé : $file');
  }
}

// ───────────────────────────── Enseignant : saisie ─────────────────────────────

class GradeSheetState extends Equatable {
  const GradeSheetState({this.sheet = const DataState(), this.inputs = const {}, this.saving = false, this.message});

  final DataState<GradeSheet> sheet;

  /// Saisie brute par élève (« 16,0 », « Abs. », « 21 »).
  final Map<String, String> inputs;
  final bool saving;
  final String? message;

  double get scale => sheet.data?.scale ?? 20;

  String? errorFor(String studentId) => GradeRules.validate(inputs[studentId] ?? '', scale);

  int get errorCount => inputs.keys.where((id) => errorFor(id) != null).length;

  int get validCount =>
      inputs.entries.where((e) => e.value.trim().isNotEmpty && errorFor(e.key) == null).length;

  int get remaining => (sheet.data?.grades.length ?? 0) - validCount - errorCount;

  bool get canSubmit => errorCount == 0 && remaining == 0 && (sheet.data?.editable ?? false);

  GradeSheetState copyWith({
    DataState<GradeSheet>? sheet,
    Map<String, String>? inputs,
    bool? saving,
    String? message,
  }) =>
      GradeSheetState(
        sheet: sheet ?? this.sheet,
        inputs: inputs ?? this.inputs,
        saving: saving ?? this.saving,
        message: message,
      );

  @override
  List<Object?> get props => [sheet, inputs, saving, message];
}

class GradeSheetCubit extends Cubit<GradeSheetState> {
  GradeSheetCubit(this._get, this._save) : super(const GradeSheetState());

  final GetGradeSheet _get;
  final SaveGradeSheet _save;

  Future<void> load(String classId) async {
    emit(state.copyWith(sheet: state.sheet.loading()));
    final result = await _get(classId);
    result.fold(
      (f) => emit(state.copyWith(sheet: state.sheet.error(f))),
      (sheet) => emit(state.copyWith(
        sheet: state.sheet.success(sheet),
        inputs: {
          for (final g in sheet.grades)
            g.studentId: g.absent ? 'Abs.' : (g.value == null ? '' : g.value!.toStringAsFixed(1).replaceAll('.', ',')),
        },
      )),
    );
  }

  void setInput(String studentId, String value) =>
      emit(state.copyWith(inputs: {...state.inputs, studentId: value}));

  Future<void> save({required bool submit}) async {
    final sheet = state.sheet.data;
    if (sheet == null) return;
    final grades = [
      for (final g in sheet.grades)
        () {
          final input = state.inputs[g.studentId] ?? '';
          final absent = GradeRules.isAbsent(input);
          return StudentGrade(
            studentId: g.studentId,
            studentName: g.studentName,
            absent: absent,
            value: absent ? null : GradeRules.parse(input),
          );
        }(),
    ];
    emit(state.copyWith(saving: true));
    final result = await _save((sheet: sheet.copyWith(grades: grades), submit: submit));
    result.fold(
      (f) => emit(state.copyWith(saving: false, message: f.message)),
      (saved) => emit(state.copyWith(
        saving: false,
        sheet: state.sheet.success(saved),
        message: saved.status == GradeSheetStatus.soumis
            ? 'Notes soumises pour validation.'
            : 'Brouillon enregistré.',
      )),
    );
  }
}

class CorrectionCubit extends Cubit<SubmitState> {
  CorrectionCubit(this._correct) : super(const SubmitState());
  final CorrectGrade _correct;

  Future<void> submit(CorrectGradeParams params) async {
    emit(const SubmitState(status: ViewStatus.loading));
    final result = await _correct(params);
    emit(result.fold(
      (f) => SubmitState(status: ViewStatus.failure, error: f.message),
      (_) => const SubmitState(status: ViewStatus.success),
    ));
  }
}

// ───────────────────────────── Enseignant : appréciations / stats ─────────────────────────────

class AppreciationsCubit extends Cubit<DataState<List<Appreciation>>> {
  AppreciationsCubit(this._get, this._save) : super(const DataState());

  final GetAppreciations _get;
  final SaveAppreciations _save;

  Future<void> load(String classId) async {
    emit(const DataState(status: ViewStatus.loading));
    final result = await _get(classId);
    emit(result.fold(state.error, state.success));
  }

  Future<String> save(String classId, List<Appreciation> items) async {
    final result = await _save((classId: classId, items: items));
    return result.fold((f) => f.message, (_) {
      emit(state.success(items));
      return 'Appréciations enregistrées.';
    });
  }
}

class ClassStatsCubit extends Cubit<DataState<ClassStats>> {
  ClassStatsCubit(this._get) : super(const DataState());
  final GetClassStats _get;

  Future<void> load(String classId) async {
    emit(const DataState(status: ViewStatus.loading));
    final result = await _get(classId);
    emit(result.fold(state.error, state.success));
  }
}
