# PH-SAAS-T8.12AS.11.1F-2-QA-MESSAGES-6OF6-CLOSEOUT-01

> Date : 2026-05-12
> Linear : KEY-304 (principal), KEY-301, KEY-263 (contexte PROD blocker)
> Phase : T8.12 AS.11.1F-2 QA closeout / synthese 6/6 / read-only strict
> Environnement : runtime read-only ; PROD strictement inchange

---

## 1. VERDICT

GO MESSAGES 6OF6 DEV QA READY

Endpoint-by-endpoint migration complete sur `/messages/conversations*` en DEV : 6/6 endpoints (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS) sont desormais en allowlist tenantGuard runtime DEV. QA Ludovic navigateur confirmee avec `switaa26@gmail.com` (tenant SWITAA) : aucune regression observee, Inbox + Brouillon IA + boutons mutationnels fonctionnels et visibles sans necessite de cliquer.

KEY-304 reste In Review : la promotion PROD (AS.11.1g) est une phase separee bloquee par decision Ludovic + KEY-263 closure conditionnelle. KEY-301 reste Open jusqu apres PROD promotion. KEY-263 reste In Review (escalation notifications PROD) car la promotion AS.11.1 n a pas encore eu lieu.

Aucun patch source, aucun build, aucun docker push, aucun kubectl apply/set/patch/edit, aucune modification de manifest, aucune mutation DB, aucun clic UI mutationnel realises dans cette phase. Smoke V1 reconfirme PASS=17 WARN=1 FAIL=0 SKIP=1.

---

## 2. Runtime baselines

| Env | Service | Image | GitOps MATCH |
|---|---|---|---|
| DEV | keybuzz-api | v3.5.175-messages-sav-status-tenantguard-dev | yes |
| DEV | keybuzz-client | v3.5.189-messages-sav-status-bff-dev | yes |
| PROD | keybuzz-api | v3.5.151-conversation-tone-metric-prod | yes |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod | yes |
| PROD | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | yes |
| PROD | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | yes |
| PROD | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod | yes |
| PROD | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod | yes |
| PROD | backfill-scheduler | v1.0.42-td02-worker-resilience-prod | yes |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | yes |

Source sync 0/0 sur 3 repos (keybuzz-api branch ph147.4/source-of-truth head 3f45a7e0, keybuzz-client branch ph148/onboarding-activation-replay head 094163b, keybuzz-infra branch main head 727c880). Pods DEV API 1/1 Ready, Client 1/1 Ready.

---

## 3. 6/6 endpoint coverage table

Source verification dans `keybuzz-api/src/plugins/tenantGuard.ts` (runtime API DEV) :

| # | Endpoint | Method | Matcher source | Phase de delivery |
|---|---|---|---|---|
| 1 | /messages/conversations | GET | PROTECTED_ROUTES entry (exact path) | AS.11.1A-R2 (2026-05-11) |
| 2 | /messages/conversations/:id | GET | `isMessagesConversationDetailGet` | AS.11.1C (2026-05-11) |
| 3 | /messages/conversations/:id/reply | POST | `isMessagesConversationReplyPost` | AS.11.1D (2026-05-11) |
| 4 | /messages/conversations/:id/status | PATCH | `isMessagesConversationStatusPatch` | AS.11.1E (2026-05-12) |
| 5 | /messages/conversations/:id/assign | PATCH | `isMessagesConversationAssignPatch` | AS.11.1F-1 (2026-05-12) |
| 6 | /messages/conversations/:id/sav-status | PATCH | `isMessagesConversationSavStatusPatch` | AS.11.1F-2 (2026-05-12) |

`isProtected()` reference les 5 matchers dynamiques + 1 PROTECTED_ROUTES static entry = 6 endpoints en allowlist runtime DEV.

Client BFF routes presentes dans bundle Client v3.5.189 (verifie en AS.11.1f-2 build) :

```
/app/.next/server/app/api/messages/conversations/route.js                  (LIST)
/app/.next/server/app/api/messages/conversations/[id]/route.js             (DETAIL)
/app/.next/server/app/api/messages/conversations/[id]/reply/route.js       (REPLY)
/app/.next/server/app/api/messages/conversations/[id]/status/route.js      (STATUS)
/app/.next/server/app/api/messages/conversations/[id]/assign/route.js      (ASSIGN)
/app/.next/server/app/api/messages/conversations/[id]/sav-status/route.js  (SAV-STATUS)
```

Helper unique `proxyMessages` (defini `keybuzz-client/app/api/messages/_bff.ts`) : NextAuth session required, injection `X-User-Email` + `X-Tenant-Id`, jamais de forward Cookie ou Authorization, jamais de log body.

---

## 4. Security recap depuis rapports PH

Source : `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1*.md` (6 rapports + 1 QA + 1 reapply + 1 BFF original).

| Sous-phase | Tests negatifs PASS | DB proof | Smoke V1 |
|---|---|---|---|
| AS.11.1A-R2 (LIST) | no-auth 401, bogus 403, cross-tenant 403 | read-only endpoint | PASS |
| AS.11.1C (DETAIL) | no-auth 401, bogus 403, cross-tenant 403, GET on /reply 404 | read-only endpoint | PASS |
| AS.11.1D (REPLY) | 8/8 PASS incl. preserve LIST/DETAIL | messages SWITAA delta 0 (162 -> 162) | PASS_WITH_WARNINGS |
| AS.11.1E (STATUS) | 8/8 PASS incl. preserve REPLY | status_change events delta 0, status field UNCHANGED ; T9 observation hors scope assign | PASS_WITH_WARNINGS |
| AS.11.1F-1 (ASSIGN) | 10/10 PASS incl. preserve STATUS | assign events delta 0 (1 -> 1 frozen), assigned_agent_id UNCHANGED ; T10 observation hors scope sav-status | PASS_WITH_WARNINGS |
| AS.11.1F-2 (SAV-STATUS) | 10/10 PASS incl. preserve ASSIGN | sav_status_change events delta 0 (1 -> 1 frozen), sav_status UNCHANGED, updated_at FROZEN (premiere fois depuis AS.11.1A) | PASS_WITH_WARNINGS |

Le WARN du smoke V1 est constant depuis AS.11.1A-R2 : `/messages/conversations 401 (auth required)` = comportement attendu post tenantGuard LIST. Aucun FAIL n a ete observe sur toute la serie. Aucun rollback n a ete declenche.

Apres AS.11.1F-2 : aucun endpoint `/messages/conversations*` n est plus exploitable sans NextAuth session + membership user-tenant.

---

## 5. Smoke V1 DEV current

```
=== Summary ===
PASS=17 WARN=1 FAIL=0 SKIP=1
RESULT=PASS_WITH_WARNINGS
```

Detail :
- A. Runtime/GitOps : 6/6 PASS (images attendues, drift NONE, pods Ready)
- B. Bundle guard : 5/5 PASS (no sentinel, api-dev inline, no PROD URL, labels Brouillon IA + Valider et envoyer)
- C. API DEV read-only : 3 PASS + 1 WARN attendu sur /messages/conversations 401
- D. Client BFF read-only : 3/3 PASS (auth redirect, /inbox 200, /api/auth/session 200)
- E. /autopilot/draft probe : SKIP (pas de SMOKE_CONVERSATION_ID, par design)

FAIL=0. RESULT=PASS_WITH_WARNINGS conforme depuis AS.11.1A-R2.

---

## 6. Logs DEV fenetre 15 minutes

| Source | Filtre | Count |
|---|---|---|
| keybuzz-api DEV | statusCode 5xx ou level=50 | 0 |
| keybuzz-client DEV | `JWT_SESSION_ERROR` | 0 |
| keybuzz-client DEV | reponse 5xx | 0 |

Aucune erreur visible cote runtime DEV apres deploy AS.11.1f-2.

---

## 7. PROD strictement inchange

8 services PROD sur leurs baselines pre-AS.5 (table section 2 deja inclut PROD). Aucun manifest PROD touche depuis le debut de la serie AS.11.1*. Aucun docker push prod-tag. Aucun kubectl apply sur namespace `*-prod`. Aucun secret PROD touche.

---

## 8. QA Ludovic navigateur

QA realisee par Ludovic (sans donnees client copiees) :

| Item | Resultat |
|---|---|
| Compte session NextAuth | `switaa26@gmail.com` (business SWITAA owner) |
| Tenant courant en navigateur | SWITAA (switaa-sasu-mnc1x4eq) |
| Inbox SWITAA -- liste conversations visible | OUI (LIST via BFF AS.11.1A-R2) |
| Conversation detail visible apres clic | OUI (DETAIL via BFF AS.11.1C) |
| Nouveaux messages visibles | OUI |
| Brouillon IA visible automatiquement sur conv AUTOPILOT eligible | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| Boutons "Modifier" / "Ignorer" visibles | OUI (NON cliques) |
| Bouton changement statut visible | OUI (NON clique) |
| Bouton assigner agent visible | OUI (NON clique) |
| Bouton SAV label visible | OUI (NON clique) |
| Banniere "API indisponible" / erreur | NON |
| Regression visible Inbox / channels / suppliers / catalogue / commande | NON |

Conclusion QA : le pattern BFF list + detail + reply + status + assign + sav-status + tenantGuard API actif sur les 6 endpoints `/messages/conversations*` ne casse pas l Inbox ni l ouverture/inspection de conversation pour un utilisateur legitimement membre du tenant. Le Brouillon IA reste fonctionnel grace au fix AS.11.0.6 (consolidated useEffect deterministe).

Aucune donnee client copiee dans ce rapport. Aucune capture ecran avec PII committee.

---

## 9. Pourquoi KEY-304 reste In Review

KEY-304 ne sera pas marque Done dans cette phase QA pour les raisons suivantes :

1. La promotion PROD est une phase distincte (AS.11.1g) qui necessite un GO explicite Ludovic, une orchestration coordonnee API + Client en PROD, des tests negatifs PROD apres deploy, et une fenetre de surveillance post-deploy.
2. KEY-263 (escalation notifications PROD promotion) reste bloque tant que la fondation tenantGuard `/messages` n est pas promue en PROD : les deux sont couples (AS.11.1g doit decider du sequencement).
3. La validation security `/messages/conversations*` reste exclusivement DEV pour le moment. Aucun PROD curl de test n a ete effectue dans cette phase QA conformement au scope read-only strict.

KEY-304 reste In Review jusqu apres AS.11.1g PROD promotion + post-deploy security tests PROD + Ludovic GO Done.

---

## 10. Pourquoi KEY-301 reste Open

KEY-301 (tenantGuardPlugin runtime audit / fix) reste Open jusqu apres :
- AS.11.1g PROD promotion reussie.
- Confirmation que le tenantGuard runtime PROD applique bien la membership check sur les 6 endpoints `/messages/conversations*`.
- Eventuelle extension a d autres modules sensibles (e.g. `/notifications`, `/billing`, decisions hors KEY-304).

Le scope KEY-301 etant plus large que les seuls endpoints `/messages`, sa closure necessite une revue globale apres PROD promotion.

---

## 11. Linear updates

| Issue | Action | Statut |
|---|---|---|
| KEY-304 | commentaire AS.11.1f-2-QA poste, disclosure controle | reste In Review (6/6 DEV OK, attente AS.11.1g PROD) |
| KEY-301 | commentaire progression complete DEV poste, disclosure controle | reste Open (attente PROD promotion) |
| KEY-263 | commentaire bloque jusqu a AS.11.1g, disclosure controle | reste In Review (bloque par KEY-301 + KEY-304 PROD) |

### 11.1 KEY-304 commentaire (texte cible)

```
## AS.11.1F-2 QA closeout -- 6/6 endpoints `/messages` protected in DEV

- Endpoint-by-endpoint migration complete : LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS.
- All 6 matchers active in tenantGuard `isProtected()` (1 PROTECTED_ROUTES + 5 dedicated dynamic matchers).
- All 6 BFF route files present in Client bundle v3.5.189.
- Security validation negative-only across the series : 8/8 to 10/10 PASS per sub-phase ; no positive mutation issued.
- DB no-mutation proof on real SWITAA conversation cumulative : status open -> open, sav_status null -> null, assigned_agent_id null -> null, sav_status_change events frozen, messages SWITAA count 162 -> 162.
- Smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1 (WARN /messages/conversations 401 = expected post LIST protection, stable since AS.11.1A-R2).
- Logs DEV 15min : 0 5xx API, 0 JWT_SESSION_ERROR Client.
- QA Ludovic navigateur with `switaa26@gmail.com` (business SWITAA owner) : Inbox liste + detail + new messages + Brouillon IA auto visible ; reply / status / assign / SAV buttons visible but NOT clicked ; no error banner ; no regression.
- Runtime DEV : API v3.5.175-messages-sav-status-tenantguard-dev + Client v3.5.189-messages-sav-status-bff-dev, MATCH=yes GitOps.
- PROD strictly unchanged (8 services).

KEY-304 remains In Review pending AS.11.1g PROD promotion (separate phase requiring explicit Ludovic GO + KEY-263 sequencing decision). Do NOT mark Done before PROD promotion + PROD post-deploy negative-only validation + Ludovic GO Done.

Disclosure controle : pas de PoC, pas de details exploit.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1F-2-QA-MESSAGES-6OF6-CLOSEOUT-01.md
```

### 11.2 KEY-301 commentaire (texte cible)

```
Runtime mitigation in DEV now COMPLETE on /messages/conversations* : 6/6 endpoints protected (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS). Cross-tenant access denied PROVEN on all 6 endpoints in DEV (ludo personal email targeting SWITAA -> 401/403, no DB mutation across the series).

QA Ludovic confirmed Inbox + Brouillon IA + mutation buttons functional in DEV without UI clicks.

KEY-301 stays Open while PROD remains on the pre-AS.5 baseline (8 services unchanged). The broader scope of KEY-301 (potential application to other modules beyond /messages) is also out of this closeout.

PROD promotion of the 6/6 /messages mitigation is the AS.11.1g phase, which has not started.

Disclosure controle : pas de PoC, pas de details exploit.
```

### 11.3 KEY-263 commentaire (texte cible)

```
KEY-263 (escalation notifications PROD promotion) remains blocked by KEY-301 + KEY-304 PROD pending. The /messages tenantGuard 6/6 endpoint-by-endpoint migration is complete in DEV as of AS.11.1F-2 (rapport PH-SAAS-T8.12AS.11.1F-2-QA-MESSAGES-6OF6-CLOSEOUT-01.md).

Next coordinated action is AS.11.1g PROD promotion of the API + Client tenantGuard `/messages` mitigation, which itself remains gated on Ludovic GO. KEY-263 closure decision depends on AS.11.1g outcome and on whether the escalation notifications PROD promotion sequencing is bundled with or sequenced after AS.11.1g.

KEY-263 stays In Review.

Disclosure controle : pas de PoC, pas de details exploit.
```

---

## 12. Compliance AS.11.1f-2-QA

| Verification | Statut |
|---|---|
| Aucun patch source | OK |
| Aucun build | OK |
| Aucun docker push | OK |
| Aucun kubectl apply / set / patch / edit | OK |
| Aucune mutation manifest | OK (un seul commit docs-only) |
| Aucune mutation DB | OK |
| Aucun clic UI mutationnel | OK (QA inspection visuelle uniquement) |
| Aucun test positif HTTP POST/PATCH | OK |
| ASCII strict rapport | OK |
| Aucune PII rapport / Linear | OK |
| Disclosure controle Linear | OK (textes prets, attente GO + methode token) |
| KEY-304 NOT marked Done | OK (reste In Review) |
| KEY-301 NOT marked Done | OK (reste Open) |
| KEY-263 NOT marked Done | OK (reste In Review) |

---

## 13. Phrase cible finale

AS.11.1F-2-QA livre : 6/6 endpoints `/messages/conversations*` proteges en DEV (LIST AS.11.1A-R2 + DETAIL AS.11.1C + REPLY AS.11.1D + STATUS AS.11.1E + ASSIGN AS.11.1F-1 + SAV-STATUS AS.11.1F-2) ; source tenantGuard contient 5 matchers dedies + 1 PROTECTED_ROUTES entry, bundle Client expose 6 routes BFF ; runtime DEV API v3.5.175-messages-sav-status-tenantguard-dev + Client v3.5.189-messages-sav-status-bff-dev MATCH=yes GitOps ; smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1 ; logs DEV 15min 0 5xx + 0 JWT_SESSION_ERROR ; PROD strictement inchange (8 services) ; QA Ludovic navigateur OK avec switaa26@gmail.com (Inbox liste + detail + nouveaux messages + Brouillon IA + boutons mutationnels visibles non cliques + aucune banniere erreur + aucune regression) ; aucun patch source, build, push, kubectl apply, mutation DB, clic UI realises dans cette phase ; KEY-304 reste In Review jusqu apres AS.11.1g PROD promotion ; KEY-301 reste Open ; KEY-263 reste In Review (bloque par AS.11.1g) ; verdict AS.11.1F-2-QA GO MESSAGES 6OF6 DEV QA READY.

STOP
