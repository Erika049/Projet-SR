# Comptes de test — SchoolConnect

Les applications mobile et web n'ont plus de données fictives : tout vient de la base PostgreSQL du backend.
Les comptes et données ci-dessous sont créés par le script `scripts/donnees-test-local.ps1` du dépôt backend
(sur une base vide, serveur local lancé).

Application **mobile** (parents, enseignants) : connexion avec le **numéro de téléphone et le mot de passe**. Application **web** (personnel) : connexion avec l'**adresse e-mail et le mot de passe**, sans inscription possible. Les deux applications sont uniquement en français. Le numéro peut être saisi
avec ou sans `+237` et avec des espaces (`690000001`, `+237 690 000 001` et `690 00 00 01` sont acceptés).

## 1. Serveur local

Lancer le backend (voir `docs/INTEGRATION-MOBILE-WEB.md` du dépôt backend), puis l'application :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1   # émulateur Android
```

Application web : `API_URL=http://localhost:8080/api/v1` dans `.env.local`, puis `npm run dev`.

### Application mobile

| Profil | Nom | Téléphone | Mot de passe | À tester |
|---|---|---|---|---|
| Parent | Madeleine Etame | `690000001` | `parent2026` | 2 enfants (Amina 3e A, Junior 6e B), notes, absences, justificatif, déclaration, reçus, code de liaison de Paul |
| Parent | Jean Nkoulou | `690000002` | `parent2026` | Boris (3e A), paiements soldés |
| Parent | Marie Mbarga | `690000003` | `parent2026` | Carine (3e A) |
| Parent | Pauline Ngo | `690000004` | `parent2026` | Esther (3e A) |
| Enseignant | Paul Kamga | `670000001` | `prof2026` | maths en 3e A (5 élèves), 4e B, 6e B ; appel, notes, emploi du temps |
| Enseignante | Aïcha Bello | `670000002` | `prof2026` | français et anglais en 3e A, anglais en 6e B |

### Application web

| Rôle | Nom | Adresse e-mail | Mot de passe |
|---|---|---|---|
| Directeur | Samuel Nguele | `direction@lbb.cm` | `Ecole2026` |
| Secrétaire | Brigitte Ondoa | `secretariat@lbb.cm` | `Ecole2026` |
| Surveillant général | Joseph Mvondo | `surveillance@lbb.cm` | `Ecole2026` |
| Économe | Florence Tchamba | `economat@lbb.cm` | `Ecole2026` |
| Super-admin | Admin Super | `admin@schoolconnect.cm` | `AdminLocal2026` |

### Autres établissements

La base contient 3 établissements : LBB (ci-dessus), le Collège Saint-Joseph de Bafoussam (CSJB) et le Lycée technique de Garoua (LTG). **Paul Kamga** enseigne à LBB et au CSJB, tous deux à Bafoussam : il choisit l'établissement à la connexion. **Jean Nkoulou** a un enfant dans chacun des deux premiers. Comptes des établissements générés : `docs/DONNEES-TEST-ETABLISSEMENTS.md` du dépôt backend (ex. `direction@csjb.cm` / `Ecole2026`, enseignant `670010001` / `prof2026`, parent `691000001` / `parent2026`).

### Scénarios de bout en bout

**Appel → surveillant général → parents**
1. Mobile, **Paul Kamga** : **Appel** d'une classe (ex. 3e A, 5 élèves), marquer un élève **A**, puis
   **Soumettre la fiche d'appel**. Les parents ne sont **pas encore** prévenus.
2. Web, **Joseph Mvondo** : **Présences** → « Fiches d'appel à vérifier » → **Vérifier la fiche** →
   **Notifier les parents des absents**. (Les fiches du 18/11 en 3e A et 6e B sont déjà en attente.)
3. Mobile, parent de l'élève : la notification « Absence de … » arrive et l'absence apparaît dans **Suivi → Absences**.
   David Njoya (3e A) n'a pas de parent lié : le web l'indique au surveillant.

**Justificatif d'absence**
1. Mobile, **Madeleine Etame** : **Suivi → Absences** → une absence « À justifier » → motif + photo ou PDF → **Envoyer**.
2. Web, **Joseph Mvondo** : **Justificatifs** → ouvrir la pièce → **Valider** ou **Refuser** (commentaire facultatif).
3. Mobile : notification de la décision, l'absence passe à « Justifié » ou « Refusé ».

**Déclaration de paiement**
1. Mobile, **Madeleine Etame** : **Suivi → Paiements → Déclarer un paiement** (mode, montant, date, référence, preuve).
2. Web, **Florence Tchamba** : **Déclarations** → ouvrir la preuve → **Valider** (paiement enregistré, reçu émis)
   ou **Rejeter** (motif transmis au parent).
3. Mobile : le paiement validé apparaît avec son reçu ; **Télécharger** enregistre le reçu PDF.

**Lier un enfant par code**
1. Mobile, **Madeleine Etame** : **Enfants → Lier un enfant** → code affiché à la fin du script de données
   (enfant : Paul Etame, 4e B).
2. Web, **Brigitte Ondoa** : **Demandes** → **Accepter**.
3. Mobile : Paul apparaît dans la liste des enfants.

**Demande de correction des informations d'un enfant**
1. Mobile, **Madeleine Etame** : **Profil → Mes enfants → Demander une correction** → choisir l'enfant, décrire l'erreur → **Envoyer**.
2. Web, **Brigitte Ondoa** : **Demandes de correction** → **Traiter** → corriger la fiche pré-remplie → **Enregistrer et accepter**
   (ou **Refuser** avec la raison).
3. Mobile : notification « Demande de correction acceptée » (ou refusée, avec la réponse) ; la fiche de l'enfant est à jour.

**Modifier un membre du personnel**
Web, **Samuel Nguele** : **Personnel** → un membre → **Modifier les informations** (nom, e-mail, téléphone, rôles).

**Mot de passe oublié**
1. Mobile : **Mot de passe oublié ?** → numéro → **Envoyer le code**.
2. Aucun fournisseur SMS n'est branché : en local, le code est écrit dans les journaux du serveur
   (`[DEV] Code de vérification SchoolConnect pour +237… : 123456`).
3. Saisir le code, puis le nouveau mot de passe (8 caractères minimum).

**Inscrire un nouveau parent et le lier à son enfant**
1. Mobile : **S'inscrire** avec un numéro non utilisé (ex. `690000011`), prénom et nom, mot de passe
   (8 caractères minimum). Le compte est créé dans la base et la session s'ouvre directement.
2. **Enfants → Lier un enfant** : saisir un des codes libres affichés à la fin du script de données
   (un par élève sans parent : David Njoya, Gaëlle Abena, Hervé Nana, Kevin Ateba, Laure Bella).
   Chaque code ne sert qu'une fois et reste valable 30 jours.
3. Web, **Brigitte Ondoa** : **Demandes de liaison** → **Accepter**.
4. Mobile : l'enfant apparaît, avec ses notes, absences, emploi du temps et paiements.

Pour obtenir un nouveau code : web, secrétariat → **Élèves** → dossier de l'élève → **Ajouter un parent ou tuteur**
(numéro sans compte) ; le code s'affiche et la **Fiche de liaison** imprimable le reprend.
Si le numéro a déjà un compte, le parent est lié directement, sans code.

## Tests automatiques

Le test d'interface `test/features/auth/auth_flow_test.dart` utilise une fausse authentification
(`test/support/auth_fake_data_source.dart`) pour tourner sans serveur ; elle n'est pas incluse dans l'application.

## Notifications du téléphone

- À la **première connexion** (ou après une inscription), Android demande directement
  l'autorisation d'envoyer des notifications. Cette demande n'apparaît qu'une fois par téléphone.
- Dans **Profil**, l'interrupteur **Notifications** suit l'autorisation du téléphone.
- Les notifications sont affichées **dans l'application** (onglet Notifications) ; les notifications push
  (Firebase) ne sont pas encore branchées.

## À savoir

- La session est mémorisée : pour changer de compte, se déconnecter depuis l'onglet **Profil**.
- Appel des élèves : **P** (présent) ou **A** (absent) ; « Tous présents » remet toute la classe à présent.
