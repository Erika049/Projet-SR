import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/sync_item.dart';
import '../repositories/sync_repository.dart';

class GetSyncOverview implements UseCase<SyncOverview, NoParams> {
  const GetSyncOverview(this._repo);
  final SyncRepository _repo;

  @override
  Future<Result<SyncOverview>> call(NoParams _) => _repo.getOverview();
}

class SyncNow implements UseCase<SyncOverview, NoParams> {
  const SyncNow(this._repo);
  final SyncRepository _repo;

  @override
  Future<Result<SyncOverview>> call(NoParams _) => _repo.syncNow();
}

class ResolveConflict implements UseCase<SyncOverview, ({String id, bool keepLocal})> {
  const ResolveConflict(this._repo);
  final SyncRepository _repo;

  @override
  Future<Result<SyncOverview>> call(({String id, bool keepLocal}) p) =>
      _repo.resolveConflict(p.id, keepLocal: p.keepLocal);
}
