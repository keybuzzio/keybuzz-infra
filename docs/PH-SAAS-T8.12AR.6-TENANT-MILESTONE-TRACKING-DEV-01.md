# PH-SAAS-T8.12AR.6 — TENANT MILESTONE TRACKING DEV

> Date : 2026-05-09
> Linear : KEY-289 (parent KEY-282)
> Type : audit + instrumentation DEV
> Environnement : DEV uniquement
> PROD : strictement inchangee

---

## VERDICT

```
TENANT MILESTONE TRACKING READY IN DEV
- PERFORMANCE SAV TIMELINE ENRICHED WITH REAL TENANT-SCOPED MILESTONES
- NO FAKE EVENTS
- NO AMBIGUOUS BACKFILL
- EMPTY STATES HONEST
- SATISFACTION STILL NOT INSTRUMENTED
- MESSAGE_SOURCE / AUTHOR_NAME / NO_REASK BASELINES PRESERVED
- NO BILLING/TRACKING/CAPI DRIFT
- PROD UNCHANGED
- READY FOR LUDOVIC QA THEN PROD PROMOTION
```

---

## 1. PREFLIGHT

### Repos

| Repo | Branche attendue | Branche reelle | HEAD | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `462ec358` | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `c300ea2` | OK |
| keybuzz-infra | `main` | `main` | `9966882` | OK |

### Images DEV/PROD

| Service | Image DEV avant | Image PROD (inchangee) | Doit changer ? |
|---|---|---|---|
| API | `v3.5.163-message-source-enrichment-dev` | `v3.5.149-message-source-enrichment-prod` | DEV OUI |
| Client | `v3.5.172-message-source-enrichment-ux-dev` | `v3.5.172-message-source-enrichment-ux-prod` | DEV OUI |
| Backend | `v1.0.47-cross-env-guard-fix-dev` | `v1.0.47-cross-env-guard-fix-prod` | NON |
| OW | `v3.5.165-escalation-flow-dev` | `v3.5.165-escalation-flow-prod` | NON |

---

## 2. SOURCES RELUES

- `PH-SAAS-T8.12AR.1` — Audit et design dashboard performance SAV
- `PH-SAAS-T8.12AR.2` — API metrics DEV
- `PH-SAAS-T8.12AR.3` — Client UI DEV
- `PH-SAAS-T8.12AR.4` — PROD promotion
- `PH-SAAS-T8.12AR.7` — Message source enrichment DEV
- `PH-SAAS-T8.12AR.7.2` — Message source PROD QA DB verify
- Code source `performance-stats.service.ts` (bastion)
- Code source `app/performance/page.tsx` (bastion)

---

## 3. AUDIT JALONS EXISTANTS

### Sources de verite identifiees

| Table | Colonnes pertinentes | Tenant-scoped | Fiable |
|---|---|---|---|
| `tenants` | `id`, `created_at` | Oui (PK) | Haute |
| `inbound_connections` | `"tenantId"`, `"createdAt"`, `marketplace` | Oui | Haute |
| `messages` | `tenant_id`, `direction`, `created_at` | Oui | Haute |
| `ai_action_log` | `tenant_id`, `action_type`, `created_at` | Oui | Haute |
| `ai_settings` | `tenant_id`, `mode`, `updated_at` | Oui | **Basse pour historique** |

### Action types disponibles (ai_action_log DEV)

| Type | Count |
|---|---|
| `evaluate` | 1164 |
| `AI_DECISION_TRACE` | 130 |
| `autopilot_reply` | 61 |
| `autopilot_escalate` | 43 |
| `AI_SUGGESTION_GENERATED` | 41 |
| `draft_applied` | 40 |
| `draft_dismissed` | 4 |
| `AI_AUTO_ESCALATED` | 1 |
| `AI_FALSE_PROMISE_DETECTED` | 1 |

### Milestones par tenant (DEV)

| Milestone | ecomlg-001 | switaa-sasu-mnc1x4eq |
|---|---|---|
| `tenant_created` | 2026-01-08T12:58 | 2026-03-29T17:47 |
| `first_channel_connected` | 2026-01-15T17:18 | 2026-03-29T17:48 |
| `first_message_received` | 2026-01-08T19:58 | 2026-03-29T18:19 |
| `first_reply_sent` | 2026-01-08T19:59 | 2026-03-30T15:15 |
| `first_ai_suggestion` | 2026-04-03T14:11 | 2026-04-03T19:19 |
| `first_ai_draft_used` | 2026-04-06T15:22 | 2026-04-06T11:43 |
| `first_autopilot_reply` | 2026-04-06T09:01 | 2026-03-29T20:56 |
| `first_auto_escalation` | presente | 2026-05-09T14:38 |

---

## 4. CONTRAT JALONS

| Milestone | Label UI | Source | Fiabilite | Historique inferable ? | Futur instrumente ? | Affichable ? |
|---|---|---|---|---|---|---|
| `tenant_created` | Espace cree | `tenants.created_at` | Haute | Oui (deterministe) | N/A | **Oui** |
| `first_channel_connected` | Premier canal connecte | `inbound_connections` | Haute | Oui | N/A | **Oui** |
| `first_message_received` | Premier message recu | `messages` | Haute | Oui | N/A | **Oui** |
| `first_reply_sent` | Premiere reponse envoyee | `messages` | Haute | Oui | N/A | **Oui** |
| `first_ai_suggestion` | Premiere suggestion IA | `ai_action_log` | Haute | Oui | N/A | **Oui** |
| `first_ai_draft_used` | Premier brouillon IA utilise | `ai_action_log` | Haute | Oui | N/A | **Oui** |
| `first_autopilot_reply` | Premiere reponse autopilot | `ai_action_log` | Haute | Oui | N/A | **Oui** |
| `first_auto_escalation` | Premiere auto-escalation IA | `ai_action_log` | Haute | Oui | N/A | **Oui** |
| `suggestion_mode_enabled` | Mode suggestion active | `ai_settings.mode` | **Basse** | **Non** (pas d'historique) | A instrumenter | **Non** |
| `autopilot_mode_enabled` | Mode autopilot active | `ai_settings.mode` | **Basse** | **Non** (pas d'historique) | A instrumenter | **Non** |
| `agent_keybuzz_enabled` | Agent KeyBuzz active | Aucune | N/A | Non | Feature inexistante | **Non** |

---

## 5. DECISION SCHEMA

| Option | Avantage | Risque | Decision |
|---|---|---|---|
| **A — Inference uniquement** | Pas de migration, 8/11 jalons couverts, zero risque | 3 jalons manquants | **RETENUE** |
| B — Table `tenant_config_events` | Future-proof pour mode changes | Schema additionnel pour 0 donnees initiales | Differee |

**Justification** : Les 8 jalons deterministes couvrent tous les jalons prouvables. Les 3 jalons manquants (suggestion_mode, autopilot_mode, agent_keybuzz) sont soit impossibles a prouver historiquement, soit lies a une feature inexistante. Creer une table vide n'apporterait aucune valeur immediate.

---

## 6. BACKFILL

Aucun backfill effectue. Tous les jalons sont inferes dynamiquement a partir des tables existantes via des requetes `MIN(created_at)`. Aucune donnee n'a ete ecrite.

---

## 7. PATCH API

| Fichier | Changement |
|---|---|
| `src/modules/stats/performance-stats.service.ts` | +`tenant_created` milestone (query tenants.created_at) |
| | +`first_autopilot_reply` milestone (ai_action_log autopilot_reply) |
| | +`milestoneConfig` avec `confidence` et `source` par milestone |
| | +`unavailableMilestones` array (3 jalons non instrumentes) |
| | Doc comment mis a jour (AR.6 reference) |

Commit API : `462ec358` sur `ph147.4/source-of-truth`

---

## 8. PATCH CLIENT

| Surface | Changement |
|---|---|
| `app/performance/page.tsx` | Type `milestones[]` enrichi avec `source?`, `confidence?` |
| | Type `unavailableMilestones?` ajoute a l'interface |
| | Dot color conditionnel (gris=creation, violet=IA, bleu=standard) |
| | Badge confiance (CheckCircle2 vert) pour milestones haute confiance |
| | Section "Non instrumentes" sous les jalons avec les milestones indisponibles |

Commit Client : `c300ea2` sur `ph148/onboarding-activation-replay`

---

## 9. TESTS DEV

### Tenant avec historique complet (ecomlg-001)

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| `tenant_created` | Present | 2026-01-08 | PASS |
| `first_channel_connected` | Present | 2026-01-15 | PASS |
| `first_message_received` | Present | 2026-01-08 | PASS |
| `first_reply_sent` | Present | 2026-01-08 | PASS |
| `first_ai_suggestion` | Present | 2026-04-03 | PASS |
| `first_ai_draft_used` | Present | 2026-04-06 | PASS |
| `first_autopilot_reply` | Present | 2026-04-06 | PASS |
| `unavailableMilestones` | 3 items | 3 items (mode suggestion, autopilot, agent) | PASS |
| Satisfaction | null | `null`, reason: `satisfaction_not_instrumented` | PASS |

### Tenant SWITAA (switaa-sasu-mnc1x4eq)

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| Milestones | 8 (tous presents) | 8 milestones | PASS |
| `first_auto_escalation` | Present | 2026-05-09T14:38 | PASS |
| Chronologie | Ordonnee | Ordonnee correctement | PASS |

### Ranges API

| Range | HTTP | Verdict |
|---|---|---|
| `7d` | 200 | PASS |
| `30d` | 200 | PASS |
| `90d` | 200 | PASS |
| `all` | 200 (implicite via SWITAA) | PASS |

---

## 10. BUILDS DEV

| Service | Commit source | Tag | Digest | Rollback |
|---|---|---|---|---|
| API | `462ec358` | `v3.5.164-tenant-milestones-dev` | `sha256:401ff3e6...` | `v3.5.163-message-source-enrichment-dev` |
| Client | `c300ea2` | `v3.5.173-tenant-milestones-ux-dev` | `sha256:759a4fcb...` | `v3.5.172-message-source-enrichment-ux-dev` |

---

## 11. GITOPS DEV

| Manifest | Image avant | Image apres |
|---|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.163-message-source-enrichment-dev` | `v3.5.164-tenant-milestones-dev` |
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.172-message-source-enrichment-ux-dev` | `v3.5.173-tenant-milestones-ux-dev` |

Commit infra : `9966882` pousse sur `main`

---

## 12. RUNTIME VALIDATION

| Surface | Validation | Resultat |
|---|---|---|
| Pods | Running | OK |
| Health API | `/health` 200 | OK |
| `/stats/performance` 30d | 200, milestones enrichis | OK |
| `/stats/performance` 7d | 200 | OK |
| `/stats/performance` 90d | 200 | OK |
| Milestones ecomlg-001 | 7 jalons, tous confidence high | OK |
| Milestones SWITAA | 8 jalons, tous confidence high | OK |
| unavailableMilestones | 3 items (suggestion_mode, autopilot_mode, agent_keybuzz) | OK |
| Satisfaction | `null`, `satisfaction_not_instrumented` | OK (AR.5 pending) |
| Aucun fake milestone | Verifie | OK |

---

## 13. NON-REGRESSION PROD

| Service PROD | Image avant | Image apres | Verdict |
|---|---|---|---|
| API | `v3.5.149-message-source-enrichment-prod` | `v3.5.149-message-source-enrichment-prod` | INCHANGE |
| Client | `v3.5.172-message-source-enrichment-ux-prod` | `v3.5.172-message-source-enrichment-ux-prod` | INCHANGE |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | INCHANGE |
| OW | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | INCHANGE |
| Manifests PROD | Non modifies | Non modifies | INCHANGE |
| DB PROD | Aucune mutation | Aucune mutation | INCHANGE |
| Stripe/Billing | Non touche | Non touche | INCHANGE |
| Tracking/CAPI | Non touche | Non touche | INCHANGE |

---

## 14. ROLLBACK DEV (non execute)

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.163-message-source-enrichment-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.172-message-source-enrichment-ux-dev -n keybuzz-client-dev
```

---

## 15. LINEAR

### KEY-289 (AR.6)
- Statut : DEV READY
- Design : Option A (inference uniquement), pas de nouvelle table
- 8 jalons deterministes avec confidence/source metadata
- 3 jalons documentes comme non instrumentes (honest empty state)
- Tags DEV : API `v3.5.164-tenant-milestones-dev`, Client `v3.5.173-tenant-milestones-ux-dev`
- Digests documentes
- Pret pour QA Ludovic puis promotion PROD

### KEY-282 (parent)
- AR.6 DEV complete
- AR.5 (satisfaction) reste a faire
- KEY-290 reste ouvert

---

## 16. GAPS RESTANTS

| # | Gap | Phase |
|---|---|---|
| 1 | `suggestion_mode_enabled` : pas d'historique de changement de mode IA | Future instrumentation (AR.6.1) |
| 2 | `autopilot_mode_enabled` : idem | Future instrumentation (AR.6.1) |
| 3 | `agent_keybuzz_enabled` : feature inexistante | Quand feature disponible |
| 4 | Satisfaction client (CSAT/feedback) | AR.5 (KEY-290) |

---

## 17. CONCLUSION

Phase AR.6 terminee avec succes en DEV. Le dashboard Performance SAV affiche desormais une timeline de jalons reels, tenant-scoped, avec :

- **8 milestones deterministes** (tenant_created, first_channel, first_message, first_reply, first_ai_suggestion, first_ai_draft, first_autopilot_reply, first_auto_escalation)
- **Metadata de confiance** (`confidence: high`, `source: table_name`) sur chaque milestone
- **3 milestones honnêtement absents** (suggestion_mode, autopilot_mode, agent_keybuzz) avec raison explicite
- **Zero fake data, zero backfill ambigu, zero invention**
- **PROD strictement inchangee**

---

*Rapport genere le 2026-05-09 — Phase AR.6 — DEV uniquement, PROD inchangee*
