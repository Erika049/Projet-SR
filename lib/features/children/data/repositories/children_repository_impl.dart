import '../../../../core/utils/result.dart';
import '../../domain/entities/child.dart';
import '../../domain/repositories/children_repository.dart';
import '../datasources/children_remote_data_source.dart';

class ChildrenRepositoryImpl implements ChildrenRepository {
  const ChildrenRepositoryImpl(this._remote);
  final ChildrenRemoteDataSource _remote;

  @override
  Future<Result<List<Child>>> getChildren() => guard(_remote.getChildren);

  @override
  Future<Result<List<LinkRequest>>> getLinkRequests() => guard(_remote.getLinkRequests);

  @override
  Future<Result<LinkRequest>> linkChild(String code) => guard(() => _remote.linkChild(code));

  @override
  Future<Result<void>> unlinkChild(String childId) => guard(() => _remote.unlinkChild(childId));

  @override
  Future<Result<void>> requestCorrection(String childId, String message) =>
      guard(() => _remote.requestCorrection(childId, message));
}
