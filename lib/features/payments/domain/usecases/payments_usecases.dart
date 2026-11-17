import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/payments.dart';
import '../repositories/payments_repository.dart';

class GetFinancialSituation implements UseCase<FinancialSituation, String> {
  const GetFinancialSituation(this._repo);
  final PaymentsRepository _repo;

  @override
  Future<Result<FinancialSituation>> call(String childId) => _repo.getSituation(childId);
}

class GetPaymentHistory implements UseCase<List<PaymentRecord>, String> {
  const GetPaymentHistory(this._repo);
  final PaymentsRepository _repo;

  @override
  Future<Result<List<PaymentRecord>>> call(String childId) => _repo.getHistory(childId);
}

typedef DeclarePaymentParams = ({
  String childId,
  PaymentMode mode,
  String amount,
  String reference,
  int balance,
});

class DeclarePayment implements UseCase<PaymentRecord, DeclarePaymentParams> {
  const DeclarePayment(this._repo);
  final PaymentsRepository _repo;

  @override
  Future<Result<PaymentRecord>> call(DeclarePaymentParams p) async {
    final amount = int.tryParse(p.amount.replaceAll(RegExp(r'[\s  ]'), ''));
    if (amount == null || amount <= 0) return const Err(ValidationFailure('Saisissez un montant valide.'));
    if (amount > p.balance) return const Err(ValidationFailure('Le montant dépasse le solde restant.'));
    if (p.mode != PaymentMode.especes && p.reference.trim().isEmpty) {
      return const Err(ValidationFailure('La référence de transaction est obligatoire.'));
    }
    return _repo.declarePayment(
      childId: p.childId,
      mode: p.mode,
      amount: amount,
      reference: p.reference.trim().isEmpty ? null : p.reference.trim(),
    );
  }
}

class DownloadReceipt implements UseCase<String, PaymentRecord> {
  const DownloadReceipt(this._repo);
  final PaymentsRepository _repo;

  @override
  Future<Result<String>> call(PaymentRecord payment) async {
    if (!payment.hasReceipt) return const Err(ValidationFailure('Le reçu sera disponible après validation.'));
    return _repo.downloadReceipt(payment.id);
  }
}
