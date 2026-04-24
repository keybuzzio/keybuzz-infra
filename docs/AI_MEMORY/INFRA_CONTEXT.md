# Contexte Infra KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : point d'entree pour GitOps, K8s, DB, build et promotion.

## Dossiers

- `C:\DEV\KeyBuzz\V3\keybuzz-infra`
- `C:\DEV\KeyBuzz\V3\Infra`
- `C:\DEV\KeyBuzz\V3\k8s`
- `C:\DEV\KeyBuzz\V3\ansible`
- Inventaire detaille : `AI_MEMORY\INFRA_SERVERS_INSTALL_CONTEXT.md`

Le repo Git local observe est `C:\DEV\KeyBuzz\V3\keybuzz-infra`. La racine `C:\DEV\KeyBuzz` n'est pas un repo Git.

## Manifests K8s observes

Dans `keybuzz-infra/k8s` :

- `keybuzz-client-dev`
- `keybuzz-client-prod`
- `keybuzz-api-dev`
- `keybuzz-api-prod`
- `keybuzz-admin-v2-dev`
- `keybuzz-admin-v2-prod`
- `keybuzz-studio-dev`
- `keybuzz-studio-prod`
- `keybuzz-studio-api-dev`
- `keybuzz-studio-api-prod`
- `keybuzz-seller-dev`
- `keybuzz-backend-dev`
- `keybuzz-backend-prod`
- `website-dev`
- `website-prod`
- `litellm`
- `minio`
- `observability`
- `monitoring-alerts`
- `vault-token-renew`

## Architecture moderne documentee

- Kubernetes kubeadm HA, pas K3s comme source moderne.
- GitOps avec manifests `k8s/*` et ArgoCD.
- Postgres HA/Patroni.
- Acces applicatif Postgres via HAProxy `10.0.0.10:5432`.
- Redis, RabbitMQ, MinIO, Vault/External Secrets selon surfaces.
- Separation stricte DEV/PROD.

## DB

Source cle : `DB-ARCHITECTURE-CONTRACT.md`

Regle majeure : architecture dual-DB.

- Product DB : `keybuzz` / `keybuzz_prod`
- Backend Prisma DB : `keybuzz_backend` / `keybuzz_backend_prod`

Pieges :

- tables PascalCase et snake_case peuvent coexister;
- Amazon OAuth peut impliquer les deux bases;
- ne pas supprimer/deplacer une table legacy sans phase explicite;
- verifier quelle app consomme quelle DB.

## Source-of-truth Git/runtime

Sources cles :

- `PH147.RULES-CURSOR-PROCESS-LOCK-01.md`
- `PH152-GIT-SOURCE-OF-TRUTH-LOCK-01.md`
- `PH152.1-DEV-TRUTH-RECONSTRUCTION-FROM-PROD-AND-REPORTS-01.md`

Regles :

- repo clean avant build;
- build depuis Git, pas depuis pod/runtime/dist;
- pas de SCP source vers bastion;
- pas de `:latest`;
- tag image explicite;
- digest et rollback documentes;
- DEV avant PROD;
- rapport de phase obligatoire.

## Inventaire serveurs

Voir `INFRA_SERVERS_INSTALL_CONTEXT.md` pour la liste detaillee des 49 serveurs v3, les IPs privees/publiques, roles, FQDN et le sommaire d'installation module par module.

## Risques

- Manifests locaux parfois en retard sur runtime/rapports.
- Images DEV temporaires peuvent avoir ete deployees pendant validation humaine.
- Ancien historique K3s/Galera/ProxySQL peut apparaitre dans les docs mais ne doit pas dominer l'etat moderne.
- Ne pas conclure depuis une seule source : recouper rapport recent, manifest, runtime.
