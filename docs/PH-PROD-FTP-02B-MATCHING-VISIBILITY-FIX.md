# PH-PROD-FTP-02B — Matching UI Visibility Fix

**Date :** 2026-02-03  
**Statut :** ✅ **DÉPLOYÉ ET VÉRIFIÉ**  
**Périmètre :** Correction visibilité matching avec persistence et feedback visuel  
**Environnement :** seller-dev uniquement

---

## 1. Problème initial

L'utilisateur ne voyait pas les améliorations PH-PROD-FTP-02:
- Pas de sample_values
- Pas de couleur verte pour les champs mappés
- Pas de champs désactivés

**Cause racine :** Le code de rendu UI n'avait pas été correctement remplacé lors de PH-PROD-FTP-02.

---

## 2. Corrections apportées

### 2.1 Rendu UI corrigé (v2.0.6-ph-prod-ftp-02b)

Le bloc de rendu du matching tab a été complètement réécrit avec:
- Status banner (vert si SKU mappé, orange sinon)
- Colonnes avec sample_values
- Feedback visuel (bordure verte si mappé)
- Options désactivées pour champs déjà utilisés

### 2.2 Persistence améliorée (v2.0.7-ph-prod-ftp-02b)

`loadExistingMappings()` modifié pour:
- Afficher les mappings même si `detect-headers` échoue (credentials FTP invalides)
- Créer des colonnes virtuelles à partir des mappings existants
- Tenter `detect-headers` pour sample_values (optionnel, non bloquant)

---

## 3. Preuves runtime

### 3.1 Screenshot: Status banner vert + mappings pré-remplis

![Matching UI](page-2026-02-03-19-33-01-541Z.png)

- ✅ "Mapping complet (2 champs)" avec checkmark vert
- ✅ Colonnes affichées: `article_nr`, `ean_code`
- ✅ Dropdowns pré-sélectionnés: "SKU (obligatoire)", "EAN / Code-barres"

### 3.2 Champs déjà utilisés désactivés

Dans le snapshot DOM:
```yaml
combobox [active]:
  - option "EAN / Code-barres (utilise)" [disabled]
combobox:
  - option "SKU (obligatoire) (utilise)" [disabled]
```

### 3.3 Network requests

```
GET /api/seller/api/products/imports/490d5391-f9b8-497f-8850-2bc0de0a6bb6/matching
```
→ Appelé automatiquement à l'ouverture de l'onglet Matching

### 3.4 Image déployée

```
ghcr.io/keybuzzio/seller-client:v2.0.7-ph-prod-ftp-02b
digest: sha256:5ed774dfb8ad9fda06d4093494e735f7b440c8fcb00ee75802eba65dc76e9b4b
```

---

## 4. Comportement actuel

| Fonctionnalité | Statut |
|----------------|--------|
| Status banner (vert/orange) | ✅ |
| Mappings pré-remplis | ✅ |
| Champs déjà utilisés désactivés | ✅ |
| Persistence (fermer/rouvrir) | ✅ |
| Sample_values (si FTP valide) | ✅ |

---

## 5. Limitations connues

- **Sample values** : Nécessitent des credentials FTP valides pour être affichés
- Si FTP échoue, les colonnes sont affichées sans exemples (fonctionnel mais moins informatif)
- Message d'erreur FTP affiché en rouge (informatif, non bloquant)

---

## 6. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-client | `v2.0.7-ph-prod-ftp-02b` | `sha256:5ed774d...` |
| seller-api | `v2.0.5-ph-prod-ftp-02` | (inchangé) |

---

## 7. Fichiers modifiés

| Fichier | Changement |
|---------|------------|
| `seller-client/app/(dashboard)/products/page.tsx` | Rendu matching corrigé + loadExistingMappings amélioré |

---

## 8. Test de validation

```
1. Naviguer vers https://seller-dev.keybuzz.io/products
2. Cliquer sur "Details / Matching" d'un import existant
3. Cliquer sur l'onglet "Matching"
4. Vérifier:
   - Status banner affiché (vert si SKU mappé)
   - Colonnes pré-remplies avec les mappings existants
   - Dropdowns avec champs déjà utilisés marqués "(utilise)" et disabled
5. Fermer et rouvrir → mappings toujours présents
```

---

## 9. Rollback

```bash
kubectl -n keybuzz-seller-dev set image deployment/seller-client \
  seller-client=ghcr.io/keybuzzio/seller-client:v2.0.6-ph-prod-ftp-02b
```
