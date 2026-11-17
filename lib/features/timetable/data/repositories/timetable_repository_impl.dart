import '../../../../core/utils/result.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../datasources/timetable_remote_data_source.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  const TimetableRepositoryImpl(this._remote);
  final TimetableRemoteDataSource _remote;

  @override
  Future<Result<List<Course>>> getWeek(DateTime day) => guard(() => _remote.getWeek(day));

  @override
  Future<Result<List<TeacherClass>>> getClasses() => guard(_remote.getClasses);
}
