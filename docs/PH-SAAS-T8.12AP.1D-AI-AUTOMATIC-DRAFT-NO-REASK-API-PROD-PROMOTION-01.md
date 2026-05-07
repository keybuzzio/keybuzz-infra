# PH-SAAS-T8.12AP.1D — AI Automatic Draft No-Reask — API PROD Promotion

> **Date** : 2026-05-07
> **Phase** : PH-SAAS-T8.12AP.1D-AI-AUTOMATIC-DRAFT-NO-REASK-API-PROD-PROMOTION-01
> **Environnement** : PROD
> **Type** : Promotion API PROD + validation runtime no-reask
> **Priorité** : P0
> **Standard appliqué** : CE_PROMPTING_STANDARD.md + RULES_AND_RISKS.md

---

## Résumé

Promotion en PROD du fix API qui corrige la surface « Brouillon IA automatique » (autopilot draft). Avant ce fix, le chemin API serveur (`autopilot/engine.ts` + `shared-ai-context.ts`) ne contenait pas d'instruction anti-reask pour le numéro de commande quand celui-ci était connu. Le fix ajoute des instructions explicites empêchant l'IA de redemander un numéro de commande ou de suivi déjà présent dans le contexte.

**Root cause AP.1C** :
- `autopilot/engine.ts` protégeait le tracking mais pas le numéro de commande
- `shared-ai-context.ts::buildEnrichedUserPrompt()` n'avait aucune instruction anti-reask commande/tracking
- Anciens brouillons stockés dans `ai_action_log` peuvent conserver du texte pré-fix

---

## Freeze API PROD

| Élément | Valeur |
|---|---|
| Runtime API PROD avant promotion | `v3.5.142-promo-retry-email-prod` |
| Digest avant promotion | `sha256:c49ab6f44493669525c08df389568808db6fdf57f57d3fe9aa11e2de025e361f` |
| Freeze confirmé | Aucun autre agent ne doit builder/déployer `keybuzz-api-prod` pendant AP.1D |
| Scope | API PROD uniquement — Client/Backend/Admin/Website inchangés |

---

## Preflight

### Repos

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `49ff3440` | src/ propre | **OK** |
| keybuzz-infra | `main` | `e7dba6c` | — | **OK** |

### Runtimes avant promotion

| Service | Env | Image actuelle | Changement prévu |
|---|---|---|---|
| API | PROD | `v3.5.142-promo-retry-email-prod` | → `v3.5.143-ai-auto-draft-no-reask-prod` |
| Client | PROD | `v3.5.163-ai-no-reask-fix-prod` | AUCUN |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | AUCUN |
| Website | PROD | `v0.6.9-promo-forwarding-prod` | AUCUN |
| Outbound Worker | PROD | `v3.5.165-escalation-flow-prod` | AUCUN |

---

## Source Lock

| Fichier | Signal attendu | Présent | Verdict |
|---|---|---|---|
| `engine.ts` L731-733 | Anti-reask commande (AP.1C) | ✅ | **OK** |
| `engine.ts` L728 | Anti-reask tracking (existant) | ✅ | **OK** |
| `engine.ts` | Validation humaine `needsHumanAction` (3 occ.) | ✅ | **OK** |
| `engine.ts` | `loadEnrichedOrderContext` (2 refs) | ✅ | **OK** |
| `engine.ts` | `resolveOrderRefFromMessages` (2 refs) | ✅ | **OK** |
| `engine.ts` | `buildChannelPromptBlock` platform-aware (2 refs) | ✅ | **OK** |
| `engine.ts` | `GUARDRAIL_SYSTEM_RULES` seller-first (2 refs) | ✅ | **OK** |
| `shared-ai-context.ts` L557-562 | Anti-reask commande + tracking (AP.1C) | ✅ | **OK** |
| Hardcoding | Aucun tenant/user/order/email | ✅ vide | **OK** |
| Auto-send | Gated par `allow_auto_reply` + mode | ✅ | **OK** |

---

## Build API PROD

| Élément | Valeur |
|---|---|
| Commit source | `49ff3440` |
| Branche | `ph147.4/source-of-truth` |
| Commande | `docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-api:v3.5.143-ai-auto-draft-no-reask-prod .` |
| Tag | `v3.5.143-ai-auto-draft-no-reask-prod` |
| Registry digest | `sha256:308ea1f4f3211fc8b039b1c0cddf3c115ad8fc0415bc510547dfab2585daacb6` |
| Image ID local | `sha256:459c3d7a2681b31b45625961d80339459b8551f0fc7fc29434ef7ce06925a2df` |
| Rollback | `v3.5.142-promo-retry-email-prod` |
| Build depuis source Git propre | ✅ (src/ diff vide) |
| Repo propre | ✅ |
| Aucun secret leak | ✅ |

---

## GitOps PROD

| Élément | Valeur |
|---|---|
| Manifest modifié | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Commit GitOps | `54ed623` |
| Message | `gitops(prod): PH-SAAS-T8.12AP.1D API PROD v3.5.143-ai-auto-draft-no-reask-prod (KEY-256)` |
| Push | `main → main` |
| kubectl apply | `deployment.apps/keybuzz-api configured` |
| Rollout | `deployment "keybuzz-api" successfully rolled out` |
| Pod | `keybuzz-api-54c7dfb74-vrl9d` — Running, 0 restart |
| Manifest = runtime | ✅ |

Aucun autre manifest touché :
- ❌ Client manifests
- ❌ Backend manifests
- ❌ Admin manifests
- ❌ Website manifests
- ❌ CronJobs
- ❌ Secrets
- ❌ DB

---

## Validation Structurelle PROD

| Signal | Présent runtime PROD | Attendu | Verdict |
|---|---|---|---|
| Image tag | `v3.5.143-ai-auto-draft-no-reask-prod` | ✅ | **OK** |
| Digest | `sha256:308ea1f4f...` | ✅ match registry | **OK** |
| Pod Running, 0 restart | ✅ | ✅ | **OK** |
| Health `{"status":"ok"}` | ✅ | ✅ | **OK** |
| Anti-reask commande `engine.js` L562 | ✅ | ✅ | **OK** |
| Anti-reask tracking `engine.js` L558 | ✅ | ✅ | **OK** |
| Anti-reask dans `shared-ai-context.js` L455, L458 | ✅ | ✅ | **OK** |
| Marqueur AP.1C | ✅ (2 fichiers) | ✅ | **OK** |
| `loadEnrichedOrderContext` | ✅ | ✅ | **OK** |
| `resolveOrderRefFromMessages` | ✅ | ✅ | **OK** |
| `buildChannelPromptBlock` | ✅ | ✅ | **OK** |
| `GUARDRAIL_SYSTEM_RULES` | ✅ | ✅ | **OK** |
| Client PROD inchangé | `v3.5.163-ai-no-reask-fix-prod` | ✅ | **OK** |
| Backend PROD inchangé | `v1.0.47-cross-env-guard-fix-prod` | ✅ | **OK** |
| Website PROD inchangé | `v0.6.9-promo-forwarding-prod` | ✅ | **OK** |
| Outbound Worker PROD inchangé | `v3.5.165-escalation-flow-prod` | ✅ | **OK** |

---

## Validation Fonctionnelle PROD Safe

| Surface | Cas | Données connues | Résultat attendu | Résultat observé | Verdict |
|---|---|---|---|---|---|
| B (Brouillon auto) | A. orderRef + tracking | Les deux | Ne demande ni l'un ni l'autre | Instructions anti-reask confirmées L558 + L562 | **OK (structurel)** |
| B (Brouillon auto) | B. orderRef seul | orderRef seul | Ne demande pas commande | Anti-reask commande L562, tracking conditionnel | **OK (structurel)** |
| B (Brouillon auto) | C. Rien connu | Aucune ref | Demande honnête possible | Aucune injection (conditionnel) | **OK (logique)** |
| B (Brouillon auto) | D. Ancien brouillon | Pré-fix | Peut rester pré-fix | Documenté — non représentatif | **CAVEAT** |
| A (Aide IA) | E. Surface A | Client AP.1B | Toujours OK | Client `v3.5.163-ai-no-reask-fix-prod` inchangé | **OK** |
| B (Brouillon auto) | F. Surface B | API AP.1D | OK via API | `engine.js` + `shared-ai-context.js` confirmés | **OK** |

**Note QA** : Les anciens brouillons stockés dans `ai_action_log` avant ce déploiement peuvent encore contenir du texte pré-fix. Seuls les nouveaux brouillons générés après le 7 mai 2026 08:57 UTC reflètent le fix.

**Scénario QA Ludovic** : Ouvrir une conversation PROD avec `orderRef` connu → vérifier que le nouveau brouillon automatique ne redemande pas le numéro de commande ni le tracking.

---

## Plan Gates PROD

| Plan | Aide IA | Brouillon IA auto | KBActions | Auto-send | Verdict |
|---|---|---|---|---|---|
| STARTER | Visible (teaser), gated KBActions | Gated KBActions | 0 inclus | Non | **OK** |
| PRO | Disponible | Disponible | 1000/mois | Non | **OK** |
| AUTOPILOT_ASSISTED | Disponible | Disponible | 1000/mois | Non (`canAutoExecute=false`) | **OK** |
| AUTOPILOT | Disponible | Disponible | 2000/mois | Oui (guardrails) | **OK** |

Vérifié : `allow_auto_reply` = 1 occ., `needsHumanAction` = 3 occ., KBActions debit = 15 refs.

---

## Non-Régression PROD

| Surface | Check | Résultat | Verdict |
|---|---|---|---|
| API health PROD | `{"status":"ok"}` | OK | **OK** |
| DB connectivity | 14 tenants | OK | **OK** |
| CronJobs PROD | 4 actifs (outbound-tick, sla, carrier-tracking, trial-lifecycle) | Inchangés | **OK** |
| Outbound worker | `v3.5.165-escalation-flow-prod`, Running | Inchangé | **OK** |
| Client PROD | `v3.5.163-ai-no-reask-fix-prod` | Inchangé | **OK** |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | Inchangé | **OK** |
| Website PROD | `v0.6.9-promo-forwarding-prod` | Inchangé | **OK** |
| 0 outbound envoyé | Aucun email déclenché | — | **OK** |
| 0 auto-send | Gated par `allow_auto_reply` + mode | — | **OK** |
| 0 billing mutation | Aucune mutation Stripe | — | **OK** |
| 0 CAPI | Aucun tracking event | — | **OK** |
| 0 DB mutation | Aucune migration, aucun ALTER | — | **OK** |

---

## Commits

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `49ff3440` | fix(ai): add anti-reask for order number in autopilot engine + shared-ai-context (AP.1C, KEY-256) |
| keybuzz-infra | `main` | `54ed623` | gitops(prod): PH-SAAS-T8.12AP.1D API PROD v3.5.143-ai-auto-draft-no-reask-prod (KEY-256) |

---

## Images

| Service | Env | Tag | Digest |
|---|---|---|---|
| API | PROD | `v3.5.143-ai-auto-draft-no-reask-prod` | `sha256:308ea1f4f3211fc8b039b1c0cddf3c115ad8fc0415bc510547dfab2585daacb6` |
| API (rollback) | PROD | `v3.5.142-promo-retry-email-prod` | `sha256:c49ab6f44493669525c08df389568808db6fdf57f57d3fe9aa11e2de025e361f` |

---

## Rollback GitOps Strict

Si rollback nécessaire :

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` :
   ```
   image: ghcr.io/keybuzzio/keybuzz-api:v3.5.142-promo-retry-email-prod
   ```
2. `git commit` + `git push`
3. `kubectl apply -f keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`
5. Vérifier manifest = runtime

**Interdit** : `kubectl set image`, `kubectl patch`, `kubectl edit`

---

## Linear

| Ticket | Action |
|---|---|
| KEY-256 | Promotion PROD API AP.1D — tag `v3.5.143-ai-auto-draft-no-reask-prod`, digest `sha256:308ea1f4f...`, Surface A + B couvertes, QA Ludovic recommandée sur nouveau brouillon. Statut : **In Review** (en attente QA navigateur Ludovic) |
| KEY-262 | Fix serveur confirmé en PROD — anti-reask dans `engine.ts` + `shared-ai-context.ts` |
| KEY-264 | Tracking context préservé — `loadEnrichedOrderContext` + instructions anti-reask tracking confirmés en runtime PROD |
| KEY-253 | Parent — AP.1A (client DEV), AP.1B (client PROD), AP.1C (API DEV), AP.1D (API PROD) complétés |
| KEY-255 | Non touché — escalade phase dédiée requise |
| KEY-263 | Non touché — escalade phase dédiée requise |

---

## Services PROD Inchangés

| Service | Image PROD | Touché par AP.1D |
|---|---|---|
| Client | `v3.5.163-ai-no-reask-fix-prod` | **NON** |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | **NON** |
| Website | `v0.6.9-promo-forwarding-prod` | **NON** |
| Outbound Worker | `v3.5.165-escalation-flow-prod` | **NON** |
| Admin | — | **NON** |
| DB | Aucune migration | **NON** |
| Stripe | Aucune mutation | **NON** |
| CAPI/tracking | Aucun event | **NON** |

---

## Aucun Hardcoding

- Aucun tenant ID hardcodé
- Aucun user/email hardcodé
- Aucun seller/order/tracking hardcodé
- Aucun marketplace/pays hardcodé

---

## Verdict

### **GO PARTIEL — LUDOVIC QA PENDING + STORED DRAFTS CAVEAT**

- Build, deploy et validations structurelles : **OK**
- Anti-reask confirmé dans le runtime PROD (engine.js L558 + L562, shared-ai-context.js L455 + L458)
- Validation humaine préservée, aucun auto-send ajouté
- Plan gates préservés, KBActions gating préservé
- Non-régression complète : tous services PROD inchangés hors API
- **QA navigateur Ludovic** : vérifier un nouveau brouillon automatique sur conversation avec orderRef connu
- **Caveat anciens brouillons** : les brouillons stockés avant le 7 mai 2026 08:57 UTC peuvent encore contenir le texte pré-fix — non représentatifs du fix

---

## Phrase cible

AI AUTOMATIC DRAFT NO-REASK LIVE IN PROD — AIDE IA AND BROUILLON IA SURFACES BOTH COVERED — KNOWN ORDER/TRACKING DATA NO LONGER REQUESTED FROM CUSTOMER ON NEW DRAFTS — HUMAN VALIDATION PRESERVED — NO AUTO-SEND — PLAN GATES PRESERVED — STARTER IA REMAINS KBACTIONS-GATED — SELLER-FIRST AND PLATFORM-AWARE GUARDRAILS PRESERVED — CLIENT/BACKEND/ADMIN/WEBSITE UNCHANGED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT

---

STOP
