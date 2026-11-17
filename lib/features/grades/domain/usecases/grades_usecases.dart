import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/grades.dart';
import '../repositories/grades_repository.dart';

/// Règle de saisie : note entre 0 et le barème, ou « Abs. ».
abstract final class GradeRules {
  /// Retourne un message d'erreur, ou `null` si la saisie est valide (ou vide).
  static String? validate(String input, double scale) {
    final v = input.trim();
    if (v.isEmpty || isAbsent(v)) return null;
    final value = double.tryParse(v.replaceAll(',', '.'));
    if (value == null || value < 0 || value > scale) {
      return 'La note doit être comprise entre 0 et ${scale.toStringAsFixed(0)} (ou Abs.)';
    }
    return null;
  }

  static bool isAbsent(String input) => input.trim().toLowerCase().startsWith('abs');

  static double? parse(String input) => double.tryParse(input.trim().replaceAll(',', '.'));
}

class GetPeriods implements UseCase<List<Period>, String> {
  const GetPeriods(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<List<Period>>> call(String childId) => _repo.getPeriods(childId);
}

class GetChildGrades implements UseCase<GradesReport, ({String childId, String periodId})> {
  const GetChildGrades(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<GradesReport>> call(({String childId, String periodId}) p) =>
      _repo.getChildGrades(p.childId, p.periodId);
}

class GetReportCards implements UseCase<List<ReportCard>, String> {
  const GetReportCards(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<List<ReportCard>>> call(String childId) => _repo.getReportCards(childId);
}

class DownloadReportCard implements UseCase<String, ReportCard> {
  const DownloadReportCard(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<String>> call(ReportCard card) async {
    if (!card.published) return const Err(ValidationFailure('Bulletin non encore publié.'));
    return _repo.downloadReportCard(card.id);
  }
}

class GetGradeSheet implements UseCase<GradeSheet, String> {
  const GetGradeSheet(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<GradeSheet>> call(String classId) => _repo.getGradeSheet(classId);
}

class SaveGradeSheet implements UseCase<GradeSheet, ({GradeSheet sheet, bool submit})> {
  const SaveGradeSheet(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<GradeSheet>> call(({GradeSheet sheet, bool submit}) p) async {
    final sheet = p.sheet;
    final invalid = sheet.grades.any((g) => g.value != null && (g.value! < 0 || g.value! > sheet.scale));
    if (invalid) return const Err(ValidationFailure('Corrigez les notes hors barème.'));
    if (p.submit && sheet.grades.any((g) => !g.isFilled)) {
      return const Err(ValidationFailure('Toutes les notes doivent être saisies avant de soumettre.'));
    }
    return _repo.saveGradeSheet(sheet, submit: p.submit);
  }
}

typedef CorrectGradeParams = ({GradeSheet sheet, String studentId, String input, String reason});

/// Correction tracée d'une note, uniquement pendant la période ouverte (CU-ENS-05).
class CorrectGrade implements UseCase<void, CorrectGradeParams> {
  const CorrectGrade(this._repo, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final GradesRepository _repo;
  final DateTime Function() _now;

  @override
  Future<Result<void>> call(CorrectGradeParams p) async {
    final until = p.sheet.openUntil;
    if (until != null && _now().isAfter(until)) {
      return const Err(ValidationFailure('La période est clôturée : la note ne peut plus être modifiée.'));
    }
    final error = GradeRules.validate(p.input, p.sheet.scale);
    final value = GradeRules.parse(p.input);
    if (error != null || value == null) return Err(ValidationFailure(error ?? 'Saisissez une note.'));
    if (p.reason.trim().isEmpty) return const Err(ValidationFailure('Indiquez le motif de la correction.'));
    return _repo.correctGrade(
      evaluationId: p.sheet.evaluationId,
      studentId: p.studentId,
      value: value,
      reason: p.reason.trim(),
    );
  }
}

class GetAppreciations implements UseCase<List<Appreciation>, String> {
  const GetAppreciations(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<List<Appreciation>>> call(String classId) => _repo.getAppreciations(classId);
}

class SaveAppreciations implements UseCase<void, ({String classId, List<Appreciation> items})> {
  const SaveAppreciations(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<void>> call(({String classId, List<Appreciation> items}) p) =>
      _repo.saveAppreciations(p.classId, p.items);
}

class GetClassStats implements UseCase<ClassStats, String> {
  const GetClassStats(this._repo);
  final GradesRepository _repo;

  @override
  Future<Result<ClassStats>> call(String classId) => _repo.getClassStats(classId);
}
