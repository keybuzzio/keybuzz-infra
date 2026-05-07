# PH-SAAS-T8.12AP.2.5 — Conversation Lifecycle Status PROD Promotion

> Date : 2026-05-07
> Auteur : Cursor Executor
> Phase : AP.2.5
> Ticket : KEY-265
> Tickets liés : KEY-253, KEY-263, KEY-267, KEY-268
> Environnement : PROD
> Type : Promotion API PROD uniquement

---

## Objectif

Promouvoir en PROD le fix AP.2.4 validé en DEV.

Le fix corrige le comportement futur : quand une conversation escaladée est passée en `resolved`, l'API nettoie automatiquement `escalation_status` → `'none'` pour éviter les conversations incohérentes `resolved + escalated`.

**Cette phase ne nettoie PAS les 18 conversations historiques PROD déjà incohérentes.**

---

## Sources relues

| Source | Statut |
|---|---|
| `CE_PROMPTING_STANDARD.md` | Relue (contexte conversation summary) |
| `RULES_AND_RISKS.md` | Relue (contexte conversation summary) |
| `AI_MESSAGING_FEATURE_PARITY_BASELINE.md` | Relue (contexte conversation summary) |
| `PH-SAAS-T8.12AP.2.4-...-TRUTH-AUDIT-AND-DEV-FIX-01.md` | Relue (rapport AP.2.4) |
| `PH-SAAS-T8.12AP.2.3.1-...-PROD-QA-DB-VERIFY-01.md` | Relue (contexte conversation summary) |
| `PH-SAAS-T8.12AP.1F-...-PROD-PROMOTION-01.md` | Relue (contexte conversation summary) |

---

## Preflight — Baselines PROD

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API PROD | `v3.5.145-outbound-author-name-prod` | `v3.5.145-outbound-author-name-prod` | MATCH |
| Client PROD | `v3.5.168-outbound-author-name-ux-prod` | `v3.5.168-outbound-author-name-ux-prod` | MATCH |
| OW PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | MATCH |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | MATCH |
| Website PROD | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | MATCH |

Health API : `{"status":"ok"}` — Pod 1/1 Running, 0 restarts.

---

## Source Lock

| Signal | Valeur | Verdict |
|---|---|---|
| Branche | `ph147.4/source-of-truth` | OK |
| Commit HEAD | `a18a361d` | MATCH attendu |
| Fix AP.2.4 (clear escalation) | `CASE WHEN $1 = 'resolved' THEN 'none'` en L734 | PRESENT |
| AP.2.2 author_name | `formatAgentDisplayName` (3 occurrences) | PRESENT |
| AP.1F no-reask stale draft | `REASK_PATTERNS` dans autopilot/routes.ts | PRESENT |
| AP.1D anti-reask AI assist | `orderRef` injection dans ai-assist-routes.ts | PRESENT |
| Git status | Seuls `dist/` deletions (pré-existants, non-bloquants) | OK |

---

## Tests avant build

| Test | Résultat |
|---|---|
| TypeScript (`tsc --noEmit`) | exit 0 — PASS |
| Static check: CASE WHEN resolved → none | 1 occurrence — PASS |
| Static check: formatAgentDisplayName | 3 occurrences — PASS |
| Static check: REASK_PATTERNS | Présent — PASS |

---

## Build

| Champ | Valeur |
|---|---|
| Source commit | `a18a361d fix(messages): clear escalation_status on resolve (AP.2.4, KEY-265)` |
| Branche | `ph147.4/source-of-truth` |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.146-conversation-lifecycle-status-prod` |
| Digest | `sha256:2325ed9332c190a48e78ca4e1c3892830f9ee5b67e657cc0425d1caa929f2a0a` |
| Build flags | `--no-cache` |

Aucun autre service buildé (Client, Backend, Website, OW, Admin).

---

## GitOps

| Champ | Valeur |
|---|---|
| Repo | `keybuzz-infra` |
| Branche | `main` |
| Fichier modifié | `k8s/keybuzz-api-prod/deployment.yaml` |
| Commit | `42a02e6` |
| Message | `gitops(prod): API PROD v3.5.146 conversation-lifecycle-status (AP.2.5, KEY-265)` |
| Image avant | `v3.5.145-outbound-author-name-prod` |
| Image après | `v3.5.146-conversation-lifecycle-status-prod` |

---

## Rollout

- `kubectl set image deployment/keybuzz-api keybuzz-api=...v3.5.146-conversation-lifecycle-status-prod -n keybuzz-api-prod`
- `kubectl rollout status` : successfully rolled out
- Nouveau pod : `keybuzz-api-5774bbd7f9-brhgp` — Running 1/1, 0 restarts

---

## Validation runtime PROD

| Check | Résultat |
|---|---|
| Runtime image | `v3.5.146-conversation-lifecycle-status-prod` — MATCH |
| Health | `{"status":"ok"}` |
| Pod | 1/1 Running, 0 restarts |
| Fix AP.2.4 dans container | `CASE WHEN` present dans `dist/modules/messages/routes.js` — 1 match |
| Author name dans container | `formatAgentDisplayName` present — 3 matches |
| No-reask dans container | `REASK_PATTERNS` present — 2 matches |

---

## Audit PROD read-only

### 18 conversations historiques resolved+escalated

| Métrique | Valeur |
|---|---|
| `resolved + escalated` count | **18** (inchangé) |
| Total conversations | 560 |
| `resolved + none` | 493 |
| `open + none` | 31 |
| `open + escalated` | 16 |
| `pending + none` | 2 |

Les 18 conversations historiques sont **préservées et inchangées**. Elles seront traitées dans une phase séparée de cleanup contrôlé si Ludovic valide.

### Aucun nouveau drift

Le fix empêche désormais la création de nouvelles conversations `resolved + escalated`. Les prochaines résolutions de conversations escaladées nettoieront automatiquement `escalation_status`.

---

## Non-régression

| Check | Résultat |
|---|---|
| API health | 200 OK |
| Conversations endpoint | Route active (400 = validation params, pas 500) |
| AI assist endpoint | Route active (400 = body requis, pas 500) |
| Billing endpoint | Route active (400 = validation, pas 500) |
| OW PROD | `v3.5.165-escalation-flow-prod` — INCHANGÉ |
| Client PROD | `v3.5.168-outbound-author-name-ux-prod` — INCHANGÉ |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` — INCHANGÉ |
| Website PROD | `v0.6.9-promo-forwarding-prod` — INCHANGÉ |
| API restarts | 0 |
| Outbound | Aucun envoi déclenché |
| Billing Stripe | Aucune mutation |
| CAPI / tracking | Aucune mutation |
| DB PROD | Lecture seule uniquement |

---

## Rollback

En cas de besoin :

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.145-outbound-author-name-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

Puis mettre à jour `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` pour rétablir le tag `v3.5.145`.

---

## Linear

| Ticket | Mise à jour |
|---|---|
| KEY-265 | AP.2.5 PROD promotion faite. Fix futur actif. 18 historiques restent pour phase séparée de cleanup. |
| KEY-253 | Progression avant Ads : no-reask, author_name, escalation lifecycle tous en PROD. |
| KEY-263 | Auto-assignation post-escalade reste hors scope (phase dédiée). |
| KEY-268 | Notification agent on-escalade reste hors scope (phase dédiée). |

KEY-265 **non fermé** — cleanup historique restant.

---

## Gaps restants

1. **18 conversations resolved+escalated** en PROD — cleanup contrôlé dans une phase séparée avec backup et mutation DB
2. **Auto-assignation post-escalade** (KEY-263) — phase dédiée
3. **Notification agent on-escalade** (KEY-268) — phase dédiée
4. **16 conversations open+escalated** — statut valide, pas un bug

---

## Images PROD après promotion

| Service | Image | Changement |
|---|---|---|
| API | `v3.5.146-conversation-lifecycle-status-prod` | **PROMUE** |
| Client | `v3.5.168-outbound-author-name-ux-prod` | Inchangé |
| OW | `v3.5.165-escalation-flow-prod` | Inchangé |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | Inchangé |
| Website | `v0.6.9-promo-forwarding-prod` | Inchangé |

---

## Verdict

**GO PROD**

CONVERSATION LIFECYCLE STATUS FIX LIVE IN PROD — RESOLVED CONVERSATIONS NOW CLEAR ESCALATION STATUS FOR FUTURE TRANSITIONS — HISTORICAL RESOLVED+ESCALATED ROWS PRESERVED FOR SEPARATE CONTROLLED CLEANUP — AUTHOR NAME AND NO-REASK BASELINES PRESERVED — CLIENT/BACKEND/WEBSITE/OW UNCHANGED — NO AUTO-SEND — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT
