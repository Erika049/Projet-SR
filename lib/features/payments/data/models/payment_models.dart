import '../../domain/entities/payments.dart';

/// Conversions JSON ↔ entités pour les paiements (table `paiement`).
abstract final class PaymentMapper {
  static PaymentMode mode(String value) => switch (value) {
        'especes' => PaymentMode.especes,
        'virement' || 'cheque' => PaymentMode.virement,
        _ => PaymentMode.mobileMoney, // mtn_momo, orange_money
      };

  static PaymentRecord record(Map<String, dynamic> j) => PaymentRecord(
        id: j['id'] as String,
        date: DateTime.parse(j['date_paiement'] as String),
        amount: j['montant'] as int,
        mode: mode(j['mode'] as String),
        status: switch (j['statut']) {
          'confirme' => PaymentStatus.confirme,
          'echoue' || 'annule' => PaymentStatus.rejete,
          _ => PaymentStatus.enAttente,
        },
        receiptNumber: j['numero_recu'] as String?,
      );

  static Map<String, dynamic> declaration(String childId, PaymentMode mode, int amount, String? reference) => {
        'eleve_id': childId,
        'mode': switch (mode) {
          PaymentMode.mobileMoney => 'mtn_momo',
          PaymentMode.especes => 'especes',
          PaymentMode.virement => 'virement',
        },
        'montant': amount,
        'reference_externe': reference,
        'canal': 'en_ligne',
      };
}
