import 'package:flutter_test/flutter_test.dart';
import 'package:schoolconnect/core/errors/exceptions.dart';
import 'package:schoolconnect/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:schoolconnect/features/auth/data/models/user_model.dart';
import 'package:schoolconnect/features/auth/domain/entities/app_user.dart';

/// Lecture des réponses du backend SchoolConnect (`UserView`, identifiants).
void main() {
  Map<String, dynamic> user(List<String> roles) => {
    'id': 'u1',
    'nom': 'Kamga',
    'prenom': 'Paul',
    'telephone': '+237670000001',
    'roles': [
      for (final r in roles) {'role': r, 'etablissementId': 'e1'},
    ],
  };

  group('UserModel.fromApi', () {
    test('le rôle ENSEIGNANT ouvre l’espace Enseignant', () {
      expect(UserModel.fromApi(user(['ENSEIGNANT'])).role, UserRole.enseignant);
      expect(UserModel.fromApi(user(['DIRECTION', 'ENSEIGNANT'])).role, UserRole.enseignant);
    });

    test('un compte sans rôle d’établissement est un parent', () {
      final u = UserModel.fromApi(user([]));
      expect(u.role, UserRole.parent);
      expect(u.fullName, 'Paul Kamga');
    });

    test('les rôles administratifs seuls sont refusés sur mobile', () {
      expect(() => UserModel.fromApi(user(['SECRETARIAT'])), throwsA(isA<AuthException>()));
    });

    test('la session enregistrée se relit (toJson → fromJson)', () {
      final u = UserModel.fromApi(user(['ENSEIGNANT']));
      expect(UserModel.fromJson(u.toJson()), u);
    });
  });

  group('Identifiant de connexion', () {
    test('le numéro est envoyé sous une forme unique', () {
      for (final input in ['690000001', '+237 690 00 00 01', '237690000001', ' 690 000 001 ']) {
        expect(AuthApiDataSource.normalizeIdentifier(input), '+237690000001');
      }
    });

    test('un email est envoyé tel quel', () {
      expect(AuthApiDataSource.normalizeIdentifier(' parent@ecole.cm '), 'parent@ecole.cm');
    });
  });
}
