import '../../domain/entities/attendance.dart';

/// Conversions JSON ↔ entités pour les présences.
abstract final class AttendanceMapper {
  static const _justification = {
    'a_justifier': JustificationStatus.aJustifier,
    'en_attente': JustificationStatus.enAttente,
    'accepte': JustificationStatus.justifie,
    'refuse': JustificationStatus.refuse,
  };

  static AttendanceRecord record(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'] as String,
        kind: j['statut'] == 'retard' ? AttendanceKind.retard : AttendanceKind.absence,
        start: DateTime.parse(j['debut'] as String),
        end: j['fin'] == null ? null : DateTime.parse(j['fin'] as String),
        subject: j['matiere'] as String?,
        minutesLate: j['minutes_retard'] as int?,
        status: _justification[j['justification']] ?? JustificationStatus.aJustifier,
      );

  static Map<String, dynamic> rollCallToJson(RollCall r) => {
        'appel_id': r.id,
        'classe_id': r.classId,
        'presences': [
          for (final e in r.entries) {'inscription_id': e.studentId, 'statut': e.status.name},
        ],
      };
}
