# PH-SAAS-T8.12AS.14.1-R2-CHANNELS-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-15
> Linear : KEY-314 (parent KEY-301 Done, KEY-313 Done)
> Phase : T8.12AS.14.1-PROD (R2 channels tenantGuard + BFF user-email PROD)
> Environnement : PROD (DEV reste protege depuis AS.14.1 + AS.14.1-FIX)

---

## 0. VERDICT

GO CHANNELS TENANTGUARD PROD READY.

Promotion PROD coordonnee API + Client livree. Channels (8 endpoints + variante trailing-slash root) proteges en PROD par tenantGuard ; BFFs Client (`list`, `catalog`, `billing`, `billing-compute`, `add`, `remove`) injectent `X-User-Email` depuis NextAuth session. Probes runtime PROD negative-only : 9/9 = 400 sans tenant, 9/9 = 401 avec fake tenant sans email, 9/9 = 403 avec fake tenant + fake email non-member. Preserve AS.12.1B + AS.12.2B + AS.13.2A + AS.13.3A + AS.13.4 sample tous en 403. 0 5xx PROD. Triple-egalite spec=last-applied=podImageID=GHCR x 2 (API + Client). Autres services PROD (admin v2, backend) strictement inchanges. QA Ludovic PROD confirmee : page Canaux operationnelle (charge, channels visibles, drawer rempli), Inbox + Brouillon IA + tenant switcher + escalation OK. Aucune action mutationnelle effectuee. Aucun provider call.

KEY-314 reste Open. Aucun GO AS.14.2 (suppliers) sans confirmation explicite Ludovic.

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.14.1-PROD only) :
- API keybuzz-api PROD : promotion v3.5.189 -> v3.5.190 (tenantGuard channels 8 endpoints + trailing-slash)
- Client keybuzz-client PROD : promotion v3.5.196 -> v3.5.197 (6 BFFs channels x-user-email injection)
- 2 manifests PROD modifies (api + client uniquement)
- 0 patch source dans cette phase
- 0 mutation channels (no add/remove/activate)
- 0 OAuth
- 0 provider call
- 0 modification autres services PROD (admin v2, backend)
- 0 modification DEV

---

## 2. PREFLIGHT

### 2.1 Repos / branches / HEAD

| Repo | Branche reelle | Branche imposee | HEAD | Sync | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 7a09c005 (AS.14.1 source) | 0/0 | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148 | 3fe90ab (AS.14.1-FIX source) | 0/0 | OK |
| keybuzz-infra | main | main | e42bfc2 (apply commit) puis 71f1ac5 -> e42bfc2 -> rapport | 0/0 | OK |

Dirty `dist/` keybuzz-api : cache local hors source, ignore par build-from-git.

### 2.2 Runtime images avant promotion PROD

| Service | DEV image | PROD image | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.190-channels-tenantguard-dev | v3.5.189-compat-amazon-tenantguard-prod | conforme |
| keybuzz-client | v3.5.197-channels-bff-userauth-dev | v3.5.196-ai-rules-bff-prod | conforme |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | v1.0.47-cross-env-guard-fix-prod | conforme |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-prod | conforme |

### 2.3 KEY-309 GHCR tag check avant build

| Image | Tag attendu | Statut |
|---|---|---|
| keybuzz-api | v3.5.190-channels-tenantguard-prod | manifest unknown (libre) |
| keybuzz-client | v3.5.197-channels-bff-userauth-prod | manifest unknown (libre) |

---

## 3. BUILD API PROD

| Champ | Valeur |
|---|---|
| Tag | v3.5.190-channels-tenantguard-prod |
| Branche source | ph147.4/source-of-truth |
| Commit source | 7a09c005 (full: 7a09c0058b383196681af68a472d8610ca8ce254) |
| Mode | build-from-git (fresh clone /tmp/) |
| Image ID | sha256:ecd28e20fa992eca5201a40213e48aa39bdd391001faecc9b2c8860182ab9b54 |
| Manifest digest GHCR | sha256:71f0ddc5fe5ad1ffffbd2ae030d89e9e364ff684effff545b181ec8a8db2f9cd |

KEY-308 OCI labels :
| Label | Valeur |
|---|---|
| created | 2026-05-14T22:25:25Z |
| revision | 7a09c0058b383196681af68a472d8610ca8ce254 |
| source | https://github.com/keybuzzio/keybuzz-api |
| title | keybuzz-api |
| version | v3.5.190-channels-tenantguard-prod |

Rollback prevu : v3.5.189-compat-amazon-tenantguard-prod (manifest sha256:3a6661f7394cd887a4f85c71d1b1ec658621a37d62cc8071e2ac499919eefcfe).

---

## 4. BUILD CLIENT PROD

| Champ | Valeur |
|---|---|
| Tag | v3.5.197-channels-bff-userauth-prod |
| Branche source | ph148/onboarding-activation-replay |
| Commit source | 3fe90ab (full: 3fe90abb21e9344016b2433a76a2d68eca1f0b65) |
| Mode | build-from-git (fresh clone /tmp/) |
| Image ID | sha256:0838332aa1a01e7aaccc5f6c7c121e85061ff918d600e6ecd60257a26fbb09e0 |
| Manifest digest GHCR | sha256:8a06fa3ad8e5c52b7d66e6631ae818af8de211a1cf221967a9d8fdf495c467b0 |

### 4.1 KEY-302 bundle guard PROD

RESULTATS : 17 PASS / 0 FAIL / 0 WARN. VERDICT : PASS - Image valide.

- URL contamination : `api.keybuzz.io` PRESENT, `api-dev.keybuzz.io` ABSENT
- Pages critiques (inbox, dashboard, channels, settings, billing, login, register, locked, onboarding, orders) : 10/10 PASS
- Signup page non-regression : PASS
- Page size sanity : 3/3 PASS
- Routes manifest : PASS

### 4.2 KEY-308 OCI labels Client PROD

| Label | Valeur |
|---|---|
| created | 2026-05-14T22:27:08Z |
| revision | 3fe90abb21e9344016b2433a76a2d68eca1f0b65 |
| source | https://github.com/keybuzzio/keybuzz-client |
| title | keybuzz-client |
| version | v3.5.197-channels-bff-userauth-prod |

Rollback prevu : v3.5.196-ai-rules-bff-prod.

---

## 5. DOCKER PUSH PROD

| Image | Manifest digest GHCR (pull) | Config digest (Image ID) |
|---|---|---|
| keybuzz-api:v3.5.190-channels-tenantguard-prod | sha256:71f0ddc5fe5ad1ffffbd2ae030d89e9e364ff684effff545b181ec8a8db2f9cd | sha256:ecd28e20fa992eca5201a40213e48aa39bdd391001faecc9b2c8860182ab9b54 |
| keybuzz-client:v3.5.197-channels-bff-userauth-prod | sha256:8a06fa3ad8e5c52b7d66e6631ae818af8de211a1cf221967a9d8fdf495c467b0 | sha256:0838332aa1a01e7aaccc5f6c7c121e85061ff918d600e6ecd60257a26fbb09e0 |

---

## 6. GITOPS PROD

### 6.1 Manifests patches

| Manifest | Ligne | Diff |
|---|---|---|
| k8s/keybuzz-api-prod/deployment.yaml | 106 | image v3.5.189 -> v3.5.190, digest commentaire mis a jour, rollback noted |
| k8s/keybuzz-client-prod/deployment.yaml | 76 | image v3.5.196 -> v3.5.197, digest commentaire mis a jour, rollback noted |

Diff scope total : 2 fichiers, 2 lignes (+2 / -2).

### 6.2 Commit + push

```
e42bfc2 deploy(prod): protect channels tenant scope + BFF auth (KEY-314)
push origin: 71f1ac5..e42bfc2 main -> main
```

### 6.3 Apply sequentiel + rollout

**API PROD :**
- `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml` -> deployment.apps/keybuzz-api configured
- rollout status 240s -> successfully rolled out

**Client PROD :**
- `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml` -> deployment.apps/keybuzz-client configured
- rollout status 240s -> successfully rolled out

### 6.4 Triple-egalite post-rollout

**API PROD :**

| Source | Valeur |
|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod |
| last-applied-configuration | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod |
| pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:71f0ddc5fe5ad1ffffbd2ae030d89e9e364ff684effff545b181ec8a8db2f9cd |
| GHCR manifest digest | sha256:71f0ddc5fe5ad1ffffbd2ae030d89e9e364ff684effff545b181ec8a8db2f9cd |
| Deploy ready/replicas | 1/1 |

**Client PROD :**

| Source | Valeur |
|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-client:v3.5.197-channels-bff-userauth-prod |
| last-applied-configuration | ghcr.io/keybuzzio/keybuzz-client:v3.5.197-channels-bff-userauth-prod |
| pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:8a06fa3ad8e5c52b7d66e6631ae818af8de211a1cf221967a9d8fdf495c467b0 |
| GHCR manifest digest | sha256:8a06fa3ad8e5c52b7d66e6631ae818af8de211a1cf221967a9d8fdf495c467b0 |
| Deploy ready/replicas | 1/1 |

Convergence x 2 : MATCH.

---

## 7. VALIDATION PROD NEGATIVE-ONLY

### 7.1 Probes API PROD 9 endpoints channels

A. **no-auth, no-tenantId (expect 400)** :

| Method | Path | Status |
|---|---|---|
| GET | /channels | 400 |
| GET | /channels/ | 400 |
| GET | /channels/catalog | 400 |
| GET | /channels/billing | 400 |
| GET | /channels/billing-compute | 400 |
| GET | /channels/by-key?key=amazon | 400 |
| POST | /channels/add | 400 |
| POST | /channels/remove | 400 |
| POST | /channels/activate-amazon | 400 |

B. **tenantId factice + no auth (expect 401)** :

9/9 endpoints retournent 401 (tenantGuard rejet absence d email).

C. **tenantId factice + fake email non-member (expect 403)** :

9/9 endpoints retournent 403 (tenantGuard rejet non-member, membership user_tenants non satisfaite).

### 7.2 Probes BFF Client PROD (expect 307 redirect)

| Endpoint BFF | Status |
|---|---|
| /api/channels/list | 307 redirect /auth/signin (middleware AuthGuard) |
| /api/channels/catalog | 307 |
| /api/channels/billing | 307 |
| /api/channels/billing-compute | 307 |
| /api/channels/add | 307 |
| /api/channels/remove | 307 |
| /api/channels/registry | 200 (public legitime, registry statique) |

Defense in-depth : middleware AuthGuard Client intercepte AVANT route handler. `getServerSession` check dans le route handler est une deuxieme barriere.

### 7.3 Preserve AS.12 + AS.13 sample (PROD)

| Phase | Endpoint | Status |
|---|---|---|
| AS.13.4 destinations | GET /outbound-conversions/destinations?tenantId=fake (email=fake) | 403 |
| AS.13.2A outbound deliveries | GET /outbound/deliveries?tenantId=fake (email=fake) | 403 |
| AS.13.3A compat Amazon | GET /api/v1/marketplaces/amazon/status?tenantId=fake (email=fake) | 403 |
| AS.12.1B notifications | GET /notifications?tenantId=fake (email=fake) | 403 |
| AS.12.2B autopilot | GET /autopilot/settings?tenantId=fake (email=fake) | 403 |

Toutes les protections AS.12 + AS.13 PROD preservees operationnelles.

### 7.4 Logs PROD

| Cible | Resultat |
|---|---|
| API PROD logs 5 min - 5xx | 0 |
| API PROD logs 5 min - channels events | requetes test visibles avec correlation aux probes ci-dessus |
| Client PROD logs 5 min - 5xx | 0 |
| Client PROD logs 5 min - erreurs | 0 |

### 7.5 No mutation positive

Aucun POST/PATCH/DELETE positif emis. Aucun OAuth start. Aucun disconnect provider. Aucun webhook simule. Tous les POSTs testes (`add`, `remove`, `activate-amazon`) bloques avant handler par tenantGuard.

### 7.6 QA Ludovic PROD (confirme par Ludovic)

| Surface | Resultat |
|---|---|
| https://client.keybuzz.io/channels charge | OK |
| Bandeau erreur catalogue absent | OK |
| Channels visibles | OK |
| Drawer "Ajouter une marketplace" rempli | OK |
| Inbox | OK |
| Brouillon IA sur les cas attendus | OK |
| Tenant switcher | OK |
| Escalation | OK |
| Aucune action mutationnelle effectuee | OK (no add/remove/activate/OAuth) |

---

## 8. AI FEATURE PARITY / ANTI-REGRESSION

| Surface | Statut PROD |
|---|---|
| Inbox messages | preserve (AS.12.1A) |
| Brouillon IA (assist/evaluate/execute/guard) | preserve (AS.12.2C-1/2/3/4) |
| AI rules / playbooks | preserve (AS.12.2C-5A/5B) |
| Tenant switcher | preserve |
| Escalation | preserve |
| Notifications | preserve (AS.12.1B) |
| Autopilot | preserve (AS.12.2B) |
| Outbound deliveries | preserve (AS.13.2A) |
| Compat Amazon | preserve (AS.13.3A) |
| Destinations | preserve (AS.13.4 checkAccess) |
| Channels (NOUVEAU) | PROTEGE + BFF FIXED |

Aucune regression detectee.

---

## 9. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 fake channel cree
- 0 fake integration
- 0 fake OAuth callback
- 0 fake marketplace connection
- 0 fake webhook
- 0 fake provider response
- 0 fake KPI / metrique
- 0 evenement GA4 / CAPI / TikTok / LinkedIn declenche
- 0 token exchange / refresh token
- 0 mutation DB volontaire

---

## 10. NON-REGRESSION PROD (avant / apres)

| Service | Image avant AS.14.1-PROD | Image apres AS.14.1-PROD | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.189-compat-amazon-tenantguard-prod | v3.5.190-channels-tenantguard-prod | UPGRADED (intentionnel) |
| keybuzz-client | v3.5.196-ai-rules-bff-prod | v3.5.197-channels-bff-userauth-prod | UPGRADED (intentionnel) |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | UNCHANGED |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | UNCHANGED |

DEV inchange :
- API DEV : v3.5.190-channels-tenantguard-dev
- Client DEV : v3.5.197-channels-bff-userauth-dev

---

## 11. LINEAR

Commentaire propose pour KEY-314 (disclosure-controlled, sans PoC, sans payload, sans secret) :

```
PH-SAAS-T8.12AS.14.1-PROD R2 channels tenantGuard + BFF user-email injection PROD livre.

Promotion PROD coordonnee API + Client :
- API PROD v3.5.189 -> v3.5.190-channels-tenantguard-prod (8 endpoints + variante trailing-slash, AS.13.3A pattern)
- Client PROD v3.5.196 -> v3.5.197-channels-bff-userauth-prod (6 BFFs channels inject x-user-email depuis NextAuth session)

Build :
- API : commit 7a09c005, image ID sha256:ecd28e20..., manifest digest sha256:71f0ddc5..., KEY-308 OCI complet
- Client : commit 3fe90ab, image ID sha256:0838332a..., manifest digest sha256:8a06fa3a..., KEY-302 bundle 17/17 PASS (api.keybuzz.io present, api-dev absent), KEY-308 OCI complet

GitOps :
- 2 manifests PROD modifies (1 fichier API + 1 fichier Client), 1 commit (e42bfc2), push origin main
- kubectl apply sequentiel API puis Client, rollouts OK
- Triple-egalite spec=last-applied=podImageID=GHCR digest x 2

Validation PROD negative-only :
- 9 endpoints channels no-auth/no-tenantId -> 400
- 9 endpoints channels tenantId factice no-auth -> 401 (tenantGuard rejet)
- 9 endpoints channels tenantId factice + fake email non-member -> 403 (tenantGuard rejet)
- 6 BFFs Client no-auth -> 307 redirect /auth/signin (middleware AuthGuard, defense in-depth)
- /api/channels/registry public legitime -> 200
- Preserve AS.13.4 + AS.13.2A + AS.13.3A + AS.12.1B + AS.12.2B PROD : 403 (toutes protections preservees)
- 0 5xx API PROD / 0 5xx Client PROD
- 0 mutation, 0 OAuth, 0 provider call, 0 webhook

QA Ludovic PROD confirmee : https://client.keybuzz.io/channels charge sans bandeau erreur, channels visibles, drawer rempli, anti-regression Inbox + Brouillon IA + tenant switcher + escalation OK. Aucune action mutationnelle.

Autres services PROD strictement inchanges : admin v2 v2.12.2-media-buyer-lp-domain-qa-prod, backend v1.0.47-cross-env-guard-fix-prod. DEV egalement inchange.

Regression DEV identifiee + corrigee en AS.14.1-FIX avant cette promotion PROD : audit AS.14.0 manquait les 6 BFFs `app/api/channels/` qui n injectaient pas X-User-Email -> page Canaux KO en DEV -> patch BFFs + redeploy Client DEV v3.5.197 -> QA DEV OK -> promotion PROD coordonnee API + Client incluant le fix.

Total cumule R2 (KEY-314) : 9 endpoints channels proteges en DEV + PROD (1 sous-phase fermee sur 6 planifiees en AS.14.x).

Prochaine sous-phase recommandee : AS.14.2 suppliers (12 endpoints, attention /supplier-inbound webhook gateway). Pre-flight AS.14.2 doit grep BFFs cote Client dans LES DEUX repertoires (`app/api/` ET `src/app/api/`) pour eviter une regression similaire.

KEY-314 reste Open. KEY-301 et KEY-313 restent Done. Aucun enchainement AS.14.2 sans GO Ludovic explicite.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.14.1-R2-CHANNELS-TENANTGUARD-HARDENING-PROD-01.md
```

KEY-314 reste Open. KEY-301 et KEY-313 restent Done.

---

## 12. ROLLBACK READY

Plan rollback PROD (si regression detectee post-promotion) :

```
cd /opt/keybuzz/keybuzz-infra
git revert e42bfc2
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=240s
```

Resultat attendu : retour PROD a :
- API v3.5.189-compat-amazon-tenantguard-prod (digest sha256:3a6661f7394cd887a4f85c71d1b1ec658621a37d62cc8071e2ac499919eefcfe)
- Client v3.5.196-ai-rules-bff-prod

Aucun rollback necessaire post-promotion : 0 5xx, 0 regression detectee, QA Ludovic OK.

---

## 13. GAPS / UNKNOWNS

| Gap | Statut | Resolution |
|---|---|---|
| Audit BFFs Client deux chemins | NOTED (memoire `feedback_audit_bff_client_two_paths`) | A appliquer dans tous audits AS.14.2+ |
| Probable BFFs legacy similaires sur suppliers/integrations/shopify/octopia | A INVESTIGUER | Pre-flight AS.14.2 audit obligatoire |
| Snapshot DB chiffre `tenant_channels` PROD | DEFERRED | 0 POST positif emis = 0 mutation possible |

Aucun gap bloquant pour declarer AS.14.1 PROD ferme.

---

## 14. PHRASE CIBLE FINALE

R2 channels protege en PROD sur 9 endpoints + variante trailing-slash root. BFFs Client injectent x-user-email correctement. Regression DEV identifiee et corrigee avant la promotion PROD. PROD admin v2 + backend strictement inchanges. AS.12 + AS.13 protections preservees. QA Ludovic PROD OK. Aucun enchainement AS.14.2 sans GO Ludovic explicite.

STOP
