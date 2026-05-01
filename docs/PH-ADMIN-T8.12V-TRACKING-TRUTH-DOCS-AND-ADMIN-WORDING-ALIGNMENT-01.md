# PH-ADMIN-T8.12V — Tracking Truth Docs and Admin Wording Alignment

**Date** : 2026-05-01
**Phase** : PH-ADMIN-T8.12V-TRACKING-TRUTH-DOCS-AND-ADMIN-WORDING-ALIGNMENT-01
**Type** : audit cible + patch wording/docs + build/deploy Admin
**Priorite** : P1

---

## Objectif

Aligner les pages Admin Marketing et la memoire projet avec la verite finale PH-T8.12U :

- Client PROD combine : `v3.5.147-sample-demo-platform-aware-tracking-parity-prod`
- GA4, sGTM, TikTok Pixel, LinkedIn Insight Tag, Meta Pixel — tous actifs sur le funnel
- Meta `Purchase` et TikTok `CompletePayment` — server-side only
- Pages protegees clean
- TikTok spend bloque, LinkedIn spend hors scope

---

## Preflight

### Repos

| Repo | Branche attendue | Branche constatee | HEAD | Dirty | Verdict |
|------|-----------------|-------------------|------|-------|---------|
| keybuzz-infra | main | main | `e1a4410` | OUI (1 doc) | Commite avant travail (`223d150`) |
| keybuzz-admin-v2 | main | main | `fd44db7` | Non | OK |

### Admin PROD avant

| Element | Valeur |
|---------|--------|
| Deployment | keybuzz-admin-v2 |
| Image runtime | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.35-agency-launch-kit-prod` |
| Image manifest | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.35-agency-launch-kit-prod` |
| Rollback | `v2.11.34-campaign-qa-event-lab-prod` |

---

## Sources relues

- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md` (transcript)
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md` (transcript)
- `keybuzz-infra/docs/AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` (lu et modifie)
- `keybuzz-infra/docs/PH-T8.12U-CLIENT-COMBINED-SAMPLE-DEMO-TRACKING-PARITY-PROD-01.md` (transcript)
- `keybuzz-infra/docs/PH-T8.12S-META-CLIENT-PIXEL-DEDUP-READINESS-AND-SAFE-ACTIVATION-01.md` (transcript)
- `keybuzz-infra/docs/PH-T8.12Q.2-TIKTOK-EVENTS-MANAGER-TEST-CODE-CLOSURE-01.md` (transcript)
- `keybuzz-infra/docs/PH-ADMIN-T8.11AP-AGENCY-LAUNCH-CHECKLIST-AND-OPERATING-KIT-01.md` (transcript)

---

## Audit Admin cible

### Fichiers audites

| Fichier | Presence |
|---------|----------|
| marketing/paid-channels/page.tsx | Oui |
| marketing/integration-guide/page.tsx | Oui |
| marketing/acquisition-playbook/page.tsx | Oui |
| marketing/campaign-qa/page.tsx | Oui |
| marketing/google-tracking/page.tsx | Oui |
| marketing/destinations/page.tsx | Oui |
| marketing/delivery-logs/page.tsx | Oui |
| metrics/page.tsx | Oui |

### Resultats audit

| Check | Resultat |
|-------|----------|
| `t.keybuzz.io` (sGTM) | 1 occurrence reelle (paid-channels L82) — corrigee |
| `t.keybuzz.io` (faux positifs `client.keybuzz.io`) | 6 occurrences — pas de correction |
| `Codex` | 0 |
| `utm_source=facebook` | 1 — message d'interdiction dans campaign-qa (conforme) |
| `CompletePayment` browser | 0 occurrence presentee comme browser |
| `Purchase` browser | 0 occurrence presentee comme browser |

---

## Patches appliques

### keybuzz-admin-v2 (commit `ecd221c`)

| # | Fichier | Correction |
|---|---------|------------|
| 1 | paid-channels/page.tsx L82 | `t.keybuzz.io` → `t.keybuzz.pro` |
| 2 | campaign-qa/page.tsx L944 | "Oui des validation LinkedIn — spend Admin hors scope" → "Oui — LinkedIn CAPI valide, spend Admin hors scope" |
| 3 | acquisition-playbook/page.tsx L738 | "Spend LinkedIn dans le cockpit Metrics (hors scope actuel)" → "Spend LinkedIn non remonte dans Metrics — hors scope actuel" |
| 4 | integration-guide/page.tsx L390, L397 | "Meta Pixel, GA4, TikTok Pixel" → "Meta Pixel, GA4, TikTok Pixel, LinkedIn Insight Tag" |
| 5 | integration-guide/page.tsx L867-869 | Rappel mis a jour : tous les pixels actifs sur le funnel, sGTM = t.keybuzz.pro, Purchase/CompletePayment server-side only, pages protegees clean |

### keybuzz-infra (commit `73f19d7`)

| # | Fichier | Correction |
|---|---------|------------|
| 1 | docs/AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md | Ajout bloc PH-T8.12U date avec image, digest, 5 pixels actifs, events server-side only, pages protegees, gaps restants |

---

## Validation statique post-patch

| Check | Resultat |
|-------|----------|
| 0 `Codex` dans surfaces Admin | OK |
| 0 `utm_source=facebook` (hors interdiction) | OK |
| 0 `t.keybuzz.io` sGTM | OK (seuls faux positifs `client.keybuzz.io` restent) |
| 0 Google destination native visible | OK |
| TikTok spend pas presente actif | OK |
| LinkedIn spend pas presente connecte | OK |
| CompletePayment pas presente browser | OK |
| Purchase pas presente browser | OK |
| `t.keybuzz.pro` present ou sGTM cite | OK (2 occurrences) |

---

## Build

| Element | Valeur |
|---------|--------|
| Tag PROD | `v2.11.36-tracking-truth-admin-prod` |
| Source | `main @ ecd221c` |
| Digest | `sha256:dfe0b7946a8df302e1959fdb17495d6d48f02081dc762fa06be2a0f6f46c02ae` |
| Build method | Clone temporaire propre `/tmp/build-admin-v/admin` sur bastion |
| Build args | `NEXT_PUBLIC_APP_ENV=production`, `NEXT_PUBLIC_API_URL=https://api.keybuzz.io` |
| Verification patches | 4/4 OK (sGTM, LinkedIn CAPI, LinkedIn spend, LinkedIn Insight Tag) |

---

## GitOps Admin PROD

| Element | Valeur |
|---------|--------|
| Infra commit | `05aec50` |
| Deployment | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.36-tracking-truth-admin-prod` |
| Rollback | `v2.11.35-agency-launch-kit-prod` |
| Apply | `kubectl apply -f deployment.yaml` |
| Rollout | `deployment "keybuzz-admin-v2" successfully rolled out` |

### Admin PROD apres

| Element | Valeur |
|---------|--------|
| Image runtime | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.36-tracking-truth-admin-prod` |
| Image manifest | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.36-tracking-truth-admin-prod` |
| Match | Runtime = Manifest = Annotation |

---

## Validation navigateur IDE

**EN ATTENTE de validation Ludovic.**

Pages a valider :
1. `/marketing/paid-channels` — sGTM = `t.keybuzz.pro`, TikTok/Meta/LinkedIn corrects
2. `/marketing/integration-guide` — LinkedIn Insight Tag dans signaux browser, rappel mis a jour
3. `/marketing/acquisition-playbook` — LinkedIn spend wording corrige
4. `/marketing/campaign-qa` — LinkedIn CAPI wording corrige
5. Aucune mention Codex visible

---

## Non-regression

| Check | Resultat |
|-------|----------|
| Aucun secret expose | OK |
| Aucun Codex visible | OK |
| Aucun faux event | OK |
| Aucun faux spend | OK |
| Client/API/Website/Backend non modifies | OK |
| Aucune destination reelle modifiee | OK |
| Aucun manifest Client PROD modifie | OK |

---

## Rollback GitOps strict

En cas de rollback :

```yaml
# k8s/keybuzz-admin-v2-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.35-agency-launch-kit-prod
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
| P2 | TikTok spend bloque (Business API credentials) | Non traite (hors scope) |
| P3 | LinkedIn spend hors scope (Ads Reporting approval) | Documente |
| P3 | Google destination native non implementee | Via sGTM/Addingwell |

---

## Artefacts

| Element | Valeur |
|---------|--------|
| Admin source commit | `ecd221c` |
| Infra memory commit | `73f19d7` |
| Infra GitOps commit | `05aec50` |
| Image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.36-tracking-truth-admin-prod` |
| Digest | `sha256:dfe0b7946a8df302e1959fdb17495d6d48f02081dc762fa06be2a0f6f46c02ae` |
| Rollback | `v2.11.35-agency-launch-kit-prod` |

---

## Verdict

**GO ADMIN TRACKING TRUTH ALIGNED** (VISUAL QA PENDING)

ADMIN MARKETING SURFACES AND TRACKING MEMORY ALIGNED WITH PH-T8.12U — GA4 SGTM TIKTOK LINKEDIN META TRUTH REFLECTED — PURCHASE/COMPLETEPAYMENT BROWSER ABSENT — TIKTOK SPEND BLOCKED — LINKEDIN SPEND OUT OF SCOPE — NO CODEX VISIBLE — NO FAKE EVENT — GITOPS STRICT
