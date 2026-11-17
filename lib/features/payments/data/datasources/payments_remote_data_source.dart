import '../../../../core/network/mock_delay.dart';
import '../../domain/entities/payments.dart';

abstract interface class PaymentsRemoteDataSource {
  Future<FinancialSituation> getSituation(String childId);
  Future<List<PaymentRecord>> getHistory(String childId);
  Future<PaymentRecord> declarePayment(String childId, PaymentMode mode, int amount, String? reference);
  Future<String> downloadReceipt(String paymentId);
}

/// Données de démonstration : scolarité 120 000 FCFA en deux versements.
class PaymentsMockDataSource implements PaymentsRemoteDataSource {
  final Map<String, List<PaymentRecord>> _history = {
    'eleve-amina': [
      PaymentRecord(
        id: 'pay-1',
        date: DateTime(2026, 9, 5),
        amount: 75000,
        mode: PaymentMode.especes,
        status: PaymentStatus.confirme,
        receiptNumber: 'LBB-2026-00412',
      ),
    ],
    'eleve-junior': [
      PaymentRecord(
        id: 'pay-2',
        date: DateTime(2026, 9, 5),
        amount: 75000,
        mode: PaymentMode.especes,
        status: PaymentStatus.confirme,
        receiptNumber: 'LBB-2026-00413',
      ),
    ],
  };

  @override
  Future<FinancialSituation> getSituation(String childId) async {
    await mockDelay();
    final history = _history[childId] ?? const [];
    final paid = history.where((p) => p.status == PaymentStatus.confirme).fold<int>(0, (s, p) => s + p.amount);
    return FinancialSituation(
      year: '2026–2027',
      totalDue: 120000,
      totalPaid: paid,
      lastReceipt: history.where((p) => p.hasReceipt).lastOrNull,
      installments: [
        Installment(label: '1er versement', amount: 75000, dueDate: DateTime(2026, 9, 15), paid: paid >= 75000),
        Installment(label: '2e versement', amount: 45000, dueDate: DateTime(2026, 11, 30), paid: paid >= 120000),
      ],
    );
  }

  @override
  Future<List<PaymentRecord>> getHistory(String childId) async {
    await mockDelay();
    return (_history[childId] ?? const []).reversed.toList();
  }

  @override
  Future<PaymentRecord> declarePayment(String childId, PaymentMode mode, int amount, String? reference) async {
    await mockDelay();
    final record = PaymentRecord(
      id: 'decl-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      amount: amount,
      mode: mode,
      status: PaymentStatus.enAttente,
    );
    (_history[childId] ??= []).add(record);
    return record;
  }

  @override
  Future<String> downloadReceipt(String paymentId) async {
    await mockDelay(700);
    return 'recu_$paymentId.pdf';
  }
}
