# PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-4-PROD -- promotion PROD coordonnee API + Client (hardening /ai/execute)
> Environnement : PROD ; DEV inchange (acquis AS.12.2C-4 DEV)

---

## 1. VERDICT

GO AI EXECUTE TENANTGUARD PROD READY

Promotion PROD coordonnee API + Client effectuee :
- API : `v3.5.183-ai-evaluate-tenantguard-prod` -> `v3.5.184-ai-execute-tenantguard-prod` (digest GHCR `sha256:6946dcbac9d90c1752070dea41be11219085599760315139a3e1b0da7aa51e56`, OCI revision `d7f2a8fd120c73d1b532940263f94ed2de2e5dc7`).
- Client : `v3.5.194-ai-evaluate-bff-prod` -> `v3.5.195-ai-execute-bff-prod` (digest GHCR `sha256:9972ba7e541725367df78c3e0e18de70292d2bd9ab40fadb255ff2c4b999ceb3`, OCI revision `14a4ea66d4b8dc67093b9061488f7307669b791c`).
- Manifest infra commit `4321375` push origin/main 0-0.
- GitOps strict : 2 kubectl apply -f PROD, rollouts successful, spec = last-applied = runtime imageID = digest pushe.

Validation negative 10/10 : `/ai/execute` NEW + 9 preserve (`/ai/evaluate`, `/ai/assist`, `/ai/guard/check`, `/messages/conversations`, `/tenants`, `/notifications`, `/autopilot/draft`, `/ai/settings`, `/ai/wallet/status`) tous 401 unauthenticated avec payloads valides. 0 5xx API PROD 5min. 0 JWT_SESSION_ERROR Client PROD 5min. DB `ai_action_log` execute_count = 0 pre/post (aucun POST positif emis).

**Ingress + NEXTAUTH_URL verifies (correction URL operationnelle)** :
- DEV ingress = `client-dev.keybuzz.io` ; Client DEV `NEXTAUTH_URL=https://client-dev.keybuzz.io` ; QA Ludovic DEV faite sur cette URL.
- PROD ingress = `client.keybuzz.io` ; Client PROD `NEXTAUTH_URL=https://client.keybuzz.io` ; QA Ludovic PROD faite sur cette URL.
- Les URLs `app.keybuzz.io` / `app-dev.keybuzz.io` ne sont **pas** les ingress Client KeyBuzz et ne doivent plus etre referencees dans les rapports.

QA Ludovic navigateur :
- Conversation `commande 07090405006` : Brouillon IA OK DEV ET PROD.
- Conversation `Commande 0808080808` : Brouillon IA KO DEV ET PROD (pattern PRE-EXISTANT, garde-fous metier `PRE_LLM_BLOCKED:HIGH` / `ESCALATION_DRAFT:0.75`).

Gap produit **GP1** maintenu et explicitement documente : certains messages declenchent les garde-fous IA et ne produisent pas de draft -> Brouillon IA UX silencieux. **Pre-existant, hors scope AS.12.2C-4 et hors scope KEY-301**. Ticket produit Linear **KEY-312** cree (https://linear.app/keybuzz/issue/KEY-312/brouillon-ia-expliciter-ou-traiter-les-conversations-bloquees-par-les). Voir section 15.

11 autres services PROD strictement inchanges (outbound-worker, admin-v2, backend, amazon-items-worker, amazon-orders-worker, backfill-scheduler, studio, studio-api, website, seller-api, seller-client). Aucune mutation source `keybuzz-api` ni `keybuzz-client` durant cette phase PROD (sources committees pendant AS.12.2C-4-DEV, identiques HEAD).

KEY-301 reste Open epic. AS.12.2C-4 ferme en PROD. Sous-phase restante : AS.12.2C-5 `/ai/rules` (admin CRUD).

---

## 2. Scope

Inclus :
- Build PROD coordonne API + Client (via scripts patches AS.12.2C-3.1, OCI labels KEY-308 complets).
- Push GHCR (KEY-309 tags immuables).
- Commit + push manifests infra PROD (2 lignes, 2 fichiers).
- 2 kubectl apply -f PROD + rollouts.
- Validation negative 10/10 + preserve + logs + DB.
- QA Ludovic navigateur PROD (`https://client.keybuzz.io`).
- Diagnostic read-only pour conversation `0808080808` (pattern PRE-EXISTANT).
- Rapport docs-only ASCII strict + commit + push.

Hors scope :
- Aucune mutation source.
- Aucune mutation DB de notre fait.
- Aucun POST positif vers `/ai/execute`.
- Aucune execution action downstream.
- Aucune generation LLM.
- Aucune consommation KBActions / debit wallet.
- Aucun draftText publie.
- Aucune PII publiee.
- AS.12.2C-5 `/ai/rules`.
- Resolution gap produit GP1 (suivi sur Linear KEY-312).
- Plan gating `/ai/execute` (gap operationnel separe).

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-DESIGN-AUDIT-01.md` (design audit).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-HARDENING-DEV-01.md` (DEV implementation).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-PROD-01.md` (precedent PROD).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3.1-BUILD-SCRIPTS-OCI-ARGS-FIX-01.md` (scripts patches).

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| keybuzz-api HEAD / branche / sync | d7f2a8fd / ph147.4/source-of-truth / 0-0 | OK |
| keybuzz-client HEAD / branche / sync | 14a4ea66 / ph148/onboarding-activation-replay / 0-0 | OK |
| keybuzz-infra HEAD / sync (pre-PROD) | ac2717a (rapport DEV AS.12.2C-4) / 0-0 / 0 dirty | OK |
| `assert-git-committed.sh` global | api + client propres -- BUILD AUTORISE | OK |
| Runtime DEV API (post AS.12.2C-4 DEV) | v3.5.184-ai-execute-tenantguard-dev | OK baseline |
| Runtime DEV Client (post AS.12.2C-4 DEV) | v3.5.195-ai-execute-bff-dev | OK baseline |
| Runtime PROD API (a promouvoir) | v3.5.183-ai-evaluate-tenantguard-prod | OK baseline |
| Runtime PROD Client (a promouvoir) | v3.5.194-ai-evaluate-bff-prod | OK baseline |
| KEY-309 tag `v3.5.184-ai-execute-tenantguard-prod` | GHCR manifest unknown | OK libre |
| KEY-309 tag `v3.5.195-ai-execute-bff-prod` | GHCR manifest unknown | OK libre |
| DB baseline PROD `ai_action_log` 24h | total=17, execute_count=0 | OK no execute in PROD |
| Ingress Client DEV | `client-dev.keybuzz.io` | OK |
| Ingress Client PROD | `client.keybuzz.io` | OK |
| Client DEV NEXTAUTH_URL | `https://client-dev.keybuzz.io` | OK aligne |
| Client PROD NEXTAUTH_URL | `https://client.keybuzz.io` | OK aligne |

Note operationnelle : la documentation anterieure mentionnant `app-dev.keybuzz.io` ou `app.keybuzz.io` est incorrecte. Les ingress Client KeyBuzz sont `client-dev.keybuzz.io` (DEV) et `client.keybuzz.io` (PROD), conformes a NEXTAUTH_URL des deployments.

---

## 5. Build PROD (scripts patches AS.12.2C-3.1)

### 5.1 API PROD

```
bash scripts/build-api-from-git.sh prod v3.5.184-ai-execute-tenantguard-prod ph147.4/source-of-truth
```

Build OK : `Successfully tagged ghcr.io/keybuzzio/keybuzz-api:v3.5.184-ai-execute-tenantguard-prod`. Git SHA `d7f2a8f`.

OCI labels conformes KEY-308 :

| Label | Valeur |
|---|---|
| revision | `d7f2a8fd120c73d1b532940263f94ed2de2e5dc7` (= HEAD post AS.12.2C-4-DEV) |
| created | `2026-05-13T10:20:23Z` (ISO 8601 UTC) |
| version | `v3.5.184-ai-execute-tenantguard-prod` |
| source | `https://github.com/keybuzzio/keybuzz-api` |
| title | `keybuzz-api` |

Image Id local : `sha256:53fafab4e7c3e3f287af1ea507627d1c8eb8be1fb2589a078ca2bb08cec5836d`.

### 5.2 Client PROD

```
bash scripts/build-from-git.sh prod v3.5.195-ai-execute-bff-prod ph148/onboarding-activation-replay
```

Build OK avec build-args positionnes par le script (post fix AS.12.2C-3.1) :
- `NEXT_PUBLIC_APP_ENV=production`
- `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
- `IMAGE_REVISION` / `IMAGE_CREATED` / `IMAGE_VERSION` remplis.

Git SHA `14a4ea6`. Image Id local : `sha256:11573080f0d404c015d17c6b5ffc84c259046d93423747a738887a8664c12a09`.

OCI labels :

| Label | Valeur |
|---|---|
| revision | `14a4ea66d4b8dc67093b9061488f7307669b791c` (= HEAD post AS.12.2C-4-DEV) |
| created | `2026-05-13T10:20:19Z` (ISO 8601 UTC) |
| version | `v3.5.195-ai-execute-bff-prod` |
| source | `https://github.com/keybuzzio/keybuzz-client` |
| title | `keybuzz-client` |

### 5.3 verify-image-clean.sh Client PROD

```
=== RESULTATS: 17 PASS / 0 FAIL / 0 WARN ===
VERDICT: PASS -- Image valide
```

### 5.4 Verifications bundle Client PROD

| Check | Count | Verdict |
|---|---|---|
| sentinel `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | PASS KEY-302 |
| `api.keybuzz.io` (PROD URL attendue) | 2 occurrences | PASS bundle PROD |
| `api-dev.keybuzz.io` (must be 0) | 0 | PASS pas de contamination DEV |
| `Brouillon IA` | 2 occurrences | PASS UX preserve |
| `Valider et envoyer` | 1 occurrence | PASS UX preserve |
| BFF route `app/api/ai/execute/route.js` compile | 6558 bytes dans `.next/server/app/api/ai/execute/` | PASS |

---

## 6. Push GHCR

| Image | Tag | Manifest digest | Config digest |
|---|---|---|---|
| keybuzz-api | v3.5.184-ai-execute-tenantguard-prod | `sha256:6946dcbac9d90c1752070dea41be11219085599760315139a3e1b0da7aa51e56` (size 2416) | local Id `sha256:53fafab4e7c3...` |
| keybuzz-client | v3.5.195-ai-execute-bff-prod | `sha256:9972ba7e541725367df78c3e0e18de70292d2bd9ab40fadb255ff2c4b999ceb3` (size 2631) | local Id `sha256:11573080f0d4...` |

KEY-309 tags immuables. KEY-308 OCI labels conserves apres push.

---

## 7. GitOps PROD apply

### 7.1 Commit manifests infra

Commit `4321375 deploy(prod): promote AS.12.2C-4 API+Client to PROD (KEY-301)` push origin/main 0-0 :
- `k8s/keybuzz-api-prod/deployment.yaml` : 1 ligne image+commentaire (v3.5.183 -> v3.5.184).
- `k8s/keybuzz-client-prod/deployment.yaml` : 1 ligne image+commentaire (v3.5.194 -> v3.5.195).

### 7.2 Apply API PROD

```
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
deployment.apps/keybuzz-api configured

kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
deployment "keybuzz-api" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.184-ai-execute-tenantguard-prod | OK |
| pod imageID nouveau | ghcr.io/keybuzzio/keybuzz-api@sha256:6946dcbac9d9... | OK MATCH digest pushe |
| pod imageID ancien (terminating) | ghcr.io/keybuzzio/keybuzz-api@sha256:fe1c166d869d... (v3.5.183) | OK rollout normal |

### 7.3 Apply Client PROD

```
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
deployment.apps/keybuzz-client configured

kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
deployment "keybuzz-client" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | ghcr.io/keybuzzio/keybuzz-client:v3.5.195-ai-execute-bff-prod | OK |
| pod imageID nouveau | ghcr.io/keybuzzio/keybuzz-client@sha256:9972ba7e5417... | OK MATCH digest pushe |
| pod imageID ancien (terminating) | ghcr.io/keybuzzio/keybuzz-client@sha256:cf346e9bbc48... (v3.5.194) | OK rollout normal |

---

## 8. Validation PROD post-apply

### 8.1 /health API PROD

```
GET https://api.keybuzz.io/health -> 200
```

### 8.2 Preserve checks 10/10 PASS (payloads valides + no-auth)

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

Aucun POST positif emis. Bodies de test contiennent uniquement des UUIDs fictifs `00000000-...` et `11111111-...`.

### 8.3 Logs

| Source | Filtre | Count |
|---|---|---|
| API PROD `statusCode 5xx / level=50` | 5min | 0 |
| Client PROD `JWT_SESSION_ERROR` | 5min | 0 |

### 8.4 DB no-mutation

| Mesure | Pre-deploy 24h | Post-deploy 1h |
|---|---|---|
| `ai_action_log` total | 17 | 0 (1h window) |
| `ai_action_log` `action_type='execute'` | 0 | 0 |

Aucun POST positif emis. Aucune mutation execute. Aucun debit wallet / KBActions de notre fait.

---

## 9. PROD unchanged proof (11 autres services)

| Namespace / Deploy | Image (inchangee pre + post) |
|---|---|
| keybuzz-api-prod / keybuzz-api | v3.5.184-ai-execute-tenantguard-prod (PROMU) |
| keybuzz-client-prod / keybuzz-client | v3.5.195-ai-execute-bff-prod (PROMU) |
| keybuzz-api-prod / keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-admin-v2-prod / keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |
| keybuzz-backend-prod / amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod / amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod / backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-backend-prod / keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-studio-prod / keybuzz-studio | v0.8.0-prod |
| keybuzz-studio-api-prod / keybuzz-studio-api | v0.8.1-prod |
| keybuzz-website-prod / keybuzz-website | v0.6.12-linkedin-insight-seo-prod |
| keybuzz-seller-dev / seller-api | v2.0.5-ph-prod-ftp-02 (hors KEY-301) |
| keybuzz-seller-dev / seller-client | v2.0.7-ph-prod-ftp-02b (hors KEY-301) |

13 services PROD inventories ; 2 promus (api + client) ; 11 autres strictement inchanges.

---

## 10. QA Ludovic navigateur PROD + diagnostic

### 10.1 URLs operationnelles confirmees

| Environnement | Ingress Client | NEXTAUTH_URL | Status |
|---|---|---|---|
| DEV | `client-dev.keybuzz.io` | `https://client-dev.keybuzz.io` | OK aligne |
| PROD | `client.keybuzz.io` | `https://client.keybuzz.io` | OK aligne |

QA Ludovic faite sur les bonnes URLs : DEV `https://client-dev.keybuzz.io` et PROD `https://client.keybuzz.io`.

### 10.2 Resultat Ludovic

| Conversation client | DEV (`client-dev.keybuzz.io`) | PROD (`client.keybuzz.io`) |
|---|---|---|
| `commande 07090405006` | Brouillon IA OK | Brouillon IA OK |
| `Commande 0808080808` | Brouillon IA KO | Brouillon IA KO |

Pattern KO identique en DEV et en PROD -> probleme **PRE-EXISTANT** confirme une fois encore, non introduit par AS.12.2C-4.

### 10.3 Diagnostic read-only

Diagnostic deja realise en AS.12.2C-4 DEV (rapport precedent) :
- `/autopilot/draft` 200 sur toutes requetes sampling DEV + PROD (tenantGuard non-bloquant pour tenant authentifie).
- `/ai/execute` 0 calls DEV + PROD (AIDecisionPanel non monte, design audit confirme).
- Entries `ai_action_log` correspondantes : `autopilot_reply` skipped `PRE_LLM_BLOCKED:HIGH` (confidence 0.00) ou `autopilot_escalate` skipped `ESCALATION_DRAFT:0.75`.
- Aucune entry `action_type='execute'` derniere 2h ni DEV ni PROD.

Patch AS.12.2C-4 **non implique** dans le KO Brouillon IA. Probleme classe **PRE-EXISTANT** -> gap produit separe GP1 (section 15).

---

## 11. AI feature parity / anti-regression PROD

| Surface | Statut PROD post AS.12.2C-4 | Justification |
|---|---|---|
| Tenant switcher | OK | inchange |
| Inbox liste/detail/reply/status/assign/sav-status | OK (KEY-304 preserve) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B preserve) | inchange |
| AIModeSwitch | OK (AS.12.2D preserve) | inchange |
| Brouillon IA auto + wallet balance | OK pour conversations sans garde-fou (preserve AS.12.2B+AS.12.2D) ; conversations PRE_LLM_BLOCKED:HIGH silent failure documentee GP1 | comportement existant DEV + PROD pre-patch |
| AISuggestionSlideOver | OK (AS.12.2C-1/2/3 preserve) | inchange |
| /ai/evaluate auto-call avoid PH25.9 | OK (AS.12.2C-3 preserve) | inchange |
| /ai/execute protection | actif (AS.12.2C-4-PROD) | objectif phase |
| AIDecisionPanel (non monte) | inchange (orphelin) | runtime sans caller actif ; BFF + tenantGuard prets si future re-integration |
| /ai/rules (admin) | inchange | scope futur AS.12.2C-5 |

---

## 12. No-mutation proof (PROD phase)

| Item | Statut |
|---|---|
| Aucune mutation source PROD | OK |
| Aucun POST positif vers /ai/execute | OK (0 calls verifies) |
| Aucune execution action downstream | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions | OK |
| Aucun debit wallet | OK |
| Aucune mutation DB de notre fait | OK (execute_count 0 -> 0) |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Bastion install-v3 only | OK |
| Build from-git fresh clone (no contamination) | OK |
| KEY-309 tags immuables / pre-push manifest unknown | OK |
| KEY-308 OCI labels complets via scripts patches | OK |
| KEY-302 sentinel Client bundle absent | OK |
| GitOps strict (kubectl apply -f only, no set/patch/edit) | OK |
| Apply order API then Client | OK |
| spec = last-applied = pod imageID = digest pushe | OK API + Client |
| 11 autres services PROD strictement inchanges | OK |

---

## 13. Rollback plan (PRET, NON EXECUTE)

```
cd /opt/keybuzz/keybuzz-infra
git revert 4321375 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.183-ai-evaluate-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml   # -> v3.5.194-ai-evaluate-bff-prod
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
```

Triggers rollback (non utilises ici) :
- Spike 401/403 sur tenant authentifie sur surface preserve.
- Spike 5xx API PROD.
- Spike JWT_SESSION_ERROR Client PROD.
- Regression UX confirmee globalement.

Triggers NON rollback (cas observes ici) :
- `/autopilot/draft` 200 sur toutes requetes -> tenantGuard non-bloquant.
- Brouillon IA absent uniquement sur conversations avec `PRE_LLM_BLOCKED:HIGH` ou `ESCALATION_DRAFT:*` (comportement garde-fou metier PRE-EXISTANT).

---

## 14. Gaps restants

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | AS.12.2C-5 `/ai/rules` (admin CRUD) reste a livrer | Medium | Phase suivante apres validation Ludovic |
| G2 | Plan gating manquant sur `/ai/execute` (requirePlan non applique) | Medium | Ticket housekeeping separe ; hors scope KEY-301 |
| G3 | AIDecisionPanel non monte (composant orphelin) | Low | A documenter dans BUILD_NOTES ; ce patch prepare le terrain pour future re-integration |
| GP1 | Brouillon IA auto silent failure (PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT) | Medium | Linear KEY-312 (https://linear.app/keybuzz/issue/KEY-312/brouillon-ia-expliciter-ou-traiter-les-conversations-bloquees-par-les) ; voir section 15 |
| G4 | Backlog 31 jeux de commentaires Linear KEY-* accumules | Low | Resoudre methode token hors-chat |

---

## 15. Gap produit GP1 (hors scope KEY-301)

### 15.1 Description

Certains messages clients (notamment `Commande 0808080808`) ne declenchent **pas** le Brouillon IA auto en DEV ni en PROD. Cause technique confirmee par diagnostic :
- L autopilot worker tourne et produit une entry `ai_action_log` ;
- Mais la generation LLM est interceptee AVANT par les garde-fous metier :
  - `PRE_LLM_BLOCKED:HIGH` (autopilot_reply skipped) : score risque eleve, contenu agressif/remboursement/commande non liee, mots-bannis ;
  - `ESCALATION_DRAFT:0.75` (autopilot_escalate skipped) : escalation score >= 0.75 declenche autopilot_escalate qui ne genere pas de draft.
- Aucun draft genere -> `/autopilot/draft` retourne `hasDraft=false` (status 200) -> AISuggestionSlideOver autoOpen ne se declenche pas.

Du point de vue utilisateur final : Brouillon IA UX silencieux. L utilisateur ne voit pas de message explicatif et peut interpreter comme un bug.

Probleme PRE-EXISTANT, confirme par snapshot `ai_action_log` DEV + PROD pre-patch AS.12.2C-4. **Hors scope KEY-301 / tenantGuard.**

### 15.2 Decision produit a prendre

Trois options :
- **(a) Maintenir blocage silencieux** (status quo) : aucun message UX, pas de draft.
- **(b) Afficher message UX explicite** : "Cette conversation necessite un traitement humain car risque eleve detecte. Aucun brouillon IA disponible."
- **(c) Generer brouillon prudent generic** : "Bonjour, votre message a bien ete recu, un conseiller vous repondra dans les meilleurs delais." Drafte automatiquement, pas de risque LLM puisque pas d invocation LLM.

### 15.3 Ticket produit propose

| Champ | Valeur |
|---|---|
| Titre | UX silent failure pour conversations bloquees par PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT (Brouillon IA invisible) |
| Description | Voir section 15.1 ci-dessus. |
| Severite | Medium (impact UX continu, pas de regression metier). |
| Actions a decider | Voir 3 options section 15.2. |
| Dependances | Necessite alignement produit + design. |
| Hors scope | KEY-301 (security tenantGuard). |

Ticket cree post-promotion : Linear **KEY-312** (https://linear.app/keybuzz/issue/KEY-312/brouillon-ia-expliciter-ou-traiter-les-conversations-bloquees-par-les). Decision produit a arbitrer parmi les 3 options ci-dessus.

---

## 16. Linear text prepared (disclosure-controlled)

### 16.1 KEY-301 commentaire cible

```
## AS.12.2C-4-PROD coordinated promotion GO READY

Hardening of /ai/execute extended to PROD after DEV validation (AS.12.2C-4 DEV report).

Runtime PROD :
- API : v3.5.183 -> v3.5.184-ai-execute-tenantguard-prod (digest sha256:6946dcbac9d90c1752070dea41be11219085599760315139a3e1b0da7aa51e56, OCI revision d7f2a8fd120c73d1b532940263f94ed2de2e5dc7).
- Client : v3.5.194 -> v3.5.195-ai-execute-bff-prod (digest sha256:9972ba7e541725367df78c3e0e18de70292d2bd9ab40fadb255ff2c4b999ceb3, OCI revision 14a4ea66d4b8dc67093b9061488f7307669b791c).
- GitOps strict, manifest commit 4321375, spec=last-applied=runtime imageID=GHCR digest.
- OCI labels KEY-308 complets, KEY-302 sentinel absent, bundle PROD api.keybuzz.io only.

Validation PROD :
- 10/10 preserve protections at 401 unauthenticated (messages, tenants, notifications, autopilot/draft, ai settings, wallet, assist, guard/check, evaluate, execute).
- 0 5xx API PROD 5min, 0 JWT_SESSION_ERROR Client PROD 5min.
- DB ai_action_log execute_count remains 0 (no positive POST issued).
- 11 other PROD services strictly unchanged.

QA Ludovic browser PROD (https://client.keybuzz.io) : conversation 07090405006 Brouillon IA OK ; conversation 0808080808 Brouillon IA KO (DEV AND PROD identically, pre-existing). Diagnosis confirms `/autopilot/draft` 200, `/ai/execute` 0 calls, ai_action_log entries with blocked_reason `PRE_LLM_BLOCKED:HIGH` or `ESCALATION_DRAFT:0.75` -- pre-existing AI guard-rail behavior, not introduced by AS.12.2C-4. Classified out-of-scope KEY-301 (gap product GP1).

Ingress + NEXTAUTH_URL alignment verified : DEV ingress = client-dev.keybuzz.io / PROD ingress = client.keybuzz.io. Previous mentions of `app.keybuzz.io` / `app-dev.keybuzz.io` in earlier docs were incorrect.

Verdict : **GO AI EXECUTE TENANTGUARD PROD READY**. No rollback triggered.

Remaining KEY-301 sub-phase : AS.12.2C-5 `/ai/rules` (admin CRUD).

Separate product gap GP1 (silent failure of Brouillon IA on PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT) now tracked as Linear **KEY-312** (https://linear.app/keybuzz/issue/KEY-312/brouillon-ia-expliciter-ou-traiter-les-conversations-bloquees-par-les), priority High, related to KEY-301 (not a blocker). Three product options to arbitrate : status quo silent / explicit UX message / prudent fallback draft.

KEY-301 stays Open. NOT marked Done.

Disclosure controle : no PoC, no exploit details, no draftText, no PII.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 17. Compliance PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only / 46.62.171.61 | OK |
| Build from-git fresh clones + SHA MATCH | OK |
| KEY-309 tags immuables (manifest unknown pre-push) | OK |
| KEY-308 OCI labels complets sur images pushees | OK |
| KEY-302 sentinel Client bundle absent | OK |
| docker push GHCR + digest captured | OK |
| GitOps strict (kubectl apply -f only) | OK |
| Apply ordre API puis Client | OK |
| spec = last-applied = pod imageID = digest pushe | OK API + Client |
| Aucune mutation source PROD | OK |
| Aucune mutation DB | OK |
| Aucun POST positif vers /ai/execute | OK (0 calls PROD) |
| Aucune generation IA / KBActions / debit wallet | OK |
| Aucun draftText publie / aucune PII | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |
| Rollback documente et pret (non execute) | OK |
| Gap produit GP1 explicite (non reclasse comme regression AS.12.2C-4) | OK |
| Ingress + NEXTAUTH_URL Client DEV/PROD documente | OK |
| QA Ludovic confirme sur bonnes URLs (client-dev.keybuzz.io / client.keybuzz.io) | OK |

---

## 18. Phrase cible finale

AS.12.2C-4-PROD livre : promotion PROD coordonnee API v3.5.183 -> v3.5.184-ai-execute-tenantguard-prod (digest GHCR `sha256:6946dcbac9d90c1752070dea41be11219085599760315139a3e1b0da7aa51e56`, OCI revision `d7f2a8fd120c73d1b532940263f94ed2de2e5dc7`, created `2026-05-13T10:20:23Z`) et Client v3.5.194 -> v3.5.195-ai-execute-bff-prod (digest GHCR `sha256:9972ba7e541725367df78c3e0e18de70292d2bd9ab40fadb255ff2c4b999ceb3`, OCI revision `14a4ea66d4b8dc67093b9061488f7307669b791c`, created `2026-05-13T10:20:19Z`) ; build PROD via scripts patches AS.12.2C-3.1 avec OCI labels KEY-308 complets ; bundle Client PROD verifie (sentinel x0, api.keybuzz.io x2, api-dev x0, Brouillon IA x2, Valider et envoyer x1, BFF route `app/api/ai/execute/route.js` compile, verify-image-clean 17 PASS / 0 FAIL / 0 WARN) ; manifest infra commit `4321375` push origin/main 0-0 ; 2 kubectl apply -f PROD sequentiels + rollouts successful ; spec = last-applied = pod imageID = digest pushe pour API + Client ; preserve 10/10 (POST /ai/execute NEW 401 + 9 preserve tous 401 no-auth avec payloads valides) ; 0 5xx API PROD 5min + 0 JWT spike Client PROD 5min ; DB `ai_action_log` execute_count 0 -> 0 (aucun POST positif emis) ; QA Ludovic navigateur PROD sur URL **correcte** `https://client.keybuzz.io` (DEV correspondant `https://client-dev.keybuzz.io`, ingress + NEXTAUTH_URL alignes) ; conversation 07090405006 Brouillon IA OK DEV+PROD ; conversation 0808080808 Brouillon IA KO DEV+PROD (pattern PRE-EXISTANT confirme), classe garde-fous metier `PRE_LLM_BLOCKED:HIGH` / `ESCALATION_DRAFT:0.75` -> gap produit GP1 documente section 15 (ticket Linear KEY-312 cree https://linear.app/keybuzz/issue/KEY-312/brouillon-ia-expliciter-ou-traiter-les-conversations-bloquees-par-les) ; patch AS.12.2C-4 **NON IMPLIQUE** (`/autopilot/draft` 200, `/ai/execute` 0 calls, AIDecisionPanel non monte confirme design audit) ; PROD strictement inchange 11 autres services ; aucune mutation source / build dirty / push tag reuse / mutation DB / generation IA / KBActions / wallet artificiel / draftText / PII ; KEY-301 reste Open epic ; AS.12.2C-4 ferme en PROD ; AS.12.2C-5 (`/ai/rules` admin CRUD) reste a livrer ; gaps G1-G4 + GP1 documentes ; verdict AS.12.2C-4-PROD GO AI EXECUTE TENANTGUARD PROD READY.

STOP
