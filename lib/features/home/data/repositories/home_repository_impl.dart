import '../../../../core/utils/result.dart';
import '../../domain/entities/parent_overview.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remote);
  final HomeRemoteDataSource _remote;

  @override
  Future<Result<ParentOverview>> getParentOverview() => guard(_remote.getParentOverview);
}
