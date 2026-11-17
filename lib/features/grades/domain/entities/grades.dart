import 'package:equatable/equatable.dart';

enum PeriodKind { sequence, trimestre }

/// Séquence ou trimestre (table `periode`).
class Period extends Equatable {
  const Period({required this.id, required this.label, required this.kind, required this.year});

  final String id;
  final String label; // « Séquence 1 »
  final PeriodKind kind;
  final String year; // « 2026–2027 »

  String get fullLabel => '$label · $year';

  @override
  List<Object?> get props => [id, label, kind, year];
}

/// Note d'une matière dans une période.
class SubjectGrade extends Equatable {
  const SubjectGrade({required this.subject, required this.coefficient, this.grade});

  final String subject;
  final double coefficient;

  /// `null` : non noté / absent.
  final double? grade;

  @override
  List<Object?> get props => [subject, coefficient, grade];
}

/// Résultats d'un enfant pour une période (CU-PAR-07).
class GradesReport extends Equatable {
  const GradesReport({
    required this.period,
    required this.subjects,
    this.rank,
    this.classSize,
    this.reportCardPublished = false,
  });

  final Period period;
  final List<SubjectGrade> subjects;
  final int? rank;
  final int? classSize;
  final bool reportCardPublished;

  /// Moyenne = Σ(note × coef.) / Σ coef. (notes saisies uniquement).
  double? get average {
    final graded = subjects.where((s) => s.grade != null);
    final coefs = graded.fold<double>(0, (sum, s) => sum + s.coefficient);
    if (coefs == 0) return null;
    return graded.fold<double>(0, (sum, s) => sum + s.grade! * s.coefficient) / coefs;
  }

  @override
  List<Object?> get props => [period, subjects, rank, classSize, reportCardPublished];
}

/// Bulletin d'une période (CU-PAR-08).
class ReportCard extends Equatable {
  const ReportCard({required this.id, required this.periodLabel, required this.published, this.fileUrl});

  final String id;
  final String periodLabel;
  final bool published;
  final String? fileUrl;

  @override
  List<Object?> get props => [id, periodLabel, published, fileUrl];
}

// ───────────────────────────── Enseignant ─────────────────────────────

/// Cycle de vie d'une feuille de notes.
enum GradeSheetStatus {
  brouillon('Brouillon'),
  soumis('Soumis'),
  valide('Validé'),
  publie('Publié');

  const GradeSheetStatus(this.label);
  final String label;
}

/// Note d'un élève dans une évaluation. [absent] = « Abs. ».
class StudentGrade extends Equatable {
  const StudentGrade({required this.studentId, required this.studentName, this.value, this.absent = false});

  final String studentId;
  final String studentName;
  final double? value;
  final bool absent;

  bool get isFilled => absent || value != null;

  @override
  List<Object?> get props => [studentId, studentName, value, absent];
}

/// Feuille de saisie d'une évaluation (CU-ENS-04).
class GradeSheet extends Equatable {
  const GradeSheet({
    required this.evaluationId,
    required this.classId,
    required this.className,
    required this.subject,
    required this.period,
    required this.evaluationLabel,
    required this.coefficient,
    required this.grades,
    this.scale = 20,
    this.status = GradeSheetStatus.brouillon,
    this.openUntil,
  });

  final String evaluationId;
  final String classId;
  final String className;
  final String subject;
  final Period period;
  final String evaluationLabel;
  final double coefficient;
  final double scale;
  final GradeSheetStatus status;
  final List<StudentGrade> grades;

  /// Fin de la période de saisie/correction.
  final DateTime? openUntil;

  bool get editable => status == GradeSheetStatus.brouillon;

  GradeSheet copyWith({List<StudentGrade>? grades, GradeSheetStatus? status}) => GradeSheet(
        evaluationId: evaluationId,
        classId: classId,
        className: className,
        subject: subject,
        period: period,
        evaluationLabel: evaluationLabel,
        coefficient: coefficient,
        scale: scale,
        status: status ?? this.status,
        openUntil: openUntil,
        grades: grades ?? this.grades,
      );

  @override
  List<Object?> get props =>
      [evaluationId, classId, className, subject, period, evaluationLabel, coefficient, scale, status, grades, openUntil];
}

/// Appréciation d'un élève (CU-ENS-06).
class Appreciation extends Equatable {
  const Appreciation({required this.studentId, required this.studentName, this.text = ''});

  final String studentId;
  final String studentName;
  final String text;

  @override
  List<Object?> get props => [studentId, studentName, text];
}

/// Statistiques d'une classe (CU-ENS-07).
class ClassStats extends Equatable {
  const ClassStats({
    required this.className,
    required this.periodLabel,
    required this.average,
    required this.highest,
    required this.lowest,
    required this.passRate,
  });

  final String className;
  final String periodLabel;
  final double average;
  final double highest;
  final double lowest;

  /// Part des élèves à 10 ou plus (0..1).
  final double passRate;

  @override
  List<Object?> get props => [className, periodLabel, average, highest, lowest, passRate];
}
