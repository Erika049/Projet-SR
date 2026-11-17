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
│   ├── constants/            # URL d'API, USE_MOCK, constantes
│   ├── errors/               # Exceptions (data) et Failures (domain)
│   ├── extensions/           # context.showMessage, context.text…
│   ├── network/              # ApiClient (dio), NetworkInfo, mockDelay
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
- **Mot de passe** : 6 caractères minimum ; le nouveau mot de passe doit être saisi deux fois.
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

## Données fictives et branchement du backend

Tant que le backend n'existe pas, chaque feature utilise une `XxxMockDataSource` fidèle aux maquettes.
Pour brancher l'API : écrire `XxxApiDataSource implements XxxRemoteDataSource` (exemple fourni :
`AuthApiDataSource`) puis l'enregistrer dans `app/di/injection.dart`.
`flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://…`

API d'authentification attendue par `AuthApiDataSource` (chemins à aligner avec le backend) :

| Appel                         | Corps                                   | Réponse                              |
|-------------------------------|-----------------------------------------|--------------------------------------|
| `POST /auth/login`            | `identifiant`, `mot_de_passe`           | `access_token`, `utilisateur`        |
| `POST /auth/register`         | `nom_complet`, `telephone`, `email`, `mot_de_passe` | — (envoie le code SMS)   |
| `POST /auth/otp/verify`       | `telephone`, `code`                     | `access_token`, `utilisateur`        |
| `POST /auth/otp/resend`       | `telephone`                             | —                                    |
| `POST /auth/password/forgot`  | `identifiant`                           | — (envoie le code SMS)               |
| `POST /auth/password/verify`  | `telephone`, `code`                     | `reset_token` (usage unique)         |
| `POST /auth/password/reset`   | `reset_token`, `mot_de_passe`           | —                                    |
| `GET /me/etablissements`      | —                                       | liste des établissements             |

L'appel envoie pour chaque élève `{inscription_id, statut}` avec `statut` = `present` ou `absent`.

Comptes de test (connexion par **téléphone + mot de passe** uniquement, code OTP `123456`) :

| Profil     | Téléphone   | Mot de passe |
|------------|-------------|--------------|
| Parent     | 690000001   | parent123    |
| Parent     | 690000002   | parent123    |
| Enseignant | 670000001   | prof123      |
| Enseignant | 670000002   | prof123      |

Détails et scénarios : `COMPTES_DE_TEST.md`.

Code de liaison d'un enfant : `SC-4F7K-92`.

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
| Datasource           | `children_remote_data_source.dart`   | `ChildrenMockDataSource`     |
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
