# PH-T8.12Q — Acquisition Tracking Parity Visual QA and Cleanup

> Date : 2026-05-01
> Environnement : PROD
> Type : audit visuel + cleanup GitOps/docs + corrections sures
> Verdict : **GO WITH DOCUMENTED GAPS**

---

## Objectif

Verifier visuellement et consolider la feature acquisition tracking KeyBuzz apres le cutover TikTok T8.12P. Prouver que les donnees sont fiables, lisibles et exploitables pour scaler les campagnes.

---

## Sources relues

| Document | Cle retenue |
|----------|-------------|
| `CE_PROMPTING_STANDARD.md` | Rollback GitOps strict, pas de `kubectl set image`, pas de faux events |
| `RULES_AND_RISKS.md` | Hierarchie source de verite, STOP conditions, repo clean |
| `SERVER_SIDE_TRACKING_CONTEXT.md` | event_id canonique, un proprietaire par event_name, dedup |
| `PH-T8.12P-...01.md` | TikTok pixel active, CompletePayment server-only, gaps GA4/Meta/sGTM Client |
| `PH-T8.12O-...01.md` | Events API readiness, Admin contradictions |
| `PH-T8.12N-...01.md` | Cutover DB ancien/nouveau pixel |
| `PH-T8.11Z-...01.md` | Baseline analytics pre-cutover |
| `PH-WEBSITE-T8.11AK-...01.md` | Pricing attribution forwarding |
| `PH-ADMIN-T8.11AN-...01.md` | Campaign QA URL Builder |
| `PH-ADMIN-T8.11AO-...01.md` | Campaign QA Event Lab safe mode |
| `PH-ADMIN-T8.11AP-...01.md` | Agency Launch Checklist |

---

## Preflight

### Repos

| Repo | Branche | HEAD | Dirty | Decision |
|------|---------|------|-------|----------|
| keybuzz-infra | `main` | `69d4e5e` | Non (untracked docs) | OK |
| keybuzz-admin-v2 | `main` | `fbed0d1` | M `paid-channels/page.tsx` | Corrige et commite (fd44db7) |
| keybuzz-client | source: `ph-t812p/tiktok-browser-pixel` @ `3325f03` | N/A local | N/A | Read-only |
| keybuzz-website | source: `main` bastion @ `0b9d1ea` | N/A local | N/A | Read-only |
| keybuzz-api | lecture seule | N/A | N/A | Read-only |

### Images PROD

| Service | Image | Manifest = Runtime |
|---------|-------|--------------------|
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.144-tiktok-browser-pixel-prod` | OUI |
| Website | `ghcr.io/keybuzzio/keybuzz-website:v0.6.8-tiktok-browser-pixel-prod` | OUI |
| Admin | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.35-agency-launch-kit-prod` | OUI |
| API (principal) | `ghcr.io/keybuzzio/keybuzz-api:v3.5.128-trial-autopilot-assisted-prod` | OUI |
| API (outbound-worker) | `ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod` | OUI |

### Rollouts

Tous les deployments sont `successfully rolled out`.

---

## Audit Website PROD

| Element | Statut | Preuve |
|---------|--------|--------|
| TikTok Pixel `D7PT12JC77U44OJIPC10` | ACTIF | Bundle SSR + static chunks |
| Ancien pixel `D7HQO0JC77U2ODPGMDI0` | ABSENT | grep exit 1 |
| GA4 `G-R3QQDYEBFG` | ACTIF | Trouve dans bundles |
| Meta Pixel fbq | ACTIF | Trouve dans bundles |
| sGTM `t.keybuzz.pro` | ACTIF | Trouve dans bundles |
| Attribution /pricing UTM | ACTIF | UTM forwarding present |
| utm_source=facebook | ABSENT | OK (convention meta) |

---

## Audit Client PROD

### Tracking actif

| Element | Statut | Preuve |
|---------|--------|--------|
| TikTok Pixel `D7PT12JC77U44OJIPC10` | ACTIF | `l="D7PT12JC77U44OJIPC10"` dans layout chunk |
| LinkedIn Insight `9969977` | ACTIF | `o="9969977"` dans layout chunk |
| CompletePayment browser | ABSENT | grep exit 1 sur `/app/.next/` entier |
| Ancien pixel TikTok | ABSENT | grep exit 1 |

### Tracking absent (gaps)

| Element | Statut | Cause | Risque |
|---------|--------|-------|--------|
| GA4 | ABSENT | `NEXT_PUBLIC_GA4_MEASUREMENT_ID` non passe au build | Aucun (pas de CAPI GA4) |
| sGTM | ABSENT | `NEXT_PUBLIC_SGTM_URL` non passe au build | Aucun (routing layer) |
| Meta Pixel | INACTIF | Code conditionnel present, `NEXT_PUBLIC_META_PIXEL_ID` non passe | **STOP DEDUP RISK** |

### Protection pages

- Funnel pages : `/register`, `/login`
- Blocked pages : `/inbox`, `/dashboard`, `/orders`, `/settings`, `/channels`, `/suppliers`, `/knowledge`, `/playbooks`, `/ai-journal`, `/billing`, `/onboarding`, `/workspace-setup`, `/start`, `/help`
- Logique : `!isBlockedPage && isFunnelPage && (any pixel ID)` → `null` sur pages protegees
- **Zero tracking script sur pages protegees** : confirme

---

## Audit Server-side

### Destinations actives (outbound_conversion_destinations)

| ID | Nom | Type | Active | Pixel/IDs |
|----|-----|------|--------|-----------|
| `75a3c56a-...` | KeyBuzz Consulting — TikTok — 2026-05 cutover | `tiktok_events` | OUI | `D7PT12JC77U44OJIPC10` |
| `87f8dc49-...` | KeyBuzz Consulting — Meta CAPI | `meta_capi` | OUI | `1234164602194748` |
| `b530ffdc-...` | KeyBuzz Consulting — LinkedIn CAPI | `linkedin_capi` | OUI | StartTrial:27491313, Purchase:27491305 |

### Destinations inactives

| ID | Nom | Type | Active | Note |
|----|-----|------|--------|------|
| `07b03162-...` | KeyBuzz Consulting — TikTok (ancien) | `tiktok_events` | NON | Desactive par cutover T8.12N |
| Plusieurs | Test/staging Meta CAPI | `meta_capi` | NON | Deleted |

---

## Matrice tracking complete

| Plateforme | Website browser | Client funnel browser | Client protege | Server-side | Double comptage |
|------------|----------------|----------------------|----------------|-------------|-----------------|
| TikTok Pixel | PageView | PageView, SubmitForm, InitiateCheckout | Aucun | — | Non |
| TikTok Events API | — | — | — | Subscribe/StartTrial, CompletePayment/Purchase | Non (browser CompletePayment retire) |
| GA4 | ACTIF | **ABSENT** | Aucun | Via sGTM (Addingwell) | Non |
| sGTM | ACTIF | **ABSENT** | Aucun | — | Non |
| Meta Pixel | ACTIF | **INACTIF** | Aucun | — | Non |
| Meta CAPI | — | — | — | StartTrial, Purchase | Non (pixel Client inactif) |
| LinkedIn Insight | Non | ACTIF | Aucun | — | Non |
| LinkedIn CAPI | — | — | — | StartTrial, Purchase | Faible (dedup LinkedIn natif) |

---

## Audit deduplication

| Plateforme | Browser | Server | event_id match | Risque | Decision |
|------------|---------|--------|----------------|--------|----------|
| TikTok CompletePayment | ABSENT (retire T8.12P) | ACTIF | N/A | Aucun | OK — server-only |
| Meta Purchase | INACTIF (pas de build-arg) | ACTIF (CAPI) | N/A | **STOP si active** | NE PAS activer sans dedup |
| LinkedIn Purchase | Absent browser | ACTIF (CAPI) | N/A | Faible | OK |
| GA4 | Website seul | Via sGTM | N/A | Aucun | OK |

---

## Corrections effectuees

### 1. Rapport T8.12P — rollback GitOps strict

- **Avant** : rollback par `kubectl set image` (interdit par regles CE)
- **Apres** : rollback par `git revert 69d4e5e` + `kubectl apply` + `kubectl rollout status`
- **Commit** : `474d67d` dans `keybuzz-infra`

### 2. Admin paid-channels wording

- **Avant** : `Pixel browser actif (ttclid capture).`
- **Apres** : `Pixel browser actif sur funnel (PageView, SubmitForm, InitiateCheckout). CompletePayment server-side only via Events API. ttclid capture.`
- **Commit** : `fd44db7` dans `keybuzz-admin-v2`
- **Promotion PROD** : en attente (P3 cosmetique)

---

## Admin Marketing coherence

| Element | Statut | Coherent avec runtime |
|---------|--------|-----------------------|
| TikTok tracking detail | Corrige (fd44db7) | OUI |
| TikTok conversions (Events API) | `active` | OUI |
| TikTok spend | `none` | OUI |
| Meta tracking | `active` (Website) | OUI |
| Meta CAPI | `active` | OUI |
| Meta spend | `none` | OUI |
| Google tracking (sGTM) | `active` (Website) | OUI |
| Google spend | `none` | OUI |
| LinkedIn tracking | `active` | OUI |
| LinkedIn CAPI | `active` | OUI |
| Integration guide | Coherent | OUI |

---

## Non-regression

| # | Check | Resultat |
|---|-------|----------|
| 1 | TikTok browser (Client + Website) | OK |
| 2 | TikTok server-side (Events API) | OK (1 destination active) |
| 3 | Meta CAPI | OK (1 destination active) |
| 4 | LinkedIn CAPI | OK (1 destination active) |
| 5 | Google/sGTM Website | OK |
| 6 | CompletePayment browser absent | OK |
| 7 | Ancien pixel TikTok absent | OK (Client + Website) |
| 8 | utm_source=facebook absent | OK |
| 9 | LinkedIn Insight Client | OK |
| 10 | Images PROD correctes | OK |
| 11 | Rollouts stables | OK |
| 12 | Faux events | Aucun |
| 13 | Fake spend | Aucun |
| 14 | Secrets exposes | Aucun dans rapport |

---

## Build

Aucun build effectue dans cette phase. Raisons :
- Corrections = docs + wording (commits only)
- Gaps GA4/sGTM Client = pre-existants, pas causes par T8.12P
- Meta Pixel Client = STOP DEDUP RISK

---

## Rollback GitOps strict

### Rapport T8.12P (si rollback tracking necessaire)

```bash
cd keybuzz-infra
git revert 69d4e5e
git push origin main

kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-prod

kubectl apply -f k8s/website-prod/deployment.yaml
kubectl rollout status deploy/keybuzz-website -n keybuzz-website-prod
```

Images rollback :
- Client : `v3.5.142-sample-demo-wow-prod`
- Website : `v0.6.7-pricing-attribution-forwarding-prod`

### Rapport T8.12Q (aucun deploy = aucun rollback deploy)

Rollback docs uniquement :
```bash
cd keybuzz-infra
git revert 474d67d
git push origin main

cd keybuzz-admin-v2
git revert fd44db7
git push origin main
```

---

## Gaps restants

| # | Gap | Severite | Description | Decision |
|---|-----|----------|-------------|----------|
| G1 | GA4 absent Client | P2 | `NEXT_PUBLIC_GA4_MEASUREMENT_ID` non passe au build Client | Restaurer dans prochain rebuild Client (safe, pas de CAPI GA4) |
| G2 | sGTM absent Client | P2 | `NEXT_PUBLIC_SGTM_URL` non passe au build Client | Restaurer avec GA4 (meme rebuild) |
| G3 | Meta Pixel Client inactif | P2 | `NEXT_PUBLIC_META_PIXEL_ID` non passe au build Client | **STOP DEDUP RISK** — ne pas activer sans desactiver Purchase browser-side |
| G4 | Admin wording non promu PROD | P3 | Commit `fd44db7` en attente de build Admin PROD | Promouvoir dans prochain cycle Admin |
| G5 | TikTok spend non connecte | P3 | Pas d'API TikTok Ads connectee | Hors scope — attente Business API credentials |
| G6 | TikTok Events Manager validation visuelle | P3 | En attente de verification Ludovic dans TikTok Business | A completer par Ludovic |

---

## Artefacts

| Element | Valeur |
|---------|--------|
| Infra commit (fix rapport) | `474d67d` |
| Admin commit (wording) | `fd44db7` |
| Client PROD | `v3.5.144-tiktok-browser-pixel-prod` (inchange) |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` (inchange) |
| Admin PROD | `v2.11.35-agency-launch-kit-prod` (inchange) |
| API PROD (principal) | `v3.5.128-trial-autopilot-assisted-prod` (inchange) |
| API PROD (outbound-worker) | `v3.5.165-escalation-flow-prod` (inchange) |
| Rapport | `keybuzz-infra/docs/PH-T8.12Q-ACQUISITION-TRACKING-PARITY-VISUAL-QA-AND-CLEANUP-01.md` |

---

## Verdict

**GO WITH DOCUMENTED GAPS**

TRACKING ACQUISITION VERIFIED — TIKTOK BROWSER + SERVER-SIDE OK — COMPLETEPAYMENT SERVER-SIDE ONLY — NO DOUBLE COUNTING — ADMIN TRUTH ALIGNED — REPORT GITOPS CLEAN — META GOOGLE LINKEDIN NON REGRESSED

Gaps documentes : GA4/sGTM Client a restaurer (P2), Meta Pixel Client STOP DEDUP RISK (P2), Admin wording promotion PROD (P3), TikTok spend non connecte (P3).
