# PH-AMZ-UI-STATE-TRUTH-01 — RAPPORT

> Date : 2026-03-27
> Auteur : Agent Cursor
> Type : correction UI — etat reel connecteur Amazon

---

## 1. PROBLEME

Le bouton "Synchroniser Amazon" apparaissait sur la page Commandes pour des tenants sans connecteur Amazon reellement actif (ex: SRV Performance), donnant l'impression fausse qu'une synchronisation est possible.

---

## 2. SOURCE UI

### Composant
`app/orders/page.tsx` — fonction `detectMarketplaces` dans un `useEffect`.

### Logique precedente
```
1. Pour chaque marketplace (Amazon, Octopia) :
   - Appel GET /api/amazon/status?tenant_id=...
   - connected = !!data.connected
2. Si connected === true → bouton sync VISIBLE
```

### Source de verite utilisee
Le backend `/api/v1/marketplaces/amazon/status` (compat routes) determine `connected` via :
```javascript
isReallyConnected = has_messages || has_oauth || has_legacy_active
```

### Probleme
`has_messages` est `true` si `inbound_addresses.lastInboundAt IS NOT NULL`.
SRV Performance avait recu des messages inbound → `has_messages = true` → `connected = true` → bouton visible.

---

## 3. CRITERES REELS

Le bouton doit apparaitre **uniquement si** le tenant a au moins un `tenant_channels` avec `status = 'active'` pour ce provider.

| Tenant | Channels Amazon actifs | Bouton attendu |
|---|---|---|
| eComLG (ecomlg-001) | 3 (FR, ES, IT) | VISIBLE |
| SRV Performance | 0 (tous removed) | CACHE |
| Test tenants | 0 (pending) | CACHE |

---

## 4. CORRECTION

### Fichier modifie
`app/orders/page.tsx` — fonction `detectMarketplaces`

### Logique ajoutee
Avant la detection des marketplaces, un appel additionnel a `/api/channels/list?tenantId=...` recupere les channels reels du tenant. Seuls les providers ayant au moins un channel `status = 'active'` sont consideres comme connectes.

```
1. GET /api/channels/list?tenantId=... → liste des tenant_channels
2. Construire un Set des providers avec status === 'active'
3. Pour chaque marketplace status check :
   connected = !!data.connected && activeProviders.has(config.id)
```

### Diff
- Ajout de 10 lignes pour le fetch channels et le cross-check
- Modification d'une seule condition (`connected` ajoute `&& hasActiveChannel`)
- Aucune modification backend

---

## 5. VALIDATION DEV

### Verification donnees
| Tenant | /channels count | active | Bouton sync |
|---|---|---|---|
| SRV Performance | 0 | 0 | CACHE |
| eComLG | 4 | 3 (FR/ES/IT) | VISIBLE |

### Cas 1 — SRV Performance sans OAuth
- 0 channels actifs Amazon
- `/channels` API retourne `total: 0`
- `activeProviders.has('amazon')` = `false`
- Bouton sync = **NON VISIBLE** ✅

### Cas 2 — eComLG avec Amazon
- 3 channels actifs Amazon (FR, ES, IT)
- `/channels` API retourne `total: 4, active: 3`
- `activeProviders.has('amazon')` = `true`
- Bouton sync = **VISIBLE** ✅

---

## 6. DEPLOIEMENT

| Env | Image | Tag |
|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-client` | `v3.5.122-ph-amz-ui-state-dev` |

GitOps : `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` mis a jour.

---

## 7. ROLLBACK

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.121-ph-autopilot-ui-feedback-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## VERDICT

# AMZ UI STATE FIXED
