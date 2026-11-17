import '../../../../core/utils/result.dart';
import '../entities/parent_overview.dart';

abstract interface class HomeRepository {
  Future<Result<ParentOverview>> getParentOverview();
}
