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

## Arborescence

```
lib/
├── main.dart                 # Initialise les dates fr, la DI, lance l'app
├── app/                      # Assemblage de l'application
│   ├── app.dart              # MaterialApp.router, thème, langue
│   ├── di/injection.dart     # Enregistrement de toutes les dépendances (get_it)
│   ├── router/               # routes.dart (chemins) + app_router.dart (redirections par rôle)
│   ├── settings/             # Langue FR/EN, mode faible consommation
│   ├── shell/                # Barres d'onglets Parent / Enseignant, page « Suivi »
│   └── theme/                # Couleurs (Marine, Vert, Ambre, Rouge) et ThemeData
├── core/                     # Code partagé, sans logique métier spécifique
│   ├── constants/            # URL d'API, USE_MOCK, constantes
│   ├── errors/               # Exceptions (data) et Failures (domain)
│   ├── extensions/           # context.showMessage, context.text…
│   ├── network/              # ApiClient (dio), NetworkInfo, mockDelay
│   ├── storage/              # LocalStorage, SyncQueue (opérations hors connexion)
│   ├── usecases/             # Contrat UseCase<T, Params>
│   ├── utils/                # Result/guard, Formatters (FCFA, dates), Validators, DataState
│   └── widgets/              # Composants réutilisables (voir ci-dessous)
└── features/
    ├── auth/                 # Connexion, inscription + OTP, mot de passe oublié, établissement, session
    ├── children/             # Enfants liés, droits, code de liaison, fiche enfant
    ├── home/                 # Accueils Parent et Enseignant
    ├── grades/               # Notes & bulletins (parent) · saisie, correction, appréciations, stats (enseignant)
    ├── attendance/           # Présences & justificatifs (parent) · appel, ma présence (enseignant)
    ├── payments/             # Situation financière, déclaration de paiement, reçus
    ├── notifications/        # Notifications, préférences d'alertes, annonces
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

`AppPage` (gabarit des écrans), `AppButton` (primaire, secondaire, soft, grisé), `AppTextField`,
`PillSelector` (pastilles), `StatusChip` (Justifié / En attente / À justifier), `AppCard`,
`HighlightCard`, `InfoBanner` (hors connexion), `SelectField` (sélecteur ⌄), `StatTile`,
`SectionTitle`, `KeyValueRow`, `NavRow`, `HelpText`, `MessageView` / `ErrorView` / `LoadingView`,
`DataStateBuilder`. Tous sont importables via `core/widgets/widgets.dart`.

Règle : un widget utilisé par une seule feature reste dans `features/<feature>/presentation/widgets/` ;
dès qu'une deuxième feature en a besoin, il passe dans `core/widgets/`.

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

`test/` reproduit l'arborescence de `lib/`. Les règles métier (moyenne pondérée, barème des notes,
validation des déclarations de paiement) sont testées dans `test/features/domain_rules_test.dart`.
