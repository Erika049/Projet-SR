import 'package:equatable/equatable.dart';

/// Versement prévu (tables `echeance_eleve` / `echeance_modele`).
class Installment extends Equatable {
  const Installment({required this.label, required this.amount, required this.dueDate, required this.paid});

  final String label; // « 1er versement »
  final int amount;
  final DateTime dueDate;
  final bool paid;

  @override
  List<Object?> get props => [label, amount, dueDate, paid];
}

enum PaymentMode {
  mobileMoney('Mobile Money'),
  especes('Espèces'),
  virement('Virement');

  const PaymentMode(this.label);
  final String label;
}

enum PaymentStatus {
  confirme('Payé'),
  enAttente('En attente'),
  rejete('Rejeté');

  const PaymentStatus(this.label);
  final String label;
}

/// Paiement encaissé (avec reçu) ou déclaration du parent en attente.
class PaymentRecord extends Equatable {
  const PaymentRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.mode,
    required this.status,
    this.receiptNumber,
  });

  final String id;
  final DateTime date;
  final int amount;
  final PaymentMode mode;
  final PaymentStatus status;

  /// Numéro du reçu numérique (présent quand le paiement est confirmé).
  final String? receiptNumber;

  bool get hasReceipt => status == PaymentStatus.confirme && receiptNumber != null;

  @override
  List<Object?> get props => [id, date, amount, mode, status, receiptNumber];
}

/// Situation financière d'un enfant pour une année (table `compte_eleve`, CU-PAR-10).
class FinancialSituation extends Equatable {
  const FinancialSituation({
    required this.year,
    required this.totalDue,
    required this.totalPaid,
    required this.installments,
    this.lastReceipt,
  });

  final String year;
  final int totalDue;
  final int totalPaid;
  final List<Installment> installments;
  final PaymentRecord? lastReceipt;

  int get balance => totalDue - totalPaid;

  Installment? get nextInstallment => installments.where((i) => !i.paid).firstOrNull;

  @override
  List<Object?> get props => [year, totalDue, totalPaid, installments, lastReceipt];
}
