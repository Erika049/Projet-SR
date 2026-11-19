import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/network/teacher_api_context.dart';
import '../../domain/entities/attendance.dart';

abstract interface class AttendanceRemoteDataSource {
  Future<AttendanceSummary> getChildAttendance(String childId, DateTime month);
  Future<void> justifyAbsence(String recordId, String reason, String? attachmentPath);
  Future<void> reportError(String childId, String message);
  Future<RollCall> getRollCall(String classId);
  Future<void> saveRollCall(RollCall rollCall);
  Future<MyAttendance> getMyAttendance();
  Future<MyAttendance> signalMyPresence();
  Future<MyAttendance> signalMyAbsence(String reason);
}

/// Backend SchoolConnect.
///
/// - Parent : `GET /mes-enfants/{eleveId}/presences?from&to` (absences vérifiées par le surveillant
///   général, avec l'état du justificatif) ; justification `POST /mes-enfants/{eleveId}/justificatifs`
///   (multipart : dateDebut, motif, piece).
/// - Enseignant : appel du jour `GET|POST /etablissements/{etab}/classes/{classe}/appels`,
///   correction `PATCH …/appels/{appelId}`. Statuts envoyés : PRESENT ou ABSENT. La fiche soumise
///   est vérifiée par le surveillant général, qui prévient ensuite les parents des absents.
class AttendanceApiDataSource implements AttendanceRemoteDataSource {
  AttendanceApiDataSource(this._api, this._teacher);

  final ApiClient _api;
  final TeacherApiContext _teacher;

  /// Préfixe des appels pas encore enregistrés sur le serveur.
  static const _newPrefix = 'nouveau-';

  /// Appels créés pendant la session (classe|date → id), pour corriger au lieu de recréer.
  final Map<String, String> _created = {};

  /// Identifiant d'une absence : « eleveId|aaaa-mm-jj » (le serveur indexe les absences par jour).
  static String recordId(String childId, String day) => '$childId|$day';

  static JustificationStatus _status(Object? v) => switch (v) {
    'EN_ATTENTE' => JustificationStatus.enAttente,
    'ACCEPTE' => JustificationStatus.justifie,
    'REFUSE' => JustificationStatus.refuse,
    _ => JustificationStatus.aJustifier,
  };

  @override
  Future<AttendanceSummary> getChildAttendance(String childId, DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1, 0);
    final rows = ApiJson.list(
      await _api.get('/mes-enfants/$childId/presences', query: {'from': ApiJson.date(from), 'to': ApiJson.date(to)}),
    );
    final records = <AttendanceRecord>[];
    final seen = <String>{};
    for (final p in rows) {
      if (p['statut'] != 'ABSENT') continue;
      final day = ApiJson.parseDate(p['date']);
      if (day == null || !seen.add('${p['date']}')) continue;
      records.add(
        AttendanceRecord(id: recordId(childId, '${p['date']}'), start: day, status: _status(p['justificatif'])),
      );
    }
    records.sort((a, b) => b.start.compareTo(a.start));
    return AttendanceSummary(month: month, records: records);
  }

  @override
  Future<void> justifyAbsence(String recordId, String reason, String? attachmentPath) async {
    final sep = recordId.lastIndexOf('|');
    if (sep <= 0) throw const ServerException('Absence introuvable. Actualisez la page.');
    final childId = recordId.substring(0, sep);
    final day = recordId.substring(sep + 1);
    await _api.postMultipart(
      '/mes-enfants/$childId/justificatifs',
      fields: {'dateDebut': day, 'dateFin': day, 'motif': reason.trim()},
      fileField: attachmentPath == null ? null : 'piece',
      filePath: attachmentPath,
    );
  }

  @override
  Future<void> reportError(String childId, String message) => notAvailableOnServer('Le signalement d’une erreur');

  @override
  Future<RollCall> getRollCall(String classId) async {
    final a = await _teacher.resolve(classId);
    final etab = _teacher.establishmentId;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour);

    // Appel déjà saisi aujourd'hui ? (404 sinon)
    Map<String, dynamic>? existing;
    try {
      existing = ApiJson.map(
        await _api.get('/etablissements/$etab/classes/${a.classId}/appels', query: {'date': ApiJson.date(now)}),
      );
      if (existing['id'] == null) existing = null;
    } on ServerException {
      existing = null;
    }

    final saved = {
      for (final p in ApiJson.list(existing?['presences'])) p['eleveId']: p,
    };
    final students = await _teacher.students(a);
    final entries = [
      for (final s in students)
        RollCallEntry(
          studentId: s.id,
          studentName: s.name,
          status: saved[s.id]?['statut'] == 'ABSENT' ? RollCallStatus.absent : RollCallStatus.present,
        ),
    ];
    // Élèves présents dans l'appel mais absents de la liste de la classe.
    for (final p in saved.values) {
      if (students.any((s) => s.id == p['eleveId'])) continue;
      entries.add(
        RollCallEntry(
          studentId: p['eleveId'] as String,
          studentName: ApiJson.studentName(p['eleve']),
          status: p['statut'] == 'ABSENT' ? RollCallStatus.absent : RollCallStatus.present,
        ),
      );
    }
    if (entries.isEmpty) throw const ServerException('Aucun élève n’est inscrit dans cette classe.');

    return RollCall(
      id: existing?['id'] as String? ?? '$_newPrefix${a.classId}',
      classId: a.classId,
      className: a.className,
      subject: a.subject,
      start: start,
      end: start.add(const Duration(hours: 1)),
      entries: entries,
    );
  }

  @override
  Future<void> saveRollCall(RollCall rollCall) async {
    final a = await _teacher.resolve(rollCall.classId);
    final etab = _teacher.establishmentId;
    final presences = [
      for (final e in rollCall.entries)
        {'eleveId': e.studentId, 'statut': e.status == RollCallStatus.absent ? 'ABSENT' : 'PRESENT'},
    ];
    final base = '/etablissements/$etab/classes/${a.classId}/appels';
    final key = '${a.classId}|${ApiJson.date(rollCall.start)}';
    final id = rollCall.id.startsWith(_newPrefix) ? _created[key] : rollCall.id;
    if (id == null) {
      final created = ApiJson.map(
        await _api.post(
          base,
          data: {'date': ApiJson.date(rollCall.start), 'matiereId': a.subjectId, 'presences': presences},
        ),
      );
      if (created['id'] is String) _created[key] = created['id'] as String;
    } else {
      await _api.patch('$base/$id', data: {'presences': presences});
    }
  }

  @override
  Future<MyAttendance> getMyAttendance() => notAvailableOnServer('La présence des enseignants');

  @override
  Future<MyAttendance> signalMyPresence() => notAvailableOnServer('La présence des enseignants');

  @override
  Future<MyAttendance> signalMyAbsence(String reason) => notAvailableOnServer('La présence des enseignants');
}
