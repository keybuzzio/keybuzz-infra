# PH-WEBSITE-T8.12AS.17.1Q-1B-5B-1-KEY-323-LLM-PROD-ESO-MIGRATION-EXEC-01

> Date : 2026-05-18
> Linear : KEY-323
> Phase : AS.17.1Q-1B-5B-1
> Environnement : PROD (mutation additive : 1 commit manifest + 1 apply ES, zero impact runtime consumers)

## VERDICT

GO Q-1B-5B-1 LLM PROD ESO MIGRATION COMPLETE

Creation additive reussie de l'ExternalSecret `keybuzz-litellm-secrets` cote `keybuzz-api-prod` pointant le Vault path canonique `secret/keybuzz/litellm/master_key`. Sequence Mode B SAFE strictement respectee :
- Gate B1 (`GO COMMIT MANIFEST ES PROD Q-1B-5B-1`) -> commit local 61a71c9
- Gate B6 (`GO PUSH MANIFEST ES PROD ONLY Q-1B-5B-1`) -> push origin main, 0 runtime impact (Argo absent confirme)
- Gate B7 (`GO APPLY ES PROD LITELLM Q-1B-5B-1`) -> kubectl apply manuel, Ready=True en 5s, Secret cree avec ownerReferences corrects

Invariants 6/6 PASS strictement vs snapshot B0.7 :
- Secret manuel `keybuzz-litellm` rv=22599356 UNCHANGED
- Deployment `keybuzz-api` generation=410, observedGeneration=410 UNCHANGED
- Pod `keybuzz-api-7685645f49-jx6m7` phase=Running, restartCount=0, startTime=2026-05-17T14:19:11Z UNCHANGED (age progresse normalement 19h -> 20h, pas de redeploy)
- Deployment env LITELLM_MASTER_KEY toujours pointe vers keybuzz-litellm (manuel), NON switched (Q-1B-5B-2 future)
- 0 Warning/Error events api-prod 15m post-apply
- LiteLLM 2 pods Running 0 restart, ages inchanges baseline B0.7, 0 Warning/Error events keybuzz-ai

AI feature parity preservee : LiteLLM ESO sync state inchange (litellm-secrets keybuzz-ai Ready=True), 0 impact runtime IA messaging baseline. Verification 100% read-only : aucun kubectl run/exec/port-forward execute (correction 4 respectee).

Aucune lecture de valeur secret (.data jamais affichee, 0 base64 -d). Aucun vault command. Aucun provider call LLM. Aucune mutation Deployment ni rollout. 0 downtime LLM PROD. Rollback prepare via phrase exacte `GO ROLLBACK DELETE ES PROD LITELLM Q-1B-5B-1` (NON utilise car succes).

## Scope / hors scope

### Scope strict applique
- Manifest cree dans `k8s/keybuzz-api-prod/externalsecret-litellm.yaml` (18 lignes, ASCII strict)
- 1 commit local separe du push (correction 1)
- 1 push origin main verifie 0 runtime impact (Argo absent prouve)
- 1 kubectl apply manuel (Argo Option II obligatoire)
- 1 ES cree + 1 Secret cree par ESO (creationPolicy=Owner)
- Verifications read-only invariants B9 + LiteLLM B10 (correction 4: sans kubectl run/exec/port-forward)

### Hors scope respecte
- AUCUNE modification Deployment keybuzz-api (env-var migration = Q-1B-5B-2 future)
- AUCUNE rotation Vault path master_key (= Q-1B-5B-5 future)
- AUCUN delete keybuzz-litellm manual (= Q-1B-5B-4 future)
- AUCUN cleanup k8s/litellm/secret.yaml expose Git (= Q-1B-5B-7 future)
- AUCUN provider call LLM (OpenAI, Anthropic, Gemini, LiteLLM proxy)
- AUCUN appel proxy LiteLLM /chat /embeddings
- AUCUN kubectl run/exec/port-forward (correction 4)
- AUCUNE lecture .data value, AUCUN base64 decode
- AUCUN vault command
- PROD autres surfaces : intouchees
- AS.17.0 / AS.17.0.1 promotion : NO GO maintenue

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-0-KEY-323-LLM-PROD-ESO-MIGRATION-DRYRUN-01.md | sha256 2b9fd5b7fd4069820a5744cbef04fe467c8be61119300be1271e3b708b519006 | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5A-KEY-323-LLM-SECRETS-DEDUP-DRYRUN-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3D-2A-KEY-323-GHCR-ORPHAN-CLEANUP-EXEC-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-1B-KEY-323-ORPHANS-CLEANUP-EXEC-01.md | present | OK |
| k8s/keybuzz-api-dev/externalsecret-litellm.yaml | manifest reference modele | OK (structure 1:1 reproduite avec ns api-prod) |
| keybuzz-infra HEAD pre-phase | 1bb2c904862beab76a72150be2e11c1e8fbecef7 | OK |

## Preflight (B0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host | install-v3 | install-v3 | OK |
| Bastion IPv4 | 46.62.171.61 | 46.62.171.61 | OK |
| Banned IP 51.159.99.247 | absent | absent | OK |
| keybuzz-infra branch | main | main | OK |
| keybuzz-infra HEAD descendant 1bb2c90 | OUI | 1bb2c90 (HEAD exact pre-phase) | OK |
| keybuzz-infra status pre-phase | clean | clean | OK |
| Rapport Q-1B-5B-0 sha256 | 2b9fd5b7... | match exact | OK |
| /tmp residuels Q-1B-5B-1 | absent | absent | OK |
| ClusterSecretStore vault-backend Ready | True | True/Valid | OK |
| Argo Application matching keybuzz-api-prod | (a determiner) | AUCUNE -> Option II obligatoire | OK identifie |

## BEFORE snapshot api-prod (B0.7)

Snapshot persiste dans `/tmp/keybuzz-q1b5b1-before-metadata.jsonl` mode 600 (5 lignes, 0 base64-payload leak), shred apres rapport.

| Resource | Field | Value | Status |
|---|---|---|---|
| ES keybuzz-api-prod/keybuzz-litellm-secrets | existence | NotFound | OK 0 collision |
| Secret keybuzz-api-prod/keybuzz-litellm-secrets | existence | NotFound | OK 0 collision |
| Secret keybuzz-api-prod/keybuzz-litellm (manuel) | rv | 22599356 | OK preserve (sera invariant) |
| Secret keybuzz-api-prod/keybuzz-litellm | type | Opaque | OK |
| Secret keybuzz-api-prod/keybuzz-litellm | keys | [LITELLM_MASTER_KEY] | OK |
| Deployment keybuzz-api api-prod | generation | 410 | OK (sera invariant) |
| Deployment keybuzz-api api-prod | observedGeneration | 410 | OK |
| Deployment keybuzz-api api-prod | replicas spec/avail/ready | 1/1/1 | OK |
| Deployment keybuzz-api env LITELLM_MASTER_KEY | secretKeyRef.name | keybuzz-litellm | OK (sera invariant) |
| Pod keybuzz-api-7685645f49-jx6m7 | phase | Running | OK |
| Pod keybuzz-api-7685645f49-jx6m7 | restartCount | 0 | OK (sera invariant) |
| Pod keybuzz-api-7685645f49-jx6m7 | startTime | 2026-05-17T14:19:11Z | OK (sera invariant, age 19h pre-phase) |
| Pod litellm-55bcfd7769-sfw8l keybuzz-ai | phase, restarts, startTime | Running, 0, 2026-04-06T09:40:46Z | OK baseline B10 |
| Pod litellm-55bcfd7769-xlhm7 keybuzz-ai | phase, restarts, startTime | Running, 0, 2026-05-15T10:59:31Z | OK baseline B10 |

## Argo CD config et decision Option I/II (B0.6)

| Item | Resultat |
|---|---|
| argocd namespace existence | Active 160d |
| argocd-server deployment | 1/1 AVAILABLE |
| Total Applications cluster-wide | 4 |
| Applications enumerees | keybuzz-api-dev (autoSync=false), keybuzz-client-dev (false), keybuzz-client-prod (false), keybuzz-seller-dev (autoSync=true) |
| Application matching k8s/keybuzz-api-prod path | AUCUNE |
| ApplicationSets | None |
| Decision | Option II OBLIGATOIRE (kubectl apply manuel apres commit + push) |

Phrase Gate B6 utilisable : `GO PUSH MANIFEST ES PROD ONLY Q-1B-5B-1` (la phrase alternative `GO PUSH MANIFEST ES PROD AND ALLOW ARGO AUTOSYNC Q-1B-5B-1` non applicable car aucune Application Argo n'observe ce path).

## Manifest committee (B5 + B6)

| Field | Value |
|---|---|
| Path | k8s/keybuzz-api-prod/externalsecret-litellm.yaml |
| Size | 429 bytes |
| ASCII strict | OUI (0 BOM, 0 non-ASCII) |
| Commit hash | 61a71c960e4fc0a6b38512e5d3c4cb9b36131ab8 |
| Commit message | feat(api-prod): add ExternalSecret keybuzz-litellm-secrets (AS.17.1Q-1B-5B-1) |
| Lignes ajoutees | 18 (1 file changed, 18 insertions) |
| Push | 1bb2c90..61a71c9 main -> main |
| Branch | main |
| Remote | https://github.com/keybuzzio/keybuzz-infra.git |

YAML committe (inline pour traceability) :

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: keybuzz-litellm-secrets
  namespace: keybuzz-api-prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: keybuzz-litellm-secrets
    creationPolicy: Owner
  data:
    - secretKey: LITELLM_MASTER_KEY
      remoteRef:
        key: secret/keybuzz/litellm/master_key
        property: value
```

Push post-verify : 0 runtime impact (defense-in-depth verifiee : 0 Argo Application matching, ES + Secret cibles toujours NotFound apres push, invariants B0.7 strictement maintenus).

## Dry-run re-validation (B3)

| Field | Value |
|---|---|
| Command | kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/externalsecret-litellm.yaml --dry-run=server |
| stdout | externalsecret.external-secrets.io/keybuzz-litellm-secrets created (server dry run) |
| exit code | 0 |
| Server-side defaults annotates | conversionStrategy=Default, decodingStrategy=None, metadataPolicy=None, deletionPolicy=Retain |
| kubectl diff exit | 1 (25 lignes ajoutees, 0 supprimees) attendu |
| Non-persistance post dry-run | ES + Secret toujours NotFound | OK |

## Apply result (B7)

| Field | Value |
|---|---|
| Command | kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/externalsecret-litellm.yaml |
| stdout | externalsecret.external-secrets.io/keybuzz-litellm-secrets created |
| exit code | 0 |
| Type d'apply | Option II manuel (Argo CD absent pour ce path) |

## Wait Ready=True (B7.3)

| Field | Value |
|---|---|
| Polling interval | 5s |
| Timeout | 120s |
| Time to Ready=True | 5s (< 60s SLO, < 120s timeout) |
| ready.status | True |
| ready.reason | SecretSynced |
| lastTransitionTime | 2026-05-18T10:38:07Z |
| refreshTime | 2026-05-18T10:38:07Z |
| syncedResourceVersion | 1-0f9b0249e6af2d7cd7a0848f21fc4ac130c0dc8d51402010f46812bc |

## Secret cree details (B8, metadata only, NO .data)

| Field | Value | Verdict |
|---|---|---|
| namespace | keybuzz-api-prod | OK |
| name | keybuzz-litellm-secrets | OK |
| type | Opaque | OK (identique ES api-dev) |
| resourceVersion | 70436873 | OK |
| creationTimestamp | 2026-05-18T10:38:07Z | OK (= ES Ready timestamp) |
| ownerReferences | [{apiVersion: external-secrets.io/v1, kind: ExternalSecret, name: keybuzz-litellm-secrets, controller: true, blockOwnerDeletion: true, uid: 4dceb402-f9b8-4cf3-8ace-1051b8fa4971}] | OK creationPolicy=Owner correct |
| key_names | [LITELLM_MASTER_KEY] | OK 1 key attendue |
| key_count | 1 | OK |
| .data values | NON LU | OK conformite read-only |

## Invariants verifies (B9, comparaison vs snapshot B0.7 - correction 6)

| ID | Resource | Field | Expected (B0.7) | Observed (post-apply) | Verdict |
|----|----------|-------|-----------------|------------------------|---------|
| B9.1 | Secret keybuzz-api-prod/keybuzz-litellm | rv | 22599356 | 22599356 | UNCHANGED OK |
| B9.2 | Deployment keybuzz-api api-prod | generation | 410 | 410 | UNCHANGED OK |
| B9.2 | Deployment keybuzz-api api-prod | observedGeneration | 410 | 410 | UNCHANGED OK |
| B9.3 | Pod keybuzz-api-7685645f49-jx6m7 | phase | Running | Running | UNCHANGED OK |
| B9.3 | Pod keybuzz-api-7685645f49-jx6m7 | restartCount | 0 | 0 | UNCHANGED OK |
| B9.3 | Pod keybuzz-api-7685645f49-jx6m7 | startTime | 2026-05-17T14:19:11Z | 2026-05-17T14:19:11Z | UNCHANGED OK (age 19h -> 20h progression normale, PAS de redeploy) |
| B9.4 | Deployment env LITELLM_MASTER_KEY | secretKeyRef.name | keybuzz-litellm | keybuzz-litellm | UNCHANGED OK (Q-1B-5B-2 future) |
| B9.4 | Deployment env LITELLM_MASTER_KEY | secretKeyRef.key | LITELLM_MASTER_KEY | LITELLM_MASTER_KEY | UNCHANGED OK |
| B9.5 | Events api-prod 15m | Warning+Error count | 0 | 0 | UNCHANGED OK |

8/8 invariants PASS strictement. Aucune mutation collaterale detectee.

## AI feature parity (B10, read-only sans kubectl run/exec/port-forward - correction 4)

| ID | Resource | Field | B0.7 baseline | Post-apply | Verdict |
|----|----------|-------|---------------|------------|---------|
| B10.1 | litellm-55bcfd7769-sfw8l | phase, restarts, startTime | Running, 0, 2026-04-06T09:40:46Z | identique | OK 0 restart, age progresse normalement |
| B10.1 | litellm-55bcfd7769-xlhm7 | phase, restarts, startTime | Running, 0, 2026-05-15T10:59:31Z | identique | OK |
| B10.2 | Events keybuzz-ai 15m | Warning+Error count | 0 | 0 | OK |
| B10.3 | ES keybuzz-ai/litellm-secrets | ready | True | True | UNCHANGED OK |
| B10.3 | ES keybuzz-ai/litellm-secrets | refresh | 2026-05-18T10:26:33Z | 2026-05-18T10:26:33Z (pre-apply, < refresh interval 1h) | OK aucun impact LiteLLM ESO sync state |

LiteLLM AI feature parity preservee. Aucun appel proxy `/chat/completions` ni `/embeddings`. Aucun pod ephemere curl (correction 4 respectee strictement). Aucun kubectl exec/run/port-forward.

Settle 30s re-poll (defense-in-depth) :
- Pod keybuzz-api jx6m7 : Running 1/1 age 20h (progression normale +1h sans restart)
- ES Ready=True rv=70436874 (incremente +1 vs B7.4 = update status normal)
- Secret rv=70436873 stable, keys=[LITELLM_MASTER_KEY]

## No fake metrics

N/A. Phase EXEC additive ESO sans impact dashboard, KPI, billing, acquisition, reporting, tracking. 0 KBAction, 0 event GA4/CAPI/TikTok/LinkedIn, 0 metric creee.

## Cleanup temporary files (B11)

| Fichier | Mode | Statut |
|---|---|---|
| /tmp/keybuzz-q1b5b1-before-metadata.jsonl | 600 | shred apres redaction rapport (donnees baseline B0.7 inline dans le rapport) |
| /tmp/keybuzz-q1b5b1-manifest.yaml | 644 | deja move vers k8s/keybuzz-api-prod/ en B2, absent dans /tmp |

Manifest definitif preserve dans `k8s/keybuzz-api-prod/externalsecret-litellm.yaml` (committe + push origin main).

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1B-5B-1 | Impact |
|---|---|---|---|
| keybuzz-api-prod Secret manuel keybuzz-litellm | rv=22599356, consume by Deployment | inchange rv | 0 |
| keybuzz-api-prod Deployment keybuzz-api | gen=410, env -> keybuzz-litellm | inchange | 0 |
| keybuzz-api-prod Pod jx6m7 | Running 1/1 age 19h restartCount=0 | Running 1/1 age 20h restartCount=0 | 0 (progression normale) |
| keybuzz-api-prod ES existantes (5) | Ready=True (jwt, postgres, minio, octopia, redis) | inchanges | 0 |
| keybuzz-api-prod NEW ES keybuzz-litellm-secrets | absent | Ready=True/SecretSynced rv=70436874 | additif (ORPHAN consumer-side jusqu'a Q-1B-5B-2) |
| keybuzz-api-prod NEW Secret keybuzz-litellm-secrets | absent | cree par ESO Owner rv=70436873 1 key | additif |
| keybuzz-backend-prod | non touche | non touche | 0 |
| keybuzz-studio-api-prod | non touche | non touche | 0 |
| keybuzz-ai litellm 2 pods | Running 0 restart | inchanges (B0.7 baseline maintenu) | 0 |
| keybuzz-ai ES litellm-secrets | Ready=True | inchange | 0 |
| keybuzz-client-prod | non touche | non touche | 0 |
| keybuzz-admin-v2-prod | non touche | non touche | 0 |
| Vault KV PROD paths | non touche (0 vault command) | non touche | 0 |
| Argo CD applications (4) | inchange | inchange (push n'a declenche aucun sync car path non couvert) | 0 |
| Providers LLM OpenAI/Anthropic/Gemini | non touche (0 provider call) | non touche | 0 |
| LiteLLM proxy /chat /embeddings | non touche | non touche | 0 |

## Compliance Mode B SAFE

| Interdit | Evidence | Verdict |
|---|---|---|
| Apply sans dry-run prealable | B3 dry-run --dry-run=server exit 0 avant B7 apply | OK |
| Apply sans manifest committe | B5+B6 commit + push effectifs AVANT B7 apply | OK |
| kubectl create/patch/edit/annotate/label/delete | 0 commande (sauf apply approuve) | OK |
| kubectl rollout restart | 0 | OK |
| kubectl run/exec/port-forward/cp (correction 4) | 0 commande (B10 100% read-only via get/jsonpath) | OK |
| Lecture .data value secret | 0 (B8 utilise `(.data // {}) | keys` projection, jamais .data values) | OK |
| base64 -d / decode | 0 commande | OK |
| Vault command (get/put/patch/delete/list/auth/token) | 0 (path deduit via ES spec uniquement Q-1B-5B-0) | OK |
| Provider call LLM externe | 0 curl/wget vers OpenAI/Anthropic/Gemini/LiteLLM | OK |
| Proxy LiteLLM /chat /embeddings | 0 appel | OK |
| Health probe LiteLLM avec pod ephemere | 0 kubectl run (correction 4) | OK |
| Manifest hors k8s/keybuzz-api-prod/ ou dans /tmp | manifest dans k8s/ uniquement post B2.2 mv | OK |
| Commit sans GO Gate B1 | commit fait apres `GO COMMIT MANIFEST ES PROD Q-1B-5B-1` | OK |
| Push sans GO Gate B6 (correction 1+2+3) | push fait apres `GO PUSH MANIFEST ES PROD ONLY Q-1B-5B-1` | OK |
| Apply sans GO Gate B7 (correction 1+3) | apply fait apres `GO APPLY ES PROD LITELLM Q-1B-5B-1` | OK |
| Rollback delete sans GO (correction 5) | 0 delete execute (succes, rollback non requis) | OK |
| Commit rapport sans GO Gate B-FINAL | rapport en untracked, attente GO `GO B14 commit/push rapport Q-1B-5B-1` | OK |
| Invariants compares au snapshot B0.7 (correction 6) | toutes comparaisons B9 utilisent snapshot B0.7 explicitement, jamais Q-1B-5B-0 historique | OK |
| SSH heredoc multi-lignes | 0 utilisation, SCP runner pattern pour manifest YAML | OK |
| Tenant/user/email hardcode dans rapport | 0 | OK |
| Toucher PROD mutation hors scope | 0 (uniquement creation ES + Secret cibles) | OK |
| Affichage valeur LITELLM_MASTER_KEY | 0 (jamais lue, jamais ecrite dans aucun output) | OK |

23/23 contraintes Mode B SAFE respectees, 0 violation.

## Brouillon Linear KEY-323

Brouillon disponible pour Ludovic, NON poste sans GO separe :

```
KEY-323 - AS.17.1Q-1B-5B-1 LLM PROD ESO MIGRATION EXEC MODE B SAFE

Status: COMPLETE
Scope: PROD additif (1 ES + 1 Secret crees, Deployment INCHANGE)

Mutations effectuees:
- Commit local 61a71c9 + push origin main (manifest k8s/keybuzz-api-prod/externalsecret-litellm.yaml)
- kubectl apply manuel (Argo CD absent pour ce path)
- ExternalSecret keybuzz-api-prod/keybuzz-litellm-secrets cree, Ready=True/SecretSynced en 5s
- Secret keybuzz-api-prod/keybuzz-litellm-secrets cree par ESO (ownerReferences=ExternalSecret/keybuzz-litellm-secrets, creationPolicy=Owner, 1 key LITELLM_MASTER_KEY)

Garanties preservees (8/8 invariants vs snapshot B0.7):
- Secret manuel keybuzz-litellm rv=22599356 UNCHANGED
- Deployment keybuzz-api gen=410, obs=410 UNCHANGED
- Pod keybuzz-api jx6m7 phase=Running, restartCount=0, startTime UNCHANGED (age 19h -> 20h progression normale)
- Deployment env LITELLM_MASTER_KEY -> keybuzz-litellm (manual) UNCHANGED (Q-1B-5B-2 future)
- 0 Warning/Error events 15m api-prod
- LiteLLM 2 pods 0 restart UNCHANGED baseline B0.7
- LiteLLM ES litellm-secrets Ready=True UNCHANGED
- 0 Argo auto-sync declenche (defense-in-depth confirmee)

Sequence Mode B SAFE 3 gates avec phrases exactes:
- GO COMMIT MANIFEST ES PROD Q-1B-5B-1 (commit local 61a71c9)
- GO PUSH MANIFEST ES PROD ONLY Q-1B-5B-1 (push, 0 runtime impact car Argo absent)
- GO APPLY ES PROD LITELLM Q-1B-5B-1 (kubectl apply manuel, succes 5s)

Hors scope respecte:
- 0 modification Deployment env-var (= Q-1B-5B-2 future)
- 0 rotation Vault master_key (= Q-1B-5B-5 future)
- 0 delete keybuzz-litellm manual (= Q-1B-5B-4 future)
- 0 provider call LLM
- 0 kubectl run/exec/port-forward (B10 100% read-only)
- 0 lecture valeur secret
- 0 vault command

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-1-KEY-323-LLM-PROD-ESO-MIGRATION-EXEC-01.md
NO GO maintenus: Q-1B-5B-2+ (migration env-var, cleanup, rotation), GHCR PAT rotation, AS.17.0/0.1 PROD promotion.
```

## Gaps restants

1. **Q-1B-5B-2 migration Deployment env-var api-dev + api-prod** : NO GO maintenu, prerequis = Q-1B-5B-1 stable >= 24h + GO PROD obligatoire. Le Secret ESO cree est ORPHAN CONSUMER-SIDE jusqu'a cette phase.
2. **Q-1B-5B-3 migration api-dev Deployment env-var** : NO GO maintenu (ordre DEV-first pour Q-1B-5B-2, deja prepare en api-dev).
3. **Q-1B-5B-4 delete keybuzz-litellm manual api-dev + api-prod** : NO GO maintenu (post-migration validation).
4. **Q-1B-5B-5 ROTATION Vault path master_key** : NO GO maintenu (prerequis dedup cumulative).
5. **Q-1B-5B-6 sync + restart pods + validation parite IA messaging baseline obligatoire** : NO GO maintenu.
6. **Q-1B-5B-7 cleanup k8s/litellm/secret.yaml expose Git** : NO GO maintenu (apres rotation neutralisation).
7. **Q-1B-5C studio-api migration ESO** : NO GO maintenu.
8. **Q-1B-5D ANTHROPIC_API_KEY dual-source audit** : differable.
9. **Q-1B-3D-2B harmonisation pleine GHCR** : NO GO maintenu (decision option A/B/C Ludovic).
10. **Q-1B-3D-3 creation dockerconfigjson via Helm/ESO** : differable.
11. **Q-1B-3E inbound-webhook ESO PROD** : differable.
12. **Q-1B-3B provider low-risk batch** : differable.
13. **Q-1B-3C OAUTH login, Q-1B-6 marketplace OAuth, Q-1B-4 infra direct, Q-1B-7 ads-encryption, Q-1F-3 validation cumulee** : restent dans la file.
14. **AS.17.0 / AS.17.0.1 PROD promotion** : NO GO maintenue (tenantGuardPlugin INACTIF KEY-301 AS.3 non patche).
15. **backfill-scheduler ImagePullBackOff** : hors scope, phase dediee.

## Phrase cible finale

ExternalSecret keybuzz-api-prod/keybuzz-litellm-secrets cree de maniere additive en Mode B SAFE 3 gates (commit 61a71c9 local + push origin main verifie 0 runtime impact car Argo absent confirme + kubectl apply manuel succes Ready=True/SecretSynced en 5s), Secret K8s `keybuzz-litellm-secrets` cree par ESO avec ownerReferences `ExternalSecret/keybuzz-litellm-secrets` correct et 1 key `LITELLM_MASTER_KEY` peuplee, 8/8 invariants verifies strictement vs snapshot B0.7 (Secret manuel keybuzz-litellm rv=22599356 unchanged, Deployment generation=410 unchanged, pod restartCount=0 unchanged, env-var pointe toujours keybuzz-litellm manual NON switched, 0 Warning event 15m), LiteLLM 2 pods Running 0 restart UNCHANGED baseline read-only sans kubectl run/exec/port-forward, 0 downtime LLM PROD, rapport docs-only pret - aucune lecture de valeur secret, 0 vault command, 0 provider call, 0 modification Deployment, asymetrie LLM PROD ESO resolue (api-prod desormais a ES + Secret alignes sur Vault path canonique master_key) - Q-1B-5B-2 migration env-var reste NO GO en attente GO Ludovic explicite.

STOP
