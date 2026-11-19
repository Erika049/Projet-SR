import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/network/teacher_api_context.dart';
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

/// Backend SchoolConnect.
///
/// - Parent : `GET /mes-enfants/{eleveId}/notes` (moyenne et notes par matière).
/// - Enseignant : `POST /etablissements/{etab}/classes/{classe}/matieres/{matiere}/evaluations`
///   à la soumission, `PATCH …/evaluations/{id}` pour corriger. Les brouillons restent sur le téléphone.
class GradesApiDataSource implements GradesRemoteDataSource {
  GradesApiDataSource(this._api, this._teacher);

  final ApiClient _api;
  final TeacherApiContext _teacher;

  /// Feuilles ouvertes pendant la session (classe → feuille), avec l'id d'évaluation une fois envoyée.
  final Map<String, GradeSheet> _sheets = {};

  /// Vue « toutes les notes de l'année » (sans filtre de période).
  static const _allPeriods = Period(id: '', label: 'Toute l’année', kind: PeriodKind.sequence, year: '');

  /// Périodes de l'enfant, gardées pour retrouver le libellé de la période affichée.
  final Map<String, Period> _periods = {};

  @override
  Future<List<Period>> getPeriods(String childId) async {
    final raw = ApiJson.list(await _api.get('/mes-enfants/$childId/periodes'));
    final now = DateTime.now();
    final list = <Period>[];
    Period? current;
    for (final p in raw) {
      final period = Period(
        id: p['id'] as String,
        label: TeacherApiContext.periodLabel(p),
        kind: p['type'] == 'SEQUENCE' ? PeriodKind.sequence : PeriodKind.trimestre,
        year: '',
      );
      if (p['type'] == 'ANNUELLE') continue;
      _periods[period.id] = period;
      list.add(period);
      final start = ApiJson.parseDate(p['dateDebut']);
      final end = ApiJson.parseDate(p['dateFin']);
      if (p['type'] == 'SEQUENCE' && start != null && end != null && !now.isBefore(start) && !now.isAfter(end)) {
        current = period;
      }
    }
    // Séquence en cours en premier (vue par défaut), puis les autres, puis « Toute l'année ».
    if (current != null) {
      list
        ..remove(current)
        ..insert(0, current);
    }
    return [...list, _allPeriods];
  }

  @override
  Future<GradesReport> getChildGrades(String childId, String periodId) async {
    final rows = ApiJson.list(
      await _api.get('/mes-enfants/$childId/notes', query: {if (periodId.isNotEmpty) 'periodeId': periodId}),
    );
    return GradesReport(
      period: _periods[periodId] ?? _allPeriods,
      subjects: [
        for (final (i, m) in rows.indexed)
          SubjectGrade(
            subject: m['matiereNom'] as String? ?? 'Matière ${i + 1}',
            coefficient: ApiJson.toDouble(m['coefficient']) ?? 1,
            grade: ApiJson.toDouble(m['moyenne']),
          ),
      ],
    );
  }

  @override
  Future<List<ReportCard>> getReportCards(String childId) => notAvailableOnServer('Les bulletins');

  @override
  Future<String> downloadReportCard(String reportCardId) => notAvailableOnServer('Le téléchargement des bulletins');

  @override
  Future<GradeSheet> getGradeSheet(String classId) async {
    final a = await _teacher.resolve(classId);
    final cached = _sheets[a.classId];
    if (cached != null) return cached;
    final period = await _teacher.currentPeriod(a.schoolYearId);
    final students = await _teacher.students(a);
    if (students.isEmpty) throw const ServerException('Aucun élève n’est inscrit dans cette classe.');
    return _sheets[a.classId] = GradeSheet(
      evaluationId: '',
      classId: a.classId,
      className: a.className,
      subject: a.subject,
      period: Period(
        id: period.id,
        label: period.label,
        kind: period.isSequence ? PeriodKind.sequence : PeriodKind.trimestre,
        year: '',
      ),
      evaluationLabel: 'Devoir surveillé',
      coefficient: 1,
      grades: [for (final s in students) StudentGrade(studentId: s.id, studentName: s.name)],
    );
  }

  List<Map<String, dynamic>> _notes(Iterable<StudentGrade> grades) => [
    for (final g in grades.where((g) => g.isFilled))
      {'eleveId': g.studentId, if (!g.absent) 'valeur': g.value, 'absent': g.absent},
  ];

  @override
  Future<GradeSheet> saveGradeSheet(GradeSheet sheet, {required bool submit}) async {
    if (!submit) {
      // Brouillon : conservé sur le téléphone, envoyé à la soumission.
      return _sheets[sheet.classId] = sheet.copyWith(status: GradeSheetStatus.brouillon);
    }
    final a = await _teacher.resolve(sheet.classId);
    final base = '/etablissements/${_teacher.establishmentId}/classes/${a.classId}/matieres/${a.subjectId}/evaluations';
    var evaluationId = sheet.evaluationId;
    if (evaluationId.isEmpty) {
      final created = ApiJson.map(
        await _api.post(
          base,
          data: {
            'periodeId': sheet.period.id,
            'nom': sheet.evaluationLabel,
            'coefficient': sheet.coefficient,
            'bareme': sheet.scale,
            'date': ApiJson.date(DateTime.now()),
            'notes': _notes(sheet.grades),
          },
        ),
      );
      evaluationId = created['id'] as String? ?? '';
    } else {
      await _api.patch('$base/$evaluationId', data: {'notes': _notes(sheet.grades)});
    }
    final saved = GradeSheet(
      evaluationId: evaluationId,
      classId: sheet.classId,
      className: sheet.className,
      subject: sheet.subject,
      period: sheet.period,
      evaluationLabel: sheet.evaluationLabel,
      coefficient: sheet.coefficient,
      scale: sheet.scale,
      status: GradeSheetStatus.soumis,
      openUntil: sheet.openUntil,
      grades: sheet.grades,
    );
    return _sheets[sheet.classId] = saved;
  }

  @override
  Future<void> correctGrade(String evaluationId, String studentId, double value, String reason) async {
    final sheet = _sheets.values.where((s) => s.evaluationId == evaluationId && evaluationId.isNotEmpty).firstOrNull;
    if (sheet == null) throw const ServerException('Soumettez d’abord la feuille de notes avant de la corriger.');
    final a = await _teacher.resolve(sheet.classId);
    await _api.patch(
      '/etablissements/${_teacher.establishmentId}/classes/${a.classId}/matieres/${a.subjectId}/evaluations/$evaluationId',
      data: {
        'notes': [
          {'eleveId': studentId, 'valeur': value, 'absent': false},
        ],
      },
    );
    _sheets[sheet.classId] = sheet.copyWith(
      grades: [
        for (final g in sheet.grades)
          g.studentId == studentId ? StudentGrade(studentId: g.studentId, studentName: g.studentName, value: value) : g,
      ],
    );
  }

  @override
  Future<List<Appreciation>> getAppreciations(String classId) => notAvailableOnServer('Les appréciations');

  @override
  Future<void> saveAppreciations(String classId, List<Appreciation> items) =>
      notAvailableOnServer('Les appréciations');

  @override
  Future<ClassStats> getClassStats(String classId) => notAvailableOnServer('Les statistiques de classe');
}
