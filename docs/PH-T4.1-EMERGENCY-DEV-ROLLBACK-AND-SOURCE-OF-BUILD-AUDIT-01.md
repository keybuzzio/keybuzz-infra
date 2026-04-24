# PH-T4.1-EMERGENCY-DEV-ROLLBACK-AND-SOURCE-OF-BUILD-AUDIT-01 — TERMINE

**Verdict : DEV STABLE RESTORED — ROOT CAUSE IDENTIFIED**

**Date : 17 avril 2026**
**Priorite : CRITIQUE**

---

## Preflight


| Element                   | Image                                                                         |
| ------------------------- | ----------------------------------------------------------------------------- |
| Client DEV avant rollback | `ghcr.io/keybuzzio/keybuzz-client:v3.5.77-tracking-t4-client-dev`             |
| API DEV avant rollback    | `ghcr.io/keybuzzio/keybuzz-api:v3.5.77-tracking-t4-api-dev`                   |
| Backend DEV               | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-ph150-thread-fix-prod` (inchange)  |
| Client rollback cible     | `ghcr.io/keybuzzio/keybuzz-client:v3.5.75-ph151-step4.1-filters-collapse-dev` |
| API cible                 | conservee `v3.5.77-tracking-t4-api-dev` (non rollback)                        |


---

## Action Appliquee

### Rollback client

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.75-ph151-step4.1-filters-collapse-dev \
  -n keybuzz-client-dev
```

- **Resultat** : `deployment "keybuzz-client" successfully rolled out`
- **Pod** : `keybuzz-client-58f849b7bc-jzm7v` Running 1/1
- **Image finale** : `v3.5.75-ph151-step4.1-filters-collapse-dev`
- **API** : non touchee (conservee a `v3.5.77-tracking-t4-api-dev`)

---

## Validation Apres Rollback


| Zone                 | Etat apres rollback                                               |
| -------------------- | ----------------------------------------------------------------- |
| `/start`             | **PRESENT** (page.js 14.5KB)                                      |
| `dashboard`          | **PRESENT** (page.js 27.8KB)                                      |
| `supervision`        | **PRESENT** (SupervisionPanel + settings/ai-supervision + chunks) |
| `autopilot`          | **PRESENT** (api/autopilot/draft, evaluate, history, settings)    |
| `resume/summary`     | **PRESENT** dans dashboard/page.js                                |
| `settings/agents`    | **PRESENT** (agents, ai-supervision, billing, tenant)             |
| `settings/signature` | **PRESENT** dans settings/page.js                                 |
| `inbox`              | **PRESENT** (page.js + [conversationId])                          |
| `API_URL`            | `api-dev.keybuzz.io` correct                                      |
| API health           | `{"status":"ok"}`                                                 |


**Conclusion : le client DEV est redevenu coherent. L'API n'a pas eu besoin de rollback.**

---

## Audit Provenance

### Source du build PH-T4 client


| Element                                                      | Valeur                  |
| ------------------------------------------------------------ | ----------------------- |
| Branche build PH-T4                                          | `ph152.6-client-parity` |
| Commit build PH-T4                                           | `e5f5f54`               |
| Nombre de commits dans cette branche (depuis ancetre commun) | 30                      |


### Source du build baseline saine


| Element                                                      | Valeur                                       |
| ------------------------------------------------------------ | -------------------------------------------- |
| Branche saine                                                | `ph148/onboarding-activation-replay`         |
| Commit saine                                                 | `5f3f16f` (PH151.2.2)                        |
| Nombre de commits dans cette branche (depuis ancetre commun) | 50                                           |
| Image produite                                               | `v3.5.75-ph151-step4.1-filters-collapse-dev` |


### Ancetre commun


| Element | Valeur                                                                                    |
| ------- | ----------------------------------------------------------------------------------------- |
| Commit  | `8542bf0`                                                                                 |
| Message | `PH131-B.2: rename Autopilot to Pilotage IA, STARTER upsell preview with locked features` |
| Date    | Pre-PH147 (etat ancien)                                                                   |


### Divergence

Les deux branches ont diverge a partir de `8542bf0` (PH131-B.2) :

- `**ph148/onboarding-activation-replay`** a accumule **50 commits** incluant :
  - PH147.5 autopilot functional recovery
  - PH148 onboarding activation replay
  - PH149/PH150 stabilisation
  - PH151 inbox intelligence (AICaseSummary, ConversationSummaryBar, MessageFilter, etc.)
  - PH151.1-STEP1 a STEP4.1 (supervision, summary, filters, collapsible)
  - PH151.2 nettoyage
- `**ph152.6-client-parity`** a accumule **30 commits** incluant :
  - PH-STUDIO (sous-projet keybuzz-studio) - **PAS en production SaaS**
  - PH-PLAYBOOKS, PH-BILLING-TRUTH, PH-AMZ - patches anciens
  - PH131-C autopilot badge
  - PH142 SLA/RBAC
  - PH145.4 Amazon channel
  - PH147 guardrails sync
  - PH152.6 "parity" atomique (22 fichiers seulement)
  - **PH-T1, PH-T3, PH-T4 tracking** (les 4 derniers commits)

### Delta fichiers critiques


| Domaine                   | Branche saine (ph148)                                | Branche PH-T4 (ph152.6)                              | Verdict               |
| ------------------------- | ---------------------------------------------------- | ---------------------------------------------------- | --------------------- |
| `/start` page             | Mise a jour PH148+                                   | Etat ancien PH131                                    | **REGRESSION**        |
| Dashboard supervision     | SupervisionPanel PH151+                              | Version ancienne                                     | **REGRESSION**        |
| Autopilot routes          | draft/consume, evaluate v2                           | Absent (draft/consume)                               | **REGRESSION**        |
| Inbox summary/filter      | AICaseSummary, MessageFilter, ConversationSummaryBar | Absent ou ancien                                     | **REGRESSION**        |
| Settings agents/signature | PH151+                                               | Ancien                                               | **REGRESSION**        |
| Onboarding                | useOnboardingState hook PH151                        | Absent                                               | **REGRESSION**        |
| Tracking PH-T1/T3/T4      | Absent                                               | Present (attribution.ts, tracking.ts, SaaSAnalytics) | Valide mais mal place |


**Total diff entre les deux branches : 277 fichiers modifies, 4 753 insertions, 45 868 deletions.**

---

## Cause Racine

### Diagnostic

**La branche `ph152.6-client-parity` est une branche ancienne basee sur l'etat PH131 (pre-PH147).**

Elle a ete creee comme un effort de "parite" qui n'a capture qu'un sous-ensemble de 22 fichiers valides, sans recuperer les 50 commits fonctionnels de la branche saine `ph148/onboarding-activation-replay` (PH147 -> PH151).

Les commits tracking PH-T1, PH-T3 et PH-T4 ont ete appliques **sur cette branche ancienne** au lieu de la branche saine.

### Resume en une phrase

> **Les patches tracking ont ete appliques sur une branche qui ne contenait pas les 50 derniers commits fonctionnels (PH147-PH151), ce qui a produit un build client dans un etat pre-supervision/pre-autopilot/pre-summary.**

### Facteurs contributifs

1. **Mauvaise branche source** : `ph152.6-client-parity` n'est PAS la branche de reference pour le client DEV sain
2. **Workspace local Windows desynchro** : le workspace `c:\DEV\KeyBuzz\V3` est sur `ph152.6-client-parity`, pas sur `ph148/onboarding-activation-replay`
3. **Build discipline partielle** : la discipline de build (repo clean, commit, push) a ete respectee, mais la **source de verite** etait incorrecte
4. **Absence de verification de baseline** : aucune comparaison entre l'image deployee avant intervention et le contenu de la branche de build n'a ete faite

---

## Plan de Replay Tracking Sans Casse

### Strategie

Rejouer PH-T1/T3/T4 client sur la branche saine, en cherry-pickant uniquement les fichiers tracking.


| Phase | Action                                                    | Service | Risque                                                                                        |
| ----- | --------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------- |
| 1     | Checkout `ph148/onboarding-activation-replay` sur bastion | client  | Nul (lecture)                                                                                 |
| 2     | Cherry-pick `ec32d98` (PH-T1 attribution)                 | client  | Faible — fichier nouveau `src/lib/attribution.ts`                                             |
| 3     | Cherry-pick `9723eef` (PH-T3 GA4/Meta)                    | client  | Faible — fichiers nouveaux `src/lib/tracking.ts`, `src/components/tracking/SaaSAnalytics.tsx` |
| 4     | Cherry-pick `65c11ee` (PH-T3 type fix)                    | client  | Nul — correction de type                                                                      |
| 5     | Cherry-pick `e5f5f54` (PH-T4 checkout attribution)        | client  | Faible — 2 fichiers modifies, changements minimaux                                            |
| 6     | Build `--no-cache` avec build-args GA4/Meta               | client  | Moyen — verifier compilation                                                                  |
| 7     | Deploy DEV + validation fonctionnelle complete            | client  | Moyen — verifier pas de regression                                                            |
| 8     | Conserver API `v3.5.77-tracking-t4-api-dev`               | API     | Nul — pas de changement                                                                       |


### Fichiers tracking a reporter (exhaustif)


| Fichier                                     | Source            | Type                                             |
| ------------------------------------------- | ----------------- | ------------------------------------------------ |
| `src/lib/attribution.ts`                    | PH-T1 (`ec32d98`) | NOUVEAU                                          |
| `src/lib/tracking.ts`                       | PH-T3 (`9723eef`) | NOUVEAU                                          |
| `src/components/tracking/SaaSAnalytics.tsx` | PH-T3 (`9723eef`) | NOUVEAU                                          |
| `app/layout.tsx`                            | PH-T3 (`9723eef`) | MODIFIE (import SaaSAnalytics)                   |
| `app/register/page.tsx`                     | PH-T3 + PH-T4     | MODIFIE (tracking events + attribution checkout) |
| `app/register/success/page.tsx`             | PH-T3 (`9723eef`) | MODIFIE (trackPurchase)                          |
| `app/api/billing/checkout-session/route.ts` | PH-T4 (`e5f5f54`) | MODIFIE (forward attribution)                    |


### Domaines fonctionnels a NE PAS toucher

- `app/start/` — ne pas modifier
- `app/dashboard/` — ne pas modifier
- `app/inbox/` — ne pas modifier
- `app/settings/` — ne pas modifier
- `src/features/dashboard/` — ne pas modifier
- `src/features/inbox/` — ne pas modifier
- `src/services/agents.service.ts` — ne pas modifier

### Prerequis avant replay

1. Verifier que `ph148/onboarding-activation-replay` @ `5f3f16f` compile (`npm run build`)
2. Verifier que les cherry-picks s'appliquent sans conflit
3. Si conflit : resoudre manuellement en ne touchant QUE les fichiers tracking
4. Build + test DEV complet avant toute promotion

---

## Etat Final


| Element                 | Image                                                  | Status                                       |
| ----------------------- | ------------------------------------------------------ | -------------------------------------------- |
| Client DEV              | `v3.5.75-ph151-step4.1-filters-collapse-dev`           | **STABLE**                                   |
| API DEV                 | `v3.5.77-tracking-t4-api-dev`                          | **OPERATIONNELLE** (tracking API fonctionne) |
| Backend DEV             | `v1.0.44-ph150-thread-fix-prod`                        | **INCHANGE**                                 |
| PROD                    | Non touche                                             | **SAFE**                                     |
| DB `signup_attribution` | Intacte                                                | **CONSERVEE**                                |
| Tracking client-side    | **INACTIF** (rollback a supprime GA4/Meta/attribution) | A rejouer                                    |
| Tracking API-side       | **ACTIF** (Stripe metadata + webhook ready)            | Operationnel                                 |


---

## Conclusion

- Client DEV restaure a un etat sain et coherent
- API DEV conservee (tracking Stripe operationnel)
- Cause racine identifiee : **mauvaise branche source pour le build client tracking**
- Plan de replay documente : cherry-pick des 4 commits tracking sur la branche saine
- Aucune autre action effectuee

STOP