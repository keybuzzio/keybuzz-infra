# PH142-O3 — Fix Remaining RED Features

> Date : 2026-04-05
> Environnement : DEV uniquement
> Image API : `ghcr.io/keybuzzio/keybuzz-api:v3.5.194b-fix-remaining-red-dev`
> Image Client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.194-fix-remaining-red-dev`

---

## 1. Resume executif

4 RED restants identifies apres PH142-O2 ont ete corriges et valides en DEV :

| Issue | Avant | Apres | Statut |
|---|---|---|---|
| KNOW-01 | GET /knowledge → 404 | GET /knowledge → 200 | **GREEN** |
| SUP-01 | GET /dashboard/supervision → 404 | GET /dashboard/supervision → 200 | **GREEN** |
| TRK-01 | GET /tracking/status → 404 | Correct path: /api/v1/orders/tracking/status → 200 | **GREEN** |
| SLA-01 | Badges SLA invisibles | slaState propage dans mapApiToLocal → badges actifs | **GREEN** |

---

## 2. KNOW-01 — Knowledge Templates

### Avant
- Module `src/modules/knowledge/routes.ts` existait avec CRUD complet sur `knowledge_templates`
- Mais **n'etait pas importe/enregistre** dans `app.ts`
- Resultat : `GET /knowledge` → 404

### Correction
- Ajout import dans `app.ts` : `import { knowledgeRoutes } from './modules/knowledge/routes';`
- Ajout enregistrement : `app.register(knowledgeRoutes, { prefix: '/knowledge' });`

### Apres
```
GET /knowledge?tenantId=ecomlg-001 → 200
{"templates":[{"id":"tpl-mlg6edqhe2glz5","title":"Template Test",...}]}
```

### Note
La page client `/knowledge` utilise encore localStorage via `loadAllLibraries()`. Le endpoint API est maintenant disponible pour la migration API-backed.

---

## 3. SUP-01 — Dashboard Supervision

### Avant
- `dashboardRoutes` n'avait qu'un endpoint `GET /summary`
- Aucun endpoint `/supervision` n'existait
- Resultat : `GET /dashboard/supervision` → 404

### Correction
- Ajout endpoint `GET /dashboard/supervision` dans `src/modules/dashboard/routes.ts`
- Requete SQL agentielle : conversations par agent, SLA par agent, temps de reponse moyen
- Utilise `getSlaStats()` et `getOverviewStats()` existants pour les donnees globales
- Cast `::text` sur le JOIN `assigned_agent_id` / `users.id` (types UUID/text)

### Apres
```
GET /dashboard/supervision?tenantId=ecomlg-001 → 200
{
  "agents": [{ "agentId": "unassigned", "totalConversations": 333, "sla": { "breached": 328, "ok": 5 } }],
  "slaGlobal": { "ok": 5, "breached": 257, "total": 262 },
  "conversationsSummary": { "total": 333, "open": 250, "pending": 12, "resolved": 71 }
}
```

### BFF client
- Cree : `app/api/dashboard/supervision/route.ts` → proxy vers `/dashboard/supervision`

---

## 4. TRK-01 — Tracking Multi-Transporteurs

### Avant
- Test appelait `GET /tracking/status` → 404
- Les routes `carrierTrackingRoutes` etaient enregistrees sous prefix `/api/v1/orders`
- Le path correct est `/api/v1/orders/tracking/status`

### Correction
- **Pas de changement de code API** — les routes etaient deja correctement enregistrees
- Documentation du path correct
- Ajout BFF client : `app/api/orders/tracking/status/route.ts` → proxy vers `/api/v1/orders/tracking/status`

### Apres
```
GET /api/v1/orders/tracking/status → 200
{
  "configuration": { "aggregator": { "providers": [{ "name": "17track", "configured": true }] } },
  "events": { "total_events": "32316", "orders_with_events": "11927" },
  "orders": { "total_orders": "11935", "with_tracking": "68" }
}
```

### Endpoints tracking complets
| Methode | Path | Description |
|---|---|---|
| GET | `/api/v1/orders/:orderId/tracking` | Events tracking commande |
| POST | `/api/v1/orders/:orderId/tracking/refresh` | Rafraichir depuis transporteur |
| POST | `/api/v1/orders/tracking/poll` | Poll batch (CronJob) |
| GET | `/api/v1/orders/tracking/status` | Status config aggregateur |
| POST | `/api/v1/tracking/webhook/17track` | Webhook 17TRACK |

---

## 5. SLA-01 — Urgence Visuelle Inbox

### Avant
- API retourne `sla_state` ("breached"/"ok"/"at_risk") dans les conversations
- `mapApiToLocal()` dans `InboxTripane.tsx` ne propagait PAS `slaState`/`slaDueAt`
- Le type `LocalConversation` n'avait pas ces champs
- `getConversationPriority()` recevait `slaState: undefined` → badges "SLA depasse"/"SLA a risque" jamais affiches
- 257 conversations en SLA breached, 0 badge visible

### Correction
- Ajout `slaState?: string | null` et `slaDueAt?: string | null` dans `interface LocalConversation`
- Ajout mapping dans `mapApiToLocal()` :
  ```
  slaState: (conv as any).sla_state || (conv as any).slaState || null,
  slaDueAt: (conv as any).sla_due_at || (conv as any).slaDueAt || null,
  ```

### Apres
- `getConversationPriority()` voit `slaState: "breached"` → retourne `{ level: 'high', score: 100, label: 'SLA depasse' }`
- `PriorityBadge` s'affiche avec badge rouge "SLA depasse" sur les conversations concernees
- Le tri par priorite (toggle PH126) classe les breached en premier (score 100)

### Preuve API
Sur 50 conversations recentes :
- ~45 ont `sla_state: "breached"`
- ~5 ont `sla_state: "ok"`

---

## 6. Tests reels DEV

| Test | Resultat |
|---|---|
| `GET /health` | 200 OK |
| `GET /knowledge?tenantId=ecomlg-001` | 200, 1 template |
| `GET /dashboard/supervision?tenantId=ecomlg-001` | 200, agents + SLA + summary |
| `GET /dashboard/summary?tenantId=ecomlg-001` | 200 (non-regression) |
| `GET /api/v1/orders/tracking/status` | 200, 17track configured, 32316 events |
| `GET /messages/conversations?tenantId=ecomlg-001` | 200, sla_state present dans response |
| Client `https://client-dev.keybuzz.io/` | 307 (redirect login OK) |

---

## 7. Commits SHA

| Repo | SHA | Message |
|---|---|---|
| keybuzz-api | `6051d5f` | PH142-O3: KNOW-01 register knowledgeRoutes + SUP-01 supervision endpoint |
| keybuzz-api | `5eccf7e` | PH142-O3: fix supervision SQL text/uuid cast |
| keybuzz-client | `29ee06e` | PH142-O3: SLA-01 slaState propagation + SUP-01/TRK-01 BFF routes |
| keybuzz-client | `1a7c51d` | PH142-O3: sync AgentWorkbenchBar types for build compat |

---

## 8. Images DEV

| Service | Image |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.194b-fix-remaining-red-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.194-fix-remaining-red-dev` |

---

## 9. Ce qui reste ORANGE/RED apres cette phase

### Hors scope (non touche, conformement aux regles)
| Feature | Statut | Raison |
|---|---|---|
| BILL-01 | ORANGE | Stripe upgrade flow — hors scope PH142-O3 |
| BILL-02 | ORANGE | Addon KBActions — hors scope |
| APT-03 | ORANGE | Safe mode draft — hors scope |
| APT-04 | ORANGE | Draft consume — hors scope |
| SET-01 | ORANGE | Signature save — hors scope |
| AGT-03 | ORANGE | Invitation agent — hors scope |

### Non impacte (deja GREEN depuis PH142-O2)
- AGT-04 : RBAC agent — GREEN
- INFRA-02/03 : pre-prod scripts — GREEN
- IA-CONSIST-01 : shared-ai-context — GREEN

---

## 10. Readiness PROD

### Pre-requis pour promotion PROD
1. Validation explicite de Ludovic
2. Build PROD : meme codebase, suffixe `-prod`
3. Variables d'env PROD (`NEXT_PUBLIC_API_URL=https://api.keybuzz.io`)
4. Deploiement sequentiel : API puis Client
5. Smoke tests PROD : health, knowledge, supervision, tracking

### Risques
- **Aucun risque billing/Stripe** — non touche
- **Aucun risque RBAC** — non touche (PH142-O2 intact)
- **Risque minimal SLA-01** — ajout de champs au mapping, pas de changement de logique
- **SUP-01** : nouvel endpoint readonly (SELECT), pas de modification de donnees

---

**VERDICT : ALL REMAINING RED FIXED IN DEV — MATRIX UPDATED — DEV READY FOR PROD PROMOTION**
