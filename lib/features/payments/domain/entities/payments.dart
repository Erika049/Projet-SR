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

/// Preuve de paiement jointe à une déclaration : photo du reçu, capture
/// Mobile Money, avis de virement (image ou PDF).
class PaymentProof extends Equatable {
  const PaymentProof({required this.name, required this.sizeBytes, this.path});

  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
  static const maxBytes = 5 * 1024 * 1024; // 5 Mo

  final String name;
  final int sizeBytes;

  /// Chemin local du fichier sur le téléphone (absent sur le web).
  final String? path;

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';
  bool get isPdf => extension == 'pdf';
  bool get hasAllowedType => allowedExtensions.contains(extension);
  bool get isTooLarge => sizeBytes > maxBytes;

  @override
  List<Object?> get props => [name, sizeBytes, path];
}

/// Déclaration d'un paiement par le parent (CU-PAR-11), après validation.
class PaymentDeclaration extends Equatable {
  const PaymentDeclaration({
    required this.childId,
    required this.mode,
    required this.amount,
    required this.paidAt,
    required this.reference,
    required this.proof,
  });

  final String childId;
  final PaymentMode mode;
  final int amount;

  /// Date à laquelle le parent a effectué le paiement.
  final DateTime paidAt;
  final String reference;
  final PaymentProof proof;

  @override
  List<Object?> get props => [childId, mode, amount, paidAt, reference, proof];
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
    this.reference,
    this.proofName,
  });

  final String id;
  final DateTime date;
  final int amount;
  final PaymentMode mode;
  final PaymentStatus status;

  /// Numéro du reçu numérique (présent quand le paiement est confirmé).
  final String? receiptNumber;

  /// Référence saisie par le parent lors de la déclaration.
  final String? reference;

  /// Nom du fichier de preuve joint à la déclaration.
  final String? proofName;

  bool get hasReceipt => status == PaymentStatus.confirme && receiptNumber != null;

  @override
  List<Object?> get props => [id, date, amount, mode, status, receiptNumber, reference, proofName];
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
