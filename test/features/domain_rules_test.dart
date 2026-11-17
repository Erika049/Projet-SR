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
  int? declaredAmount;

  @override
  Future<Result<PaymentRecord>> declarePayment({
    required String childId,
    required PaymentMode mode,
    required int amount,
    String? reference,
  }) async {
    declaredAmount = amount;
    return Ok(PaymentRecord(
      id: 'x',
      date: DateTime(2026),
      amount: amount,
      mode: mode,
      status: PaymentStatus.enAttente,
    ));
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
      const report = GradesReport(period: period, subjects: [
        SubjectGrade(subject: 'Mathématiques', coefficient: 4, grade: 16),
        SubjectGrade(subject: 'Français', coefficient: 4, grade: 14),
        SubjectGrade(subject: 'Anglais', coefficient: 3, grade: 13.5),
      ]);
      expect(report.average, closeTo(14.59, 0.01));
    });

    test('ignore les matières non notées', () {
      const report = GradesReport(period: period, subjects: [
        SubjectGrade(subject: 'Maths', coefficient: 4, grade: 12),
        SubjectGrade(subject: 'Français', coefficient: 4),
      ]);
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

    setUp(() {
      repo = _FakePayments();
      declare = DeclarePayment(repo);
    });

    DeclarePaymentParams params(String amount, {String reference = 'MP123', PaymentMode mode = PaymentMode.mobileMoney}) =>
        (childId: 'c', mode: mode, amount: amount, reference: reference, balance: 45000);

    test('accepte un montant formaté « 45 000 »', () async {
      final r = await declare(params('45 000'));
      expect(r, isA<Ok<PaymentRecord>>());
      expect(repo.declaredAmount, 45000);
    });

    test('refuse un montant supérieur au solde', () async {
      final r = await declare(params('50000'));
      expect((r as Err).failure, isA<ValidationFailure>());
    });

    test('exige une référence pour Mobile Money', () async {
      final r = await declare(params('10000', reference: ''));
      expect(r, isA<Err<PaymentRecord>>());
    });

    test('référence facultative en espèces', () async {
      final r = await declare(params('10000', reference: '', mode: PaymentMode.especes));
      expect(r, isA<Ok<PaymentRecord>>());
    });
  });
}
