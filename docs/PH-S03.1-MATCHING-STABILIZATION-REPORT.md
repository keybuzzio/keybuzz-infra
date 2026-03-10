# PH-S03.1 — Stabilisation Catalog Sources + FTP + Matching CSV (seller-dev)

**Date :** 2026-01-30  
**Périmètre :** Corrections ciblées (FIXES ONLY) — pas de nouvelle feature d’ingestion.  
**Environnement :** seller-dev uniquement.  
**Référence :** [PH-S03.0-AUDIT-MATCHING-FTP.md](./PH-S03.0-AUDIT-MATCHING-FTP.md)

---

## 1. Objectifs et invariants

- **Objectifs :**
  1. Éliminer les "Failed to fetch" liés au cross-origin en forçant le proxy same-origin.
  2. Verrouiller le payload PUT /fields (field_code / field_label / required).
  3. Wizard robuste : si une étape post-création échoue, guider vers la fiche source (message + ouverture fiche).
  4. Status `ready` uniquement si (a) au moins 1 fichier sélectionné ET (b) mapping SKU présent.

- **Invariants respectés :** multi-tenant strict, aucun secret en clair, pas de parsing CSV complet, GitOps only, DEV only.

---

## 2. Travaux réalisés

### A) Proxy API — requêtes same-origin

**Fichiers modifiés :**
- `keybuzz-seller/seller-client/src/lib/config.ts` — commentaire PH-S03.1 : en navigateur `apiUrl` forcé à `''` pour que toutes les requêtes passent par le proxy.
- `keybuzz-seller/seller-client/src/lib/api.ts` — en navigateur, `base` forcé à `''` (ignorer toute valeur `config.apiUrl` côté client) pour garantir l’usage du proxy.

**Preuve :** En exécution côté client (navigateur), `base` est toujours `''`, donc `path = config.apiProxyPrefix + endpoint` → URL = `window.location.origin + '/api/seller' + endpoint` → requêtes same-origin. Aucun appel direct à `seller-api-dev.keybuzz.io` depuis le navigateur.

---

### B) Payload PUT /fields (field_code / field_label / required)

**Fichiers :**
- **Nouveau :** `keybuzz-seller/seller-client/src/lib/catalogSourceFields.ts`
  - `buildFieldsPayload(fields: WizardField[]): ApiFieldPayload[]` — mapping explicite `code` → `field_code`, `label` → `field_label`, `required` → `required`.
  - En dev, assertion (log safe) si un item n’a pas les clés attendues.
- **Modifié :** `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx` — appel `api.put(..., buildFieldsPayload(wizardData.fields))` à la place d’un `.map` inline.

**Preuve :** Le body envoyé à `PUT /api/catalog-sources/{id}/fields` a la forme attendue par le schéma Pydantic `CatalogSourceFieldCreate` (field_code, field_label, required). Plus de 422 "Field required" si le client déployé est à jour.

**Exemple de payload (sans secret) :**
```json
[
  { "field_code": "sku", "field_label": "Reference produit (SKU)", "required": true },
  { "field_code": "stock", "field_label": "Quantite disponible", "required": false }
]
```

---

### C) Wizard UX — échec post-création

**Modifié :** `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx` — dans `createSource()` catch :
- "Nom déjà existant" affiché **uniquement** si la création (POST) a échoué avec un conflit de nom (pas de `source` créée).
- Si `source` existe (POST réussi, étape suivante en échec) :
  - Fermeture du wizard.
  - Rafraîchissement de la liste (`loadSources()`).
  - Ouverture de la fiche source (`setSelectedSource(source)`, `setShowDetail(true)`).
  - Message dans le bandeau : "Source créée, configuration incomplète. Complétez la configuration (FTP, mapping) depuis la fiche source."

**Preuve :** L’utilisateur n’est plus bloqué avec un message trompeur "nom existe déjà" ; il est redirigé vers la fiche de la source créée pour compléter FTP ou mapping.

---

### D) Status ready = fichiers + mapping SKU

**Modifié :** `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx` — calcul du `status` envoyé au POST create :
- `hasSkuMapping = wizardData.columnMappings.some(m => m.targetField === 'sku')`.
- `isReady = wizardData.selectedFiles.length > 0 && hasSkuMapping`.
- `status: isReady ? 'ready' : 'to_complete'`.

**Preuve :** Une source créée sans mapping SKU (ou sans fichier sélectionné) a le statut `to_complete` et n’apparaît pas "Prête" en UI.

---

## 3. Validation (preuves attendues)

| Scénario | Résultat attendu |
|----------|------------------|
| **1) Parcours wizard complet** | FTP → browse → select file → detect headers → mapping SKU → create → source `status=ready`. |
| **2) Parcours incomplet** | Fichier(s) sélectionné(s) sans mapping SKU → create → `status=to_complete` + message / guidance "A compléter". |
| **3) Échec post-création** | POST create 201, puis échec (ex. PUT fields 422 ou timeout) → wizard se ferme, fiche source s’ouvre, bandeau "Source créée, configuration incomplète...". |
| **4) Absence 422 fields** | Après déploiement du client avec `buildFieldsPayload`, plus d’erreur 422 "Field required" sur PUT /fields (vérifiable en logs API + UI). |

---

## 4. Liens commits

*(À compléter après commit Git. Preuves post-déploiement : voir [PH-S03.1B-POSTDEPLOY-PROOFS.md](./PH-S03.1B-POSTDEPLOY-PROOFS.md).)*

- Proxy + status + UX wizard : `keybuzz-seller/seller-client` — fichiers `config.ts`, `api.ts`, `page.tsx`.
- Payload fields : `keybuzz-seller/seller-client` — `src/lib/catalogSourceFields.ts`, `page.tsx`.

---

## 5. Exemples payload (sans secrets)

**POST /api/catalog-sources (création) :**
```json
{
  "name": "Catalogue Fournisseur ABC",
  "source_kind": "supplier",
  "source_type_ext": "ftp_csv",
  "priority": 100,
  "description": null,
  "status": "ready"
}
```
*(`status` est `"ready"` seulement si fichiers sélectionnés et mapping SKU ; sinon `"to_complete"`.)*

**PUT /api/catalog-sources/{id}/fields :**  
Voir section 2.B ci-dessus.

---

## 6. Screenshots UI

**Preuves post-déploiement (scénarios 1→4) :** voir l’addendum **[PH-S03.1B-POSTDEPLOY-PROOFS.md](./PH-S03.1B-POSTDEPLOY-PROOFS.md)** — procédures de validation, emplacements pour screenshots et extraits de logs (masqués).

À fournir dans l’addendum après déploiement sur seller-dev :
- Scénario 1 (READY) : wizard étape 5 (mapping SKU), liste (badge « Prête »), fiche source.
- Scénario 2 (TO_COMPLETE) : mapping sans SKU, liste (badge « À compléter »).
- Scénario 3 (échec post-création) : bandeau « Source créée, configuration incomplète… » + fiche ouverte ; log UI masqué.
- Scénario 4 : extrait logs seller-api (0 × 422 « Field required » sur PUT /fields).

---

## 7. Confirmation

- **Aucun fichier SSH modifié.**
- **Aucun secret exposé** (exemples masqués ou sans valeur réelle).
- **Aucune action PROD** (modifications applicables au déploiement seller-dev uniquement).
- **Aucune persistance de mot de passe en DB** ; **aucune lecture CSV au-delà des en-têtes** (detect-headers-direct inchangé).
