# PH-WEBSITE-T8.12AS.17.1Q-1B-5B-0-KEY-323-LLM-PROD-ESO-MIGRATION-DRYRUN-01

> Date : 2026-05-18
> Linear : KEY-323
> Phase : AS.17.1Q-1B-5B-0
> Environnement : PROD lecture + DEV lecture (dry-run server uniquement, aucune persistance)

## VERDICT

GO READY Q-1B-5B-0 PROD ESO MIGRATION DRY-RUN COMPLETE

Validation dry-run server-side de la creation d'un ExternalSecret `keybuzz-litellm-secrets` cote `keybuzz-api-prod` pointant le Vault path canonique `secret/keybuzz/litellm/master_key`. Tous les checks PASS :

- Preflight : bastion install-v3 / 46.62.171.61, HEAD infra descendant 997225c (Q-1B-5A), clean, deps OK, /tmp libre, ClusterSecretStore `vault-backend` Ready=True/Valid.
- BEFORE api-prod : ES `keybuzz-litellm-secrets` NotFound, Secret `keybuzz-litellm-secrets` NotFound (0 collision), Secret manuel `keybuzz-litellm` PRESENT (rv=22599356, key=LITELLM_MASTER_KEY, preserve), Deployment `keybuzz-api` env LITELLM_MASTER_KEY -> keybuzz-litellm (confirme), 1 pod Running age 18h.
- Preuve indirecte Vault path : ES api-dev `keybuzz-litellm-secrets` Ready=True/SecretSynced, refreshTime 2026-05-18T08:26:42Z sur ce meme path -> path lisible par ESO via `vault-backend`.
- Preuve ESO controller fonctionnel en api-prod ns : 5 ExternalSecrets existantes (keybuzz-api-jwt, keybuzz-api-postgres, minio-credentials, octopia-credentials, redis-credentials) toutes Ready=True/SecretSynced, refresh recents (< 1h), store=vault-backend -> RBAC ESO + connectivite Vault + reachability OK depuis le namespace cible.
- kubectl apply --dry-run=server : exit 0, server-side validation reussie, annotations server-added (conversionStrategy=Default, decodingStrategy=None, metadataPolicy=None, deletionPolicy=Retain).
- kubectl diff : 25 lignes ajoutees, 0 supprimees (creation de ressource attendue).
- Non-persistance : apres dry-run, kubectl get retourne NotFound pour ES + Secret cibles -> pur validation, aucune mutation persistee.

Aucune mutation runtime. Aucun vault command. Aucun provider call. Aucune lecture de valeur secret. Aucun apply effectif. Aucun GitOps push. PROD intouchee. Manifest draft ecrit UNIQUEMENT dans /tmp (mode 600), shred apres redaction, JAMAIS ecrit dans k8s/keybuzz-api-prod/.

Q-1B-5B-1 EXEC est sequence et documente en 8 steps, prerequis remplis, en attente GO Ludovic explicite pour apply effectif futur. Q-1B-5B-2+ restent NO GO maintenus.

## Scope / hors scope

### Scope strict applique
- Lecture cluster : ES + Secrets + Deployment + Pods api-prod
- Lecture manifest reference api-dev existant
- Generation manifest YAML cible dans /tmp/keybuzz-q1b5b0-externalsecret-litellm.yaml (mode 600)
- 1 commande mutationnelle autorisee : `kubectl apply -f /tmp/...yaml --dry-run=server` (validation API server, NON persistante)
- `kubectl diff -f /tmp/...yaml` (lecture comparative)
- Shred du manifest /tmp apres redaction rapport

### Hors scope respecte
- AUCUNE ecriture dans `/opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/` (correction 1 Ludovic appliquee)
- AUCUN git add manifest (correction 2 : commit rapport SEUL en E14)
- AUCUNE apply effective (uniquement --dry-run=server)
- AUCUNE mutation Vault, AUCUN vault command
- AUCUN provider call LLM
- AUCUN appel proxy LiteLLM /chat /embeddings (uniquement health probe deja effectue en Q-1B-5A sans Auth header)
- AUCUNE lecture valeur secret (.data jamais affichee, base64 jamais decode)
- AUCUN kubectl create/patch/edit/delete/annotate/label/rollout
- PROD intouchee (lecture pure + 1 dry-run server-side non-persistant)
- AS.17.0 / AS.17.0.1 promotion : NO GO maintenue
- Q-1B-5B-1 EXEC : NO GO maintenu
- Q-1B-5B-2+ : NO GO maintenus

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5A-KEY-323-LLM-SECRETS-DEDUP-DRYRUN-01.md | sha256 d5a2dc86d0834cd6a71569a4bfbca188846e56bf04dbeed172c627b5d553dbc0 | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3D-2A-KEY-323-GHCR-ORPHAN-CLEANUP-EXEC-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-1B-KEY-323-ORPHANS-CLEANUP-EXEC-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-0-KEY-323-PROVIDER-MANUAL-DECISIONS-DRYRUN-01.md | present | OK (asymetrie origine documentee) |
| k8s/keybuzz-api-dev/externalsecret-litellm.yaml | manifest reference modele | OK structure simple 1 secretKey LITELLM_MASTER_KEY -> path/value |
| keybuzz-infra HEAD | 997225c8e4c3ad1c2249367b9cad100c3ed621e2 | OK |

## Preflight

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host | install-v3 | install-v3 | OK |
| Bastion IPv4 | 46.62.171.61 | 46.62.171.61 | OK |
| Banned IP 51.159.99.247 | absent | absent | OK |
| keybuzz-infra branch | main | main | OK |
| keybuzz-infra HEAD descendant | 997225c | 997225c (HEAD exact) | OK |
| keybuzz-infra status | clean | clean | OK |
| Rapports dependances | 4 PH presents | 4 OK | OK |
| /tmp residuels Q-1B-5B-0 | absent | absent | OK |
| ClusterSecretStore vault-backend Ready | True | True / reason=Valid | OK |

## BEFORE snapshot api-prod

| Resource | Expected | Observed | Verdict |
|---|---|---|---|
| ExternalSecret keybuzz-api-prod/keybuzz-litellm-secrets | NotFound | NotFound | OK (0 collision) |
| Secret keybuzz-api-prod/keybuzz-litellm-secrets | NotFound | NotFound | OK (0 collision) |
| Secret keybuzz-api-prod/keybuzz-litellm (manuel) | Exists | rv=22599356, type=Opaque, key=LITELLM_MASTER_KEY | OK (preserve, sera inchange en Q-1B-5B-1) |
| Deployment keybuzz-api consumer | env LITELLM_MASTER_KEY -> keybuzz-litellm (key=LITELLM_MASTER_KEY) | identique | OK |
| Pods api-prod | >=1 Running | keybuzz-api-7685645f49-jx6m7 Running 1/1 age 18h restarts=0 | OK |

## Vault path accessibility proof (correction 3 - double preuve)

### Preuve 1 - indirecte via ES api-dev sur le meme path

| Field | Value |
|---|---|
| ES namespace | keybuzz-api-dev |
| ES name | keybuzz-litellm-secrets |
| store | vault-backend (ClusterSecretStore) |
| target | keybuzz-litellm-secrets (creationPolicy=Owner) |
| remoteRef.key | secret/keybuzz/litellm/master_key |
| remoteRef.property | value |
| refreshInterval | 1h |
| Ready | True |
| reason | SecretSynced |
| refreshTime | 2026-05-18T08:26:42Z |

Conclusion : ESO via vault-backend lit ce Vault path avec succes pour le namespace api-dev. Le Vault path existe, la cle est valide, la property `value` est definie.

### Preuve 2 - ESO controller fonctionne dans le namespace cible api-prod

| ES name api-prod | Ready | reason | store | refreshTime |
|---|---|---|---|---|
| keybuzz-api-jwt | True | SecretSynced | vault-backend | 2026-05-18T08:19:10Z |
| keybuzz-api-postgres | True | SecretSynced | vault-backend | 2026-05-18T08:39:40Z |
| minio-credentials | True | SecretSynced | vault-backend | 2026-05-18T08:26:43Z |
| octopia-credentials | True | SecretSynced | vault-backend | 2026-05-18T07:59:33Z |
| redis-credentials | True | SecretSynced | vault-backend | 2026-05-18T07:59:34Z |

Conclusion : 5 ExternalSecrets existantes en keybuzz-api-prod sont toutes Ready=True/SecretSynced via vault-backend. Cela prouve :
- RBAC ESO controller dans le namespace api-prod : OK (peut creer Secret K8s)
- Connectivite reseau ESO controller -> Vault : OK
- ClusterSecretStore vault-backend resoluble depuis api-prod : OK
- Refresh recents (< 1h) : controller actif et fonctionnel

Combinaison preuves 1 + 2 = la creation future de l'ES `keybuzz-litellm-secrets` cote api-prod doit sync immediatement (< 60s) sans erreur attendue.

## Manifest YAML propose (ecrit en /tmp UNIQUEMENT, NON dans k8s/)

Le manifest suivant a ete genere dans `/tmp/keybuzz-q1b5b0-externalsecret-litellm.yaml` mode 600 puis shred en E12. Inclus ici inline dans le rapport pour traceability ; **non commit, non applique** en Q-1B-5B-0 ; sera recree depuis ce contenu inline et commit dans Q-1B-5B-1 EXEC.

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

Notes de design :
- Structure 1:1 du manifest reference api-dev (uniquement `namespace` change : keybuzz-api-dev -> keybuzz-api-prod).
- Pas de commentaire interne expose au runtime (commentaires de provenance restent dans le fichier /tmp draft uniquement, deja shred).
- creationPolicy=Owner : si l'ES est supprime, le Secret K8s qu'il a cree est aussi supprime (rollback unitaire safe).
- refreshInterval 1h identique a tous les autres ES KeyBuzz (convention).
- target.name identique au ES name (convention api-dev maintenue).

## kubectl apply --dry-run=server output

| Field | Value |
|---|---|
| Command | `kubectl apply -f /tmp/keybuzz-q1b5b0-externalsecret-litellm.yaml --dry-run=server` |
| stdout | `externalsecret.external-secrets.io/keybuzz-litellm-secrets created (server dry run)` |
| stderr | (vide) |
| exit code | 0 |
| server-added defaults | conversionStrategy=Default, decodingStrategy=None, metadataPolicy=None, deletionPolicy=Retain |
| simulated generation | 1 |
| simulated creationTimestamp | 2026-05-18T08:44:31Z (simulee, non persistee) |
| simulated UID | b36a3ba2-8347-4583-854f-c7e2aa51e562 (simulee, non persistee) |
| kubectl diff exit code | 1 (1 = differences exist, attendu pour ressource a creer) |
| diff resume | 25 lignes ajoutees, 0 supprimees |
| Re-verify post dry-run : ES keybuzz-litellm-secrets api-prod | NotFound (non-persistance confirmee) |
| Re-verify post dry-run : Secret keybuzz-litellm-secrets api-prod | NotFound (non-persistance confirmee) |

Conclusion validation : schema CRD OK, store resolution OK, RBAC OK, namespace OK, ressource non-persistee, pret pour apply effectif en Q-1B-5B-1.

## Simulation post-apply attendue (Q-1B-5B-1 EXEC, NON execute ici)

| Resource | Pre-EXEC | Post-EXEC attendu | Impact runtime |
|---|---|---|---|
| ES api-prod/keybuzz-litellm-secrets | absent | Ready=True (sync <60s) | additif |
| Secret api-prod/keybuzz-litellm-secrets | absent | cree par ESO, ownerReferences=ExternalSecret/keybuzz-litellm-secrets, 1 key LITELLM_MASTER_KEY | additif |
| Secret api-prod/keybuzz-litellm (manuel) | actif, rv=22599356, consume by Deployment | inchange, rv inchange | 0 |
| Deployment api-prod/keybuzz-api | env LITELLM_MASTER_KEY -> keybuzz-litellm | inchange (toujours pointe manuel) | 0 |
| Pod api-prod keybuzz-api-7685645f49-jx6m7 | Running 1/1 age 18h restarts=0 | inchange age + restarts | 0 |
| LiteLLM keybuzz-ai 2 pods | Running | inchange | 0 |
| Argo CD detection diff | n/a | si manifest commit (Q-1B-5B-1) : detection diff sync ; sinon : aucune detection | 0 (manifest non commit Q-1B-5B-0) |

Invariant cle : le nouveau Secret api-prod sera ORPHAN CONSUMER-SIDE jusqu'a Q-1B-5B-2 (qui migrera le Deployment env-var). Statut orphan-temporaire ACCEPTABLE car couvert par creationPolicy=Owner -> delete ES = delete Secret automatique si rollback.

## Risk matrix

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | Schema CRD ESO v1 a evolue depuis la creation de l'ES api-dev | TRES FAIBLE (v1 valide en E5.1) | MOYEN | dry-run server E5.1 valide sur live API server, exit 0 |
| R2 | RBAC ESO controller n'a pas l'autorisation de creer Secret dans api-prod ns | TRES FAIBLE (5 ES existantes Ready=True en api-prod proof E3-bis) | MOYEN | preuve E3-bis = 5 ES PROD deja synced, RBAC verifie |
| R3 | Vault path retourne erreur 403/404 depuis api-prod alors que api-dev y arrive | TRES FAIBLE (CSS cluster-scoped + meme provider config) | ELEVE | preuve E3 ES api-dev Ready+SecretSynced refresh recent < 17min |
| R4 | Collision nominale keybuzz-litellm-secrets deja occupee | NEANT (E2.1 + E2.2 NotFound) | ELEVE | STOP gate explicit, vide confirme |
| R5 | Manifest dans /tmp accidentellement attrape par Argo CD auto-sync | NEANT (Argo lit Git commits, pas /tmp) | NEANT | manifest dans /tmp hors scope Git, shred a E12 |
| R6 | Apply effectif Q-1B-5B-1 provoque side-effect imprevu | MOYEN si tests dry-run incomplets | ELEVE | cette phase Q-1B-5B-0 est la couverture dry-run exhaustive |
| R7 | Argo CD detecte le nouveau manifest commit en Q-1B-5B-1 et auto-applique avant la phase EXEC dediee | FAIBLE (depend config Argo) | MOYEN | Q-1B-5B-1 prompt CE devra anticiper et soit (a) sequencer commit + apply manuel + verify, soit (b) laisser Argo auto-apply et observer |
| R8 | Diff entre les valeurs Vault path et le secret manuel keybuzz-litellm api-prod (cles differentes) | INCONNU (valeurs jamais lues) | ELEVE en Q-1B-5B-2 migration | Q-1B-5B-1 cree le Secret ES en parallele sans migrer ; Q-1B-5B-2 fera A/B test base64 length avant switch Deployment env-var (sans valeur affichee) |

## Plan Q-1B-5B-1 EXEC sequence (NON execute, propose)

| step | action | dependency | gate | risk | rollback | required_GO_phrase |
|---|---|---|---|---|---|---|
| 1 | E0 preflight CE : bastion + infra HEAD descendant de Q-1B-5B-0 commit | Q-1B-5B-0 rapport committe | STOP si dirty / non-ancestor | FAIBLE | none | (preflight automatique) |
| 2 | Generer manifest dans /tmp ou recreer depuis YAML inline du rapport Q-1B-5B-0 | E0 OK | scope strict | NEANT | rm -f | (interne CE) |
| 3 | Re-verifier BEFORE state api-prod (ES + Secret + manuel + Deployment + Pod) | step 2 | STOP si changement vs Q-1B-5B-0 | FAIBLE | none | (auto-verify) |
| 4 | Stager manifest dans k8s/keybuzz-api-prod/externalsecret-litellm.yaml puis git add + commit + push (SOIT en meme commit que rapport Q-1B-5B-1, SOIT separe : decision Ludovic) | step 3 OK | GO Ludovic | FAIBLE | git revert | GO COMMIT MANIFEST ES PROD Q-1B-5B-1 |
| 5 | Choisir entre kubectl apply manuel OU laisser Argo CD auto-sync (depend config) | step 4 OK | GO Ludovic apply manuel ou observer Argo | MOYEN | kubectl delete externalsecret + Secret auto-delete par Owner | GO APPLY ES PROD LITELLM Q-1B-5B-1 |
| 6 | Wait Ready=True (max 120s) + verify Secret cree | step 5 | STOP si Ready != True a 120s | MOYEN | kubectl delete ES | (auto-monitor) |
| 7 | Verify Deployment keybuzz-api INCHANGE + pod restartCount inchange + ImagePullBackOff=0 | step 6 | STOP si pod redeploy/error | NEANT (Deployment pas touche) | none | (auto-verify) |
| 8 | Rapport Q-1B-5B-1 docs-only ASCII strict + STOP commit/push rapport | step 7 | GO commit | none | none | GO E_LAST commit/push rapport Q-1B-5B-1 |

Ouverture sur Q-1B-5B-2 (migration Deployment env-var) : hors scope cette phase, prompt CE dedie a preparer apres Q-1B-5B-1 stable >= 24h.

## Plan Q-1B-5B-2+ esquisse (hors scope cette phase)

- **Q-1B-5B-2** : Migrer Deployment `keybuzz-api` api-prod env LITELLM_MASTER_KEY de `keybuzz-litellm` (manuel) vers `keybuzz-litellm-secrets` (ESO). Patch manifest + apply + rollout + verify pods Ready. GO Ludovic PROD obligatoire. Risk MOYEN-ELEVE (drift valeurs potentiel R8).
- **Q-1B-5B-3** : Meme migration en api-dev (ES deja existante, juste switcher Deployment env). DEV-first, donc step 3 logiquement avant Q-1B-5B-2 PROD. Reorder potentiel.
- **Q-1B-5B-4** : Delete `keybuzz-litellm` manual api-dev + api-prod apres validation stable 24h cumule.
- **Q-1B-5B-5** : ROTATION Vault path `secret/keybuzz/litellm/master_key` (openssl rand -hex 32 offline via runner SCP + vault kv patch property-only, jamais echoed).
- **Q-1B-5B-6** : Sync force + restart pods (litellm 2 pods + keybuzz-api dev+prod) + validation parite IA messaging baseline obligatoire.
- **Q-1B-5B-7** : Cleanup manifest Git `k8s/litellm/secret.yaml` (cle exposee neutralisee par rotation step 5).
- **Q-1B-5C** (futur) : Migration `keybuzz-studio-api` vers ESO.

## No fake metrics

N/A. Phase dry-run pure sans impact dashboard, KPI, billing, acquisition, reporting, tracking. 0 KBAction, 0 event GA4/CAPI/TikTok/LinkedIn, 0 metric creee.

## AI feature parity

N/A direct (dry-run zero-impact runtime confirme par E5.4 non-persistance + E6 simulation additive).

Documentation explicite :
- 0 restart pod LiteLLM (keybuzz-ai), keybuzz-api, keybuzz-studio-api.
- 0 modification Deployment quelconque.
- 0 apply effective.
- LLM PROD continue de fonctionner exactement comme avant (consumer keybuzz-litellm manuel reste source unique en api-prod).
- L'EXEC Q-1B-5B-1 sera additif zero-impact runtime (creation ES + Secret K8s sans consumer Deployment).

Reference parite IA : voir `AI_MEMORY/AI_MESSAGING_FEATURE_PARITY_BASELINE.md` pour les tests parite a executer en Q-1B-5B-2 (migration Deployment) et Q-1B-5B-6 (validation post-rotation).

## Cleanup temporary files

| Fichier | Mode | Statut |
|---|---|---|
| /tmp/keybuzz-q1b5b0-externalsecret-litellm.yaml | 600 | sera shred en E12 final (apres redaction rapport, contenu deja inline dans le rapport ci-dessus) |

Aucun runner SCP separe en Q-1B-5B-0 (commandes inline + 1 SCP du manifest /tmp). Aucun snapshot BEFORE-metadata-only (commandes BEFORE inline sans persistance JSONL).

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1B-5B-0 | Impact |
|---|---|---|---|
| keybuzz-api-prod ES count | 5 ES Ready | 5 ES Ready (inchange) | 0 |
| keybuzz-api-prod Secret keybuzz-litellm | rv=22599356, key=LITELLM_MASTER_KEY | rv=22599356 (inchange) | 0 |
| keybuzz-api-prod Deployment keybuzz-api | env -> keybuzz-litellm | inchange | 0 |
| keybuzz-api-prod Pod jx6m7 | Running 1/1 age 18h restarts=0 | inchange | 0 |
| keybuzz-backend-prod | non touche | non touche | 0 |
| keybuzz-studio-api-prod | non touche | non touche | 0 |
| keybuzz-ai litellm 2 pods | Running | non touche | 0 |
| keybuzz-client-prod | non touche | non touche | 0 |
| keybuzz-admin-v2-prod | non touche | non touche | 0 |
| Vault KV PROD paths | non touche (0 vault command) | non touche | 0 |
| ESO ClusterSecretStores | Ready=True | inchange | 0 |
| GitOps Argo CD | non touche | non touche (manifest /tmp hors Git) | 0 |
| Providers LLM OpenAI/Anthropic/Gemini | non touche (0 provider call) | non touche | 0 |
| LiteLLM proxy /chat /embeddings | non touche (0 appel) | non touche | 0 |

## Compliance read-only + dry-run

| Interdit | Evidence | Verdict |
|---|---|---|
| Mutation cluster K8s (create/patch/edit/delete) | 0 commande de ce type ; seulement `kubectl apply --dry-run=server` non-persistant verifie par E5.4 NotFound post-dry-run | OK |
| Mutation Vault | 0 vault kv/auth/token command | OK |
| Provider call LLM | 0 curl/wget vers api.openai/anthropic/gemini/litellm | OK |
| Proxy LiteLLM /chat /embeddings | 0 appel (aucune health probe consommatrice ; health probes Q-1B-5A deja effectues sans Auth) | OK |
| Lecture valeur secret | 0 .data value affichee, 0 base64 -d, 0 jsonpath '{.data.*}' | OK |
| Manifest dans k8s/keybuzz-api-prod/ (correction 1) | manifest ecrit UNIQUEMENT dans /tmp/keybuzz-q1b5b0-externalsecret-litellm.yaml, shred en E12, inline dans rapport pour traceability | OK |
| git add manifest (correction 2) | 0 git add manifest, git status post-shred = 1 untracked = rapport seul | OK |
| Apply effectif | 0 kubectl apply sans --dry-run=server | OK |
| Argo CD auto-sync trigger via manifest commit | manifest hors Git => Argo NE detecte rien | OK |
| Rollout restart | 0 commande rollout, pod jx6m7 age 18h inchange | OK |
| SSH heredoc multi-lignes | 0 utilisation, SCP runner pattern pour manifest (1 fichier SCP) | OK |
| Tenant/user/email hardcode dans rapport | 0 | OK |
| Toucher PROD mutation | 0 commande mutation namespace *-prod | OK |
| Affichage valeur LITELLM_MASTER_KEY | 0 (valeur jamais lue, jamais ecrite dans aucun output) | OK |

## Brouillon Linear KEY-323

Brouillon disponible pour Ludovic, NON poste sans GO separe :

```
KEY-323 - AS.17.1Q-1B-5B-0 LLM PROD ESO MIGRATION DRY-RUN

Status: COMPLETE READY FOR Q-1B-5B-1
Scope: PROD lecture + DEV lecture, dry-run server uniquement

Validation:
- BEFORE confirme 0 collision (ES + Secret keybuzz-litellm-secrets absents en api-prod)
- Secret manuel keybuzz-litellm api-prod preserve (rv=22599356)
- Preuve indirecte Vault path: ES api-dev keybuzz-litellm-secrets Ready=True/SecretSynced refresh recent
- Preuve ESO controller fonctionne en api-prod: 5 ES existantes Ready=True/SecretSynced via vault-backend
- kubectl apply --dry-run=server: exit 0, server-side validation OK
- Non-persistance confirmee: NotFound post-dry-run pour ES + Secret
- 0 mutation runtime, 0 vault command, 0 provider call, 0 GitOps push
- Manifest draft dans /tmp uniquement, shred apres redaction, NON commit

Plan Q-1B-5B-1 EXEC propose en 8 steps documente.

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-0-KEY-323-LLM-PROD-ESO-MIGRATION-DRYRUN-01.md
NO GO maintenus: Q-1B-5B-1 EXEC, Q-1B-5B-2+, GHCR PAT rotation, AS.17.0/0.1 PROD promotion.
```

## Gaps restants

1. **Q-1B-5B-1 EXEC apply ES api-prod** : NO GO maintenu, requires GO Ludovic explicite + decision sequence (commit + Argo auto-sync ou commit + kubectl apply manuel).
2. **Q-1B-5B-2 migration Deployment env-var api-prod + api-dev** : NO GO maintenu, requires Q-1B-5B-1 stable + GO PROD obligatoire.
3. **Q-1B-5B-3 + Q-1B-5B-4 cleanup manuels** : NO GO maintenu, sequencing apres migration.
4. **Q-1B-5B-5 ROTATION Vault path master_key** : NO GO maintenu (prerequis migration cumulative).
5. **Q-1B-5B-6 sync + restart + parite IA messaging** : NO GO maintenu.
6. **Q-1B-5B-7 cleanup k8s/litellm/secret.yaml expose** : NO GO maintenu (apres rotation).
7. **Q-1B-5C studio-api migration ESO** : NO GO maintenu.
8. **Q-1B-5D ANTHROPIC_API_KEY dual-source audit** : differable.
9. **Q-1B-3D-2B harmonisation pleine GHCR** : NO GO maintenu (decision Ludovic).
10. **Q-1B-3D-3 creation dockerconfigjson via Helm/ESO** : differable.
11. **Q-1B-3E inbound-webhook ESO PROD** : differable.
12. **Q-1B-3B provider low-risk batch** : differable.
13. **Q-1B-3C OAUTH login, Q-1B-6 marketplace OAuth, Q-1B-4 infra direct, Q-1B-7 ads-encryption, Q-1F-3 validation cumulee** : restent dans la file.
14. **AS.17.0 / AS.17.0.1 PROD promotion** : NO GO maintenu (tenantGuardPlugin INACTIF KEY-301 AS.3 non patche).
15. **backfill-scheduler ImagePullBackOff** : hors scope, phase dediee.

## Phrase cible finale

Validation dry-run ExternalSecret keybuzz-api-prod/keybuzz-litellm-secrets complete (BEFORE confirme absence collision sur ES + Secret cibles, Secret manuel keybuzz-litellm preserve rv=22599356, double preuve Vault path lisible via ES api-dev Ready=True + ESO controller fonctionnel en api-prod prouve par 5 ES existantes Ready=True/SecretSynced, kubectl apply --dry-run=server exit 0 avec server-side defaults annotates, kubectl diff 25 lignes ajoutees, non-persistance verifiee post-dry-run par NotFound persistant, simulation post-apply additive zero-impact runtime documentee), manifest draft genere dans /tmp uniquement et shred apres redaction, plan EXEC Q-1B-5B-1 sequence 8 steps documente avec GO phrases exactes - aucune mutation runtime, aucune apply effective, aucune lecture de valeur secret, 0 vault command, 0 provider call, 0 manifest commit, PROD intouchee - EXEC Q-1B-5B-1 reste NO GO en attente GO Ludovic explicite.

STOP
