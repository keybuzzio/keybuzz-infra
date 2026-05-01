# PH-ADMIN-T8.12W — Admin Acquisition Baseline Spend and Runtime Truth Cleanup

**Date** : 2026-05-01
**Phase** : PH-ADMIN-T8.12W-ADMIN-ACQUISITION-BASELINE-SPEND-AND-RUNTIME-TRUTH-CLEANUP-01
**Type** : audit cible + patch Admin/docs + build/deploy Admin
**Priorite** : P1

---

## Objectif

Finaliser la coherence Admin apres PH-T8.12U/V :

1. Officialiser la baseline acquisition au 2026-05-01 00:00 Europe/Paris
2. Faire disparaitre les faux "new customers" / funnel test des vues par defaut via filtre de periode
3. Clarifier `/marketing/ad-accounts` : seuls Meta + Google connectes pour le spend
4. Verifier `/marketing/destinations` : TikTok PROD active, ancienne inactive, Meta/LinkedIn actifs
5. Verifier la coherence des pages acquisition-playbook, campaign-qa, integration-guide

---

## Preflight

### Repos

| Repo | Branche attendue | Branche constatee | HEAD | Dirty | Verdict |
|------|-----------------|-------------------|------|-------|---------|
| keybuzz-infra | main | main | `e577a07` | Non (untracked docs only) | OK |
| keybuzz-admin-v2 | main | main | `ecd221c` | Non | OK |

### Admin PROD avant

| Element | Valeur |
|---------|--------|
| Deployment | keybuzz-admin-v2 |
| Image runtime | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.36-tracking-truth-admin-prod` |
| Image manifest | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.36-tracking-truth-admin-prod` |
| Rollback | `v2.11.35-agency-launch-kit-prod` |

---

## Sources relues

- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md` (transcript)
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md` (transcript)
- `keybuzz-infra/docs/AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` (lu et modifie)
- `keybuzz-infra/docs/PH-T8.12U-CLIENT-COMBINED-SAMPLE-DEMO-TRACKING-PARITY-PROD-01.md` (transcript)
- `keybuzz-infra/docs/PH-ADMIN-T8.12V-TRACKING-TRUTH-DOCS-AND-ADMIN-WORDING-ALIGNMENT-01.md` (transcript)

---

## Audit Runtime Read-Only

### Destinations PROD

| Destination | Type | Pixel | Ad Account | Active | Conforme |
|-------------|------|-------|-----------|--------|----------|
| KeyBuzz Consulting — TikTok — 2026-05 cutover | tiktok_events | `D7PT12JC77U44OJIPC10` | `7634494806858252304` | **OUI** | OK (id `75a3c56a`) |
| KeyBuzz Consulting — TikTok (ancienne) | tiktok_events | `D7HQO0JC77U2ODPGMDI0` | `7629719710579130369` | **NON** | OK |
| KeyBuzz Consulting — Meta CAPI | meta_capi | `1234164602194748` | `1485150039295668` | **OUI** | OK |
| KeyBuzz Consulting — LinkedIn CAPI | linkedin_capi | conversion IDs JSONB | `514471703` | **OUI** | OK |

3 destinations soft-deleted (test/staging) — non visibles en usage normal.

### Ad Accounts PROD

| Platform | Account ID | Account Name | Status |
|----------|-----------|--------------|--------|
| Google | `5947963982` | KeyBuzz Google Ads | active |
| Meta | `1485150039295668` | KeyBuzz Consulting (legacy migration) | active |

TikTok et LinkedIn absents par design (pas de spend sync).

### Post-baseline (2026-05-01 00:00 Europe/Paris)

| Endpoint | Resultat |
|----------|----------|
| funnel/metrics | Tous steps = 0 |
| funnel/events | 0 events |
| metrics/overview | new_customers=0, spend.total_eur=0, spend_available=false |

---

## Patches appliques

### keybuzz-admin-v2 (commit `8ae3229`)

| # | Fichier | Correction |
|---|---------|------------|
| 1 | metrics/page.tsx | `useState('2026-01-01')` → `useState('2026-05-01')` + micro-copy baseline |
| 2 | marketing/funnel/page.tsx | `useState('2026-01-01')` → `useState('2026-05-01')` + micro-copy baseline |
| 3 | marketing/acquisition-playbook/page.tsx | "29 avril 2026" → "1er mai 2026" (5 occurrences), ajout mention cutover tracking |
| 4 | marketing/campaign-qa/page.tsx | "29 avril 2026" → "1er mai 2026" + mention cutover 29-30 avril |
| 5 | marketing/ad-accounts/page.tsx | Bloc explicatif "Pourquoi TikTok et LinkedIn n'apparaissent pas ici ?" |

### keybuzz-infra (commit `7010072`)

| # | Fichier | Correction |
|---|---------|------------|
| 1 | docs/AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md | Bloc PH-ADMIN-T8.12W : baseline, TikTok destination cutover, ad accounts, spend truth |

---

## Validation statique

| Check | Resultat |
|-------|----------|
| 0 Codex dans Admin | OK |
| 0 `utm_source=facebook` (hors interdiction) | OK |
| 0 `t.keybuzz.io` sGTM | OK (faux positifs `client.keybuzz.io` uniquement) |
| `t.keybuzz.pro` present | OK |
| 0 `AW-18098643667` (hors check QA) | OK (1 = logique de validation bloquante) |
| 0 `2026-01-01` dans defaults Metrics/Funnel | OK |
| `2026-05-01` present dans defaults | OK |
| TikTok spend pas presente actif | OK |
| LinkedIn spend pas presente connecte | OK |
| Google destination native absente | OK |

---

## Build

| Element | Valeur |
|---------|--------|
| Tag PROD | `v2.11.37-acquisition-baseline-truth-prod` |
| Source | `main @ 8ae3229` |
| Digest | `sha256:f434eed82abf01bdd6d5b5e4d082f569bac2357fe35dcd43e5778bffd6439c0a` |
| Build method | Clone temporaire propre `/tmp/build-admin-w/admin` sur bastion |
| Build args | `NEXT_PUBLIC_APP_ENV=production`, `NEXT_PUBLIC_API_URL=https://api.keybuzz.io` |
| Verification patches | 5/5 OK |

---

## GitOps Admin PROD

| Element | Valeur |
|---------|--------|
| Infra commit | `feac8f2` |
| Deployment | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.37-acquisition-baseline-truth-prod` |
| Rollback | `v2.11.36-tracking-truth-admin-prod` |
| Rollout | `deployment "keybuzz-admin-v2" successfully rolled out` |

### Admin PROD apres

| Element | Valeur |
|---------|--------|
| Image runtime | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.37-acquisition-baseline-truth-prod` |
| Image manifest | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.37-acquisition-baseline-truth-prod` |
| Match | Runtime = Manifest = Annotation |

---

## Linear

Linear unavailable (aucun MCP Linear configure). Tickets recommandes documentes ci-dessous.

### Tickets recommandes

| Priorite | Ticket | Description |
|----------|--------|-------------|
| P2 | TikTok ViewContent content_id | payload quality gap |
| P3 | TikTok Ads spend sync | Business API approval requis |
| P3 | LinkedIn Ads spend sync | Ads Reporting approval requis |

---

## Validation technique Ludovic

Validation technique confirmee par Ludovic :

- Admin PROD runtime = `v2.11.37-acquisition-baseline-truth-prod`
- Digest runtime = `sha256:f434eed82abf01bdd6d5b5e4d082f569bac2357fe35dcd43e5778bffd6439c0a`
- TikTok destination cutover active confirmee
- Ancienne destination TikTok inactive confirmee
- Meta CAPI / LinkedIn CAPI actifs confirmes
- Ad Accounts Google + Meta uniquement confirme coherent
- Post-baseline 2026-05-01 : new_customers=0, funnel=0, spend=0 confirme

Validation navigateur IDE visible des 7 pages : confirmee.

---

## Non-regression

| Check | Resultat |
|-------|----------|
| Aucun secret expose | OK |
| Aucun Codex visible | OK |
| Aucun faux event | OK |
| Aucun faux spend | OK |
| Aucune donnee PROD supprimee | OK |
| Client/API/Website/Backend non modifies | OK |
| Aucune destination reelle modifiee | OK |

---

## Rollback GitOps strict

En cas de rollback :

```yaml
# k8s/keybuzz-admin-v2-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.36-tracking-truth-admin-prod
```

```bash
git revert <commit>
git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout status deploy/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

---

## Gaps restants

| Priorite | Gap | Statut |
|----------|-----|--------|
| P2 | TikTok `content_id` manquant sur ViewContent | Non traite (hors scope) |
| P2 | TikTok spend bloque (Business API credentials) | Documente dans Admin |
| P3 | LinkedIn spend hors scope (Ads Reporting approval) | Documente dans Admin |
| P3 | Google destination native non implementee | Via sGTM/Addingwell |

---

## Artefacts

| Element | Valeur |
|---------|--------|
| Admin source commit | `8ae3229` |
| Infra memory commit | `7010072` |
| Infra GitOps commit | `feac8f2` |
| Rapport commit | (ce commit) |
| Image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.37-acquisition-baseline-truth-prod` |
| Digest | `sha256:f434eed82abf01bdd6d5b5e4d082f569bac2357fe35dcd43e5778bffd6439c0a` |
| Rollback | `v2.11.36-tracking-truth-admin-prod` |

---

## Verdict

**GO ADMIN ACQUISITION BASELINE AND SPEND TRUTH ALIGNED — VISUAL QA DONE**

ADMIN ACQUISITION BASELINE MOVED TO 2026-05-01 EUROPE/PARIS — METRICS AND FUNNEL DEFAULTS NO LONGER COUNT SETUP DATA — TIKTOK DESTINATION CUTOVER VERIFIED — AD ACCOUNTS SPEND TRUTH CLARIFIED — NO FAKE EVENT — NO FAKE SPEND — NO SECRET — GITOPS STRICT
