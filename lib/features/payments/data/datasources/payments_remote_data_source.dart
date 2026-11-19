import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_json.dart';
import '../../domain/entities/payments.dart';

abstract interface class PaymentsRemoteDataSource {
  Future<FinancialSituation> getSituation(String childId);
  Future<List<PaymentRecord>> getHistory(String childId);

  /// Envoie la déclaration avec sa preuve (envoi multipart côté API).
  Future<PaymentRecord> declarePayment(PaymentDeclaration declaration);
  Future<String> downloadReceipt(String paymentId);
}

/// Backend SchoolConnect :
/// - `GET /mes-enfants/{eleveId}/situation-financiere` (`totalDu`, `totalPaye`, `fraisApplicables`, `paiements`) ;
/// - `GET|POST /mes-enfants/{eleveId}/declarations-paiement` (multipart : montant, mode, reference, date, preuve) ;
/// - `GET /mes-enfants/{eleveId}/paiements/{id}/recu` : reçu PDF, enregistré là où le parent le choisit.
class PaymentsApiDataSource implements PaymentsRemoteDataSource {
  PaymentsApiDataSource(this._api);
  final ApiClient _api;

  /// Paiement → enfant, pour retrouver la route du reçu.
  final Map<String, String> _childOfPayment = {};

  static String _apiMode(PaymentMode m) => switch (m) {
    PaymentMode.mobileMoney => 'MOBILE_MONEY',
    PaymentMode.especes => 'ESPECES',
    PaymentMode.virement => 'VIREMENT',
  };

  static PaymentRecord _declaration(Map<String, dynamic> d) => PaymentRecord(
    id: 'declaration-${d['id']}',
    date: ApiJson.parseDate(d['datePaiement']) ?? DateTime.now(),
    amount: ApiJson.toInt(d['montant']),
    mode: _mode(d['mode']),
    status: d['statut'] == 'REJETEE' ? PaymentStatus.rejete : PaymentStatus.enAttente,
    reference: d['reference'] as String?,
    proofName: ApiJson.map(d['preuve'])['nom'] as String?,
  );

  Future<Map<String, dynamic>> _situation(String childId) async =>
      ApiJson.map(await _api.get('/mes-enfants/$childId/situation-financiere'));

  static PaymentMode _mode(Object? v) => switch (v) {
    'ESPECES' => PaymentMode.especes,
    'MOBILE_MONEY' => PaymentMode.mobileMoney,
    _ => PaymentMode.virement, // VIREMENT, CHEQUE
  };

  static PaymentRecord _payment(Map<String, dynamic> p) {
    final valid = p['statut'] != 'ANNULE';
    return PaymentRecord(
      id: p['id'] as String? ?? '',
      date: ApiJson.parseDate(p['date']) ?? DateTime.now(),
      amount: ApiJson.toInt(p['montant']),
      mode: _mode(p['mode']),
      status: valid ? PaymentStatus.confirme : PaymentStatus.rejete,
      receiptNumber: p['numeroRecu'] as String?,
      reference: p['reference'] as String?,
    );
  }

  @override
  Future<FinancialSituation> getSituation(String childId) async {
    final s = await _situation(childId);
    final totalPaid = ApiJson.toInt(s['totalPaye']);
    final fees = ApiJson.list(s['fraisApplicables'])
      ..sort((a, b) => '${a['dateEcheance']}'.compareTo('${b['dateEcheance']}'));
    // Les versements sont considérés réglés dans l'ordre des échéances.
    var cumulated = 0;
    final installments = [
      for (final f in fees)
        () {
          cumulated += ApiJson.toInt(f['montant']);
          return Installment(
            label: f['libelle'] as String? ?? 'Frais',
            amount: ApiJson.toInt(f['montant']),
            dueDate: ApiJson.parseDate(f['dateEcheance']) ?? DateTime.now(),
            paid: totalPaid >= cumulated,
          );
        }(),
    ];
    final payments = ApiJson.list(s['paiements']).map(_payment).toList()..sort((a, b) => a.date.compareTo(b.date));
    return FinancialSituation(
      year: 'Année en cours',
      totalDue: ApiJson.toInt(s['totalDu']),
      totalPaid: totalPaid,
      installments: installments,
      lastReceipt: payments.where((p) => p.hasReceipt).lastOrNull,
    );
  }

  /// Paiements encaissés + déclarations du parent encore en attente ou rejetées
  /// (une déclaration validée devient un paiement avec reçu).
  @override
  Future<List<PaymentRecord>> getHistory(String childId) async {
    final s = await _situation(childId);
    final payments = ApiJson.list(s['paiements']).map(_payment).toList();
    for (final p in payments) {
      _childOfPayment[p.id] = childId;
    }
    final declarations = ApiJson.list(await _api.get('/mes-enfants/$childId/declarations-paiement'))
        .where((d) => d['statut'] != 'VALIDEE')
        .map(_declaration);
    return [...payments, ...declarations]..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<PaymentRecord> declarePayment(PaymentDeclaration declaration) async {
    final path = declaration.proof.path;
    if (path == null) throw const ServerException('Joignez la preuve du paiement.');
    final created = await _api.postMultipart(
      '/mes-enfants/${declaration.childId}/declarations-paiement',
      fields: {
        'montant': '${declaration.amount}',
        'mode': _apiMode(declaration.mode),
        'reference': declaration.reference.trim(),
        'date': ApiJson.date(declaration.paidAt),
      },
      fileField: 'preuve',
      filePath: path,
      fileName: declaration.proof.name,
    );
    return _declaration(ApiJson.map(created));
  }

  /// Télécharge le reçu PDF puis demande au parent où l'enregistrer.
  @override
  Future<String> downloadReceipt(String paymentId) async {
    final childId = _childOfPayment[paymentId];
    if (childId == null) throw const ServerException('Reçu introuvable. Actualisez l’historique.');
    final bytes = await _api.getBytes('/mes-enfants/$childId/paiements/$paymentId/recu');
    final saved = await FilePicker.saveFile(
      fileName: 'recu-$paymentId.pdf',
      bytes: Uint8List.fromList(bytes),
      mimeType: 'application/pdf',
      dialogTitle: 'Enregistrer le reçu',
    );
    if (saved == null) throw const ServerException('Enregistrement du reçu annulé.');
    return saved.pathSegments.isEmpty ? 'recu.pdf' : Uri.decodeComponent(saved.pathSegments.last);
  }
}
