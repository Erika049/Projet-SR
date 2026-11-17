import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/view_status.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/usecases/attendance_usecases.dart';

/// Onglet « Présences » du parent.
class ChildAttendanceCubit extends Cubit<DataState<AttendanceSummary>> {
  ChildAttendanceCubit(this._get, this._report) : super(const DataState());

  final GetChildAttendance _get;
  final ReportAttendanceError _report;
  String? _childId;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> load(String childId, {DateTime? month}) async {
    _childId = childId;
    if (month != null) this.month = month;
    emit(const DataState(status: ViewStatus.loading));
    final result = await _get((childId: childId, month: this.month));
    emit(result.fold(state.error, state.success));
  }

  Future<void> reload() async {
    if (_childId != null) await load(_childId!);
  }

  Future<String?> reportError(String message) async {
    final result = await _report((childId: _childId ?? '', message: message));
    return result.fold((f) => f.message, (_) => null);
  }
}

/// « Justifier l'absence ».
class JustifyCubit extends Cubit<SubmitState> {
  JustifyCubit(this._justify) : super(const SubmitState());
  final JustifyAbsence _justify;

  Future<void> submit(JustifyParams params) async {
    emit(const SubmitState(status: ViewStatus.loading));
    final result = await _justify(params);
    emit(
      result.fold(
        (f) => SubmitState(status: ViewStatus.failure, error: f.message),
        (_) => const SubmitState(status: ViewStatus.success),
      ),
    );
  }
}

class RollCallState extends Equatable {
  const RollCallState({this.rollCall = const DataState(), this.query = '', this.saving = false, this.message});

  final DataState<RollCall> rollCall;
  final String query;
  final bool saving;
  final String? message;

  List<RollCallEntry> get visible {
    final entries = rollCall.data?.entries ?? const [];
    if (query.isEmpty) return entries;
    final q = query.toLowerCase();
    return entries.where((e) => e.studentName.toLowerCase().contains(q)).toList();
  }

  RollCallState copyWith({DataState<RollCall>? rollCall, String? query, bool? saving, String? message}) =>
      RollCallState(
        rollCall: rollCall ?? this.rollCall,
        query: query ?? this.query,
        saving: saving ?? this.saving,
        message: message,
      );

  @override
  List<Object?> get props => [rollCall, query, saving, message];
}

/// « Faire l'appel » (CU-ENS-03).
class RollCallCubit extends Cubit<RollCallState> {
  RollCallCubit(this._get, this._save) : super(const RollCallState());

  final GetRollCall _get;
  final SaveRollCall _save;

  Future<void> load(String classId) async {
    emit(state.copyWith(rollCall: state.rollCall.loading()));
    final result = await _get(classId);
    emit(state.copyWith(rollCall: result.fold(state.rollCall.error, state.rollCall.success)));
  }

  void search(String query) => emit(state.copyWith(query: query.trim()));

  void mark(String studentId, RollCallStatus status) {
    final rc = state.rollCall.data;
    if (rc == null) return;
    emit(
      state.copyWith(
        rollCall: state.rollCall.success(
          rc.withEntries([for (final e in rc.entries) e.studentId == studentId ? e.withStatus(status) : e]),
        ),
      ),
    );
  }

  void allPresent() {
    final rc = state.rollCall.data;
    if (rc == null) return;
    emit(
      state.copyWith(
        rollCall: state.rollCall.success(
          rc.withEntries([for (final e in rc.entries) e.withStatus(RollCallStatus.present)]),
        ),
      ),
    );
  }

  Future<void> save() async {
    final rc = state.rollCall.data;
    if (rc == null) return;
    emit(state.copyWith(saving: true));
    final result = await _save(rc);
    emit(
      state.copyWith(
        saving: false,
        message: result.fold(
          (f) => f.message,
          (online) => online
              ? 'Appel enregistré. Les parents des absents sont notifiés.'
              : 'Hors connexion : appel enregistré sur ce téléphone.',
        ),
      ),
    );
  }
}

/// « Ma présence » (CU-ENS-08).
class MyAttendanceCubit extends Cubit<DataState<MyAttendance>> {
  MyAttendanceCubit(this._get, this._present, this._absent) : super(const DataState());

  final GetMyAttendance _get;
  final SignalMyPresence _present;
  final SignalMyAbsence _absent;

  Future<void> load() async {
    emit(state.loading());
    final result = await _get(const NoParams());
    emit(result.fold(state.error, state.success));
  }

  Future<String> signalPresence() async {
    final result = await _present(const NoParams());
    return result.fold((f) => f.message, (me) {
      emit(state.success(me));
      return 'Présence enregistrée.';
    });
  }

  Future<String> signalAbsence(String reason) async {
    final result = await _absent(reason);
    return result.fold((f) => f.message, (me) {
      emit(state.success(me));
      return 'Absence signalée à l’établissement.';
    });
  }
}
