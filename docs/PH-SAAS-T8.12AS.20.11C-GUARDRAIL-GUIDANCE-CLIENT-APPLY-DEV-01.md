# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-APPLY-DEV-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 (seller-first/refund) ; KEY-231 (KBActions anxiety) ; KEY-305 (race UI) ; KEY-263 (DEV/PROD isolation) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE APPLY Client DEV GitOps strict
> Environnement : DEV only (aucun PROD, aucun LLM, aucune KBActions)

## VERDICT

GO APPLY CLIENT GUARDRAIL GUIDANCE DEV READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Manifest `k8s/keybuzz-client-dev/deployment.yaml` bumpe v3.5.213 -> v3.5.214-ai-draft-blocked-reason-dev.
- Infra commit manifest `4dcb58b` push origin/main.
- kubectl apply OK -> rollout `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau unique **`keybuzz-client-7c65567649-nsh5f`** Ready 1/1, 0 restart.
- Runtime digest DEV : `sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff` MATCH GHCR manifest digest.
- Triple match parfait : last-applied = manifest spec = pod imageID.
- Smokes pod : `/api/healthz` HTTP 200 (chunked), `/` HTTP 200 9046 bytes.
- **Guidance PH-20.11C LIVE runtime 7/7** : `Trame de reponse securisee=2, Point de depart humain=2, sans generation IA=2, consommation de KBActions=2, ne peux pas confirmer immediatement=2, remboursement ou un remplacement avant verification=2, Copier la trame=4`.
- AutoOpen PH-20.11B pattern compile preserve : `.draftText)||(null==S?void 0:S.blocked` + reset conditionnel.
- Markers PH-20.11B preserve : `blockedInfo=4, Garde-fou actif=2, Brouillon IA bloque par securite=2, Validation humaine recommandee=2`.
- AI feature parity preserve : `Brouillon IA=6, Suggestion IA=4, Aide IA=10`.
- KEY-263 DEV isolation strict : `api-dev.keybuzz.io=87, api.keybuzz.io PROD=0`.
- KEY-302 sentinel `__MUST_BE_SET_BY_BUILD_ARG__=0`.
- Logs Client DEV : 0 TypeError, 0 ReferenceError, 0 ChunkLoadError, 0 unhandled.
- Startup OK : "Ready in 362ms".
- Runtime API DEV+PROD + Client PROD INCHANGES.

**La stack PH-20.11B + PH-20.11C est maintenant LIVE en DEV. La carte UX `Garde-fou actif` + sous-bloc `Trame de reponse securisee` + bouton `Copier la trame` doivent etre visibles pour les conversations PRE_LLM_BLOCKED/ESCALATION_DRAFT.**

STOP avant QA browser Ludovic.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T01:50:09Z |
| kube-context | kubernetes-admin@kubernetes |
| keybuzz-infra HEAD avant | c73fe69 |
| keybuzz-infra HEAD apres bump | **4dcb58b** |
| Runtime Client DEV avant | v3.5.213-ai-draft-blocked-reason-dev |
| Runtime API DEV avant | v3.5.254-ai-draft-blocked-reason-dev LIVE |

## E1 GHCR DIGEST VERIFY

| Item | Valeur | Verdict |
|---|---|---|
| Image GHCR | ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev | OK |
| Config digest | sha256:74d13025bd24642cc28c58f416de73ff57d11456fa695c062bd4242d742ce4e4 | OK MATCH expected |
| Manifest digest | sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff | OK MATCH expected |
| OCI revision | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 | OK |

## E2 BUMP MANIFEST GITOPS

| Item | Valeur |
|---|---|
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image apres bump | `image: ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev` + annotation PH-20.11C-GUARDRAIL-GUIDANCE avec KEY-312/235/231/305/263/302, commit 1a30ad9, manifest digest GHCR, rollback |
| Dry-run server | `deployment.apps/keybuzz-client configured (server dry run)` |
| Commit infra | `4dcb58b` chore(client): deploy PH-20.11C guardrail guidance DEV |
| Push | OK c73fe69..4dcb58b main -> main |

## E3 APPLY DEV + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply | `deployment.apps/keybuzz-client configured` |
| Rollout status | `deployment "keybuzz-client" successfully rolled out` |
| Pod nouveau unique | **keybuzz-client-7c65567649-nsh5f** Ready 1/1, 0 restart |

### Triple match Client DEV

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-client:v3.5.214-ai-draft-blocked-reason-dev | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff | OK MATCH GHCR |

## E5 SMOKES POD

| Endpoint | HTTP | Bytes | Verdict |
|---|---|---|---|
| /api/healthz | 200 | chunked | OK |
| / | 200 | 9046 | OK |

## E6 BUNDLE RUNTIME AUDIT (/app/.next pod)

### Markers GUIDANCE PH-20.11C LIVE

| Marker | Count | Verdict |
|---|---|---|
| Trame de reponse securisee | 2 | **LIVE** |
| Point de depart humain | 2 | **LIVE** |
| sans generation IA | 2 | **LIVE** |
| consommation de KBActions | 2 | **LIVE** |
| ne peux pas confirmer immediatement | 2 | **LIVE** |
| remboursement ou un remplacement avant verification | 2 | **LIVE** |
| Copier la trame | 4 | **LIVE** |

### Pattern compile AutoOpen PH-20.11B preserve

```
.draftText)||(null==S?void 0:S.blocked
.draftText)&&es(w),R(!0)):w||(null==S?void 0:S.blocked
```

Pattern compile preserve LIVE runtime.

### Markers PH-20.11B + parent wire (preserve)

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

### KEY-263 DEV isolation + KEY-302 sentinel

| Indicateur | Count | Verdict |
|---|---|---|
| api-dev.keybuzz.io | 87 | OK |
| api.keybuzz.io PROD pattern | 0 | OK isolation respectee |
| `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | OK |

## E7 LOGS

| Pattern | Count | Verdict |
|---|---|---|
| TypeError | 0 | OK |
| ReferenceError | 0 | OK |
| ChunkLoadError | 0 | OK |
| unhandled | 0 | OK |
| Startup | "Ready in 362ms" | OK |

## E8 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | DEV | **v3.5.214-ai-draft-blocked-reason-dev** | **NOUVEAU LIVE (cible deployee)** |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |

Aucun deploy supplementaire. Aucun kubectl set/patch/edit.

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Etat | Verdict |
|---|---|---|
| Brouillon IA visible quand DRAFT_GENERATED | preserve | OK |
| Brouillon IA blockedInfo auto-open PH-20.11B | preserve (pattern compile LIVE) | OK |
| **Trame de reponse securisee (NOUVEAU PH-20.11C)** | **LIVE 7/7 markers** | **enrichissement** |
| Copier la trame (clipboard local) | LIVE | OK |
| Suggestion IA fallback (sans draft) | preserve | OK |
| Aide IA manuelle | preserve (10) | OK |
| KEY-305 race UI fix preserve | dans pattern compile | OK |
| Doctrine seller-first/refund-protection | INCHANGE 100% | OK |
| Wallet/KBActions modifie | NON | OK |
| Aucun changement send/reply/consume | confirmed | OK |
| KEY-263 isolation DEV/PROD strict | OK | OK |

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
- AUCUN deploy PROD.
- AUCUN restart pod hors rollout normal.
- AUCUN kubectl set/patch/edit (GitOps strict apply -f).
- AUCUN changement API/Backend/Website/Admin.
- AUCUN changement source au-dela commit 1a30ad9.
- AUCUN faux event / register / checkout / lead.
- AUCUN appel LLM reel.
- AUCUNE consommation KBActions.
- AUCUN secret/token/PII affiche.
- AUCUN Linear ticket statut modifie.
- AUCUN seuil guardrail modifie.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- Doctrine seller-first INCHANGE 100% (autopilotGuardrails.ts non touche).
- KEY-305 fix race UI preserve.
- KEY-263 isolation DEV/PROD respectee.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK DEV DOCUMENTE (non execute)

Si regression observee :
```
cd /opt/keybuzz/keybuzz-infra
# Editer k8s/keybuzz-client-dev/deployment.yaml -> image v3.5.213-ai-draft-blocked-reason-dev
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "ops(client-dev): ROLLBACK PH-20.11C-GUARDRAIL-GUIDANCE to v3.5.213"
git push origin main
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s
```

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Services

| Service | Avant | Apres | Verdict |
|---|---|---|---|
| Client DEV | v3.5.213-ai-draft-blocked-reason-dev | **v3.5.214-ai-draft-blocked-reason-dev** | OK NOUVEAU LIVE |
| Client PROD | v3.5.201 | inchange | OK |
| API DEV | v3.5.254 | inchange | OK LIVE |
| API PROD | v3.5.252 | inchange | OK |

### 2. Manifest + Apply

| Manifest | Commit | Apply | Rollout | Verdict |
|---|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | 4dcb58b | OK | successfully rolled out | OK |

### 3. Pod / Digest

| Pod | Digest runtime | Digest GHCR | Match | Verdict |
|---|---|---|---|---|
| keybuzz-client-7c65567649-nsh5f | sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff | sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff | OK | MATCH |

### 4. Bundle markers

| Marker | Count | Verdict |
|---|---|---|
| **GUIDANCE PH-20.11C : Trame/Point depart/sans generation IA/consommation KBActions/ne peux pas confirmer/remboursement remplacement/Copier la trame** | **2/2/2/2/2/2/4** | LIVE 7/7 |
| Pattern compile autoOpen `draftText \|\| blocked` | PRESENT (2 occurrences distinctes) | preserve PH-20.11B |
| blockedInfo / Garde-fou actif / Brouillon IA bloque / Validation humaine | 4/2/2/2 | preserve |
| Brouillon IA / Suggestion IA / Aide IA | 6/4/10 | preserve |
| api-dev / api.keybuzz.io PROD / sentinel | 87/0/0 | OK |

### 5. Logs

| Pattern | Count | Verdict |
|---|---|---|
| TypeError / ReferenceError / ChunkLoadError / unhandled | 0/0/0/0 | OK |
| Startup "Ready in 362ms" | OK | OK |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build/push | OUI | aucun build/push run |
| deploy PROD | OUI | runtime PROD inchange |
| kubectl set/patch/edit/delete | OUI | uniquement apply -f + get + rollout status |
| restart pod manuel | OUI | rollout normal |
| LLM call / /ai/assist / /draft/consume | OUI | 0 |
| fake event/metric/KBActions | OUI | 0 |
| mutation DB | OUI | aucun acces DB |
| changement Linear statut | OUI | comment only |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO APPLY CLIENT GUARDRAIL GUIDANCE DEV READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | 1a30ad925fed3fb0b237e7b82694c2f839bc0778 |
| Image runtime DEV | v3.5.214-ai-draft-blocked-reason-dev |
| Runtime digest DEV | sha256:072e22e4d95d2dc60a35607d5e5875fada8274b2155f5361ab798fcf58662dff |
| Pod DEV | 7c65567649-nsh5f Ready 1/1 0 restart |
| Triple match | OK |
| Commit infra manifest | 4dcb58b push origin/main |
| Smokes /api/healthz + / pod | HTTP 200 / 200 |
| Guidance PH-20.11C LIVE bundle | OK 7/7 markers |
| AutoOpen PH-20.11B preserve | OK pattern compile LIVE |
| AI feature parity | preserve (6/4/10) |
| KEY-263 isolation DEV/PROD | OK (87/0) |
| KEY-302 sentinel | 0 |
| Logs DEV | 0 erreur, "Ready in 362ms" |
| Runtime PROD + API DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA CLIENT GUARDRAIL GUIDANCE DEV PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

(QA browser Ludovic sur conversation reelle bloquee SWITAA pour observer drawer auto-ouvert + carte amber Garde-fou actif + sous-bloc Trame de reponse securisee + bouton Copier la trame)

STOP. Aucun PROD, aucun LLM, aucune KBActions, aucun changement Linear statut.
