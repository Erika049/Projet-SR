import '../../../../core/utils/result.dart';
import '../entities/course.dart';

abstract interface class TimetableRepository {
  /// Cours de la semaine contenant [day] (CU-ENS-02).
  Future<Result<List<Course>>> getWeek(DateTime day);

  /// Classes de l'enseignant avec leur prochain cours.
  Future<Result<List<TeacherClass>>> getClasses();
}
