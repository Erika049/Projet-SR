import '../../../../core/utils/result.dart';
import '../entities/grades.dart';

abstract interface class GradesRepository {
  // Parent
  Future<Result<List<Period>>> getPeriods(String childId);
  Future<Result<GradesReport>> getChildGrades(String childId, String periodId);
  Future<Result<List<ReportCard>>> getReportCards(String childId);
  Future<Result<String>> downloadReportCard(String reportCardId);

  // Enseignant
  Future<Result<GradeSheet>> getGradeSheet(String classId);

  /// Enregistre la feuille. Hors connexion, elle reste en brouillon local
  /// et est ajoutée à la file de synchronisation.
  Future<Result<GradeSheet>> saveGradeSheet(GradeSheet sheet, {required bool submit});

  Future<Result<void>> correctGrade({
    required String evaluationId,
    required String studentId,
    required double value,
    required String reason,
  });

  Future<Result<List<Appreciation>>> getAppreciations(String classId);
  Future<Result<void>> saveAppreciations(String classId, List<Appreciation> items);
  Future<Result<ClassStats>> getClassStats(String classId);
}
