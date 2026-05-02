# PH-SAAS-T8.12Y.8 — Trial Lifecycle Foundation + Unsubscribe PROD Promotion

> Date : 2026-05-02
> Environnement : PROD
> Type : Promotion PROD fondation technique lifecycle emails + unsubscribe
> Priorite : P1
> Image precedente : `ghcr.io/keybuzzio/keybuzz-api:v3.5.131-transactional-email-design-prod`
> Image deployee : `ghcr.io/keybuzzio/keybuzz-api:v3.5.132-trial-lifecycle-foundation-unsubscribe-prod`

---

## 1. OBJECTIF

Promouvoir en PROD la fondation technique des emails lifecycle trial, sans activer l'envoi automatique :
- Table d'idempotence `trial_lifecycle_emails_sent` (0 row, prete pour activation future)
- Colonne `tenant_settings.lifecycle_email_optout` (default false)
- Endpoint unsubscribe HMAC-signe (`/lifecycle/unsubscribe`) fonctionnel en PROD
- Lien de desabonnement visible dans les templates lifecycle (HTML + text/plain)
- Copy human-friendly avec tirets classiques (zero em dash, zero HTML entities dans text/plain)
- Routes tick/candidates protegees par `NODE_ENV !== 'production'` (404 en PROD)

**Exclusions strictes** :
- ZERO CronJob lifecycle en PROD
- ZERO email envoye en PROD
- ZERO modification Client/Admin/Website/Backend
- ZERO modification billing/Stripe

---

## 2. PREFLIGHT

### Repos

| Repo | Branche | HEAD | Dirty | Verdict |
|------|---------|------|-------|---------|
| keybuzz-api | main | Verifie | Non | OK |
| keybuzz-infra | main | Verifie | Non | OK |
| keybuzz-client | Pas touche | - | - | OK |
| keybuzz-backend | Pas touche | - | - | OK |

### Image DEV source

- DEV validee : `v3.5.138-lifecycle-visible-unsubscribe-copy-dev`
- Source identique pour le build PROD

---

## 3. SOURCE LOCK (15/15 controles)

Verification exhaustive du code source avant build :

| # | Controle | Resultat |
|---|----------|----------|
| 1 | `NODE_ENV !== 'production'` guard sur tick route | OK |
| 2 | `NODE_ENV !== 'production'` guard sur candidates route | OK |
| 3 | Unsubscribe route enregistree (tous envs) | OK |
| 4 | Zero `setInterval` lifecycle | OK |
| 5 | Zero `setTimeout` lifecycle | OK |
| 6 | Zero `cron` dans lifecycle | OK |
| 7 | HMAC secret via `COOKIE_SECRET || JWT_SECRET` | OK |
| 8 | `buildUnsubscribeUrl` utilise `API_URL` | OK |
| 9 | Unsubscribe HTML human-friendly | OK |
| 10 | Text/plain entity cleanup (.replace chain) | OK |
| 11 | Zero em dash literal | OK |
| 12 | Zero `&mdash;` | OK |
| 13 | Zero hardcoded tenant ID | OK |
| 14 | Zero hardcoded email | OK |
| 15 | recipientOverride allowlist = DEV-only | OK |

---

## 4. VALIDATION STATIQUE

```
tsc --noEmit : OK (0 erreurs TypeScript)
Secrets leakes : 0
Tracking/analytics : 0
CronJob references : 0 lifecycle-specific
```

---

## 5. BUILD PROD

```
Image tag : ghcr.io/keybuzzio/keybuzz-api:v3.5.132-trial-lifecycle-foundation-unsubscribe-prod
Build : docker build --no-cache (sur bastion)
Push : docker push -> ghcr.io
Digest : sha256:1d9b39... (verifie)
```

---

## 6. GITOPS PROD

### Manifest modifie

- Fichier : `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
- Image : `v3.5.131-transactional-email-design-prod` -> `v3.5.132-trial-lifecycle-foundation-unsubscribe-prod`
- Commit : `7552f67`
- Push : `origin/main`

### Deploiement

```
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod : OK
Pod : keybuzz-api-67fbbf9cdd-nl5bb 1/1 Running
Health : {"status":"ok"}
```

### Rollback GitOps strict

En cas de probleme :
1. Modifier `deployment.yaml` : image -> `v3.5.131-transactional-email-design-prod`
2. `git add && git commit && git push`
3. Sur le bastion : `git pull && kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
4. Verifier rollout : `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`

---

## 7. MIGRATIONS DB PROD

| # | Migration | Resultat |
|---|-----------|----------|
| 1 | `CREATE TABLE trial_lifecycle_emails_sent` (8 colonnes) | OK |
| 2 | `UNIQUE INDEX uq_lifecycle_tenant_template` (tenant_id, template_name) | OK |
| 3 | `INDEX idx_lifecycle_tenant` | OK |
| 4 | `INDEX idx_lifecycle_template` | OK |
| 5 | `ALTER TABLE tenant_settings ADD COLUMN lifecycle_email_optout BOOLEAN DEFAULT false` | OK |

### Verification post-migration

- Table existe : OK (0 rows)
- 4 index : PK + uq_lifecycle_tenant_template + idx_lifecycle_tenant + idx_lifecycle_template
- Colonne optout : boolean, default false
- Schema identique au DEV

---

## 8. VALIDATION RUNTIME PROD (sans envoi)

| # | Test | Attendu | Resultat |
|---|------|---------|----------|
| 1 | `GET /health` | 200 | 200 OK |
| 2 | `GET /lifecycle/unsubscribe` (sans token) | 400 | 400 PASS |
| 3 | `GET /lifecycle/unsubscribe?token=invalid` | 400 | 400 PASS |
| 4 | `POST /internal/trial-lifecycle/tick` | 404 | 404 PASS |
| 5 | `GET /internal/trial-lifecycle/candidates` | 404 | 404 PASS |
| 6 | `trial_lifecycle_emails_sent` rows | 0 | 0 PASS |
| 7 | `tenant_settings.lifecycle_email_optout = true` count | 0 | 0 PASS |
| 8 | HMAC secret disponible | YES | YES (64 chars) PASS |
| 9 | `NODE_ENV` | production | production PASS |
| 10 | Zero lifecycle CronJob en PROD | 0 | 0 PASS |

---

## 9. NON-REGRESSION PROD (10/10 PASS)

| # | Endpoint | HTTP | Verdict |
|---|----------|------|---------|
| 1 | `GET /health` | 200 | PASS |
| 2 | `GET /tenant-context/check-user` | 200 | PASS |
| 3 | `GET /messages/conversations` | 200 | PASS (3 conversations) |
| 4 | `GET /dashboard/summary` | 200 | PASS |
| 5 | `GET /ai/wallet/status` | 200 | PASS |
| 6 | `GET /api/v1/orders` | 200 | PASS |
| 7 | `GET /billing/current` | 200 | PASS |
| 8 | CronJobs PROD | 2 (outbound-tick + sla-evaluator) | PASS (zero lifecycle) |
| 9 | Outbound worker | 1/1 Running | PASS |
| 10 | External `https://api.keybuzz.io/health` | 200 | PASS |

---

## 10. RESUME

### Ce qui est deploye en PROD

| Composant | Status |
|-----------|--------|
| Table `trial_lifecycle_emails_sent` | Creee, vide, prete |
| UNIQUE index idempotence | Actif |
| Colonne `lifecycle_email_optout` | Ajoutee, default false |
| Endpoint `/lifecycle/unsubscribe` | Actif, HMAC-signe |
| Lien desabonnement visible (HTML + text/plain) | Dans les templates |
| Copy human-friendly (tirets classiques) | Actif |
| Routes tick/candidates | 404 en PROD (garde NODE_ENV) |

### Ce qui n'est PAS deploye en PROD

| Composant | Raison |
|-----------|--------|
| CronJob lifecycle | Phase future (activation) |
| Envoi automatique d'emails | Phase future |
| Tout email envoye | Zero email lifecycle en PROD |

### Versions deployees post-Y.8

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.138-lifecycle-visible-unsubscribe-copy-dev` | `v3.5.132-trial-lifecycle-foundation-unsubscribe-prod` |
| Client | `v3.5.48-white-bg-dev` | `v3.5.48-white-bg-prod` |
| Backend | `v1.0.38-vault-tls-dev` | `v1.0.38-vault-tls-prod` |

---

## 11. PROCHAINE ETAPE

Phase Y.9 (future) : Activation controlee des lifecycle emails en PROD
- Creer un CronJob PROD avec dryRun=true initialement
- Valider les candidats
- Activer l'envoi reel de maniere progressive
