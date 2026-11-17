# Comptes de test — SchoolConnect mobile

Ces comptes fonctionnent tant que l'application tourne avec les données fictives
(`USE_MOCK=true`, valeur par défaut). Ils sont définis dans
`lib/features/auth/data/datasources/auth_mock_data_source.dart` (`DemoAccounts`).

La connexion se fait **uniquement avec le numéro de téléphone et le mot de passe**.
Le numéro peut être saisi avec ou sans `+237` et avec des espaces
(`690000001`, `+237 690 000 001` et `690 00 00 01` sont acceptés).

## Parents

| Nom              | Téléphone   | Mot de passe |
|------------------|-------------|--------------|
| Madeleine Etame  | `690000001` | `parent123`  |
| Jean Nkoulou     | `690000002` | `parent123`  |

## Enseignants

| Nom          | Téléphone   | Mot de passe | Ce qu'on peut tester                                         |
|--------------|-------------|--------------|--------------------------------------------------------------|
| Paul Kamga   | `670000001` | `prof123`    | 2 établissements → écran « Choisir un établissement »        |
| Aïcha Bello  | `670000002` | `prof123`    | 1 seul établissement → arrivée directe sur l'accueil         |

## Inscription d'un nouveau parent

1. Sur l'écran de connexion : **Vous n'avez pas de compte ? S'inscrire**.
2. Remplir le formulaire avec un numéro qui n'est pas dans les tableaux ci-dessus, puis **Envoyer**.
3. Code de vérification (OTP) : **`123456`**.

Le compte créé permet ensuite de se reconnecter avec ce numéro et ce mot de passe,
jusqu'à la fermeture de l'application (il n'est pas enregistré durablement).

## Mot de passe oublié

1. Sur l'écran de connexion : **Mot de passe oublié ?**, saisir le numéro, puis **Envoyer le code**.
2. Code reçu par SMS : **`123456`** (validé automatiquement au 6e chiffre).
3. Choisir le nouveau mot de passe (6 caractères minimum, saisi deux fois), puis **Enregistrer**.
4. Retour à la connexion : seul le nouveau mot de passe fonctionne désormais.

Pour ne pas révéler qui est inscrit, l'étape 1 passe toujours au code, même avec un
numéro inconnu. C'est le code qui est alors refusé (« Code incorrect ou expiré »).
Comme pour l'inscription, le changement est perdu à la fermeture de l'application.

## À savoir

- Les données affichées après connexion (enfants, notes, paiements, classes…) sont les
  mêmes données fictives pour tous les parents et pour tous les enseignants.
- La session est mémorisée : pour changer de compte, se déconnecter depuis l'onglet **Profil**.
- Pour brancher le vrai serveur : `flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://…`
