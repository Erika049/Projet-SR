import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/view_status.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/usecases/sync_usecases.dart';

/// État de synchronisation. Fourni au niveau de l'espace Enseignant
/// (utilisé par l'accueil, le profil et l'écran « Synchronisation »).
class SyncCubit extends Cubit<DataState<SyncOverview>> {
  SyncCubit(this._get, this._sync, this._resolve) : super(const DataState());

  final GetSyncOverview _get;
  final SyncNow _sync;
  final ResolveConflict _resolve;

  Future<void> load() async {
    final result = await _get(const NoParams());
    emit(result.fold(state.error, state.success));
  }

  Future<String> syncNow() async {
    emit(state.loading());
    final result = await _sync(const NoParams());
    return result.fold(
      (f) {
        emit(state.error(f));
        return f.message;
      },
      (o) {
        emit(state.success(o));
        return 'Synchronisation terminée.';
      },
    );
  }

  Future<void> resolve(String id, {required bool keepLocal}) async {
    final result = await _resolve((id: id, keepLocal: keepLocal));
    emit(result.fold(state.error, state.success));
  }
}
