import '../../../../core/utils/result.dart';
import '../../domain/entities/payments.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_remote_data_source.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  const PaymentsRepositoryImpl(this._remote);
  final PaymentsRemoteDataSource _remote;

  @override
  Future<Result<FinancialSituation>> getSituation(String childId) => guard(() => _remote.getSituation(childId));

  @override
  Future<Result<List<PaymentRecord>>> getHistory(String childId) => guard(() => _remote.getHistory(childId));

  @override
  Future<Result<PaymentRecord>> declarePayment({
    required String childId,
    required PaymentMode mode,
    required int amount,
    String? reference,
  }) =>
      guard(() => _remote.declarePayment(childId, mode, amount, reference));

  @override
  Future<Result<String>> downloadReceipt(String paymentId) => guard(() => _remote.downloadReceipt(paymentId));
}
