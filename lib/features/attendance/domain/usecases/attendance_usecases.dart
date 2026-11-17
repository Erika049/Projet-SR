import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/attendance.dart';
import '../repositories/attendance_repository.dart';

class GetChildAttendance implements UseCase<AttendanceSummary, ({String childId, DateTime month})> {
  const GetChildAttendance(this._repo);
  final AttendanceRepository _repo;

  @override
  Future<Result<AttendanceSummary>> call(({String childId, DateTime month}) p) =>
      _repo.getChildAttendance(p.childId, DateTime(p.month.year, p.month.month));
}

typedef JustifyParams = ({AttendanceRecord record, String reason, String? attachmentPath});

/// Justifier une absence (CU-PAR-06). Validée ensuite par la surveillance.
class JustifyAbsence implements UseCase<void, JustifyParams> {
  const JustifyAbsence(this._repo);
  final AttendanceRepository _repo;

  @override
  Future<Result<void>> call(JustifyParams p) async {
    if (p.record.status != JustificationStatus.aJustifier) {
      return const Err(ValidationFailure('Cette absence a déjà été traitée.'));
    }
    if (p.reason.trim().isEmpty) return const Err(ValidationFailure('Indiquez le motif de l’absence.'));
    return _repo.justifyAbsence(recordId: p.record.id, reason: p.reason.trim(), attachmentPath: p.attachmentPath);
  }
}

class ReportAttendanceError implements UseCase<void, ({String childId, String message})> {
  const ReportAttendanceError(this._repo);
  final AttendanceRepository _repo;

  @override
  Future<Result<void>> call(({String childId, String message}) p) async {
    if (p.message.trim().isEmpty) return const Err(ValidationFailure('Décrivez l’erreur constatée.'));
    return _repo.reportError(p.childId, p.message.trim());
  }
}

class GetRollCall implements UseCase<RollCall, String> {
  const GetRollCall(this._repo);
  final AttendanceRepository _repo;

  @override
  Future<Result<RollCall>> call(String classId) => _repo.getRollCall(classId);
}

class SaveRollCall implements UseCase<bool, RollCall> {
  const SaveRollCall(this._repo);
  final AttendanceRepository _repo;

  @override
  Future<Result<bool>> call(RollCall rollCall) => _repo.saveRollCall(rollCall);
}

class GetMyAttendance implements UseCase<MyAttendance, NoParams> {
  const GetMyAttendance(this._repo);
  final AttendanceRepository _repo;

  @override
  Future<Result<MyAttendance>> call(NoParams _) => _repo.getMyAttendance();
}

class SignalMyPresence implements UseCase<MyAttendance, NoParams> {
  const SignalMyPresence(this._repo);
  final AttendanceRepository _repo;

  @override
  Future<Result<MyAttendance>> call(NoParams _) => _repo.signalMyPresence();
}

class SignalMyAbsence implements UseCase<MyAttendance, String> {
  const SignalMyAbsence(this._repo);
  final AttendanceRepository _repo;

  @override
  Future<Result<MyAttendance>> call(String reason) async {
    if (reason.trim().isEmpty) return const Err(ValidationFailure('Indiquez le motif de votre absence.'));
    return _repo.signalMyAbsence(reason.trim());
  }
}
