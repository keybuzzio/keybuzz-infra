# PH-SAAS-T8.12AP.1F — AI Stored Drafts No-Reask — PROD Promotion

> **Date** : 2026-05-07
> **Phase** : PH-SAAS-T8.12AP.1F-AI-STORED-DRAFTS-NO-REASK-PROD-PROMOTION-01
> **Environnement** : PROD
> **Type** : Promotion API PROD + validation runtime
> **Priorité** : P0
> **Standard appliqué** : CE_PROMPTING_STANDARD.md + RULES_AND_RISKS.md

---

## Résumé

Promotion en PROD du fix API AP.1E (invalidation des brouillons IA stockés obsolètes à la lecture). Le handler GET `/autopilot/draft` vérifie désormais si un brouillon contient des patterns reask tout en ayant un `order_ref` connu pour la conversation — si oui, il retourne `hasDraft: false`.

**Découverte PROD** : les 8 brouillons suspects identifiés en AP.1E étaient déjà tous consommés (`DRAFT_DISMISSED`, `DRAFT_MODIFIED`, `DRAFT_APPLIED`). Le fix agit comme protection structurelle pour tout futur cas similaire.

---

## Freeze API PROD

| Élément | Valeur |
|---|---|
| Runtime API PROD avant promotion | `v3.5.143-ai-auto-draft-no-reask-prod` |
| Digest avant promotion | `sha256:308ea1f4f3211fc8b039b1c0cddf3c115ad8fc0415bc510547dfab2585daacb6` |
| Pod | `keybuzz-api-54c7dfb74-vrl9d` — Running, 0 restart |
| Health | `{"status":"ok"}` |
| **Freeze confirmé** | Aucun autre agent ne doit builder/déployer `keybuzz-api-prod` pendant AP.1F |
| Scope | API PROD uniquement — Client/Backend/Admin/Website inchangés |

---

## Preflight

### Repos

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `5ae88713` | src/ propre | **OK** |
| keybuzz-infra | `main` | `2162186` | — | **OK** |

### Runtimes avant promotion

| Service | Env | Image actuelle | Changement prévu |
|---|---|---|---|
| API | PROD | `v3.5.143-ai-auto-draft-no-reask-prod` | → `v3.5.144-ai-stored-drafts-no-reask-prod` |
| Client | PROD | `v3.5.163-ai-no-reask-fix-prod` | **AUCUN** |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | **AUCUN** |
| Website | PROD | `v0.6.9-promo-forwarding-prod` | **AUCUN** |
| Outbound Worker | PROD | `v3.5.165-escalation-flow-prod` | **AUCUN** |

---

## Source Lock

| Fichier | Signal attendu | Présent | Verdict |
|---|---|---|---|
| `routes.ts` L252-279 | AP.1E stale draft invalidation | ✅ | **OK** |
| `routes.ts` | `REASK_PATTERNS` (8 regex) | ✅ | **OK** |
| `routes.ts` | `staleReason: reask_with_known_data` | ✅ | **OK** |
| `routes.ts` | `canRegenerate: true` | ✅ | **OK** |
| `engine.ts` L728-733 | AP.1D anti-reask commande + tracking | ✅ | **OK** |
| `shared-ai-context.ts` L557-562 | AP.1D anti-reask commande + tracking | ✅ | **OK** |
| Hardcoding | Aucun | ✅ vide | **OK** |
| `needsHumanAction` | 3 occ. | ✅ | **OK** |
| `GUARDRAIL_SYSTEM_RULES` | 2 refs | ✅ | **OK** |
| `loadEnrichedOrderContext` | 2 refs | ✅ | **OK** |
| `allow_auto_reply` | 2 refs | ✅ | **OK** |

---

## Build API PROD

| Élément | Valeur |
|---|---|
| Commit source | `5ae88713` |
| Branche | `ph147.4/source-of-truth` |
| Commande | `docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-api:v3.5.144-ai-stored-drafts-no-reask-prod .` |
| Tag | `v3.5.144-ai-stored-drafts-no-reask-prod` |
| Registry digest | `sha256:e13c92543f0fcd914c3228fc186648823f3cca9bb4e1e7ff9598c7dfa458cf2f` |
| Rollback | `v3.5.143-ai-auto-draft-no-reask-prod` |
| Build depuis source Git propre | ✅ |
| Aucun secret leak | ✅ |

---

## GitOps PROD

| Élément | Valeur |
|---|---|
| Manifest modifié | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Commit GitOps | `05c33f7` |
| Message | `gitops(prod): PH-SAAS-T8.12AP.1F API PROD v3.5.144-ai-stored-drafts-no-reask-prod (KEY-256)` |
| Push | `main → main` |
| kubectl apply | `deployment.apps/keybuzz-api configured` |
| Rollout | `deployment "keybuzz-api" successfully rolled out` |
| Pod | `keybuzz-api-7955785f46-snrhh` — Running, 0 restart |
| Manifest = runtime | ✅ |

---

## Validation Structurelle PROD

| Signal | Présent runtime PROD | Attendu | Verdict |
|---|---|---|---|
| Image tag | `v3.5.144-ai-stored-drafts-no-reask-prod` | ✅ | **OK** |
| Digest | `sha256:e13c92543f0fcd914c3228fc186648823f3cca9bb4e1e7ff9598c7dfa458cf2f` | ✅ match registry | **OK** |
| Pod Running, 0 restart | ✅ | ✅ | **OK** |
| Health `{"status":"ok"}` | ✅ | ✅ | **OK** |
| AP.1E marker + REASK_PATTERNS dans dist | ✅ L208-232 | ✅ | **OK** |
| `staleReason: reask_with_known_data` dans dist | ✅ | ✅ | **OK** |
| AP.1D anti-reask `engine.js` L558+562 | ✅ | ✅ | **OK** |
| AP.1D anti-reask `shared-ai-context.js` L455+458 | ✅ | ✅ | **OK** |
| Plan gates (`allow_auto_reply`=1, `needsHumanAction`=3, `GUARDRAIL_SYSTEM_RULES`=1) | ✅ | ✅ | **OK** |

---

## Validation Fonctionnelle PROD Safe

| Cas | Données connues | Attendu | Observé | Verdict |
|---|---|---|---|---|
| A. Suspect + order connu | order_ref défini | `hasDraft: false` | Aucun draft éligible en PROD (tous consommés) — protection structurelle confirmée dans dist | **OK (structurel)** |
| B. Suspect + pas d'order | order_ref NULL | Peut rester affiché | 1 draft éligible sans order_ref — correctement affiché | **OK** |
| C. Non-suspect | — | Reste affiché | Non impacté par le fix (pas de pattern match) | **OK** |
| D. Nouveau brouillon | — | Ne demande pas commande/suivi connu | AP.1D confirmé dans engine.js | **OK** |
| E. Aide IA | — | Toujours OK | Client `v3.5.163` inchangé | **OK** |

---

## PROD Read-Only Impact Check

### Analyse des 8 brouillons suspects PROD

| ID | Conversation | order_ref | Status actuel | Éligible GET /draft | Invalidé par AP.1F |
|---|---|---|---|---|---|
| alog-1777963503219 | cmmos9k8cn... | 404-3892837-3215550 | DRAFT_DISMISSED | NON | — |
| alog-1777821812880 | cmmopx7bo2... | 171-8133751-3047512 | DRAFT_MODIFIED | NON | — |
| alog-1777586841107 | cmmom1b2fk... | 405-1105549-0850713 | DRAFT_MODIFIED | NON | — |
| alog-1777488151951 | cmmokejpqh... | 404-5163461-4923541 | DRAFT_MODIFIED | NON | — |
| alog-1776786185879 | cmmo8sivoa... | NULL | DRAFT_APPLIED | NON | — |
| alog-1776786031753 | cmmo8sivoa... | NULL | DRAFT_GENERATED | OUI | NON (pas d'order_ref) |
| alog-1776726180560 | conv-b1dd4be4 | NULL | DRAFT_APPLIED | NON | — |
| alog-1775894578241 | cmmnu11w22... | NULL | DRAFT_APPLIED | NON | — |

**Résultat** : 0 brouillons PROD seraient servis comme suggestion invalide. Les 4 qui avaient un `order_ref` ont tous été consommés par les agents. Le fix AP.1F agit comme filet de sécurité structurel.

| Check | Résultat | Mutation | Verdict |
|---|---|---|---|
| 8 suspects analysés | 0 éligible + avec order_ref | NON | **OK** |
| Aucun DELETE/UPDATE DB | ✅ | NON | **OK** |
| Aucune mutation billing/tracking/CAPI | ✅ | NON | **OK** |

---

## Plan Gates PROD

| Plan | Aide IA | Brouillon IA auto | KBActions | Auto-send | Verdict |
|---|---|---|---|---|---|
| STARTER | Visible (teaser), gated KBActions | Gated KBActions | 0 inclus | Non | **OK** |
| PRO | Disponible | Disponible | 1000/mois | Non | **OK** |
| AUTOPILOT_ASSISTED | Disponible | Disponible | 1000/mois | Non | **OK** |
| AUTOPILOT | Disponible | Disponible | 2000/mois | Oui (guardrails) | **OK** |

---

## Non-Régression PROD

| Surface | Check | Résultat | Verdict |
|---|---|---|---|
| API health PROD | `{"status":"ok"}` | OK | **OK** |
| DB connectivity | 14 tenants | OK | **OK** |
| CronJobs PROD | 4 actifs | Inchangés | **OK** |
| Client PROD | `v3.5.163-ai-no-reask-fix-prod` | Inchangé | **OK** |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | Inchangé | **OK** |
| Website PROD | `v0.6.9-promo-forwarding-prod` | Inchangé | **OK** |
| Outbound Worker PROD | `v3.5.165-escalation-flow-prod` | Inchangé | **OK** |
| 0 outbound envoyé | — | — | **OK** |
| 0 auto-send | — | — | **OK** |
| 0 billing mutation | — | — | **OK** |
| 0 CAPI | — | — | **OK** |
| 0 DB mutation | — | — | **OK** |

---

## Commits

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `5ae88713` | fix(ai): stale draft invalidation (AP.1E, KEY-256) |
| keybuzz-infra | `main` | `05c33f7` | gitops(prod): API PROD `v3.5.144-ai-stored-drafts-no-reask-prod` (KEY-256) |

---

## Images

| Service | Env | Tag | Digest |
|---|---|---|---|
| API | PROD | `v3.5.144-ai-stored-drafts-no-reask-prod` | `sha256:e13c92543f0fcd914c3228fc186648823f3cca9bb4e1e7ff9598c7dfa458cf2f` |
| API (rollback) | PROD | `v3.5.143-ai-auto-draft-no-reask-prod` | `sha256:308ea1f4f3211fc8b039b1c0cddf3c115ad8fc0415bc510547dfab2585daacb6` |

---

## Aucun Hardcoding

- Aucun tenant ID hardcodé
- Aucun user/email hardcodé
- Aucun seller/order/tracking hardcodé
- Aucun marketplace/pays hardcodé

---

## Rollback GitOps Strict

Si rollback nécessaire :

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` :
   ```
   image: ghcr.io/keybuzzio/keybuzz-api:v3.5.143-ai-auto-draft-no-reask-prod
   ```
2. `git commit` + `git push`
3. `kubectl apply -f keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`
5. Vérifier manifest = runtime

**Interdit** : `kubectl set image`, `kubectl patch`, `kubectl edit`

---

## Services PROD Inchangés

| Service | Image PROD | Touché par AP.1F |
|---|---|---|
| Client | `v3.5.163-ai-no-reask-fix-prod` | **NON** |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | **NON** |
| Website | `v0.6.9-promo-forwarding-prod` | **NON** |
| Outbound Worker | `v3.5.165-escalation-flow-prod` | **NON** |
| DB | Aucune mutation | **NON** |
| Stripe | Aucune mutation | **NON** |
| CAPI/tracking | Aucun event | **NON** |

---

## Linear

| Ticket | Action |
|---|---|
| KEY-256 | Promotion PROD AP.1F — tag `v3.5.144-ai-stored-drafts-no-reask-prod`. Protection complète : génération (AP.1D) + lecture (AP.1F). Analyse PROD montre 0 draft suspect éligible (tous consommés). **Peut passer en Done** si Ludovic confirme. |
| KEY-262 | Protection serveur complète — génération anti-reask (AP.1D) + lecture invalidation (AP.1F) |
| KEY-264 | Tracking context préservé dans engine.js + shared-ai-context.js |
| KEY-253 | Chaîne AP.1A→1F complétée. Couverture no-reask exhaustive. |
| KEY-255 | Non touché — escalade phase dédiée |
| KEY-263 | Non touché — escalade phase dédiée |

---

## Bilan complet AP.1 → AP.1F

| Phase | Surface | Env | Fix | Status |
|---|---|---|---|---|
| AP.1 | Aide IA (client) | DEV | Découplage orderRef/savStatus + instruction anti-reask | ✅ |
| AP.1A | Aide IA (client) | DEV | Build + validation runtime | ✅ |
| AP.1B | Aide IA (client) | PROD | Promotion client PROD | ✅ |
| AP.1C | Brouillon IA auto (API) | DEV | Anti-reask dans engine.ts + shared-ai-context.ts | ✅ |
| AP.1D | Brouillon IA auto (API) | PROD | Promotion API PROD | ✅ |
| AP.1E | Brouillons stockés (API) | DEV | Invalidation lecture stale drafts | ✅ |
| AP.1F | Brouillons stockés (API) | PROD | Promotion API PROD | ✅ |

---

## Verdict

### **GO PROD**

- Build, deploy et validations structurelles : **OK**
- AP.1E stale draft invalidation confirmée dans runtime PROD
- AP.1D anti-reask confirmé dans runtime PROD
- 0 brouillon suspect PROD éligible à servir (tous consommés) — le fix est une protection structurelle
- Validation humaine préservée, aucun auto-send ajouté
- Plan gates préservés, KBActions gating préservé
- Non-régression complète
- Aucune suppression/mutation DB

---

## Phrase cible

AI STORED DRAFTS NO-REASK LIVE IN PROD — OLD PREFIX DRAFTS NO LONGER SHOWN AS VALID SUGGESTIONS WHEN ORDER DATA KNOWN — NEW AUTOMATIC DRAFTS USE KNOWN ORDER/TRACKING DATA — AIDE IA REMAINS VALID — HUMAN VALIDATION PRESERVED — NO AUTO-SEND — PLAN GATES PRESERVED — CLIENT/BACKEND/ADMIN/WEBSITE UNCHANGED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT

---

STOP
