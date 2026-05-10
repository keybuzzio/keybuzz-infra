# PH-SAAS-T8.12AS.3 -- Tenant Guard Runtime Truth Audit

> Date : 2026-05-11
> Linear : KEY-301 (Security) ; KEY-263 (incident parent)
> Phase : audit READ-ONLY runtime DEV+PROD du tenantGuardPlugin avant toute promotion AS.1
> Environnement : DEV + PROD strictement READ-ONLY -- aucun build, aucun deploy, aucune mutation runtime ni DB

## VERDICT

**NO GO SECURITY -- PROD CROSS-TENANT RISK CONFIRMED -- PATCH REQUIRED BEFORE ANY PROMOTION**

Le `tenantGuardPlugin` source de keybuzz-api est exporte sans `fastify-plugin` wrapper. Le `fastify.addHook('preHandler')` declare a l'interieur du plugin est ainsi confine au scope encapsule cree par `app.register(tenantGuardPlugin)` et ne s'applique a AUCUNE des routes registered en sibling scope (notifications, messages, autopilot, stats, etc.).

Verifie en runtime DEV (real tenant) : `GET https://api-dev.keybuzz.io/messages/conversations?tenantId=<real-tenant-dev>&limit=1` sans aucun header d'authentification retourne **HTTP 200 + body 1214 bytes contenant des donnees client reelles** (id, subject, customer_name, channel, status). Comportement reproduit en cluster-internal (bypass ingress) -- le bug est dans le pod, pas dans l'ingress.

Verifie en runtime PROD (fake tenant inexistant, no PII) : `GET https://api.keybuzz.io/messages/conversations?tenantId=<fake>&limit=1` sans auth retourne **HTTP 200 + body 2 bytes ([])**. La route s'execute sans guard ; le body vide vient simplement du filtre SQL sur un tenant inexistant. Le pattern PROD est identique au pattern DEV.

**Risque concret PROD** : un attaquant avec uniquement la connaissance d'un tenantId reel peut lire les conversations, les notifications, etc. depuis Internet sans aucune authentification. Les routes mutation (`PATCH /notifications/:id/ack`, `POST /messages/conversations/:id/reply`, `POST /notifications/simulate`) sont egalement accessibles.

La promotion AS.1 PROD du badge escalation est **bloquee** par cette faille critique multi-tenant. Toute autre feature dependant de la membership tenant l'est aussi.

---

## 0. Preflight (READ-ONLY)

### Repos bastion install-v3

| Repo | Branche attendue | Branche reelle | HEAD | Sync origin | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 070707a1 | 0/0 | 223 fichiers `D dist/*.js` (artifacts trackes en git, supprimes localement, sans .gitignore) -- explique et compris | OK COMPRIS |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | f244a58 | 0/0 | tsconfig.tsbuildinfo artifact | OK |
| keybuzz-infra | main | main | cb55a42 | 0/0 | clean | OK |

Bastion : install-v3, IP 46.62.171.61.

---

## 1. Runtime baseline (READ-ONLY)

| Service | Runtime image | Last-applied image | Pod ready | Match | Attendu |
|---|---|---|---|---|---|
| API DEV | v3.5.168-escalation-notifications-dev | identique | 1/1, age 3h8m | OK | OK |
| Client DEV | v3.5.179-as1-1-build-args-fix-dev | identique | 1/1, age 82m | OK | OK |
| API PROD | v3.5.151-conversation-tone-metric-prod | identique | 1/1, age 18h | OK | OK |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | identique | 1/1, age 18h | OK | OK |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | identique | 1/1, age 4d13h | OK | OK |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | identique | 2/2, age 47h | OK | OK |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | identique | 1/1, age 39h | OK | OK |
| OW PROD | v3.5.165-escalation-flow-prod | identique | 1/1, age 30d (7 restarts, last 11d ago) | OK | OK |
| OW DEV | v3.5.165-escalation-flow-dev | identique | 1/1, age 30d (8 restarts, last 11d ago) | OK | OK |

DEV coherent GitOps. PROD inchangee. Aucun drift bloquant.

---

## 2. Source audit -- tenantGuardPlugin (`src/plugins/tenantGuard.ts`, 105 lignes)

| Point | Fichier/ligne | Comportement attendu | Risque source |
|---|---|---|---|
| Enregistrement | `src/app.ts:103` `await app.register(tenantGuardPlugin)` | Hook preHandler global | **CRITIQUE -- voir cause racine ci-dessous** |
| Exemptions exactes | `tenantGuard.ts:24` | `/`, `/health` | OK |
| Exemptions par prefix | `tenantGuard.ts:13-23` | `/health`, `/auth`, `/tenant-context`, `/space-invites`, `/billing/stripe/webhook`, `/public`, `/inbound`, `/api/v1/tracking/webhook`, `/debug`, `/api/v1/orders/webhook`, `/octopia/marketplaces/octopia/sync` | OK design |
| Exemption methode | `tenantGuard.ts:28` | `OPTIONS` (CORS preflight) | OK |
| Resolution tenantId | `tenantGuard.ts:34-46` | priorite query.tenantId > header x-tenant-id > body.tenantId | OK |
| Resolution user identity | `tenantGuard.ts:91` | header x-user-email (must contain `@`) | OK |
| Membership SQL | `tenantGuard.ts:60-66` | `SELECT 1 FROM user_tenants ut JOIN users u WHERE u.email = $1 AND ut.tenant_id = $2 LIMIT 1` (lowercased email, params SQL safe) | OK |
| Cache | `tenantGuard.ts:48-50` | in-memory map, TTL 30s, max 10000 | OK |
| Sans tenantId | `tenantGuard.ts:88` | 400 TENANT_ID_MISSING | OK design |
| Sans email valide | `tenantGuard.ts:94` | 401 AUTH_REQUIRED | OK design |
| Pas membre | `tenantGuard.ts:99-101` | 403 + log warn `[TenantGuard] DENIED cross-tenant access` | OK design |
| Mode DEV permissif | aucun | -- | OK -- aucun bypass conditionnel |

### CAUSE RACINE TECHNIQUE

`src/plugins/tenantGuard.ts` est exporte ainsi :

```ts
export async function tenantGuardPlugin(fastify: FastifyInstance) {
  fastify.addHook('preHandler', async (request, reply) => { ... });
}
```

**Aucun `fastify-plugin` wrapper.** Aucun `fp(...)`. Aucune balise `name` ni `'fastify-plugin'` declaration.

Comportement Fastify : quand `app.register(tenantGuardPlugin)` est appele, Fastify cree un nouveau scope encapsule pour ce plugin. Le `fastify.addHook('preHandler', ...)` est ajoute au scope local du plugin, pas au scope parent `app`. Les routes registered ulterieurement via `app.register(routesXxx, ...)` aux lignes 147+ de `src/app.ts` sont des SCOPES SIBLINGS de celui du plugin, pas des enfants. Les hooks confines au scope tenantGuard ne se propagent pas a ces siblings.

Resultat : le hook `preHandler` du tenantGuardPlugin n'est JAMAIS execute pour les routes notifications, messages, autopilot, stats, etc. Le plugin est effectivement un no-op depuis sa creation.

`grep fastify-plugin src/plugins/` confirme : aucune occurrence dans aucun plugin. Le pattern correct serait :

```ts
import fp from 'fastify-plugin';
export const tenantGuardPlugin = fp(async (fastify) => {
  fastify.addHook('preHandler', async (request, reply) => { ... });
});
```

Ou alternativement : ajouter le hook directement sur `app` dans `app.ts`, sans passer par un plugin encapsule.

---

## 3. Source audit -- notifications routes (`src/modules/notifications/routes.ts`, 271 lignes)

| Route | Guard global (theorique) | Ownership DB | Mutation | Risque effectif |
|---|---|---|---|---|
| GET `/notifications` | NON applique (bug) | filtre conditionnel `AND tenant_id = $X` (si tenantId fourni en query) | NON | Eleve -- sans guard, accessible sans auth ; sans tenantId, retourne TOUTES les notifications de TOUS les tenants |
| GET `/notifications/:id` | NON applique (bug) | `WHERE id = $1 AND tenant_id = $2` | NON | Modere -- ownership SQL limite l'acces, mais lecture cross-tenant possible si on connait la paire (id, tenantId) |
| PATCH `/notifications/:id/ack` | NON applique (bug) | `WHERE id = $1 AND tenant_id = $2` `RETURNING ...` | OUI (UPDATE status='acknowledged') | Eleve -- mutation cross-tenant possible si on connait (id, tenantId) |
| POST `/notifications/simulate` | NON applique (bug) | aucune ownership (INSERT direct avec tenantId du body) | OUI (INSERT) | Critique -- INSERT dans n'importe quel tenant, aucun garde-fou |

---

## 4. Source audit -- conversations routes (`src/modules/messages/routes.ts`, 1169 lignes)

| Route | Guard (theorique) | SQL tenant filter | Ownership | Risque effectif |
|---|---|---|---|---|
| GET `/messages/conversations` | NON applique (bug) | `tenant_id = $X` requis (400 du handler sinon) | n/a (list) | Eleve -- list cross-tenant accessible sans auth |
| GET `/messages/conversations/:id` | NON applique (bug) | `WHERE id = $1 AND tenant_id = $2` | OUI | Modere -- ownership SQL limite, lecture cross-tenant possible si on connait (id, tenantId) |
| POST `/messages/conversations/:id/reply` | NON applique (bug) | `convCheck SELECT WHERE id = $1 AND tenant_id = $2`, puis utilise `convCheck.rows[0].tenant_id` comme source de verite | OUI | Critique -- envoi de message au nom du tenant possible si on connait (id, tenantId), suivi d'un INSERT dans messages, et potentielle escalation/auto-assign side-effects |
| PATCH `/messages/conversations/:id/status` | NON applique (bug) | `WHERE id AND tenant_id` | OUI | Eleve -- mutation status (resolved/etc) cross-tenant possible |

---

## 5. Audit Client / BFF

| Surface Client | Source tenant | Source user | Appel API | Risque relatif |
|---|---|---|---|---|
| BFF `/api/notifications` (`app/api/notifications/route.ts`) | query.tenantId fourni par caller | NextAuth `session.email` (server-side) | inject `X-User-Email` + `X-Tenant-Id` headers | Headers correctement injectes -- mais inutile car guard API inactif. Aucune protection c'est la source de verite pour la membership. |
| BFF `/api/stats/conversations` | query.tenantId | session.email | inject X-User-Email seul | Idem |
| `useTenant().currentTenantId` (`src/features/tenant/TenantProvider.tsx:48`) | `getTenantContext()` derive de la session NextAuth | n/a | n/a | OK source unique cote Client |
| Direct browser fetch `fetchConversations` (`src/services/conversations.service.ts:160`) | tenantId query | cookies session domain `.keybuzz.io` (forwardes) | direct vers `https://api[-dev].keybuzz.io/messages/conversations?tenantId=...` | Le browser envoie cookies session, mais l'API ne les utilise pas (seulement `x-user-email` header). Le BFF est le seul a injecter cet header. Un appel direct browser sans BFF n'aura pas de header email -- mais l'API repond 200 quand meme car le guard est inactif. |

Cookie scope `.keybuzz.io` (vu dans le bundle code auth-options) -- partage entre app.keybuzz.io et app-dev.keybuzz.io. Mais la session cote API ne s'appuie pas sur le cookie en l'etat ; seulement sur l'header `x-user-email` injecte par les BFF. Le BFF est censur etre la seule entree, mais en pratique l'API est exposee directement.

---

## 6. Tests HTTP DEV (READ-ONLY)

### Acces via ingress public api-dev.keybuzz.io

| # | Endpoint | Headers | Status | Body summary | Interpretation |
|---|---|---|---|---|---|
| T1 | GET /health | aucun | 200 | 96 bytes | OK exempt |
| T2 | GET /notifications?tenantId=<real-tenant>&channel=escalation&status=pending&limit=1 | aucun | **200** | 2 ([]) | Route executee sans guard ; SQL retourne 0 row pour ces filtres (table notifications vide en DEV) |
| T3 | GET /notifications | aucun | **200** | 2 ([]) | Route executee sans guard ; query sans tenantId retournerait toutes notifs, mais table vide |
| T4 | GET /notifications?... avec x-tenant-id seul | partiel | **200** | 2 ([]) | Idem |
| T5 | GET /notifications?tenantId=<real>&... avec x-user-email bogus | partiel | **200** | 2 ([]) | Idem -- guard ne valide pas |
| T6 | GET /messages/conversations?tenantId=<real-tenant-dev>&limit=1 | aucun | **200** | **1214 bytes contenant DATA REELLE (id, subject, customer_name, channel, status, ...)** | **PREUVE DEFINITIVE -- fuite cross-tenant confirmee, donnees PII renvoyees sans aucune auth** |
| T7 | GET /notifications/notif-fake-12345?tenantId=<real-tenant> | aucun | 404 | 34 bytes (`{"error":"Notification not found"}`) | Handler-level 404 (pas du guard) ; ownership SQL fonctionne, mais sans guard, un attaquant peut enumerer les ids existants en testant /notifications list |

### Acces direct cluster-internal (bypass ingress)

Test depuis le pod `keybuzz-client` du namespace `keybuzz-client-dev` vers `http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001/messages/conversations?tenantId=<real>&limit=1` :

```
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8
content-length: 1214
```

**Le bug n'est pas dans l'ingress.** Le pod API DEV repond directement 200 + data sans auth. L'ingress n'a aucune annotation OAuth/mTLS/header-injection -- juste rate limiting standard.

### Logs

`kubectl logs -l app=keybuzz-api -n keybuzz-api-dev --tail=300 --since=15m | grep -iE 'tenant.?guard|TENANT_ID_MISSING|AUTH_REQUIRED|cross-tenant'` retourne **ZERO ligne**. Le hook tenantGuard n'a jamais ete declenche.

### Env

`kubectl exec -- env | grep -iE 'TENANT|GUARD|BYPASS|DISABLE|PERMISS|DEV_MODE|AUTH'` ne retourne aucune flag de mode permissif. `NODE_ENV=development` est present mais le code source ne contient aucun bypass conditionnel sur cette variable.

---

## 7. Tests HTTP PROD (READ-ONLY, fake tenants pour eviter PII)

### Acces via ingress public api.keybuzz.io

| # | Endpoint | Headers | Status | Body | Interpretation |
|---|---|---|---|---|---|
| T1 PROD | GET /health | aucun | 200 | 96 bytes | OK exempt |
| T2 PROD | GET /messages/conversations?tenantId=nonexistent-test-xyz123&limit=1 | aucun | **200** | 2 ([]) | Route executee sans guard ; tenantId inexistant -> SQL retourne 0 row -> [] |
| T3 PROD | GET /notifications?tenantId=nonexistent-test-xyz123&limit=1 | aucun | **200** | 2 ([]) | Idem |
| T4 PROD | GET /messages/conversations (sans tenantId) | aucun | 400 | 32 bytes | **400 du HANDLER** (msg routes ont `if (!tenantId) reply 400` au debut du handler), pas du guard. Si le guard etait actif, on aurait `400 TENANT_ID_MISSING` avec body plus long. |
| T5 PROD | GET /notifications (sans tenantId) | aucun | **200** | 2 ([]) | Notifications handler ne valide pas tenantId presence (juste un optional WHERE) -> retourne TOUTES les notifs PROD si la table contient -- ici body=[] suggere que sans tenantId, le SQL renvoie 0 par autre cause, ou table vide PROD aussi |

### Test cluster-internal PROD

Tentative depuis pod `keybuzz-client` PROD vers service API PROD : connexion timeout (network policy entre namespaces, isolation correcte cote cluster). **L'isolation cluster-internal n'est PAS la protection en cause** : le risque est l'API exposee publiquement via ingress sans guard.

### Conclusion PROD

PROD reproduit exactement le pattern DEV. Le `tenantGuardPlugin` est inactif au runtime PROD aussi. Les tests avec fake tenants ont volontairement evite de reveler des donnees clients reelles. Aucun test PROD n'a ete fait avec un tenantId reel. La coherence du pattern source + DEV runtime + PROD pattern (avec route executee sans guard) est suffisante pour conclure.

---

## 8. Cross-tenant analysis (sans mutation)

| Cas | Preuve source | Preuve runtime read-only | Verdict |
|---|---|---|---|
| GET list cross-tenant possible | guard inactif (bug encapsulation), handler list filtre par tenantId si fourni mais accepte sans auth | DEV T6 retourne 1214 bytes data avec real tenant ; PROD T2 retourne 200 [] avec fake tenant | **CONFIRME** |
| GET by id cross-tenant possible | ownership `WHERE id AND tenant_id` au handler -- protege si attaquant ne connait pas la paire | DEV T7 retourne 404 sur fake id, mais avec real id l'ownership SQL renverrait la donnee | Possible si enumeration |
| PATCH ack cross-tenant possible | ownership `WHERE id AND tenant_id` -- protege si paire inconnue | non teste (mutation interdite) | Possible si paire connue ; preuve runtime requiert micro-phase mutationnelle dediee (STOP, hors scope) |
| POST simulate cross-tenant possible | aucune ownership ; INSERT direct avec tenantId du body | non teste (mutation interdite) | Tres probable -- INSERT dans n'importe quel tenant. Preuve runtime requiert micro-phase mutationnelle dediee. |
| POST reply cross-tenant possible | ownership convCheck `WHERE id AND tenant_id` ; protege si paire inconnue | non teste (mutation interdite) | Possible si paire connue ; preuve runtime requiert micro-phase mutationnelle dediee. |

Aucune mutation reelle n'a ete tentee dans cette phase. Les hypotheses mutation sont basees sur l'analyse source. Si une preuve mutationnelle est requise, ouvrir une micro-phase dediee avec un GO Ludovic explicite et un tenant test/sandbox dedie.

---

## 9. Classification du comportement 200 [] observe pendant AS.1

| Hypothese | Preuve pour | Preuve contre | Verdict |
|---|---|---|---|
| A. Mode DEV permissif volontaire | Initialement plausible (rapport AS.1 evoquait NODE_ENV=development) | env pod ne contient aucune flag de bypass ; PROD reproduit le pattern -- ce n'est donc pas DEV-only | REJETE |
| B. TenantGuard actif, SQL filtre = empty set | Plausible pour T2-T5 DEV et T2-T5 PROD (notifications []) | DEV T6 (real tenant conversations) retourne 1214 bytes de data sans auth -- pas un empty set | PARTIEL : explique seulement les [] de notifications (table vide) ; n'explique pas T6 conversations |
| C. Route exemptee par erreur | Plausible | `/notifications` et `/messages/conversations` ne sont PAS dans EXEMPT_PREFIXES | REJETE |
| D. Ingress/BFF/session bypass de test | Initialement plausible | Direct cluster-internal (bypass ingress complet) reproduit le meme 200 + data | REJETE |
| E. Absence de donnees | Vrai pour table notifications DEV et PROD apparemment | Mais T6 conversations retourne data reelle | PARTIEL |
| F. **Faille reelle membership : guard plugin encapsule Fastify, hook scope-only, ne s'applique pas aux routes en sibling scope** | `tenantGuardPlugin` source n'utilise PAS `fastify-plugin` ; DEV runtime confirme 200 + data sans auth ; PROD runtime confirme route executee sans auth ; aucun log `[TenantGuard]` jamais emis | aucune | **CAUSE RACINE CONFIRMEE** |

Le 200 [] observe pendant AS.1 etait composite : (a) le guard etait deja inactif (faille existante avant AS.1), et (b) la table notifications etait vide donc le filtre SQL legitime renvoyait 0 row. La fuite cross-tenant etait deja presente sur les routes ayant des donnees (conversations), mais n'avait pas ete detectee parce que les tests AS.1 portaient sur notifications -- table vide -> [] -> pas alarmant.

---

## 10. Non-regression (READ-ONLY phase)

| Surface | Avant phase | Apres phase | Statut |
|---|---|---|---|
| API DEV runtime | v3.5.168-escalation-notifications-dev | v3.5.168-escalation-notifications-dev | INCHANGE |
| Client DEV runtime | v3.5.179-as1-1-build-args-fix-dev | v3.5.179-as1-1-build-args-fix-dev | INCHANGE |
| API PROD runtime | v3.5.151-conversation-tone-metric-prod | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD runtime | v3.5.174-conversation-tone-metric-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| OW DEV / OW PROD | v3.5.165-escalation-flow-* | identiques | INCHANGE |
| DB | aucune mutation | aucune mutation | INCHANGE |
| Manifests GitOps | aucun modifie | aucun modifie | INCHANGE |
| Pods | aucun restart cause par cette phase | identique | INCHANGE |

Aucun build, aucun docker push, aucun kubectl apply, aucun set image / patch / edit / set env. Aucune mutation runtime. Phase READ-ONLY respectee.

---

## 11. Gaps restants

1. **Patch tenantGuardPlugin requis avant toute promotion PROD multi-tenant**. Implementation proposee :
   ```ts
   import fp from 'fastify-plugin';
   export const tenantGuardPlugin = fp(async (fastify) => {
     fastify.addHook('preHandler', async (request, reply) => { ... });
   });
   ```
   ou alternativement, ajouter `app.addHook('preHandler', ...)` directement dans `app.ts` (eliminer le plugin encapsule).
2. **Audit complementaire post-patch** : tester que toutes les routes critiques (notifications, messages, autopilot, stats, ai, suppliers, channels, billing, etc.) retournent bien 401/403 sans auth apres le patch. Pas seulement notifications.
3. **Audit autres plugins potentiellement affectes** : `rateLimiter`, `requestContext`, `postgres` -- verifier si l'un de ces plugins utilise aussi `addHook` sans `fastify-plugin`. Ils pourraient avoir le meme defaut sans symptome visible.
4. **Verification mutationnelle differee** : pour confirmer que `POST /notifications/simulate` est bien exploitable cross-tenant, une micro-phase mutationnelle dediee (avec un tenant test sandbox + GO Ludovic explicite) serait necessaire. Hors scope de cette phase READ-ONLY.
5. **Absence de GIT_COMMIT_SHA dans le pod API runtime** : empeche de tracer quel commit exact tourne en runtime. Idealement, exposer un endpoint /version qui rapporte le commit baked into l'image.
6. **AS.1 PROD reste BLOQUE** : la promotion du badge escalation depend du guard. Pas de promotion possible avant patch + retest.
7. **KEY-302 deja Done** : Dockerfile Client hardened (build args). Independant de cette faille.
8. **Image v3.5.177-escalation-notifications-ux-dev** encore en cache local Docker bastion : peut etre extraite et son bundle inspecte pour confirmer empiriquement l'hypothese build args (innocenter le code AS.1 definitivement). Optionnel.

---

## 12. Decision sur AS.1 PROD

**AS.1 PROD : BLOQUE jusqu'a patch tenantGuardPlugin + retest runtime DEV+PROD post-deploy.**

Le badge escalation cote Client n'est qu'une UI ; mais sa source de verite est `/notifications`, qui est exposee sans authentification en l'etat. Promouvoir le badge sans patcher la faille reviendrait a (a) afficher des compteurs derives de donnees non-autorisees, (b) potentiellement aggraver l'exposition en augmentant la surface d'API hits, (c) communiquer publiquement sur une feature qui repose sur une auth defectueuse.

Decision recommandee :

1. Ouvrir une phase patch `PH-SAAS-T8.12AS.4-TENANT-GUARD-PLUGIN-FIX-DEV` (KEY-303 a creer) qui :
   - patch `src/plugins/tenantGuard.ts` pour utiliser `fastify-plugin`
   - retest runtime DEV (toutes routes critiques 401/403 sans auth)
   - GO PROD apres validation
2. Apres patch deploye en DEV puis en PROD avec tests negatifs verts, reprendre AS.1 cote Client (reactiver callsite + nouveau build) sur clean slate.
3. KEY-301 reste open jusqu'au deploy patch en PROD + revalidation.

---

## 13. Rollback

Aucun rollback runtime applicable -- phase READ-ONLY strict, aucun deploy ni mutation.

Si le rapport contient une erreur factuelle, corriger par nouveau commit doc dans keybuzz-infra (ne pas reset historique).

---

## 14. Phrase cible finale

L'audit READ-ONLY AS.3 (KEY-301) a etabli que le `tenantGuardPlugin` source est exporte sans `fastify-plugin` wrapper et reste donc encapsule dans son scope Fastify, ce qui rend le hook `preHandler` inactif sur l'ensemble des routes API ; verifie en runtime DEV par fuite reelle de donnees conversations PII sur GET /messages/conversations sans auth, et reproduit en PROD avec fake tenants montrant que la route s'execute toujours sans guard ; aucun build, aucun deploy, aucune mutation runtime ni DB ; AS.1 PROD est bloque jusqu'a patch tenantGuardPlugin (KEY-303 a ouvrir), redeploy DEV puis PROD, et revalidation runtime que toutes les routes critiques retournent 401/403 sans auth ; KEY-301 reste open ; KEY-302 reste Done.

STOP -- audit livre, decision sur ouverture KEY-303 patch en attente Ludovic.
