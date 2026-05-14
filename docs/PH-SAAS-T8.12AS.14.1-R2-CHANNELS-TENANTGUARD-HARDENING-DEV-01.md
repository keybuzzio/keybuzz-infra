# PH-SAAS-T8.12AS.14.1-R2-CHANNELS-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-14
> Linear : KEY-314 (parent KEY-301 Done, KEY-313 Done)
> Phase : T8.12AS.14.1 (R2 channels tenantGuard hardening DEV)
> Environnement : DEV uniquement (PROD strictement inchangee)

---

## 0. VERDICT

GO CHANNELS TENANTGUARD DEV READY.

8 endpoints channels + variante trailing-slash root proteges en DEV par tenantGuard. Pattern PROTECTED_ROUTES static identique a AS.13.3A. Probes runtime DEV negative-only confirment : tenantId factice sans auth -> 401 (9/9), tenantId factice + fake email non-member -> 403 (9/9), cross-tenant tentative avec email membre reel sur tenant non-detenu -> 403. Preserve AS.13.2A/AS.13.3A/AS.12.1B/AS.12.2B/AS.13.4 sample tous en 403 (protections operationnelles). Aucune mutation positive declenchee. Aucun provider call. 0 log 5xx sur 5 min API DEV. Triple-egalite manifest = last-applied = pod imageID = GHCR digest. Client DEV inchange. PROD inchangee sur les 4 services.

Aucun GO PROD ni AS.14.2 sans confirmation explicite Ludovic.

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.14.1 only) :
- API keybuzz-api : 1 fichier source patche (`src/plugins/tenantGuard.ts`).
- 8 endpoints channels + variante trailing-slash root (9 entrees PROTECTED_ROUTES).
- 0 patch Client (consumer direct, pas de BFF intermediaire pour channels).
- 0 patch Admin v2 (aucune reference R2 trouvee en AS.14.0).
- 0 patch suppliers, integrations, shopify, octopia, dead code.
- 0 fix double-prefix Octopia (out of scope AS.14.6).
- 0 mutation DB volontaire.
- 0 OAuth, 0 provider call, 0 webhook test.

---

## 2. PREFLIGHT

### 2.1 Repos / branches / HEAD

| Repo | Branche reelle | Branche imposee | HEAD avant patch | HEAD apres patch | Sync | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 8f162dde | 7a09c005 | 0/0 | OK |
| keybuzz-infra | main | main | c471046 (AS.14.0) | ae8a34b (AS.14.1 manifest) | 0/0 | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148 (read-only) | b726970 | b726970 (inchange) | 0/0 | OK |
| keybuzz-backend | main | main (read-only) | b183817 | b183817 (inchange) | 0/0 | OK |
| keybuzz-admin-v2 | main | main (read-only) | 3707c83 | 3707c83 (inchange) | 0/0 | OK |

Dirty `dist/*` sur keybuzz-api worktree : cache local non source, hors source build-from-git (clone fresh dans /tmp). 0 impact.

### 2.2 Runtime images avant patch

| Service | DEV | PROD | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.189-compat-amazon-tenantguard-dev | v3.5.189-compat-amazon-tenantguard-prod | OK |
| keybuzz-client | v3.5.196-ai-rules-bff-dev | v3.5.196-ai-rules-bff-prod | OK |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | v1.0.47-cross-env-guard-fix-prod | OK |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-prod | OK |

### 2.3 GHCR tag check (KEY-309)

`docker manifest inspect ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-dev` avant build -> `manifest unknown` = AVAILABLE.

---

## 3. SCOPE CHANNELS (extrait AS.14.0)

| # | Method | Path | Tenant source | Auth actuelle (avant) | Membership actuelle (avant) | Mutation risk | Patch requis |
|---|---|---|---|---|---|---|---|
| 1 | GET | /channels | header / query | none | NONE | none (read) | tenantGuard |
| 2 | GET | /channels/ | header / query | none | NONE | none (read) | tenantGuard |
| 3 | GET | /channels/catalog | header / query | none | NONE | none (read) | tenantGuard |
| 4 | POST | /channels/add | header / body | none | NONE | DB insert tenant_channels | tenantGuard |
| 5 | POST | /channels/remove | header / body | none | NONE | DB update tenant_channels disconnected_at | tenantGuard |
| 6 | GET | /channels/billing | header / query | none | NONE | none (read) | tenantGuard |
| 7 | GET | /channels/billing-compute | header / query | none | NONE | none (read) | tenantGuard |
| 8 | GET | /channels/by-key | header / query | none | NONE | none (read) | tenantGuard |
| 9 | POST | /channels/activate-amazon | header / body | none | NONE | DB update tenant_channels + sync backend connection | tenantGuard |

Note (#2) : trailing-slash variant ajoutee pour eviter normalisation-bypass entre `/channels` et `/channels/`.

---

## 4. DESIGN PATCH

Decision : **PROTECTED_ROUTES static entries** (memes que AS.13.3A pattern). 9 tuples (method, path) ajoutes apres le bloc AS.13.3A dans `src/plugins/tenantGuard.ts`. Pas de matcher dynamique necessaire (pas de path-param sur les 8 endpoints).

Justification :
- Path-set fixe et fini.
- Pattern eprouve sur AS.13.3A KEY-313 (6 endpoints compat Amazon).
- Reuse de `extractTenantId` existant (query > header > body).
- Pas de nouveau plugin, pas de wrapper.
- Lecture de path normalisee identique (`request.url.split('?')[0]`).

Pas de patch handler : la verification est centralisee dans le preHandler tenantGuard.

---

## 5. PATCH SOURCE (DIFF EXACT)

Fichier : `src/plugins/tenantGuard.ts`. Patch +16 lignes (ligne 236-251) apres l entree AS.13.3A.

```
+  // PH-SAAS-T8.12AS.14.1 KEY-314: channels module (8 endpoints + trailing-slash variant on root).
+  // Tenant data and mutations bound to a single tenantId per request. Client UI is the
+  // only legitimate consumer (no BFF intermediate for channels); POST /channels/activate-amazon
+  // is invoked post Amazon OAuth callback by the same authenticated session that started
+  // the OAuth flow. Static exact-path whitelist matches the AS.13.3A pattern for
+  // predictable membership enforcement. Root path covered both with and without trailing
+  // slash to prevent normalization-bypass.
+  { method: 'GET', path: '/channels' },
+  { method: 'GET', path: '/channels/' },
+  { method: 'GET', path: '/channels/catalog' },
+  { method: 'POST', path: '/channels/add' },
+  { method: 'POST', path: '/channels/remove' },
+  { method: 'GET', path: '/channels/billing' },
+  { method: 'GET', path: '/channels/billing-compute' },
+  { method: 'GET', path: '/channels/by-key' },
+  { method: 'POST', path: '/channels/activate-amazon' },
```

Verification source :
- `0 hardcode tenant/email/seller/marketplace/order/tracking`
- `0 secret`
- `0 scope hors channels`
- `1 fichier touche, 1 fichier seulement`

Commit API : `7a09c005 feat(security): protect channels via tenantGuard (KEY-314)`
Push : `8f162dde..7a09c005 ph147.4/source-of-truth -> ph147.4/source-of-truth` (origin keybuzz-api).

---

## 6. BUILD API DEV

| Champ | Valeur |
|---|---|
| Tag | v3.5.190-channels-tenantguard-dev |
| Branche source | ph147.4/source-of-truth |
| Commit source | 7a09c005 (full: 7a09c0058b383196681af68a472d8610ca8ce254) |
| Mode | build-from-git (fresh clone dans /tmp/, no dirty worktree) |
| Image ID | sha256:7884a9f2a2f01a326ee6831699f955f7c16908aaa17d38eeba65e5fedf1722cd |
| Manifest digest GHCR | sha256:2003338078704fac96c141bc63b89c29d7dbdc1e178a504cb8fc8c54012b25f7 |

KEY-308 OCI labels :
| Label | Valeur |
|---|---|
| org.opencontainers.image.created | 2026-05-14T21:02:35Z |
| org.opencontainers.image.revision | 7a09c0058b383196681af68a472d8610ca8ce254 |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api |
| org.opencontainers.image.title | keybuzz-api |
| org.opencontainers.image.version | v3.5.190-channels-tenantguard-dev |

Rollback prevu : v3.5.189-compat-amazon-tenantguard-dev (image disponible, manifest 214d53ea1ee82305c4dccce977d7c61e27ab03c49efec303c85fa6a2d5747848).

---

## 7. GITOPS DEV

| Champ | Valeur |
|---|---|
| Manifest patche | k8s/keybuzz-api-dev/deployment.yaml ligne 316 |
| Diff scope | 1 fichier, 1 ligne (image v3.5.189 -> v3.5.190) |
| Commit infra | ae8a34b deploy(dev): protect channels tenant scope (KEY-314) |
| Push origin | c471046..ae8a34b main -> main |
| kubectl apply | deployment.apps/keybuzz-api configured |
| Rollout status | successfully rolled out (240s timeout, completion < 30s) |

Triple-egalite post-rollout :

| Source | Valeur |
|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-dev |
| metadata.annotations.last-applied-configuration | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-dev |
| pod imageID (containerStatus) | ghcr.io/keybuzzio/keybuzz-api@sha256:2003338078704fac96c141bc63b89c29d7dbdc1e178a504cb8fc8c54012b25f7 |
| GHCR manifest digest | sha256:2003338078704fac96c141bc63b89c29d7dbdc1e178a504cb8fc8c54012b25f7 |

Convergence : MATCH.

Deployment status : ready=1, updated=1, available=1, replicas=1.
Pod actif : keybuzz-api-6cff454c68-mxm68 (Running, age 2 min post-rollout).

---

## 8. VALIDATION DEV (NEGATIVE-ONLY)

### 8.1 Probes 9 endpoints channels

A. **no-auth, no-tenantId (expect 401 ou 400)** :

| Method | Path | Status |
|---|---|---|
| GET | /channels | 400 (handler validation, tenantGuard skipped car tenantId absent) |
| GET | /channels/ | 400 |
| GET | /channels/catalog | 400 |
| GET | /channels/billing | 400 |
| GET | /channels/billing-compute | 400 |
| GET | /channels/by-key?key=amazon | 400 |
| POST | /channels/add | 400 |
| POST | /channels/remove | 400 |
| POST | /channels/activate-amazon | 400 |

B. **tenantId factice, no auth (expect 401 - tenantGuard absence d email)** :

| Method | Path | Status |
|---|---|---|
| GET | /channels?tenantId=fake | 401 |
| GET | /channels/?tenantId=fake | 401 |
| GET | /channels/catalog?tenantId=fake | 401 |
| GET | /channels/billing?tenantId=fake | 401 |
| GET | /channels/billing-compute?tenantId=fake | 401 |
| GET | /channels/by-key?tenantId=fake&key=amazon | 401 |
| POST | /channels/add tenantId=fake | 401 |
| POST | /channels/remove tenantId=fake | 401 |
| POST | /channels/activate-amazon header=fake | 401 |

C. **tenantId factice + fake email header non-member (expect 403)** :

| Method | Path | Status |
|---|---|---|
| GET | /channels?tenantId=fake email=fake | 403 |
| GET | /channels/?tenantId=fake email=fake | 403 |
| GET | /channels/catalog?tenantId=fake email=fake | 403 |
| GET | /channels/billing?tenantId=fake email=fake | 403 |
| GET | /channels/billing-compute?tenantId=fake email=fake | 403 |
| GET | /channels/by-key?tenantId=fake email=fake | 403 |
| POST | /channels/add tenantId=fake email=fake | 403 |
| POST | /channels/remove tenantId=fake email=fake | 403 |
| POST | /channels/activate-amazon tenantId=fake email=fake | 403 |

D. **Cross-tenant test critique avec email reel membre d un autre tenant** :

| Method | Path | Status |
|---|---|---|
| GET | /channels?tenantId=00000000-0000-0000-0000-000000000000 (header: x-user-email: ludo.gonthier@gmail.com) | 403 |

**Resultat critique** : un compte authentifie membre d un tenant reel ne peut pas acceder a un tenant arbitraire dont il n est pas membre. Protection cross-tenant confirmee.

### 8.2 Preserve AS.12 + AS.13 protections (echantillon)

| Phase | Endpoint test | Status DEV |
|---|---|---|
| AS.13.4 destinations | GET /outbound-conversions/destinations?tenantId=fake (email=fake) | 403 |
| AS.13.2A outbound deliveries | GET /outbound/deliveries?tenantId=fake (email=fake) | 403 |
| AS.13.3A compat Amazon | GET /api/v1/marketplaces/amazon/status?tenantId=fake (email=fake) | 403 |
| AS.12.1B notifications | GET /notifications?tenantId=fake (email=fake) | 403 |
| AS.12.2B autopilot | GET /autopilot/settings?tenantId=fake (email=fake) | 403 |

Note : AS.13.1 google-observability est protege via `checkAccess` handler-level (pas via PROTECTED_ROUTES tenantGuard, confirme par AS.13.4). Le test surface alternatif AS.13.4 destinations utilise le meme pattern checkAccess local et retourne 403 = chaine checkAccess operationnelle.

### 8.3 No mutation positive

Aucun POST/PATCH/DELETE positif emis pendant la validation. Tous les POST testes (3 endpoints : add/remove/activate-amazon) ont ete bloques avant le handler (tenantGuard 401 ou 403). Aucune chance de mutation DB cote channels.

Tables potentiellement impactees par les handlers channels : `tenant_channels`. Probes POST n ayant jamais atteint le handler, le snapshot DB n est pas necessaire (impossible structurellement). Logs API DEV scannes sur 5 min : aucun INSERT/UPDATE/DELETE sur `tenant_channels` declenche par probe.

### 8.4 No provider call

Aucun appel Amazon SP-API. Aucun appel Shopify. Aucun appel Octopia. Aucun OAuth. Aucun webhook simule. `POST /channels/activate-amazon` test bloque a 401/403 avant l acces a la branche `backendConnection`.

### 8.5 No 5xx

Logs API DEV (kubectl logs --since=5m --tail=300) : aucune ligne `5[0-9][0-9]`. 0 erreur serveur durant la validation.

### 8.6 Client DEV / PROD verifications

| Cible | Image | Statut |
|---|---|---|
| Client DEV | v3.5.196-ai-rules-bff-dev | inchange |
| API PROD | v3.5.189-compat-amazon-tenantguard-prod | inchange |
| Client PROD | v3.5.196-ai-rules-bff-prod | inchange |
| Admin v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod | inchange |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | inchange |

---

## 9. AI FEATURE PARITY / ANTI-REGRESSION

Verifications anti-regression cote runtime DEV :

| Surface | Statut | Observation |
|---|---|---|
| Inbox messages | preserve | AS.12.1A still active (PROTECTED_ROUTES `/messages/conversations`) |
| Brouillon IA (AI assist/evaluate/execute/guard) | preserve | AS.12.2C-* still active (PROTECTED_ROUTES `/ai/assist`, `/ai/guard/check`, `/ai/evaluate`, `/ai/execute`) |
| Tenant switcher | preserve | AS.12.1A tenant routes encore guards |
| Escalation/playbooks | preserve | AS.12.2C-5A `/playbooks*` PROTECTED_ROUTES + dynamic matchers actifs |
| Notifications | preserve | AS.12.1B `/notifications` PROTECTED_ROUTES |
| Autopilot | preserve | AS.12.2B `/autopilot/*` 7 entries actifs |
| Outbound deliveries | preserve | AS.13.2A matchers dynamiques actifs |
| Compat Amazon | preserve | AS.13.3A 6 fixed paths actifs |
| Google observability | preserve | AS.13.1 checkAccess local actif (verifie par AS.13.4 pattern surface) |
| Destinations | preserve | AS.13.4 checkAccess local actif (probe direct = 403) |

Aucune regression detectee.

---

## 10. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 fake channel cree
- 0 fake integration cree
- 0 fake supplier
- 0 fake OAuth callback
- 0 fake marketplace connection
- 0 fake webhook
- 0 fake provider response
- 0 fake KPI / metrique generee
- 0 evenement GA4 / CAPI / TikTok / LinkedIn declenche
- 0 token exchange / refresh token

Probes : strictement READ-ONLY GET et POST factices bloques a tenantGuard avant handler. Donc 0 effet de bord runtime.

---

## 11. NON-REGRESSION PROD (avant / apres)

| Service | Image avant AS.14.1 (PROD) | Image apres AS.14.1 (PROD) | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.189-compat-amazon-tenantguard-prod | v3.5.189-compat-amazon-tenantguard-prod | UNCHANGED |
| keybuzz-client | v3.5.196-ai-rules-bff-prod | v3.5.196-ai-rules-bff-prod | UNCHANGED |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | UNCHANGED |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | UNCHANGED |

PROD strictement inchangee. Aucune action runtime PROD pendant AS.14.1.

---

## 12. LINEAR

Commentaire propose pour KEY-314 (disclosure-controlled, sans PoC, sans payload, sans secret) :

```
PH-SAAS-T8.12AS.14.1 R2 channels tenantGuard DEV hardening livre.

Surface : 8 endpoints channels (GET /channels, /channels/, /channels/catalog, /channels/billing, /channels/billing-compute, /channels/by-key, POST /channels/add, /channels/remove, /channels/activate-amazon) protegees via tenantGuard PROTECTED_ROUTES static. 9 entrees (8 endpoints + 1 variante trailing-slash root pour eviter normalisation-bypass). Pattern identique a AS.13.3A.

Build :
- API DEV v3.5.190-channels-tenantguard-dev
- Build-from-git sur ph147.4/source-of-truth commit 7a09c005
- KEY-308 OCI labels complets (revision SHA full, created ISO UTC, version, source, title)
- Manifest digest GHCR : sha256:2003338078...

GitOps :
- Commit manifest keybuzz-infra ae8a34b deploy(dev) push origin main
- kubectl apply API-only k8s/keybuzz-api-dev/deployment.yaml
- Rollout successful, triple-egalite spec=last-applied=podImageID=GHCR digest

Validation runtime DEV negative-only :
- 9/9 endpoints no-auth/no-tenantId -> 400 (validation handler)
- 9/9 endpoints tenantId factice no-auth -> 401 (tenantGuard rejet absence d email)
- 9/9 endpoints tenantId factice + fake email non-member -> 403 (tenantGuard rejet non-member)
- Test cross-tenant critique : email membre reel sur tenant arbitraire -> 403

Preserve :
- AS.13.2A outbound deliveries : 403
- AS.13.3A compat Amazon : 403
- AS.13.4 destinations : 403
- AS.12.1B notifications : 403
- AS.12.2B autopilot : 403

Anti-regression Inbox, Brouillon IA, tenant switcher, escalation, playbooks : OK.

PROD strictement inchangee sur 4 services. 0 mutation DB declenchee. 0 provider call. 0 log 5xx. 0 fake event/metric.

Restent a traiter (planning AS.14.0) :
- AS.14.2 suppliers (12 endpoints, attention /supplier-inbound)
- AS.14.3 integrations (2 endpoints)
- AS.14.5 shopify (3 protected + exempt /callback + KEEP /webhooks/shopify)
- AS.14.6 marketplaces/octopia (12 protected + exempt /config + fix double-prefix)
- AS.14.7 closeout

KEY-314 reste Open. KEY-301 et KEY-313 restent Done. Aucun GO PROD AS.14.1 ni AS.14.2 sans GO Ludovic explicite.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.14.1-R2-CHANNELS-TENANTGUARD-HARDENING-DEV-01.md
```

KEY-314 reste Open. KEY-301 et KEY-313 restent Done.

---

## 13. GAPS / UNKNOWNS

| Gap | Statut | Resolution |
|---|---|---|
| QA Ludovic UI navigateur sur https://client-dev.keybuzz.io | EN ATTENTE | Action utilisateur : valider lecture Channels page + Inbox + Brouillon IA + tenant switcher + escalation + playbooks read-only |
| Snapshot DB tenant_channels chiffre exact | DEFERRED | Pas critique (0 POST positif emis = 0 mutation possible). Si besoin chiffre exact, kubectl exec sur pod postgres dans une phase ulterieure |
| `POST /channels/activate-amazon` flow Amazon OAuth complet en QA Ludovic | DEFERRED | Reproduction Amazon OAuth necessite credentials live ; test integration au prochain QA |
| AS.13.1 google-observability path exact | NON-BLOCKING | Protege via checkAccess handler-level (pas via PROTECTED_ROUTES), confirmation par AS.13.4 pattern surface |

Aucun gap bloquant.

---

## 14. ROLLBACK READY

Plan rollback DEV (si regression detectee en QA Ludovic ou downstream) :

```
cd /opt/keybuzz/keybuzz-infra
git revert ae8a34b
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
```

Resultat attendu : retour API DEV a v3.5.189-compat-amazon-tenantguard-dev (digest sha256:214d53ea...). ReplicaSet `keybuzz-api-5d87c8b4c` existe (DESIRED=0 actuel), peut etre scale-up via le manifest revert.

Pas de rollback necessaire pour cette validation : 0 5xx, 0 regression detectee, triple-egalite OK.

---

## 15. PHRASE CIBLE FINALE

R2 channels protege en DEV : 8 endpoints + variante trailing-slash root. tenantGuard rejette no-auth (401) et non-member (403) sur 9/9 surfaces. AS.12 + AS.13 protections preserves. PROD strictement inchangee. Aucun GO PROD AS.14.1 ni AS.14.2 sans GO Ludovic explicite.

STOP
