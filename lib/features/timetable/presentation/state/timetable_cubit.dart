import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/view_status.dart';
import '../../domain/entities/course.dart';
import '../../domain/usecases/timetable_usecases.dart';

class TimetableCubit extends Cubit<DataState<List<Course>>> {
  TimetableCubit(this._get) : super(const DataState());
  final GetWeekTimetable _get;

  Future<void> load() async {
    emit(state.loading());
    final result = await _get(DateTime.now());
    emit(result.fold(state.error, state.success));
  }
}
