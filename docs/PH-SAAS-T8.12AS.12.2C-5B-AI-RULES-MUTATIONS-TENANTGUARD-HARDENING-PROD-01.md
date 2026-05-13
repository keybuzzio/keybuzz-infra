# PH-SAAS-T8.12AS.12.2C-5B-AI-RULES-MUTATIONS-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-5B-PROD -- promotion PROD API-only (hardening MUTATIONS rules + playbooks)
> Environnement : PROD ; Client PROD strictement inchange

---

## 1. VERDICT

GO AI RULES MUTATIONS TENANTGUARD PROD READY

Promotion PROD API-only de la protection tenantGuard 5B :
- API : `v3.5.185-ai-rules-read-tenantguard-prod` -> `v3.5.186-ai-rules-mut-tenantguard-prod` (digest GHCR `sha256:637ee3d659ac0e65f10e8f0b9937924f42555b09e41c1805d5d2d238459a0e18`, OCI revision `05bb57cd6b0d312abf69c6e13608a71fbf2929f5`).
- Client PROD : **inchange** `v3.5.196-ai-rules-bff-prod` (aucun build / aucun apply Client cette phase).
- Manifest infra commit `8737fc3` push origin/main 0-0.
- 1 kubectl apply -f PROD API + rollout successful ; spec = last-applied = pod imageID = digest pushe.

Validation negative 21/21 PROD :
- **7 NEW MUTATIONS (AS.12.2C-5B)** : `POST /ai/rules`, `POST /playbooks`, `PUT /playbooks/:id`, `DELETE /playbooks/:id`, `PATCH /playbooks/:id/toggle`, `PATCH /playbooks/suggestions/:id/apply`, `PATCH /playbooks/suggestions/:id/dismiss` tous 401 unauthenticated.
- **4 preserve 5A READ** : `GET /ai/rules`, `GET /playbooks`, `GET /playbooks/:id`, `GET /playbooks/suggestions` tous 401 (matcher 5A intact apres 5B).
- **10 preserve** (KEY-304 + AS.12.1A/1B + AS.12.2B + AS.12.2C-1/2/3/4 + AS.12.2D) tous 401.

Logs PROD 5min : 0 5xx API + 0 JWT_SESSION_ERROR Client. **DB no-mutation STRICT** : `ai_rules`=390, `ai_rule_conditions`=104, `ai_rule_actions`=936, `playbook_suggestions`=6, counts strictement identiques pre + post deploy.

QA Ludovic navigateur PROD (`https://client.keybuzz.io`) : playbooks pages list/detail/suggestions consultes read-only **sans cliquer aucun bouton create/edit/delete/toggle/apply/dismiss** ; Inbox + Brouillon IA + tenant switcher + escalation OK. **Aucune regression visible**.

**12 autres services PROD strictement inchanges**. Client PROD a v3.5.196 verifie. KEY-301 reste Open epic (decision closeout separee par Ludovic).

---

## 2. Scope

Inclus :
- Build API PROD from-git via scripts patches AS.12.2C-3.1 (KEY-308 + KEY-309).
- 1 docker push GHCR (API uniquement).
- 1 commit + push manifest infra PROD (1 fichier API, 1 ligne).
- 1 kubectl apply -f PROD API + rollout.
- Validation negative 21/21 + logs + DB snapshot pre/post.
- QA Ludovic navigateur PROD read-only.
- Rapport docs-only ASCII strict + commit + push.

Hors scope strict :
- **Aucun build / push / deploy Client PROD** (Client reste v3.5.196).
- Aucune modification Admin v2 / Website / Backend / Workers.
- Aucun POST/PUT/PATCH/DELETE positif vers rules/playbooks.
- Aucune creation / modification / suppression / toggle / apply / dismiss.
- Aucune fixture / dry-run / fake data.
- Aucune mutation DB de notre fait.
- Aucun draftText / PII.
- Resolution GP1 (KEY-312 separe).
- Plan gating /ai/rules + /playbooks (gap operationnel separe).
- Closeout KEY-301 (decision Ludovic separee).

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md`.
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5-AI-RULES-TENANTGUARD-DESIGN-AUDIT-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-DEV-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-PROD-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5B-AI-RULES-MUTATIONS-TENANTGUARD-HARDENING-DEV-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3.1-BUILD-SCRIPTS-OCI-ARGS-FIX-01.md`.

---

## 4. Preflight

| Repo | Path | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 05bb57cd | 0-0 | 0 | OK |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | b726970 | 0-0 | 0 | OK (read-only) |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | c0d21dc (rapport 5B DEV) | 0-0 | 0 | OK |

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| Runtime DEV API (post 5B-DEV) | v3.5.186-ai-rules-mut-tenantguard-dev | OK baseline |
| Runtime DEV Client | v3.5.196-ai-rules-bff-dev | OK |
| Runtime PROD API (a promouvoir) | v3.5.185-ai-rules-read-tenantguard-prod | OK baseline |
| Runtime PROD Client (read-only) | v3.5.196-ai-rules-bff-prod | OK |
| KEY-309 tag `v3.5.186-ai-rules-mut-tenantguard-prod` (pre-build) | GHCR manifest unknown | OK libre |
| `assert-git-committed.sh` | api + client propres -- BUILD AUTORISE | OK |
| DB baseline PROD `ai_rules` | 390 rows | OK |
| DB baseline PROD `ai_rule_conditions` | 104 rows | OK |
| DB baseline PROD `ai_rule_actions` | 936 rows | OK |
| DB baseline PROD `playbook_suggestions` | 6 rows | OK |

---

## 5. Confirmation source API

HEAD `keybuzz-api` ph147.4/source-of-truth = `05bb57cd6b0d312abf69c6e13608a71fbf2929f5` (commit AS.12.2C-5B IMPL DEV).

| Endpoint | Method | Matcher / Protected route | Expected no-auth | Verdict |
|---|---|---|---|---|
| /ai/rules | POST | exact PROTECTED_ROUTES (5B) | 401 | confirme |
| /playbooks | POST | exact PROTECTED_ROUTES (5B) | 401 | confirme |
| /playbooks/:id | PUT | isPlaybookDetailMutation (5B) | 401 | confirme |
| /playbooks/:id | DELETE | isPlaybookDetailMutation (5B) | 401 | confirme |
| /playbooks/:id/toggle | PATCH | isPlaybookTogglePatch (5B) | 401 | confirme |
| /playbooks/suggestions/:id/apply | PATCH | isPlaybookSuggestionActionPatch (5B) | 401 | confirme |
| /playbooks/suggestions/:id/dismiss | PATCH | isPlaybookSuggestionActionPatch (5B) | 401 | confirme |
| /ai/rules | GET | exact PROTECTED_ROUTES (5A) | 401 preserve | OK |
| /playbooks | GET | exact PROTECTED_ROUTES (5A) | 401 preserve | OK |
| /playbooks/:id | GET | isPlaybookDetailGet (5A) | 401 preserve | OK |
| /playbooks/suggestions | GET | exact PROTECTED_ROUTES (5A) | 401 preserve | OK |

---

## 6. Build evidence

### 6.1 Build API PROD

```
bash scripts/build-api-from-git.sh prod v3.5.186-ai-rules-mut-tenantguard-prod ph147.4/source-of-truth
```

Build OK, Git SHA `05bb57c` (= HEAD post-push 5B DEV). Local Image Id `sha256:bab5b0ebaef014b6d3b96bc0191d607069a012e3062801f8cf3eb0c8aea84856`.

OCI labels KEY-308 :

| Image | Tag | Source SHA | OCI revision | Created | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | v3.5.186-ai-rules-mut-tenantguard-prod | 05bb57c | `05bb57cd6b0d312abf69c6e13608a71fbf2929f5` | `2026-05-13T20:54:40Z` | PASS |

Source : `https://github.com/keybuzzio/keybuzz-api`. Title : `keybuzz-api`.

### 6.2 Aucun build Client

Conformement au scope API-only : aucun build Client PROD effectue. Image Client PROD reste `v3.5.196-ai-rules-bff-prod`.

---

## 7. Push evidence

| Image | Tag | GHCR digest | Revision | Verdict |
|---|---|---|---|---|
| keybuzz-api | v3.5.186-ai-rules-mut-tenantguard-prod | `sha256:637ee3d659ac0e65f10e8f0b9937924f42555b09e41c1805d5d2d238459a0e18` (size 2416) | 05bb57cd6b0d312abf69c6e13608a71fbf2929f5 | PASS |

KEY-309 immuable confirme : `docker manifest inspect` pre-push retournait `manifest unknown` (libre), post-push retourne le digest. Aucun overwrite.

---

## 8. GitOps evidence

### 8.1 Commit manifest infra

Commit `8737fc3 deploy(prod): promote AS.12.2C-5B API to PROD (KEY-301)` push origin/main 0-0 :
- `k8s/keybuzz-api-prod/deployment.yaml` : 1 ligne image+commentaire (v3.5.185 -> v3.5.186).
- `k8s/keybuzz-client-prod/deployment.yaml` : **non touche** (Client PROD inchange).

Diff stat : 1 file changed, 1 insertion(+), 1 deletion(-).

### 8.2 Apply API PROD

```
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
deployment.apps/keybuzz-api configured
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
deployment "keybuzz-api" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | v3.5.186-ai-rules-mut-tenantguard-prod | OK |
| last-applied-configuration | identique | OK |
| pod imageID nouveau | `sha256:637ee3d659ac0e65f10e8f0b9937924f42555b09e41c1805d5d2d238459a0e18` | OK MATCH digest pushe |
| pod imageID ancien (terminating) | `sha256:43246c294ca8...` (v3.5.185) | OK rollout normal |

### 8.3 Aucun apply Client PROD

Client PROD inchange : `kubectl -n keybuzz-client-prod get deploy keybuzz-client` retourne `ghcr.io/keybuzzio/keybuzz-client:v3.5.196-ai-rules-bff-prod`.

---

## 9. Runtime digest evidence

Pod API PROD post-rollout imageID = `ghcr.io/keybuzzio/keybuzz-api@sha256:637ee3d659ac0e65f10e8f0b9937924f42555b09e41c1805d5d2d238459a0e18` = digest GHCR pushe = source de v3.5.186-ai-rules-mut-tenantguard-prod = commit `05bb57cd`. Chaine source/build/registry/runtime verifiee.

---

## 10. Security validation negative-only

### 10.1 /health PROD

```
GET https://api.keybuzz.io/health -> 200
```

### 10.2 Tests 5B NEW (7 mutations, no-auth, payloads representatifs)

UUIDs fictifs : `tenantId=00000000-...`, `playbookId=22222222-...`, `suggestionId=33333333-...`.

| Test | Endpoint | Method | Matcher | Observed | DB impact | Verdict |
|---|---|---|---|---|---|---|
| 5B-N1 | /ai/rules | POST | exact PROTECTED_ROUTES | 401 | 0 | PASS |
| 5B-N2 | /playbooks | POST | exact PROTECTED_ROUTES | 401 | 0 | PASS |
| 5B-N3 | /playbooks/22222222-...-2222 | PUT | isPlaybookDetailMutation | 401 | 0 | PASS |
| 5B-N4 | /playbooks/22222222-...-2222 | DELETE | isPlaybookDetailMutation | 401 | 0 | PASS |
| 5B-N5 | /playbooks/22222222-...-2222/toggle | PATCH | isPlaybookTogglePatch | 401 | 0 | PASS |
| 5B-N6 | /playbooks/suggestions/33333333-...-3333/apply | PATCH | isPlaybookSuggestionActionPatch | 401 | 0 | PASS |
| 5B-N7 | /playbooks/suggestions/33333333-...-3333/dismiss | PATCH | isPlaybookSuggestionActionPatch | 401 | 0 | PASS |

### 10.3 Tests preserve 5A READ (4 endpoints)

| Test | Endpoint | Method | Observed | Verdict |
|---|---|---|---|---|
| 5A-N1 | /ai/rules | GET | 401 | PASS |
| 5A-N2 | /playbooks | GET | 401 | PASS |
| 5A-N3 | /playbooks/22222222-...-2222 | GET (matcher isPlaybookDetailGet) | 401 | PASS |
| 5A-N4 | /playbooks/suggestions | GET | 401 | PASS |

Coexistence matchers 5A et 5B verifiee : `isPlaybookDetailGet` (GET only) reste actif et n est pas casse par les 3 matchers 5B (PUT/DELETE/PATCH distincts par method check).

### 10.4 Tests preserve 10 autres protections

| Endpoint | Method | Phase | Observed | Verdict |
|---|---|---|---|---|
| /ai/execute | POST | AS.12.2C-4 | 401 | PASS |
| /ai/evaluate | POST | AS.12.2C-3 | 401 | PASS |
| /ai/assist | POST | AS.12.2C-1 | 401 | PASS |
| /ai/guard/check | POST | AS.12.2C-2 | 401 | PASS |
| /messages/conversations | GET | KEY-304 | 401 | PASS |
| /tenants | GET | AS.12.1A | 401 | PASS |
| /notifications | GET | AS.12.1B | 401 | PASS |
| /autopilot/draft | GET | AS.12.2B | 401 | PASS |
| /ai/settings | GET | AS.12.2D | 401 | PASS |
| /ai/wallet/status | GET | AS.12.2D | 401 | PASS |

**21/21 PASS**. Aucun POST/PUT/PATCH/DELETE positif emis. tenantGuard preHandler rejette en 401 avant atteinte du handler.

---

## 11. DB no-mutation proof

### 11.1 Counts pre / post deploy

| Mesure | Pre-deploy | Post-deploy 10min | Delta | Verdict |
|---|---|---|---|---|
| `ai_rules` total | 390 | 390 | 0 | PASS |
| `ai_rule_conditions` total | 104 | 104 | 0 | PASS |
| `ai_rule_actions` total | 936 | 936 | 0 | PASS |
| `playbook_suggestions` total | 6 | 6 | 0 | PASS |

**Delta strict 0 sur 4 tables**. Aucune mutation DB causee par cette phase. Pas de classification "activite naturelle" requise puisque counts strictement identiques (contrairement a AS.12.2C-5A-PROD qui avait observe +15/+4/+36 lies a un seeding starter natural durant la fenetre de deploy).

Validation 100% negative : tenantGuard preHandler rejette `401 AUTH_REQUIRED` avant atteinte du handler -> 0 INSERT / UPDATE / DELETE sur les 4 tables impactees.

---

## 12. Logs / health

| Source | Filtre | Count | Verdict |
|---|---|---|---|
| GET /health API PROD | -- | 200 | PASS |
| API PROD `statusCode 5xx / level=50` | 5min | 0 | PASS |
| Client PROD `JWT_SESSION_ERROR` | 5min | 0 | PASS |
| API PROD pod restart post-rollout | observation | 0 | PASS |

---

## 13. QA Ludovic

URL PROD : **`https://client.keybuzz.io`** (ingress + NEXTAUTH_URL alignes, cf rapport AS.12.2C-4-PROD section 4 et AS.12.2C-5A-PROD).

Resultat Ludovic :
- Playbooks pages list/detail/suggestions consultes en read-only **sans cliquer aucun bouton create/edit/delete/toggle/apply/dismiss**.
- Inbox **OK**.
- Brouillon IA OK sur les cas attendus.
- tenant switcher **OK**.
- escalation badge **OK**.
- **Aucune regression visible**.

**Verdict QA** : GO AI RULES MUTATIONS TENANTGUARD PROD READY.

Note : aucun test mutationnel UI (create/edit/delete/toggle/apply/dismiss) effectue conformement au scope. Les mutations UI authentifiees seront validees lors de la prochaine utilisation produit naturelle.

---

## 14. PROD services unchanged

| Service | PROD image before 5B | PROD image after 5B | Status |
|---|---|---|---|
| keybuzz-api-prod / keybuzz-api | v3.5.185-ai-rules-read-tenantguard-prod | v3.5.186-ai-rules-mut-tenantguard-prod | PROMU |
| keybuzz-client-prod / keybuzz-client | v3.5.196-ai-rules-bff-prod | idem (inchange) | OK unchanged |
| keybuzz-api-prod / keybuzz-outbound-worker | v3.5.165-escalation-flow-prod | idem | OK unchanged |
| keybuzz-admin-v2-prod / keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | idem | OK unchanged |
| keybuzz-backend-prod / amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod | idem | OK unchanged |
| keybuzz-backend-prod / amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod | idem | OK unchanged |
| keybuzz-backend-prod / backfill-scheduler | v1.0.42-td02-worker-resilience-prod | idem | OK unchanged |
| keybuzz-backend-prod / keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | idem | OK unchanged |
| keybuzz-studio-prod / keybuzz-studio | v0.8.0-prod | idem | OK unchanged |
| keybuzz-studio-api-prod / keybuzz-studio-api | v0.8.1-prod | idem | OK unchanged |
| keybuzz-website-prod / keybuzz-website | v0.6.12-linkedin-insight-seo-prod | idem | OK unchanged |
| keybuzz-seller-dev / seller-api | v2.0.5-ph-prod-ftp-02 | idem (hors KEY-301) | OK unchanged |
| keybuzz-seller-dev / seller-client | v2.0.7-ph-prod-ftp-02b | idem (hors KEY-301) | OK unchanged |

13 services PROD inventories ; **1 promu** (api) ; **12 strictement inchanges**.

---

## 15. Rollback plan (PRET, NON EXECUTE)

```
cd /opt/keybuzz/keybuzz-infra
git revert 8737fc3 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.185-ai-rules-read-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
```

Triggers rollback (non utilises ici) :
- Spike 401/403 sur GET /playbooks (5A read) pour tenant authentifie -> regression matcher.
- Spike 5xx API PROD.
- Spike JWT_SESSION_ERROR Client PROD durable.
- QA Ludovic confirme regression /playbooks UI pour son tenant.

Note : Client PROD non touche cette phase -> rollback Client non applicable.

---

## 16. Linear text prepared (disclosure-controlled)

### 16.1 KEY-301 commentaire cible

```
## AS.12.2C-5B-PROD coordinated promotion GO READY (API-only)

Hardening of MUTATIONS rules + playbooks surface extended to PROD after DEV validation (AS.12.2C-5B DEV report).

Runtime PROD :
- API : v3.5.185 -> v3.5.186-ai-rules-mut-tenantguard-prod (digest sha256:637ee3d659ac0e65f10e8f0b9937924f42555b09e41c1805d5d2d238459a0e18, OCI revision 05bb57cd6b0d312abf69c6e13608a71fbf2929f5).
- Client PROD unchanged at v3.5.196-ai-rules-bff-prod.
- Manifest commit 8737fc3, GitOps strict, spec=last-applied=runtime imageID=GHCR digest.
- OCI labels KEY-308 complete, KEY-309 immuable.

Validation PROD :
- 21/21 preserve protections at 401 unauthenticated (7 NEW MUTATIONS + 4 preserve 5A READ + 10 preserve earlier phases).
- 0 5xx API PROD 5min. 0 JWT_SESSION_ERROR Client PROD 5min.
- DB no-mutation STRICT : ai_rules 390 / ai_rule_conditions 104 / ai_rule_actions 936 / playbook_suggestions 6 -- counts strictement identiques pre + post deploy.
- 12 other PROD services strictly unchanged.

QA Ludovic browser PROD (https://client.keybuzz.io) : playbooks pages list/detail/suggestions consulted read-only WITHOUT clicking any create/edit/delete/toggle/apply/dismiss button. Inbox + Brouillon IA + tenant switcher + escalation OK. No regression observed.

Verdict : **GO AI RULES MUTATIONS TENANTGUARD PROD READY**. No rollback triggered.

KEY-301 epic AI rules + playbooks surface (READ + MUTATIONS) maintenant entierement protege en DEV + PROD.

Remaining sub-tasks (separated from KEY-301 closeout decision) :
- KEY-312 (GP1 Brouillon IA silent failure) -- product decision pending.
- Plan gating on /ai/rules + /playbooks -- separate housekeeping ticket.
- BFF /api/ai/rules POST -- deferred (no Client caller).
- Admin v2 mock chain -- to wire when admin v2 connects rules.

KEY-301 stays Open. Closeout decision by Ludovic separately.

Disclosure controle : no PoC, no exploit details, no draftText, no PII.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5B-AI-RULES-MUTATIONS-TENANTGUARD-HARDENING-PROD-01.md
```

Note : backlog 36 jeux de commentaires Linear KEY-* accumules en attente methode token API.

---

## 17. Compliance PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 / 46.62.171.61 | OK |
| Build from-git fresh clone + SHA MATCH | OK |
| KEY-309 tag immuable (pre-push manifest unknown) | OK |
| KEY-308 OCI labels complets | OK |
| docker push GHCR + digest captured | OK |
| GitOps strict (kubectl apply -f only) | OK |
| Aucun build / push / deploy Client PROD | OK |
| Aucun manifest Client PROD touche | OK |
| spec = last-applied = pod imageID = digest pushe | OK API |
| Aucune mutation source PROD | OK |
| Aucune mutation DB causee par cette phase | OK (delta strict 0) |
| Aucun POST/PUT/PATCH/DELETE positif vers rules/playbooks | OK |
| Aucune creation/modification/suppression/toggle/apply/dismiss | OK |
| Aucune generation LLM / KBActions / debit wallet | OK |
| Aucun draftText / PII | OK |
| Aucun secret display | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear (prepared) | OK |
| KEY-301 statut Done NON applique | OK |
| Rollback documente et pret (non execute) | OK |
| 12 autres services PROD strictement inchanges | OK |
| QA Ludovic confirme aucune regression UX sur URL correcte client.keybuzz.io | OK |

---

## 18. Gaps remaining

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | BFF `/api/playbooks/[id]/simulate` et `/[id]/suggestions` pointent vers endpoints API potentiellement absents (cf AS.12.2C-5 design audit) | Low | RCA dediee si necessaire ; pas de regression observee |
| G2 | Plan gating absent sur /ai/rules + /playbooks (requirePlan non applique) | Medium | Ticket housekeeping separe ; hors scope KEY-301 |
| G3 | Admin v2 mock pur sur rules ; future connexion API necessitera BFF + tenantGuard deja prets via 5A+5B | Low | A documenter quand admin v2 branche real rules |
| G4 | BFF /api/ai/rules POST handler differe (aucun caller actuel) | Low | Anticipation a faire si caller apparait |
| G5 | Backlog 36 jeux de commentaires Linear KEY-* accumules en attente methode token | Low | Resoudre methode token hors-chat |
| GP1 | (rappel) Brouillon IA silent failure -- Linear KEY-312 | Medium | Decision produit en cours, hors KEY-301 |

---

## 19. KEY-301 status recommendation

**Recommandation technique** : la surface AI rules + playbooks (READ + MUTATIONS) est maintenant **entierement protege** par tenantGuard en DEV + PROD avec :
- 21 endpoints proteges (4 READ + 7 MUTATIONS + 10 preserve earlier phases).
- 0 mutation DB causee.
- Pattern de validation negative reproductible.
- Bundle Client PROD KEY-302 OK.
- 12 services PROD inchanges.

**KEY-301 epic security tenantGuard** peut etre considere **techniquement complet** sur la surface AI + rules. La decision de closeout (Done) reste a Ludovic.

Sous-tickets persistants (separes de KEY-301) :
- **KEY-312** (GP1 Brouillon IA silent failure) -- decision produit a prendre.
- Plan gating /ai/rules + /playbooks -- ticket housekeeping separe a creer.
- BFF /api/ai/rules POST -- anticipation differee.

---

## 20. Phrase cible finale

AS.12.2C-5B-PROD livre API-only : promotion PROD API v3.5.185 -> v3.5.186-ai-rules-mut-tenantguard-prod (digest GHCR `sha256:637ee3d659ac0e65f10e8f0b9937924f42555b09e41c1805d5d2d238459a0e18`, OCI revision `05bb57cd6b0d312abf69c6e13608a71fbf2929f5`, created `2026-05-13T20:54:40Z`) ; build PROD via scripts patches AS.12.2C-3.1 avec OCI labels KEY-308 complets ; aucun build Client (Client PROD reste `v3.5.196-ai-rules-bff-prod` inchange) ; docker push GHCR API (KEY-309 immuable pre-push manifest unknown) ; manifest infra commit `8737fc3` push origin main 0-0 (1 fichier API PROD, 1 ligne) ; 1 kubectl apply -f API PROD + rollout successful ; spec = last-applied = pod imageID = digest pushe ; preserve+NEW 21/21 (7 NEW MUTATIONS POST /ai/rules + POST /playbooks + PUT/DELETE /playbooks/:uuid (isPlaybookDetailMutation) + PATCH /playbooks/:uuid/toggle (isPlaybookTogglePatch) + PATCH /playbooks/suggestions/:uuid/apply|dismiss (isPlaybookSuggestionActionPatch) + 4 preserve 5A READ + 10 autres preserve tous 401 no-auth avec payloads valides) ; 3 matchers dynamiques verifies en runtime sans conflit avec 5A ; 0 5xx API PROD 5min + 0 JWT spike Client PROD 5min + 0 restart pod post-rollout ; DB no-mutation STRICT `ai_rules`=390 / `ai_rule_conditions`=104 / `ai_rule_actions`=936 / `playbook_suggestions`=6 (delta 0 sur les 4 tables, aucune mutation causee) ; QA Ludovic navigateur PROD sur URL **correcte** `https://client.keybuzz.io` : playbooks pages list/detail/suggestions consultes en read-only **sans cliquer aucun bouton create/edit/delete/toggle/apply/dismiss** + Inbox + Brouillon IA + tenant switcher + escalation OK, aucune regression visible ; PROD strictement inchange 12 autres services (outbound-worker, admin-v2, backend, amazon-items-worker, amazon-orders-worker, backfill-scheduler, studio, studio-api, website, seller-api, seller-client, keybuzz-client v3.5.196-prod) ; aucune mutation source PROD / build dirty / push tag reuse / mutation DB / creation / modification / suppression / toggle / apply / dismiss de regle ; KEY-301 reste Open epic ; KEY-301 epic AI rules + playbooks (READ + MUTATIONS) maintenant **techniquement complet** sur DEV + PROD ; closeout Done a la discretion de Ludovic ; sous-tickets persistants : KEY-312 GP1 produit + plan gating housekeeping + BFF POST /api/ai/rules differe + admin v2 mock future ; verdict AS.12.2C-5B-PROD GO AI RULES MUTATIONS TENANTGUARD PROD READY.

STOP. AS.12.2C-5B PROD livre. Aucun enchainement vers cloture KEY-301 sans GO explicite Ludovic.
