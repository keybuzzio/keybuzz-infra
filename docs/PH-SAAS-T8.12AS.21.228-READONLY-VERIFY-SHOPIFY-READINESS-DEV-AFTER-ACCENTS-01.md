# PH-SAAS-T8.12AS.21.228 - Readonly verify Shopify readiness DEV after accents

Date: 2026-06-30

## Verdict

READY_DEV_STILL_VALIDATED / PROD_UNTOUCHED.

La reprise Shopify est saine après la correction des accents onboarding PH-21.227. Le runtime DEV conserve l'API Shopify readiness et le Client DEV conserve les entrées Shopify. La PROD n'a pas été modifiée.

## Scope

- Lecture seule.
- Vérification API DEV, Client DEV et GitOps.
- Croisement avec PH-21.224, PH-21.225-226 et PH-21.227.

Hors scope :

- Aucun OAuth Shopify réel.
- Aucun webhook replay.
- Aucun POST `/shopify/connect`, `/shopify/disconnect`, `/shopify/orders/sync`.
- Aucun fake event.
- Aucune mutation DB.
- Aucun secret lu ou affiché.
- Aucun build, docker push, apply, deploy ou mutation PROD.

## Sources relues

| Source | Résultat |
| --- | --- |
| PH-21.224 | Shopify non prêt avant hardening; P0 identifiés tenantGuard/HMAC/version/scope messaging/sync. |
| PH-21.225-226 | Hardening + readiness DEV validés; PROD untouched; gate restant = test réel Shopify DEV avant promotion. |
| PH-21.227 | Client DEV/PROD accents déployés; PROD construite accent-only sans patch Shopify DEV. |

## Source actuelle

| Repo | Branche | HEAD | Dirty |
| --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | b0ce5fc523f43d5b9684c77648f1f771a5e08697 | 0 |
| keybuzz-client | ph148/onboarding-activation-replay | 8646ee6e54fe0f656b10bd5071f38253b7007cbd | 0 |
| keybuzz-infra | main | 074ec1305dfa22010e7deabfe35cbbf30c9da47d | 0 |

Client DEV source lineage :

- `b14710f` : Shopify entrypoints visibles en DEV, sans claim messaging.
- `8646ee6` : correction accents onboarding appliquée au-dessus.

## Runtime DEV

| Service | Image | Digest | Ready | Generation | Restarts |
| --- | --- | --- | --- | --- | --- |
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.281-shopify-readiness-dev | sha256:88cbfd8c56668f44ec04b5fb631cb96dceed06da9e45e3a586ae0aa994405451 | 1/1 | 522/522 | 0 |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.281-onboarding-french-accents-dev | sha256:c335d708d7b140b9f03cb5ef78dd938f2d1fa92027dee42984afa36bfea1e76c | 1/1 | 1043/1043 | 0 |

Égalité vérifiée :

- manifest Git = last-applied = deployment spec = pod spec = pod imageID.

## Runtime markers

| Surface | Marker | Résultat |
| --- | --- | --- |
| API DEV | fichiers `shopify.routes.js` et `shopifyWebhook.routes.js` | PASS |
| API DEV | tenantGuard | PASS |
| API DEV | rawBody webhook HMAC | PASS |
| API DEV | `x-shopify-webhook-id` idempotence | PASS |
| API DEV | `app/uninstalled` | PASS |
| API DEV | `SHOPIFY_API_VERSION` / `2026-04` | PASS |
| Client DEV | Shopify visible dans bundle | PASS |
| Client DEV | `Commandes Shopify` présent | PASS |
| Client DEV | API DEV présente | PASS |
| Client DEV | API PROD absente | PASS |
| Client DEV | accents onboarding PH-21.227 présents | PASS |

## État PROD

PROD inchangée sur Shopify :

- API PROD reste `ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-prod`.
- Client PROD reste `ghcr.io/keybuzzio/keybuzz-client:v3.5.279-onboarding-french-accents-prod`.
- Le Client PROD ne contient pas la readiness Shopify DEV selon PH-21.227.

## Anti-régression IA / messages / connecteurs

- Shopify reste orders-first.
- Pas de claim messaging Shopify activé.
- Pas de fake webhook.
- Pas de replay.
- Pas de sync commandes déclenchée.
- Les features Amazon/Octopia/Inbox/AI ne sont pas modifiées par cette reprise read-only.

## Gate suivant

La suite technique correcte dépend d'une décision de promotion :

1. Test réel DEV Shopify avec une boutique de test, si Ludovic veut valider l'OAuth et la sync 90 jours avant PROD.
2. Promotion PROD GitOps de la readiness Shopify, uniquement avec GO explicite, en gardant les verrous :
   - API PROD depuis `b0ce5fc`.
   - Client PROD depuis une source PROD sûre qui combine accents + Shopify readiness, sans embarquer de drift DEV non validé.
   - Build args PROD explicites.
   - Bundle PROD avec `https://api.keybuzz.io`, sans `https://api-dev.keybuzz.io`.
   - GitOps strict, rollback documenté.

## No side effect

- Aucun build.
- Aucun docker push.
- Aucun kubectl apply.
- Aucun OAuth Shopify.
- Aucun webhook.
- Aucun event.
- Aucune mutation DB.
- Aucun secret lu ou affiché.
- Aucune action Linear.

STOP.
