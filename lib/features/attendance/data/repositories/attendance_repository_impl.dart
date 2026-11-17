import 'package:intl/intl.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/storage/sync_queue.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';
import '../models/attendance_models.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  const AttendanceRepositoryImpl(this._remote, this._network, this._queue);

  final AttendanceRemoteDataSource _remote;
  final NetworkInfo _network;
  final SyncQueue _queue;

  @override
  Future<Result<AttendanceSummary>> getChildAttendance(String childId, DateTime month) =>
      guard(() => _remote.getChildAttendance(childId, month));

  @override
  Future<Result<void>> justifyAbsence({required String recordId, required String reason, String? attachmentPath}) =>
      guard(() => _remote.justifyAbsence(recordId, reason, attachmentPath));

  @override
  Future<Result<void>> reportError(String childId, String message) =>
      guard(() => _remote.reportError(childId, message));

  @override
  Future<Result<RollCall>> getRollCall(String classId) => guard(() => _remote.getRollCall(classId));

  @override
  Future<Result<bool>> saveRollCall(RollCall rollCall) => guard(() async {
    if (!await _network.isConnected) {
      await _queue.put(
        PendingOperation(
          id: rollCall.id,
          kind: 'appel',
          label: 'Appel · ${rollCall.className} · ${DateFormat('dd MMM', 'fr_FR').format(rollCall.start)}',
          draft: false,
          createdAt: DateTime.now(),
          payload: AttendanceMapper.rollCallToJson(rollCall),
        ),
      );
      return false;
    }
    await _remote.saveRollCall(rollCall);
    await _queue.remove(rollCall.id);
    return true;
  });

  @override
  Future<Result<MyAttendance>> getMyAttendance() => guard(_remote.getMyAttendance);

  @override
  Future<Result<MyAttendance>> signalMyPresence() => guard(_remote.signalMyPresence);

  @override
  Future<Result<MyAttendance>> signalMyAbsence(String reason) => guard(() => _remote.signalMyAbsence(reason));
}
