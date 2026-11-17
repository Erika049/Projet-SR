import '../../../../core/utils/result.dart';
import '../entities/attendance.dart';

abstract interface class AttendanceRepository {
  // Parent
  Future<Result<AttendanceSummary>> getChildAttendance(String childId, DateTime month);
  Future<Result<void>> justifyAbsence({
    required String recordId,
    required String reason,
    String? attachmentPath,
  });
  Future<Result<void>> reportError(String childId, String message);

  // Enseignant
  Future<Result<RollCall>> getRollCall(String classId);

  /// Retourne `true` si l'appel a été envoyé, `false` s'il est gardé hors connexion.
  Future<Result<bool>> saveRollCall(RollCall rollCall);

  Future<Result<MyAttendance>> getMyAttendance();
  Future<Result<MyAttendance>> signalMyPresence();
  Future<Result<MyAttendance>> signalMyAbsence(String reason);
}
