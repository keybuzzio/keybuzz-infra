# PH-SAAS-T8.12AS.21.229 - Readonly design Shopify PROD promotion safety

Date: 2026-06-30

## Verdict

READY_FOR_EXPLICIT_PROD_GO.

La readiness Shopify DEV reste valide après PH-21.227. La promotion PROD est techniquement préparée, mais elle doit rester derrière un GO explicite car elle modifie API PROD et Client PROD.

## Scope

- Lecture seule.
- Design de promotion PROD Shopify.
- Aucun build, push, deploy ou mutation runtime.

Hors scope :

- Aucun OAuth Shopify.
- Aucun webhook replay.
- Aucun `/shopify/orders/sync`.
- Aucun fake event.
- Aucune mutation DB.
- Aucun secret lu ou affiché.

## Baseline PROD actuelle

| Service | Image PROD actuelle | Ready | Generation |
| --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-prod | 1/1 | 439/439 |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.279-onboarding-french-accents-prod | 1/1 | 439/439 |

## Sources proposées

| Service | Source build proposée | Justification |
| --- | --- | --- |
| API PROD | `b0ce5fc523f43d5b9684c77648f1f771a5e08697` sur `ph147.4/source-of-truth` | Descendant direct de la source PROD actuelle `f030088d`; contient seulement les commits Shopify hardening/readiness au-dessus. |
| Client PROD | `8646ee6e54fe0f656b10bd5071f38253b7007cbd` sur `ph148/onboarding-activation-replay` | Descendant direct de la source PROD précédente `e7aefa`; contient `9371e30`, `b14710f` et les accents PH-21.227. |

Preuves ancestry :

- API : `f030088d` est ancêtre de `b0ce5fc`.
- Client : `e7aefa15` est ancêtre de `8646ee6`.

## Commits entrants

### API

| Commit | Scope |
| --- | --- |
| `28bcfa1e` | Shopify tenantGuard, OAuth shop/state validation, raw-body HMAC, webhook idempotence, uninstall handling, API version. |
| `b0ce5fc5` | Shopify initial 90-day paginated sync readiness. |

### Client

| Commit | Scope |
| --- | --- |
| `9371e30` | Shopify messaging disabled until supported. |
| `b14710f` | Shopify connector entrypoints visibles. |
| `8646ee6` | Accents onboarding PH-21.227. |

## Tags cibles proposés

| Service | Tag cible | Registry safety |
| --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.282-shopify-readiness-prod` | absent |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.282-shopify-readiness-prod` | absent |

Rollback :

- API PROD : `v3.5.279-ai-response-humanness-prod`.
- Client PROD : `v3.5.279-onboarding-french-accents-prod`.

## Build requirements

### API PROD

- Build-from-git depuis commit `b0ce5fc`.
- Repo clean obligatoire.
- Tests minimum avant build :
  - TypeScript.
  - tests PH-21.225 Shopify hardening.
  - tests PH-21.226 Shopify readiness.
  - tests AI response humanness / non-régression si disponibles.
- Audit image :
  - Shopify routes présentes.
  - `tenantGuard` présent.
  - HMAC rawBody présent.
  - `x-shopify-webhook-id` présent.
  - `app/uninstalled` présent.
  - `SHOPIFY_API_VERSION` / `2026-04` présent.

### Client PROD

- Build-from-git depuis commit `8646ee6`.
- Build args PROD explicites obligatoires :
  - `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
  - `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
  - IDs tracking PROD existants inchangés.
- Audit bundle obligatoire avant push :
  - `https://api.keybuzz.io` présent.
  - `https://api-dev.keybuzz.io` absent.
  - Shopify visible.
  - `Commandes Shopify` présent.
  - claim messaging Shopify absent.
  - accents onboarding PH-21.227 présents.
  - fake StartTrial/Purchase/CompletePayment absent.

## GitOps requirements

Modifier uniquement :

- `k8s/keybuzz-api-prod/deployment.yaml`
- `k8s/keybuzz-client-prod/deployment.yaml`

Puis :

- commit infra.
- push infra.
- `kubectl apply -f` sur les deux manifests.
- `kubectl rollout status`.
- vérifier runtime = manifest = last-applied = pod imageID.

Commandes interdites :

- `kubectl set image`
- `kubectl set env`
- `kubectl patch`
- `kubectl edit`

## Validation post-apply

| Surface | Validation |
| --- | --- |
| API PROD | pod ready 1/1, restarts 0, health OK. |
| Client PROD | pod ready 1/1, restarts 0, smoke `/channels` auth redirect normal. |
| Shopify API | `/shopify/status` sans tenant/auth ne doit pas exposer de donnée. |
| Bundle Client | API PROD présente, API DEV absente, Shopify visible, messaging claim absent. |
| Secrets | metadata-only, aucune valeur lue/décodée. |
| DB | read-only snapshot avant/après, delta 0 si aucun trafic réel. |
| Tracking | aucun fake event. |

## Anti-régression IA / messages / connecteurs

- Shopify reste orders-first.
- `supports_messaging=false` tant que l'ingestion réelle de messages Shopify n'existe pas.
- Ne pas casser Amazon, Octopia, Inbox, commandes, playbooks, AI drafts, Agent KeyBuzz.
- Vérifier que le Client ne présente pas Shopify comme canal de messagerie complet.

## Gate produit

Deux chemins possibles :

1. Test réel DEV avec boutique Shopify de test avant PROD.
2. Promotion PROD directement si Ludovic accepte le risque contrôlé : les hardenings P0 sont corrigés et la promotion ne déclenche aucun OAuth/sync/webhook par elle-même.

Dans les deux cas, la prochaine mutation PROD demande un GO explicite.

## No side effect

- Aucun build.
- Aucun push image.
- Aucun apply.
- Aucun OAuth Shopify.
- Aucun webhook.
- Aucun sync.
- Aucune mutation DB.
- Aucun secret lu.
- Aucune action Linear.

STOP.
