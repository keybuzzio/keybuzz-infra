# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-APPLY-PROD-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 (seller-first/refund) ; KEY-231 (KBActions anxiety) ; KEY-305 (race UI) ; KEY-263 (DEV/PROD isolation) ; KEY-302 (build args) ; KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE APPLY Client PROD GitOps strict
> Environnement : PROD Client only (API PROD inchange v3.5.255)

## VERDICT

GO APPLY CLIENT GUARDRAIL GUIDANCE PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Manifest `k8s/keybuzz-client-prod/deployment.yaml` bumpe v3.5.201 -> v3.5.215-ai-draft-blocked-reason-prod.
- Infra commit manifest `20109ef` push origin/main.
- kubectl apply OK -> rollout `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau unique **`keybuzz-client-696bcd98c6-92c96`** Ready 1/1, 0 restart.
- Runtime digest Client PROD : `sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77` MATCH GHCR manifest digest.
- Triple match parfait : last-applied = manifest spec = pod imageID.
- Smokes pod : `/api/healthz` HTTP 200 (chunked), `/` HTTP 200 9046 bytes.
- **Guidance PH-20.11C LIVE runtime 7/7** : Trame=2, Point depart=2, sans generation IA=2, consommation KBActions=2, ne peux pas confirmer=2, remboursement remplacement=2, Copier la trame=4.
- **AutoOpen PH-20.11B pattern compile preserve LIVE** : `.draftText)||(null==S?void 0:S.blocked`.
- Markers PH-20.11B preserve : blockedInfo=4, Garde-fou actif=2, Brouillon IA bloque=2, Validation humaine=2.
- AI feature parity preserve : Brouillon IA=6, Suggestion IA=4, Aide IA=10.
- **KEY-263 PROD isolation STRICT** : api.keybuzz.io PROD=87, api-dev.keybuzz.io DEV=0.
- KEY-302 sentinel `__MUST_BE_SET_BY_BUILD_ARG__=0`.
- Logs Client PROD : 0 TypeError, 0 ReferenceError, 0 ChunkLoadError, 0 unhandled. Startup "Ready in 514ms".
- Runtime API PROD `v3.5.255-ai-draft-blocked-reason-prod` INCHANGE.
- Runtime DEV (Client + API) INCHANGE LIVE.

**STACK COMPLETE PH-20.11B + PH-20.11C LIVE EN PROD : API PROD v3.5.255 + Client PROD v3.5.215. La carte UX `Garde-fou actif` + sous-bloc `Trame de reponse securisee` + bouton `Copier la trame` sont desormais visibles pour les conversations PRE_LLM_BLOCKED/ESCALATION_DRAFT en production.**

STOP avant QA browser Ludovic PROD.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T11:03:36Z |
| kube-context | kubernetes-admin@kubernetes |
| keybuzz-infra HEAD avant | 4b6f39c |
| keybuzz-infra HEAD apres bump | **20109ef** |

## E1 GHCR DIGEST VERIFY

| Item | Valeur | Verdict |
|---|---|---|
| Image GHCR | ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod | OK |
| Config digest | sha256:38474f0835c1a271c7219cc91566c8dde827007cfb62727250c82aaa2cf66af1 | OK MATCH expected |
| Manifest digest | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 | OK MATCH expected |
| OCI revision | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK |

## E2 BUMP MANIFEST GITOPS

| Item | Valeur |
|---|---|
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image apres bump | `image: ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod` + annotation PH-20.11C-GUARDRAIL-GUIDANCE-CLIENT-APPLY-PROD avec KEY-312/235/231/305/263/302, commit 1a30ad9, parite DEV/PROD QA, manifest digest GHCR, rollback |
| Dry-run server | `deployment.apps/keybuzz-client configured (server dry run)` |
| Commit infra | `20109ef` chore(client): deploy PH-20.11C guardrail guidance PROD |
| Push | OK 4b6f39c..20109ef main -> main |

## E3 APPLY PROD + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply | `deployment.apps/keybuzz-client configured` |
| Rollout status | `deployment "keybuzz-client" successfully rolled out` |
| Pod nouveau unique | **keybuzz-client-696bcd98c6-92c96** Ready 1/1, 0 restart |

### Triple match Client PROD

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ai-draft-blocked-reason-prod | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 | OK MATCH GHCR |

## E5 SMOKES POD

| Endpoint | HTTP | Bytes | Verdict |
|---|---|---|---|
| /api/healthz | 200 | chunked | OK |
| / | 200 | 9046 | OK |

## E6 BUNDLE RUNTIME AUDIT (/app/.next pod Client PROD)

### Markers GUIDANCE PH-20.11C LIVE

| Marker | Count | Verdict |
|---|---|---|
| Trame de reponse securisee | 2 | LIVE |
| Point de depart humain | 2 | LIVE |
| sans generation IA | 2 | LIVE |
| consommation de KBActions | 2 | LIVE |
| ne peux pas confirmer immediatement | 2 | LIVE |
| remboursement ou un remplacement avant verification | 2 | LIVE |
| Copier la trame | 4 | LIVE |

### Pattern compile AutoOpen PH-20.11B preserve

```
.draftText)||(null==S?void 0:S.blocked
```

PRESENT runtime PROD -> drawer s'ouvre auto pour blocked.

### Markers AutoOpen + parent-wire PH-20.11B preserve

| Marker | Count | Verdict |
|---|---|---|
| blockedInfo | 4 | preserve |
| Garde-fou actif | 2 | preserve |
| Brouillon IA bloque par securite | 2 | preserve |
| Validation humaine recommandee | 2 | preserve |

### AI feature parity preserve

| Marker | Count | Verdict |
|---|---|---|
| Brouillon IA | 6 | preserve |
| Suggestion IA | 4 | preserve |
| Aide IA | 10 | preserve |

### KEY-263 PROD isolation STRICT

| Indicateur | Count | Verdict |
|---|---|---|
| api.keybuzz.io PROD pattern | **87** | OK PROD endpoint LIVE |
| api-dev.keybuzz.io DEV pattern | **0** | OK isolation strict |
| `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | OK KEY-302 |

## E7 LOGS

| Pattern | Count | Verdict |
|---|---|---|
| TypeError | 0 | OK |
| ReferenceError | 0 | OK |
| ChunkLoadError | 0 | OK |
| unhandled | 0 | OK |
| Startup | "Ready in 514ms" | OK |

## E8 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | PROD | **v3.5.215-ai-draft-blocked-reason-prod** | **NOUVEAU LIVE (cible deployee)** |
| keybuzz-api | PROD | v3.5.255-ai-draft-blocked-reason-prod | INCHANGE LIVE PH-20.11C |
| keybuzz-client | DEV | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Etat runtime PROD | Verdict |
|---|---|---|
| Brouillon IA visible quand DRAFT_GENERATED | preserve | OK |
| Brouillon IA blockedInfo auto-open PH-20.11B | pattern compile LIVE | OK |
| **Trame de reponse securisee PH-20.11C** | **LIVE 7/7 markers** | **enrichissement** |
| Copier la trame (clipboard local) | LIVE | OK |
| Suggestion IA | preserve | OK |
| Aide IA | preserve (10) | OK |
| KEY-305 race UI fix preserve | dans pattern compile | OK |
| Doctrine seller-first/refund-protection | INCHANGE 100% | OK |
| Wallet/KBActions | INCHANGE | OK |
| KEY-263 PROD isolation strict | OK (87/0) | OK |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Aucun appel `/ai/assist` | 0 | OK |
| Aucun appel `/ai/execute` | 0 | OK |
| Aucun appel `/autopilot/draft/consume` | 0 | OK |
| Aucun message marketplace envoye | 0 | OK |
| Aucun event marketing genere | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucun LLM call | 0 | OK |
| Smokes /api/healthz + / GET only | OK | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy API PROD (API PROD INCHANGE v3.5.255).
- AUCUN restart pod hors rollout normal.
- AUCUN kubectl set/patch/edit (GitOps strict apply -f).
- AUCUN changement Backend/Website/Admin.
- AUCUN changement source au-dela commit 1a30ad9.
- AUCUN faux event / register / checkout / lead.
- AUCUN appel LLM reel.
- AUCUNE consommation KBActions.
- AUCUN secret/token/PII affiche.
- AUCUN Linear ticket statut modifie.
- AUCUN seuil guardrail modifie.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- Doctrine seller-first INCHANGE 100%.
- KEY-305 fix race UI preserve dans bundle compile.
- KEY-263 PROD isolation strict respectee.
- KEY-302 sentinel preserve.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PROD DOCUMENTE (non execute)

Si regression observee :
```
cd /opt/keybuzz/keybuzz-infra
# Editer k8s/keybuzz-client-prod/deployment.yaml -> image v3.5.201-register-polish-prod
git add k8s/keybuzz-client-prod/deployment.yaml
git commit -m "ops(client-prod): ROLLBACK PH-20.11C to v3.5.201"
git push origin main
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status -n keybuzz-client-prod deploy/keybuzz-client --timeout=300s
```

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Services

| Service | Avant | Apres | Verdict |
|---|---|---|---|
| Client PROD | v3.5.201-register-polish-prod | **v3.5.215-ai-draft-blocked-reason-prod** | OK NOUVEAU LIVE |
| API PROD | v3.5.255 | inchange | OK LIVE PH-20.11C |
| Client DEV | v3.5.214 | inchange | OK LIVE |
| API DEV | v3.5.254 | inchange | OK LIVE |

### 2. Manifest + Apply

| Manifest | Commit | Apply | Rollout | Verdict |
|---|---|---|---|---|
| k8s/keybuzz-client-prod/deployment.yaml | 20109ef | OK | successfully rolled out | OK |

### 3. Pod / Digest

| Pod | Digest runtime | Digest GHCR | Match | Verdict |
|---|---|---|---|---|
| keybuzz-client-696bcd98c6-92c96 | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 | OK | MATCH |

### 4. Bundle markers

| Marker | Count | Verdict |
|---|---|---|
| **GUIDANCE PH-20.11C (7 markers)** | 2/2/2/2/2/2/4 | LIVE 7/7 |
| Pattern compile autoOpen `draftText \|\| blocked` | PRESENT | preserve PH-20.11B |
| blockedInfo / Garde-fou actif / Brouillon IA bloque / Validation humaine | 4/2/2/2 | preserve |
| Brouillon IA / Suggestion IA / Aide IA | 6/4/10 | preserve |
| api.keybuzz.io PROD / api-dev.keybuzz.io DEV / KEY-302 sentinel | 87/0/0 | OK STRICT |

### 5. Logs

| Pattern | Count | Verdict |
|---|---|---|
| TypeError / ReferenceError / ChunkLoadError / unhandled | 0/0/0/0 | OK |
| Startup "Ready in 514ms" | OK | OK |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build/push | OUI | aucun build/push run |
| deploy API PROD | OUI | runtime API PROD inchange v3.5.255 |
| kubectl set/patch/edit/delete | OUI | uniquement apply -f + get + rollout status |
| restart pod manuel | OUI | rollout normal |
| LLM call / /ai/assist / /draft/consume | OUI | 0 |
| fake event/metric/KBActions | OUI | 0 |
| mutation DB | OUI | aucun acces DB |
| changement Linear statut | OUI | comment only |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| **Verdict** | **GO APPLY CLIENT GUARDRAIL GUIDANCE PROD READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE** |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| Image runtime PROD | v3.5.215-ai-draft-blocked-reason-prod |
| Runtime digest PROD | sha256:ae312d263c91acd0ea7d938c4662557acd5f27b9d37481489dec5a3b66be1b77 |
| Pod PROD | 696bcd98c6-92c96 Ready 1/1 0 restart |
| Triple match | OK |
| Commit infra manifest | 20109ef push origin/main |
| Smokes /api/healthz + / pod | HTTP 200 / 200 9046 bytes |
| Guidance PH-20.11C LIVE bundle | OK 7/7 markers |
| AutoOpen PH-20.11B preserve | OK pattern compile + 4/2/2/2 |
| AI feature parity | preserve (6/4/10) |
| KEY-263 PROD isolation | OK strict (87/0) |
| KEY-302 sentinel | 0 |
| Logs PROD | 0 erreur, "Ready in 514ms" |
| Runtime API PROD + DEV | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-APPLY-PROD-01.md` |

**STACK COMPLETE PH-20.11B + PH-20.11C LIVE EN PROD :**
- API PROD `v3.5.255-ai-draft-blocked-reason-prod` (blockedInfo expose read-only)
- Client PROD `v3.5.215-ai-draft-blocked-reason-prod` (autoOpen + carte amber + guidance statique + bouton copier)

### Prochaine phrase GO attendue

`GO QA CLIENT GUARDRAIL GUIDANCE PROD PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

(QA browser Ludovic PROD sur conversation PROD reelle bloquee SWITAA `cmmph7bhmgcb...` pour observer drawer auto-ouvert + carte amber `Garde-fou actif` + sous-bloc `Trame de reponse securisee` + bouton `Copier la trame`)

STOP. Aucun changement API PROD, aucun changement Linear statut.
