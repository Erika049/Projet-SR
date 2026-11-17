import '../../../../core/network/network_info.dart';
import '../../../../core/storage/sync_queue.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/grades.dart';
import '../../domain/repositories/grades_repository.dart';
import '../datasources/grades_remote_data_source.dart';
import '../models/grades_models.dart';

class GradesRepositoryImpl implements GradesRepository {
  const GradesRepositoryImpl(this._remote, this._network, this._queue);

  final GradesRemoteDataSource _remote;
  final NetworkInfo _network;
  final SyncQueue _queue;

  @override
  Future<Result<List<Period>>> getPeriods(String childId) => guard(() => _remote.getPeriods(childId));

  @override
  Future<Result<GradesReport>> getChildGrades(String childId, String periodId) =>
      guard(() => _remote.getChildGrades(childId, periodId));

  @override
  Future<Result<List<ReportCard>>> getReportCards(String childId) => guard(() => _remote.getReportCards(childId));

  @override
  Future<Result<String>> downloadReportCard(String reportCardId) =>
      guard(() => _remote.downloadReportCard(reportCardId));

  @override
  Future<Result<GradeSheet>> getGradeSheet(String classId) => guard(() => _remote.getGradeSheet(classId));

  @override
  Future<Result<GradeSheet>> saveGradeSheet(GradeSheet sheet, {required bool submit}) => guard(() async {
        if (!await _network.isConnected) {
          // Hors connexion : brouillon local, envoyé à la prochaine synchronisation.
          await _queue.put(PendingOperation(
            id: 'notes-${sheet.evaluationId}',
            kind: 'notes',
            label: 'Notes · ${sheet.className} · ${sheet.period.label}',
            draft: !submit,
            createdAt: DateTime.now(),
            payload: GradesMapper.sheetToJson(sheet),
          ));
          return sheet.copyWith(status: GradeSheetStatus.brouillon);
        }
        final saved = await _remote.saveGradeSheet(sheet, submit: submit);
        await _queue.remove('notes-${sheet.evaluationId}');
        return saved;
      });

  @override
  Future<Result<void>> correctGrade({
    required String evaluationId,
    required String studentId,
    required double value,
    required String reason,
  }) =>
      guard(() => _remote.correctGrade(evaluationId, studentId, value, reason));

  @override
  Future<Result<List<Appreciation>>> getAppreciations(String classId) =>
      guard(() => _remote.getAppreciations(classId));

  @override
  Future<Result<void>> saveAppreciations(String classId, List<Appreciation> items) =>
      guard(() => _remote.saveAppreciations(classId, items));

  @override
  Future<Result<ClassStats>> getClassStats(String classId) => guard(() => _remote.getClassStats(classId));
}
