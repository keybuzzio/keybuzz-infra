# PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-APPLY-DEV-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related) ; KEY-263 (DEV/PROD isolation) ; KEY-302 (build args) ; KEY-308 (OCI) ; KEY-309 (tag immuable)
> Phase : PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX APPLY Client DEV GitOps strict
> Environnement : DEV only (aucun PROD, aucun LLM, aucune KBActions)

## VERDICT

GO APPLY CLIENT AI DRAFT AUTOOPEN ESCALATION DEV READY PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX

- Manifest `k8s/keybuzz-client-dev/deployment.yaml` bumpe v3.5.212 -> v3.5.213-ai-draft-blocked-reason-dev.
- Infra commit manifest `2cb8610` push origin/main.
- kubectl apply OK -> rollout `deployment "keybuzz-client" successfully rolled out`.
- Pod nouveau unique **`keybuzz-client-6cd86c9796-bdht4`** Ready 1/1, 0 restart.
- Runtime digest DEV : `sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462` MATCH GHCR manifest digest.
- Triple match parfait : last-applied = manifest spec = pod imageID.
- Smokes pod : `/api/healthz` HTTP 200 (chunked), `/` HTTP 200 9046 bytes.
- **Pattern compile autoopen LIVE dans bundle runtime** : `.draftText)||(null==S?void 0:S.blocked` + `:w||(null==S?void 0:S.blocked` confirme le fix actif.
- Markers PH-20.11B preserve : `blockedInfo=4, Garde-fou actif=2, Brouillon IA bloque par securite=2, Validation humaine recommandee=2`.
- AI feature parity preserve : `Brouillon IA=6, Suggestion IA=4, Aide IA=10`.
- KEY-263 DEV isolation strict : `api-dev.keybuzz.io=87, api.keybuzz.io PROD=0`.
- KEY-302 sentinel `__MUST_BE_SET_BY_BUILD_ARG__=0`.
- Logs Client DEV : 0 TypeError, 0 ReferenceError, 0 ChunkLoadError, 0 unhandled.
- Startup OK : "Ready in 404ms".
- Runtime API DEV+PROD + Client PROD INCHANGES.

**La stack PH-20.11B-AUTOOPEN-FIX est maintenant LIVE en DEV. La carte UX `Garde-fou actif` doit desormais s'auto-ouvrir pour les conversations PRE_LLM_BLOCKED/ESCALATION_DRAFT.**

STOP avant QA browser Ludovic.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T00:16:54Z |
| kube-context | kubernetes-admin@kubernetes |
| keybuzz-infra HEAD avant | ba4f4f6 |
| keybuzz-infra HEAD apres bump | **2cb8610** |
| Runtime Client DEV avant | v3.5.212-ai-draft-blocked-reason-dev |
| Runtime API DEV avant | v3.5.254-ai-draft-blocked-reason-dev LIVE |

## E1 GHCR DIGEST VERIFY

| Item | Valeur | Verdict |
|---|---|---|
| Image GHCR | ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev | OK |
| Config digest | sha256:3158c38651e1b6b68650e589e383f848b3b57eeb3874dffee7035d65de34fffb | OK MATCH expected |
| Manifest digest | sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 | OK MATCH expected |
| OCI revision | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 | OK |

## E2 BUMP MANIFEST GITOPS

| Item | Valeur |
|---|---|
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Image apres bump | `image: ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev` + annotation PH-20.11B-AUTOOPEN-FIX avec KEY-312/305/235/231/263/302, commit d132cc4f, manifest digest GHCR, rollback |
| Dry-run server | `deployment.apps/keybuzz-client configured (server dry run)` |
| Commit infra | `2cb8610` chore(client): deploy PH-20.11B autoopen fix DEV |
| Push | OK ba4f4f6..2cb8610 main -> main |

## E3 APPLY DEV + ROLLOUT

| Item | Valeur |
|---|---|
| kubectl apply | `deployment.apps/keybuzz-client configured` |
| Rollout status | `deployment "keybuzz-client" successfully rolled out` |
| Pod nouveau unique | **keybuzz-client-6cd86c9796-bdht4** Ready 1/1, 0 restart |

### Triple match Client DEV

| Source | Valeur | Verdict |
|---|---|---|
| last-applied annotation | ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev | OK |
| manifest spec | ghcr.io/keybuzzio/keybuzz-client:v3.5.213-ai-draft-blocked-reason-dev | OK |
| pod imageID | ghcr.io/keybuzzio/keybuzz-client@sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 | OK MATCH GHCR |

## E5 SMOKES POD

| Endpoint | HTTP | Bytes | Verdict |
|---|---|---|---|
| /api/healthz | 200 | chunked | OK |
| / | 200 | 9046 | OK |

## E6 BUNDLE RUNTIME AUDIT (/app/.next pod)

### Pattern compile AUTOOPEN-FIX LIVE

```
.draftText)||(null==S?void 0:S.blocked
.draftText)&&er(w),R(!0)):w||(null==S?void 0:S.blocked
```

Pattern compile minifie `(initialDraft?.draftText || blockedInfo?.blocked)` + branche reset conditionnel `w || blockedInfo?.blocked || setActiveDraft(null)` PRESENT runtime LIVE.

### Markers PH-20.11B + parent wire

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
| Startup | "Ready in 404ms" | OK |

## E8 RUNTIME NON-REGRESSION

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | DEV | **v3.5.213-ai-draft-blocked-reason-dev** | **NOUVEAU LIVE (cible deployee)** |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |

Aucun deploy supplementaire. Aucun kubectl set/patch/edit.

## AI FEATURE PARITY / ANTI-REGRESSION

| Promesse | Etat | Verdict |
|---|---|---|
| Brouillon IA visible quand DRAFT_GENERATED | preserve | OK |
| **Brouillon IA blockedInfo auto-open PRE_LLM_BLOCKED/ESCALATION_DRAFT** | **LIVE (pattern compile + bundle markers)** | **FIX** |
| Suggestion IA fallback (sans draft) | preserve | OK |
| Aide IA manuelle | preserve (10) | OK |
| KEY-305 race UI fix preserve | dans pattern compile (`es.current!==d`) | OK |
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
- AUCUN changement source au-dela commit d132cc4f.
- AUCUN faux event / register / checkout / lead.
- AUCUN appel LLM reel.
- AUCUNE consommation KBActions.
- AUCUN secret/token/PII affiche.
- AUCUN Linear ticket statut modifie.
- AUCUN seuil guardrail modifie.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- Doctrine seller-first INCHANGE 100%.
- KEY-305 fix race UI preserve.
- KEY-263 isolation DEV/PROD respectee.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK DEV DOCUMENTE (non execute)

Si regression observee :
```
cd /opt/keybuzz/keybuzz-infra
# Editer k8s/keybuzz-client-dev/deployment.yaml -> image v3.5.212-ai-draft-blocked-reason-dev
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "ops(client-dev): ROLLBACK PH-20.11B-AUTOOPEN-FIX to v3.5.212"
git push origin main
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=300s
```

INTERDIT : kubectl set image, git reset --hard, git clean.

## TABLEAUX FINAUX

### 1. Services

| Service | Avant | Apres | Verdict |
|---|---|---|---|
| Client DEV | v3.5.212-ai-draft-blocked-reason-dev | **v3.5.213-ai-draft-blocked-reason-dev** | OK NOUVEAU LIVE |
| Client PROD | v3.5.201 | inchange | OK |
| API DEV | v3.5.254 | inchange | OK LIVE |
| API PROD | v3.5.252 | inchange | OK |

### 2. Manifest + Apply

| Manifest | Commit | Apply | Rollout | Verdict |
|---|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | 2cb8610 | OK | successfully rolled out | OK |

### 3. Pod / Digest

| Pod | Digest runtime | Digest GHCR | Match | Verdict |
|---|---|---|---|---|
| keybuzz-client-6cd86c9796-bdht4 | sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 | sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 | OK | MATCH |

### 4. Bundle markers

| Marker | Count | Verdict |
|---|---|---|
| Pattern compile `draftText \|\| blocked` autoopen | PRESENT (2 occurrences distinctes) | LIVE |
| blockedInfo | 4 | preserve |
| Garde-fou actif / Brouillon IA bloque / Validation humaine | 2/2/2 | preserve |
| Brouillon IA / Suggestion IA / Aide IA | 6/4/10 | preserve |
| api-dev / api.keybuzz.io PROD / sentinel | 87/0/0 | OK |

### 5. Logs

| Pattern | Count | Verdict |
|---|---|---|
| TypeError / ReferenceError / ChunkLoadError / unhandled | 0/0/0/0 | OK |
| Startup "Ready in 404ms" | OK | OK |

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
| Verdict | GO APPLY CLIENT AI DRAFT AUTOOPEN ESCALATION DEV READY PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | d132cc4f1a83da8185196b1b9faaa6e00ef4e1b6 |
| Image runtime DEV | v3.5.213-ai-draft-blocked-reason-dev |
| Runtime digest DEV | sha256:f7c4615aa1cb7992e21cef5aea15b11e5904bea953b80abd9567a71176e84462 |
| Pod DEV | 6cd86c9796-bdht4 Ready 1/1 0 restart |
| Triple match | OK |
| Commit infra manifest | 2cb8610 push origin/main |
| Smokes /api/healthz + / pod | HTTP 200 / 200 |
| Pattern autoopen LIVE bundle | OK (draftText)||(blocked) compile present |
| AI feature parity | preserve (6/4/10) |
| KEY-263 isolation DEV/PROD | OK (87/0) |
| KEY-302 sentinel | 0 |
| Logs DEV | 0 erreur, "Ready in 404ms" |
| Runtime PROD + API DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX-CLIENT-APPLY-DEV-01.md` |

### Prochaine phrase GO attendue

`GO QA CLIENT AI DRAFT AUTOOPEN ESCALATION DEV PH-SAAS-T8.12AS.20.11B-AUTOOPEN-FIX`

(QA browser Ludovic sur conversation reelle bloquee cmmphi008y8f98ba07... SWITAA pour observer drawer auto-ouvert + carte amber Garde-fou actif)

STOP. Aucun PROD, aucun LLM, aucune KBActions, aucun changement Linear statut.
