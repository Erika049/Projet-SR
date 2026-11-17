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
  DateTime? paidAt,
  String reference,
  PaymentProof? proof,
  int balance,
});

/// Déclaration d'un paiement (CU-PAR-11) : montant, date, référence et preuve
/// (image ou PDF) sont tous obligatoires.
class DeclarePayment implements UseCase<PaymentRecord, DeclarePaymentParams> {
  DeclarePayment(this._repo, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final PaymentsRepository _repo;
  final DateTime Function() _now;

  @override
  Future<Result<PaymentRecord>> call(DeclarePaymentParams p) async {
    final amount = int.tryParse(p.amount.replaceAll(RegExp(r'[\s  ]'), ''));
    if (amount == null || amount <= 0) return const Err(ValidationFailure('Saisissez un montant valide.'));
    if (amount > p.balance) return const Err(ValidationFailure('Le montant dépasse le solde restant.'));

    final paidAt = p.paidAt;
    if (paidAt == null) return const Err(ValidationFailure('Indiquez la date du paiement.'));
    final now = _now();
    if (DateTime(paidAt.year, paidAt.month, paidAt.day).isAfter(DateTime(now.year, now.month, now.day))) {
      return const Err(ValidationFailure('La date du paiement ne peut pas être dans le futur.'));
    }

    final reference = p.reference.trim();
    if (reference.isEmpty) return const Err(ValidationFailure('La référence du paiement est obligatoire.'));

    final proof = p.proof;
    if (proof == null) return const Err(ValidationFailure('Joignez la preuve de paiement (image ou PDF).'));
    if (!proof.hasAllowedType) {
      return const Err(ValidationFailure('La preuve doit être une image (JPG, PNG) ou un PDF.'));
    }
    if (proof.isTooLarge) return const Err(ValidationFailure('La preuve ne doit pas dépasser 5 Mo.'));

    return _repo.declarePayment(
      PaymentDeclaration(
        childId: p.childId,
        mode: p.mode,
        amount: amount,
        paidAt: paidAt,
        reference: reference,
        proof: proof,
      ),
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
