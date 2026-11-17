import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/mock_delay.dart';
import '../../domain/entities/grades.dart';

abstract interface class GradesRemoteDataSource {
  Future<List<Period>> getPeriods(String childId);
  Future<GradesReport> getChildGrades(String childId, String periodId);
  Future<List<ReportCard>> getReportCards(String childId);
  Future<String> downloadReportCard(String reportCardId);
  Future<GradeSheet> getGradeSheet(String classId);
  Future<GradeSheet> saveGradeSheet(GradeSheet sheet, {required bool submit});
  Future<void> correctGrade(String evaluationId, String studentId, double value, String reason);
  Future<List<Appreciation>> getAppreciations(String classId);
  Future<void> saveAppreciations(String classId, List<Appreciation> items);
  Future<ClassStats> getClassStats(String classId);
}

/// Données de démonstration (maquettes : Amina 3e A, M. Kamga).
class GradesMockDataSource implements GradesRemoteDataSource {
  static const _year = '2026–2027';
  static const _periods = [
    Period(id: 'seq1', label: 'Séquence 1', kind: PeriodKind.sequence, year: _year),
    Period(id: 'seq2', label: 'Séquence 2', kind: PeriodKind.sequence, year: _year),
    Period(id: 'tri1', label: 'Trimestre 1', kind: PeriodKind.trimestre, year: _year),
  ];

  static const classStudents = {
    '3eA': ['Amina Etame', 'Boris Fotso', 'Carine Mbarga', 'David Njoya', 'Esther Ngo', 'Franck Tchoua'],
    '4eB': ['Gaëlle Abena', 'Hervé Nana', 'Irène Mballa', 'Jules Onana'],
    '2ndeC': ['Kevin Ateba', 'Laure Bella', 'Marc Essomba', 'Nadia Fouda'],
  };

  static String className(String classId) =>
      {'3eA': '3e A', '4eB': '4e B', '2ndeC': '2nde C'}[classId] ?? classId;

  final Map<String, GradeSheet> _sheets = {};
  final Map<String, List<Appreciation>> _appreciations = {};

  @override
  Future<List<Period>> getPeriods(String childId) async {
    await mockDelay(200);
    return _periods;
  }

  @override
  Future<GradesReport> getChildGrades(String childId, String periodId) async {
    await mockDelay();
    final period = _periods.firstWhere((p) => p.id == periodId);
    if (childId == 'eleve-junior' || periodId != 'seq1') {
      // Notes non encore publiées.
      return GradesReport(period: period, subjects: const []);
    }
    return GradesReport(
      period: period,
      rank: 5,
      classSize: 52,
      subjects: const [
        SubjectGrade(subject: 'Mathématiques', coefficient: 4, grade: 16),
        SubjectGrade(subject: 'Français', coefficient: 4, grade: 14),
        SubjectGrade(subject: 'Anglais', coefficient: 3, grade: 13.5),
      ],
    );
  }

  @override
  Future<List<ReportCard>> getReportCards(String childId) async {
    await mockDelay();
    final amina = childId == 'eleve-amina';
    return [
      ReportCard(id: '$childId-seq1', periodLabel: 'Séquence 1', published: amina, fileUrl: amina ? 'https://example.cm/b1.pdf' : null),
      ReportCard(id: '$childId-seq2', periodLabel: 'Séquence 2', published: false),
      ReportCard(id: '$childId-tri1', periodLabel: 'Trimestre 1', published: false),
    ];
  }

  @override
  Future<String> downloadReportCard(String reportCardId) async {
    await mockDelay(700);
    return 'bulletin_$reportCardId.pdf';
  }

  @override
  Future<GradeSheet> getGradeSheet(String classId) async {
    await mockDelay();
    return _sheets[classId] ??
        GradeSheet(
          evaluationId: 'eval-$classId-ds1',
          classId: classId,
          className: className(classId),
          subject: 'Mathématiques',
          period: _periods.first,
          evaluationLabel: 'Devoir surveillé',
          coefficient: 4,
          openUntil: DateTime(2026, 11, 20, 23, 59),
          grades: [
            for (final (i, name) in (classStudents[classId] ?? const []).indexed)
              StudentGrade(studentId: '$classId-$i', studentName: name),
          ],
        );
  }

  @override
  Future<GradeSheet> saveGradeSheet(GradeSheet sheet, {required bool submit}) async {
    await mockDelay();
    final saved = sheet.copyWith(status: submit ? GradeSheetStatus.soumis : GradeSheetStatus.brouillon);
    _sheets[sheet.classId] = saved;
    return saved;
  }

  @override
  Future<void> correctGrade(String evaluationId, String studentId, double value, String reason) async {
    await mockDelay();
    final classId = studentId.split('-').first;
    final sheet = _sheets[classId];
    if (sheet == null) throw const ServerException('Évaluation introuvable.');
    _sheets[classId] = sheet.copyWith(grades: [
      for (final g in sheet.grades)
        g.studentId == studentId
            ? StudentGrade(studentId: g.studentId, studentName: g.studentName, value: value)
            : g,
    ]);
  }

  @override
  Future<List<Appreciation>> getAppreciations(String classId) async {
    await mockDelay();
    return _appreciations[classId] ??
        [
          for (final (i, name) in (classStudents[classId] ?? const []).indexed)
            Appreciation(
              studentId: '$classId-$i',
              studentName: name,
              text: switch (i) { 0 => 'Très bon travail, continuez.', 1 => 'Peut mieux faire.', _ => '' },
            ),
        ];
  }

  @override
  Future<void> saveAppreciations(String classId, List<Appreciation> items) async {
    await mockDelay();
    _appreciations[classId] = items;
  }

  @override
  Future<ClassStats> getClassStats(String classId) async {
    await mockDelay();
    return ClassStats(
      className: className(classId),
      periodLabel: 'Séquence 1',
      average: 11.9,
      highest: 17.5,
      lowest: 4,
      passRate: 0.71,
    );
  }
}
