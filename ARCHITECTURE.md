# Architecture — SchoolConnect (mobile)

Application Flutter des espaces **Parent** et **Enseignant**. Les autres profils
(direction, secrétariat, surveillance, économat) utilisent l'application web.

Le projet suit une **Clean Architecture organisée par fonctionnalité (feature-first)**.
Chaque fonctionnalité est découpée en trois couches : `domain`, `data`, `presentation`.

## Pile technique

| Besoin                     | Paquet                         |
|----------------------------|--------------------------------|
| Gestion d'état             | `flutter_bloc` (Cubit)         |
| Navigation                 | `go_router` (StatefulShellRoute pour les barres d'onglets) |
| Injection de dépendances   | `get_it`                       |
| HTTP                       | `dio`                          |
| Stockage local / cache     | `shared_preferences`           |
| Égalité des objets         | `equatable`                    |
| Dates / montants (fr_FR)   | `intl`                         |
| Pièces jointes             | `file_picker`                  |
| Autorisations du téléphone | `permission_handler`           |
| Icône de l'application     | `flutter_launcher_icons` (dev) |

## Arborescence

```
assets/
├── images/logo.png           # Logo (page de bienvenue), fond transparent
└── icons/                    # Sources de l'icône du téléphone (app_icon*.png)
lib/
├── main.dart                 # Initialise les dates fr, la DI, lance l'app
├── app/                      # Assemblage de l'application
│   ├── app.dart              # MaterialApp.router, thème clair, langue, suivi de l'autorisation notifications
│   ├── di/injection.dart     # Enregistrement de toutes les dépendances (get_it)
│   ├── router/               # routes.dart (chemins) + app_router.dart (redirections par rôle)
│   ├── settings/             # SettingsCubit (langue, notifications, faible conso) + permission_prompts
│   ├── shell/                # Barres d'onglets Parent / Enseignant, page « Suivi »
│   └── theme/                # Couleurs (Marine, Vert, Ambre, Rouge) et ThemeData
├── core/                     # Code partagé, sans logique métier spécifique
│   ├── constants/            # URL d'API, constantes
│   ├── errors/               # Exceptions (data) et Failures (domain)
│   ├── extensions/           # context.showMessage, context.text…
│   ├── network/              # ApiClient (dio), ApiJson, TeacherApiContext, NetworkInfo, mockDelay
│   ├── permissions/          # AppPermissions : notifications et accès aux fichiers
│   ├── storage/              # LocalStorage, SyncQueue (opérations hors connexion)
│   ├── usecases/             # Contrat UseCase<T, Params>
│   ├── utils/                # Result/guard, Formatters (FCFA, dates), Validators, DataState
│   └── widgets/              # Composants réutilisables (voir ci-dessous)
└── features/
    ├── auth/                 # Bienvenue, connexion, inscription + code SMS, mot de passe oublié (3 étapes), établissement, session
    ├── children/             # Enfants liés, droits, code de liaison, fiche enfant
    ├── home/                 # Accueils Parent et Enseignant
    ├── grades/               # Notes & bulletins (parent) · saisie, correction, appréciations, stats (enseignant)
    ├── attendance/           # Absences & justificatifs (parent) · appel présent/absent, ma présence (enseignant)
    ├── payments/             # Situation financière, déclaration de paiement avec preuve, reçus
    ├── notifications/        # Notifications (push par défaut), préférences d'alertes, annonces
    ├── timetable/            # Emploi du temps de l'enseignant
    ├── sync/                 # File de synchronisation hors connexion
    └── profile/              # Profils et paramètres
```

Chaque feature :

```
<feature>/
├── domain/        ❶ Dart pur : entities/, repositories/ (contrats), usecases/
├── data/          ❷ datasources/ (mock + API), models/ (JSON ↔ entités), repositories/ (implémentations)
└── presentation/  ❸ pages/, widgets/, state/ (Cubits)
```

Les use cases d'une feature sont regroupés dans `domain/usecases/<feature>_usecases.dart`
(une classe par cas d'utilisation, références CU-PAR-xx / CU-ENS-xx en commentaire).

## Composants réutilisables (`core/widgets/`)

`AppPage` (gabarit des écrans : barre blanche avec flèche de retour et titre de la page), `AppButton` (primaire, secondaire, soft, grisé), `AppTextField`,
`PillSelector` (pastilles), `StatusChip` (Justifié / En attente / À justifier), `AppCard`,
`HighlightCard`, `InfoBanner` (hors connexion), `SelectField` (sélecteur ⌄), `StatTile`,
`SectionTitle`, `KeyValueRow`, `NavRow`, `HelpText`, `MessageView` / `ErrorView` / `LoadingView`,
`DataStateBuilder`. Tous sont importables via `core/widgets/widgets.dart`.

Règle : un widget utilisé par une seule feature reste dans `features/<feature>/presentation/widgets/` ;
dès qu'une deuxième feature en a besoin, il passe dans `core/widgets/`.

Écrans d'authentification (`features/auth/presentation/widgets/`) :
- `AuthLayout` : bandeau marine arrondi (flèche de retour + titre de la page, sous-titre,
  indicateur « Étape x sur y ») puis formulaire, avec un lien en bas d'écran (`AuthLink`).
- `AuthLogo` : logo `assets/images/logo.png` sur carré blanc arrondi (page de bienvenue).
- `OtpCodeField` + `ResendCodeLink` : saisie du code SMS en 6 cases, partagée par l'inscription
  et le mot de passe oublié.

## Thème

L'application est **uniquement en thème clair** (`AppTheme.build(dark: false)`, `ThemeMode.light`).
Les couleurs sont lues dans `AppColors` (Marine `navy`, Vert `green`, Ambre `amber`, Rouge `red`,
`header` pour les bandeaux d'authentification).

## Notifications et autorisations du téléphone

- Les alertes sont envoyées en **push par défaut** (`NotificationPreferences.defaultChannel`) ;
  SMS et email sont désactivés tant que le parent ne les active pas.
- À la **première connexion ou après l'inscription**, la demande d'autorisation des notifications
  du téléphone s'affiche **directement** (sans boîte de dialogue intermédiaire), une seule fois
  par téléphone (`LocalStorage.keyNotificationsPrompted`).
- L'interrupteur **Notifications** du profil reflète à la fois le choix de l'utilisateur et
  l'autorisation du téléphone (relue au démarrage et au retour dans l'application).
- **Accès aux fichiers** : demandé directement au moment de joindre une preuve de paiement
  (`ensureFilesPermission`).
- Si une autorisation a été **bloquée définitivement**, une boîte propose d'ouvrir les paramètres
  du téléphone (le système n'affiche plus de demande dans ce cas).
- Déclarations : `POST_NOTIFICATIONS`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` (≤ Android 12)
  dans `AndroidManifest.xml` ; `NSPhotoLibraryUsageDescription` dans `ios/Runner/Info.plist`.
- Les notifications push venant du serveur nécessiteront Firebase Cloud Messaging (non branché).

## Règles métier principales

- **Présence des élèves** : un élève est **présent** ou **absent** (`RollCallStatus`), il n'y a
  pas de retard. Le parent ne voit que les absences et peut les justifier. (Le statut « Retard »
  n'existe que pour la présence de l'enseignant, `StaffStatus`.)
- **Déclaration de paiement** (`DeclarePayment`) : montant > 0 et ≤ solde restant, date de paiement
  obligatoire et non future, référence obligatoire, preuve obligatoire (JPG, PNG ou PDF, 5 Mo max).
- **Mot de passe** : 8 caractères minimum à la création (règle du serveur) ; le nouveau mot de passe doit être saisi deux fois.
- **Mot de passe oublié** : l'étape 1 répond de la même façon que le numéro soit inscrit ou non,
  pour ne pas révéler qui est inscrit.

## Règle de dépendance

```
presentation  ──►  domain  ◄──  data
```

- `domain` ne dépend de rien (ni Flutter, ni `data`, ni HTTP).
- `data` implémente les contrats de `domain` et convertit les exceptions en `Failure` via `guard()`.
- `presentation` n'appelle que des **use cases**, jamais un datasource.
- Une feature n'importe pas la couche `data` d'une autre feature.
- Exceptions assumées : `SessionCubit` (auth) et `ChildrenCubit` (children) sont des états globaux
  partagés par les espaces ; `app/` assemble librement les features (ex. page « Suivi »).

## Backend

L'application est branchée par défaut sur le **backend SchoolConnect** :

- URL : `https://school-connect-backend-production-d24122f4.up.railway.app/api/v1`
  (Swagger : `…/swagger-ui/index.html`), modifiable avec `--dart-define=API_BASE_URL=…`.
- Authentification par jeton JWT (`Authorization: Bearer …`), ajouté par `ApiClient`.
- Erreurs du serveur `{status, error, details}` affichées en français à l'écran.
  Un 401 **sans** jeton (mauvais identifiants) n'est pas une session expirée.

Chaque feature a une source de données `XxxApiDataSource` (backend), enregistrée dans `app/di/injection.dart`.
L'application ne contient aucune donnée fictive. Seul le test d'interface `test/features/auth/auth_flow_test.dart`
remplace l'authentification par `test/support/auth_fake_data_source.dart` pour tourner sans serveur.

`core/network/teacher_api_context.dart` regroupe ce que partagent l'emploi du temps, l'appel
et les notes de l'enseignant : établissement choisi, affectations (classe + matière), élèves
de la classe, période de saisie ouverte.

### Correspondance avec l'API

| Fonction de l'application                 | Route du backend                                                        |
|-------------------------------------------|-------------------------------------------------------------------------|
| Connexion                                 | `POST /auth/login` `{identifiant, motDePasse}`                           |
| Inscription d'un parent (session ouverte directement, sans code SMS) | `POST /auth/register` `{prenom, nom, telephone, email, motDePasse, langue}` |
| Mot de passe oublié (code SMS → nouveau mot de passe) | `POST /auth/mot-de-passe-oublie`, `…/verifier` → jeton, `…/reinitialiser` |
| Rôle et établissements de l'enseignant    | `GET /auth/me`, `GET /etablissements/{id}`                               |
| Classes de l'enseignant                   | `GET /etablissements/{etab}/mes-affectations`, `…/classes?anneeScolaireId`, `…/matieres` |
| Élèves d'une classe                       | `GET /etablissements/{etab}/classes/{classe}/eleves`                     |
| Emploi du temps de l'enseignant           | `GET /etablissements/{etab}/mon-emploi-du-temps`                         |
| Appel (présent / absent), fiche soumise au surveillant général | `GET` / `POST /etablissements/{etab}/classes/{classe}/appels`, `PATCH …/appels/{id}` |
| Saisie et correction des notes            | `POST …/classes/{classe}/matieres/{matiere}/evaluations`, `PATCH …/evaluations/{id}` |
| Période de saisie                         | `GET /etablissements/{etab}/annees-scolaires/{annee}/periodes`           |
| Enfants du parent, liaison par code, retrait | `GET /mes-enfants`, `GET\|POST /mes-enfants/liaisons`, `DELETE /mes-enfants/{id}` |
| Périodes de l'enfant                      | `GET /mes-enfants/{eleveId}/periodes`                                    |
| Absences d'un enfant (avec état du justificatif) | `GET /mes-enfants/{eleveId}/presences?from&to`                    |
| Justifier une absence                     | `POST /mes-enfants/{eleveId}/justificatifs` (multipart : dateDebut, motif, piece) |
| Notes d'un enfant (nom et coefficient des matières) | `GET /mes-enfants/{eleveId}/notes?periodeId`                    |
| Situation financière, paiements           | `GET /mes-enfants/{eleveId}/situation-financiere`                        |
| Déclarer un paiement, déclarations en attente | `POST\|GET /mes-enfants/{eleveId}/declarations-paiement`             |
| Reçu PDF (enregistré où le parent choisit) | `GET /mes-enfants/{eleveId}/paiements/{id}/recu`                        |
| Notifications, « tout marquer comme lu »  | `GET /mes-notifications`, `PATCH /mes-notifications/lues`                |
| Annonces                                  | notifications de type `MESSAGE_ETABLISSEMENT`                            |
| Accueil parent                            | moyenne et absences à justifier par enfant + notifications non lues      |

Règles appliquées pour le serveur :
- Mot de passe d'au moins **8 caractères** à l'inscription ; prénom **et** nom obligatoires.
- Numéro de téléphone envoyé sous la forme `+2376XXXXXXXX` (inscription, connexion, mot de passe oublié).
- Un compte avec le rôle `ENSEIGNANT` ouvre l'espace Enseignant ; un compte sans rôle
  d'établissement est un parent ; les rôles administratifs seuls sont refusés (application web).
- **Appel** : la fiche soumise par l'enseignant part chez le surveillant général, qui la vérifie sur le web
  puis prévient les parents des absents. Le parent ne voit l'absence qu'à ce moment-là.
- Code de liaison : 8 lettres ou chiffres remis par le secrétariat ; la demande est validée par le secrétariat.
- Brouillon de notes conservé sur le téléphone ; l'évaluation est créée sur le serveur à la soumission.

### Fonctions encore sans route sur le backend

Ces écrans affichent « … : pas encore disponible sur le serveur SchoolConnect. »

| Fonction                                   | Route à prévoir côté backend (proposition)                     |
|--------------------------------------------|----------------------------------------------------------------|
| Signaler une erreur, demande de correction | `POST /mes-enfants/{eleveId}/signalements`                     |
| Bulletins (liste, PDF)                     | `GET /mes-enfants/{eleveId}/bulletins`                         |
| Appréciations, statistiques de classe      | routes dédiées                                                 |
| Présence de l'enseignant (« Ma présence ») | routes dédiées                                                 |
| Préférences d'alertes                      | conservées sur le téléphone en attendant                       |
| Notifications push                         | Firebase Cloud Messaging (à prévoir : jeton de l'appareil + envoi par le serveur) |

### Serveur local

Backend lancé sur le PC (voir `docs/INTEGRATION-MOBILE-WEB.md` du dépôt backend) :

```bash
# Émulateur Android (10.0.2.2 = le PC)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
# Téléphone sur le même Wi-Fi : adresse IP du PC
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080/api/v1
```

Le HTTP non chiffré n'est autorisé que dans les versions de débogage (`android/app/src/debug/AndroidManifest.xml`).
Comptes du jeu de données local : `COMPTES_DE_TEST.md`.
## Hors connexion

- L'appel et les brouillons de notes sont placés dans la `SyncQueue` quand `NetworkInfo` est hors ligne,
  puis envoyés depuis l'écran « Synchronisation ».
- Les notifications sont mises en cache et restent visibles hors connexion.
- `SimulatedNetworkInfo.online = false` permet de tester ces écrans ; à remplacer par `connectivity_plus`.

## Conventions de nommage

| Élément              | Fichier                              | Classe                       |
|----------------------|--------------------------------------|------------------------------|
| Entity               | `child.dart`                         | `Child`                      |
| Model / mapper       | `child_model.dart`                   | `ChildModel`                 |
| Repository (contrat) | `children_repository.dart`           | `ChildrenRepository`         |
| Repository (impl.)   | `children_repository_impl.dart`      | `ChildrenRepositoryImpl`     |
| Datasource           | `children_remote_data_source.dart`   | `ChildrenApiDataSource`      |
| Use cases            | `children_usecases.dart`             | `GetChildren`, `LinkChild`…  |
| Cubit                | `children_cubit.dart`                | `ChildrenCubit`              |
| Page                 | `link_child_page.dart`               | `LinkChildPage`              |

## Tests

`test/` reproduit l'arborescence de `lib/`. Lancer avec `flutter test`.

| Fichier                                         | Contenu                                                        |
|-------------------------------------------------|----------------------------------------------------------------|
| `test/features/domain_rules_test.dart`          | Moyenne pondérée, barème des notes, validation des déclarations de paiement |
| `test/features/auth/auth_mock_data_source_test.dart` | Comptes de test, inscription, mot de passe oublié (code, jeton à usage unique) |
| `test/features/auth/auth_flow_test.dart`        | Parcours à l'écran : bienvenue → connexion → inscription → mot de passe oublié |

## Environnement Android

SDK `C:\Android\Sdk`, NDK `28.2.13676358` (`ndkVersion = flutter.ndkVersion`), `compileSdk = 37`
(exigé par `permission_handler_android`, avec `android.suppressUnsupportedCompileSdk=37` dans
`android/gradle.properties`), Java 17.
