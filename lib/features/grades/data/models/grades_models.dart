import '../../domain/entities/grades.dart';

/// Conversions JSON ↔ entités pour la fonctionnalité notes.
abstract final class GradesMapper {
  static Period period(Map<String, dynamic> j) => Period(
        id: j['id'] as String,
        label: j['libelle'] as String,
        kind: j['type'] == 'trimestre' ? PeriodKind.trimestre : PeriodKind.sequence,
        year: j['annee'] as String,
      );

  static GradesReport report(Map<String, dynamic> j) => GradesReport(
        period: period(j['periode'] as Map<String, dynamic>),
        rank: j['rang'] as int?,
        classSize: j['effectif_classe'] as int?,
        reportCardPublished: j['bulletin_publie'] as bool? ?? false,
        subjects: [
          for (final s in j['matieres'] as List)
            SubjectGrade(
              subject: s['matiere'] as String,
              coefficient: (s['coefficient'] as num).toDouble(),
              grade: (s['moyenne'] as num?)?.toDouble(),
            ),
        ],
      );

  static ReportCard reportCard(Map<String, dynamic> j) => ReportCard(
        id: j['id'] as String,
        periodLabel: j['periode'] as String,
        published: j['publie'] as bool,
        fileUrl: j['fichier_url'] as String?,
      );

  static Map<String, dynamic> sheetToJson(GradeSheet s) => {
        'evaluation_id': s.evaluationId,
        'statut': s.status.name,
        'notes': [
          for (final g in s.grades)
            {
              'eleve_id': g.studentId,
              'valeur': g.value,
              'statut': g.absent ? 'absent' : (g.value == null ? 'non_note' : 'saisie'),
            },
        ],
      };
}
