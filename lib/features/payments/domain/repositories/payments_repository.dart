import '../../../../core/utils/result.dart';
import '../entities/payments.dart';

abstract interface class PaymentsRepository {
  Future<Result<FinancialSituation>> getSituation(String childId);
  Future<Result<List<PaymentRecord>>> getHistory(String childId);

  /// Déclaration d'un paiement par le parent, validée ensuite par l'économat (CU-PAR-11).
  Future<Result<PaymentRecord>> declarePayment(PaymentDeclaration declaration);

  /// Retourne le chemin local du reçu PDF (CU-PAR-12).
  Future<Result<String>> downloadReceipt(String paymentId);
}
