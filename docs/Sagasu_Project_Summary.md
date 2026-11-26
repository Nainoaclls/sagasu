# Sagasu : résumé détaillé du projet

> Projet final Le Wagon Tokyo · objectif : une app en ligne, présentable à des investisseurs.
> Résumé de la session de travail du 23 au 26 novembre 2026. État vérifié le 26 novembre 2026.

---

## 1. Le produit en une phrase

**Sagasu** (探す, « chercher ») aide les acheteurs du BTP à **trouver, comparer et faire approuver des fournisseurs**.
L'acheteur colle sa liste de matériaux. L'IA la regroupe par type de fournisseur et propose des fournisseurs tirés de la
base de l'entreprise, avec les **preuves** de chaque suggestion et ce qui **reste à confirmer**. Le manager approuve ou
renvoie la bidder list. **Les humains décident, chaque décision est traçable.**

---

## 2. Chronologie

### 2.1 Cadrage (concept, user stories, schéma, routes)
- **Concept v0.2** : relu et analysé. Le risque principal était le périmètre (19 tables pour 2 semaines).
- **User stories** : réécrites (14 stories MVP et 2 « Later »), PDF `docs/Sagasu_User_Stories.pdf`.
  - Corrigé : une ligne copiée d'un autre projet (« interview environment »), des « So that » vides, la story de connexion manquante.
- **Schéma** :

  | Version | Tables | Contenu |
  |---|---|---|
  | v1 (équipe) | 19 | Tout le concept (audit, base de connaissances IA, approbations multi-étapes) |
  | v2 (MVP) | 9 | Seulement ce qu'utilisent les user stories, noms Rails |
  | v3 | 9 | + `approvals.snapshot`, `group_suppliers.feedback_reason`, `reviews.status` |
  | **v3.1** (construit) | 9 | + champs de preuve fournisseur, `evidence` / `missing_info` sur les suggestions |

  Depuis, une migration a ajouté `ai_runs.item_group_id`. Le fichier XML v3.1 ne l'inclut pas encore.
- **Routes** : PDF `docs/Sagasu_Routes.pdf`, une route par user story.
  - Depuis, deux ajouts : `item_groups#create` (groupe ajouté à la main) et `item_groups#edit` (renommage sur place). Le PDF ne les mentionne pas encore.

### 2.2 Identité visuelle
- **Palettes** : la palette sauge a été écartée (pas de couleur foncée ni d'accent). Palette retenue :
  **Blue Slate `#326273`**, **Pacific Blue `#5C9EAD`**, **Tangerine `#E39774`** (accent, réservé à l'IA), White, Platinum,
  plus **Ink `#1E2F36`** ajouté pour le texte.
- **Logo** : 5 pistes, puis 4 variantes du logo de Gonzalo (loupe, chemin en S, point « trouvé »). **Version A retenue**
  (SVG, plus une app icon). Charte dans `docs/brand/README.md`.
- **Règles de contraste WCAG** : jamais de texte blanc sur Pacific Blue (3,0:1) ni sur Tangerine (2,3:1).

### 2.3 Dépôts Git
- **GonBDev/sagasu** (repo de Gonzalo) : cloné dans `~/code/GonBDev/sagasu`. App générée avec le template Le Wagon *devise*.
  Branche locale `mvp` (charte, MVP, archives). **Rien n'a jamais été poussé** : le repo GitHub est toujours vide.
- **Nainoaclls/sagasu** (ton repo, **privé**) : copie complète dans `~/code/Nainoaclls/sagasu`. **C'est la version de référence aujourd'hui.**

### 2.4 Construction du MVP
Les 14 user stories sont fonctionnelles, vérifiées dans le navigateur avec la vraie IA OpenAI (détail en section 4).

### 2.5 Corrections après coup
- **Page figée après « Decline »** : le dialogue modal restait actif après le rafraîchissement de la page. Corrigé.
- **Refus sans raison** : il ne faisait rien. Il est maintenant enregistré (« No reason given »).
- **Dependabot** : `image_processing` est passé de 1.14 à 2.2 (PR #1 fusionnée par toi). Mon commit a été rejoué par-dessus, les tests passent.

### 2.6 Passage aux outils Le Wagon (PR #2, **fusionnée le 25 novembre 2026**)

| # | Changement | Effet |
|---|---|---|
| 1 | IA en tâches de fond (ActiveJob) + diffusion Turbo Stream | Plus de requête bloquante ni de risque du délai Heroku de 30 s ; la page se met à jour seule |
| 2 | Turbo Streams | Chaque action remplace seulement ce qui change, sans recharger la page |
| 3 | Simple Form partout | Erreurs sous chaque champ, style uniforme |
| 4 | Composants Bootstrap | Palette dans `$theme-colors`, modal, toasts, nav-pills, grille ; environ 110 lignes de SCSS en moins |
| 5 | SweetAlert2, Tom Select, Typed.js | Confirmations aux couleurs de la marque, listes déroulantes avec recherche, effet de frappe |
| 6 | Turbo Frame « edit in place » | Renommer un groupe sur place |
| 7 | Google Fonts | Noto Sans en ~40 Ko au lieu de 1,6 Mo |

---

## 3. État actuel (vérifié le 26 novembre 2026)

| Où | État |
|---|---|
| GitHub `Nainoaclls/sagasu` `main` | Contient tout (MVP, correctif, Dependabot, PR #2 fusionnée) |
| Local `~/code/Nainoaclls/sagasu` | Tu es sur `refactor/lewagon-tools` (avec le commit de fusion). Ton `main` local a **10 commits de retard** : fais `git switch main && git pull` |
| GitHub `GonBDev/sagasu` | **Vide** : rien n'a été poussé |
| Local `~/code/GonBDev/sagasu` | Branche `mvp` avec l'ancienne version du MVP (avant les correctifs et la PR #2) |
| Base de données | `sagasu_development` est **partagée** entre les deux dossiers locaux |

---

## 4. Ce que fait l'application

### Parcours (user stories)
1. Page d'accueil : présentation, démo animée, preuves de confiance.
2. Inscription et connexion (Devise), avec un rôle : acheteur ou approbateur.
3. Créer un projet RFQ : besoin, client, zone de livraison, budget, matériaux collés.
4. Ajouter des matériaux (collés depuis Excel ou l'ERP, ou en texte libre).
5. **Groupement par l'IA**, avec la raison de chaque groupe.
6. Modifier les groupes : renommer sur place, déplacer un matériau, ajouter un groupe à la main.
7. **Suggestions de fournisseurs par l'IA** : raison, preuves, « à confirmer ».
8. Sélectionner ou refuser une suggestion. Une raison de refus est demandée et sert de retour à l'IA.
9. Chercher un fournisseur et l'ajouter à un groupe.
10. Fiche fournisseur et avis de l'équipe.
11. Écrire un avis, en choisissant sa visibilité (toute l'organisation ou un seul projet) et si l'IA peut l'utiliser.
12. Envoyer en approbation : la liste est figée (snapshot) et verrouillée.
13. File d'attente de l'approbateur.
14. Approuver, ou renvoyer avec un commentaire obligatoire. L'historique des versions est conservé.

### Règles du concept intégrées
- **Preuves avant confiance** : une info absente s'affiche « to confirm », et l'IA n'invente jamais de chiffre.
- **Les humains décident** : l'IA suggère, l'acheteur sélectionne, seul l'approbateur désigné décide.
- **Pas de blacklist silencieuse** : un avis négatif reste une « observation non vérifiée » ; un refus est un indice, jamais une exclusion.
- **La confidentialité n'est pas un simple booléen** : visibilité, usage par l'IA et nom de l'auteur sont réglés séparément ; l'IA ne lit que ce que l'utilisateur a le droit de voir, sans les auteurs.
- **Traçabilité** : snapshot à chaque envoi en approbation ; chaque appel IA est enregistré (`AiRun` : modèle, version du prompt, entrée, sortie).

### Architecture technique
- **Rails 8.1**, PostgreSQL, Devise, Pundit (une politique par modèle), pg_search, RubyLLM avec `gpt-4.1` et un **mode de secours local**.
- **Hotwire** : Turbo Drive, Frames et Streams, diffusion Action Cable, 14 contrôleurs Stimulus.
- **Bootstrap 5.3**, Simple Form, Font Awesome, SweetAlert2, Tom Select, Typed.js (importmap).
- **Accessibilité** : lien d'évitement, focus visible, cibles de 44 px, statuts toujours écrits en texte, contrastes WCAG AA, respect de la réduction des animations.
- **Tests** : 46 tests, 188 vérifications (modèles, services IA, jobs, Turbo Streams, parcours complet, droits d'accès).

### Comptes de démo (mot de passe `sagasu123`)
| Compte | Rôle | À montrer |
|---|---|---|
| `aiko@sagasu.test` | Acheteuse | « Shinjuku office tower » : grouper avec l'IA, suggérer, sélectionner, envoyer |
| `kenji@sagasu.test` | Approbateur | File d'attente, approuver ou renvoyer |
| `yuki@`, `daichi@` | Acheteurs | Autres membres de l'équipe |
| `hiroshi@` | Approbateur | Projet Chiba renvoyé |

---

## 5. Commandes utiles

```bash
cd ~/code/Nainoaclls/sagasu
git switch main && git pull          # récupérer la version à jour
bin/rails db:migrate                 # après un pull
bin/rails db:seed                    # remettre les données de démo à zéro
bin/rails server                     # http://localhost:3000
bin/rails test                       # 46 tests
```

---

## 6. Ce qu'il reste à faire

**Avant une mise en ligne :**
- [ ] Déployer sur Heroku avec `SOLID_QUEUE_IN_PUMA=true` (sinon les tâches IA ne tournent pas) et `OPENAI_API_KEY`.
- [ ] Mettre à jour Ruby 3.3.5 vers 3.3.14 ou plus (faille signalée par Brakeman).
- [ ] Ajouter une CI GitHub Actions (tests automatiques sur chaque PR) : il n'y en a aucune.

**Équipe :**
- [ ] Gonzalo : accepter l'invitation collaborateur sur `Nainoaclls/sagasu`.
- [ ] Décider du sort du repo `GonBDev/sagasu`. Il est vide, et sa branche locale `mvp` contient une version dépassée.

**Documentation :**
- [ ] Mettre à jour le PDF des routes (`item_groups#create` et `#edit`).
- [ ] Mettre à jour le schéma XML (v3.2 : `ai_runs.item_group_id`).

**Pistes optionnelles vues au Wagon :**
- [ ] Carte des fournisseurs (Mapbox + Geocoder).
- [ ] Catalogues PDF des fournisseurs comme preuves (Cloudinary).
- [ ] File d'approbation en temps réel (Action Cable).
- [ ] Assistant « Ask Sagasu » (le robot) avec RubyLLM chat et tools.

---

## 7. Fichiers de référence (`docs/`)
- `Sagasu_Concept_v0.2.txt` : le concept d'origine
- `Sagasu_User_Stories.pdf` : les 14 user stories
- `Sagasu_Routes.pdf` : les routes (à compléter)
- `Sagasu_Schema_v3.xml`, `Sagasu_Schema_v3.1.xml` : le schéma (à importer dans kitt)
- `brand/` : logos SVG, app icon, charte graphique
- `archive/` : brouillons (sources HTML des PDF, schéma MVP, première planche de logos)
