# PH131-C-PROD-PROMOTION-01 — Rapport

**Phase** : PH131-C-PROD-PROMOTION-01
**Date** : 2026-03-26
**Type** : Promotion contrôlée PROD — aucun changement fonctionnel
**Verdict** : **PH131-C PROD PROMOTED SAFELY**

---

## 1. Vérification source de vérité

| Élément | Statut |
|---|---|
| API Git clean (branch main, HEAD `574f32f`) | ✅ |
| Client Git clean (branch main, HEAD `364222e`) | ✅ |
| Infra Git clean (branch main, HEAD `0d9dc4f`) | ✅ |
| API commits PH131-C pushés (`574f32f`, `a0623c6`, `8849e45`) | ✅ |
| Client commits PH131-C pushés (`364222e`, `91533fd`) | ✅ |
| `engine.ts` + `routes.ts` + inbound hooks présents | ✅ |
| BFF evaluate + history routes présentes | ✅ |
| Badge autopilot types + MessageSourceBadge présents | ✅ |
| Aucun diff bastion non commité | ✅ |

**PH131-C SOURCE OF TRUTH = OK**

---

## 2. Images exactes promues

| Service | Tag DEV (source) | Tag PROD (cible) |
|---|---|---|
| API | `v3.5.107b-ph131-autopilot-engine-dev` | `v3.5.107b-ph131-autopilot-engine-prod` |
| Client | `v3.5.107-ph131-autopilot-engine-dev` | `v3.5.107-ph131-autopilot-engine-prod` |

**Build** : `docker build --no-cache` depuis le même code source, avec variables d'env PROD.

---

## 3. Commits exacts

### API (`keybuzz-api`, branch `main`)

| Commit | Description |
|---|---|
| `574f32f` | PH131-C: fix ai_action_log schema — use correct columns |
| `a0623c6` | PH131-C: fix compilation — chatCompletion signature, routes scope, inbound hooks |
| `8849e45` | PH131-C: autopilot engine — safe controlled execution with inbound trigger |

### Client (`keybuzz-client`, branch `main`)

| Commit | Description |
|---|---|
| `364222e` | PH131-C: autopilot badge + BFF evaluate/history routes |
| `91533fd` | PH131-C: autopilot badge + BFF evaluate/history routes |

---

## 4. Preflight DEV (avant promotion)

| Check | Résultat |
|---|---|
| PRO blocked (PLAN_INSUFFICIENT:PRO) | **PASS** |
| Settings accessible (200) | **PASS** |
| History accessible (200, total=0) | **PASS** |
| Conversations (200) | **PASS** |
| Agents (200) | **PASS** |
| AI Settings (200) | **PASS** |
| Billing (200) | **PASS** |
| Auth (200) | **PASS** |
| Health (200) | **PASS** |

**9/9 PASS**

---

## 5. Validations techniques PROD

| Check | Résultat |
|---|---|
| T1 - Health | **PASS** (200) |
| T2 - Autopilot settings | **PASS** (200) |
| T3 - Autopilot history | **PASS** (200) |
| T4 - Agents | **PASS** (200) |
| T5 - Inbox/conversations | **PASS** (200) |
| T6 - Auth | **PASS** (200) |
| T7 - Billing | **PASS** (200) |
| T8 - AI Settings | **PASS** (200) |
| Pod restarts | **0** |

**8/8 PASS, 0 restarts**

---

## 6. Validations métier PROD

| Check | Résultat | Détail |
|---|---|---|
| M1 - Moteur bloqué | **PASS** | `DISABLED` (settings off, executed=false, KBA=0) |
| M2 - Settings cohérents | **PASS** | mode=off, enabled=false, safe_mode=true |
| M3 - 0 actions auto | **PASS** | total=0 |
| M4 - Conversations intactes | **PASS** | count=50 |
| M5 - Agents intacts | **PASS** | count=1 |

**5/5 PASS**

**Note** : M1 retourne `DISABLED` au lieu de `PLAN_INSUFFICIENT:PRO` car les settings PROD sont à `enabled=false, mode=off` (valeurs par défaut). C'est plus sécurisé — le moteur bloque AVANT même de vérifier le plan.

---

## 7. Non-régressions

| Module | Statut |
|---|---|
| Inbox (conversations) | ✅ Intact (50 conversations) |
| Auth (tenant-context/me) | ✅ 200 |
| Billing (current) | ✅ 200 |
| Agents | ✅ Intact (1 agent) |
| AI Settings | ✅ 200 |
| Autopilot settings PH131-B | ✅ Intact |
| KBActions | ✅ Aucun débit (0) |
| DEV inchangé | ✅ Images DEV non touchées |

---

## 8. Rollback

En cas de problème, rollback immédiat vers les images précédentes :

| Service | Tag rollback |
|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.104-ph131-autopilot-settings-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.106-ph131-starter-upsell-prod` |

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.104-ph131-autopilot-settings-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.106-ph131-starter-upsell-prod -n keybuzz-client-prod
```

---

## 9. Images déployées (état final)

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.107b-ph131-autopilot-engine-dev` | `v3.5.107b-ph131-autopilot-engine-prod` |
| Client | `v3.5.107-ph131-autopilot-engine-dev` | `v3.5.107-ph131-autopilot-engine-prod` |

---

## Verdict final

# PH131-C PROD PROMOTED SAFELY
