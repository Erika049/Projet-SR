import 'package:flutter_test/flutter_test.dart';
import 'package:schoolconnect/core/errors/failures.dart';
import 'package:schoolconnect/core/utils/result.dart';
import 'package:schoolconnect/features/grades/domain/entities/grades.dart';
import 'package:schoolconnect/features/grades/domain/usecases/grades_usecases.dart';
import 'package:schoolconnect/features/payments/domain/entities/payments.dart';
import 'package:schoolconnect/features/payments/domain/repositories/payments_repository.dart';
import 'package:schoolconnect/features/payments/domain/usecases/payments_usecases.dart';

/// Faux repository : enregistre l'appel sans réseau.
class _FakePayments implements PaymentsRepository {
  PaymentDeclaration? declared;
  int? get declaredAmount => declared?.amount;

  @override
  Future<Result<PaymentRecord>> declarePayment(PaymentDeclaration d) async {
    declared = d;
    return Ok(
      PaymentRecord(
        id: 'x',
        date: d.paidAt,
        amount: d.amount,
        mode: d.mode,
        status: PaymentStatus.enAttente,
        reference: d.reference,
        proofName: d.proof.name,
      ),
    );
  }

  @override
  Future<Result<String>> downloadReceipt(String paymentId) => throw UnimplementedError();
  @override
  Future<Result<List<PaymentRecord>>> getHistory(String childId) => throw UnimplementedError();
  @override
  Future<Result<FinancialSituation>> getSituation(String childId) => throw UnimplementedError();
}

void main() {
  const period = Period(id: 's1', label: 'Séquence 1', kind: PeriodKind.sequence, year: '2026–2027');

  group('GradesReport.average', () {
    test('moyenne pondérée Σ(note × coef) / Σ coef — exemple des maquettes', () {
      const report = GradesReport(
        period: period,
        subjects: [
          SubjectGrade(subject: 'Mathématiques', coefficient: 4, grade: 16),
          SubjectGrade(subject: 'Français', coefficient: 4, grade: 14),
          SubjectGrade(subject: 'Anglais', coefficient: 3, grade: 13.5),
        ],
      );
      expect(report.average, closeTo(14.59, 0.01));
    });

    test('ignore les matières non notées', () {
      const report = GradesReport(
        period: period,
        subjects: [
          SubjectGrade(subject: 'Maths', coefficient: 4, grade: 12),
          SubjectGrade(subject: 'Français', coefficient: 4),
        ],
      );
      expect(report.average, 12);
    });

    test('null sans aucune note', () {
      expect(const GradesReport(period: period, subjects: []).average, isNull);
    });
  });

  group('GradeRules.validate', () {
    test('accepte 0..20, virgule et « Abs. »', () {
      for (final v in ['0', '20', '16,5', '14.0', 'Abs.', 'abs', '']) {
        expect(GradeRules.validate(v, 20), isNull, reason: v);
      }
    });

    test('refuse hors barème ou non numérique', () {
      for (final v in ['21', '-1', 'abc']) {
        expect(GradeRules.validate(v, 20), isNotNull, reason: v);
      }
    });
  });

  group('DeclarePayment', () {
    late _FakePayments repo;
    late DeclarePayment declare;
    final today = DateTime(2026, 11, 17, 10);
    const receipt = PaymentProof(name: 'recu.jpg', sizeBytes: 300 * 1024, path: '/tmp/recu.jpg');

    setUp(() {
      repo = _FakePayments();
      declare = DeclarePayment(repo, now: () => today);
    });

    DeclarePaymentParams params(
      String amount, {
      String reference = 'MP123',
      PaymentMode mode = PaymentMode.mobileMoney,
      DateTime? paidAt,
      PaymentProof? proof = receipt,
      bool noDate = false,
    }) => (
      childId: 'c',
      mode: mode,
      amount: amount,
      paidAt: noDate ? null : (paidAt ?? DateTime(2026, 11, 15)),
      reference: reference,
      proof: proof,
      balance: 45000,
    );

    Future<String> error(DeclarePaymentParams p) async => ((await declare(p)) as Err).failure.message;

    test('accepte une déclaration complète (montant formaté « 45 000 »)', () async {
      final r = await declare(params('45 000'));
      expect(r, isA<Ok<PaymentRecord>>());
      expect(repo.declaredAmount, 45000);
      expect(repo.declared!.paidAt, DateTime(2026, 11, 15));
      expect(repo.declared!.proof.name, 'recu.jpg');
    });

    test('refuse un montant supérieur au solde', () async {
      final r = await declare(params('50000'));
      expect((r as Err).failure, isA<ValidationFailure>());
    });

    test('exige la date du paiement', () async {
      expect(await error(params('10000', noDate: true)), contains('date'));
    });

    test('refuse une date dans le futur, accepte aujourd’hui', () async {
      expect(await error(params('10000', paidAt: DateTime(2026, 11, 18))), contains('futur'));
      expect(await declare(params('10000', paidAt: DateTime(2026, 11, 17, 23))), isA<Ok<PaymentRecord>>());
    });

    test('exige une référence, y compris en espèces', () async {
      expect(await declare(params('10000', reference: '  ')), isA<Err<PaymentRecord>>());
      expect(await declare(params('10000', reference: '', mode: PaymentMode.especes)), isA<Err<PaymentRecord>>());
    });

    test('exige la preuve de paiement', () async {
      expect(await error(params('10000', proof: null)), contains('preuve'));
    });

    test('accepte une preuve PDF, refuse les autres formats', () async {
      const pdf = PaymentProof(name: 'Avis_Virement.PDF', sizeBytes: 1000);
      expect(await declare(params('10000', proof: pdf)), isA<Ok<PaymentRecord>>());
      const doc = PaymentProof(name: 'recu.docx', sizeBytes: 1000);
      expect(await error(params('10000', proof: doc)), contains('PDF'));
    });

    test('refuse une preuve de plus de 5 Mo', () async {
      const big = PaymentProof(name: 'photo.png', sizeBytes: 6 * 1024 * 1024);
      expect(await error(params('10000', proof: big)), contains('5 Mo'));
    });
  });
}
