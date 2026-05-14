# PH-SAAS-T8.12AS.14.1-FIX-R2-CHANNELS-BFF-USER-EMAIL-INJECTION-DEV-01

> Date : 2026-05-15
> Linear : KEY-314 (parent KEY-301 Done, KEY-313 Done)
> Phase : T8.12AS.14.1-FIX (Client BFF fix pour completer AS.14.1)
> Environnement : DEV uniquement (PROD strictement inchangee)

---

## 0. VERDICT

GO CHANNELS BFF USER-EMAIL INJECTION DEV READY.

Regression QA AS.14.1 corrigee. 6 BFFs Client channels (`list`, `catalog`, `billing`, `billing-compute`, `add`, `remove`) patches pour injecter `X-User-Email` depuis NextAuth `getServerSession(authOptions)`. Pattern aligne sur AS.12.2C-5A. Cookie no longer forwarded vers API. Client DEV v3.5.197-channels-bff-userauth-dev deploye. API DEV v3.5.190-channels-tenantguard-dev inchange. QA Ludovic DEV confirmee : page Canaux refonctionne (bandeau erreur disparu, channels visibles, drawer rempli). Anti-regression Inbox + Brouillon IA + tenant switcher OK. PROD strictement inchangee.

Aucun GO PROD ni AS.14.2 sans confirmation explicite Ludovic.

---

## 1. CAUSE RACINE (RCA)

### 1.1 Symptomes QA DEV

- Bandeau "Erreur chargement du catalogue" sur /channels
- Compteur "Canaux utilises : 1 / 5" mais aucun channel visible
- Drawer "Ajouter une marketplace" vide avec message "Toutes les marketplaces ont ete ajoutees"
- Inbox / Brouillon IA / tenant switcher / escalation / playbooks : OK

### 1.2 Cause identifiee

Les 6 BFFs Client `/api/channels/{list,catalog,billing,billing-compute,add,remove}` etaient anciens (pre-AS.12.2C-*) et envoyaient au backend API :
- `X-Tenant-Id: <tenantId>`
- `Cookie: <session-cookie>`

mais **PAS** `X-User-Email`.

L'API tenantGuard verifie `user_tenants WHERE email = $1 AND tenant_id = $2`. Sans `x-user-email` header, le preHandler retourne 401 (`No email provided`).

### 1.3 Audit AS.14.0 manque

Mon audit AS.14.0 a cherche les BFFs dans `/opt/keybuzz/keybuzz-client/src/app/api/` au lieu de `/opt/keybuzz/keybuzz-client/app/api/`. Le repo Client Next.js a deux conventions de structure historiques. Resultat : 0 BFF channels detecte alors que 6 existent et sont registered.

### 1.4 Confirmation runtime probes

| Test | Resultat |
|---|---|
| BFF reproduit `X-Tenant-Id` + `Cookie` (sans `x-user-email`) | HTTP **401** |
| Meme requete avec `X-User-Email: ludo.gonthier@gmail.com` (member d un autre tenant que celui probed) | HTTP **403** |
| Pattern reference AS.12.2C-5A BFF `/api/ai/rules` | Injecte `X-User-Email` via `getServerSession(authOptions)` |

---

## 2. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.14.1-FIX only) :
- Client keybuzz-client : 6 fichiers BFF patches (`app/api/channels/{list,catalog,billing,billing-compute,add,remove}/route.ts`).
- 0 patch `services/channels.service.ts` (les fetches relatifs `/api/channels/...` restent identiques).
- 0 patch routes Client UI (pages /channels et autres).
- 0 patch API keybuzz-api (la protection AS.14.1 v3.5.190 reste active).
- 0 patch manifest API DEV (v3.5.190 reste applique).
- 0 modification PROD.
- 0 OAuth, 0 provider call, 0 mutation positive declenchee.

---

## 3. PATCH PATTERN (6 FICHIERS)

Pattern aligne sur AS.12.2C-5A BFF `/api/ai/rules` :

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../auth/[...nextauth]/auth-options';
import { getApiUrl } from '@/src/lib/api-url';

export const dynamic = 'force-dynamic';

// PH-SAAS-T8.12AS.14.1-FIX KEY-314 (2026-05-15): inject x-user-email from
// NextAuth session so API tenantGuard membership check applies cleanly.
// Pattern aligne sur AS.12.2C-5A BFF /api/ai/rules. Cookie no longer forwarded.
export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.email) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }
    const userEmail = session.user.email;

    const tenantId = request.nextUrl.searchParams.get('tenantId') || '';
    if (!tenantId) return NextResponse.json({ error: 'tenantId required' }, { status: 400 });

    const API_URL = getApiUrl();
    const res = await fetch(`${API_URL}/channels?...`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json', 'X-User-Email': userEmail, 'X-Tenant-Id': tenantId },
      cache: 'no-store',
    });
    // ... response handling
  } catch (error: any) { /* ... */ }
}
```

Changements communs aux 6 fichiers :
- AJOUT : `import { getServerSession } from 'next-auth';`
- AJOUT : `import { authOptions } from '../../auth/[...nextauth]/auth-options';`
- AJOUT : `const session = await getServerSession(authOptions);` + check email + extract userEmail
- REMPLACEMENT header : `'Cookie': request.headers.get('cookie') || ''` -> `'X-User-Email': userEmail` (Cookie no longer forwarded)
- CONSERVATION : `X-Tenant-Id`

Pattern variant pour billing-compute (utilise `process.env.BACKEND_URL`) et POST (add/remove) : meme injection x-user-email, conservation body tenantId.

Diff stat : `6 files changed, 72 insertions(+), 6 deletions(-)`.

---

## 4. PREFLIGHT POST-RCA

| Repo | Branche | HEAD avant | HEAD apres | Sync | Verdict |
|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | b726970 | 3fe90ab | 0/0 | OK |
| keybuzz-infra | main | 4899747 | fc2e5dd | 0/0 | OK |
| keybuzz-api | ph147.4/source-of-truth | 7a09c005 | 7a09c005 (inchange) | 0/0 | OK |

Runtime images avant fix :
- API DEV : v3.5.190-channels-tenantguard-dev (AS.14.1)
- Client DEV : v3.5.196-ai-rules-bff-dev
- API PROD : v3.5.189-compat-amazon-tenantguard-prod
- Client PROD : v3.5.196-ai-rules-bff-prod

Tag GHCR `v3.5.197-channels-bff-userauth-dev` : libre (verifie KEY-309).

---

## 5. BUILD CLIENT DEV

| Champ | Valeur |
|---|---|
| Tag | v3.5.197-channels-bff-userauth-dev |
| Branche source | ph148/onboarding-activation-replay |
| Commit source | 3fe90ab (full: 3fe90abb21e9344016b2433a76a2d68eca1f0b65) |
| Mode | build-from-git (fresh clone) |
| Image ID | sha256:4b5590665d1275fea1284a433183208e616ce1ac7e6e8b7cd20e0f564b109183 |
| Manifest digest GHCR | sha256:ed86032d55a27907556d44f475873d6b0f487472922bdc1cab3b755b69458ecc |

### 5.1 KEY-302 bundle guard (verify-image-clean.sh)

```
RESULTATS: 17 PASS / 0 FAIL / 0 WARN
VERDICT: PASS -- Image valide
```

Verifications cles :
- URL contamination : api-dev.keybuzz.io PRESENT, api.keybuzz.io ABSENT
- Pages : /dashboard, /channels, /settings, /billing, /login, /register, /locked, /onboarding, /orders -> PASS
- Page size sanity : /inbox, /dashboard, /settings > 500 bytes -> PASS
- Routes manifest complete -> PASS
- Signup page non-regression (redirect, not full form) -> PASS

### 5.2 KEY-308 OCI labels

| Label | Valeur |
|---|---|
| org.opencontainers.image.created | 2026-05-14T22:07:41Z |
| org.opencontainers.image.revision | 3fe90abb21e9344016b2433a76a2d68eca1f0b65 |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client |
| org.opencontainers.image.title | keybuzz-client |
| org.opencontainers.image.version | v3.5.197-channels-bff-userauth-dev |

Rollback prevu : v3.5.196-ai-rules-bff-dev (image disponible).

---

## 6. GITOPS DEV

| Champ | Valeur |
|---|---|
| Manifest patche | k8s/keybuzz-client-dev/deployment.yaml ligne 77 |
| Diff scope | 1 fichier, 1 ligne (image v3.5.196 -> v3.5.197) |
| Commit infra | fc2e5dd deploy(dev): channels BFF inject x-user-email (KEY-314 AS.14.1-FIX) |
| Push origin | 4899747..fc2e5dd main -> main |
| kubectl apply | deployment.apps/keybuzz-client configured |
| Rollout status | successfully rolled out (240s timeout) |

Triple-egalite post-rollout :

| Source | Valeur |
|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-client:v3.5.197-channels-bff-userauth-dev |
| last-applied-configuration | ghcr.io/keybuzzio/keybuzz-client:v3.5.197-channels-bff-userauth-dev |
| pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:ed86032d55a27907556d44f475873d6b0f487472922bdc1cab3b755b69458ecc |
| GHCR manifest digest | sha256:ed86032d55a27907556d44f475873d6b0f487472922bdc1cab3b755b69458ecc |

Convergence : MATCH. Deploy status ready=1/1.

---

## 7. VALIDATION DEV

### 7.1 BFFs no-auth (probes safe)

| Endpoint BFF | Resultat | Interpretation |
|---|---|---|
| GET /api/channels/list | 307 redirect /auth/signin | Middleware Client AuthGuard intercepte avant route handler |
| GET /api/channels/catalog | 307 redirect /auth/signin | idem |
| GET /api/channels/billing | 307 redirect /auth/signin | idem |
| GET /api/channels/billing-compute | 307 redirect /auth/signin | idem |
| GET /api/channels/registry | 200 OK | Public legitime (registry statique, pas de tenantId requis) |

Defense in-depth : la couche AuthGuard middleware Client redirige les non-authentifies AVANT meme d atteindre le route handler. Le `getServerSession` check dans le route handler est une 2eme barriere.

### 7.2 Logs Client DEV (last 5 min)

| Verification | Resultat |
|---|---|
| 5xx errors | 0 |
| Erreurs channels BFFs | 0 |

### 7.3 Logs API DEV (post-fix, requetes Client UI Ludovic)

API DEV a recu durant la QA Ludovic post-fix les 4 endpoints `/channels`, `/channels/billing`, `/channels/billing-compute`, `/channels/catalog` avec tenantId `switaa-sasu-mnc1x4eq` (tenant reel Ludovic) depuis le pod Client (10.244.118.114). Aucun 5xx, aucun 401, aucun 403 sur ces requetes (Ludovic confirme UI fonctionnelle = response 200).

### 7.4 QA Ludovic DEV (confirme par Ludovic)

| Surface | Avant fix | Apres fix |
|---|---|---|
| /channels bandeau erreur catalogue | PRESENT | DISPARU |
| /channels liste channels actifs | VIDE (compteur 1/5 affiche mais zero element) | VISIBLE |
| /channels drawer "Ajouter une marketplace" | VIDE ("Toutes ajoutees") | REMPLI |
| /inbox | OK | OK |
| Brouillon IA | OK | OK |
| Tenant switcher | OK | OK |
| Escalation | OK | OK (preserve AS.12.x) |
| Playbooks read-only | OK | OK |

### 7.5 Aucune action mutationnelle

Aucun POST add/remove/activate-amazon emis pendant la validation et la QA. Aucune mutation DB declenchee par cette phase. Aucun provider call.

### 7.6 PROD inchangee

| Service | Image PROD | Statut |
|---|---|---|
| keybuzz-api | v3.5.189-compat-amazon-tenantguard-prod | inchange |
| keybuzz-client | v3.5.196-ai-rules-bff-prod | inchange |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | inchange |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | inchange |

### 7.7 API DEV inchangee

API DEV reste v3.5.190-channels-tenantguard-dev (AS.14.1). La protection tenantGuard cote API est conservee operationnelle. Le fix ne touche que le Client BFF qui injecte maintenant correctement `X-User-Email`.

---

## 8. AI FEATURE PARITY / ANTI-REGRESSION

| Surface | Statut |
|---|---|
| Inbox messages | preserve (AS.12.1A actif, BFFs `/api/messages/conversations` inchange) |
| Brouillon IA (assist/evaluate/execute/guard) | preserve (AS.12.2C-1/2/3/4 actifs) |
| AI rules / playbooks (AS.12.2C-5A/5B) | preserve |
| Tenant switcher | preserve |
| Escalation | preserve |
| Notifications | preserve |
| Autopilot | preserve |
| Channels (nouveau) | FIXED via x-user-email injection |

Aucune regression detectee post-fix.

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
- 0 evenement GA4 / CAPI / TikTok / LinkedIn
- 0 token exchange
- 0 mutation DB volontaire

---

## 10. NON-REGRESSION PROD (avant / apres AS.14.1-FIX)

| Service | Image PROD avant | Image PROD apres | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.189-compat-amazon-tenantguard-prod | v3.5.189-compat-amazon-tenantguard-prod | UNCHANGED |
| keybuzz-client | v3.5.196-ai-rules-bff-prod | v3.5.196-ai-rules-bff-prod | UNCHANGED |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | UNCHANGED |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | UNCHANGED |

PROD strictement inchangee. Aucune action runtime PROD pendant AS.14.1-FIX.

---

## 11. LINEAR

Commentaire propose pour KEY-314 (disclosure-controlled, sans PoC, sans payload, sans secret) :

```
PH-SAAS-T8.12AS.14.1-FIX R2 channels BFF user-email injection DEV livre.

Resolution regression QA AS.14.1 : 6 BFFs Client channels (list, catalog, billing, billing-compute, add, remove) patches pour injecter X-User-Email depuis NextAuth session via getServerSession(authOptions). Pattern aligne sur AS.12.2C-5A BFF /api/ai/rules. Cookie no longer forwarded vers API. Aucun patch services/channels.service.ts.

Cause racine : les 6 BFFs Client etaient anciens (pre-AS.12.2C-*) et envoyaient X-Tenant-Id + Cookie mais pas X-User-Email. tenantGuard exige email + tenantId pour user_tenants membership check -> sans email -> 401 -> page Canaux non fonctionnelle (bandeau erreur catalogue, channels invisibles, drawer vide).

Audit AS.14.0 a manque les BFFs car cherche dans src/app/api/ au lieu de app/api/ (deux conventions de structure historiques dans le repo Client).

Build :
- Client DEV v3.5.197-channels-bff-userauth-dev
- Build-from-git sur ph148/onboarding-activation-replay commit 3fe90ab
- KEY-302 bundle guard 17/17 PASS (api-dev.keybuzz.io present, api.keybuzz.io absent)
- KEY-308 OCI labels complets

GitOps :
- Commit manifest keybuzz-infra fc2e5dd deploy(dev) push origin main
- kubectl apply Client DEV uniquement
- Rollout successful, triple-egalite spec=last-applied=podImageID=GHCR digest

Validation DEV :
- BFFs no-auth : 307 redirect /auth/signin (middleware AuthGuard) - defense in-depth attendue
- /api/channels/registry public : 200 OK
- API DEV logs : 4 endpoints /channels frappes avec tenant reel post-fix, response 200 (Ludovic confirme UI)
- 0 5xx Client / API
- 0 mutation
- 0 provider call

QA Ludovic DEV confirmee : page /channels refonctionne (bandeau erreur disparu, channels visibles, drawer rempli). Anti-regression Inbox + Brouillon IA + tenant switcher OK.

API DEV reste v3.5.190-channels-tenantguard-dev (AS.14.1 inchange). PROD strictement inchangee sur 4 services. 

KEY-314 reste Open. KEY-301 et KEY-313 restent Done. Aucun GO PROD AS.14.1 + AS.14.1-FIX ni AS.14.2 sans GO Ludovic explicite.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.14.1-FIX-R2-CHANNELS-BFF-USER-EMAIL-INJECTION-DEV-01.md
```

KEY-314 reste Open. KEY-301 et KEY-313 restent Done.

---

## 12. ROLLBACK READY

Plan rollback Client DEV (si regression future) :

```
cd /opt/keybuzz/keybuzz-infra
git revert fc2e5dd
git push origin main
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client --timeout=240s
```

Resultat attendu : retour Client DEV a v3.5.196-ai-rules-bff-dev. Note : ce rollback re-introduit le bug 401 (channels page KO) tant que API DEV reste v3.5.190. Si rollback necessaire, considerer en parallele rollback API DEV vers v3.5.189-compat-amazon-tenantguard-dev (re-ouvre la vulnerabilite cross-tenant en DEV mais re-active la page Canaux).

Aucun rollback necessaire post-fix : 0 regression detectee, QA Ludovic OK.

---

## 13. GAPS / UNKNOWNS

| Gap | Statut | Resolution |
|---|---|---|
| Pattern audit AS.14.0 manque BFF channels | NOTED | Mise a jour memoire MEMORY.md : audit BFF Client doit chercher dans `/app/api/` ET `/src/app/api/` (2 conventions historiques) |
| Probable autres BFFs avec meme pattern Cookie-only (suppliers, integrations, etc.) | A INVESTIGUER | Avant AS.14.2 (suppliers) : audit explicite BFF suppliers + integrations + shopify dans `/app/api/` |
| Bundle Client DEV taille | NORMAL | KEY-302 17/17 PASS |

---

## 14. PHRASE CIBLE FINALE

R2 channels BFFs corriges en DEV : 6 BFFs patches pour injecter X-User-Email depuis NextAuth session. Page Canaux refonctionne. API DEV v3.5.190 tenantGuard reste actif. PROD strictement inchangee. Aucun GO PROD AS.14.1 + AS.14.1-FIX sans GO Ludovic explicite.

STOP
