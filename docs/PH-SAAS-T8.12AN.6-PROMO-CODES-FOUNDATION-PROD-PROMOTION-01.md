# PH-SAAS-T8.12AN.6 — Promo Codes Foundation PROD Promotion

> Phase : PH-SAAS-T8.12AN.6R (reprise contrôlée après interruption shell)
> Date : 2026-05-05
> Environnement : PROD
> Verdict : **GO PROD FOUNDATION**

---

## Résumé

Promotion en PROD de la fondation Promo Codes validée en DEV (phases AN.2 à AN.5).
Reprise contrôlée après interruption shell lors de la phase AN.6 initiale.

---

## ÉTAPE 0 — Preflight Reprise

| Élément | Valeur | Verdict |
|---------|--------|---------|
| Autre agent build/deploy | Aucun | ✓ |
| Autre agent keybuzz-infra | Aucun | ✓ |
| Autre agent Stripe promo | Aucun | ✓ |
| API PROD runtime | `v3.5.139-amazon-oauth-inbound-bridge-prod` | ✓ baseline |
| Client PROD runtime | `v3.5.151-amazon-oauth-inbound-bridge-prod` | ✓ baseline |
| Admin PROD runtime | `v2.11.37-acquisition-baseline-truth-prod` | ✓ baseline |
| Website PROD runtime | `v0.6.8-tiktok-browser-pixel-prod` | ✓ baseline |
| Backend PROD runtime | `v1.0.42-amazon-oauth-inbound-bridge-prod` | ✓ inchangé |
| Dernier commit GitOps | `df189ae` (AN.5 DEV) | ✓ |
| Migration PROD (signup_attribution) | 4 colonnes promo ajoutées | ✓ vérifié |
| Build AN.6 déjà déployé | Non | ✓ |

---

## ÉTAPE 1 — Audit Script `/tmp/an6_build_prod.sh`

Script complet affiché et audité.

| Check | Résultat | Verdict |
|-------|----------|---------|
| `set -e` | Présent | ✓ |
| Repos utilisés | Bastion persistants `/opt/keybuzz/*` | ⚠ déviation documentée |
| Branches correctes | API `ph147.4/source-of-truth`, Admin `main`, Client `ph148/onboarding-activation-replay`, Website `main` | ✓ |
| HEAD commits | API `edd385bb`, Admin `22a268e`, Client `b0968c6`, Website `7fc942b` | ✓ |
| Tracked files dirty | Aucun | ✓ |
| `--no-cache` | Présent tous les builds | ✓ |
| Client build args PROD | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `APP_ENV=production` | ✓ |
| `kubectl set image` | Absent | ✓ |
| Secrets dans logs | Aucun | ✓ |
| Coupon LIVE | Aucun | ✓ |
| Mutation business | Aucune | ✓ |

**Déviation documentée** : le script utilise les repos bastion persistants (procédure standard du projet, Section 7 du contexte). Les repos sont propres, branches correctes, HEAD confirmés. `.dockerignore` exclut `dist/`, `.git`, `node_modules`.

**Décision** : GO BUILD (avec correction Client pour tracking, voir ci-dessous).

---

## ÉTAPE 2 — Migration PROD Vérifiée

| Objet DB | État observé | Action | Verdict |
|----------|-------------|--------|---------|
| `signup_attribution.promo_code` | `text`, nullable | Existe | ✓ |
| `signup_attribution.promo_code_id` | `text`, nullable | Existe | ✓ |
| `signup_attribution.stripe_promotion_code_id` | `text`, nullable | Existe | ✓ |
| `signup_attribution.promo_campaign` | `text`, nullable | Existe | ✓ |
| `signup_attribution` row count | 5 (inchangé) | Aucune mutation | ✓ |
| Rows avec promo_code | 0 | Aucune injection | ✓ |
| `promo_codes` table (Admin) | N'existe pas dans PROD DB | Créée auto par Admin `ensureTables()` | ✓ attendu |
| `promo_code_audit_log` table | N'existe pas dans PROD DB | Créée auto par Admin `ensureTables()` | ✓ attendu |

---

## ÉTAPE 3 — Sources Exactes

| Repo | Branche | Commit | Briques présentes | Verdict |
|------|---------|--------|-------------------|---------|
| keybuzz-api | `ph147.4/source-of-truth` | `edd385bb` | PROMO_PLAN_MISMATCH (1), applies_to_products (5), allow_promotion_codes:false (1), utm_content (3), promo_code attribution (6) | ✓ |
| keybuzz-admin-v2 | `main` | `22a268e` | promo-codes pages (4 fichiers), API routes, RBAC | ✓ |
| keybuzz-client | `ph148/onboarding-activation-replay` | `b0968c6` | promo register (2), attribution (3) | ✓ |
| keybuzz-website | `main` | `7fc942b` | promo pricing forwarding (1) | ✓ |

---

## ÉTAPE 4 — Builds PROD

### Build initial (4 images)

| Service | Tag | Digest | Source commit | Verdict |
|---------|-----|--------|---------------|---------|
| API | `v3.5.140-promo-plan-only-attribution-prod` | `sha256:a3f6c304971a5a6bb7b703f95630f874a696c19a167f035ddfd185f0159200bb` | `edd385bb` | ✓ |
| Admin | `v2.12.1-promo-codes-foundation-prod` | `sha256:9021f0840b63fd9fbd44a93ffbbd73502e32123fb72f1aae2cadddb321a4393f` | `22a268e` | ✓ |
| Client | `v3.5.152-promo-attribution-prod` | (initial, sans tracking) | `b0968c6` | ✗ tracking manquant |
| Website | `v0.6.9-promo-forwarding-prod` | `sha256:5ba5e626e92060425a3fc277bc0789c76c842b740cb8e2c4ecd137140d19cee1` | `7fc942b` | ✓ |

### Incident Tracking Client

Le script de build original n'incluait pas les `--build-arg` tracking (`NEXT_PUBLIC_GA4_MEASUREMENT_ID`, `NEXT_PUBLIC_META_PIXEL_ID`, `NEXT_PUBLIC_SGTM_URL`, `NEXT_PUBLIC_TIKTOK_PIXEL_ID`).

**Cause** : ces variables sont `NEXT_PUBLIC_*` donc remplacées au build time. Le Dockerfile a des défauts vides pour GA4, Meta, sGTM, TikTok (seul LinkedIn `9969977` a un défaut non-vide).

**Comparaison tracking** :

| Tracking | PROD actuelle (v3.5.151) | Build initial (v3.5.152) | Après rebuild |
|----------|--------------------------|--------------------------|---------------|
| GA4 | 5 fichiers | 0 ✗ | 5 ✓ |
| sGTM | 7 fichiers | 2 ✗ | 7 ✓ |
| TikTok | 2 fichiers | 0 ✗ | 2 ✓ |
| LinkedIn | 2 fichiers | 2 ✓ | 2 ✓ |
| Meta | 2 fichiers | 0 ✗ | 2 ✓ |

**Fix** : Client reconstruit avec tous les `--build-arg` tracking :
```
--build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG
--build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro
--build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10
--build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
--build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748
```

### Client rebuilt (final)

| Service | Tag | Digest (final) | Verdict |
|---------|-----|----------------|---------|
| Client | `v3.5.152-promo-attribution-prod` | `sha256:3abeb58db035c397422460589096fd00404da06cd97372fde2d3d0bacf161371` | ✓ |

---

## ÉTAPE 5 — Validation Images

### API Image

| Check | Résultat | Verdict |
|-------|----------|---------|
| PROMO_PLAN_MISMATCH | 1 | ✓ |
| applies_to_products | 5 | ✓ |
| allow_promotion_codes | 3 (true+false instances) | ✓ |
| utm_content metadata | 5 | ✓ |
| promo_code attribution | 6 | ✓ |
| Secrets | 0 | ✓ |

### Admin Image

| Check | Résultat | Verdict |
|-------|----------|---------|
| Promo Codes page | Compilé dans `.next/server/app/(admin)/marketing/promo-codes/` | ✓ |
| API routes | 3 route files dans `.next/server/app/api/admin/marketing/promo-codes/` | ✓ |
| Auto-create coupon LIVE | Aucun `stripe.coupons.create` au démarrage | ✓ |

### Client Image (rebuilt)

| Check | Résultat | Verdict |
|-------|----------|---------|
| Promo register | 1 | ✓ |
| GA4 | 5 fichiers | ✓ |
| sGTM | 7 fichiers | ✓ |
| TikTok | 2 fichiers | ✓ |
| LinkedIn | 2 fichiers | ✓ |
| Meta | 2 fichiers | ✓ |
| API URL | `api.keybuzz.io` | ✓ |
| Shopify logo | `shopify.png` + `shopify.svg` | ✓ |

### Website Image

| Check | Résultat | Verdict |
|-------|----------|---------|
| Promo forwarding | 2 fichiers contenant "promo" | ✓ |
| Register links | 18 fichiers | ✓ |
| DEV leak | Aucun | ✓ |

---

## ÉTAPE 6 — GitOps PROD

| Service | Image avant | Image après | Rollback |
|---------|-------------|-------------|----------|
| API | `v3.5.139-amazon-oauth-inbound-bridge-prod` | `v3.5.140-promo-plan-only-attribution-prod` | `v3.5.139-amazon-oauth-inbound-bridge-prod` |
| Admin | `v2.11.37-acquisition-baseline-truth-prod` | `v2.12.1-promo-codes-foundation-prod` | `v2.11.37-acquisition-baseline-truth-prod` |
| Client | `v3.5.151-amazon-oauth-inbound-bridge-prod` | `v3.5.152-promo-attribution-prod` | `v3.5.151-amazon-oauth-inbound-bridge-prod` |
| Website | `v0.6.8-tiktok-browser-pixel-prod` | `v0.6.9-promo-forwarding-prod` | `v0.6.8-tiktok-browser-pixel-prod` |

**GitOps commit** : `ed8432c` sur `keybuzz-infra` main
**Procédure** : manifest modifié → commit → push → `kubectl apply -f` → `kubectl rollout status` → runtime vérifié

Tous les rollouts réussis. Runtime = manifest = annotations.

---

## ÉTAPE 7 — Validation PROD

| Surface | Attendu | Résultat | Verdict |
|---------|---------|----------|---------|
| API health | OK | `{"status":"ok"}` | ✓ |
| Admin /login | 200 | 200 | ✓ |
| Client /register | 200 | 200 | ✓ |
| Website /pricing | 200 | 200 | ✓ |
| Stripe coupons LIVE | 0 | 0 | ✓ |
| Stripe promotion codes LIVE | 0 | 0 | ✓ |
| `promo_codes` table PROD | Non créée (Admin ensureTables) | NOT YET CREATED | ✓ |
| CronJobs | Tous actifs | Confirmé | ✓ |
| 17TRACK | `carrier-tracking-poll` | Actif | ✓ |
| Lifecycle | dry-run-only | `trial-lifecycle-dryrun` | ✓ |

---

## ÉTAPE 8 — Non-Régression

| Risque | Vérification | Verdict |
|--------|-------------|---------|
| Billing existant | 4 subs actives, 9 customers | ✓ inchangé |
| Fake purchase | 0 events dernière heure | ✓ |
| CAPI event | Aucun | ✓ |
| Fake spend | Aucun | ✓ |
| Lifecycle email | dry-run-only | ✓ |
| Stripe coupon LIVE | 0 coupons | ✓ |
| Stripe promotion code LIVE | 0 codes | ✓ |
| DB mutation hors migration | 0 promo rows, counts stables (12T/32U/541C) | ✓ |
| Client tracking | GA4:5, sGTM:7, TikTok:2, LinkedIn:2, Meta:2 | ✓ aucune régression |
| API auth | check-user 200 | ✓ |

---

## ÉTAPE 9 — Rollback GitOps

### Procédure de rollback strict

Si nécessaire, restaurer les images précédentes par GitOps :

1. Modifier les manifests :

```yaml
# k8s/keybuzz-api-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.139-amazon-oauth-inbound-bridge-prod

# k8s/keybuzz-admin-v2-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.37-acquisition-baseline-truth-prod

# k8s/keybuzz-client-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.151-amazon-oauth-inbound-bridge-prod

# k8s/website-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-website:v0.6.8-tiktok-browser-pixel-prod
```

2. Commit : `git add ... && git commit -m "ROLLBACK: revert AN.6 promo foundation PROD"`
3. Push : `git push origin main`
4. Apply : `kubectl apply -f k8s/<service>/deployment.yaml`
5. Vérifier : `kubectl rollout status deployment/<service> -n <namespace>`
6. Confirmer : runtime = manifest = annotation

**INTERDIT** : `kubectl set image`, `kubectl patch`, `kubectl edit`

---

## Gaps Restants

1. **`promo_codes` table PROD** : sera auto-créée par Admin `ensureTables()` au premier accès à la page Promo Codes. Comportement attendu, pas d'action requise.
2. **Build script tracking** : le script `/tmp/an6_build_prod.sh` original ne contenait pas les `--build-arg` tracking. Pour les futurs builds Client, toujours inclure les 5 build args tracking (GA4, sGTM, TikTok, LinkedIn, Meta).
3. **`max_redemptions`** : garde `max_redemptions` non testée E2E en production (pas de coupon LIVE). Sera validée lors de la création du premier vrai code concours (AN.7).

---

## Prochaine Phase AN.7

La fondation est en place. La prochaine phase `PH-SAAS-T8.12AN.7` pourra :
- Créer le premier vrai coupon Stripe LIVE
- Créer le premier Promotion Code Stripe LIVE
- Valider le flux checkout complet avec un code valide
- Tester `max_redemptions` en conditions réelles
- Publier le lien concours

---

## Verdict Final

**GO PROD FOUNDATION**

PROMO CODES FOUNDATION LIVE IN PROD — RESUME SCRIPT AUDITED — ADMIN READY — API PLAN-ONLY GUARDS ACTIVE — PROMO ATTRIBUTION SCHEMA READY — CLIENT/WEBSITE PROMO FORWARDING ACTIVE — AGENT/KBACTIONS/ADDONS EXCLUDED — NO LIVE COUPON CREATED — NO FAKE CHECKOUT — NO TRACKING/BILLING/CAPI DRIFT — GITOPS STRICT — READY FOR FIRST CONTEST CODE CREATION

---

## Chemin du rapport

`keybuzz-infra/docs/PH-SAAS-T8.12AN.6-PROMO-CODES-FOUNDATION-PROD-PROMOTION-01.md`
