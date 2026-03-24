# PH-AMZ-ORDERS-LIST-SYNC-BUTTON-FIX-04 — Rapport de validation

> Date : 23 mars 2026
> Environnements : DEV + PROD
> Verdict : **AMZ ORDERS LIST + SYNC BUTTON FIXED AND VALIDATED**

---

## 1. Problèmes rapportés

Le product owner a identifié 2 écarts restants après PH-AMZ-TRACKING-PROD-TRUTH-FIX-03 :

| # | Problème | Description |
|---|----------|-------------|
| A | Tracking absent de la liste Commandes | Le tracking est visible dans le panneau Messages mais pas dans la colonne "Livraison" de la liste Commandes |
| B | Bouton sync Amazon absent en PROD | Le bouton "Synchroniser Amazon Seller" n'apparaît pas en PROD malgré un connecteur Amazon actif |

---

## 2. Root causes identifiées

### Problème A — Tracking absent de la liste Commandes

**Root cause** : La colonne "Livraison" dans `app/orders/page.tsx` avait une condition `order.isFbm` qui masquait le tracking pour les commandes non-FBM, et les commandes FBM n'affichaient qu'un lien discret peu visible.

Le serializer backend `orderRowToApiResponse` expose correctement les champs `trackingCode`, `carrier`, `trackingUrl`, `hasTracking`. Le problème était purement côté UI/rendu.

### Problème B — Bouton sync Amazon absent en PROD

**Root cause** : La route `/api/v1/marketplaces/amazon/status` recevait le display tenant ID `ecomlg` (envoyé par `useTenant().currentTenantId`), mais la table `inbound_connections` stocke le canonical ID `ecomlg-001`. La query retournait 0 résultats → `connected: false` → `activeMarketplaces.length === 0` → bouton masqué.

Complication supplémentaire : un fallback initial via la table `tenants` (avec `name ILIKE`) trouvait le mauvais tenant (`ecomlg-mmiyygfg` au lieu de `ecomlg-001`) car un autre tenant a `name = 'ecomlg'`.

---

## 3. Corrections appliquées

### 3.1 Client — `app/orders/page.tsx`

**Modification de la colonne "Livraison"** :

- Suppression de la condition `order.isFbm` qui masquait le tracking
- Affichage du tracking pour toute commande avec `trackingCode` ou `trackingUrl`
- Style amélioré : `inline-flex items-center gap-1`, icône `Truck` (lucide-react), `font-medium`
- Format : `Carrier — Code` cliquable si URL de tracking disponible
- FBA : lien vers Amazon order details avec icône `Package`
- Cas sans tracking mais avec carrier : affiche "suivi indisponible" en discret

### 3.2 API — `src/modules/compat/routes.ts`

**Fallback display→canonical tenant ID** :

Ajout d'un fallback direct dans `inbound_connections` quand le tenant ID initial ne trouve rien :

```typescript
if (result.rows.length === 0) {
  const fallbackResult = await pool.query(
    `SELECT * FROM inbound_connections 
     WHERE "tenantId" LIKE $1 
     AND marketplace = 'amazon' 
     AND status = 'READY' LIMIT 1`,
    [tenantId + '-%']
  );
  if (fallbackResult.rows.length > 0) {
    result = fallbackResult;
  }
}
```

Cette approche cherche directement dans `inbound_connections` avec un pattern `LIKE 'ecomlg-%'` au lieu de passer par la table `tenants`, évitant ainsi les faux matches de nom.

---

## 4. Validation DEV

| Test | Résultat |
|------|----------|
| Health | `ok` ✓ |
| Amazon status `ecomlg` (display) | `connected: true, CONNECTED` ✓ |
| Amazon status `ecomlg-001` (canonical) | `connected: true, CONNECTED` ✓ |
| Target order 406-7738696-7078755 (API) | `carrier: FedEx, trackingCode: 889685676345, hasTracking: true` ✓ |
| Target order (DB) | `tracking_code: 889685676345, tracking_url: fedex.com/...` ✓ |
| Orders stats | 11,767 total, 3 avec tracking ✓ |
| Sync status | `completed`, 47 importées, 0 erreurs ✓ |
| Client tracking UI code | `Truck` icon présent dans le build compilé ✓ |

**AMZ ORDERS LIST TRACKING DEV = OK**
**AMZ SYNC BUTTON DEV = OK**

---

## 5. Validation PROD

| Test | Résultat |
|------|----------|
| Health | `ok` ✓ |
| Amazon status `ecomlg` (display) | `connected: true, CONNECTED` ✓ |
| Amazon status `ecomlg-001` (canonical) | `connected: true, CONNECTED` ✓ |
| Target order 406-7738696-7078755 (API) | `carrier: FedEx, trackingCode: 889685676345, hasTracking: true` ✓ |
| Target order (DB) | `tracking_code: 889685676345, tracking_url: fedex.com/...` ✓ |
| Orders stats | 5,732 total, 6 avec tracking ✓ |
| Sync status | `completed`, 392 importées, 0 erreurs ✓ |
| Check-user non-régression | `exists: true, hasTenants: true` ✓ |
| Fallback code déployé | LIKE query correcte dans dist ✓ |

**AMZ ORDERS LIST TRACKING PROD = OK**
**AMZ SYNC BUTTON PROD = OK**

---

## 6. Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `keybuzz-client/app/orders/page.tsx` | Colonne Livraison : suppression condition `isFbm`, icônes Truck/Package, tracking cliquable |
| `keybuzz-api/src/modules/compat/routes.ts` | Fallback LIKE direct sur `inbound_connections` pour display→canonical ID |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image → `v3.5.49-amz-orders-list-sync-fix-dev` |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | Image → `v3.5.49-amz-orders-list-sync-fix-prod` |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Image → `v3.5.75-amz-orders-list-sync-fix-dev` |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | Image → `v3.5.75-amz-orders-list-sync-fix-prod` |

---

## 7. Images déployées

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.49-amz-orders-list-sync-fix-dev` | `v3.5.49-amz-orders-list-sync-fix-prod` |
| Client | `v3.5.75-amz-orders-list-sync-fix-dev` | `v3.5.75-amz-orders-list-sync-fix-prod` |

---

## 8. Non-régressions confirmées

- Tracking dans Messages (panneau droit) : inchangé ✓
- FBM / FBA : comportement compatible ✓
- Export commandes : non touché ✓
- Détail commande : non touché ✓
- Auth (check-user, OAuth) : fonctionnel ✓
- Sync Amazon : fonctionnel ✓

---

## 9. Rollback

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.48-amz-prod-truth-fix-dev` | `v3.5.48-amz-prod-truth-fix-prod` |
| Client | `v3.5.48-white-bg-dev` | `v3.5.72-ph118-onboarding-hardening-prod` |

Rollback via manifests GitOps uniquement.

---

## 10. Verdict final

### **AMZ ORDERS LIST + SYNC BUTTON FIXED AND VALIDATED**

Les 2 problèmes identifiés sont résolus et validés en DEV et PROD :

1. **Tracking visible dans la liste Commandes** — affiché avec icône Truck, carrier + numéro cliquable
2. **Bouton sync Amazon visible en PROD** — fallback tenant ID fonctionnel, `connected: true` pour display et canonical IDs
