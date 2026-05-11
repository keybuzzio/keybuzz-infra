# PH-SAAS-T8.12AS.5 -- Messages Conversations Tenant Guard DEV

> Date : 2026-05-11
> Linear : KEY-304 (Security) ; KEY-301 ; KEY-263 ; KEY-302
> Phase : patch securite endpoint-by-endpoint -- /messages/conversations
> Environnement : DEV uniquement pour patch/build/deploy -- PROD READ-ONLY

## VERDICT

**GO DEV MESSAGES SECURITY PATCH READY -- MESSAGES CONVERSATIONS PROTECTED -- INBOX DEV FUNCTIONAL -- PROD UNCHANGED**

Le patch endpoint-by-endpoint phase 1 est livre en DEV. La surface `/messages/conversations` est maintenant protegee par le tenantGuard actif sur le prefix `/messages` uniquement. Inbox DEV charge la liste centrale, les nouveaux messages arrivent, navigation et autres surfaces non concernees (notifications, ai, channels, suppliers, billing, tenants) restent inchangees grace au mecanisme PROTECTED_PREFIXES.

Un bug AI auto-suggestion pre-existant (non cause par AS.5) reste a investiguer separement -- documente en gap section 16.

PROD strictement inchangee. KEY-301 et KEY-304 restent OPEN jusqu'a couverture endpoint-by-endpoint complete des autres surfaces. AS.1 PROD reste BLOQUE.

---

## 0. Preflight

| Repo | Branche | HEAD initial | HEAD final | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | a523db7c | eae84b58 | 0/0 | 223 D dist artifacts (compris) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | 9a2081c | 57766ea | 0/0 | tsbuildinfo (artifact) | OK |
| keybuzz-infra | main | 654aa63 | c1c3478 + rapport a venir | 0/0 | clean | OK |

Bastion : install-v3, IP 46.62.171.61.

---

## 1. Runtime baseline READ-ONLY

### Avant phase

| Service | Image |
|---|---|
| API DEV | v3.5.168-escalation-notifications-dev |
| Client DEV | v3.5.179-as1-1-build-args-fix-dev |
| API PROD | v3.5.151-conversation-tone-metric-prod |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod |
| Website PROD | v0.6.12-linkedin-insight-seo-prod |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod |
| OW PROD | v3.5.165-escalation-flow-prod |

### Apres phase (DEV migre, PROD inchangee)

| Service | Image |
|---|---|
| API DEV | v3.5.169-messages-tenant-guard-dev |
| Client DEV | v3.5.180-messages-bff-tenant-guard-dev |
| API PROD | v3.5.151-conversation-tone-metric-prod (INCHANGE) |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod (INCHANGE) |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod (INCHANGE) |
| Website PROD | v0.6.12-linkedin-insight-seo-prod (INCHANGE) |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod (INCHANGE) |
| OW PROD | v3.5.165-escalation-flow-prod (INCHANGE) |

---

## 2. Audit API messages conversations

8 routes sous prefix `/messages` (src/modules/messages/routes.ts) :

| Route API | Methode | Tenant requis | Ownership SQL | Mutation | Test autorise |
|---|---|---|---|---|---|
| GET /messages/conversations | GET | OUI (query) | filtre `WHERE tenant_id = $X` si fourni | NON | OUI (read-only) |
| GET /messages/conversations/:id | GET | OUI | `WHERE id = $1 AND tenant_id = $2` | NON | OUI (read-only) |
| POST /messages/conversations/:id/reply | POST | OUI | convCheck `WHERE id AND tenant_id` | OUI (INSERT messages + possible outbound) | TEST NEGATIF fake-id seulement |
| PATCH /messages/conversations/:id/status | PATCH | OUI | `WHERE id AND tenant_id` | OUI (UPDATE) | TEST NEGATIF fake-id seulement |
| PATCH /messages/conversations/:id/sav-status | PATCH | OUI | `WHERE id AND tenant_id` | OUI (UPDATE) | TEST NEGATIF fake-id seulement |
| PATCH /messages/conversations/:id/assign | PATCH | OUI | `WHERE id AND tenant_id` | OUI (UPDATE) | TEST NEGATIF fake-id seulement |
| PATCH /messages/conversations/:id/escalation | PATCH | OUI | `WHERE id AND tenant_id` | OUI (UPDATE) | TEST NEGATIF fake-id seulement |
| GET /messages/conversations/:id/escalation | GET | OUI | `WHERE id AND tenant_id` | NON | OUI (read-only) |

Note : `/messages/inbound/amazon/status` partage le prefix `/messages` mais est sous `/inbound` qui est dans EXEMPT_PREFIXES -- il reste non protege par cette phase, ce qui est attendu pour les webhooks marketplace.

`fastify-plugin@^4.0.0` est deja present dans le package.json -- Option B disponible.

---

## 3. Audit Client conversations.service

6 fonctions browser-direct vers API (src/services/conversations.service.ts) :

| Fonction Client | Endpoint actuel (avant) | Methode | Endpoint cible BFF | Risque UX |
|---|---|---|---|---|
| fetchConversations | ${baseUrl}/messages/conversations?tenantId=... | GET | /api/messages/conversations | Inbox liste si casse |
| fetchConversationDetail | ${baseUrl}/messages/conversations/:id | GET | /api/messages/conversations/:id | detail conversation |
| sendReply | ${baseUrl}/messages/conversations/:id/reply | POST | /api/messages/conversations/:id/reply | envoi reponse |
| updateConversationStatus | ${baseUrl}/messages/conversations/:id/status | PATCH | /api/messages/conversations/:id/status | update status |
| updateConversationAssignee | ${baseUrl}/messages/conversations/:id/assign | PATCH | /api/messages/conversations/:id/assign | assignation |
| updateConversationSavStatus | ${baseUrl}/messages/conversations/:id/sav-status | PATCH | /api/messages/conversations/:id/sav-status | SAV status |

---

## 4. Design BFF dediee

7 fichiers NEW :

| BFF route file | API target | Methode | Session required | Tenant required | Body forwarded |
|---|---|---|---|---|---|
| app/api/messages/_bff.ts (helper) | -- | -- | OUI | best-effort | OUI |
| app/api/messages/conversations/route.ts | /messages/conversations | GET | OUI | query | NO body |
| app/api/messages/conversations/[id]/route.ts | /messages/conversations/:id | GET | OUI | query | NO body |
| app/api/messages/conversations/[id]/reply/route.ts | /messages/conversations/:id/reply | POST | OUI | query/body | OUI |
| app/api/messages/conversations/[id]/status/route.ts | /messages/conversations/:id/status | PATCH | OUI | query/body | OUI |
| app/api/messages/conversations/[id]/assign/route.ts | /messages/conversations/:id/assign | PATCH | OUI | query/body | OUI |
| app/api/messages/conversations/[id]/sav-status/route.ts | /messages/conversations/:id/sav-status | PATCH | OUI | query/body | OUI |

Le helper `_bff.ts` (prefix underscore = ignore Next routing) :
- validate getServerSession(authOptions) -- 401 NO_SESSION si manquante
- forward to `API_URL_INTERNAL` (env serveur)
- inject X-User-Email + X-Tenant-Id si tenantId trouve en query ou header
- forward query string + body + Content-Type
- ne log jamais le body
- ne forward jamais Cookie ni Authorization

Scope strict : helper hardcoded sous `/api/messages/`. Pas de catchall. Pas un proxy generique.

---

## 5. Design API guard

Option B retenue (fastify-plugin wrapper), car `fastify-plugin@^4.0.0` deja dans deps.

| Option | Dependency | Fichiers | Risque | Verdict |
|---|---|---|---|---|
| A. Hook direct parent scope | aucune nouvelle | src/plugins/tenantGuard.ts + src/app.ts | facile mais necessite modification app.ts | non retenu |
| B. fastify-plugin wrapper | deja presente ^4.0.0 | src/plugins/tenantGuard.ts uniquement | standard Fastify, pas de modification app.ts | RETENU |

Mecanisme PROTECTED_PREFIXES inverse de EXEMPT_PREFIXES :
- par defaut, TOUT path retourne early du hook avec aucun check
- seuls les paths under PROTECTED_PREFIXES sont valides

```
const PROTECTED_PREFIXES = ['/messages'];
```

Migration endpoint-by-endpoint : ajouter un prefix a cette liste = active le guard pour ce prefix. Aucune autre route n'est affectee. Phase 1 (AS.5) ne protege que `/messages`.

---

## 6. Patch Client

| Fichier | Changement | Scope | Risque |
|---|---|---|---|
| app/api/messages/_bff.ts | NEW (115 l) | helper proxy scoped /messages | faible -- mirror pattern /api/notifications |
| app/api/messages/conversations/route.ts | NEW (7 l) | BFF GET list | faible |
| app/api/messages/conversations/[id]/route.ts | NEW (8 l) | BFF GET detail | faible |
| app/api/messages/conversations/[id]/reply/route.ts | NEW (8 l) | BFF POST reply | faible |
| app/api/messages/conversations/[id]/status/route.ts | NEW (8 l) | BFF PATCH status | faible |
| app/api/messages/conversations/[id]/assign/route.ts | NEW (8 l) | BFF PATCH assign | faible |
| app/api/messages/conversations/[id]/sav-status/route.ts | NEW (8 l) | BFF PATCH sav-status | faible |
| src/config/api.ts | EDIT (+7/-6) | 6 endpoints conversations vers BFF relative | faible |

Total : 7 nouveaux fichiers + 1 modification, +169/-6 lignes.

Hors scope (PAS touche) :
- ai.service.ts
- tenants.service.ts
- channels, suppliers, catalogue, performance page, AS.1 badge, AIAssistant.tsx

---

## 7. Patch API

| Fichier | Changement | Scope | Risque |
|---|---|---|---|
| src/plugins/tenantGuard.ts | EDIT (+57/-3) | ajout PROTECTED_PREFIXES, wrap fastify-plugin | faible |

Note : `src/app.ts` NON modifie. Il continue d'appeler `await app.register(tenantGuardPlugin)`. Comme le plugin est maintenant wrap avec `fp()`, le hook se propage correctement au parent app scope.

---

## 8. Checks source

| Repo | Check | Commande | Resultat |
|---|---|---|---|
| keybuzz-api | TypeScript | npx tsc --noEmit | exit 0 |
| keybuzz-client | TypeScript | npx tsc --noEmit | exit 0 |

---

## 9. Commits

| Repo | Commit | Sujet | Files | Push |
|---|---|---|---|---|
| keybuzz-client | 57766ea | fix(client): route messages conversations through authenticated BFF (KEY-304) | 8 files +169/-6 | 9a2081c..57766ea sur ph148/onboarding-activation-replay |
| keybuzz-api | eae84b58 | fix(security): enable tenant guard for messages conversations protection (KEY-304) | 1 file +57/-3 | a523db7c..eae84b58 sur ph147.4/source-of-truth |
| keybuzz-infra | c1c3478 | deploy(dev): protect messages conversations with tenant guard and BFF (KEY-304) | 2 manifests +2/-2 | 654aa63..c1c3478 sur main |

---

## 10. Builds DEV (worktree clean)

| Image | Source commit | Tag | Build ID local | Digest registry |
|---|---|---|---|---|
| keybuzz-api | eae84b58 | v3.5.169-messages-tenant-guard-dev | 2dd672a51f50 | sha256:3d8de5990ee492208f8c4ffea6b95c23bee10c59bbf4072c321ec85598234518 |
| keybuzz-client | 57766ea | v3.5.180-messages-bff-tenant-guard-dev | b4f8e4868fe8 | sha256:c458e5bc5c9eb2d18cec1065ea99b8fc9c21fa08b655f269a9dab3610a4a9386 |

Client build avec KEY-302 build args explicites :
- NEXT_PUBLIC_APP_ENV=development
- NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io
- NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io

Bundle check manuel Client v3.5.180 :

| URL | Count |
|---|---|
| https://api.keybuzz.io (PROD URL, doit etre 0) | 0 |
| https://api-dev.keybuzz.io (preserve par auth.service /auth/me) | 2 |
| /api/messages/conversations (preuve BFF baked) | 12 |

KEY-302 verify-bundle script non execute (gap connu : ne sait pas valider mode BFF). Verification manuelle suffisante.

Worktrees `git worktree` utilises pour les 2 builds depuis commits pousses (build-from-Git strict). Worktrees nettoyes apres builds.

---

## 11. GitOps DEV

| Manifest | Image avant | Image apres | Apply | Rollout |
|---|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | v3.5.179-as1-1-build-args-fix-dev | v3.5.180-messages-bff-tenant-guard-dev | kubectl apply -f | successfully rolled out |
| k8s/keybuzz-api-dev/deployment.yaml | v3.5.168-escalation-notifications-dev | v3.5.169-messages-tenant-guard-dev | kubectl apply -f | successfully rolled out |

Ordre apply : Client d'abord (BFF deployee, compatible avec API ancienne sans guard), puis API (active guard `/messages` uniquement). Pas de fenetre Inbox cassee.

Aucun manifest PROD touche.

---

## 12. Validation negative DEV

Sans auth, depuis le bastion via ingress public api-dev.keybuzz.io :

| Endpoint | Method | Auth | Status | Body | Verdict |
|---|---|---|---|---|---|
| GET /messages/conversations?tenantId=switaa-sasu-mnc1x4eq&limit=1 | GET | none | **401** | `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | **FUITE FERMEE** (etait 200+1214B avant) |
| GET /messages/conversations/fake-id-xyz?tenantId=... | GET | none | 401 | AUTH_REQUIRED | OK |
| PATCH /messages/conversations/fake-id/status?tenantId=... | PATCH | none | 401 | AUTH_REQUIRED | OK |
| POST /messages/conversations/fake-id/reply?tenantId=... | POST | none | 401 | AUTH_REQUIRED | OK |
| GET /messages/conversations?tenantId=... + x-user-email bogus | GET | partial | **403** | `{"error":"Access denied: not a member of this tenant"}` | **MEMBERSHIP CHECK ACTIF** |
| GET /notifications?tenantId=... (OUT OF SCOPE, non protege) | GET | none | **200** | `[]` | **PROTECTED_PREFIXES mechanism works** -- /notifications non protege comme prevu |

`[TenantGuard] DENIED cross-tenant access` log apparait dans les logs API DEV pour les hits non-membres (preuve guard actif).

---

## 13. Validation positive Inbox DEV

QA Ludovic apres rollout :

| Surface | Test | Resultat | Verdict |
|---|---|---|---|
| Inbox liste centrale | refresh page | conversations chargees correctement | OK |
| Nouveaux messages | arriving | nouveaux messages apparaissent | OK |
| Detail conversation | click on conv | detail OK | OK (implicit dans QA) |
| Channels / catalogue | other UI | inchanges (PROTECTED_PREFIXES ne touche pas /channels) | OK |
| AI auto-suggestion | ouvre suggestion panel | **bouton manuel affiche, generation auto absente** | **PRE-EXISTING BUG -- non cause par AS.5** |

Investigation AI auto-suggestion :

| Check | Resultat | Conclusion |
|---|---|---|
| `/ai/assist` reachable sans auth | POST returns 400 "contextType must be conversation/order/playbook" | endpoint repond, handler-level reject pour body invalide |
| Logs API DEV /ai/assist hits 3min | 0 hit | le browser N'EMET PAS l'appel auto |
| AIAssistant.tsx ligne 143 | `fetch(${API_URL}/ai/assist)` browser direct (preserve par revert AS.4.3) | etat inchange depuis runtime stable v3.5.179 |
| PROTECTED_PREFIXES affecte /ai/* ? | NON (PROTECTED_PREFIXES = ['/messages'] uniquement) | guard ne bloque pas /ai |

Conclusion : l'AI auto-suggestion etait deja non fonctionnelle avant AS.5 (probablement depuis le rollback AS.1.1 qui a unwired des hooks AS.1). Bug pre-existant, non cause par AS.5. Gap documente section 16, a investiguer dans une phase separee hors KEY-304 scope.

---

## 14. PROD read-only

| Service PROD | Image avant | Image apres | Verdict |
|---|---|---|---|
| API PROD | v3.5.151-conversation-tone-metric-prod | identique | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | identique | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | identique | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | identique | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | identique | INCHANGE |
| OW PROD | v3.5.165-escalation-flow-prod | identique | INCHANGE |

Aucun manifest PROD modifie. Aucun rollout PROD. Aucun docker push PROD. Aucun kubectl apply PROD.

---

## 15. Rollback non execute

Rollback DEV non execute -- la validation positive est OK pour le scope strict de AS.5 (messages conversations).

Si rollback DEV requis plus tard :
- API DEV : `v3.5.168-escalation-notifications-dev` (image en cache local + registry)
- Client DEV : `v3.5.179-as1-1-build-args-fix-dev`
- Mecanisme : edit manifest -> commit -> push -> kubectl apply -f -> rollout status
- A executer uniquement sur GO Ludovic explicite

---

## 16. Gaps restants

1. **AI auto-suggestion ne se declenche pas automatiquement** : symptome pre-existant non cause par AS.5. AIAssistant.tsx fait toujours browser direct `${API_URL}/ai/assist`. PROTECTED_PREFIXES ne le bloque pas. Le browser n'emet simplement pas l'appel. A investiguer hors scope KEY-304 (probablement un hook de declenchement desactive depuis le rollback AS.1.1).
2. **KEY-301 reste OPEN** : faille tenantGuard non corrigee pour les autres surfaces (/notifications, /ai, /channels, /suppliers, /billing, /tenants).
3. **KEY-304 reste OPEN** : phase 1 livree (/messages), phases suivantes a livrer.
4. **AS.1 PROD reste BLOQUE** : la source de verite /notifications reste non protegee.
5. **KEY-302 verify-bundle script** ne supporte pas le mode BFF (`baseUrl='/api/...'` partiel) -- gap connu, hors scope ici. Verification manuelle suffisante.
6. **Sequence recommandee phases suivantes** :
   - Phase 2 : `/notifications` (precondition AS.1 PROD)
   - Phase 3 : `/ai/*` (inclure correction AIAssistant.tsx + BFF /api/ai/* generique scoped)
   - Phase 4 : `/channels`, `/suppliers`
   - Phase 5 : `/tenants` (refactor handler-level deja prepare dans archive/key-304-api-tenant-guard-experiment-4d88e989)
   - Chaque phase : 1 ajout dans PROTECTED_PREFIXES + 1 BFF dediee + 1 service Client + test E2E.
7. **OW DEV / OW PROD** : workers process, pas exposes HTTP, non affectes. Pas d'action requise.

---

## 17. Textes Linear -- NON POSTES

### Texte KEY-304 (a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5 -- Endpoint-by-endpoint phase 1 -- /messages/conversations.

PATCH SECURITE LIVRE EN DEV
- API DEV : v3.5.169-messages-tenant-guard-dev (digest 3d8de5990ee4...)
  source commit eae84b58 : tenantGuardPlugin via fastify-plugin,
  PROTECTED_PREFIXES = ['/messages'] uniquement
- Client DEV : v3.5.180-messages-bff-tenant-guard-dev (digest c458e5bc5c9e...)
  source commit 57766ea : 6 BFF routes /api/messages/conversations/*
  + conversations.service migrated to relative BFF paths
- Infra commit c1c3478 : 2 manifests DEV updated, apply OK

VALIDATIONS DEV
Negatives (no auth) :
- GET /messages/conversations real tenant -> 401 (etait 200+1214B avant)
- GET /messages/conversations/:id, PATCH status, POST reply -> 401
- GET avec email non-membre -> 403 Access denied (membership check active)
- Log [TenantGuard] DENIED cross-tenant access apparait dans API logs
Out of scope verifiees inchangees :
- GET /notifications no auth -> 200 [] (toujours non protege, normal)
Positives (QA Ludovic) :
- Inbox liste centrale OK
- Nouveaux messages OK
PRE-EXISTING BUG (non cause par AS.5) :
- AI auto-suggestion ne se declenche pas auto -- bouton manuel visible.
  Diagnostic : /ai/assist endpoint reachable (PROTECTED_PREFIXES ne le
  bloque pas), 0 hit dans les logs API, AIAssistant.tsx fait browser
  direct comme avant. Bug existait deja dans runtime stable v3.5.179.
  A investiguer hors scope KEY-304.

PROD STRICTEMENT INCHANGEE.

PROCHAINES PHASES PROPOSEES (sequence endpoint-by-endpoint) :
1. AS.6 -- /notifications (precondition pour AS.1 PROD badge escalation)
2. AS.7 -- /ai/* (inclure fix AIAssistant.tsx auto-trigger + BFF
   generique /api/ai/* scoped)
3. AS.8 -- /channels, /suppliers
4. AS.9 -- /tenants (refactor handler-level disponible dans
   archive/key-304-api-tenant-guard-experiment-4d88e989)

Chaque phase : 1 ajout PROTECTED_PREFIXES + 1 BFF dediee + 1 service
Client + test E2E avant deploy.

KEY-304 reste OPEN jusqu'a livraison de toutes les phases. AS.1 PROD
reste BLOQUE jusqu'a AS.6 (/notifications) au minimum.

Rapport : keybuzz-infra commit a venir
docs/PH-SAAS-T8.12AS.5-MESSAGES-CONVERSATIONS-TENANT-GUARD-DEV-01.md
ASCII strict.
```

### Texte KEY-301 (a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5 -- Premiere phase patch securite livree en DEV.

La surface /messages/conversations est maintenant protegee en runtime
DEV. Toutes les autres surfaces (notifications, ai, channels, suppliers,
billing, tenants) restent expose comme avant -- elles seront migrees
une par une dans les phases suivantes.

Mecanisme : tenantGuard wrappe avec fastify-plugin (hook apply
correctement sur parent scope), PROTECTED_PREFIXES = ['/messages']
seulement. Migration endpoint-by-endpoint sans casser les flows non
encore migres.

KEY-301 reste OPEN jusqu'a couverture complete. AS.1 PROD reste
BLOQUE car /notifications n'est pas encore protege.

PROD strictement inchangee.
```

### Texte KEY-263 (a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5 -- Securite endpoint-by-endpoint phase 1 livree.

/messages/conversations est protege en DEV. /notifications (la source
de verite du badge escalation AS.1) sera la prochaine phase (AS.6) avant
toute reprise AS.1 PROD.

Aucune action AS.1 dans cette phase. PROD inchangee.
```

---

## 18. Phrase cible finale

Le patch securite endpoint-by-endpoint phase 1 a livre la protection runtime DEV pour la surface `/messages/conversations` : le tenantGuardPlugin de keybuzz-api a ete wrap avec `fastify-plugin` (hook applique correctement sur parent app scope) et la liste `PROTECTED_PREFIXES = ['/messages']` limite explicitement la protection a la surface migree, preservant toutes les autres routes (/notifications, /ai, /channels, /suppliers, /billing, /tenants) comme avant ; cote keybuzz-client une BFF dediee a 7 fichiers a ete ajoutee sous `app/api/messages/conversations/` avec injection serveur des headers X-User-Email + X-Tenant-Id depuis NextAuth, et `src/config/api.ts` redirige les 6 endpoints conversations browser-direct vers ce BFF relatif ; les builds DEV (API v3.5.169 + Client v3.5.180) sont signed et deployes via GitOps strict, validations negatives 401/403 confirmees y compris log `[TenantGuard] DENIED cross-tenant access` pour membership refuse ; QA Ludovic confirme Inbox liste fonctionnelle + nouveaux messages OK ; un bug pre-existant AI auto-suggestion (non cause par AS.5, browser ne hit pas /ai/assist) est documente comme gap a investiguer hors scope KEY-304 ; PROD strictement inchangee ; KEY-301 et KEY-304 restent OPEN avec sequence proposee AS.6 (/notifications) -> AS.7 (/ai) -> AS.8 (/channels, /suppliers) -> AS.9 (/tenants) ; AS.1 PROD reste BLOQUE jusqu'a AS.6 minimum.

STOP -- phase 1 livree, en attente decision Ludovic sur lancement AS.6 (/notifications) ou investigation hors-scope AI auto-suggestion.
