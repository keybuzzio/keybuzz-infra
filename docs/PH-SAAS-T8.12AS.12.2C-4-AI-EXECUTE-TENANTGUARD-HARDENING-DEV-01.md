# PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-4 -- implementation hardening /ai/execute en DEV (BFF + tenantGuard)
> Environnement : DEV ; PROD strictement read-only et inchange

---

## 1. VERDICT

GO AI EXECUTE TENANTGUARD DEV READY

Implementation du hardening /ai/execute livree en DEV selon le design audit AS.12.2C-4 :
- API : `v3.5.183-ai-evaluate-tenantguard-dev` -> `v3.5.184-ai-execute-tenantguard-dev` (digest GHCR `sha256:50ebb39228ea6b3b14c2615eaa987581b16467e2e20cb4852f3f3c1a8b22ffff`, OCI revision `d7f2a8fd120c73d1b532940263f94ed2de2e5dc7`).
- Client : `v3.5.194-ai-evaluate-bff-dev` -> `v3.5.195-ai-execute-bff-dev` (digest GHCR `sha256:10ab15de30c137c268c6447c9d7a0d4db2aa754956017bbf63a027121ae35294`, OCI revision `14a4ea66d4b8dc67093b9061488f7307669b791c`).
- Manifest infra commit `6580abb` push origin/main 0-0.
- 2 kubectl apply -f DEV + rollouts successful ; spec = last-applied = pod imageID = digest pushe.

Validation negative DEV : **10/10 protections actives** (`/ai/execute` NEW + 9 preserve : `/ai/evaluate`, `/ai/assist`, `/ai/guard/check`, `/messages/conversations`, `/tenants`, `/notifications`, `/autopilot/draft`, `/ai/settings`, `/ai/wallet/status`, tous 401 unauthenticated avec payloads valides). 0 5xx API DEV 5min, 0 JWT_SESSION_ERROR Client DEV 5min. DB `ai_action_log` execute_count = 0 (aucun POST positif emis).

QA Ludovic navigateur DEV (URL **`https://client-dev.keybuzz.io`**) : conversation `commande 07090405006` Brouillon IA auto OK ; conversations `Commande 0808080808` Brouillon IA KO mais **pattern identique en PROD pre-patch** = garde-fous metier `PRE_LLM_BLOCKED:HIGH` (autopilot_reply skipped) et `ESCALATION_DRAFT:0.75` (autopilot_escalate skipped). Diagnostic read-only confirme :
- `/autopilot/draft` = 200/200 toutes requetes (tenantGuard non-bloquant) ;
- `/ai/execute` = 0 calls (AIDecisionPanel non monte, design audit confirme) ;
- aucune entry `ai_action_log` `action_type='execute'` derniere 2h.

Patch AS.12.2C-4 **non implique** dans le KO Brouillon IA. Probleme classe **PRE-EXISTANT** (visible DEV ET PROD avant ce patch) -> gap produit separe documente (section 14). PROD strictement inchange (toutes images DEV-only). KEY-301 reste Open epic.

---

## 2. Scope

Inclus :
- 3 patches sources (1 ligne API tenantGuard + 1 fonction Client ai.service refactor + 1 nouveau BFF route ~70 lignes).
- 2 commits + push sur branches imposees (api ph147.4 / client ph148).
- Build DEV from-git via scripts patches AS.12.2C-3.1 (KEY-308 OCI labels conformes).
- 2 docker push GHCR (KEY-309 immutable tags).
- 1 commit + push manifests DEV.
- 2 kubectl apply -f DEV + rollouts.
- Validation negative + preserve 10/10 + logs + DB no-mutation.
- QA Ludovic navigateur DEV + PROD (read-only PROD).
- Rapport docs-only ASCII strict + commit + push.

Hors scope :
- Aucun build / push / deploy PROD.
- Aucun POST positif vers /ai/execute.
- Aucune execution action downstream.
- Aucune generation LLM.
- Aucune consommation KBActions / debit wallet.
- Aucune mutation DB de notre fait.
- Aucun draftText publie / aucune PII.
- AS.12.2C-5 `/ai/rules` (admin CRUD) differe.
- Plan gating manquant sur /ai/execute (gap operationnel separe).

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-DESIGN-AUDIT-01.md` (design audit).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-PROD-01.md` (pattern PROD precedent).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3.1-BUILD-SCRIPTS-OCI-ARGS-FIX-01.md` (scripts patches).
- `keybuzz-api/src/modules/ai/routes.ts` (handler `POST /execute` lignes 356-394).
- `keybuzz-api/src/plugins/tenantGuard.ts` (PROTECTED_ROUTES + insertion point).
- `keybuzz-client/src/services/ai.service.ts` (executeAI ligne 187 + pattern evaluateAI ligne 172).
- `keybuzz-client/app/api/ai/evaluate/route.ts` (template BFF NextAuth).
- `keybuzz-client/src/features/ai-ui/AIDecisionPanel.tsx` (caller verifie).

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| keybuzz-api HEAD pre-patch / branche / sync | 85555b26 / ph147.4/source-of-truth / 0-0 | OK |
| keybuzz-client HEAD pre-patch / branche / sync | c24d8c9 / ph148/onboarding-activation-replay / 0-0 | OK |
| keybuzz-infra HEAD pre-patch / sync | 45b4971 (rapport AS.12.2C-4 design) / 0-0 / 0 dirty | OK |
| Runtime DEV API pre-patch | v3.5.183-ai-evaluate-tenantguard-dev | OK baseline |
| Runtime DEV Client pre-patch | v3.5.194-ai-evaluate-bff-dev | OK baseline |
| Runtime PROD API | v3.5.183-ai-evaluate-tenantguard-prod | OK (read-only) |
| Runtime PROD Client | v3.5.194-ai-evaluate-bff-prod | OK (read-only) |
| KEY-309 tag availability `v3.5.184-ai-execute-tenantguard-dev` | GHCR manifest unknown | OK libre |
| KEY-309 tag availability `v3.5.195-ai-execute-bff-dev` | GHCR manifest unknown | OK libre |
| Smoke V1 DEV | scripts/smoke-v1.sh absent du repo bastion | NOTE saute (non bloquant) |

---

## 5. Patch sources

### 5.1 keybuzz-api : `src/plugins/tenantGuard.ts`

Header doc : ajout du block AS.12.2C-4 et mise a jour du commentaire AS.12.2C-5.

PROTECTED_ROUTES : ajout `{ method: 'POST', path: '/ai/execute' }` apres l entree AS.12.2C-3 evaluate.

Total : 19 insertions(+) / 3 deletions(-) sur 1 fichier. Aucune autre modification API.

Commit : `d7f2a8fd feat(security): protect /ai/execute via tenantGuard (KEY-301 AS.12.2C-4)` push origin/ph147.4/source-of-truth 0-0.

### 5.2 keybuzz-client : `src/services/ai.service.ts`

Fonction `executeAI` reecrite :
- Avant : `return fetchAI<AIExecuteResponse>('/ai/execute', ...)` (browser direct API).
- Apres : `fetch('/api/ai/execute', { method: 'POST', headers: 'Content-Type: application/json', body })` (BFF relatif).

Commentaire PH-SAAS-T8.12AS.12.2C-4 KEY-301 explicite la migration.

Total : 13 insertions(+) / 1 deletion(-) sur 1 fichier.

### 5.3 keybuzz-client : `app/api/ai/execute/route.ts` (nouveau)

Nouveau fichier BFF Next.js Server (~66 lignes) :
- `import { getServerSession } from 'next-auth'` + `authOptions`.
- POST handler : verifie session NextAuth (401 si absente).
- Lit tenantId depuis header `X-Tenant-Id` ou body.tenantId (400 si manquant).
- Forward POST `${API_URL}/ai/execute` avec headers `X-User-Email` + `X-Tenant-Id` injectes ; body inchange.
- Gestion erreur non-2xx avec extrait stdout 200 chars.
- `export const dynamic = 'force-dynamic'` pour eviter cache Next.js.

Aucun cookie forward, aucune fuite secret, aucune ecriture cote BFF.

Commit Client : `14a4ea6 feat(security): protect /ai/execute via new BFF + ai.service refactor (KEY-301 AS.12.2C-4)` push origin/ph148/onboarding-activation-replay 0-0. 79 insertions(+) / 1 deletion(-) sur 2 fichiers (ai.service modified + nouveau route.ts).

### 5.4 Diff scope verifie

Aucun autre fichier touche dans aucun des 2 repos source. Aucune mutation manifest, aucune mutation script, aucune mutation autre composant Client / API.

---

## 6. Build DEV (scripts patches AS.12.2C-3.1)

### 6.1 API DEV

```
bash scripts/build-api-from-git.sh dev v3.5.184-ai-execute-tenantguard-dev ph147.4/source-of-truth
```

Build OK : `Successfully built ...`, `Successfully tagged ghcr.io/keybuzzio/keybuzz-api:v3.5.184-ai-execute-tenantguard-dev`. Git SHA `d7f2a8f`.

OCI labels conformes KEY-308 :

| Label | Valeur |
|---|---|
| revision | `d7f2a8fd120c73d1b532940263f94ed2de2e5dc7` (= HEAD post-push) |
| created | `2026-05-13T09:04:08Z` (ISO 8601 UTC) |
| version | `v3.5.184-ai-execute-tenantguard-dev` |
| source | `https://github.com/keybuzzio/keybuzz-api` |
| title | `keybuzz-api` |

Image Id local : `sha256:586f8a5a6cd14df9979caccd3084157643b7a8e92ab982c0058b5b4b90a6ca63` (343.6 MB).

### 6.2 Client DEV

```
bash scripts/build-from-git.sh dev v3.5.195-ai-execute-bff-dev ph148/onboarding-activation-replay
```

Build OK avec build-args automatiquement positionnes par le script (post fix AS.12.2C-3.1) :
- `NEXT_PUBLIC_APP_ENV=development`
- `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`
- `IMAGE_REVISION` / `IMAGE_CREATED` / `IMAGE_VERSION` remplis.

Git SHA `14a4ea6`. Image Id local : `sha256:8859323b4d63a18fbdd57cb9ebb7435a3fdea8f32272d7ceba48cf694305986f` (280.1 MB).

OCI labels :

| Label | Valeur |
|---|---|
| revision | `14a4ea66d4b8dc67093b9061488f7307669b791c` (= HEAD post-push) |
| created | `2026-05-13T09:04:05Z` (ISO 8601 UTC) |
| version | `v3.5.195-ai-execute-bff-dev` |
| source | `https://github.com/keybuzzio/keybuzz-client` |
| title | `keybuzz-client` |

### 6.3 verify-image-clean.sh Client DEV

```
=== RESULTATS: 17 PASS / 0 FAIL / 0 WARN ===
VERDICT: PASS -- Image valide
```

### 6.4 Verifications bundle Client DEV

| Check | Count | Verdict |
|---|---|---|
| sentinel `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | PASS KEY-302 |
| `api-dev.keybuzz.io` (DEV URL attendue) | 2 occurrences | PASS bundle DEV |
| `api.keybuzz.io` standalone (sans api-dev) | 0 | PASS pas de contamination PROD |
| `Brouillon IA` | 2 occurrences `.next/static` | PASS UX preserve |
| `Valider et envoyer` | 1 occurrence | PASS UX preserve |
| BFF route `app/api/ai/execute/route.js` | compile dans `.next/server` | PASS |
| `/api/ai/execute` ref dans manifests Next.js | 2 dans `app-path-routes-manifest.json` + 5 dans route compiled | PASS |
| `executeAI` symbol dans `.next/static` | 0 occurrences | NOTE tree-shaking (coherent design audit : AIDecisionPanel non monte) |

Note : la fonction `executeAI` est tree-shaked car son seul caller `AIDecisionPanel.tsx` est defini + reexporte mais non monte. Le BFF reste compile et servable. Si future re-integration AIDecisionPanel, executeAI sera re-inclus dans le bundle au prochain build, sans modification BFF necessaire.

---

## 7. Push GHCR

```
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.184-ai-execute-tenantguard-dev
v3.5.184-ai-execute-tenantguard-dev: digest: sha256:50ebb39228ea6b3b14c2615eaa987581b16467e2e20cb4852f3f3c1a8b22ffff size: 2416

docker push ghcr.io/keybuzzio/keybuzz-client:v3.5.195-ai-execute-bff-dev
v3.5.195-ai-execute-bff-dev: digest: sha256:10ab15de30c137c268c6447c9d7a0d4db2aa754956017bbf63a027121ae35294 size: 2631
```

KEY-309 tags immuables, KEY-308 OCI labels conformes.

---

## 8. GitOps DEV apply

### 8.1 Commit manifests infra

Commit `6580abb deploy(dev): promote AS.12.2C-4 API+Client (KEY-301 /ai/execute tenantGuard)` push origin/main 0-0 :
- `k8s/keybuzz-api-dev/deployment.yaml` : 1 ligne image+commentaire (v3.5.183 -> v3.5.184).
- `k8s/keybuzz-client-dev/deployment.yaml` : 1 ligne image+commentaire (v3.5.194 -> v3.5.195).

git status post-push : clean. Sync : 0-0.

### 8.2 Apply API DEV

```
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
deployment.apps/keybuzz-api configured

kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
deployment "keybuzz-api" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.184-ai-execute-tenantguard-dev | OK |
| last-applied-configuration | identique | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:50ebb39228ea... | OK MATCH digest pushe |

### 8.3 Apply Client DEV

```
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
deployment.apps/keybuzz-client configured

kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client --timeout=300s
deployment "keybuzz-client" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | ghcr.io/keybuzzio/keybuzz-client:v3.5.195-ai-execute-bff-dev | OK |
| last-applied-configuration | identique | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:10ab15de30c1... | OK MATCH digest pushe |

---

## 9. Validation DEV

### 9.1 /health DEV

```
GET https://api-dev.keybuzz.io/health -> 200
```

### 9.2 Preserve checks 10/10 PASS (payloads valides + no-auth)

| # | Endpoint | Method | Body / query | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| P1 | /ai/execute | POST | `{tenantId:fake,ruleId:r1,conversationId:fake}` | 401 (AS.12.2C-4 NEW) | 401 | PASS |
| P2 | /ai/evaluate | POST | `{tenantId:fake,conversationId:fake}` | 401 (preserve AS.12.2C-3) | 401 | PASS |
| P3 | /ai/assist | POST | `{tenantId:fake,contextType:message}` | 401 (preserve AS.12.2C-1) | 401 | PASS |
| P4 | /ai/guard/check | POST | `{tenantId:fake}` | 401 (preserve AS.12.2C-2) | 401 | PASS |
| P5 | /messages/conversations | GET | `tenantId=fake` | 401 (preserve KEY-304) | 401 | PASS |
| P6 | /tenants | GET | none | 401 (preserve AS.12.1A) | 401 | PASS |
| P7 | /notifications | GET | `tenantId=fake` | 401 (preserve AS.12.1B) | 401 | PASS |
| P8 | /autopilot/draft | GET | `tenantId=fake&conversationId=fake` | 401 (preserve AS.12.2B) | 401 | PASS |
| P9 | /ai/settings | GET | `tenantId=fake` | 401 (preserve AS.12.2D) | 401 | PASS |
| P10 | /ai/wallet/status | GET | `tenantId=fake` | 401 (preserve AS.12.2D) | 401 | PASS |

Bodies de test contiennent uniquement des UUIDs fictifs `00000000-...` et `11111111-...`. Aucun POST positif emis.

### 9.3 Logs

| Source | Filtre | Count |
|---|---|---|
| API DEV `statusCode 5xx / level=50` | 5min | 0 |
| Client DEV `JWT_SESSION_ERROR` | 5min | 0 |

### 9.4 DB no-mutation

| Mesure | Pre-deploy | Post-deploy 15min |
|---|---|---|
| `ai_action_log` (last 1h) total | 0 | 0 |
| `ai_action_log` (last 1h) `action_type='execute'` | 0 | 0 |

Aucun POST positif emis. Aucune mutation execute. Aucun debit wallet / KBActions.

### 9.5 Smoke V1 DEV

`scripts/smoke-v1.sh` absent du bastion. Skipped (non bloquant pour cette phase).

### 9.6 Snapshot inventory post-apply

DEV API : `v3.5.184-ai-execute-tenantguard-dev` (PROMU). DEV Client : `v3.5.195-ai-execute-bff-dev` (PROMU). Tous autres services DEV inchanges. **PROD strictement inchange** (api v3.5.183 + client v3.5.194 + outbound v3.5.165 + admin v2.12.2 + backend v1.0.47 + amazon-items v1.0.40 + amazon-orders v1.0.40 + backfill v1.0.42 + studio v0.8.0 + studio-api v0.8.1 + website v0.6.12).

---

## 10. QA Ludovic navigateur DEV + diagnostic comparatif PROD

### 10.1 URL DEV correcte

URL DEV : **`https://client-dev.keybuzz.io`** (corrige par Ludovic en cours de QA). Toutes les QA navigateur de cette phase sont basees sur `client-dev.keybuzz.io`. Cette URL est notee pour les phases futures.

### 10.2 Resultat Ludovic

| Conversation client | DEV | PROD |
|---|---|---|
| `commande 07090405006` | Brouillon IA auto OK | Brouillon IA auto OK |
| `Commande 0808080808` | Brouillon IA KO (ne s active pas) | Brouillon IA KO (ne s active pas) |

Pattern KO **identique en DEV et en PROD** -> probleme PRE-EXISTANT, non introduit par AS.12.2C-4.

### 10.3 Diagnostic read-only

**DEV** -- `ai_action_log` tenant SWITAA derniere 2h :

| conversation_id (extrait) | action_type | status | blocked | blocked_reason | confidence_score |
|---|---|---|---|---|---|
| cmmp3v8ys... | autopilot_escalate | skipped | true | ESCALATION_DRAFT:0.75 | 0.75 |
| cmmp3v0yq... | autopilot_reply | skipped | true | PRE_LLM_BLOCKED:HIGH | 0.00 |

**PROD** -- meme tenant, meme intervalle :

| conversation_id (extrait) | action_type | status | blocked | blocked_reason | confidence_score |
|---|---|---|---|---|---|
| cmmp3vjbg... | autopilot_escalate | skipped | true | ESCALATION_DRAFT:0.75 | 0.75 |
| cmmp3vbby... | autopilot_reply | skipped | true | PRE_LLM_BLOCKED:HIGH | 0.00 |

**Aucune entry `action_type='execute'`** dans `ai_action_log` derniere 2h ni en DEV ni en PROD pour SWITAA.

### 10.4 /autopilot/draft + /ai/execute traffic last 15min

| Endpoint | DEV | PROD |
|---|---|---|
| `/autopilot/draft` requetes echantillonees | 200/200 (toutes 200) | 200/200 (toutes 200) |
| `/ai/execute` requetes | 0 calls | 0 calls |

`tenantGuard` non-bloquant pour `/autopilot/draft` (tenant authentifie passe). Aucun caller `/ai/execute` (coherent design audit : AIDecisionPanel non monte).

### 10.5 Classification

Les conversations KO `0808080808` ont l autopilot worker qui :
1. A tourne (entries `ai_action_log` presentes) ;
2. A ete intercepte par garde-fous metier (`PRE_LLM_BLOCKED:HIGH` ou `ESCALATION_DRAFT:0.75`) AVANT generation LLM ;
3. N a pas produit de draft -> `/autopilot/draft` retourne `hasDraft=false` (status 200) -> Brouillon IA auto ne s ouvre pas.

C est le comportement attendu des guard-rails PH25.x (anti-emballement IA). Aucun rapport au patch AS.12.2C-4. **Patch confirme NON-IMPLIQUE.**

Pour la conversation OK `commande 07090405006`, autopilot worker a produit un draft persiste anterieurement (ou autopilot_reply executed/applied non present dans le snapshot 2h, traite plus tot). Coherent.

### 10.6 PROD strictement read-only (curl audits + kubectl get only)

Aucun curl POST positif PROD. Aucun docker push PROD. Aucun kubectl apply PROD. Aucun manifest PROD touche.

---

## 11. AI feature parity / anti-regression DEV

| Surface | Statut DEV post AS.12.2C-4 | Justification |
|---|---|---|
| Tenant switcher | OK | inchange |
| Inbox liste/detail/reply/status/assign/sav-status | OK (KEY-304 preserve) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B preserve) | inchange |
| AIModeSwitch | OK (AS.12.2D preserve) | inchange |
| Brouillon IA auto + wallet balance | OK pour conversations sans garde-fou (preserve AS.12.2B+AS.12.2D) ; conversation 0808080808 PRE_LLM_BLOCKED:HIGH (probleme PRE-EXISTANT hors scope) | inchange runtime |
| AISuggestionSlideOver | OK (AS.12.2C-1/2/3 preserve) | inchange |
| /ai/evaluate auto-call avoid PH25.9 | OK (AS.12.2C-3 preserve) | inchange |
| /ai/execute protection | actif (AS.12.2C-4) | objectif phase |
| AIDecisionPanel (non monte) | inchange (orphelin, hors scope) | runtime sans caller actif |
| /ai/rules (admin) | inchange | scope futur AS.12.2C-5 |

---

## 12. No-mutation proof (DEV phase)

| Item | Statut |
|---|---|
| Aucun patch source PROD | OK |
| Aucun build / push / deploy PROD | OK |
| Aucun POST positif vers /ai/execute | OK (0 calls verifies DEV+PROD) |
| Aucune execution action downstream | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions | OK |
| Aucun debit wallet | OK |
| Aucune mutation DB de notre fait | OK (`ai_action_log` execute_count 0->0) |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Bastion install-v3 only | OK |
| GitOps strict (kubectl apply -f only) | OK |
| KEY-301 statut Done NON applique | OK |
| PROD strictement read-only | OK |

---

## 13. Rollback plan (PRET, NON EXECUTE)

```
cd /opt/keybuzz/keybuzz-infra
git revert 6580abb --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.183-ai-evaluate-tenantguard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml   # -> v3.5.194-ai-evaluate-bff-dev
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client --timeout=300s
```

Triggers rollback (non utilises ici) :
- Spike 401/403 sur tenant authentifie sur surface preserve.
- Spike 5xx API DEV.
- Spike JWT_SESSION_ERROR Client DEV.
- Regression Brouillon IA cross-tenant authentifie (non observe : pattern KO present aussi PROD pre-patch).

---

## 14. Gap produit separe (hors scope KEY-301)

| # | Gap | Severite | Description | Plan |
|---|---|---|---|---|
| GP1 | Brouillon IA auto bloque pour certaines conversations sans alternative UX | Medium | Certains messages clients (agressifs, demande remboursement explicite, commande non liee, contexte 17Track absent, score risque eleve) declenchent les garde-fous `PRE_LLM_BLOCKED:HIGH` ou `ESCALATION_DRAFT:0.75` cote autopilot worker -> aucun draft genere -> `/autopilot/draft` retourne `hasDraft=false` -> Brouillon IA UX silencieux. L utilisateur ne voit pas de message explicatif "Cette conversation necessite un traitement humain car risque eleve detecte". Comportement preserve mais UX silencieuse. Probleme PRE-EXISTANT confirme en PROD pre AS.12.2C-4 (idem en DEV). | Ticket produit Linear **KEY-312** cree (https://linear.app/keybuzz/issue/KEY-312/brouillon-ia-expliciter-ou-traiter-les-conversations-bloquees-par-les). Hors scope KEY-301. Decision produit a prendre parmi : (a) maintenir blocage silencieux (UX actuel) ; (b) afficher message UX explicite "Risque eleve detecte, traitement humain recommande" ; (c) produire un brouillon prudent generic ("Bonjour, votre message a bien ete recu, un conseiller vous repondra...") au lieu de bloquer. |

---

## 15. Linear text prepared (disclosure-controlled)

### 15.1 KEY-301 commentaire cible

```
## AS.12.2C-4 hardening /ai/execute DEV -- GO READY

Implementation delivered following the AS.12.2C-4 design audit :
- API tenantGuard.ts : POST /ai/execute added to PROTECTED_ROUTES.
- Client : new BFF `app/api/ai/execute/route.ts` (NextAuth + X-User-Email + X-Tenant-Id injection).
- Client ai.service.ts : `executeAI` rewritten to call relative `/api/ai/execute`.

Runtime DEV :
- API : v3.5.183 -> v3.5.184-ai-execute-tenantguard-dev (digest sha256:50ebb39228ea6b3b14c2615eaa987581b16467e2e20cb4852f3f3c1a8b22ffff, OCI revision d7f2a8fd120c73d1b532940263f94ed2de2e5dc7).
- Client : v3.5.194 -> v3.5.195-ai-execute-bff-dev (digest sha256:10ab15de30c137c268c6447c9d7a0d4db2aa754956017bbf63a027121ae35294, OCI revision 14a4ea66d4b8dc67093b9061488f7307669b791c).
- Manifest commit 6580abb, GitOps strict, spec=last-applied=runtime imageID=GHCR digest.
- OCI labels KEY-308 complets, KEY-302 sentinel absent, bundle DEV `api-dev.keybuzz.io` only.

Validation DEV :
- 10/10 preserve protections at 401 unauthenticated.
- 0 5xx API DEV 5min, 0 JWT_SESSION_ERROR Client DEV 5min.
- DB ai_action_log execute count remains 0 (no positive POST issued).
- PROD strictly unchanged (DEV-only manifests touched).

QA Ludovic browser DEV (https://client-dev.keybuzz.io) : conversation 07090405006 Brouillon IA OK ; conversation 0808080808 Brouillon IA KO (DEV AND PROD identically). Read-only diagnosis showed `/autopilot/draft` answers 200 on all sampled requests (tenantGuard non-blocking) and `/ai/execute` = 0 calls (AIDecisionPanel non-mounted, design audit confirmed). Affected conversations correspond to `ai_action_log` entries with status=skipped and blocked_reason `PRE_LLM_BLOCKED:HIGH` or `ESCALATION_DRAFT:0.75`. Pre-existing AI guard-rail behavior visible on PROD pre-patch -- not introduced by AS.12.2C-4. Classified out-of-scope KEY-301.

Verdict : **GO AI EXECUTE TENANTGUARD DEV READY**. No rollback triggered.

Note product gap GP1 (separate from KEY-301) : some incoming messages trigger PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT silently -> UX silent failure. Tracked as Linear KEY-312 (https://linear.app/keybuzz/issue/KEY-312/brouillon-ia-expliciter-ou-traiter-les-conversations-bloquees-par-les). Product decision pending : keep silent block / show explicit message / generate prudent fallback draft.

KEY-301 stays Open. AS.12.2C-4-PROD eligible after Ludovic GO. Remaining KEY-301 sub-phase : AS.12.2C-5 `/ai/rules` (admin CRUD).

Disclosure controle : no PoC, no exploit details, no draftText, no PII.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 16. Compliance DEV

| Verification | Statut |
|---|---|
| Bastion install-v3 only / 46.62.171.61 | OK |
| Branches imposees respectees (api ph147.4 / client ph148 / infra main) | OK |
| Commit+push AVANT build (PH152) | OK |
| Build from-git fresh clone (no contamination) | OK |
| KEY-309 tags immuables / pre-push manifest unknown | OK |
| KEY-308 OCI labels complets via scripts patches AS.12.2C-3.1 | OK |
| KEY-302 sentinel Client bundle absent | OK |
| docker push GHCR + digest captured | OK |
| GitOps strict (kubectl apply -f only, no set/patch/edit) | OK |
| Apply order API then Client | OK |
| spec = last-applied = pod imageID = digest pushe | OK API + Client |
| Aucun patch source PROD | OK |
| Aucune mutation DB | OK |
| Aucun POST positif vers /ai/execute | OK (0 calls DEV+PROD) |
| Aucune generation LLM | OK |
| Aucune consommation KBActions / debit wallet | OK |
| Aucun draftText publie / aucune PII | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |
| Rollback documente et pret (non execute) | OK |
| PROD strictement read-only | OK |
| QA Ludovic confirme + diagnostic classification hors scope | OK |

---

## 17. Gaps restants

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | AS.12.2C-4-PROD promotion (coordinated API+Client) reste a livrer apres GO Ludovic | High | Phase suivante |
| G2 | AS.12.2C-5 `/ai/rules` (admin CRUD) reste a livrer | Medium | Phase suivante apres AS.12.2C-4-PROD |
| G3 | Plan gating manquant sur `/ai/execute` (requirePlan non applique) | Medium | Ticket housekeeping separe ; hors scope KEY-301 |
| G4 | AIDecisionPanel non monte (composant orphelin) | Low | A documenter dans BUILD_NOTES ; patch AS.12.2C-4 prepare le terrain pour future re-integration |
| GP1 | Brouillon IA auto silent failure sur conversations PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT:0.75 | Medium | Ticket produit Linear KEY-312 (https://linear.app/keybuzz/issue/KEY-312/brouillon-ia-expliciter-ou-traiter-les-conversations-bloquees-par-les) -- decision parmi 3 options |
| G5 | Backlog 30 jeux de commentaires Linear KEY-* accumules | Low | Resoudre methode token hors-chat |

---

## 18. Phrase cible finale

AS.12.2C-4 implementation DEV livre : 3 patches sources (API `src/plugins/tenantGuard.ts` +19/-3 + Client `src/services/ai.service.ts` +13/-1 + Client nouveau `app/api/ai/execute/route.ts` 66 lignes) ; commits sources `d7f2a8fd` (api ph147.4) + `14a4ea6` (client ph148) push origin 0-0 ; build DEV API + Client from-git via scripts patches AS.12.2C-3.1 avec OCI labels KEY-308 complets (revision SHA complet + created ISO UTC + version tag) ; bundle Client DEV KEY-302 sentinel absent + api-dev.keybuzz.io x2 + api.keybuzz.io x0 + BFF route compile + executeAI tree-shaked coherent design audit ; verify-image-clean 17 PASS / 0 FAIL ; docker push GHCR API digest `sha256:50ebb39228ea6b3b14c2615eaa987581b16467e2e20cb4852f3f3c1a8b22ffff` + Client digest `sha256:10ab15de30c137c268c6447c9d7a0d4db2aa754956017bbf63a027121ae35294` (KEY-309 immuables) ; manifest infra commit `6580abb` push origin main 0-0 ; 2 kubectl apply -f DEV sequentiels + rollouts successful ; spec = last-applied = pod imageID = digest pushe pour API + Client ; preserve 10/10 (POST /ai/execute NEW 401 + 9 preserve POST /ai/evaluate POST /ai/assist POST /ai/guard/check GET /messages/conversations GET /tenants GET /notifications GET /autopilot/draft GET /ai/settings GET /ai/wallet/status tous 401 no-auth avec payloads valides) ; 0 5xx API DEV 5min + 0 JWT spike Client DEV 5min ; DB `ai_action_log` execute_count 0 -> 0 (aucun POST positif emis) ; URL DEV correcte `https://client-dev.keybuzz.io` (notee) ; QA Ludovic DEV : conversation 07090405006 Brouillon IA OK ; conversations 0808080808 Brouillon IA KO en DEV ET PROD (pattern identique pre-patch) ; diagnostic read-only confirme `/autopilot/draft` 200/200 + `/ai/execute` 0 calls + entries `ai_action_log` `autopilot_reply` PRE_LLM_BLOCKED:HIGH + `autopilot_escalate` ESCALATION_DRAFT:0.75 -> garde-fous metier IA legitimes, probleme PRE-EXISTANT, **patch AS.12.2C-4 NON IMPLIQUE** ; gap produit separe GP1 documente (UX silencieuse a decider) ; PROD strictement read-only et inchange ; KEY-301 reste Open epic ; AS.12.2C-4-PROD eligible apres GO Ludovic ; AS.12.2C-5 + gaps G1-G5 + GP1 restent a livrer ; verdict AS.12.2C-4 DEV GO AI EXECUTE TENANTGUARD DEV READY.

STOP
