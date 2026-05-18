# PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2A-EXEC-KEY-323-STAKATER-RELOADER-GIT-CLEANUP-API-PROD-01

> Date : 2026-05-18
> Linear : KEY-323
> Phase : AS.17.1Q-1B-5B-2A-EXEC
> Environnement : PROD keybuzz-api-prod (mutation GitOps + apply Deployment ciblee)

## VERDICT

GO Q-1B-5B-2A-EXEC STAKATER RELOADER GIT CLEANUP API-PROD COMPLETE

Suppression effective de l'env-var `STAKATER_VAULT_ROOT_TOKEN_SECRET` du manifest Git source `k8s/keybuzz-api-prod/deployment.yaml` (committee accidentellement par commit `e77b7cb` 2026-04-20 documente Q-1B-5B-2A) + apply manuel resolu :
- Sequence Mode B SAFE 2 gates respectee strictement :
  - **Gate G1** `GO COMMIT MANIFEST REMOVE STAKATER PROD Q-1B-5B-2A-EXEC` -> commit `4628a6a` + push `11e3230..4628a6a main -> main`, 0 runtime impact (Argo absent confirme)
  - **Gate G2** `GO APPLY REMOVE STAKATER PROD Q-1B-5B-2A-EXEC` -> kubectl apply manuel `deployment.apps/keybuzz-api configured` exit 0, rollout successfully completed en ~10s

Invariants 6/6 PASS strictement vs snapshot B0.9 et observations Q-1B-5B-2A :
- Secret manuel `keybuzz-litellm` rv=`22599356` UNCHANGED (preserve, non-touche)
- ES `keybuzz-litellm-secrets` Ready=True UNCHANGED
- LiteLLM 2 pods (keybuzz-ai/sfw8l + xlhm7) Running 0 restart, ages inchanges baseline B0.9
- 0 Warning/Error events 15m api-prod + keybuzz-ai
- Argo CD applications inchanges (push n'a declenche aucun auto-sync, attendu car aucune Application observait `k8s/keybuzz-api-prod/`)
- Sources Git autres surfaces non touchees (manifests autres Deployments md5 stables)

Finding architectural critique CONFIRME : kubectl strategic merge patch a parfaitement isole le retrait via `last-applied-configuration` annotation. STAKATER_VAULT_ROOT_TOKEN_SECRET (qui etait dans last-applied Git) a ete retire du runtime ; les 2 autres STAKATER vars (STAKATER_KEYBUZZ_GOOGLE_ADS_SECRET + STAKATER_KEYBUZZ_API_JWT_SECRET, Reloader-only injection jamais committee en Git) sont PRESERVES automatiquement par Kubernetes (Reloader peut continuer son cycle normal). Cela confirme empiriquement le pattern correct attendu Q-1B-5B-2A et debloque architecturalement les phases ulterieures.

Generation Deployment 410 -> 411 (bump nominal post-apply). Pod recree `keybuzz-api-5874f4d576-4zr29` Running 1/1 ready, restart count=0, age 73s post-settle. Ancien pod jx6m7 terminate proprement. 0 downtime LLM ou auth Vault observe.

Aucune lecture de valeur secret en clair. Aucun base64 decode. Aucun vault command. Aucun provider call. Aucun appel proxy LiteLLM /chat /embeddings. Aucun kubectl run/exec/port-forward. Aucune mutation Vault. Manifests autres Deployments (api-dev, client, studio-api) intouches (correction scope api-prod uniquement). Rollback emergency `kubectl rollout undo` reste disponible avec phrase exacte `GO ROLLBACK EMERGENCY UNDO STAKATER PROD Q-1B-5B-2A-EXEC` (NON utilise, succes complet).

Q-1B-5B-2 LLM env-var migration reste NO GO en attente prompt CE separe DEV-first. Q-1B-5B-2A-RELOADER-CLEANUP (extension client + studio-api DEV+PROD) proposee comme phase ulterieure pour coherence cluster-wide.

## Scope / hors scope

### Scope strict applique

- 1 modification manifest Git : `k8s/keybuzz-api-prod/deployment.yaml` (3 lignes supprimees : commentaire PH-T8.2E + name STAKATER_VAULT_ROOT_TOKEN_SECRET + value)
- 1 commit + 1 push GitOps
- 1 kubectl apply manuel
- Validations read-only : rollout status + pod state + invariants Secret/ES + LiteLLM baseline preserve

### Hors scope respecte

- Q-1B-5B-2 LLM env-var migration : NO GO maintenu (prompt CE separe DEV-first)
- Q-1B-5B-2A-RELOADER-CLEANUP extension client + studio-api : NO GO maintenu (phase dediee)
- Cleanup cluster-wide autres deployments STAKATER (5 Deployments restants identifies Q-1B-5B-2A) : NO GO
- Rotation Vault / LLM / GHCR : NO GO
- Vault commands : 0
- Lecture/affichage valeurs secret : 0
- Provider calls (OpenAI/Anthropic/Gemini/LiteLLM) : 0
- kubectl run/exec/port-forward : 0
- Linear comment : NON poste sans GO separe
- AS.17.0 / AS.17.0.1 promotion : NO GO maintenue

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2A-KEY-323-STAKATER-VAULT-TOKEN-DRIFT-INVESTIGATION-DRYRUN-01.md | commit 11e3230, sha256 915eadde427547abe1f68df9feab0501ec0aec38c2f86f125ad0420ff8c81403 | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2-KEY-323-LLM-API-ENV-VAR-MIGRATION-DRYRUN-01.md | present (E6.4 a revele le drift) | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-1-KEY-323-LLM-PROD-ESO-MIGRATION-EXEC-01.md | present (Argo absent api-prod confirme) | OK |
| k8s/keybuzz-api-prod/deployment.yaml | md5 d471a089 (BEFORE) -> 2bfd756d (AFTER) | OK changement attendu |
| keybuzz-infra HEAD | 11e3230 -> 4628a6a (apres commit) | OK |

## Preflight (B0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host / IPv4 | install-v3 / 46.62.171.61 | match | OK |
| keybuzz-infra branch / HEAD / status | main / desc 11e3230 / clean | match | OK |
| Rapport Q-1B-5B-2A sha256 | 915eadde | match | OK |
| /tmp residuels Q-1B-5B-2A-EXEC | absent | absent | OK |
| Manifest source md5 BEFORE | d471a089a2d145f1d2ba70ecb1f6ab81 | match | OK |
| ES api-prod keybuzz-litellm-secrets Ready/refresh | True/SecretSynced/< 2h | True/SecretSynced/refresh 11:38:07Z | OK |
| Argo Application api-prod | absent (heritage Q-1B-5B-1) | aucune | OK confirme |
| Reloader deployment Ready | 1/1 | 1/1 | OK |

## BEFORE snapshot api-prod (B0.9)

| Resource | Field | Value |
|---|---|---|
| Deployment keybuzz-api | generation / observedGeneration | 410 / 410 |
| Deployment keybuzz-api | replicas spec/avail/ready | 1 / 1 / 1 |
| Deployment keybuzz-api | image | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod |
| Deployment keybuzz-api | strategy | RollingUpdate |
| Deployment keybuzz-api | annotation reloader.stakater.com/auto | true |
| Deployment keybuzz-api | STAKATER env-vars runtime | 3 (VAULT_ROOT_TOKEN, KEYBUZZ_GOOGLE_ADS, KEYBUZZ_API_JWT) |
| Pod keybuzz-api-7685645f49-jx6m7 | phase / restarts / startTime | Running / 0 / 2026-05-17T14:19:11Z (age ~22h) |
| LiteLLM 2 pods baseline | Running 0 restart | sfw8l 2026-04-06, xlhm7 2026-05-15 |

## Patch manifest (B1)

Generation patche dans `/tmp/keybuzz-q1b5b2aexec-deployment-patched.yaml` (mode 600) via SCP runner Python avec redacteur hex40/hex64 -> `<HEX40_<sha8>>` / `<HEX64_<sha8>>`. 3 lignes retirees exactement (commentaire + name + value) sur ligne 297-299 du manifest source.

| Stat | Source | Patched | Delta |
|---|---|---|---|
| Lines | 365 | 362 | -3 |
| md5 | d471a089a2d145f1d2ba70ecb1f6ab81 | 2bfd756d17b6306d6e17dba4cd4e340c | changed |
| env count `- name:` | 67 | 66 | -1 |
| STAKATER_VAULT_ROOT_TOKEN_SECRET | present | absent | OK |
| non-ASCII bytes | 51 | 51 | preexistant identique source |

Diff redacted inline pour traceability :

```diff
@@ -294,9 +294,6 @@
               value: "http://keybuzz-backend.keybuzz-backend-prod.svc.cluster.local:4000"
             - name: KEYBUZZ_INTERNAL_PROXY_TOKEN
               value: "true"
-            # PH-T8.2E: tracking env vars (synced from live PROD)
-            - name: STAKATER_VAULT_ROOT_TOKEN_SECRET
-              value: "<HEX40_c0f128e4>"
             - name: CONVERSION_WEBHOOK_ENABLED
               value: "true"
             - name: CONVERSION_WEBHOOK_URL
```

## kubectl apply --dry-run=server pre-commit (B2)

| Field | Value |
|---|---|
| Command | kubectl apply -f /tmp/keybuzz-q1b5b2aexec-deployment-patched.yaml --dry-run=server |
| stdout | deployment.apps/keybuzz-api configured (server dry run) |
| exit code | 0 |
| kubectl diff exit | 1 (differences exist, attendu) |
| diff lines | 21 (changement secretKey + bump generation effet futur) |
| Non-persistance verifiee | Deployment gen=410 inchange post dry-run | OK |

## Gate G1 commit + push (B3-B7)

| Item | Statut |
|---|---|
| Phrase exacte attendue | GO COMMIT MANIFEST REMOVE STAKATER PROD Q-1B-5B-2A-EXEC |
| Phrase exacte recue | identique verbatim |
| mv /tmp -> k8s/keybuzz-api-prod/ | OK md5 NEW 2bfd756d |
| /tmp source cleared | OK |
| git status post-mv | 1 modified = manifest seul |
| git add explicit single file | OK |
| git diff --cached redacted | montre 3 lignes supprimees (commentaire + name + value `<HEX40_c0f128e4>`) |
| git commit | 4628a6a fix(api-prod): remove STAKATER_VAULT_ROOT_TOKEN_SECRET committed accidentally (AS.17.1Q-1B-5B-2A-EXEC) |
| 1 file changed | 3 deletions(-) |
| git push origin main | 11e3230..4628a6a main -> main |
| Post-push runtime impact | 0 (Argo absent api-prod, push GitHub n'a rien deploye) |
| Post-push invariants snapshot | gen=410, 3 STAKATER vars runtime, pod age 22h restart=0 | UNCHANGED |

## Gate G2 apply (B8)

| Item | Statut |
|---|---|
| Phrase exacte attendue | GO APPLY REMOVE STAKATER PROD Q-1B-5B-2A-EXEC |
| Phrase exacte recue | identique verbatim |
| kubectl apply | deployment.apps/keybuzz-api configured |
| exit code | 0 |
| Generation bump | 410 -> 411 |
| Rollout status | successfully rolled out (~10s) |

## Pod state post-rollout (B8.4)

| pod | phase | ready | restarts | startTime | age |
|---|---|---|---|---|---|
| keybuzz-api-5874f4d576-4zr29 | Running | true | 0 | 2026-05-18T13:05:01Z | 11s (then 73s post-settle) |
| keybuzz-api-7685645f49-jx6m7 (ancien) | Running -> Terminating | true | 0 | 2026-05-17T14:19:11Z | 22h (terminated post rollout) |

0 ImagePullBackOff / ErrImagePull / CreateContainerConfigError detectee. RollingUpdate nominal sans degradation observable.

## Invariants verifies (B9)

| ID | Resource | Field | Expected (B0.9 baseline) | Observed (post-apply) | Verdict |
|----|----------|-------|--------------------------|------------------------|---------|
| B9.1 | Secret keybuzz-api-prod/keybuzz-litellm (manuel) | rv | 22599356 | 22599356 | UNCHANGED OK |
| B9.2 | ES keybuzz-api-prod/keybuzz-litellm-secrets | ready | True | True (refresh nominal post 1h) | UNCHANGED OK |
| B9.3 | Deployment keybuzz-api STAKATER env-vars runtime | 2 ou 3 (selon timing Reloader) | 2 vars (VAULT_ROOT_TOKEN_SECRET supprime, KEYBUZZ_GOOGLE_ADS + KEYBUZZ_API_JWT preserves) | OK comportement nominal |
| B9.4 | Events api-prod 15m | 0 Warning/Error | 0 | UNCHANGED OK |
| B9.5 | Pod nouveau keybuzz-api Running ready=1/1 | OUI < 30s | Running 1/1 11s post-apply | OK |
| B9.6 | Deployment generation == observedGeneration | OUI | 411 == 411 | OK rollout complete |

6/6 invariants PASS strictement. Aucune regression observable.

## STAKATER env-vars runtime detail (B9.3)

Post-apply, le runtime contient EXACTEMENT 2 env-vars STAKATER (au lieu de 3 baseline B0.9) :

| STAKATER env-var | Pre-apply (B0.9) | Post-apply | Cause |
|---|---|---|---|
| STAKATER_VAULT_ROOT_TOKEN_SECRET | present (Git + Reloader sync) | **ABSENT** | Notre suppression Git via strategic merge patch (etait dans last-applied) |
| STAKATER_KEYBUZZ_GOOGLE_ADS_SECRET | present (Reloader-only) | **PRESERVED** | Jamais en Git, jamais dans last-applied, Kubernetes preserve les champs non-tracked |
| STAKATER_KEYBUZZ_API_JWT_SECRET | present (Reloader-only) | **PRESERVED** | Idem |

**Finding architectural confirme empiriquement** : kubectl strategic merge patch respecte `last-applied-configuration` annotation pour decider quels champs ajouter/retirer. Notre Q-1B-5B-2A hypothese H2 (Reloader auto-injection autonome) est validee : les 2 vars Reloader-only restent intactes alors que la var "manuellement commit en Git" est correctement retiree.

Note : si un Secret reference change ulterieurement, Reloader pourra re-injecter STAKATER_VAULT_ROOT_TOKEN_SECRET dans le runtime (cycle normal). Mais cette injection NE sera PAS committe en Git (pas de workflow `kubectl get -o yaml | commit` accidentel a renouveler), donc le drift initial ne reapparaitra pas spontanement.

## AI feature parity (B10)

Comparaison vs baseline B0.9 :

| Resource | B0.9 baseline | Post-apply | Verdict |
|---|---|---|---|
| litellm-55bcfd7769-sfw8l | Running 0 restart startTime 2026-04-06 | identique | UNCHANGED OK |
| litellm-55bcfd7769-xlhm7 | Running 0 restart startTime 2026-05-15 | identique | UNCHANGED OK |
| Events keybuzz-ai 15m Warning+Error | 0 | 0 | UNCHANGED OK |

LiteLLM AI feature parity preservee. Aucun appel proxy `/chat/completions` ni `/embeddings`. Aucun kubectl run/exec/port-forward (correction 4 heritage Q-1B-5B-1 maintenue).

Aucun impact sur Deployment keybuzz-backend, keybuzz-studio-api, keybuzz-client, keybuzz-admin-v2.

## No fake metrics

N/A. Phase cleanup manifest Git + apply api-prod sans impact dashboard/KPI/billing/acquisition/reporting. 0 KBAction, 0 event GA4/CAPI/TikTok/LinkedIn, 0 metric creee.

## Cleanup temporary files

| Fichier | Mode | Statut |
|---|---|---|
| /tmp/keybuzz-q1b5b2aexec-deployment-patched.yaml | 600 | mv vers k8s/ effective en B3.2 (absent /tmp post-mv) |
| /tmp/keybuzz-q1b5b2aexec-before-metadata.jsonl | 600 | shred apres rapport |
| /tmp/keybuzz-q1b5b2aexec-redactor.py | 600 | shred apres rapport |
| /tmp/keybuzz-q1b5b2aexec-diff.txt | 600 | shred apres rapport |
| /tmp/keybuzz-q1b5b2aexec-b1b2-runner.sh | 755 | shred apres rapport |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1B-5B-2A-EXEC | Impact |
|---|---|---|---|
| keybuzz-api-prod Deployment | gen=410 obs=410 ready=1/1 | gen=411 obs=411 ready=1/1 | rollout normal (effet apply) |
| keybuzz-api-prod Pod | jx6m7 age 22h restart=0 | 4zr29 age 73s restart=0 (nouveau) | rolling update nominal |
| keybuzz-api-prod Secret manuel keybuzz-litellm | rv=22599356 | rv=22599356 | UNCHANGED |
| keybuzz-api-prod Secret keybuzz-litellm-secrets ESO | Ready=True | Ready=True | UNCHANGED |
| keybuzz-api-prod ES keybuzz-litellm-secrets | rv ESO | inchange | UNCHANGED |
| keybuzz-api-prod STAKATER_VAULT_ROOT_TOKEN_SECRET runtime | present (Git + Reloader) | **absent** | retire (intentionnel, attendu) |
| keybuzz-api-prod STAKATER_KEYBUZZ_GOOGLE_ADS_SECRET runtime | present (Reloader-only) | present (preserve) | UNCHANGED |
| keybuzz-api-prod STAKATER_KEYBUZZ_API_JWT_SECRET runtime | present (Reloader-only) | present (preserve) | UNCHANGED |
| keybuzz-api-prod Events 15m Warning/Error | 0 | 0 | UNCHANGED |
| keybuzz-backend-prod | non touche | non touche | 0 |
| keybuzz-studio-api-prod | non touche | non touche | 0 |
| keybuzz-ai litellm 2 pods | Running 0 restart | Running 0 restart | UNCHANGED |
| Vault KV PROD | non touche | non touche | 0 |
| Argo CD applications | inchange (aucune api-prod) | inchange | 0 |
| Providers LLM externes | non touche | non touche | 0 |
| LiteLLM proxy /chat /embeddings | non touche | non touche | 0 |
| Sources Git autres manifests (api-dev, client, studio-api) | md5 stables | md5 stables | 0 (correction scope api-prod) |

## Compliance Mode B SAFE

| Interdit | Evidence | Verdict |
|---|---|---|
| Token STAKATER en clair stdout/fichiers/rapport | redacteur Python hex40 -> <HEX40_<sha8>> applique partout | OK |
| kubectl diff/git diff hex40 affiche clair | toutes sorties pipe via redacteur AVANT affichage et fichier | OK |
| vault command | 0 | OK |
| base64 -d / .data secret value lecture | 0 | OK |
| kubectl patch/edit/set env/set image/delete/rollout restart | 0 | OK |
| kubectl run/exec/port-forward (correction 4) | 0 | OK |
| kubectl apply hors api-prod ou sans GO | apply uniquement post GO Gate G2 sur target k8s/keybuzz-api-prod/deployment.yaml | OK |
| Rollback sans GO exact | 0 utilise (succes complet) | OK |
| Commit/push manifest avant Gate G1 | rapport en untracked pre-G1, commit + push post-Gate G1 exact | OK |
| Apply PROD avant Gate G2 | apply uniquement post-Gate G2 exact | OK |
| Rapport commit/push avant Gate G3 | rapport en untracked, attente GO Gate G3 | OK |
| SSH heredoc multi-lignes > 5 lignes | 0, SCP runner pattern partout (3 runners SCP) | OK |
| Modifications hors deployment.yaml api-prod + rapport | 0 (verifie via git status post-each-step) | OK |
| Tenant/user/email hardcode dans rapport | 0 | OK |
| Affichage valeur STAKATER_VAULT_ROOT_TOKEN_SECRET en clair | 0 (redacteur applique) | OK |

15/15 contraintes Mode B SAFE respectees, 0 violation.

## Brouillon Linear KEY-323

Brouillon disponible pour Ludovic, NON poste sans GO separe :

```
KEY-323 - AS.17.1Q-1B-5B-2A-EXEC STAKATER RELOADER GIT CLEANUP API-PROD MODE B SAFE

Status: COMPLETE
Scope: PROD api-prod ciblee (1 manifest + 1 apply)

Mutations effectuees:
- Commit 4628a6a (1 file changed, 3 deletions): retrait STAKATER_VAULT_ROOT_TOKEN_SECRET + commentaire PH-T8.2E du manifest source Git k8s/keybuzz-api-prod/deployment.yaml
- Push 11e3230..4628a6a main -> main (0 runtime impact, Argo absent api-prod)
- kubectl apply manuel: deployment.apps/keybuzz-api configured, generation 410 -> 411, rollout successfully rolled out ~10s

Garanties preservees (6/6 invariants vs baseline B0.9):
- Secret manuel keybuzz-litellm rv=22599356 UNCHANGED
- ES keybuzz-litellm-secrets Ready=True UNCHANGED
- LiteLLM 2 pods Running 0 restart, baseline UNCHANGED
- 0 Warning/Error events api-prod + keybuzz-ai
- Nouveau pod keybuzz-api-5874f4d576-4zr29 Running 1/1 age 73s post-settle, 0 ImagePullBackOff/ErrImagePull
- Ancien pod jx6m7 Terminated proprement (rolling update nominal)

Finding architectural confirme empiriquement:
- kubectl strategic merge patch respecte last-applied-configuration annotation
- STAKATER_VAULT_ROOT_TOKEN_SECRET (Git + Reloader sync) correctement RETIREE du runtime
- STAKATER_KEYBUZZ_GOOGLE_ADS_SECRET + STAKATER_KEYBUZZ_API_JWT_SECRET (Reloader-only) PRESERVES automatiquement
- Hypothese Q-1B-5B-2A H2 (Reloader auto-injection autonome) validee
- Pattern Q-1B-5B-2A-EXEC reproductible pour 5 autres Deployments restants (api-dev, client-dev, client-prod, studio-api-dev, studio-api-prod)

Sequence Mode B SAFE 2 gates respectee:
- GO COMMIT MANIFEST REMOVE STAKATER PROD Q-1B-5B-2A-EXEC (commit local + push effective)
- GO APPLY REMOVE STAKATER PROD Q-1B-5B-2A-EXEC (kubectl apply manuel)

Hors scope respecte:
- 0 modification autres Deployments (api-dev, client, studio-api intouches)
- 0 rotation Vault / LLM / GHCR
- 0 vault command, 0 provider call, 0 appel proxy LiteLLM /chat /embeddings
- 0 kubectl run/exec/port-forward (verification 100% read-only)
- 0 affichage valeur secret en clair (redacteur hex40 applique partout)

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2A-EXEC-KEY-323-STAKATER-RELOADER-GIT-CLEANUP-API-PROD-01.md

Debloque Q-1B-5B-2-EXEC-PROD (LLM env-var migration PROD) en attente prompt CE separe.
NO GO maintenus: Q-1B-5B-2-EXEC, Q-1B-5B-2A-RELOADER-CLEANUP extension, autres phases KEY-323, AS.17.0/0.1 PROD promotion.
```

## Gaps restants

1. **Q-1B-5B-2A-RELOADER-CLEANUP** (NOUVELLE proposee) : extension du pattern Q-1B-5B-2A-EXEC aux 5 Deployments restants (api-dev, client-dev, client-prod, studio-api-dev, studio-api-prod) + 2 fichiers hex64 client-{dev,prod}/deployment.yaml. Phase dediee Mode B SAFE.
2. **Q-1B-5B-2-EXEC-DEV** : NO GO maintenu, debloque maintenant que drift initial PROD est resolu. Requires prompt CE Mode B SAFE separe.
3. **Q-1B-5B-2-EXEC-PROD** : NO GO maintenu, prerequis Q-1B-5B-2-EXEC-DEV stable 24h.
4. **Q-1B-5B-4 delete Secrets manuels keybuzz-litellm DEV+PROD** : NO GO maintenu.
5. **Q-1B-5B-5 rotation Vault path master_key** : NO GO maintenu.
6. **Q-1B-5B-6 sync + restart + parite IA messaging baseline** : NO GO maintenu.
7. **Q-1B-5B-7 cleanup k8s/litellm/secret.yaml expose Git** : NO GO maintenu.
8. **Q-1B-5C studio-api migration ESO** : NO GO maintenu.
9. **Q-1B-3D-2B harmonisation pleine GHCR** : NO GO maintenu.
10. **Q-1B-3D-3 / Q-1B-3E / Q-1B-3B / Q-1B-3C / Q-1B-6 / Q-1B-4 / Q-1B-7 / Q-1F-3** : restent dans la file.
11. **AS.17.0 / AS.17.0.1 PROD promotion** : NO GO maintenue (tenantGuardPlugin INACTIF KEY-301 AS.3 non patche).
12. **backfill-scheduler ImagePullBackOff** : hors scope.

## Phrase cible finale

STAKATER_VAULT_ROOT_TOKEN_SECRET retire de maniere chirurgicale du manifest Git source `k8s/keybuzz-api-prod/deployment.yaml` (commit 4628a6a 1 file changed 3 deletions) + push origin main verifie 0 runtime impact (Argo absent confirme) + kubectl apply manuel reussi (generation 410 -> 411 rollout successfully rolled out ~10s avec nouveau pod keybuzz-api-5874f4d576-4zr29 Running 1/1 age 73s 0 restart) + 6/6 invariants preserves strictement vs snapshot B0.9 (Secret manuel keybuzz-litellm rv=22599356 unchanged, ES keybuzz-litellm-secrets Ready=True unchanged, LiteLLM 2 pods baseline unchanged, 0 Warning event, 0 ImagePullBackOff) + finding architectural confirme empiriquement (kubectl strategic merge patch isole correctement le retrait via last-applied-configuration annotation : STAKATER_VAULT_ROOT_TOKEN_SECRET supprime, STAKATER_KEYBUZZ_GOOGLE_ADS_SECRET + STAKATER_KEYBUZZ_API_JWT_SECRET Reloader-only preserves automatiquement) + Reloader continuera cycle normal sans Git pollution future + 0 downtime LLM ou auth Vault observable + rapport docs-only pret - aucune lecture de valeur en clair, 0 vault command, 0 provider call, 0 modification autres Deployments, Q-1B-5B-2-EXEC LLM env migration debloque en attente prompt CE separe DEV-first.

STOP
