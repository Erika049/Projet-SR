import 'package:flutter_test/flutter_test.dart';
import 'package:schoolconnect/core/errors/exceptions.dart';
import 'package:schoolconnect/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:schoolconnect/features/auth/domain/entities/app_user.dart';

void main() {
  late AuthMockDataSource source;

  setUp(() => source = AuthMockDataSource());

  group('Comptes de test', () {
    test('chaque compte se connecte avec son téléphone et son mot de passe', () async {
      for (final account in DemoAccounts.all) {
        final session = await source.login(account.phone, account.password);
        expect(session.user.id, account.user.id);
      }
    });

    test('le numéro est accepté avec +237 et des espaces', () async {
      final session = await source.login('+237 690 00 00 01', DemoAccounts.parentPassword);
      expect(session.user.role, UserRole.parent);
    });

    test('un mauvais mot de passe est refusé', () {
      expect(source.login('690000001', 'mauvais'), throwsA(isA<AuthException>()));
    });

    test('un numéro inconnu est refusé', () {
      expect(source.login('699999999', DemoAccounts.parentPassword), throwsA(isA<AuthException>()));
    });

    test('Paul Kamga a 2 établissements, Aïcha Bello un seul', () async {
      await source.login('670000001', DemoAccounts.teacherPassword);
      expect(await source.getEstablishments(), hasLength(2));
      await source.login('670000002', DemoAccounts.teacherPassword);
      expect(await source.getEstablishments(), hasLength(1));
    });
  });

  group('Inscription', () {
    test('un parent inscrit peut ensuite se connecter', () async {
      await source.registerParent('Alice Mballa', '+237 655 123 456', null, 'secret1');
      final created = await source.verifyOtp('+237 655 123 456', DemoAccounts.otp);
      expect(created.user.prenom, 'Alice');
      expect(created.user.nom, 'Mballa');

      final session = await source.login('655123456', 'secret1');
      expect(session.user.id, created.user.id);
    });

    test('un numéro déjà utilisé est refusé', () {
      expect(source.registerParent('Doublon', '690000001', null, 'secret1'), throwsA(isA<AuthException>()));
    });

    test('un code OTP faux est refusé', () async {
      await source.registerParent('Alice Mballa', '655123456', null, 'secret1');
      expect(source.verifyOtp('655123456', '000000'), throwsA(isA<AuthException>()));
    });
  });

  group('Mot de passe oublié', () {
    test('code → nouveau mot de passe → connexion avec le nouveau seulement', () async {
      await source.requestPasswordReset('+237 690 00 00 01');
      final token = await source.verifyResetCode('690000001', DemoAccounts.otp);
      await source.resetPassword(token, 'nouveau1');

      final session = await source.login('690000001', 'nouveau1');
      expect(session.user.id, 'u-parent-1');
      expect(source.login('690000001', DemoAccounts.parentPassword), throwsA(isA<AuthException>()));
    });

    test('la demande ne révèle pas si le numéro est inscrit', () async {
      await expectLater(source.requestPasswordReset('699999999'), completes);
      expect(source.verifyResetCode('699999999', DemoAccounts.otp), throwsA(isA<AuthException>()));
    });

    test('un code faux est refusé', () {
      expect(source.verifyResetCode('690000001', '000000'), throwsA(isA<AuthException>()));
    });

    test('le jeton ne sert qu’une fois', () async {
      final token = await source.verifyResetCode('670000001', DemoAccounts.otp);
      await source.resetPassword(token, 'nouveau1');
      expect(source.resetPassword(token, 'autre12'), throwsA(isA<AuthException>()));
    });
  });
}
