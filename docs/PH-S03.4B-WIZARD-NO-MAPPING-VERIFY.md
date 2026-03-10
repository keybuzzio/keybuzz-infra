# PH-S03.4B — Wizard FTP : vérifier absence étape « Mapping » + onglet « Colonnes (CSV) » (DEV only)

**Date :** 2026-01-30  
**Périmètre :** Confirmer que le wizard ne contient plus l’étape « Mapping des colonnes » et que l’onglet « Colonnes (CSV) » existe et fonctionne sur la fiche source.  
**Environnement :** seller-dev uniquement.

**Règles :** DEV only, GitOps only, pas de refactor, zéro action manuelle Ludovic.

---

## 1. Contexte et objectifs

- **Demande produit :** Le wizard doit rester simple (connexion FTP + sélection fichier + enregistrer). Le mapping se fait **après** création, depuis la fiche source (onglet « Colonnes (CSV) »).
- **Constat :** Un screenshot peut encore montrer l’étape « Mapping des colonnes » dans le wizard → drift ou déploiement non effectif.
- **Objectifs :**
  1. Faire disparaître l’étape « Mapping des colonnes » du wizard (déjà fait en PH-S03.4).
  2. S’assurer que l’onglet « Colonnes (CSV) » existe sur la fiche source et fonctionne (détection en-têtes + bulk mapping).
  3. Preuve par screenshots sur seller-dev.

---

## 2. État du code (déjà en place — PH-S03.4)

### Wizard : pas d’étape Mapping

- **Fichier :** `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx`
- **totalSteps avec FTP :** **5** (et non 6).
- **Étapes avec FTP :**
  1. D’où viennent vos produits ?
  2. Type de source
  3. Connexion au serveur
  4. Sélection des fichiers
  5. **Finalisation** (nom, description, priorité, champs, bouton Créer)
- **Supprimé du wizard :** L’étape « Mapping des colonnes » (détection en-têtes + mapping colonne → champ) ; plus d’appel à `detect-headers-direct` ni à `column-mappings/bulk` dans le wizard.
- **getStepTitle :** étape 5 = « Finalisation » (pas « Mapping des colonnes »).
- **Contenu Finalisation :** affiché pour `(needsFtp && step === 5) || (!needsFtp && step === 3)`.

### Fiche source : onglet « Colonnes (CSV) »

- **DetailModal** a des onglets : **Infos** | **Connexion FTP** | **Colonnes (CSV)** (si type FTP/CSV).
- **Onglet « Colonnes (CSV) » :** composant `SourceColumnMappingTab` avec :
  - liste des fichiers sélectionnés (GET `/api/catalog-sources/{id}/ftp/files`) ;
  - choix du fichier pour la détection ;
  - bouton « Détecter les colonnes » → POST `/api/catalog-sources/{id}/column-mappings/detect-headers` ;
  - tableau mapping colonne → champ produit (SKU obligatoire) ;
  - bouton « Enregistrer le mapping » → POST `/api/catalog-sources/{id}/column-mappings/bulk`.

---

## 3. Identifier la version déployée

- **ArgoCD :** révision + image tag pour `keybuzz-seller-dev` (seller-client).
- **Vérifier** que le build déployé contient les changements PH-S03.4 (wizard 5 étapes, onglet Colonnes (CSV), pas d’étape Mapping).
- Si le screenshot montre encore 6 étapes ou « Mapping des colonnes », la version déployée est **antérieure** à PH-S03.4 → déployer la version à jour via GitOps (build + push image, sync ArgoCD).

---

## 4. Preuves par screenshots (seller-dev)

1. **Wizard sans étape Mapping :**
   - Ouvrir Catalog Sources → « Ajouter une source ».
   - Choisir type FTP (ex. Fichier CSV).
   - Parcourir les étapes : **5 étapes** au total, dernière = « Finalisation » (nom, description, priorité, champs, bouton Créer).
   - **Aucune** étape « Mapping des colonnes » ni « Associez les colonnes… ».

2. **Onglet « Colonnes (CSV) » sur la fiche source :**
   - Ouvrir une source existante (type FTP/CSV).
   - Vérifier les onglets : **Infos** | **Connexion FTP** | **Colonnes (CSV)**.
   - Onglet « Colonnes (CSV) » : fichier pour détection, bouton « Détecter les colonnes », tableau mapping, bouton « Enregistrer le mapping ».

3. **Fonctionnement :**
   - Détecter les colonnes → en-têtes affichés.
   - Mapper au moins la colonne SKU → « Enregistrer le mapping » → succès (liste des mappings ou message OK).

---

## 5. Récapitulatif

| Élément | Attendu | Vérification |
|--------|---------|--------------|
| Wizard avec FTP | 5 étapes (origine, type, connexion, fichiers, finalisation) | Screenshot |
| Pas d’étape « Mapping des colonnes » | Aucune étape mapping dans le wizard | Screenshot |
| Onglet « Colonnes (CSV) » | Présent sur la fiche source (type FTP/CSV) | Screenshot |
| Détection + bulk mapping | Détecter les colonnes + Enregistrer le mapping fonctionnent | Screenshot / test |

**Statut :** Code PH-S03.4 déjà en place. Si l’UI montre encore l’ancien wizard (6 étapes / Mapping), vérifier la version déployée et déployer la version à jour. Preuves par screenshots à collecter sur seller-dev après déploiement.
