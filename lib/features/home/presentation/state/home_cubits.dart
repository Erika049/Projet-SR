import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/view_status.dart' show DataState;
import '../../../timetable/domain/entities/course.dart';
import '../../../timetable/domain/usecases/timetable_usecases.dart';
import '../../domain/entities/parent_overview.dart';
import '../../domain/usecases/home_usecases.dart';

class ParentHomeCubit extends Cubit<DataState<ParentOverview>> {
  ParentHomeCubit(this._get) : super(const DataState());
  final GetParentOverview _get;

  Future<void> load() async {
    emit(state.loading());
    final result = await _get(const NoParams());
    emit(result.fold(state.error, state.success));
  }
}

class TeacherOverview extends Equatable {
  const TeacherOverview({required this.classes, this.current});

  final List<TeacherClass> classes;

  /// Cours en cours ou prochain cours du jour.
  final Course? current;

  @override
  List<Object?> get props => [classes, current];
}

class TeacherHomeCubit extends Cubit<DataState<TeacherOverview>> {
  TeacherHomeCubit(this._classes, this._week) : super(const DataState());

  final GetTeacherClasses _classes;
  final GetWeekTimetable _week;

  Future<void> load() async {
    emit(state.loading());
    final now = DateTime.now();
    final classes = await _classes(const NoParams());
    final week = await _week(now);
    Failure? failure;
    final list = classes.fold((f) {
      failure = f;
      return const <TeacherClass>[];
    }, (l) => l);
    if (failure != null) return emit(state.error(failure!));
    final current = week.fold((_) => null, (courses) => currentOrNextCourse(courses, now));
    emit(state.success(TeacherOverview(classes: list, current: current)));
  }
}
