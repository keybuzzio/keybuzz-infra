# PH-SAAS-T8.12AS.11.1A-R2-QA-CLOSEOUT-01

> Date : 2026-05-11
> Linear : KEY-304 (principal), KEY-301
> Phase : T8.12 AS.11.1A-R2 QA closeout / Linear/docs only / no code / no deploy
> Environnement : runtime read-only ; PROD inchange

---

## 1. VERDICT

GO MESSAGES LIST QA CLOSEOUT READY

QA Ludovic navigateur confirmee sur DEV avec le compte business SWITAA `switaa26@gmail.com`. L Inbox SWITAA et Brouillon IA sont fonctionnels post AS.11.1A-R2. Aucune regression observee. PROD strictement inchange.

KEY-304 reste In Review (NE PAS Done) : seul l endpoint LIST `/messages/conversations` est protege. Les autres routes `/messages` (detail, reply, status, assign, sav-status) restent ouvertes jusqu a leurs sous-phases dediees AS.11.1c -> AS.11.1f.

KEY-301 reste Open : la securisation runtime est partielle (1/6 endpoints `/messages` proteges).

Aucun patch source, aucun build, aucun deploy, aucun kubectl apply, aucune mutation DB realises dans cette phase. Smoke V1 reconfirme PASS=18 WARN=0 FAIL=0 SKIP=1 RESULT=PASS sur bastion install-v3.

---

## 2. Runtime

| Env | Service | Image | MATCH GitOps | Pods |
|---|---|---|---|---|
| DEV | keybuzz-api | v3.5.170-messages-list-tenantguard-dev | yes | 1 ready, 0 restart |
| DEV | keybuzz-client | v3.5.184-messages-list-bff-dev | yes | 1 ready, 0 restart |
| PROD | keybuzz-api | v3.5.151-conversation-tone-metric-prod | yes | 1 ready, 0 restart |
| PROD | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | yes | 1 ready, 0 restart |
| PROD | keybuzz-backend, website, admin-v2, outbound-worker | inchange | yes | ready |

Aucun drift GitOps post AS.11.1A-R2. Smoke V1 confirme PASS=18.

---

## 3. Ludovic QA

QA reportee par Ludovic dans la conversation (sans donnees client) :

| Item | Resultat |
|---|---|
| Compte de session NextAuth utilise | switaa26@gmail.com (compte business SWITAA owner, name="Ludovic GONTHIER" dans la base) |
| Tenant courant selectionne en navigateur | SWITAA (switaa-sasu-mnc1x4eq) |
| Inbox SWITAA -- liste conversations visible | OUI |
| Conversations -- detail visible (route non protegee par AS.11.1A) | OUI |
| Brouillon IA -- visible automatiquement sur conv AUTOPILOT eligible | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique, mutation interdite par scope) |
| Boutons "Modifier" / "Ignorer" visibles | OUI (NON cliques) |
| Aucune banniere "API indisponible" | OUI |
| Aucune erreur visible Inbox / channels / suppliers / catalogue | OUI |
| Regression visible sur d autres surfaces | NON |

Conclusion QA : le pattern BFF list + tenantGuard API actif sur `GET /messages/conversations` ne casse PAS Inbox ni Brouillon IA pour un utilisateur legitimement membre du tenant (switaa26 = owner SWITAA dans user_tenants).

Aucune donnee client copiee dans ce rapport. Aucune capture ecran avec PII committee.

---

## 4. Linear updates

| Issue | Action | Commentaire URL | Statut |
|---|---|---|---|
| KEY-304 | commentaire QA closeout poste | cf section 4.1 ci-dessous | reste In Review (LIST OK, autres endpoints futurs) |
| KEY-301 | commentaire progression poste | cf section 4.2 ci-dessous | reste Open/Todo (1/6 endpoints `/messages` proteges runtime) |

### 4.1 KEY-304 commentaire

```
## AS.11.1A-R2 QA Ludovic OK

- `/messages/conversations` LIST protected in DEV.
- Security validation passed: no-auth 401, bogus 403, legit SWITAA owner 200, personal Ludovic account denied for SWITAA (cross-tenant denied PROVEN).
- Smoke V1 PASS.
- QA Ludovic with `switaa26@gmail.com`: Inbox and Brouillon IA functional, no regression observed.
- PROD unchanged.

KEY-304 remains In Review because only LIST endpoint is protected; detail/reply/status/assign/sav-status remain future phases AS.11.1c -> AS.11.1f. Do not Done until all 6 endpoints are migrated.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1A-R2-QA-CLOSEOUT-01.md
```

### 4.2 KEY-301 commentaire

```
Partial runtime mitigation in DEV validated for `/messages/conversations` LIST. Cross-tenant access denied confirmed for an ecomlg-001 user trying to read SWITAA conversations.

Broader tenantGuard security issue remains open: 5 additional `/messages` endpoints (detail, reply, status, assign, sav-status) still unprotected at runtime. Continue endpoint-by-endpoint sequence AS.11.1c -> AS.11.1f before considering PROD promotion.

KEY-301 stays Open.
```

---

## 5. Remaining endpoints (AS.11.1c -> AS.11.1f)

Sequence prevue, dans cet ordre :

| Sous-phase | Endpoint | Method | Pattern requis dans tenantGuard | Risque |
|---|---|---|---|---|
| AS.11.1c | `/messages/conversations/:id` | GET | adaptation `isProtected` pour path parameter `:id` (regex ou `startsWith('/messages/conversations/') && method='GET' && path !== '/messages/conversations'`) | timing detail vs autopilotDraft -- attenue par AS.11.0.6 fix |
| AS.11.1d | `/messages/conversations/:id/reply` | POST | path parameter + method POST | mutation, validation send-flow obligatoire |
| AS.11.1e | `/messages/conversations/:id/status` | PATCH | path parameter + method PATCH | status mutation, UI state coherence |
| AS.11.1f-1 | `/messages/conversations/:id/assign` | PATCH | path parameter + method PATCH | assign mutation, sidebar agent display |
| AS.11.1f-2 | `/messages/conversations/:id/sav-status` | PATCH | path parameter + method PATCH | sav-status mutation, panel coherence |
| AS.11.1g | promotion PROD coordonnee | n/a | post toutes sous-phases DEV valides + KEY-263 closure | PROD impact |

Chaque sous-phase suivra le pattern AS.11.1A-R2 : extension `PROTECTED_ROUTES`, ajout route BFF Client, modification UN seul endpoint dans `api.ts`, build + push + apply GitOps, security validation 6 checks, smoke V1, QA Ludovic avec le compte approprie (switaa26 pour QA SWITAA).

---

## 6. Next phase

**AS.11.1c proposition** : `/messages/conversations/:id` GET detail.

Prerequis :
- adaptation `isProtected(method, path)` dans tenantGuard pour supporter pattern dynamique (path parameter `:id`). Deux options :
  - Option 1 (simple) : `path.startsWith('/messages/conversations/') && method === 'GET'` (accepte tout detail GET, exclut le list par construction).
  - Option 2 (strict) : regex `^/messages/conversations/[a-zA-Z0-9_-]+$` + method GET.
- Option 1 plus simple, suffisante (les sous-paths reply/status/etc. ont leur propre method ; `:id` est cmmpXX... format Cuid2).
- Client : ajouter route BFF `app/api/messages/conversations/[id]/route.ts` GET only.
- `src/config/api.ts` : modifier UNE entree `conversationDetail` vers path relatif BFF.
- Build API v3.5.171 (numero libre apres v3.5.170) + Client v3.5.185 (numero libre apres v3.5.184).
- KEY-302 + KEY-308 + KEY-309 obligatoires.
- Validation matrix complete.
- QA Ludovic avec switaa26 pour selection conv + verifier Brouillon IA reste OK (apres AS.11.0.6 fix, ce gating critique doit etre robuste).

---

## 7. Compliance AS.11.1A-R2-QA

| Verification | Statut |
|---|---|
| Aucun patch source | OK |
| Aucun build | OK |
| Aucun deploy | OK |
| Aucun kubectl apply/set/patch/edit | OK |
| Aucune mutation manifest | OK (1 commit docs-only au rapport) |
| Aucune mutation DB | OK |
| Aucun secret affiche | OK |
| Aucune PII / donnees client | OK (note generale "Inbox visible" sans contenu) |
| KEY-304 ne pas Done | OK (reste In Review) |

---

### 7.bis Phrase cible finale

AS.11.1A-R2 QA closeout livre : Ludovic confirme en navigateur DEV avec `switaa26@gmail.com` que l Inbox SWITAA fonctionne et Brouillon IA visible auto post AS.11.1A-R2 ; runtime DEV MATCH=yes GitOps (API v3.5.170 + Client v3.5.184) ; PROD strictement inchange (6 services) ; smoke V1 PASS=18 WARN=0 ; KEY-304 reste In Review (seul LIST protected, 5 endpoints `/messages` restant) ; KEY-301 reste Open (1/6 endpoints proteges runtime) ; aucun patch source, aucun build, aucun deploy, aucun kubectl apply, aucune mutation DB realises ; verdict AS.11.1A-R2-QA GO MESSAGES LIST QA CLOSEOUT READY.

STOP
