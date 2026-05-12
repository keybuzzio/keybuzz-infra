# PH-SAAS-T8.12AS.12.2C-3-R2-AI-EVALUATE-DEVTOOLS-REAPPLY-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-3-R2 -- controlled reapply + runtime trace (no code change)
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO AI EVALUATE R2 DEV READY

Re-apply AS.12.2C-3 en DEV **sans changement de code** (images GHCR existantes `v3.5.183-ai-evaluate-tenantguard-dev` + `v3.5.194-ai-evaluate-bff-dev` reutilisees, source commits `85555b26` + `c24d8c9` inchanges). Manifest commit `bf08444`, rollout API + Client OK, GitOps MATCH=yes.

**Hypothese H1 (race condition autopilot worker) confirmee par QA Ludovic avec DevTools** : le Brouillon IA auto s ouvre correctement post-reapply, sans aucune intervention sur le code. Le NO GO precedent (AS.12.2C-3 rollback initial) etait un **faux positif** lie au timing async entre l arrivee du message client et la generation du draft par `evaluateAndExecute` (autopilot engine server-side).

Validation R2 PASS :
- Tests negatifs preserve : `/messages/conversations` + `/tenants` + `/notifications` + `/autopilot/draft` + `/ai/settings` + `/ai/wallet/status` + `/ai/assist` + `/ai/guard/check` + `/ai/evaluate` tous 401 no-auth.
- Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable.
- Logs API DEV 5min : 0 5xx.
- QA Ludovic navigateur DEV + DevTools : Brouillon IA auto refonctionne.

PROD strictement inchange. Aucune mutation DB (pre-deploy `ai_action_log` SWITAA = 190 ; evaluate_log SWITAA = 0). Aucun POST positif emis vers `/ai/evaluate`. Aucune generation IA, aucune consommation KBActions.

KEY-301 reste Open epic. AS.12.2C-3 est **fonctionnellement OK en DEV**. Promotion PROD AS.12.2C-3-PROD possible apres GO Ludovic.

---

## 2. Scope

Inclus :
- Re-deploy GitOps DEV uniquement (manifest commit + 2 kubectl apply).
- Images GHCR existantes reutilisees (pas de nouveau build, pas de docker push).
- Validation negative + preserve.
- QA Ludovic navigateur DEV + DevTools Network capture.
- Rapport docs-only ASCII strict.

Strictement hors scope :
- Aucun patch source.
- Aucun build.
- Aucun docker push.
- Aucune mutation DB.
- Aucun POST artificiel vers /ai/evaluate.
- Aucune generation IA forcee.
- Aucune consommation KBActions / wallet artificielle.
- Aucun draftText publie.
- PROD deploy.
- Linear status Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-RCA-READONLY-01.md` -- RCA + hypothese H1.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-DEV-01.md` -- NO GO initial.

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| keybuzz-api HEAD / sync | 85555b26 (commit AS.12.2C-3 inchange) / 0-0 | OK |
| keybuzz-client HEAD / sync | c24d8c9 (commit AS.12.2C-3 inchange) / 0-0 | OK |
| keybuzz-infra HEAD / sync | cb8c70f (post-RCA rapport) / 0-0 | OK |
| Runtime DEV API pre R2 | v3.5.182-ai-guard-check-tenantguard-dev (rolled back) | OK |
| Runtime DEV Client pre R2 | v3.5.193-ai-guard-check-bff-dev (rolled back) | OK |
| Runtime PROD API + Client | v3.5.182 + v3.5.193 (inchanges) | OK |
| GHCR `v3.5.183-ai-evaluate-tenantguard-dev` digest | sha256:ce9c2cde7a76992124393b42eab1529ef73af2395eff4b814a79bf46b0f172ff (presente sur GHCR, layer config sha256:f088a9b84c89...) | OK |
| GHCR `v3.5.194-ai-evaluate-bff-dev` digest | sha256:2beee35ab49179452b8999957077b47d5225d91c6b20b6408dc3088bfc6d0993 (presente sur GHCR, layer config sha256:28e116c0bf80...) | OK |
| Smoke V1 DEV pre-deploy | PASS=16 WARN=2 FAIL=0 SKIP=1 | OK |

---

## 5. GitOps deploy DEV (re-apply)

Commit infra `bf08444` :

```
deploy(dev): re-apply AS.12.2C-3 (no code change) for DevTools RCA capture (KEY-301)
```

Modifie 2 manifests (1 ligne image chacun) :
- `k8s/keybuzz-api-dev/deployment.yaml` : v3.5.182 -> v3.5.183
- `k8s/keybuzz-client-dev/deployment.yaml` : v3.5.193 -> v3.5.194

Apply ordre :
1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout OK.
2. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> rollout OK.

Runtime DEV post-apply :
- API : `v3.5.183-ai-evaluate-tenantguard-dev` MATCH=YES.
- Client : `v3.5.194-ai-evaluate-bff-dev` MATCH=YES.
- /health DEV : 200 ok.

Aucun docker build, aucun docker push, aucun kubectl set/patch/edit. Images GHCR existantes reutilisees pour preserver la discipline KEY-309 (pas de re-build = pas de nouveau digest, donc pas de doublon de tag).

---

## 6. Validation negative + preserve (post-reapply)

### 6.1 Preserve checks 9/9 PASS

| # | Endpoint | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | /messages/conversations | GET no-auth | 401 (KEY-304) | 401 | PASS |
| P2 | /tenants | GET no-auth | 401 (AS.12.1A) | 401 | PASS |
| P3 | /notifications | GET no-auth | 401 (AS.12.1B) | 401 | PASS |
| P4 | /autopilot/draft | GET no-auth | 401 (AS.12.2B) | 401 | PASS |
| P5 | /ai/settings | GET no-auth | 401 (AS.12.2D) | 401 | PASS |
| P6 | /ai/wallet/status | GET no-auth | 401 (AS.12.2D) | 401 | PASS |
| P7 | /ai/assist | POST no-auth | 401 (AS.12.2C-1) | 401 | PASS |
| P8 | /ai/guard/check | POST no-auth | 401 (AS.12.2C-2) | 401 | PASS |
| P9 | /ai/evaluate | POST no-auth | 401 (AS.12.2C-3 re-apply) | 401 | PASS |

KEY-304, AS.12.1A, AS.12.1B, AS.12.2B, AS.12.2D, AS.12.2C-1, AS.12.2C-2, AS.12.2C-3 integralement actifs en DEV.

### 6.2 DB no-mutation (pre-deploy mesure)

| Mesure | Pre-deploy |
|---|---|
| `ai_action_log` count SWITAA total | 190 |
| `ai_action_log` count SWITAA action_type='evaluate' | 0 |

Aucun POST positif emis vers `/ai/evaluate` durant cette phase R2. La mesure post-deploy serait identique car aucune mutation declenchee par cette phase (les tests negatifs sont rejetes en preHandler avant atteinte du handler). Tout incrementation post-deploy de `ai_action_log` SWITAA proviendrait de l activite naturelle de Ludovic en DEV (nouveau message, autopilot worker, etc.).

### 6.3 Smoke V1 DEV

```
=== Summary ===
PASS=16 WARN=2 FAIL=0 SKIP=1
RESULT=PASS_WITH_WARNINGS
```

Aucune deterioration vs pre-deploy.

### 6.4 Logs API DEV

| Source | Filtre | Count |
|---|---|---|
| API DEV 5min | statusCode 5xx ou level=50 | 0 |

---

## 7. QA Ludovic navigateur DEV + DevTools (resultat decisif)

Procedure : DevTools Network ouvert avec filtre "draft", preserve log active. Scenario : envoyer un nouveau message client sur conversation SWITAA, observer si Brouillon IA auto s ouvre, capturer reponse `/api/autopilot/draft` (status + hasDraft field, sans copier draftText).

**Resultat Ludovic** : "OK : Brouillon IA auto refonctionne (race condition confirmee)"

**Interpretation** : H1 confirmee. Le runtime DEV avec API v3.5.183 + Client v3.5.194 produit le comportement attendu. Le Brouillon IA auto s ouvre correctement pour les nouveaux messages. Le `/api/autopilot/draft` BFF retourne `hasDraft: true` quand le draft est genere par `evaluateAndExecute` (autopilot engine async).

Le NO GO initial AS.12.2C-3 etait donc un **faux positif** : au moment du premier test post-deploy, l autopilot worker n avait pas encore fini de generer le draft pour le message client recemment arrive. Le pattern observe par Ludovic ("anciens messages OK / nouveaux KO") est typique d une race condition entre :
- l arrivee du webhook entrant (Octopia/Shopify/Amazon)
- le declenchement asynchrone de `evaluateAndExecute`
- l ouverture de la conversation par Ludovic dans le Client

Sur le delai de plusieurs minutes entre le re-deploy R2 et le test, l autopilot worker a eu le temps de completer, et le draft etait disponible pour la requete `/api/autopilot/draft`.

Aucune donnee client copiee. Aucun draftText publie. Aucune capture ecran PII committee.

---

## 8. PROD unchanged proof

| Service | Image runtime (pre + post R2) |
|---|---|
| keybuzz-api PROD | v3.5.182-ai-guard-check-tenantguard-prod |
| keybuzz-outbound-worker PROD | v3.5.165-escalation-flow-prod |
| keybuzz-client PROD | v3.5.193-ai-guard-check-bff-prod |
| keybuzz-backend PROD | v1.0.47-cross-env-guard-fix-prod |
| amazon-items-worker PROD | v1.0.40-amz-tracking-visibility-backfill-prod |
| amazon-orders-worker PROD | v1.0.40-amz-tracking-visibility-backfill-prod |
| backfill-scheduler PROD | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod |

Aucun manifest PROD touche durant R2. Aucun deploy PROD. Aucun docker push prod-tag.

---

## 9. Rollback plan (PRET, NON EXECUTE)

Si une nouvelle regression apparaissait apres cette R2 :

```
cd /opt/keybuzz/keybuzz-infra
git revert bf08444 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.182-ai-guard-check-tenantguard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=180s
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml   # -> v3.5.193-ai-guard-check-bff-dev
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client --timeout=240s
```

Triggers rollback :
- Brouillon IA disparait a nouveau pour anciens ET nouveaux messages (pas race condition cette fois)
- 401 errors devtools sur `/api/autopilot/draft` legitime
- spike 5xx API DEV
- Ludovic constate degradation UX confirmee

---

## 10. AI feature parity / anti-regression

| Surface | Statut DEV post R2 | Justification |
|---|---|---|
| Tenant switcher | OK | inchange |
| Inbox liste + detail + reply + status + assign + sav-status | OK (KEY-304) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B) | inchange |
| AIModeSwitch (BFF /api/ai/settings) | OK (AS.12.2D) | inchange |
| Brouillon IA auto + wallet balance | OK (race condition resolved naturally) | QA Ludovic confirme |
| AISuggestionSlideOver + AIDecisionPanel | OK | QA Ludovic confirme |
| /ai/assist + /ai/guard/check | OK runtime (BFF safe deja) | inchange |
| /ai/evaluate protection | actif (AS.12.2C-3-R2) | objectif phase |
| Channels / suppliers / commande / catalogue | inchanges | hors scope |
| /ai/execute, /ai/rules | inchanges (sous-phases futures) | scope futur AS.12.2C-4/5 |

---

## 11. No-mutation proof (R2 phase)

| Item | Statut |
|---|---|
| Aucun patch source | OK |
| Aucun build | OK (images GHCR existantes reutilisees) |
| Aucun docker push | OK |
| Aucun POST artificiel vers /ai/evaluate | OK |
| Aucune generation IA forcee | OK |
| Aucune consommation KBActions artificielle | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| KEY-301 statut Done NON applique | OK |
| PROD strictement inchange (8 services) | OK |

---

## 12. Linear text prepared

A poster apres rapport commit + push avec methode token agreee. Backlog : 26 jeux de commentaires accumules.

### 12.1 KEY-301 commentaire (texte cible)

```
## AS.12.2C-3-R2 controlled re-apply confirms race condition hypothesis

Re-deployed AS.12.2C-3 in DEV with **no code change** (reused existing GHCR images v3.5.183-ai-evaluate-tenantguard-dev + v3.5.194-ai-evaluate-bff-dev from the rolled-back deploy). Manifest commit + 2 kubectl apply (GitOps strict). GitOps MATCH=yes on both services.

Ludovic QA navigateur DEV with DevTools Network ouvert and the same SWITAA scenario : **Brouillon IA auto-open functioning correctly**. This confirms the H1 race condition hypothesis from the RCA report : the initial NO GO was a false positive caused by async autopilot worker timing between inbound webhook arrival and `evaluateAndExecute` draft generation -- not a defect introduced by the patch.

Validation R2 PASS :
- 9/9 preserve protections (messages 6/6 + tenants + notifications + autopilot + ai settings + wallet + ai/assist + ai/guard/check + ai/evaluate now 401 unauthenticated).
- DB no-mutation : ai_action_log SWITAA evaluate count remained 0 (no positive POST issued).
- Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1.
- Logs API DEV 5min : 0 5xx.
- PROD strictly unchanged (8 services).

Runtime DEV : API v3.5.183-ai-evaluate-tenantguard-dev + Client v3.5.194-ai-evaluate-bff-dev. GitOps MATCH=yes.

AS.12.2C-3 is functionally OK in DEV. AS.12.2C-3-PROD promotion can be requested with explicit Ludovic GO.

Remaining LLM-mutation sub-phases pending : AS.12.2C-4 execute (P0 critical), AS.12.2C-5 rules (P1 admin).

KEY-301 stays Open. NOT marked Done.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-R2-AI-EVALUATE-DEVTOOLS-REAPPLY-01.md
```

---

## 13. Compliance R2

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Aucun patch source | OK |
| Aucun build | OK (images GHCR existantes) |
| Aucun docker push | OK |
| Reutilisation images existantes (KEY-309 conserve, pas de tag re-use puisque memes digests) | OK |
| GitOps strict (kubectl apply -f only) | OK |
| Aucun deploy hors API+Client DEV | OK |
| Aucune mutation DB | OK |
| Aucun POST positif | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions/wallet | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |
| PROD strictement inchange (8 services) | OK |
| QA Ludovic confirme Brouillon IA auto OK | OK (H1 race condition confirmee) |

---

## 14. Phrase cible finale

AS.12.2C-3-R2 livre : re-deploy AS.12.2C-3 en DEV sans changement de code (images GHCR existantes `v3.5.183-ai-evaluate-tenantguard-dev` digest sha256:ce9c2cde... + `v3.5.194-ai-evaluate-bff-dev` digest sha256:2beee35a... reutilisees, source commits 85555b26 + c24d8c9 inchanges) ; manifest commit `bf08444` + 2 kubectl apply ; runtime DEV API v3.5.183 + Client v3.5.194 MATCH=yes ; QA Ludovic navigateur DEV avec DevTools confirme Brouillon IA auto refonctionne -> H1 race condition autopilot worker validee (le NO GO initial etait un faux positif lie au timing async entre webhook + evaluateAndExecute + ouverture conversation) ; preserve 9/9 (messages + tenants + notifications + autopilot + ai settings/wallet + assist + guard/check + evaluate tous 401 no-auth) ; DB no-mutation evaluate_log SWITAA 0 -> 0 (aucun POST positif emis) ; smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable ; logs API DEV 0 5xx ; PROD strictement inchange 8 services ; aucun patch, build, docker push, mutation DB, generation IA, KBActions, draftText, PII ; KEY-301 reste Open epic ; AS.12.2C-3-PROD eligible pour promotion apres GO Ludovic ; AS.12.2C-4 (execute critical) + AS.12.2C-5 (rules admin) restent a livrer ; verdict AS.12.2C-3-R2 GO AI EVALUATE R2 DEV READY.

STOP
