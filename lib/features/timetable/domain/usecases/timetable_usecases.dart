import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/course.dart';
import '../repositories/timetable_repository.dart';

class GetWeekTimetable implements UseCase<List<Course>, DateTime> {
  const GetWeekTimetable(this._repo);
  final TimetableRepository _repo;

  @override
  Future<Result<List<Course>>> call(DateTime day) => _repo.getWeek(day);
}

class GetTeacherClasses implements UseCase<List<TeacherClass>, NoParams> {
  const GetTeacherClasses(this._repo);
  final TimetableRepository _repo;

  @override
  Future<Result<List<TeacherClass>>> call(NoParams _) => _repo.getClasses();
}

/// Cours en cours, sinon le prochain cours de la journée.
Course? currentOrNextCourse(List<Course> courses, DateTime now) {
  final today = courses
      .where((c) => c.start.year == now.year && c.start.month == now.month && c.start.day == now.day)
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return today.where((c) => c.isOngoing(now)).firstOrNull ?? today.where((c) => c.start.isAfter(now)).firstOrNull;
}
