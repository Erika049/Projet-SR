import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_overview.dart';
import '../repositories/home_repository.dart';

class GetParentOverview implements UseCase<ParentOverview, NoParams> {
  const GetParentOverview(this._repo);
  final HomeRepository _repo;

  @override
  Future<Result<ParentOverview>> call(NoParams _) => _repo.getParentOverview();
}
