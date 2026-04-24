# Contexte Seller KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : point d'entree pour `seller` / `seller-dev`.

## Surfaces locales

Chemins :

- API historique/directe : `C:\DEV\KeyBuzz\V3\seller-api`
- Workspace seller : `C:\DEV\KeyBuzz\V3\keybuzz-seller`
- Client seller : `C:\DEV\KeyBuzz\V3\keybuzz-seller\seller-client`
- API seller dans workspace : `C:\DEV\KeyBuzz\V3\keybuzz-seller\seller-api`

Manifests trouves :

- DEV : `C:\DEV\KeyBuzz\V3\keybuzz-infra\k8s\keybuzz-seller-dev`
- `seller` : pas de manifest dedie trouve localement pendant la passe 2026-04-21

Hosts DEV attendus :

- `seller-dev.keybuzz.io`
- `seller-api-dev.keybuzz.io`

Hosts `seller` :

- `seller.keybuzz.io`
- `seller-api.keybuzz.io`

## Stack

Seller API :

- FastAPI
- Python 3.12
- SQLAlchemy async
- Alembic
- Redis
- RabbitMQ
- boto3
- zeep

Seller client :

- Next.js, structure app router detectee
- routes dashboard : `catalog-sources`, `marketplaces`, `secret-refs`, `tenants`
- routes API client : `auth`, `seller`

## Etat documentaire

Source cle : `PH-S01-SELLER-FOUNDATIONS-REPORT.md`

Role documente :

- SaaS seller separe;
- SSO depuis client-dev;
- schema DB `seller`;
- registry marketplaces;
- catalog sources;
- secret refs;
- isolation tenant via `X-Tenant-Id`;
- fondation event-driven avec Redis/RabbitMQ selon architecture.

## Code observe

Dans `seller-api` :

- `app/api/v1/health.py`
- `app/models/tenant.py`
- `app/models/stock.py`
- `app/models/sync.py`
- `app/models/base.py`

Cette surface semble beaucoup plus jeune que client/admin/API. Ne pas supposer une parite DEV/PROD sans verification runtime.

## Regles

- Toujours verifier quel dossier seller est la source active avant patch.
- Ne pas inventer une variante PROD separee : la nomenclature corrigee est `seller`.
- Verifier runtime/deploiement `seller` avant toute action hors `seller-dev`.
- Maintenir isolation tenant stricte.
- Ne jamais exposer secrets marketplace, utiliser references/secrets.
