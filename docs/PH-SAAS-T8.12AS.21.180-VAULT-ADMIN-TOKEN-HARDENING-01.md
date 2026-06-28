# PH-SAAS-T8.12AS.21.180 - Vault admin token hardening

## Verdict

READY_CLOSED.

Dette critique fermee: `vault-management/vault-admin-token` ne stocke plus un token Vault `root` dans Kubernetes. Il stocke maintenant un token limite `default,keybuzz-vault-renewer`, orphan, renewable, periodique 768h.

## Contexte

Apres la reparation Vault/Amazon de PH-21.177, un controle read-only a montre que `vault-management/vault-admin-token` etait redevenu un token `root`:

| Champ | Avant |
|---|---|
| display_name | `root` |
| policies | `root` |
| ttl | `0` |
| orphan | `true` |
| root_policy_present | `YES` |
| Secret resourceVersion | `91185525` |

Ce token est consomme uniquement par le CronJob `vault-token-renew` dans `vault-management`.

## Objectif

Remplacer le token root stocke dans le Secret Kubernetes par un token limite capable de faire uniquement les operations necessaires au CronJob:

- `auth/token/lookup-self`
- `auth/token/renew`
- `auth/token/create`

Hors scope volontaire:

- ne pas revoquer le root token externe de Ludovic;
- ne pas toucher aux unseal keys;
- ne pas lire/afficher de secret;
- ne pas tourner les secrets applicatifs si leurs TTL sont sains.

## Source de verite verifiee

CronJob runtime:

| Objet | Valeur |
|---|---|
| Namespace | `vault-management` |
| CronJob | `vault-token-renew` |
| Schedule | `0 3 * * *` |
| Last successful avant hardening | `2026-06-28T03:00:07Z` |
| VAULT_ADDR runtime | `http://vault.default.svc.cluster.local:8200` |
| TOKEN_PERIOD | `768h` |
| POLICIES creees pour app tokens | `keybuzz-app-read,keybuzz-backend-rw` |

Policy Vault verifiee:

```hcl
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew" {
  capabilities = ["update"]
}

path "auth/token/create" {
  capabilities = ["create", "update", "sudo"]
}
```

## Mutation effectuee

Un nouveau token Vault a ete cree en memoire avec:

- `-orphan`
- `-period=768h`
- `-policy=keybuzz-vault-renewer`
- display name `vault-admin-token-ph21180-2026-06-28`

Le Secret Kubernetes `vault-management/vault-admin-token` a ete applique avec la nouvelle valeur sans afficher le token.

| Controle | Resultat |
|---|---|
| Secret resourceVersion avant | `91185525` |
| Secret resourceVersion apres | `91376594` |
| resourceVersion changed | OK |
| token value printed | NO |
| temp token files shredded | OK |

## Verification post-hardening

Lookup Vault du token stocke dans Kubernetes:

| Champ | Apres |
|---|---|
| display_name | `token-vault-admin-token-ph21180-2026-06-28` |
| policies | `default,keybuzz-vault-renewer` |
| ttl | `2764787` puis decroissant |
| period | `2764800` |
| renewable | `true` |
| orphan | `true` |
| root_policy_present | `NO` |

Capabilities:

| Path | Capability |
|---|---|
| `auth/token/lookup-self` | `read` |
| `auth/token/create` | `create, sudo, update` |
| `auth/token/renew` | `update` |
| `secret/metadata/keybuzz/llm_provider_credit/prod/monitor_token` | `deny` |
| `secret/data/keybuzz/amazon/prod/switaa-sasu-mqwuvv8z` | `deny` |

Conclusion: le token K8s ne peut plus lire/ecrire KV et n'est plus un root token.

## App token TTL read-only

| Token applicatif | TTL |
|---|---:|
| `keybuzz-api-prod/vault-root-token` | `2732657` |
| `keybuzz-api-dev/vault-root-token` | `2732657` |
| `keybuzz-backend-prod/vault-app-token` | `2732659` |
| `keybuzz-backend-dev/vault-app-token` | `2732659` |

Ces TTL sont au-dessus du seuil de 7 jours. Aucune rotation applicative n'etait necessaire.

## Validation CronJob

Deux jobs manuels ont ete lances pour valider le fonctionnement:

1. Avant correction de wording script: `vault-renew-ph21180-20260628070722`
2. Apres correction de wording script: `vault-renew-ph21180-20260628070904`

Resultat final:

```text
OK: Admin token read (95 chars)
OK: Admin token valid (ttl=2764643)
TOKEN1: ttl=2732501s (759h)
OK: Healthy
TOKEN2: ttl=2732503s (759h)
OK: Healthy
=== COMPLETE: renewed=0 recreated=0 errors=0 ===
```

Aucune recreation, aucun restart workload declenche par le CronJob.

## Patch GitOps configmap

Le script du CronJob disait encore `Root token` dans ses logs alors que le token attendu est maintenant un admin token limite.

Commit infra:

`9286820b1feeda2843ea64618350403f7cd668ad fix(vault): label renewer token as admin token`

Fichier modifie:

`k8s/vault-token-renew/configmap-script.yaml`

Changement:

- variable interne `ROOT_TOKEN` renommee `ADMIN_TOKEN`;
- logs `Root token` remplaces par `Admin token`;
- appels renew/create inchanges fonctionnellement.

Validation:

| Test | Resultat |
|---|---|
| `git diff --check` | PASS |
| `kubectl apply --dry-run=client -f k8s/vault-token-renew/configmap-script.yaml` | PASS |
| `kubectl apply --dry-run=server -f k8s/vault-token-renew/configmap-script.yaml` | PASS |
| commit + push avant apply | PASS |
| `kubectl apply -f k8s/vault-token-renew/configmap-script.yaml` | PASS |
| ConfigMap resourceVersion | `91377371` |
| manual CronJob post-apply | PASS |

## No side-effect

- Aucun token affiche.
- Aucun secret affiche.
- Aucun root token revoke.
- Aucun unseal key lu/utilise.
- Aucun KV Vault lu/ecrit.
- Aucun app token recree.
- Aucun deployment redemarre par le CronJob.
- Aucun build Docker.
- Aucun event tracking/fake event.
- Aucun formulaire, checkout ou DB mutation applicative.

## Break-glass root token

Le root token initial n'a pas ete revoque volontairement.

Raison: il peut correspondre au token break-glass conserve par Ludovic hors cluster. La dette fermee ici est l'exposition d'un root token dans Kubernetes, pas la suppression de l'acces root admin externe.

Etat final attendu:

- root token externe: responsabilite Ops/Admin Ludovic, hors Kubernetes;
- token Kubernetes `vault-admin-token`: non-root, limite au renouvellement/creation de tokens applicatifs.

## Backlog produit

Demande Ludovic conservee pour phase future: ameliorer les reponses IA et brouillons IA auto-generes pour les rendre plus humains, avec un equivalent de consigne type `/humain` pour OpenAI/ChatGPT et autres providers. Hors scope PH-21.180.

## Verdict final

GO VAULT ADMIN TOKEN HARDENING READY_CLOSED PH-SAAS-T8.12AS.21.180.

STOP.
