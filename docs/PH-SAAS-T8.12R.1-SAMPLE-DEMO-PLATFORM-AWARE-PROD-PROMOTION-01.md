# PH-SAAS-T8.12R.1 — Sample Demo Platform-Aware PROD Promotion

**Phase** : PH-SAAS-T8.12R.1-SAMPLE-DEMO-PLATFORM-AWARE-PROD-PROMOTION-01
**Date** : 2026-05-01
**Linear** : KEY-235 (fermeture recommandee)
**Environnement** : PROD
**Type** : promotion PROD Client — Sample Demo platform-aware

---

## Objectif

Promouvoir en PROD l'alignement Sample Demo platform-aware valide en DEV (PH-SAAS-T8.12R).

- 5 conversations demo : 3 Amazon, 1 Octopia, 1 email
- Textes Amazon-only generalises ("Connecter un canal")
- `onConnectAmazon` remplace par `onConnect`
- 0 refund-first wording
- Doctrine seller-first respectee
- Zero DB/API/tracking/billing/CAPI drift

## Sources relues

- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- `AI_MEMORY/SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md`
- `PH-API-T8.12Q.2-PLATFORM-AWARE-REFUND-PROTECTION-PROD-PROMOTION-01.md`
- `PH-SAAS-T8.12R-SAMPLE-DEMO-PLATFORM-AWARE-SURFACE-ALIGNMENT-DEV-01.md`
- `PH-SAAS-T8.12O-SAMPLE-DEMO-SELLER-FIRST-MESSAGE-AND-REFUND-PROTECTION-ALIGNMENT-01.md`
- `PH-SAAS-T8.12N.4-SAMPLE-DEMO-WOW-PROD-PROMOTION-01.md`
- `PH-SAAS-T8.12N.3.1-SAMPLE-DEMO-MOBILE-OVERFLOW-HOTFIX-DEV-01.md`

## Preflight

| Repo | Branche attendue | Branche constatee | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|---|
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `195fe7cd` | Non | OK |
| `keybuzz-infra` | `main` | `main` | `ca4a4b6` | Non | OK |

### Runtime avant promotion

| Service | ENV | Image | Match manifest ? |
|---|---|---|---|
| Client | PROD | `v3.5.146-client-meta-pixel-dedup-safe-prod` | OK |
| API | PROD | `v3.5.130-platform-aware-refund-strategy-prod` | hors scope |
| Backend | PROD | `v1.0.46-ph-recovery-01-prod` | hors scope |
| Website | PROD | `v0.6.8-tiktok-browser-pixel-prod` | hors scope |

## Source promue

| Brique | Attendu | Resultat |
|---|---|---|
| 5 conversations demo | 5 | OK (conv-001 a conv-005) |
| >= 1 scenario Octopia | >= 1 | OK (conv-004 = octopia) |
| >= 1 scenario email | >= 1 | OK (conv-003 = email) |
| Textes Amazon-only generalises | 0 "Connecter Amazon" | OK |
| `onConnectAmazon` absent | 0 | OK |
| `onConnect` present | >= 1 | OK (6 occurrences) |
| 0 refund-first (IA promet remboursement) | 0 | OK |
| 0 API writes dans demo | 0 | OK |
| 0 tracking import | 0 | OK |
| Mobile master/detail | hidden/flex | OK |

## Validation statique

| Check | Attendu | Resultat |
|---|---|---|
| 0 `AW-18098643667` | 0 | OK |
| 0 `codex` | 0 | OK |
| 0 secret | 0 | OK |
| 0 `api-dev.keybuzz.io` | 0 | OK |
| 0 `onConnectAmazon` | 0 | OK |
| 0 phrase refund-first | 0 | OK |
| 0 POST/PUT/PATCH/DELETE dans demo | 0 | OK |

## Build PROD

| Element | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-client:v3.5.146-sample-demo-platform-aware-prod` |
| HEAD source | `3d858a8` |
| Branche | `ph148/onboarding-activation-replay` |
| Digest | `sha256:c08e95ecfbdb6a63457a13e63c625f3684b18bf85b1e4787efdbb3ed0c455989` |
| Clone temporaire | Oui (`/tmp/build-client-prod-t812r1-318491`) |
| Build args | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production` |
| `--no-cache` | Oui |
| Source dirty | Non |

## GitOps PROD

| Manifest | Image avant | Image apres | Runtime | Verdict |
|---|---|---|---|---|
| `keybuzz-client-prod/deployment.yaml` | `v3.5.146-client-meta-pixel-dedup-safe-prod` | `v3.5.146-sample-demo-platform-aware-prod` | `v3.5.146-sample-demo-platform-aware-prod` | OK |

Commit infra : `7be510f`
Pod : `keybuzz-client-7894666fcc-58lqb` Running 1/1, 0 restarts

## Validation PROD structurelle

| Check | Attendu | Resultat |
|---|---|---|
| Pod Running 1/1 | Running 1/1 | OK |
| 0 restarts post rollout | 0 | OK |
| `/login` HTTP OK | 200 | OK |
| `/register` HTTP OK | 200 | OK |
| API PROD inchangee | `v3.5.130-platform-aware-refund-strategy-prod` | OK |
| Backend PROD inchange | `v1.0.46-ph-recovery-01-prod` | OK |
| Website PROD inchange | `v0.6.8-tiktok-browser-pixel-prod` | OK |
| API health | `status: ok` | OK |

## Validation tenant reel PROD

| Tenant | conv_count | Demo visible ? | Attendu | Resultat |
|---|---|---|---|---|
| `ecomlg-001` | 483 | Non | Pas de demo | OK |
| `switaa-sasu-mnc1ouqu` | 29 | Non | Pas de demo | OK |
| `switaa-sasu-mn9c3eza` | 6 | Non | Pas de demo | OK |
| `compta-ecomlg-gmail--mnvu4649` | 3 | Non | Pas de demo | OK |
| `ecomlg-mo4h93e7` | 2 | Non | Pas de demo | OK |
| `romruais-gmail-com-mn7mc6xl` | 1 | Non | Pas de demo | OK |

Tous les tenants avec conversations reelles ne voient pas la demo (`conversationCount > 0`).

## Validation tenant vide PROD

Mode : validation par bundle/source (pas de fake signup).

| Check | Attendu | Resultat |
|---|---|---|
| Channels dans bundle | 3 amazon, 1 email, 1 octopia | OK |
| `onConnectAmazon` | 0 | OK |
| `Connecter un canal` | >= 1 | OK |
| `kb_demo_dismissed` | present | OK |
| `marie.l@exemple-client.fr` | present | OK (conv email) |
| `acheteur-exemple-4@cdiscount` | present | OK (conv octopia) |
| `demo-conv-` prefix | present | OK |
| Mobile hidden/md:flex | present | OK |

**GO PARTIEL** : Le prochain tenant vide en PROD verra la demo multi-canal platform-aware.

## Non-pollution / non-regression PROD

| Surface | Attendu | Resultat |
|---|---|---|
| 0 DB rows `demo-*` conversations | 0 | OK |
| 0 DB rows `demo-*` messages | 0 | OK |
| 0 billing event nouveau | 0 | OK |
| 0 signup_complete | 0 | OK |
| 0 purchase | 0 | OK |
| 0 CAPI | 0 | OK |
| 0 GA4 conversion fake | 0 | OK |
| 0 AW direct | 0 | OK |
| API health | `status: ok` | OK |
| Client PROD | HTTP 200 | OK |
| Client restarts | 0 | OK |
| API PROD inchangee | `v3.5.130-platform-aware-refund-strategy-prod` | OK |
| Backend PROD inchange | `v1.0.46-ph-recovery-01-prod` | OK |
| Website PROD inchange | `v0.6.8-tiktok-browser-pixel-prod` | OK |

## Rollback GitOps

Image de rollback : `v3.5.146-client-meta-pixel-dedup-safe-prod`

Procedure stricte (GitOps uniquement) :

1. Modifier `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` :
   ```yaml
   image: ghcr.io/keybuzzio/keybuzz-client:v3.5.146-client-meta-pixel-dedup-safe-prod
   ```
2. `git add && git commit -m "rollback(client-prod): revert PH-SAAS-T8.12R.1" && git push`
3. `kubectl apply -f deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod`
5. Verifier runtime = manifest

Interdit : `kubectl set image`, `kubectl edit`, `kubectl patch`.

## Statut KEY-235

**Recommandation : fermer KEY-235.**

L'alignement platform-aware est complet :
- API PROD : posture marketplace strict vs direct seller-controlled
- Client PROD : demo reflétant Amazon, Octopia, et email
- Textes generalises (plus d'impression Amazon-only)
- Doctrine seller-first respectee
- 0 refund-first wording

La distinction fine Cdiscount vs FNAC (deux marketplaces Octopia distinctes dans l'UI) pourra faire l'objet d'un ticket futur dedie plus petit, lorsque des comptes Octopia reels seront connectes.

## Chemin du rapport

`keybuzz-infra/docs/PH-SAAS-T8.12R.1-SAMPLE-DEMO-PLATFORM-AWARE-PROD-PROMOTION-01.md`

---

**SAMPLE DEMO PLATFORM-AWARE LIVE IN PROD — DEMO REFLECTS MARKETPLACE VS DIRECT CHANNEL DIFFERENCES — REAL TENANTS STAY REAL — REFUND-FIRST WORDING ABSENT — NO DB/API/TRACKING/BILLING/CAPI DRIFT — GITOPS STRICT**
