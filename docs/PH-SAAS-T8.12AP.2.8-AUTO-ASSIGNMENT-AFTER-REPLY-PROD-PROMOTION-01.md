# PH-SAAS-T8.12AP.2.8 — Auto-Assignment After Reply — PROD Promotion

> Phase : PH-SAAS-T8.12AP.2.8-AUTO-ASSIGNMENT-AFTER-REPLY-PROD-PROMOTION-01
> Ticket : KEY-268
> Tickets liés : KEY-265, KEY-253, KEY-263, KEY-267
> Date : 2026-05-07
> Environnement : PROD
> Type : promotion API PROD uniquement

---

## Objectif

Promouvoir en PROD le fix AP.2.7 validé en DEV : auto-assignation des conversations non assignées au vrai agent humain tenant-scoped lors d'une réponse.

Cette phase active uniquement le comportement futur. Elle ne nettoie PAS les 193 conversations historiques non assignées.

---

## Sources relues

| Document | Vérifié |
|---|---|
| CE_PROMPTING_STANDARD.md | OUI |
| RULES_AND_RISKS.md | OUI |
| AI_MESSAGING_FEATURE_PARITY_BASELINE.md | OUI |
| PH-SAAS-T8.12AP.2.7 (rapport DEV) | OUI |
| PH-SAAS-T8.12AP.2.5 (référence promotion) | OUI |
| PH-SAAS-T8.12AP.2.6 (cleanup historique) | OUI |
| PH-SAAS-T8.12AP.2.3.1 (author_name QA) | OUI |
| PH-SAAS-T8.12AP.1F (no-reask/stale draft) | OUI |

---

## Baselines PROD avant promotion

| Service | Image attendue | Image runtime | Match |
|---|---|---|---|
| API PROD | `v3.5.146-conversation-lifecycle-status-prod` | `v3.5.146-conversation-lifecycle-status-prod` | OUI |
| Client PROD | `v3.5.168-outbound-author-name-ux-prod` | `v3.5.168-outbound-author-name-ux-prod` | OUI |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | OUI |
| Website PROD | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | OUI |
| OW PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | OUI |

---

## Source lock

| Signal | Valeur |
|---|---|
| Repo | keybuzz-api |
| Branche | `ph147.4/source-of-truth` |
| Commit source | `9521fb35` feat(messages): auto-assign conversation to human replier (AP.2.7, KEY-268) |
| Commit match | OUI |
| Git dirty | dist/ uniquement (rebuild artifacts) |

### Vérification signaux source

| Signal | Présent source | Verdict |
|---|---|---|
| AP.2.7 `assigned_agent_id IS NULL` | OUI (L527) | PASS |
| AP.2.7 `user_tenants WHERE user_id` | OUI (L522) | PASS |
| AP.2.7 `resolvedAgentUserId` | OUI (L398, L404, L519) | PASS |
| AP.2.4 `CASE WHEN resolved` | OUI (L757) | PASS |
| AP.2.2 `formatAgentDisplayName` | OUI (L23) | PASS |
| AP.1F `REASK_PATTERNS` | OUI (L253) | PASS |
| Hardcoding | 0 matches | PASS |
| Auto-send | 0 matches | PASS |
| TSC compile | exit 0 | PASS |

---

## Build PROD

| Champ | Valeur |
|---|---|
| Source commit | `9521fb35` |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.147-auto-assignment-after-reply-prod` |
| Digest | `sha256:dbd1d4f7628b500fbafb61966a74f1d012727928069e836b3868c856f34d513f` |
| Build | `docker build --no-cache` |
| TSC build | OUI (Step 7/19) |
| Push | OUI |

---

## GitOps

| Champ | Valeur |
|---|---|
| Fichier | `k8s/keybuzz-api-prod/deployment.yaml` |
| Commit infra | `b95037e` gitops(prod): API PROD v3.5.147 auto-assignment-after-reply (AP.2.8, KEY-268) |
| Push | OUI (main) |

---

## Déploiement

| Champ | Valeur |
|---|---|
| Commande | `kubectl set image` |
| Rollout | `successfully rolled out` |
| Pod | `keybuzz-api-57f4bb6446-tkdxd` |
| Restarts | 0 |
| Health | `{"status":"ok"}` |

---

## Validation structurelle container compilé

| Signal | Grep JS compilé | Verdict |
|---|---|---|
| `assigned_agent_id IS NULL` | L472 | PRESENT |
| `user_tenants WHERE user_id` | L470 | PRESENT |
| `resolvedAgentUserId` | L371, L377, L468, L470, L472, L474 | PRESENT |
| `Auto-assigned conversation` | L474 | PRESENT |
| `SELECT id, name FROM users` | L374 | PRESENT |
| `CASE WHEN` (AP.2.4) | PRESENT | PRESENT |
| `formatAgentDisplayName` (AP.2.2) | 3 occurrences | PRESENT |
| `REASK_PATTERNS` (AP.1F) | 2 occurrences | PRESENT |

---

## Validation read-only PROD (post-promotion)

| Métrique | Valeur | Verdict |
|---|---|---|
| Outbound humain + agent NULL | 193 | Historique attendu, pas nettoyé |
| Escalated + agent NULL | 16 | "À prendre en charge", correct |
| Already assigned | 2 | Inchangé |
| Resolved + escalated | **0** | Clean (AP.2.6) |
| Total conversations | 561 | Inchangé |
| Total messages | 1661 | Inchangé |
| Billing events | 160 | Inchangé |

### Distribution author_name outbound

| author_name | message_source | Count |
|---|---|---|
| KeyBuzz Agent | HUMAN | 442 |
| Equipe SAV | SUPPLIER_CONTACT | 5 |
| Equipe SAV eComLG | SUPPLIER_CONTACT | 4 |
| Ludovic.G | HUMAN | 2 |
| Equipe SAV Test | SUPPLIER_CONTACT | 1 |

### Matrice status/escalation

| Status | Escalation | Count |
|---|---|---|
| resolved | none | 511 |
| open | none | 32 |
| open | escalated | 16 |
| pending | none | 2 |

---

## Non-régression

| Test | Résultat | Verdict |
|---|---|---|
| Health API | 200 OK | PASS |
| Dashboard summary | 200 | PASS |
| Billing current | 400 (paramètre requis) | PASS (structurel) |
| Restarts | 0 | PASS |
| Client PROD image | `v3.5.168-outbound-author-name-ux-prod` | INCHANGÉ |
| OW PROD image | `v3.5.165-escalation-flow-prod` | INCHANGÉ |
| Backend PROD image | `v1.0.47-cross-env-guard-fix-prod` | INCHANGÉ |
| Website PROD image | `v0.6.9-promo-forwarding-prod` | INCHANGÉ |
| Mutation DB | 0 | PASS |
| Outbound envoyé | 0 | PASS |
| Billing drift | 0 | PASS |
| Stripe mutation | 0 | PASS |

---

## Rollback

| Champ | Valeur |
|---|---|
| Image rollback | `v3.5.146-conversation-lifecycle-status-prod` |
| Procédure | Modifier manifest GitOps → commit → push → `kubectl apply` → `rollout status` |

---

## Contrat AP.2.7 — Vérification PROD

| Règle | Status PROD |
|---|---|
| Humain reply + non assigné → assigne au user tenant-scoped | CODE PRÉSENT, actif |
| Humain reply + déjà assigné → inchangé | `WHERE assigned_agent_id IS NULL` |
| IA-assisted validé par humain → assigne au validateur si vide | CODE PRÉSENT (même chemin reply) |
| Autopilot → pas de fausse assignation | Vérifié (engine.ts distinct, pas de auto-assign) |
| Escalade non prise → reste actionnable | 16 conversations open/escalated sans agent |
| No-reask | REASK_PATTERNS présent |
| author_name réel | formatAgentDisplayName présent |
| resolved clears escalation | CASE WHEN présent |
| Aucun auto-send ajouté | 0 match |

---

## Linear

| Ticket | Mise à jour |
|---|---|
| KEY-268 | PROD promotion faite. Comportement futur actif. QA Ludovic si nécessaire avant close. |
| KEY-265 | Auto-assignment PROD actif. Cycle conversations quasiment clos sauf notification/escalade (KEY-263). |
| KEY-253 | Progression : no-reask + author_name + lifecycle + auto-assignment tous PROD. Prêt avant Ads. |
| KEY-263 | Notification d'escalade reste hors scope. Phase dédiée recommandée. |
| KEY-267 | `assigned_agent_name` API non ajouté. L'UI actuelle utilise `assigned_agent_id` + lookup users. Suffisant pour le moment, à réévaluer si UX requiert le nom directement. |

---

## Gaps restants

1. **193 conversations historiques** non assignées malgré réponse humaine — cleanup futur possible mais non bloquant
2. **KEY-263** notification d'escalade — phase séparée
3. **KEY-267** `assigned_agent_name` enrichissement API — à évaluer si besoin UX
4. **442 messages KeyBuzz Agent** au lieu de Prénom.N — données historiques avant AP.2.2, ne seront pas corrigées rétroactivement

---

## Verdict

### GO PROD

AUTO-ASSIGNMENT AFTER HUMAN REPLY LIVE IN PROD — UNASSIGNED CONVERSATIONS ARE ASSIGNED TO THE REAL TENANT-SCOPED HUMAN AGENT ON REPLY — EXISTING ASSIGNMENTS PRESERVED — IA-ASSISTED HUMAN SENDS ATTRIBUTED TO HUMAN VALIDATOR — AUTOPILOT DOES NOT CREATE FAKE HUMAN ASSIGNMENT — ESCALATED UNASSIGNED CONVERSATIONS REMAIN ACTIONABLE — NO AUTO-SEND ADDED — NO-REASK/AUTHOR_NAME/LIFECYCLE BASELINES PRESERVED — CLIENT/BACKEND/WEBSITE/OW UNCHANGED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT
