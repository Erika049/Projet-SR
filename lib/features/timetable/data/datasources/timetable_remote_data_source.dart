import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/network/teacher_api_context.dart';
import '../../domain/entities/course.dart';

abstract interface class TimetableRemoteDataSource {
  Future<List<Course>> getWeek(DateTime day);
  Future<List<TeacherClass>> getClasses();
}

/// Backend SchoolConnect :
/// - cours de la semaine : `GET /etablissements/{etab}/mon-emploi-du-temps` (créneaux hebdomadaires) ;
/// - classes : affectations de l'enseignant (`GET /etablissements/{etab}/mes-affectations`).
class TimetableApiDataSource implements TimetableRemoteDataSource {
  const TimetableApiDataSource(this._api, this._teacher);
  final ApiClient _api;
  final TeacherApiContext _teacher;

  static DateTime _at(DateTime day, Object? time) {
    final parts = '$time'.split(':');
    return DateTime(day.year, day.month, day.day, int.tryParse(parts.first) ?? 0,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  /// Cours de la semaine contenant [day], datés à partir des créneaux hebdomadaires.
  @override
  Future<List<Course>> getWeek(DateTime day) async {
    final slots = ApiJson.list(await _api.get('/etablissements/${_teacher.establishmentId}/mon-emploi-du-temps'));
    final counts = await _teacher.studentCounts();
    final monday = DateTime(day.year, day.month, day.day).subtract(Duration(days: day.weekday - 1));
    final courses = [
      for (final s in slots)
        () {
          final date = monday.add(Duration(days: ApiJson.toInt(s['jourSemaine']) - 1));
          final start = _at(date, s['heureDebut']);
          return Course(
            id: '${s['id']}-${ApiJson.date(date)}',
            classId: s['classeId'] as String? ?? '',
            className: s['classeNom'] as String? ?? 'Classe',
            subject: s['matiereNom'] as String? ?? '',
            start: start,
            end: _at(date, s['heureFin']),
            room: s['salle'] as String? ?? '',
            studentCount: counts[s['classeId']] ?? 0,
          );
        }(),
    ]..sort((a, b) => a.start.compareTo(b.start));
    return courses;
  }

  @override
  Future<List<TeacherClass>> getClasses() async {
    final assignments = await _teacher.assignments();
    final counts = await _teacher.studentCounts();
    final now = DateTime.now();
    List<Course> courses;
    try {
      courses = [...await getWeek(now), ...await getWeek(now.add(const Duration(days: 7)))];
    } on ServerException {
      courses = const [];
    }
    final seen = <String>{};
    return [
      for (final a in assignments)
        if (seen.add(a.classId))
          TeacherClass(
            id: a.classId,
            name: a.className,
            studentCount: counts[a.classId] ?? 0,
            nextCourse: courses.where((c) => c.classId == a.classId && c.end.isAfter(now)).firstOrNull,
          ),
    ];
  }
}
