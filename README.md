# SchoolConnect — application mobile

**SchoolConnect** est un projet mis à la disposition des établissements secondaires camerounais
pour centraliser et sécuriser leur gestion administrative, pédagogique et financière, et rapproche
l'école des familles.

Ce dépôt contient l'**application mobile** des espaces **Parent** et **Enseignant**.
Les autres profils (direction, secrétariat, surveillance, économat/comptabilité) utilisent l'application web.

## Fonctionnalités

**Accès**
- Page de bienvenue, puis connexion par **numéro de téléphone + mot de passe**.
- Inscription d'un parent avec vérification du numéro par code SMS.
- Mot de passe oublié en 3 étapes : numéro → code SMS → nouveau mot de passe.
- Enseignant rattaché à plusieurs établissements : choix de l'établissement à la connexion.

**Espace Parent**
- Accueil, fiche de chaque enfant, liaison d'un enfant par code.
- Notes et bulletins.
- Absences (un élève est **présent** ou **absent**) et justification des absences.
- Situation financière, **déclaration de paiement** (montant, date, référence, preuve image/PDF), reçus.
- Notifications (push par défaut), annonces et convocations.

**Espace Enseignant**
- Emploi du temps, **appel** (présent / absent), saisie et correction des notes, appréciations,
  statistiques de classe, « Ma présence ».
- Fonctionnement hors connexion avec synchronisation différée.

**Profil**
- Activation / désactivation des notifications, reliée à l'autorisation du téléphone.
- Langue, mode faible consommation, enfants et droits, déconnexion.

L'application est en **français** par défaut et uniquement en **thème clair**.

## Prérequis

| Outil          | Version / emplacement                                  |
|----------------|--------------------------------------------------------|
| Flutter        | 3.44 (Dart 3.12)                                        |
| Android SDK    | `C:\Android\Sdk`                                        |
| Android NDK    | `C:\Android\Sdk\ndk\28.2.13676358`                      |
| compileSdk     | 37 (exigé par `permission_handler`)                     |
| Java           | 17                                                      |

Le chemin du SDK est défini dans `android/local.properties` (`sdk.dir=C:\\Android\\Sdk`) et pour
Flutter avec `flutter config --android-sdk C:\Android\Sdk`.

## Démarrage

```bash
flutter pub get
flutter devices                      # repérer l'identifiant du téléphone
flutter run -d <identifiant>         # ex. flutter run -d 26031JEGR02593 (Pixel 6a)
```

Par défaut l'application est branchée sur le **backend SchoolConnect**
(`https://school-connect-backend-production-d24122f4.up.railway.app`, Swagger : `/swagger-ui/index.html`).

```bash
flutter run -d <identifiant> --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1  # serveur local (émulateur)
flutter run -d <identifiant> --dart-define=API_BASE_URL=https://…/api/v1   # autre serveur
```

Toutes les données viennent du serveur : l'application ne contient aucune donnée fictive.
Ce qui attend encore une route du backend : voir [ARCHITECTURE.md](ARCHITECTURE.md#backend).

## Comptes de test

Comptes du jeu de données local (script `scripts/donnees-test-local.ps1` du backend) :

| Profil     | Téléphone   | Mot de passe |
|------------|-------------|--------------|
| Parent     | 690000001   | parent2026   |
| Enseignant | 670000001   | prof2026     |

Tous les comptes, les codes de liaison et les scénarios : [COMPTES_DE_TEST.md](COMPTES_DE_TEST.md).

## Commandes utiles

```bash
dart analyze lib test               # analyse statique
flutter test                        # tests unitaires et de widgets
dart run flutter_launcher_icons     # régénérer l'icône après modification du logo
```

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — organisation du code, règles, autorisations, API attendue.
- [COMPTES_DE_TEST.md](COMPTES_DE_TEST.md) — comptes de démonstration et scénarios à tester.
