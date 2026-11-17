import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:schoolconnect/app/app.dart';
import 'package:schoolconnect/app/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('fr_FR');
    await configureDependencies();
  });

  testWidgets('bienvenue → connexion → inscription', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const SchoolConnectApp());

    // 0. La page de bienvenue s'affiche en premier.
    await tester.pump();
    expect(find.text('Pensé pour les écoles du Cameroun'), findsOneWidget);

    await tester.pumpAndSettle();
    // Elle reste affichée tant qu'on n'appuie pas sur « Démarrer ».
    expect(find.text('Démarrer'), findsOneWidget);
    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();

    // 2-4. Connexion : téléphone + mot de passe, sans langue ni choix Email.
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('English'), findsNothing);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Créer un compte parent'), findsNothing);
    expect(find.textContaining('Personnel de l’école'), findsNothing);
    expect(find.text('Vous n’avez pas de compte ?'), findsOneWidget);

    // 1. Inscription : bouton « Envoyer ».
    await tester.tap(find.text('S’inscrire'));
    await tester.pumpAndSettle();
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
    expect(find.text('Recevoir le code SMS'), findsNothing);

    // Mot de passe oublié.
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    expect(find.text('Envoyer le code'), findsOneWidget);

    // Étape 1 → 2 : numéro puis code SMS.
    await tester.enterText(find.byType(TextFormField), '690000001');
    await tester.tap(find.text('Envoyer le code'));
    await tester.pumpAndSettle();
    expect(find.text('Code de vérification'), findsOneWidget);

    // Étape 2 → 3 : le code collé dans la 1re case est validé automatiquement.
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle();
    expect(find.text('Nouveau mot de passe'), findsWidgets);

    // Étape 3 → connexion.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nouveau1');
    await tester.enterText(fields.at(1), 'nouveau1');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.textContaining('Mot de passe modifié'), findsOneWidget);
  });
}
