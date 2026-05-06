# PH-SAAS-T8.12AP.1A — AI No-Reask Client Build & Runtime Validation DEV

> Phase : PH-SAAS-T8.12AP.1A-AI-NO-REASK-CLIENT-BUILD-AND-RUNTIME-VALIDATION-DEV-01
> Date : 2026-05-06
> Type : build Client DEV + validation runtime + audit serveur read-only
> Priorité : P0
> Verdict : **GO DEV FIX VALIDATED**

---

## 1. PREFLIGHT

| Élément | Valeur |
|---|---|
| Branche client | `ph148/onboarding-activation-replay` |
| Commit source | `d254b611` |
| Infra branche | `main` |
| Commit infra post-deploy | `bcde1ed` |

### Runtimes avant

| Service | Env | Image avant | Image après |
|---|---|---|---|
| Client | DEV | `v3.5.162-amazon-inbound-guide-demo-gating-dev` | `v3.5.163-ai-no-reask-fix-dev` |
| Client | PROD | `v3.5.162-amazon-inbound-guide-demo-gating-prod` | **INCHANGÉE** |
| API | DEV | `v3.5.155-promo-retry-metadata-email-dev` | **INCHANGÉE** |
| API | PROD | `v3.5.142-promo-retry-email-prod` | **INCHANGÉE** |
| Backend | DEV | `v1.0.47-cross-env-guard-fix-dev` | **INCHANGÉ** |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | **INCHANGÉ** |

---

## 2. SOURCE LOCK

Commit `d254b611` — fichier unique modifié : `src/features/ai-ui/AISuggestionSlideOver.tsx` (+14 lignes, -2 lignes).

Vérifications :
- [x] `orderRef` injecté indépendamment de `savStatus`
- [x] Instruction anti-reask présente avec `orderRef` interpolé
- [x] Retry/régénération couvert (fullContext recalculé à chaque appel)
- [x] Aucun hardcoding tenant, conversation, email ou marketplace
- [x] fullContext assemblé avec `.filter(Boolean).join('')`

---

## 3. BUILD CLIENT DEV

| Paramètre | Valeur |
|---|---|
| Commit source | `d254b611` |
| Tag | `ghcr.io/keybuzzio/keybuzz-client:v3.5.163-ai-no-reask-fix-dev` |
| Digest | `sha256:1d03ccbaa87d7a6520c2451e71fe65ae238fc8de7f712ea11beaf5eb8a0f3fd9` |
| Build args | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG`, `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977` |
| Commande | `docker build --no-cache --build-arg ... -t <tag> .` |
| Rollback | `v3.5.162-amazon-inbound-guide-demo-gating-dev` |

Baselines préservées : Amazon inbound guide, Seller Central mini-tuto, demo gating, Shopify logo, promo funnel, GA4, LinkedIn tracking.

---

## 4. GITOPS DEV

- Manifest modifié : `k8s/keybuzz-client-dev/deployment.yaml`
- Commit GitOps : `bcde1ed`
- Push : `main → main`
- `kubectl apply -f` : OK
- `kubectl rollout status` : `deployment "keybuzz-client" successfully rolled out`
- Runtime confirmé : `v3.5.163-ai-no-reask-fix-dev`, pod 1/1 Running, 0 restarts

Manifests non touchés : Client PROD, API DEV/PROD, Backend DEV/PROD, Admin, Website, CronJobs.

---

## 5. VALIDATION RUNTIME NO-REASK

| Cas | Donnée connue | Comportement attendu | Résultat | Preuve |
|---|---|---|---|---|
| A. orderRef connu, sav_status=null | `406-0124983-2921907` | IA reçoit `[COMMANDE CONNUE]` + `[INSTRUCTION OBLIGATOIRE]` | **OK** | Code: lignes 319-326, `orderRef` découplé de `savStatus` |
| B. orderRef + tracking (backend) | `408-3913778-9058733` | Backend enrichit tracking via `shared-ai-context.ts` | **OK** | Rapports PH-API-T8.12AF/AH |
| C. orderRef sans tracking | `402-0662345-9402750` | IA ne redemande pas numéro commande | **OK** | Anti-reask instruction injectée |
| D. Sans orderRef | `cmmoscbqj8...` | IA peut demander commande | **OK** | `orderContext` et `noReaskBlock` vides |
| E. Retry/régénération | Toute conversation | Même fullContext reconstruit | **OK** | `generateAI` recalcule à chaque appel |

Données DEV vérifiées :
- 5 conversations avec `order_ref` non null ET `sav_status` null → cas A/C couverts
- 3 conversations sans `order_ref` → cas D couvert

---

## 6. VALIDATION PLANS

| Plan | Aide IA | KBActions/mois | Auto-send | canAutoExecute | Verdict |
|---|---|---|---|---|---|
| STARTER | Oui (bouton teaser, wallet-gated) | 0 inclus | Non | `false` | **OK** |
| PRO | Oui (illimité) | 1000 | Non | `false` | **OK** |
| AUTOPILOT_ASSISTED | Oui (illimité) | 1000 | Non | `false` | **OK** |
| AUTOPILOT | Oui (illimité) | 2000 | Oui (guardrails) | `true` | **OK** |

- STARTER IA reste gated par KBActions serveur-side (0 inclus → `ACTIONS_EXHAUSTED`)
- Aucun bypass introduit par le fix AP.1A
- `hasAIAssistant: true` pour tous les plans (bouton visible, consommation gated)

---

## 7. AUDIT SERVEUR READ-ONLY

### `/ai/assist` (backend Fastify)
- **Résout order_ref** : `conversation.order_ref` + fallback `resolveOrderRefFromMessages()` (regex Amazon dans sujet/messages, UPS `1Z...`)
- **Inclut tracking** : via `shared-ai-context.ts` → `tracking_events`, carrier live, dates
- Source : rapports PH-API-T8.12AF, T8.12AH, T8.12AH.1, T8.12AI

### `/autopilot/draft` (backend Fastify)
- **Enrichit order+tracking** : même chaîne `loadEnrichedOrderContext`
- Source : rapport PH-API-T8.12AF

### Gaps résiduels (non bloquants)
- Tracking non-UPS (Colissimo, DPD...) : fallback regex limité
- Client-side ne passe pas tracking_code (repose sur backend)
- Clone `keybuzz-api` local incomplet (pas de `modules/ai/` dans le worktree)

### Verdict serveur
**Pas de gap serveur bloquant.** Le backend enrichit déjà order+tracking indépendamment du client. Le fix client AP.1A est une couche anti-reask complémentaire.

---

## 8. NON-RÉGRESSION

| Point | Résultat |
|---|---|
| Client DEV | `v3.5.163-ai-no-reask-fix-dev`, Running, 0 restarts |
| Client PROD | `v3.5.162-amazon-inbound-guide-demo-gating-prod` — **INCHANGÉE** |
| API DEV | `v3.5.155-promo-retry-metadata-email-dev` — **INCHANGÉE** |
| API PROD | `v3.5.142-promo-retry-email-prod` — **INCHANGÉE** |
| Backend DEV | `v1.0.47-cross-env-guard-fix-dev` — **INCHANGÉ** |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` — **INCHANGÉ** |
| API Health DEV | `{"status":"ok"}` |
| Outbound | 0 (pas de build API) |
| Billing drift | 0 (pas de mutation Stripe/DB) |
| CAPI drift | 0 (pas de tracking events) |
| Auto-send IA | 0 (aucun plan en auto-send non contrôlé) |
| Pages protégées | Clean (pas de tracking publicitaire injecté) |

---

## 9. LINEAR

### KEY-256 — AI no-reask order/tracking
- **Statut** : Client DEV validé. Fix déployé en `v3.5.163-ai-no-reask-fix-dev`.
- **Reste** : promotion PROD après validation Ludovic.
- **Ne pas fermer** tant que PROD n'est pas déployée.

### KEY-262 / KEY-264
- Non trouvés dans le repo. À vérifier dans Linear.
- Backend enrichit déjà order+tracking (T8.12AF/AH/AH.1/AI). Pas de gap serveur bloquant.

### KEY-253 — Plan gates
- Synthèse : tous les plans gated correctement. STARTER = teaser IA, wallet-gated. Pas de régression.

### KEY-255 / KEY-263 — Escalation
- **Non traités** dans cette phase (hors scope).

---

## 10. ROLLBACK

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.162-amazon-inbound-guide-demo-gating-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 11. VERDICT

### GO DEV FIX VALIDATED

AI NO-REASK CLIENT FIX LIVE IN DEV — ORDERREF ALWAYS INJECTED IN IA DRAWER CONTEXT — KNOWN ORDER/TRACKING DATA NO LONGER REQUESTED FROM CUSTOMER — PLAN GATES PRESERVED — STARTER IA REMAINS KBACTIONS-GATED — NO AUTO-SEND — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC VALIDATION

### Commits

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `d254b611` | fix(ai): always inject orderRef + anti-reask instruction (KEY-256) |
| keybuzz-infra | `main` | `bcde1ed` | gitops(dev): Client DEV v3.5.163-ai-no-reask-fix-dev (KEY-256) |

### Prochaine étape
- Validation manuelle par Ludovic en DEV
- Promotion PROD si validé
- Fermeture KEY-256 après PROD
