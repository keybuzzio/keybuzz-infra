# Surfaces operationnelles KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : carte des SaaS et environnements exposes.

## Vue d'ensemble

KeyBuzz contient plusieurs produits/surfaces, chacun avec son couple DEV/PROD attendu :

| Produit | DEV | PROD | Role |
|---|---|---|---|
| Client SaaS | `client-dev.keybuzz.io` | `client.keybuzz.io` | SaaS support client, inbox, orders, billing, IA, autopilot. |
| API SaaS | `api-dev.keybuzz.io` | `api.keybuzz.io` | API Fastify principale du client SaaS. |
| Admin v2 | `admin-dev.keybuzz.io` | `admin.keybuzz.io` | Cockpit admin/ops/tenants/billing/metrics. |
| Studio | `studio-dev.keybuzz.io` | `studio.keybuzz.io` | Marketing Operating System autonome. |
| Studio API | `studio-api-dev.keybuzz.io` | `studio-api.keybuzz.io` | API Fastify de Studio. |
| Seller | `seller-dev.keybuzz.io` | `seller.keybuzz.io` | SaaS seller/catalog/connecteurs. |
| Seller API | `seller-api-dev.keybuzz.io` | `seller-api.keybuzz.io` | API FastAPI seller. |

Note : Ludovic a corrige la nomenclature : on dit `seller`, pas une variante PROD separee. Dans les manifests locaux `keybuzz-infra/k8s`, j'ai trouve `keybuzz-seller-dev`; verifier le runtime/deploiement `seller` avant toute action hors DEV.

## Client SaaS

Chemin local principal : `C:\DEV\KeyBuzz\V3`

Manifests :

- DEV : `keybuzz-infra/k8s/keybuzz-client-dev`
- PROD : `keybuzz-infra/k8s/keybuzz-client-prod`

Hosts :

- DEV : `client-dev.keybuzz.io`
- PROD : `client.keybuzz.io`

Images vues dans manifests locaux :

- DEV : `ghcr.io/keybuzzio/keybuzz-client:v3.5.63-ph151.2-case-summary-clean-dev`
- PROD : `ghcr.io/keybuzzio/keybuzz-client:v3.5.63-ph151.2-case-summary-clean-prod`

Attention : plusieurs rapports PH154 indiquent des images DEV plus recentes deployees temporairement (`v3.5.80`, `v3.5.83`, `v3.5.84`) en attente de validation humaine. Les manifests locaux peuvent donc ne pas raconter seuls l'etat runtime. Toujours recouper manifest, rapport recent et runtime.

## API SaaS

Hosts connus :

- DEV : `api-dev.keybuzz.io`
- PROD : `api.keybuzz.io`

Role :

- conversations/messages;
- inbound/outbound;
- orders/tracking;
- tenant context;
- billing/KBActions/Stripe;
- autopilot/IA engines;
- metrics internes.

Etat recent important :

- `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-PROD-PROMOTION-01.md` documente API DEV/PROD en `v3.5.91-autopilot-escalation-handoff-fix-*`.
- `PH-AUTOPILOT-E2E-TRUTH-AUDIT-01.md` documente que le blocage courant de l'autopilot est le plan gate de `ecomlg-001`, pas une panne BFF/API.

## Admin v2

Chemin local :

- `C:\DEV\KeyBuzz\keybuzz-admin-v2`

Manifests :

- DEV : `keybuzz-infra/k8s/keybuzz-admin-v2-dev`
- PROD : `keybuzz-infra/k8s/keybuzz-admin-v2-prod`

Hosts :

- DEV : `admin-dev.keybuzz.io`
- PROD : `admin.keybuzz.io`

Images vues dans manifests :

- DEV : `ghcr.io/keybuzzio/keybuzz-admin:v2.10.6-ph-t8-3-1d-metrics-trial-paid-dev`
- PROD : voir manifest, corrige recemment autour de PH-T8.3.1E.

Point critique :

- `KEYBUZZ_API_INTERNAL_URL` doit utiliser le port service K8s.
- En PROD, `keybuzz-api.keybuzz-api-prod.svc.cluster.local` sans `:3001`.
- En DEV, `keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001` est correct si le service expose 3001.

## Studio

Chemins locaux :

- Front : `C:\DEV\KeyBuzz\V3\keybuzz-studio`
- API : `C:\DEV\KeyBuzz\V3\keybuzz-studio-api`

Manifests :

- Studio DEV : `keybuzz-infra/k8s/keybuzz-studio-dev`
- Studio PROD : `keybuzz-infra/k8s/keybuzz-studio-prod`
- Studio API DEV : `keybuzz-infra/k8s/keybuzz-studio-api-dev`
- Studio API PROD : `keybuzz-infra/k8s/keybuzz-studio-api-prod`

Hosts :

- DEV front : `studio-dev.keybuzz.io`
- PROD front : `studio.keybuzz.io`
- DEV API : `studio-api-dev.keybuzz.io`
- PROD API : `studio-api.keybuzz.io`

Images vues dans manifests locaux :

- Studio front DEV/PROD : `v0.1.0-dev/prod`
- Studio API DEV/PROD : `v0.1.0-dev/prod`

Attention : `STUDIO-MASTER-REPORT.md` documente des phases beaucoup plus avancees (`v0.8.x`, LLM, learning, quality, client intelligence). Les manifests locaux semblent potentiellement plus anciens que les rapports. Pour Studio, toujours lire `STUDIO-MASTER-REPORT.md` et verifier runtime avant de conclure.

## Seller

Chemins locaux :

- `C:\DEV\KeyBuzz\V3\seller-api`
- `C:\DEV\KeyBuzz\V3\keybuzz-seller`

Manifests trouves localement :

- DEV : `keybuzz-infra/k8s/keybuzz-seller-dev`
- `seller` : pas de manifest dedie trouve localement dans la passe 2026-04-21; ne pas lui inventer une nomenclature separee

Hosts :

- `seller-dev.keybuzz.io`
- `seller-api-dev.keybuzz.io`
- `seller.keybuzz.io`
- `seller-api.keybuzz.io`

Images vues dans manifests DEV :

- seller-api : `ghcr.io/keybuzzio/seller-api:*`
- seller-client : `ghcr.io/keybuzzio/seller-client:v2.0.7-ph-prod-ftp-02b`

Role d'apres `PH-S01-SELLER-FOUNDATIONS-REPORT.md` :

- SaaS seller avec SSO KeyBuzz;
- schema DB `seller`;
- registry marketplaces;
- catalog sources;
- secret refs Vault;
- FastAPI backend;
- Next.js seller-client;
- isolation tenant via `X-Tenant-Id`.

## Regle de reprise

Pour toute demande, identifier d'abord la surface :

1. `client` / `client-dev`
2. `api` / `api-dev`
3. `admin` / `admin-dev`
4. `studio` / `studio-dev`
5. `studio-api` / `studio-api-dev`
6. `seller` / `seller-dev`
7. `seller-api` / `seller-api-dev`

Puis lire le rapport recent correspondant avant d'ecrire un prompt ou de toucher au code.
