# PH-CLIENT-T8.12AJ.1 — SHOPIFY OFFICIAL LOGO PROD PROMOTION

> Date : 2026-05-03
> Verdict : **GO PROD**
> Phase précédente : PH-SAAS-T8.12AJ (logo DEV) + PH-T8.12U (tracking baseline)
> Type : promotion visuelle isolée, GitOps strict

---

## Résumé exécutif

Le logo Shopify officiel (PNG 70KB fourni par Ludovic) validé en DEV lors de PH-SAAS-T8.12AJ a été promu en PROD. L'image Client PROD combine la baseline tracking T8.12U (GA4, sGTM, TikTok, LinkedIn, Meta) avec le logo Shopify officiel. Aucune activation du connecteur Shopify PROD n'a été effectuée.

---

## Preflight

### Runtime avant

| Service | Image | Digest | Verdict |
|---------|-------|--------|---------|
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | `sha256:d50740d58338129cb289640e2f69cf21164d33ccd3e754e9a737e9a44b5bbde3` | Baseline confirmée |
| API PROD | `v3.5.137-conversation-order-tracking-link-prod` | — | Inchangée |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | — | Inchangée |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | — | Inchangée |

### Source

| Élément | Valeur |
|---------|--------|
| Repo | keybuzz-client |
| Branche | `ph148/onboarding-activation-replay` |
| HEAD bastion | `54ed713` |
| Commit logo | `54ed713 PH-SAAS-T8.12AJ: replace Shopify logo with official asset (PNG)` |
| Build depuis | Clone propre bastion |

---

## Audit logo commit (54ed713)

| Fichier | Action | Risque | Décision |
|---------|--------|--------|----------|
| `public/marketplaces/shopify.png` | Ajout (70 528 bytes) | Aucun — asset visuel | **INCLUS** |
| `app/channels/page.tsx` | 2 refs `.svg` → `.png` | Aucun — changement visuel | **INCLUS** |
| `app/billing/options/page.tsx` | 1 ref `.svg` → `.png` | Aucun — changement visuel | **INCLUS** |
| `src/features/onboarding/components/OnboardingHub.tsx` | 1 ref `.svg` → `.png` | Aucun — changement visuel | **INCLUS** |

**4 fichiers, 4 insertions, 4 suppressions — uniquement visuel, aucun tracking, aucun OAuth, aucune logique.**

---

## Audit tracking T8.12U (avant build)

| Signal | Présent source | Présent build | Verdict |
|--------|---------------|--------------|---------|
| GA4 `G-R3QQDYEBFG` | Via build-arg | Confirmé dans `.next/` | **OK** |
| sGTM `https://t.keybuzz.pro` | Via build-arg | Confirmé dans `.next/` | **OK** |
| TikTok `D7PT12JC77U44OJIPC10` | Via build-arg | Confirmé dans `.next/` | **OK** |
| LinkedIn `9969977` | Via build-arg + Dockerfile default | Confirmé dans `.next/` | **OK** |
| Meta Pixel `1234164602194748` | Via build-arg | Confirmé dans `.next/` | **OK** |
| Meta Purchase browser | Absent (server-side CAPI only) | Confirmé absent | **OK** |
| TikTok CompletePayment browser | Absent (server-side Events API only) | Confirmé absent | **OK** |

---

## Build PROD

| Élément | Valeur |
|---------|--------|
| Tag | `ghcr.io/keybuzzio/keybuzz-client:v3.5.148-shopify-official-logo-tracking-parity-prod` |
| Digest | `sha256:e42cdbd3095d319819f04998edc7662dcbcfb947abe8bb8857db8fff9328470a` |
| Source commit | `54ed713` |
| Source branche | `ph148/onboarding-activation-replay` |
| Build method | Clone propre, `docker build --no-cache` |
| Build args | 8 build args complets (API_URL, API_BASE_URL, APP_ENV, GA4, sGTM, TikTok, LinkedIn, Meta) |
| Rollback | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` |

### Build args utilisés

```
--build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io
--build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io
--build-arg NEXT_PUBLIC_APP_ENV=production
--build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG
--build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro
--build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10
--build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
--build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748
```

---

## GitOps PROD

| Étape | Résultat |
|-------|----------|
| Manifest modifié | `k8s/keybuzz-client-prod/deployment.yaml` |
| Commit infra | `6f5f9f7` |
| Push | `main → origin/main` |
| `kubectl apply` | `deployment.apps/keybuzz-client configured` |
| Rollout | `deployment "keybuzz-client" successfully rolled out` |
| Manifest = Runtime | **OUI** — `v3.5.148-shopify-official-logo-tracking-parity-prod` |
| Digest runtime | `sha256:e42cdbd3095d319819f04998edc7662dcbcfb947abe8bb8857db8fff9328470a` |

---

## Validation runtime PROD

### Logo

| Vérification | Résultat | Verdict |
|-------------|----------|---------|
| `shopify.png` dans pod | 70 528 bytes, md5 `061049e0...` | **OK** |
| Références `shopify.png` dans build | 6 fichiers | **OK** |
| Références `shopify.svg` dans build | 0 fichier | **OK** (ancien SVG ignoré) |

### Tracking dans build

| Signal | Présent dans `.next/` | Verdict |
|--------|----------------------|---------|
| GA4 `G-R3QQDYEBFG` | OUI | **OK** |
| sGTM `t.keybuzz.pro` | OUI | **OK** |
| TikTok `D7PT12JC77U44OJIPC10` | OUI | **OK** |
| LinkedIn `9969977` | OUI | **OK** |
| Meta `1234164602194748` | OUI | **OK** |

---

## Non-régression PROD

| Service | Image | Verdict |
|---------|-------|---------|
| API PROD | `v3.5.137-conversation-order-tracking-link-prod` | **INCHANGÉE** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | **INCHANGÉE** |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | **INCHANGÉE** |
| Client PROD | `v3.5.148-shopify-official-logo-tracking-parity-prod` | **MISE À JOUR** |
| Shopify API PROD | Routes absentes (pas de connecteur PROD) | **INCHANGÉ** |
| DB PROD | 0 mutation | **INCHANGÉE** |
| Outbound | 0 envoi | **OK** |
| Billing | 0 mutation | **OK** |
| CAPI/tracking | 0 event parasite | **OK** |

---

## Rollback GitOps strict

En cas de problème, procédure :

1. Modifier `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml`
2. Remplacer image par : `v3.5.147-sample-demo-platform-aware-tracking-parity-prod`
3. `git commit` + `git push`
4. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
5. `kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod`

---

## Commits

| Repo | Commit | Description |
|------|--------|-------------|
| keybuzz-infra | `6f5f9f7` | Manifest Client PROD `v3.5.148` + annotation |

---

## Verdict

**GO PROD**

SHOPIFY OFFICIAL LOGO LIVE IN PROD — CLIENT TRACKING PARITY PRESERVED (GA4 + sGTM + TikTok + LinkedIn + Meta) — SAMPLE DEMO PLATFORM-AWARE PRESERVED — NO SHOPIFY API PROD ACTIVATION — NO OAUTH/WEBHOOK/SYNC CHANGE — 0 REFS TO OLD SVG IN BUILD — PROTECTED PAGES CLEAN — NO TRACKING/BILLING/CAPI DRIFT — GITOPS STRICT
