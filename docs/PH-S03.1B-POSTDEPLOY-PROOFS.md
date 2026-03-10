# PH-S03.1B — Preuves post-déploiement seller-dev (matching CSV + wizard)

**Date :** 2026-01-30  
**Référence :** [PH-S03.1-MATCHING-STABILIZATION-REPORT.md](./PH-S03.1-MATCHING-STABILIZATION-REPORT.md)  
**Scope :** Aucune modif code, aucun déploiement hors GitOps, DEV uniquement, aucune donnée sensible (masquer cookies / secrets).

---

## Liens commits (à compléter)

| Commit / tag | Dépôt / chemin | Description |
|--------------|----------------|-------------|
| *(ex. `abc1234`)* | `keybuzz-seller/seller-client` | PH-S03.1 proxy, payload fields, wizard UX, status ready |

*(Renseigner après déploiement sur seller-dev.)*

---

## 1) Scénario complet (READY)

**Parcours :** FTP → browse → select file → detect headers → mapping SKU → create.

**Résultat attendu :** Source créée avec `status = ready`, badge **« Prête »** en liste et en fiche.

**Procédure :**
1. Ouvrir seller-client (seller-dev) → Catalog Sources → « Ajouter une source ».
2. Étape 1 : choisir « Fournisseur ».
3. Étape 2 : choisir « Fichier CSV » (FTP).
4. Étape 3 : renseigner host, port, user, mot de passe (test) → « Tester la connexion » (succès).
5. Étape 4 : « Parcourir » → sélectionner au moins un fichier CSV.
6. Étape 5 : « Détecter les en-têtes » → mapper au moins une colonne vers **SKU** (obligatoire) → continuer.
7. Étape 6 : nom, optionnellement champs produits → « Créer la source ».

**Preuves à fournir :**

| Preuve | Description | Emplacement |
|--------|-------------|-------------|
| **Screenshot 1** | Wizard étape 5 — mapping avec SKU configuré (colonne → SKU) | *Coller ou lier l’image ci-dessous* |
| **Screenshot 2** | Liste des sources — la nouvelle source avec badge « Prête » | *Coller ou lier l’image ci-dessous* |
| **Screenshot 3** | Fiche source (détail) — statut « Prête » | *Coller ou lier l’image ci-dessous* |

```
[Screenshot 1 — Étape 5 mapping SKU]
[Screenshot 2 — Liste avec badge Prête]
[Screenshot 3 — Fiche source Prête]
```

---

## 2) Scénario incomplet (TO_COMPLETE)

**Parcours :** Select file **sans** mapping SKU → create.

**Résultat attendu :** Source créée avec `status = to_complete`, badge **« À compléter »** + guidance UI.

**Procédure :**
1. Nouvelle source → Fournisseur → Fichier CSV.
2. Connexion FTP + test OK.
3. Sélectionner au moins un fichier.
4. Étape 5 : **ne pas** mapper de colonne vers SKU (ou ignorer toutes les colonnes) → continuer.
5. Étape 6 : nom → « Créer la source ».

**Preuves à fournir :**

| Preuve | Description | Emplacement |
|--------|-------------|-------------|
| **Screenshot 4** | Étape 5 — aucun mapping SKU (ou mapping partiel sans SKU) | *Coller ou lier l’image* |
| **Screenshot 5** | Liste des sources — la source avec badge « À compléter » | *Coller ou lier l’image* |

```
[Screenshot 4 — Mapping sans SKU]
[Screenshot 5 — Liste avec badge À compléter]
```

---

## 3) Scénario échec post-création

**Parcours :** Simuler l’échec d’une étape **après** le POST create (ex. PUT /fields bloqué ou erreur).

**Résultat attendu :** Wizard se ferme, fiche source s’ouvre, bandeau « Source créée, configuration incomplète. Complétez la configuration (FTP, mapping) depuis la fiche source. »

**Procédure pour simuler l’échec (sans modifier le code) :**
1. Ouvrir les DevTools (F12) → onglet **Network**.
2. Option A — Bloquer une requête :  
   Clic droit sur une requête future → « Block request URL » (ou utiliser un pattern) pour bloquer `**/catalog-sources/*/fields` (PUT).  
   Puis lancer le wizard complet (avec champs cochés) jusqu’à « Créer la source ». Le POST create réussit, le PUT /fields est bloqué → le catch doit fermer le wizard, ouvrir la fiche et afficher le bandeau.
3. Option B — Throttling / offline :  
   Après avoir cliqué « Créer la source », passer le réseau en « Offline » avant que le PUT /fields ne réponde (timing serré).  
   Ou utiliser « Slow 3G » et annuler la requête PUT /fields dans l’onglet Network.

**Preuves à fournir :**

| Preuve | Description | Emplacement |
|--------|-------------|-------------|
| **Screenshot 6** | Bandeau « Source créée, configuration incomplète… » + fiche source ouverte | *Coller ou lier l’image* |
| **Log UI (masqué)** | Message d’erreur affiché (sans cookies / tokens) — ex. « Failed to load » ou détail 422/500 masqué | *Copier le texte ci-dessous* |

```
Message bandeau (attendu) :
Source créée, configuration incomplète. Complétez la configuration (FTP, mapping) depuis la fiche source.

Erreur console / UI (exemple masqué) :
[Coller ici le message d’erreur avec secrets masqués, ex. "PUT .../fields ... 422" ou "Failed to fetch"]
```

---

## 4) Absence 422 « Field required » sur PUT /fields

**Objectif :** Vérifier qu’après déploiement du client PH-S03.1 (buildFieldsPayload), les appels PUT `/api/catalog-sources/{id}/fields` ne renvoient plus de 422 « Field required ».

**Procédure :**
1. Exécuter les scénarios 1 et/ou 2 en créant une source avec au moins un « champ produit » coché (étape 6).
2. Consulter les logs seller-api (pods seller-dev) sur la période du test.
3. Rechercher : `422`, `Field required`, `field_code`, `field_label`, ou `Unprocessable Entity` sur la route PUT `/catalog-sources/.../fields`.

**Preuve à fournir :**

| Preuve | Description | Emplacement |
|--------|-------------|-------------|
| **Extrait logs (masqué)** | Confirmation qu’aucun 422 « Field required » n’apparaît pour PUT /fields ; ou extrait montrant 200/201 pour PUT /fields (sans secret) | *Coller ci-dessous* |

```
Exemple attendu (succès) :
PUT /api/catalog-sources/<source_id_masqué>/fields 200
(ou 201 selon implémentation)

Recherche effectuée dans les logs :
- "422" sur route fields : 0 occurrence
- "Field required" : 0 occurrence (pour PUT /fields)

[Coller un extrait de log masqué si utile, ex. une ligne de requête sans headers sensibles]
```

---

## Récapitulatif des preuves

| # | Scénario | Preuves |
|---|----------|---------|
| 1 | Complet (READY) | Screenshots 1, 2, 3 |
| 2 | Incomplet (TO_COMPLETE) | Screenshots 4, 5 |
| 3 | Échec post-création | Screenshot 6 + log UI (masqué) |
| 4 | Absence 422 fields | Extrait logs ou compteur 0 |

---

## Confirmation PH-S03.1B

- **Aucun secret exposé** (tous les extraits et screenshots sont masqués ou sans valeur sensible).
- **Aucun SSH modifié** (validation en lecture / exécution UI et consultation logs uniquement).
- **DEV uniquement** (seller-dev ; aucune action PROD).
