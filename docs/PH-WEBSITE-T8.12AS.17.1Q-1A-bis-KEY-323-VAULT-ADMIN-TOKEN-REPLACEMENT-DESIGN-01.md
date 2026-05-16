# PH-WEBSITE-T8.12AS.17.1Q-1A-bis-KEY-323-VAULT-ADMIN-TOKEN-REPLACEMENT-DESIGN-01

> Date : 2026-05-16
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1Q-1A-bis Vault admin/root token replacement design
> Environnement : HashiCorp Vault HA Raft + External Secrets Operator
>          + Kubernetes - design read-only strict, aucune execution
> Reference rapport : `keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1A-...md` (commit b27e94a)

---

## VERDICT

GO ADMIN TOKEN REPLACEMENT DESIGN READY

Design plan complet documente pour replacement safe et minimal-disruption
du `vault-management/vault-admin-token` (K8s Secret traite comme
potentiellement expose pendant la fenetre attaque 2026-05-15
ou` les k8s-worker etaient sous controle SSH attaquant 1-14h).

Architecture analysee :
- ESO auth chain (K8s SA JWT vers roles `keybuzz-external-secrets` +
  `eso-keybuzz`) est **INDEPENDANTE** du vault-admin-token. Rotation
  admin-token sans toucher auth/kubernetes policies = **zero disruption ESO**
- vault-token-renew CronJob lit vault-admin-token comme TOKEN argument
  pour creer/renouveler les vault-app/root/token namespaces apps.
  Rotation = patch K8s secret + next CronJob run = OK
- vault-app/root/token consommes par apps (keybuzz-api, keybuzz-backend)
  pour appels Vault directs. Tokens auto-renouveles par CronJob, donc
  rotation admin-token n'affecte pas ces tokens si CronJob continue
- Shamir unseal keys assumees offline (confirme Ludovic). Pas de rekey
  necessaire si attaquant n'a jamais eu acces aux keyshares offline

Plan execution Q-1A-bis-exec en 6 phases sequentielles, mutation
limitee a :
- generation nouveau admin-token via root recovery Ludovic offline
- patch K8s Secret `vault-management/vault-admin-token`
- revocation ancien admin-token apres confirmation new admin-token
  operationnel

Aucune mutation effectuee dans Q-1A-bis (design seulement). Aucun
existing vault-admin-token lu ni utilise. Aucune valeur secret affichee.
NO GO KV secret rotation Q-1B maintenu jusqu'a admin-token trust restaure.

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu.

---

## Resume executif

### Modele de menace vault-admin-token

| Element | Statut compromission probable |
|---|---|
| **vault-admin-token** stockage K8s Secret `vault-management/vault-admin-token` | **EXPOSE PROBABLE** : K8s Secret monte dans `/var/run/secrets` des pods qui le consomment, et lu en clair depuis filesystem k8s-worker pendant fenetre attaque 1-14h |
| Pods qui consomment vault-admin-token | vault-token-renew CronJob (k8s-worker random selection) |
| Pods compromis pendant l'attaque | k8s-worker-01/02/03 sous controle SSH attaquant pendant fenetre rebuild + restore (~14-17h max) |
| Hypothese expose | **PROUVE POSSIBLE** : si CronJob a tourne pendant la fenetre, le pod ephemere a mount le secret sur le k8s-worker compromis |
| Hypothese non expose | **PROUVE POSSIBLE inverse** : si aucun CronJob run pendant la fenetre, et que le K8s Secret n'etait pas dans `/var/lib/kubelet/pods/*/volumes/kubernetes.io~secret/` cache durant la fenetre, alors non expose |

**Decision Ludovic** : traiter comme **potentially exposed** par precaution. Rotation requise.

### Architecture Vault token tree

```
                         Shamir Unseal Keys 5/3
                           (offline Ludovic)
                                  |
                                  v
                       Vault Root Token recovery
                       (generate-root via unseal)
                                  |
                                  v
                        ROOT Token (TTL=infinite ou court selon usage)
                                  |
                  +---------------+---------------+
                  |                               |
                  v                               v
        vault-admin-token            auth/kubernetes/ config
        (vault-management            (role keybuzz-external-secrets,
         K8s Secret)                  role eso-keybuzz, policies
        utilise par CronJob          attachees ; SA external-secrets
        vault-token-renew            external-secrets/external-secrets)
                  |                               |
                  v                               v
        Cree/renouvelle :          Authentifie ESO operator pods via
        - vault-app-token          K8s SA JWT court-lived (1h TTL
        - vault-root-token         default Kubernetes 1.21+) ->
        - vault-token              short-lived Vault token pour lire
        sur namespaces apps        KV paths /secret/keybuzz/...
                  |
                  v
        Consomme par :
        - keybuzz-api pods (vault-root-token in valueFromSecret)
        - keybuzz-backend pods (vault-app-token, vault-token in envFrom)
        - keybuzz-seller-dev pods (vault-token in valueFromSecret)
```

### Couches d'impact rotation admin-token

| Couche | Impact rotation admin-token |
|---|---|
| Shamir unseal keys (offline) | **AUCUN** (offline, pas touche par rotation) |
| Vault Root Token (genere via unseal) | **AUCUN** (root token n'est pas stocke ; regenere on-demand via unseal) |
| **vault-admin-token (K8s Secret cible rotation)** | **MUTATION** : ancien token revoque, nouveau admin-token genere via root token (unseal), patch K8s Secret |
| auth/kubernetes/ config (role + policies) | **AUCUN** si on ne modifie pas. ESO continue d'authentifier via SA JWT |
| vault-app/root/token namespaces apps | **AUCUN immediat** : tokens existants restent valides jusqu'a leur prochaine renew. Si CronJob n'a pas de nouveau admin-token, les renew futures echouent et les tokens expirent au fil des TTL (default 768h = 32 jours marge). Patch K8s secret admin-token avant prochain CronJob run = continuite assuree |
| Apps consommatrices (keybuzz-api, keybuzz-backend, keybuzz-seller-dev) | **AUCUN immediat** : leurs tokens en pod env restent valides ; reloader rolling restart inutile cote rotation admin-token (les apps ne lisent jamais vault-admin-token directement) |
| ESO + 30 ExternalSecrets | **AUCUN** : ESO utilise auth K8s SA JWT, independant du vault-admin-token |
| KV secrets stockes dans Vault (`secret/keybuzz/...`) | **AUCUN immediat** : KV values inchangees par rotation admin-token. Rotation KV = phase Q-1B separee, decision conditionnee a trust restaure post-Q-1A-bis-exec |

**Conclusion impact** : rotation `vault-admin-token` est **isolee et zero-disruption** pour les apps en runtime, si executee correctement.

---

## Preflight (design seulement)

| Element | Valeur | Statut design |
|---|---|---|
| Bastion identite | install-v3 / 46.62.171.61 | OK (pour audit metadata) |
| Date design | 2026-05-16 | OK |
| keybuzz-infra HEAD | `b27e94a` (post AS.17.1Q-1A) | OK clean |
| Token operateur `~/.vault-token` | INVALIDE/EXPIRE (AS.17.1Q-1A confirme) | BLOCKER pour audit policies en read-only |
| vault-admin-token K8s Secret | NON LU (interdit par Ludovic) | conforme |
| Shamir unseal keys | OFFLINE par Ludovic | confirme |
| Vault HA Raft cluster | UP (leader vault-03 / 10.0.0.155) | OK |
| vault-token-renew CronJob | Schedule `0 3 * * *` | derniere run 2026-05-16T03:00 Complete |

---

## Analyse architecture Vault tokens (deductive)

### Permissions deductibles du vault-admin-token

Source : `/opt/keybuzz/keybuzz-infra/k8s/vault-token-renew/configmap-script.yaml`
analyse en AS.17.1Q-0 sans lecture du token.

Operations realisees par le CronJob avec `vault-admin-token` :

| Operation | Path Vault | Capability requise |
|---|---|---|
| `auth/token/lookup-self` (via X-Vault-Token header) | `/v1/auth/token/lookup-self` | `read` policy `default` (built-in) |
| `auth/token/lookup` cible token | `/v1/auth/token/lookup` | `update` policy admin tokens management |
| `auth/token/renew` cible token | `/v1/auth/token/renew` | `update` policy admin tokens management |
| `auth/token/create` nouveau token avec policies | `/v1/auth/token/create` | `create` + `sudo` (si policies admin requested) |

Policies probables attachees au vault-admin-token (deductives) :

```hcl
# Probable policy "vault-admin" or similar
path "auth/token/lookup" {
  capabilities = ["update"]
}
path "auth/token/renew" {
  capabilities = ["update"]
}
path "auth/token/create" {
  capabilities = ["create", "update", "sudo"]
}
path "auth/token/revoke*" {
  capabilities = ["update"]
}
# Possibly additional broad policies if admin-token has root-like access
```

**Note critique** : si vault-admin-token a la policy `root` (full
sudo wildcard `path "*" { capabilities = ["sudo", ...] }`), il peut
**lire tous les KV** + manipuler toutes les policies.

**Verification policies BLOQUEE** par token operateur invalide.

A confirmer via :
- Ludovic se re-loggue Vault avec ses credentials operateur
- OU consultation GitOps des HCL policies si versionnees dans repo
  keybuzz-infra/k8s/vault-policies/* (pas trouve dans audit AS.17.1Q-0)
- OU Vault GUI Hetzner consulte par Ludovic

### Comparaison vault-admin-token vs Vault Root Token reel

| Aspect | vault-admin-token (K8s Secret) | Vault Root Token reel |
|---|---|---|
| Stockage | K8s Secret `vault-management/vault-admin-token` | non stocke (recovered on-demand via Shamir unseal) |
| TTL | inconnu, probable long-lived (CronJob renouvelle daily) | court selon `vault operator generate-root` |
| Policies | probable admin-level (cree tokens, lookup) | `root` policy (full sudo) |
| Acces apps | OUI via CronJob lecteur | NON (jamais expose en runtime) |
| Compromission | **EXPOSEE PROBABLE** pendant fenetre attaque | **NON COMPROMISE** (offline keyshares chez Ludovic seul) |

**Conclusion** : rotation `vault-admin-token` est suffisante si on
peut prouver que le `vault-admin-token` n'a JAMAIS ete root-policy.
Sinon, **rotation Vault Root Token aussi** requise.

### ESO auth chain analysis (independance)

`ClusterSecretStore vault-backend` config :
```
spec.provider.vault.auth.kubernetes:
  mountPath: kubernetes
  role: keybuzz-external-secrets
  serviceAccountRef:
    name: external-secrets
    namespace: external-secrets
```

`ClusterSecretStore vault-backend-database` config :
```
spec.provider.vault.auth.kubernetes:
  mountPath: kubernetes
  role: eso-keybuzz
  serviceAccountRef:
    name: external-secrets
    namespace: external-secrets
```

**Authentification ESO** :
1. ESO pod monte SA token JWT short-lived (1h TTL Kubernetes 1.21+
   projected SA token, ou legacy long-lived selon config)
2. ESO POST le JWT vers `auth/kubernetes/login` avec role `keybuzz-external-secrets`
3. Vault verifie JWT signature contre Kubernetes API + valide role
4. Vault retourne un token court-lived (TTL selon role config)
5. ESO utilise ce token court-lived pour lire `secret/keybuzz/...` paths
6. Token expire automatiquement

**Independance vs vault-admin-token** :
- Le role `keybuzz-external-secrets` est configure dans `auth/kubernetes/`
  avec ses propres policies
- Le SA JWT est genere par Kubernetes (pas par vault-admin-token)
- ESO n'a JAMAIS besoin du vault-admin-token

**Donc rotation vault-admin-token SANS toucher au role
`keybuzz-external-secrets` = AUCUN impact ESO.**

### Vault tokens namespaces apps (vault-app/root/token)

| K8s Secret | Namespace | Cree par | Consomme par | Impact rotation admin-token |
|---|---|---|---|---|
| vault-root-token | keybuzz-api-prod, keybuzz-api-dev | vault-token-renew CronJob | keybuzz-api pods (valueFromSecret) | tokens existants restent valides ; prochaine renew depend du nouveau admin-token |
| vault-app-token | keybuzz-api-prod, keybuzz-api-dev, keybuzz-backend-prod, keybuzz-backend-dev | meme | keybuzz-api + keybuzz-backend pods | idem |
| vault-token | keybuzz-backend-prod, keybuzz-backend-dev, keybuzz-seller-dev | meme | keybuzz-backend, seller-api pods (valueFromSecret + envFrom) | idem |
| vault-emergency-token | keybuzz-api-dev | manuel | (unknown usage) | idem |

**TTL** : `TOKEN_PERIOD=768h` (32 jours) selon script CronJob. Donc
si CronJob ne tourne pas pendant 32 jours, les tokens expirent. La
fenetre est tres large.

**Strategie rotation safe** :
1. Patch admin-token K8s Secret AVANT prochaine execution CronJob
   (next run = 2026-05-17T03:00 UTC = 24h marge)
2. CronJob next run lit nouveau admin-token et fait son job normalement
3. Tokens app continuent d'etre renouveles
4. Apps en runtime ne sont pas impactees

---

## Design replacement plan Q-1A-bis-exec (NON execute)

### Phase 1 - Pre-flight & decisions Ludovic

Decisions requises avant Phase 2 :

1. **Verifier policies attachees au vault-admin-token** :
   - Option A : Ludovic re-login Vault avec ses credentials operateur
     (root recovery via Shamir unseal keys), puis `vault token lookup
     -accessor <admin-token-accessor>` pour voir policies
   - Option B : Ludovic execute Vault audit log dump et fournit
     accessor + policies hors chat
   - Option C : si policies versionnees dans repo, lire `keybuzz-infra/
     k8s/vault-policies/*.hcl` (non trouve dans audits precedents)

2. **Confirmer Shamir unseal keys OFFLINE** :
   - 5 keyshares chez Ludovic only ? (confirme par toi)
   - Aucune copie online ?
   - Aucun keyshare commit dans Git/K8s/cloud ?
   - Si YES a toutes : pas de rekey
   - Si NO : rekey requise (`vault operator rekey` cycle)

3. **Decision rotation Vault Root Token aussi ?** :
   - Si vault-admin-token avait policy `root` : OUI necessaire
   - Si vault-admin-token avait policy admin-restricted : NON
   - Decision Ludovic apres Phase 1.1

### Phase 2 - Generation nouveau admin-token

Pre-requis : Ludovic session Vault active avec root permissions
(via Shamir unseal + generate-root).

```
# A executer par Ludovic offline avec root token TEMPORAIRE
# (genere via `vault operator generate-root`, jamais commit, jamais
# affiche en clair dans chat)

vault token create \
  -display-name="vault-admin-token-2026-05-16-postincident" \
  -policy="vault-admin" \
  -period=768h \
  -orphan \
  -format=json \
  | jq -r '.auth.client_token' \
  > /tmp/new-admin-token.txt \
  && chmod 600 /tmp/new-admin-token.txt
```

Note : `-orphan` important pour que le token nouveau ne soit pas un
child du root TEMPORAIRE (qui sera lui-meme revoque apres usage).
`-period=768h` aligne avec TOKEN_PERIOD du CronJob actuel.

**Mutation Vault** : creation token. **Pas de revocation de l'ancien
admin-token a ce stade**.

### Phase 3 - Patch K8s Secret vault-management/vault-admin-token

```
# Avec le contenu de /tmp/new-admin-token.txt, jamais affiche en clair
NEW_TOKEN_B64=$(cat /tmp/new-admin-token.txt | tr -d '\n' | base64 | tr -d '\n')

kubectl -n vault-management patch secret vault-admin-token \
  --type='json' \
  -p="[{\"op\":\"replace\",\"path\":\"/data/token\",\"value\":\"${NEW_TOKEN_B64}\"}]"

# Cleanup local
shred -u /tmp/new-admin-token.txt
unset NEW_TOKEN_B64
```

**Mutation K8s** : patch secret data. Pas de rollout immediat
necessaire (le CronJob lit le secret au prochain run, pas en runtime
permanent).

### Phase 4 - Verifier vault-token-renew next run avec nouveau admin-token

Option A - Attendre next scheduled run (next : 2026-05-17T03:00 UTC) :
```
# Apres next scheduled run :
kubectl -n vault-management get jobs --sort-by=.metadata.creationTimestamp \
  | tail -3

# Verifier last vault-token-renew-* job Complete
kubectl -n vault-management logs job/vault-token-renew-<id> \
  | grep -E "(OK|ERROR|WARN)" \
  | tail -20
```

Option B - Trigger manuel earlier (recommande) :
```
kubectl -n vault-management create job \
  --from=cronjob/vault-token-renew \
  vault-token-renew-manual-postrotation

# Wait for completion
kubectl -n vault-management wait \
  --for=condition=complete \
  job/vault-token-renew-manual-postrotation \
  --timeout=120s

# Inspect logs
kubectl -n vault-management logs job/vault-token-renew-manual-postrotation \
  | grep -E "(OK|ERROR|WARN|TOKEN.*ttl|RECREATED)"
```

Resultat attendu :
- Job Complete (no error)
- Logs montrent OK pour TOKEN1, TOKEN2, etc.
- Pas de RECREATED 0 (sauf si normal)
- Tokens namespaces apps renouveles avec succes

### Phase 5 - Verification stabilite ecosystem

```
# Verifier ESO continue de syncer (independant)
kubectl get externalsecrets --all-namespaces | grep -v SecretSynced
# (output vide attendu = tous SecretSynced)

# Verifier apps consommatrices vault tokens
kubectl -n keybuzz-api-prod get pods | grep -v Running
kubectl -n keybuzz-backend-prod get pods | grep -v Running
# (output vide attendu = tous Running)

# Test sub-set service availability (sans mutation)
curl -sS -o /dev/null -w "HTTP=%{http_code}\n" https://api.keybuzz.io/health
# (attendu 200)
```

### Phase 6 - Revocation ancien admin-token

Pre-requis : Phase 4+5 OK.

```
# Le accessor du ancien admin-token doit etre identifie via :
# Ludovic root session : vault token lookup <ancien-token-value>
# Reponse contient `accessor`

# Revoke par accessor (ne necessite pas de connaitre la valeur)
vault token revoke -accessor <ancien-token-accessor>

# Verifier revocation
vault token lookup -accessor <ancien-token-accessor>
# Attendu : error "invalid accessor"
```

**Mutation Vault** : revocation token. Apres cela, l'ancien token
est definitivement inutilisable. Si attaquant avait copie, sa copie
est neutralisee.

### Phase 7 - Audit Vault logs anomalies ancien token

```
# Inspector Vault audit logs (necessite root token + audit device active)
vault audit list
# Si pas d'audit device, activer un audit log file device avant
# Phase 1 ideal (mais necessite mutation)

# Cherche utilisations ancien admin-token entre 2026-05-15T08:00 UTC
# et Phase 6 revocation (incluant indirect usages)
grep -F '<ancien-accessor>' /var/log/vault/audit.log 2>/dev/null
# OU equivalent selon storage audit logs
```

Si anomalie detectee : compromission confirmee, declencher
investigation forensic + RGPD breach decision business.

---

## Verification post-replacement checklist

| Check | Commande | Resultat attendu |
|---|---|---|
| Nouveau admin-token K8s secret | `kubectl -n vault-management get secret vault-admin-token -o jsonpath='{.metadata.resourceVersion}'` | resourceVersion increment |
| vault-token-renew job Complete | `kubectl -n vault-management get jobs \| tail -3` | Last job Complete 1/1 |
| Apps Running | `kubectl get pods -A \| grep -v Running\|Completed` | output vide |
| ESO sync | `kubectl get externalsecrets -A` | toutes SecretSynced |
| Service health PROD | `curl https://api.keybuzz.io/health` | 200 |
| Ancien token revoke | `vault token lookup -accessor <ancien>` | invalid accessor |
| Audit logs ancien token | `grep <ancien-accessor> audit.log` | aucune entree post-revocation |

---

## Rollback plan

Si Phase 4 (CronJob next run) echoue ou anomalie detectee :

```
# Rollback K8s secret au revision precedent
kubectl -n vault-management rollout undo \
  --to-revision=<previous-revision> ?
# Note: K8s Secrets ne supportent pas rollout undo direct, utiliser
#       backup manuel pre-Phase 3 :

# Avant Phase 3 :
kubectl -n vault-management get secret vault-admin-token -o yaml \
  > /root/.vault-admin-token-backup-pre-rotation.yaml
# (ne pas commit, ne pas afficher contenu, supprime apres Phase 6)

# Si rollback necessaire :
kubectl apply -f /root/.vault-admin-token-backup-pre-rotation.yaml
```

Si nouveau admin-token defectueux :
- Ne PAS revoke ancien admin-token avant nouveau prouve operationnel
- Phase 6 (revoke) ne se fait QUE apres Phase 4+5 OK

Si rollback necessite : retour ancien admin-token = retour
compromission possible. Decision business si poursuite rotation
avec nouveau token via Ludovic generation differemment.

---

## Minimal app disruption analysis

| App / Service | Impact rotation admin-token | Disruption attendue |
|---|---|---|
| ESO operator pods | aucun (auth K8s SA JWT independant) | **0 downtime** |
| 30 ExternalSecrets sync | aucun | **0 downtime** |
| reloader pods | aucun | **0 downtime** |
| vault-token-renew CronJob next run | depend lecture nouveau admin-token | si Phase 3 fait avant next run : **0 downtime** |
| keybuzz-api pods (consomment vault-root-token, vault-app-token) | aucun immediat ; tokens valides jusqu'a expiration TTL | **0 downtime** si rotation tokens apps via CronJob continue |
| keybuzz-backend pods (consomment vault-token, vault-app-token, etc.) | aucun immediat | **0 downtime** |
| seller-api pods (consomment vault-token) | aucun immediat | **0 downtime** |
| Postgres / Redis / RabbitMQ / MinIO infra | aucun (independant Vault) | **0 downtime** |
| Website / Admin v2 / Client / Studio | aucun (n'utilisent pas vault-admin-token) | **0 downtime** |
| **OTP signup / billing / Inbox / OAuth marketplaces** | aucun | **0 downtime** |

**Conclusion** : rotation `vault-admin-token` correctement
sequencee = **ZERO disruption applicative**. Tres safe.

---

## Risk register

| Risk ID | Severity | Finding | Action |
|---|---|---|---|
| R-Q1A-bis-1 | P0 | vault-admin-token K8s Secret EXPOSE PROBABLE pendant fenetre attaque k8s-worker compromis | rotation via Phase 1-7 design |
| R-Q1A-bis-2 | P0 indetermine | Policies attachees au vault-admin-token inconnues. Si root-policy = full sudo, attaquant a pu lire tout le KV Vault | verification Phase 1.1 + si root : rotation Vault Root Token aussi |
| R-Q1A-bis-3 | P1 | Vault Root Token regenerable via Shamir unseal (offline) ; si keyshares offline confirme = OK | Ludovic confirme |
| R-Q1A-bis-4 | P1 | vault-token-renew CronJob downtime potentiel si Phase 3 fait apres next scheduled run | recommandation : trigger Phase 3 + Phase 4 manuel avant 2026-05-17T03:00 UTC |
| R-Q1A-bis-5 | P1 | Audit logs Vault peut-etre pas active (`vault audit list`) | si pas active, recommander activation avant Phase 7 |
| R-Q1A-bis-6 | P2 | Possibilite anomalie usage indirecte ancien admin-token entre Phase 6 revocation et premier audit | inspection audit logs Phase 7 |
| R-Q1A-bis-7 | OK | ESO auth chain INDEPENDANTE de vault-admin-token | preserver, ne pas toucher auth/kubernetes config |
| R-Q1A-bis-8 | OK | Apps en runtime ne consomment pas vault-admin-token directement | preserver |

---

## Recommendations phase suivante Q-1A-bis-exec

### Conditions de GO

Avant Q-1A-bis-exec, Ludovic doit confirmer :
1. **Shamir unseal keys offline OK** (deja confirme)
2. **Decision rotation Vault Root Token aussi ou non** (depend policies admin-token)
3. **Verification policies vault-admin-token** :
   - Option recommandee : re-login Vault par Ludovic + `vault token lookup -accessor <admin-accessor>`
   - Option alternative : Ludovic confirme par GUI Vault ou souvenir setup initial
4. **Window operations decide** : ideal entre maintenant et 2026-05-17T03:00 UTC pour eviter race condition avec next CronJob run
5. **Vault audit log device** : verifier active OU activer en Phase 0 (mutation Vault, decision Ludovic)
6. **Backup K8s Secret pre-rotation** : Phase 0 (sauvegarde locale Ludovic only, jamais commit)

### Q-1A-bis-exec ordre execution

| Phase | Action | Mutation | Owner |
|---|---|---|---|
| 0 | Pre-flight : backup K8s secret vault-admin-token + verif policies + verif Vault audit log active | K8s read + optionnel mutation audit | Ludovic + CE assist |
| 1 | Decision policies + Vault Root rotation | n/a | Ludovic |
| 2 | Generation nouveau admin-token via root session | Vault create token | Ludovic offline |
| 3 | Patch K8s secret vault-admin-token | K8s mutation | Ludovic OR CE avec GO |
| 4 | Trigger manuel vault-token-renew job + verifier Complete | K8s job create + read | CE avec GO |
| 5 | Verification stabilite ESO + apps + services | read-only | CE |
| 6 | Revocation ancien admin-token | Vault mutation | Ludovic offline |
| 7 | Audit Vault logs ancien token + cleanup local backup | read-only audit + shred backup | CE + Ludovic |

### Apres Q-1A-bis-exec verde

Phase suivante AS.17.1Q-1B Vault control-plane trust restaure :
- KV secrets rotation peut commencer (30+ ExternalSecrets-managed)
- Suivi par Q-1C (15+ PROD manuels), Q-1D (infra direct), Q-1E (P1), Q-1F (validation), Q-1G (promotion PROD), Q-1H (P2)

---

## Brouillon commentaire Linear KEY-323 (NON poste)

```
Audit AS.17.1Q-1A-bis Vault admin/root token replacement design.
Rapport :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1A-bis-KEY-323-VAULT-ADMIN-TOKEN-REPLACEMENT-DESIGN-01.md

Verdict : GO ADMIN TOKEN REPLACEMENT DESIGN READY

ELEMENTS PRINCIPAUX :

1. Modele de menace : vault-management/vault-admin-token K8s Secret
   traite comme POTENTIALLY EXPOSED pendant fenetre attaque
   k8s-workers compromis (~14-17h max).

2. Architecture analysis :
   - ESO auth chain (K8s SA JWT vers roles keybuzz-external-secrets +
     eso-keybuzz) INDEPENDANTE du vault-admin-token. Rotation =
     ZERO disruption ESO.
   - vault-token-renew CronJob lit vault-admin-token comme TOKEN
     argument. Patch K8s Secret avant next CronJob run = continuite.
   - Vault tokens apps namespaces (vault-app/root/token) consommes
     par keybuzz-api + keybuzz-backend + seller-api. TTL period 768h.
     Rotation admin-token n'affecte pas tokens existants apps.
   - Shamir unseal keys confirme OFFLINE par Ludovic = pas de rekey.

3. Plan replacement Q-1A-bis-exec en 7 phases sequentielles :
   - Phase 0 : pre-flight backup K8s secret + verif policies + activate
     audit log
   - Phase 1 : decision rotation Vault Root Token aussi ou non
     (depend policies admin-token)
   - Phase 2 : generation nouveau admin-token via root session
     (Ludovic offline)
   - Phase 3 : patch K8s Secret vault-admin-token
   - Phase 4 : trigger manuel vault-token-renew job + verifier Complete
   - Phase 5 : verification stabilite ESO + apps + services
   - Phase 6 : revocation ancien admin-token
   - Phase 7 : audit Vault logs ancien token + cleanup local backup

4. Window operations recommandee : entre maintenant et 2026-05-17T03:00
   UTC (avant next CronJob scheduled run).

5. Disruption applicative ZERO si Phase 3+4 sequence correcte.

BLOQUEURS Q-1A-bis-exec :
- Verification policies attachees au vault-admin-token (BLOCKED par
  token operateur invalide ; Ludovic re-login Vault requis OU
  alternative)
- Decision rotation Vault Root Token : depend si vault-admin-token
  avait policy "root" (full sudo) ou policy admin-restricted

RISK REGISTER :
- P0 indetermine : si vault-admin-token avait policy root, attaquant
  a pu lire TOUT le KV Vault. Trust restoration necessite rotation
  Root Token + revocation, plus longue.
- P1 : sequence operations Phase 3 avant next CronJob run ; activation
  Vault audit logs
- OK : ESO independante, apps unaffected, unseal keys offline

Aucune mutation effectuee dans Q-1A-bis (design seulement). vault-admin-
token NON LU. Aucune valeur secret affichee. Conformite aux interdits
Ludovic.

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu.
NO GO KV secret rotation Q-1B maintenu jusqu'a admin-token trust
restaure post-Q-1A-bis-exec.
Status KEY-323 et KEY-322 inchanges.
```

A NE PAS poster sans GO Ludovic. Codex via connecteur Linear postera
apres GO commit.

---

## Hors scope / actions NON faites

- Aucune lecture du vault-admin-token actuel
- Aucune utilisation du vault-admin-token actuel
- Aucune commande mutation Vault (`vault write`, `vault token create`,
  `vault token revoke`, `vault operator rekey`, etc.)
- Aucune commande mutation K8s (`kubectl patch/apply/edit/delete`)
- Aucun rollout / restart de service
- Aucun appel provider externe
- Aucun affichage valeur token / root token / unseal key
- Aucun affichage K8s secret data
- Aucun commit Git infra du rapport AS.17.1Q-1A-bis (en attente GO -
  ce rapport untracked apres ecriture)
- Aucun comment Linear poste
- Aucun changement statut KEY-322 ni KEY-323
- Aucune rotation declenchee
- Aucun rekey Shamir
- Aucun touch a auth/kubernetes config (preserver ESO chain)
- Aucun token Hetzner reutilise

---

## Phrase cible finale

GO ADMIN TOKEN REPLACEMENT DESIGN READY. Architecture analysee :
ESO auth chain (K8s SA JWT) INDEPENDANTE du vault-admin-token,
rotation = ZERO disruption ESO/apps si Phase 3 (patch K8s secret)
sequencee avant Phase 4 (trigger CronJob run) avant Phase 6
(revocation). Window operations : maintenant -> 2026-05-17T03:00 UTC.
Bloqueurs : verification policies admin-token (BLOCKED token operateur
invalide), decision rotation Vault Root Token (depend policies).
Shamir unseal keys offline confirme = pas de rekey. vault-admin-token
NON LU, aucune mutation, aucune valeur secret affichee. NO GO KV
secret rotation Q-1B maintenu jusqu'a admin-token trust restaure
post-Q-1A-bis-exec. NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu.

---
