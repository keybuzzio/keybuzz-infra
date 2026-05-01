# PH-SAAS-T8.12N.4 — Sample Demo Wow PROD Promotion

> Phase : PH-SAAS-T8.12N.4-SAMPLE-DEMO-WOW-PROD-PROMOTION-01
> Date : 2026-05-01
> Environnement : PROD
> Type : promotion PROD Client — Sample Demo Wow UI non polluante
> Priorite : P0

---

## Sources relues

- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`
- `keybuzz-infra/docs/AI_MEMORY/SAAS_TRIAL_WOW_AND_PRODUCT_CONTEXT.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N-SAMPLE-DATA-NON-POLLUTING-WOW-DESIGN-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.1-SAMPLE-DEMO-CLIENT-FOUNDATION-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.2-SAMPLE-DEMO-WOW-UI-INTEGRATION-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.3-SAMPLE-DEMO-LAMBDA-RUNTIME-VALIDATION-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.3.1-SAMPLE-DEMO-MOBILE-OVERFLOW-HOTFIX-DEV-01.md`

---

## Preflight

| Repo | Branche attendue | Branche constatee | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|---|
| `keybuzz-infra` | `main` | `main` | `256551e` | Non | OK |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `a5d8656` | `tsconfig.tsbuildinfo` only | OK |

| Service | ENV | Image manifest | Image runtime | Match ? |
|---|---|---|---|---|
| Client | DEV | `v3.5.142-sample-demo-mobile-overflow-dev` | `v3.5.142-sample-demo-mobile-overflow-dev` | OK |
| Client | PROD | `v3.5.139-onboarding-cleanup-prod` | `v3.5.139-onboarding-cleanup-prod` | OK |
| API | PROD | `v3.5.128-trial-autopilot-assisted-prod` | `v3.5.128-trial-autopilot-assisted-prod` | OK |
| Website | PROD | `v0.6.7-pricing-attribution-forwarding-prod` | `v0.6.7-pricing-attribution-forwarding-prod` | OK |

---

## Source verifiee

| Brique | Point verifie | Resultat |
|---|---|---|
| `sampleData.ts` | Fichier present, IDs prefixes `demo-` | OK |
| `useDemoMode.ts` | Fichier present | OK |
| `DemoBanner.tsx` | Textes marques "exemples" / "demonstration" | OK |
| `DemoInboxExperience.tsx` | Hotfix mobile master/detail (6 patterns) | OK |
| `DemoDashboardPreview.tsx` | Fichier present | OK |
| `DemoOnboardingCard.tsx` | Fichier present | OK |
| `index.ts` | 7 exports composants/hooks + 5 types | OK |
| Inbox integration | `useDemoMode` + `DemoInboxExperience` | OK |
| Dashboard integration | `useDemoMode` + `DemoDashboardPreview` | OK |
| Onboarding integration | `DemoOnboardingCard` | OK |
| API write | 0 appel POST/PUT/PATCH/DELETE | OK |
| Tracking/CAPI | 0 import | OK |
| `codex` | 0 | OK |
| `AW-18098643667` | 0 | OK |
| Secrets | 0 | OK |
| IDs sample `demo-` | Confirme | OK |
| Textes marques | "Simulation", "Exemple", "Apercu" | OK |

---

## Build PROD

| Element | Valeur |
|---|---|
| Commit client | `a5d8656` |
| Tag PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.142-sample-demo-wow-prod` |
| Digest PROD | `sha256:844131507b82fb51a9c5574ecd0f123f485a3a8e0d8e0c914240626e25ab58cc` |
| Source build | Clone temporaire propre `/tmp/keybuzz-client-build-prod-n4` |
| Pre-build clean | `rm -rf` avant clone |
| Build-from-git | Oui (clone + verify HEAD = `a5d8656`) |
| Build-args PROD | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production` |

---

## GitOps PROD

| Element | Valeur |
|---|---|
| Commit infra | `8b04b54` |
| Image avant | `v3.5.139-onboarding-cleanup-prod` |
| Image apres | `v3.5.142-sample-demo-wow-prod` |
| Runtime image | `v3.5.142-sample-demo-wow-prod` |
| Rollback PROD | `v3.5.139-onboarding-cleanup-prod` |
| Rollout | `deployment "keybuzz-client" successfully rolled out` |

---

## Validation PROD structurelle

| Check | Attendu | Resultat |
|---|---|---|
| Pod Running 1/1 | Oui | `keybuzz-client-84f7bddfb8-8jhbz 1/1 Running` |
| Restarts post-rollout | 0 | **0** |
| Client PROD health | HTTP 200 | **200** |
| API PROD health | `{"status":"ok"}` | **OK** |
| `codex` dans bundle | 0 | **0** |
| `AW-18098643667` dans bundle | 0 | **0** |
| `api-dev.keybuzz.io` dans bundle | 0 | **0** |
| `sk_live`/`sk_test` dans bundle | 0 | **0** |
| API PROD inchangee | `v3.5.128-trial-autopilot-assisted-prod` | **OK** |
| Website PROD inchange | `v0.6.7-pricing-attribution-forwarding-prod` | **OK** |
| Backend PROD inchange | `v1.0.46-ph-recovery-01-prod` | **OK** |

---

## Validation navigateur PROD

### Tenant reel (eComLG PROD)

| Tenant | Route | Viewport | Attendu | Resultat |
|---|---|---|---|---|
| eComLG (482 conv) | `/dashboard` | desktop | Dashboard reel, 0 demo | OK (API total=482 → isDemoMode=false) |
| eComLG | `/inbox` | desktop | InboxTripane reel, 0 demo | OK |
| eComLG | `/onboarding` | desktop | Onboarding data-aware reel | OK |

### Tenant vide PROD

**GO PARTIEL** : Aucun tenant vide PROD sur disponible sans risque.

La logique `useDemoMode` est identique (meme commit `a5d8656`), validee en DEV :
- tenant vide DEV `test-lambda-k1-sas-molcr3ha` (0 conv) → demo visible
- dismiss tenant-scoped via `localStorage.setItem('kb_demo_dismissed:v1:${tenantId}', 'true')`
- mobile master/detail valide (classes dans bundle PROD confirme)

Logique conditionnelle : `conversationCount === 0` → `isDemoMode = true`
Le prochain tenant vide qui se connectera en PROD verra automatiquement la demo.

### Bundle mobile

| Check | Resultat |
|---|---|
| master/detail classes (`handleBack`, `md:w-72`, `md:hidden`) | Present dans 1 chunk |
| `useDemoMode` (`kb_demo_dismissed`) | Present dans 1 chunk |
| PROD API URL (`api.keybuzz.io`) | Present dans 1 chunk |

---

## Non-pollution PROD

| Surface | Attendu | Resultat |
|---|---|---|
| DB `conversations WHERE id LIKE 'demo-%'` | 0 | **0** |
| DB `messages WHERE conversation_id LIKE 'demo-%'` | 0 | **0** |
| `billing_events` | Aucun post-promotion (dernier: 29 avr) | **OK** |
| `ai_action_log` | Aucun faux event (dernier: 30 avr, tenant reel) | **OK** |
| `billing_subscriptions` | Aucune nouvelle post-promotion | **OK** |
| CAPI / faux signup | 0 (pas de code tracking dans module demo) | **OK** |
| Stripe | Aucun checkout/purchase post-promotion | **OK** |
| GA4/Ads | Aucun faux event conversion | **OK** |

---

## Non-regression

| Surface | Attendu | Resultat |
|---|---|---|
| `/login` PROD | 200 | **200** |
| `/signup` PROD | 200 | **200** |
| `/pricing` PROD | 200 | **200** |
| `/inbox` PROD | 307 | **307** |
| `/dashboard` PROD | 307 | **307** |
| `/onboarding` PROD | 307 | **307** |
| `/start` PROD | 307 | **307** |
| `/billing/plan` PROD | 307 | **307** |
| `/channels` PROD | 307 | **307** |
| API PROD health | `{"status":"ok"}` | **OK** |
| Website PROD | 200 | **200** |
| Client DEV routes | Inchangees | **OK** |
| API DEV health | `{"status":"ok"}` | **OK** |

---

## Rollback GitOps PROD

En cas de regression :

```yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.139-onboarding-cleanup-prod
```

---

## Confirmation API/Website/Admin inchanges

| Service | Image PROD | Status |
|---|---|---|
| API | `v3.5.128-trial-autopilot-assisted-prod` | **Inchangee** |
| Website | `v0.6.7-pricing-attribution-forwarding-prod` | **Inchange** |
| Backend | `v1.0.46-ph-recovery-01-prod` | **Inchange** |

---

## Gaps restants

1. **Tenant vide PROD** : aucun tenant vide PROD sur disponible pour validation navigateur live. La logique est prouvee en DEV (meme commit, meme code). Le prochain nouveau trial activera automatiquement la demo. **Severite : faible.**

---

## Historique des phases N.x

| Phase | Description | Env | Verdict |
|---|---|---|---|
| N | Design Option E — client-side only | - | GO |
| N.1 | Foundation demo module (7 fichiers) | DEV | GO |
| N.2 | Integration UI inbox/dashboard/onboarding | DEV | GO |
| N.3 | Validation runtime tenant reel vs vide | DEV | GO |
| N.3.1 | Hotfix mobile overflow inbox demo | DEV | GO |
| **N.4** | **Promotion PROD** | **PROD** | **GO PARTIEL** |

---

## Rapport

`keybuzz-infra/docs/PH-SAAS-T8.12N.4-SAMPLE-DEMO-WOW-PROD-PROMOTION-01.md`

---

## Verdict

```
SAMPLE DEMO WOW LIVE IN PROD
EMPTY TENANTS GET NON-POLLUTING GUIDED EXPERIENCE
REAL TENANTS STAY REAL
MOBILE SAFE
NO DB/API/TRACKING/BILLING/CAPI DRIFT
GITOPS STRICT
GO PARTIEL — tenant vide PROD non testable (logique prouvee en DEV)
```
