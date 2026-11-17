import '../../../../core/network/mock_delay.dart';
import '../../domain/entities/course.dart';

abstract interface class TimetableRemoteDataSource {
  Future<List<Course>> getWeek(DateTime day);
  Future<List<TeacherClass>> getClasses();
}

/// Emploi du temps de démonstration de M. Kamga (Mathématiques),
/// recalculé sur la semaine en cours.
class TimetableMockDataSource implements TimetableRemoteDataSource {
  static const _classes = {
    '3eA': ('3e A', 52, 'Salle 04'),
    '4eB': ('4e B', 48, 'Salle 02'),
    '2ndeC': ('2nde C', 45, 'Salle 11'),
  };

  /// (jour 1=lundi, heure, classe)
  static const _slots = [
    (1, 8, '3eA'),
    (2, 10, '4eB'),
    (2, 14, '2ndeC'),
    (3, 8, '3eA'),
    (4, 10, '4eB'),
    (4, 15, '3eA'),
    (5, 9, '2ndeC'),
  ];

  List<Course> _week(DateTime day) {
    final monday = DateTime(day.year, day.month, day.day).subtract(Duration(days: day.weekday - 1));
    return [
      for (final (weekday, hour, classId) in _slots)
        () {
          final (name, count, room) = _classes[classId]!;
          final start = monday.add(Duration(days: weekday - 1, hours: hour));
          return Course(
            id: '$classId-${start.toIso8601String()}',
            classId: classId,
            className: name,
            subject: 'Mathématiques',
            start: start,
            end: start.add(const Duration(hours: 1)),
            room: room,
            studentCount: count,
          );
        }(),
    ];
  }

  @override
  Future<List<Course>> getWeek(DateTime day) async {
    await mockDelay();
    return _week(day);
  }

  @override
  Future<List<TeacherClass>> getClasses() async {
    await mockDelay();
    final now = DateTime.now();
    final courses = [..._week(now), ..._week(now.add(const Duration(days: 7)))];
    return [
      for (final MapEntry(key: id, value: (name, count, _)) in _classes.entries)
        TeacherClass(
          id: id,
          name: name,
          studentCount: count,
          nextCourse: courses.where((c) => c.classId == id && c.end.isAfter(now)).firstOrNull,
        ),
    ];
  }
}
