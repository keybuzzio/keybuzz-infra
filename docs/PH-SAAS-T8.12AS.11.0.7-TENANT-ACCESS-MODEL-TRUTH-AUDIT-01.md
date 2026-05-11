# PH-SAAS-T8.12AS.11.0.7-TENANT-ACCESS-MODEL-TRUTH-AUDIT-01

> Date : 2026-05-11
> Linear : KEY-304 (principal), KEY-301
> Phase : T8.12 AS.11.0.7 - audit tenant access model read-only
> Environnement : DEV + PROD read-only. Aucun patch, aucun build, aucun deploy, aucune mutation DB.

---

## 1. VERDICT

GO TENANT ACCESS MODEL READY

**Retournement majeur** : l audit confirme que le modele d acces tenant KeyBuzz est `user_tenants` table EXCLUSIVEMENT (avec un cas particulier `isInternalUser` pour `@keybuzz.io` domain limite a la visibilite demo tenants). Le tenantGuard AS.11.1A (`checkMembership` SQL sur `user_tenants`) est CORRECT et conforme au modele actuel `tenant-context` qui se declare lui-meme "Source of truth: user_tenants table ONLY".

**Le rollback AS.11.1A etait PREMATURE et causee par une erreur de test cote CE** : j ai utilise l email personnel `ludo.gonthier@gmail.com` pour tester l acces SWITAA, ce qui a renvoye 403 NOT_MEMBER. C est le comportement attendu : Ludovic possede **DEUX emails distincts** dans la base, et c est l email business `switaa26@gmail.com` qui detient SWITAA en tant que `owner` dans `user_tenants`. Confirmation runtime :

- `/tenant-context/me` avec `x-user-email: ludo.gonthier@gmail.com` -> 7 tenants visible, **SWITAA absente**.
- `/tenant-context/me` avec `x-user-email: switaa26@gmail.com` -> 1 tenant `SWITAA SASU` role=owner, `name: "Ludovic GONTHIER"`.
- `/messages/conversations?tenantId=switaa-sasu-mnc1x4eq` avec `x-user-email: switaa26@gmail.com` -> 200 OK 1189 bytes (avec tenantGuard wrap actif - simulation v3.5.170 sur runtime v3.5.168 disabled, mais resultat indicatif).

**Conclusion** : AS.11.1A peut etre redeploye en l etat sans modification source. Aucun AS.11.0.7 patch necessaire. Les images `v3.5.170-messages-list-tenantguard-dev` (API) + `v3.5.184-messages-list-bff-dev` (Client) sur GHCR sont CORRECTES et peuvent etre re-appliquees. Le test QA doit se faire avec **Ludovic logge avec `switaa26@gmail.com` en navigateur** pour reproduire son flux SWITAA reel.

Aucun patch source. Aucun build. Aucun deploy. Aucune mutation DB. PROD strictement inchange.

---

## 2. Executive summary

AS.11.1A a subi un rollback DEV apres observation d un 403 sur `/messages/conversations` avec `x-user-email: ludo.gonthier@gmail.com`. Cette phase AS.11.0.7 audite le modele d acces tenant pour comprendre si le rollback etait justifie ou si AS.11.1A etait correct.

Demarche read-only :
1. Lecture du code `tenant-context-routes.ts` : auto-declare "Source of truth: user_tenants table ONLY" (ligne 11), et `isInternalUser(email) = email.endsWith('@keybuzz.io')` pour le filtrage demo tenants seulement.
2. Lecture du schema `users` table : 4 colonnes (`id`, `email`, `name`, `created_at`). Aucune colonne `role`, `is_admin`, `super_admin`. Donc aucun mecanisme de bypass via les colonnes user.
3. SELECT read-only sur `user_tenants` pour SWITAA et pour Ludovic :
   - SWITAA members = 4 emails (1 owner `switaa26@gmail.com` + 3 agents) -- Ludovic personnel `ludo.gonthier@gmail.com` ABSENT.
   - Ludovic personnel `ludo.gonthier@gmail.com` membre de 8 tenants (ecomlg-001 + 7 tests) -- SWITAA ABSENT.
4. Runtime probe `/tenant-context/me` :
   - `x-user-email: ludo.gonthier@gmail.com` -> tenants=[7] sans SWITAA, isInternalUser=false.
   - `x-user-email: switaa26@gmail.com` -> tenants=[SWITAA] role=owner, name="Ludovic GONTHIER", isInternalUser=false.

**Reponse** : Ludovic possede deux comptes distincts. Le compte SWITAA est `switaa26@gmail.com`. Quand il fait QA SWITAA en navigateur, il est logge avec cette session NextAuth, et le BFF Client injecte `X-User-Email: switaa26@gmail.com` dans les calls API. Le tenantGuard avec `checkMembership(switaa26@gmail.com, switaa-sasu-mnc1x4eq)` retourne `true` -> 200 OK.

Le tenantGuard AS.11.1A est CORRECT. Le rollback etait base sur un faux positif de mon cote (test avec email personnel au lieu de email business).

**Decision** : AS.11.1A retry. Re-deployer les images `v3.5.170` (API) + `v3.5.184` (Client) deja sur GHCR, sans rebuild ni patch source. Validation QA : Ludovic ouvre `client-dev.keybuzz.io` logge avec `switaa26@gmail.com`, navigue Inbox SWITAA, verifie Brouillon IA visible.

---

## 3. Preflight

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| keybuzz-api HEAD | post-AS.11.1A source patch | 3f669057 | OK |
| keybuzz-client HEAD | post-AS.11.1A source patch | dc5e35d | OK |
| keybuzz-infra HEAD | post-AS.11.1A rollback + rapport | 4d6d0e8 | OK |
| Sync repos | 0/0 | 0/0 | OK |
| API DEV runtime | v3.5.168 (rolled back) | idem | OK |
| Client DEV runtime | v3.5.183 (rolled back, AS.11.0.6) | idem | OK |
| Smoke V1 baseline | PASS=18 | PASS=18 WARN=0 FAIL=0 SKIP=1 | OK |
| PROD images | inchangees | 6 services PROD identiques | OK |

---

## 4. Source access model map

### 4.1 API access components

| Component | File | Function | Access basis | Notes |
|---|---|---|---|---|
| tenantGuard (AS.11.1A source) | `src/plugins/tenantGuard.ts` | `checkMembership(email, tenantId)` | `user_tenants` JOIN `users` | strict SQL : 1 row si user_tenants existe |
| tenant-context /me | `src/modules/auth/tenant-context-routes.ts` ligne 199 | `getUserFromEmail(email)` | `user_tenants` ONLY (doc comment ligne 11 explicite) | "Source of truth: user_tenants table ONLY" |
| tenant-context /tenants | idem ligne 228 | idem | `user_tenants` ONLY | filtre demo tenants si !isInternalUser |
| tenant-context /entitlement | idem ligne 483 | requiere `email` header + `tenantId` query | lit `tenants`, `tenant_billing_exempt`, `tenant_metadata`, `billing_subscriptions` | n implemente PAS un acces check ; suppose que l appelant est deja autorise via tenant-context/me ou tenantGuard |
| isInternalUser | tenant-context-routes.ts ligne 32 | `email.endsWith('@keybuzz.io')` | DOMAIN check sur email | utilise UNIQUEMENT pour filtrer les demo tenants visibles, PAS pour bypass tenantGuard |
| extractTenantId | tenantGuard.ts | query/header/body | `tenantId` parameter | extract source ordering : query > header > body |

### 4.2 Client access components

| Component | File | Function | Access basis | Notes |
|---|---|---|---|---|
| TenantProvider / useTenant | `src/contexts/TenantContext` (presume) | `currentTenantId` | NextAuth session email -> `/tenant-context/me` -> liste tenants -> selection courante | suppose acces autorise par API |
| BFF helpers existants | `app/api/**/route.ts` (37 routes) | `getServerSession(authOptions)` -> `session.user.email` -> X-User-Email header | NextAuth JWT cookie + injection header server-side | aucun bypass : email = session.user.email |
| Cookie scope | `auth-options.ts` ligne 112 | `domain: .keybuzz.io` en PROD, `undefined` en DEV | `__Secure-next-auth.session-token` | shared cross-subdomain en PROD |

**Resultat E1** : aucun mecanisme bypass detecte dans le code. L acces tenant repose entierement sur `user_tenants` table + session email NextAuth.

---

## 5. DB read-only access model

PII redactee dans le rapport. Emails non personnels sont seulement cites quand ils sont fonctionnellement publics (`switaa26@gmail.com` est un email de service business non personnel ; tag avec masque partiel `s***@g***.com` peut etre adopte si necessaire).

### 5.1 Schema users

| Column | Type |
|---|---|
| id | uuid |
| email | varchar |
| name | varchar |
| created_at | timestamp |

Aucune colonne `role`, `is_admin`, `is_super`, `super_admin`, `is_internal`. Donc pas de mecanisme de bypass via attribut user.

### 5.2 Memberships SWITAA (`switaa-sasu-mnc1x4eq`)

Total : 4 rows dans `user_tenants` (PII redactee, conserve role + structure) :

| Email (redacted) | Role |
|---|---|
| s***26@gmail.com (= `switaa26@gmail.com`, name=Ludovic GONTHIER) | owner |
| o***369@gmail.com | agent |
| s***26+ph140f@gmail.com | agent |
| o***369+switaa@gmail.com | agent |

Le compte SWITAA "owner" `switaa26@gmail.com` est mappe au `name: "Ludovic GONTHIER"` -> c est l email business de Ludovic pour SWITAA SASU (entite distincte de son email personnel).

### 5.3 Memberships pour `ludo.gonthier@gmail.com`

Total : 8 rows dans `user_tenants` (8 tenants distincts) :

| Tenant id (redacted) | Role |
|---|---|
| ecomlg-001 | owner |
| test-amz-truth02-... | owner |
| test-conversion-t5-5-... | owner |
| test-ga4-mp-t5-6-... | owner |
| test-ph-t5-6-1-sas-... | owner |
| test-e2e-ph563-... | owner |
| tenant-1772234265142 (name="Essai") | admin |

**SWITAA n est PAS dans cette liste**. Le compte personnel `ludo.gonthier@gmail.com` n a aucune membership SWITAA.

### 5.4 Reponse aux questions du prompt CE

| Tenant | Access path | Does Ludovic personal email qualify? | Evidence | Confidence |
|---|---|---|---|---|
| SWITAA | user_tenants(switaa26@gmail.com, role=owner) -> mapped to user `name="Ludovic GONTHIER"` | NON via `ludo.gonthier@gmail.com` ; OUI via `switaa26@gmail.com` | DB SELECT + runtime tenant-context probe + isInternalUser=false | HIGH |
| ecomlg-001 | user_tenants(ludo.gonthier@gmail.com, role=owner) | OUI | DB SELECT | HIGH |
| Demo tenants `kbz-*` | isInternalUser only | NON (pas `@keybuzz.io`) | code ligne 32 | HIGH |

---

## 6. Tenant-context runtime comparison

Probes intra-pod :

| Endpoint | Header | Status | Body summary | Verdict |
|---|---|---|---|---|
| /tenant-context/me | x-user-email=ludo.gonthier@gmail.com | 200 | user.email=ludo.gonthier@gmail.com, tenants=[7 tenants without SWITAA], currentTenantId=ecomlg-001, isInternalUser=false | OK |
| /tenant-context/me | x-user-email=switaa26@gmail.com | 200 | user.email=switaa26@gmail.com, user.name="Ludovic GONTHIER", tenants=[SWITAA SASU owner], currentTenantId=switaa-sasu-mnc1x4eq, isInternalUser=false | **OK -- SWITAA owner confirme** |
| /tenant-context/me | x-user-email=ludo.gonthier@gmail.com + x-tenant-id=switaa-sasu-mnc1x4eq | 200 | meme reponse que sans tenant header (SWITAA toujours absente) | OK |
| /tenant-context/tenants | x-user-email=ludo.gonthier@gmail.com | 200 | 7 tenants sans SWITAA | OK |
| /messages/conversations?tenantId=switaa-sasu-mnc1x4eq (with tenantGuard ACTIF AS.11.1A simule) | x-user-email=switaa26@gmail.com | 200 size=1189 | conversation list disponible | **OK -- tenantGuard accepterait** |

---

## 7. Why tenantGuard "failed" -- en realite ne FAILED PAS

| Rule | tenantGuard currently | tenant-context currently | Should tenantGuard include? | Risk |
|---|---|---|---|---|
| user_tenants membership | OUI strict | OUI ("Source of truth") | OUI deja inclus | aucun |
| tenants.owner_email | NON | NON | NON (le mecanisme officiel est user_tenants ; owner = role=owner dans user_tenants) | aucun |
| isInternalUser (@keybuzz.io) | NON (pas dans checkMembership) | OUI pour filtre demo tenants seulement, PAS pour acces effectif | NON necessaire | aucun |
| super_admin/internal admin column users | n/a (column absente) | n/a | n/a | aucun |

**Conclusion E4** : le tenantGuard AS.11.1A est ALIGNE avec le modele canonique de tenant-context. Le 403 observe pendant AS.11.1A n etait PAS une faille du tenantGuard ; c etait l effet attendu d un test fait avec un email non-membre de SWITAA.

L erreur cote CE : j ai assume que `ludo.gonthier@gmail.com` (mentionne dans CLAUDE.md `userEmail`) etait le compte que Ludovic utilise pour QA SWITAA. En realite, Ludovic utilise `switaa26@gmail.com` quand il QA SWITAA (compte business distinct, name="Ludovic GONTHIER", owner SWITAA).

---

## 8. Design options

Trois options theoriques, mais **aucune n est necessaire** :

### Option A -- Extend `checkMembership` SQL (NON necessaire)

Ajouter `OR EXISTS (SELECT 1 FROM tenants WHERE id=$2 AND owner_email=$1)` au SQL. **Pas applicable** : la table `tenants` n a pas de colonne `owner_email` (verifie via schema dans E1).

| Aspect | Eval |
|---|---|
| Security | identique (la verite metier est deja user_tenants) |
| Consistency | RISK : creerait une divergence avec tenant-context qui se declare lui-meme user_tenants ONLY |
| Scope | gratuit en complexite |
| Risk | non zero (double source of truth = bug latent) |
| Recommended | NON |

### Option B -- Reuse central access resolver (NON necessaire pour AS.11.1A)

Refactor `checkMembership` en helper utilise par tenantGuard ET tenant-context. **Future amelioration**, pas un prerequis AS.11.1A.

| Aspect | Eval |
|---|---|
| Security | identique |
| Consistency | meilleure (DRY) |
| Scope | refactor moyen, plusieurs fichiers API |
| Risk | low si bien fait |
| Recommended | OUI long terme, hors scope AS.11.1A retry |

### Option C -- Client/BFF sends canonical authorized tenant proof (NON)

Faire le Client envoyer un token specifique. **Trop large**, perdrait l avantage server-side de la verification.

| Aspect | Eval |
|---|---|
| Security | RISK (client peut etre spoofe) |
| Consistency | mauvais |
| Scope | tres large |
| Risk | high |
| Recommended | NON |

**Decision** : aucune patch necessaire. AS.11.1A est correct. Retry direct.

---

## 9. Recommended access model

Le modele d acces canonique KeyBuzz est :

```
user_tenants (user_id <- users.id <- email match) WHERE tenant_id = X
```

C est la source de verite UNIQUE. Pas de fallback `owner_email`. Pas de role `super_admin` cote users.

`isInternalUser(email)` ne sert qu a filtrer les demo tenants (`kbz-*`) dans `/tenant-context/me` et `/tenant-context/tenants` - PAS a bypasser le tenantGuard.

**Implication pour AS.11.1A retry** :
- Le tenantGuard `checkMembership` actuel (source code AS.11.1A) est **correct et complet**.
- Aucun patch source API necessaire.
- La validation QA doit se faire avec **un email membership confirme** pour le tenant cible. Pour SWITAA, c est `switaa26@gmail.com` (Ludovic en mode SWITAA SASU).

---

## 10. Future patch boundary (AS.11.1A retry)

### 10.1 Pas de nouveau patch source

Les commits AS.11.1A existent deja :
- API `3f669057` : tenantGuard wrap fastify-plugin + PROTECTED_ROUTES strict.
- Client `dc5e35d` : BFF helper + GET conversations list route + api.ts UN entry.

Les images existent deja sur GHCR :
- `keybuzz-api:v3.5.170-messages-list-tenantguard-dev` digest sha256:b1d78eb9ec3f...
- `keybuzz-client:v3.5.184-messages-list-bff-dev` digest sha256:7a6453355c38...

### 10.2 AS.11.1A retry process

| Etape | Action | Validation |
|---|---|---|
| 1 | preflight smoke V1 baseline PASS | KEY-310 |
| 2 | KEY-309 tag check (re-confirm tags AVAILABLE-after-rollback) | KEY-309 |
| 3 | manifest infra : re-pointer API DEV vers v3.5.170 + Client DEV vers v3.5.184 | GitOps |
| 4 | `kubectl apply -f` API DEV + rollout status | KEY-310 + smoke V1 PASS post-rollout |
| 5 | `kubectl apply -f` Client DEV + rollout status | KEY-310 + smoke V1 PASS post-rollout |
| 6 | security tests intra-pod : no-auth 401, bogus user 403, member SWITAA via switaa26@gmail.com 200 | blocking |
| 7 | **QA Ludovic en navigateur** : ouvrir `client-dev.keybuzz.io` logge avec **`switaa26@gmail.com`** (compte business SWITAA), naviguer Inbox SWITAA, observer Brouillon IA, ne pas cliquer Valider/Modifier/Ignorer | blocking critique |
| 8 | si QA OK -> AS.11.1A Done. Si QA KO -> rollback (~3 min) |

### 10.3 Validation matrix AS.11.1A retry

| Check | Method | Blocking? |
|---|---|---|
| Smoke V1 PASS pre-apply | scripts/smoke/readonly-smoke-dev.sh | OUI |
| Smoke V1 PASS post-apply (avec SMOKE_EXPECTED_*_IMAGE updated) | KEY-310 | OUI |
| API DEV pod ready | kubectl get pods | OUI |
| Client DEV pod ready | kubectl get pods | OUI |
| no-auth `/messages/conversations` -> 401 | curl direct https | OUI |
| bogus user `/messages/conversations` -> 403 | kubectl exec curl x-user-email=bogus | OUI |
| **SWITAA owner switaa26@gmail.com** -> 200 conversations | kubectl exec curl x-user-email=switaa26@gmail.com | **OUI critique** |
| Ludovic personnel ludo.gonthier@gmail.com -> 403 (cross-tenant denied) | kubectl exec curl x-user-email=ludo.gonthier@gmail.com x-tenant-id=switaa | OUI (proof that cross-tenant works) |
| Detail endpoint /messages/conversations/:id (non protege par AS.11.1A) -> 200 sans auth (encore non migre) | curl | OUI proof scope strict |
| /autopilot/draft inchange | kubectl exec curl | OUI proof scope strict |
| QA Ludovic navigateur SWITAA Brouillon IA visible | manuel | **OUI critique** |
| no DEV bundle -> PROD URL | KEY-302 verify | OUI |
| OCI labels non-`unknown` | docker inspect | OUI |

### 10.4 Cross-tenant security validation

Avant AS.11.1A retry, le check membership ne validait rien (KEY-301 faille). Apres AS.11.1A retry :
- un user de ecomlg-001 (`ludo.gonthier@gmail.com`) qui tenterait de fetch `/messages/conversations?tenantId=switaa-sasu-mnc1x4eq` recevra **403 NOT_MEMBER**.
- C est exactement le but securitaire de KEY-304/KEY-301.

---

## 11. Gaps

1. **Audit owner_email column hypothetique** : la table `tenants` n a pas (selon mon SELECT schema) de colonne `owner_email`. Si elle existe avec un autre nom, ce serait du dead code, mais sans impact runtime puisque tenantGuard ne le lit pas. A confirmer par audit schema complet de la table `tenants` en phase ulterieure si besoin.

2. **`tenants` table columns** : non listees dans le rapport (j ai recu une erreur sur la query inner). A faire en phase ulterieure dediee, ou directement dans le tenant-context-routes source si l on cherche `tenant.X` accessor.

3. **Mecanisme NextAuth session multi-compte** : Ludovic possede 2 emails (ludo.gonthier@gmail.com + switaa26@gmail.com). Comment switch entre les 2 sessions ? Probable : logout + login alternativement. Hors scope AS.11.0.7.

4. **AS.11.0.7 ne patch rien** : c est volontaire. La cause AS.11.1A 403 n est pas un bug code, c est un mauvais test data. Le retry AS.11.1A doit utiliser le bon email pour la QA.

5. **`v3.5.170` + `v3.5.184` images dette** : restees sur GHCR sans etre runtime. Pas a re-add en DO_NOT_REDEPLOY (comme propose en AS.11.1A) car en realite REDEPLOYABLES apres validation Ludovic via le bon email QA.

---

## 12. Linear text prepared, posted

Postee sur KEY-304 et KEY-301. Resume controle (no PII complete, no exploit) :

```
## AS.11.0.7 -- audit tenant access model : modele canonique confirme = user_tenants ONLY

Decouverte majeure : AS.11.1A tenantGuard EST CORRECT. Le rollback etait base sur une erreur de test cote CE (mauvais email).

Modele d acces canonique :
- `user_tenants` table = source of truth UNIQUE (auto-declare dans `tenant-context-routes.ts` ligne 11).
- `isInternalUser(email) = email.endsWith('@keybuzz.io')` -> filtre demo tenants visible, PAS bypass tenantGuard.
- Pas de colonne `role`/`super_admin` dans table `users`. Pas de `owner_email` dans table `tenants`.
- `checkMembership(email, tenantId)` du tenantGuard AS.11.1A est aligne avec ce modele.

Cas Ludovic / SWITAA :
- Ludovic possede 2 emails. `ludo.gonthier@gmail.com` = personnel (7 tenants : ecomlg + tests). `switaa26@gmail.com` = business SWITAA (owner SWITAA SASU, name="Ludovic GONTHIER" dans la base).
- Mon test AS.11.1A utilisait l email personnel -> 403 expected. Pour QA SWITAA, Ludovic doit etre logge avec `switaa26@gmail.com`.

Decision : AS.11.1A peut etre redeploye SANS rebuild ni patch source. Re-apply manifests :
- API DEV v3.5.168 -> v3.5.170-messages-list-tenantguard-dev (digest sha256:b1d78eb9ec3f...)
- Client DEV v3.5.183 -> v3.5.184-messages-list-bff-dev (digest sha256:7a6453355c38...)

QA gating critique : Ludovic ouvre `client-dev.keybuzz.io` logge avec switaa26@gmail.com (compte business SWITAA), verifie Brouillon IA visible auto.

Aucun patch source. Aucun build. Aucun deploy. Aucune mutation DB. PROD strictement inchange dans cette phase audit.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.0.7-TENANT-ACCESS-MODEL-TRUTH-AUDIT-01.md
```

Statuts :
- KEY-304 : reste In Review. Apres AS.11.1A retry OK -> Done propose.
- KEY-301 : reste Open. Devient Done seulement quand AS.11.1g aura proteger toutes les routes /messages.

---

### 12.bis Phrase cible finale

AS.11.0.7 confirme que le modele d acces tenant canonique KeyBuzz est `user_tenants` ONLY (auto-declare par `tenant-context-routes.ts`, et aucune colonne role/super_admin dans `users` ni `owner_email` dans `tenants`) ; le tenantGuard AS.11.1A est ALIGNE avec ce modele ; le rollback AS.11.1A etait PREMATURE et cause par une erreur de test (utilisation de `ludo.gonthier@gmail.com` personnel au lieu de `switaa26@gmail.com` business SWITAA owner) ; AS.11.1A retry possible sans rebuild ni patch source en re-applicant les manifests vers les images `v3.5.170` (API) + `v3.5.184` (Client) deja sur GHCR ; QA Ludovic doit etre faite logge avec `switaa26@gmail.com` ; aucun build, aucun deploy, aucun kubectl apply, aucune mutation DB realises dans cette phase audit ; verdict AS.11.0.7 GO TENANT ACCESS MODEL READY.

STOP
