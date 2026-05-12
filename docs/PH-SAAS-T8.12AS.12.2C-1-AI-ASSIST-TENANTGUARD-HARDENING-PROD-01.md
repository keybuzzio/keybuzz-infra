# PH-SAAS-T8.12AS.12.2C-1-AI-ASSIST-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-1-PROD -- AI assist (LLM mutation) tenantGuard PROD promotion
> Environnement : PROD ; API-only ; 7 autres services PROD strictement inchanges

---

## 1. VERDICT

GO AI ASSIST TENANTGUARD PROD READY

Promotion PROD AS.12.2C-1 reussie en API-only. L endpoint `POST /ai/assist` (LLM-cost, KBActions-consuming) est desormais couvert par tenantGuard runtime en PROD. Bundle minimal : aucun delta source au-dela de KEY-301 AS.12.2C-1 (1 fichier `tenantGuard.ts` au commit `28a31d96`, deja runtime DEV depuis v3.5.181).

Validation post-deploy PROD : T1 no-auth -> 401 AUTH_REQUIRED, T2 no body -> 400 TENANT_ID_MISSING (rejet avant atteinte handler LLM dans les deux cas). Preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet (toutes 401 no-auth). /health PROD 200, 0 5xx API + 0 JWT_SESSION_ERROR Client + 0 pod restart. GitOps MATCH=YES. Rollout 20s.

QA Ludovic navigateur PROD CRITIQUE confirmee : Brouillon IA auto visible + AISuggestionSlideOver charge + AIDecisionPanel charge + qualite reponse inchangee + Inbox + tenant switcher + escalation badge + auth flow fonctionnels, aucune banniere d erreur, aucune regression.

Aucune mutation DB, aucune generation LLM artificielle, aucune consommation KBActions, aucun wallet debit, aucun draftText publie. Rollback PROD pret en moins de 5 minutes vers `v3.5.180-ai-settings-wallet-tenantguard-prod`.

Plan gating handler-level PH137-D (PRO+ requis) est desormais bind par tenantGuard membership en amont en PROD : contournement plan via crafted tenantId cross-tenant ferme.

KEY-301 reste Open epic. AS.12.2C-2 (guard/check), AS.12.2C-3 (evaluate), AS.12.2C-4 (execute), AS.12.2C-5 (rules) restent a livrer.

---

## 2. Scope

Inclus :
- Build API PROD `v3.5.181-ai-assist-tenantguard-prod` depuis commit `28a31d96`.
- Push GHCR (1 cible).
- Manifest `k8s/keybuzz-api-prod/deployment.yaml` (1 ligne image).
- Validation negative + preserve PROD.
- QA Ludovic navigateur PROD focus Brouillon IA.
- Rapport docs-only ASCII strict.
- Texte Linear KEY-301 prepare.

Strictement hors scope :
- Aucun build Client.
- Aucun deploy Client PROD.
- Aucun touchement Backend / Outbound worker / Amazon workers / Backfill scheduler / Admin-v2.
- Aucune mutation DB.
- Aucun POST positif PROD vers /ai/assist (interdit : aurait declenche LLM + KBActions).
- Aucune generation IA artificielle.
- Aucune consommation KBActions / wallet / credits artificielle.
- Aucun draftText publie.
- /ai/evaluate, /ai/execute, /ai/guard/check, /ai/rules (sous-phases AS.12.2C-2..5).
- /ai/global/settings, /ai/credits/add, /ai/wallet/dev/* (defer maintenu).
- Aucun changement Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-1-AI-ASSIST-TENANTGUARD-HARDENING-DEV-01.md` -- DEV validation + design.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-LLM-MUTATIONS-TENANTGUARD-DESIGN-AUDIT-01.md` -- audit + roadmap.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2D-AI-SETTINGS-WALLET-TENANTGUARD-HARDENING-PROD-01.md` -- promotion API+Client PROD precedente.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / 28a31d96 / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / a46eb5f / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 508414b / 0-0 | identique | OK |
| Runtime DEV API | v3.5.181-ai-assist-tenantguard-dev | identique | OK |
| Runtime PROD API pre | v3.5.180-ai-settings-wallet-tenantguard-prod | identique | OK |
| Runtime PROD Client | v3.5.192-ai-settings-wallet-bff-prod | identique | OK |
| KEY-309 tag avail API PROD | v3.5.181-ai-assist-tenantguard-prod AVAILABLE | AVAILABLE | OK |
| Disk bastion docker | > 30 GB libres | 75 GB libres (20% used) | OK |

---

## 5. Build PROD

| Item | Valeur |
|---|---|
| Source commit | 28a31d962f05e647a004211a5bdc1e27fdea7a2e |
| Source ligne | `fix(security): protect /ai/assist LLM mutation with tenant guard (KEY-301 AS.12.2C-1)` |
| Tag image | v3.5.181-ai-assist-tenantguard-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | 28a31d962f05e647a004211a5bdc1e27fdea7a2e |
| KEY-308 OCI created | 2026-05-12T15:52:36Z |
| KEY-308 OCI version | v3.5.181-ai-assist-tenantguard-prod |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Build output | Successfully built 4b47d92b04d9 |
| Digest GHCR | sha256:fa238d56a4f4d1572e52c553f9e5b0c408f64528809df202806f03a9abc44fee |
| Rollback tag | v3.5.180-ai-settings-wallet-tenantguard-prod (sha256:bed42ecb7f6e...) |

Source commit identique entre DEV et PROD. Build-from-Git strict. Aucun docker push hors la cible PROD API.

---

## 6. GitOps PROD

Commit infra `148ba5a` :

```
gitops(prod): promote /ai/assist tenantGuard API (AS.12.2C-1-PROD KEY-301)
```

Modifie 1 manifest :
- `k8s/keybuzz-api-prod/deployment.yaml` : v3.5.180 -> v3.5.181

Apply :
- `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
- Rollout duration : **20 secondes**
- Pod API PROD : nouveau pod 1/1 Running, ancien Terminating puis supprime.

Aucun kubectl set / patch / edit / set env. GitOps pur.

---

## 7. Runtime PROD post-deploy

| Service | Namespace | Image pre | Image post | MATCH | Pods Ready | Restarts |
|---|---|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.180-ai-settings-wallet-tenantguard-prod | **v3.5.181-ai-assist-tenantguard-prod** | YES | 1/1 | 0 |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | identique | YES | 1/1 | inchange |
| keybuzz-client | keybuzz-client-prod | v3.5.192-ai-settings-wallet-bff-prod | identique | YES | 1/1 | inchange |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | identique | YES | 1/1 | inchange |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | identique | YES | 1/1 | inchange |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | identique | YES | 1/1 | inchange |

Runtime API PROD = spec manifest = last-applied = digest pushe sur GHCR. 7 autres services PROD strictement inchanges.

---

## 8. Validation PROD (negative + preserve, no PII, no LLM)

### 8.1 Negative tests /ai/assist PROD

| # | Endpoint | Method | Body | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| T1 | /ai/assist | POST | `{"tenantId":"fake-tenant"}` | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| T2 | /ai/assist | POST | `{}` (no tenantId) | 400 TENANT_ID_MISSING (tenantGuard extractTenantId returns null before email check) | 400 | PASS |

Aucun POST positif emis avec body valide (`contextType` + `contextId`/`conversationId` + `payload`) -> aucune generation LLM declenchee en PROD.

### 8.2 Preserve previous PROD protections

| # | Endpoint | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | /messages/conversations | GET | 401 (KEY-304) | 401 | PASS |
| P2 | /tenants | GET (no-auth) | 401 (AS.12.1A-PROD) | 401 | PASS |
| P3 | /notifications | GET | 401 (AS.12.1B-PROD) | 401 | PASS |
| P4 | /autopilot/draft | GET | 401 (AS.12.2B-PROD) | 401 | PASS |
| P5 | /ai/settings | GET | 401 (AS.12.2D-PROD) | 401 | PASS |
| P6 | /ai/wallet/status | GET | 401 (AS.12.2D-PROD) | 401 | PASS |

KEY-304, AS.12.1A-PROD, AS.12.1B-PROD, AS.12.2B-PROD, AS.12.2D-PROD integralement preserves.

### 8.3 Health + logs

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| /health PROD public | 200 | 200 | PASS |
| Logs API PROD 5 min, 5xx ou level=50 | 0 | 0 | PASS |
| Logs Client PROD 5 min, JWT_SESSION_ERROR | 0 | 0 | PASS |
| Pod API PROD restarts (new pod) | 0 | 0 | PASS |

### 8.4 QA Ludovic navigateur PROD

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth PROD | compte business habituel |
| Inbox liste conversations visible | OUI |
| Brouillon IA visible automatiquement | OUI |
| AISuggestionSlideOver charge correctement | OUI |
| AIDecisionPanel charge (consomme assist) | OUI |
| Qualite reponse Brouillon IA visuellement | inchangee |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| AIModeSwitch + wallet display (AS.12.2D-PROD) | OUI |
| Tenant switcher fonctionnel | OUI |
| Escalation badge KEY-263 | OUI |
| Auth flow OK | OUI |
| Banniere erreur visible | NON |
| 401 errors devtools sur appels /api/ai/assist legitimes | NON observe |
| Regression visible | NON |

Le BFF Client `/api/ai/assist` injecte X-User-Email + X-Tenant-Id depuis NextAuth (inchange depuis AS.12.2A) -> tenantGuard PROD accepte les appels legitimes -> Brouillon IA + AISuggestionSlideOver + AIDecisionPanel continuent de fonctionner en PROD. La qualite de reponse est preservee : le handler `assist` n est pas modifie, seul l acces preHandler est ajoute.

Aucune donnee client copiee. Aucun draftText publie. Aucune capture ecran PII committee.

---

## 9. DB / mutation no-impact (PROD)

Aucun POST positif emis vers `/ai/assist` PROD avec body valide. Toutes les requetes negatives sont rejetees par tenantGuard preHandler (401) ou par extractTenantId (400) AVANT atteinte du handler `assist`. Aucun appel LLM execute. Aucune ligne `ai_action_log` inseree par cette phase en PROD. Aucune consommation wallet / KBActions / credits.

Aucune lecture DB PROD au-dela de ce qui est strictement necessaire pour la phase. La preuve indirecte (401/400 preHandler) suffit.

---

## 10. Rollback plan (PRET, NON EXECUTE)

Rollback PROD strict GitOps en moins de 5 minutes :

```
cd /opt/keybuzz/keybuzz-infra
git revert 148ba5a --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.180-ai-settings-wallet-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
```

Tag rollback exact : `v3.5.180-ai-settings-wallet-tenantguard-prod` (sha256:bed42ecb7f6e42dbe1e0bee2c60480a0939dc3be200b88c7d72756356931fe7b).

Triggers rollback immediat :
- Brouillon IA disparait en PROD (Inbox affiche conversations mais zone Suggestion IA vide)
- AISuggestionSlideOver ou AIDecisionPanel ne charge plus
- 401 errors devtools sur `/api/ai/assist` legitime
- spike 5xx API PROD anormal
- consommation anormale wallet/KBActions PROD
- 403 NOT_MEMBER injustifie sur compte legitime PROD

Fenetre de surveillance recommandee : 30 min actives + 24h passives.

---

## 11. PROD unchanged proof (7 autres services)

| Namespace | Workload | Image runtime (pre + post AS.12.2C-1-PROD) |
|---|---|---|
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-client-prod | keybuzz-client | v3.5.192-ai-settings-wallet-bff-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Seul `keybuzz-api-prod/keybuzz-api` est passe de v3.5.180 a v3.5.181. Aucun manifest PROD autre touche.

---

## 12. AI feature parity / anti-regression

| Surface | Statut PROD post AS.12.2C-1-PROD | Justification |
|---|---|---|
| Tenant switcher | OK | inchange |
| Inbox liste / detail / reply / status / assign / sav-status | OK (KEY-304 PROD) | inchange |
| Escalation badge KEY-263 (BFF /api/notifications) | OK (AS.12.1B-PROD) | inchange |
| AIModeSwitch (BFF /api/ai/settings) | OK (AS.12.2D-PROD) | inchange |
| Brouillon IA auto + wallet balance | OK (AS.12.2D-PROD pour wallet/settings + AS.12.2C-1-PROD pour assist call) | verifie QA Ludovic |
| AISuggestionSlideOver + AIDecisionPanel | OK | verifie QA Ludovic |
| Autopilot settings + history + draft + draft/consume + evaluate | OK (AS.12.2B-PROD) | inchange |
| Channels / suppliers / commande / catalogue | inchanges | hors scope KEY-301 |
| /ai/evaluate, /ai/execute, /ai/guard/check, /ai/rules | inchanges (sous-phases AS.12.2C-2..5) | scope futur |

Aucune regression observee. Aucune mutation reellement effectuee en PROD.

---

## 13. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve. Toutes les valeurs (digest sha256:fa238d56..., commits 148ba5a + 28a31d96, rollout 20s, log counts 0 5xx + 0 JWT_SESSION_ERROR + 0 restart, runtime images PROD post-deploy) sont issues de mesures directes runtime ou GHCR.

---

## 14. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 21 jeux de commentaires accumules.

### 14.1 KEY-301 commentaire AS.12.2C-1-PROD (texte cible)

```
## AS.12.2C-1-PROD promotion executed -- /ai/assist hardened in PROD

- API PROD : v3.5.180-ai-settings-wallet-tenantguard-prod -> v3.5.181-ai-assist-tenantguard-prod (source commit 28a31d96, identical to DEV runtime).
- Client PROD strictly unchanged (v3.5.192). No Client build, no Client deploy. The BFF /api/ai/assist already requires a NextAuth session (401 NO_SESSION) and injects X-User-Email + X-Tenant-Id ; tenantGuard now accepts legitimate calls.
- 7 other PROD services strictly unchanged.
- GitOps MATCH=yes. Rollout 20s.
- Validation post-deploy PROD : /ai/assist returns 401 unauthenticated and 400 if tenantId is missing -- both reject before reaching the LLM handler. No positive POST issued ; no LLM generation triggered, no KBActions consumed, no wallet debit.
- Preserve checks : KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet all 401 unauthenticated.
- /health PROD 200. 0 API 5xx. 0 Client JWT_SESSION_ERROR. 0 pod restart.
- Ludovic QA navigateur PROD reconfirmed : Brouillon IA auto visible + AISuggestionSlideOver + AIDecisionPanel loads + response quality visually unchanged + AIModeSwitch + wallet display + Inbox + tenant switcher + escalation badge all functional, no error banner, no regression.

Plan gating handler-level PH137-D (PRO+ required for AI suggestions) is now bound to the calling user's actual tenant membership in PROD : a crafted tenantId attempting to exploit a tier's LLM access is rejected at preHandler.

KEY-301 stays Open as an epic. Remaining LLM-mutation sub-phases pending : AS.12.2C-2 guard/check (P1 read-only, BFF + Client patch), AS.12.2C-3 evaluate (P0 mutation log, BFF + Client patch), AS.12.2C-4 execute (P0 critical downstream side effects, BFF + Client patch), AS.12.2C-5 rules (P1 admin, BFF + Client patch).

Rollback ready in less than 5 minutes via revert infra commit 148ba5a.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-1-AI-ASSIST-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 15. Compliance AS.12.2C-1-PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (api 28a31d96 + infra 148ba5a) | OK |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| API-only (aucun build/push Client) | OK |
| KEY-308 OCI labels non "unknown" | OK |
| KEY-309 pre-push tag check AVAILABLE | OK |
| Digest documente | OK (sha256:fa238d56...) |
| Rollback plan documente et tag rollback | OK section 10 |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit / set env | OK |
| Aucun deploy hors keybuzz-api-prod/keybuzz-api | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB | OK |
| Aucun POST positif PROD vers /ai/assist | OK |
| Aucune generation LLM artificielle | OK |
| Aucune consommation KBActions / wallet / credits | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 NOT marked Done | OK (reste Open epic) |
| 7 autres PROD services strictement unchanged | OK |
| Pod API PROD restart count = 0 post-deploy | OK |
| Plan gating PH137-D preserve, desormais bind par tenantGuard membership en amont | OK |

---

## 16. Phrase cible finale

AS.12.2C-1-PROD livre : promotion PROD du hardening /ai/assist (LLM mutation) en API-only ; image PROD v3.5.180-ai-settings-wallet-tenantguard-prod -> v3.5.181-ai-assist-tenantguard-prod depuis source commit 28a31d96 (identique runtime DEV AS.12.2C-1) ; digest GHCR sha256:fa238d56a4f4d1572e52c553f9e5b0c408f64528809df202806f03a9abc44fee ; commit infra `148ba5a` ; rollout API PROD 20s ; GitOps MATCH=yes ; 7 autres services PROD strictement inchanges (worker, backend, Amazon workers x2, backfill scheduler, admin-v2, Client PROD inchange v3.5.192) ; validation PROD T1 no-auth 401 + T2 no body 400 + preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet 401 + /health 200 ; logs PROD 5min 0 5xx + 0 JWT_SESSION_ERROR + 0 restart ; QA Ludovic navigateur PROD reconfirmee (Brouillon IA auto + AISuggestionSlideOver + AIDecisionPanel + qualite reponse inchangee + AIModeSwitch + wallet display + Inbox + tenant switcher + escalation badge + auth fonctionnels, aucune banniere, aucune regression) ; aucun POST positif PROD vers /ai/assist, aucune generation LLM, aucune consommation KBActions/wallet/credits, aucun draftText publie, aucune PII publiee, aucun secret, aucun deploy hors API PROD ; plan gating handler-level PH137-D PRO+ desormais bind par tenantGuard membership en amont en PROD ; rollback PROD pret en < 5 min vers v3.5.180-ai-settings-wallet-tenantguard-prod ; KEY-301 reste Open epic ; AS.12.2C-2..5 (guard/check, evaluate, execute, rules) restent a livrer ; verdict AS.12.2C-1-PROD GO AI ASSIST TENANTGUARD PROD READY.

STOP
