# PH-SAAS-T8.12AS.20.56-READONLY-VERIFY-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-DEV-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.56 (READONLY VERIFY API DEV + plan trigger)
> Environnement : DEV read-only strict ; 0 POST/trigger/backfill/mutation/deploy/kubectl apply

## 1. Verdict

GO READONLY VERIFY AMAZON INBOUND ADDRESS VALIDATION SYNC DEV READY PH-SAAS-T8.12AS.20.56

Le correctif PH-20.52 est ACTIF en runtime API DEV (v3.5.260-amazon-inbound-address-sync-dev, imageID
sha256:b05da3d78801..., markers presents). L'audit DB DEV ne montre AUCUN split de type as0yom
(Backend VALIDATED + Product/API PENDING sur une ligne existante). Le bridge applicatif
(POST /channels/activate-amazon) est identifie, idempotent, tenant-scope, promote-only : c'est le
mecanisme sur pour exercer la sync sans SQL manuel. Recommandation : Option A (re-declencher le
bridge), sous phase GO dediee PH-20.57. Aucun bouton de validation Amazon dans Channels.

## 2. Rappel UX (important)

Il n'existe PAS de bouton de validation Amazon dans Channels. L'action utilisateur disponible reste
retirer + reconnecter OAuth Amazon ; techniquement, le bridge activate-channels peut etre
re-declenche sous phase GO dediee. Aucune action n'a ete executee dans PH-20.56.

## 3. Runtime (E0)

| env | service | namespace | image | imageID digest | ready | restarts | verdict |
|---|---|---|---|---|---:|---:|---|
| DEV | keybuzz-api | keybuzz-api-dev | v3.5.260-amazon-inbound-address-sync-dev | sha256:b05da3d78801a432851d2cd14c58cc6a4141f314c8539c12cc3a126b821b7a7e | true | 0 | OK (== GHCR PH-20.54) |
| PROD | keybuzz-api | keybuzz-api-prod | v3.5.259-ai-assist-notification-scope-prod | - | 1/1 | - | intact |
| DEV/PROD | keybuzz-outbound-worker | keybuzz-api-* | v3.5.165-escalation-flow-* | - | 1/1 | - | intact |
| DEV | keybuzz-client | keybuzz-client-dev | v3.5.259-ai-assist-notification-scope-dev | - | - | - | intact |

Bastion install-v3 / 46.62.171.61 (aucune trace 51.159.99.247).

## 4. Markers runtime (E1, pod API DEV)

| marker | expected | observed | verdict |
|---|---|---|---|
| normalizeInboundValidationStatus (helper dist) | present | 2 | OK |
| normalizeInboundValidationStatus (route) | present | 2 | OK |
| validationStatus (route) | present | 2 | OK |
| marketplaceStatus (route) | present | 2 | OK |
| ON CONFLICT (route) | present | 3 | OK |
| promote-only validationStatus CASE (route) | present | 1 | OK |
| lastInboundAt (route) | absent par design | 0 | OK (non porte par le payload bridge, cf PH-20.52 gap ; gate worker lit validationStatus, pas lastInboundAt) |
| worker gate validationStatus='VALIDATED' (outboundWorker) | intact | 1 | OK |
| messages gate validationStatus='VALIDATED' | intact | 1 | OK |
| determineAmazonProvider | present | 3 | OK |
| determineAiAssistNotificationSkip | present | 2 | OK |

Fix PH-20.52 confirme EN RUNTIME DEV. AI Assist (PH-20.49) et provider Amazon intacts.

## 5. Audit split DB DEV (E2, read-only)

Product/API DB DEV : 23 adresses amazon. Backend DB DEV : 35 adresses amazon. Comparaison par
(tenant, country) (le bridge fait ON CONFLICT sur tenantId+marketplace+country, pas sur token) :

| tenant | country | backend_status | api_status | classification |
|---|---|---|---|---|
| ecomlg-001 | FR | VALIDATED | VALIDATED | SYNC_OK |
| tenant_test_dev | FR | VALIDATED | (absent) | BACKEND_VALIDATED_API_MISSING (cas exploitable Option A) |
| ecomlg-001 | BE/ES/IT | PENDING | VALIDATED | API_VALIDATED_BACKEND_PENDING (Product en avance) |
| ecomlg-001 | DE | (absent) | VALIDATED | API_VALIDATED_BACKEND_MISSING |
| ecomlg07-...-mn7pn69e | FR/IT | (absent) | VALIDATED | API_VALIDATED_BACKEND_MISSING |
| test-amz-truth02-... | FR | (absent) | VALIDATED | API_VALIDATED_BACKEND_MISSING |
| switaa-mn9ioy5j | FR | (absent) | VALIDATED | API_VALIDATED_BACKEND_MISSING |
| switaa-sasu-mnc1x4eq | DE/FR | PENDING | VALIDATED | API_VALIDATED_BACKEND_PENDING |
| keybuzz-mnqnjna8 | DE/ES/IT/FR | PENDING | PENDING | SYNC_OK (les deux PENDING) |
| switaa-sasu-mnc1x4eq | ES/PL/UK/NL/MX/SE | PENDING | PENDING | SYNC_OK |
| w3lg-mnfwmtof, olyara369-... | FR | PENDING | PENDING | SYNC_OK |

Finding cle : **0 cas BACKEND_VALIDATED_API_PENDING (type as0yom) en DEV.** Le split PROD as0yom n'est
PAS reproduit en DEV (attendu : as0yom est PROD). Le pattern DEV dominant est l'INVERSE
(Product VALIDATED / Backend PENDING ou MISSING) -> le promote-only protege : un re-trigger ne
downgrade jamais ces lignes. Divergence de tokens entre les 2 bases observee (generation
independante) ; non pertinente pour le gate (qui lit validationStatus), et le bridge re-aligne le
token via ON CONFLICT DO UPDATE.

## 6. Audit chemin du bridge (E3, source read-only, NON appele)

| trigger/path | method | auth/tenant | reads | writes | idempotent | risk | verdict |
|---|---|---|---|---|---|---|---|
| BFF app/api/amazon/activate-channels -> API POST /channels/activate-amazon (channelsRoutes:122) | POST | session (BFF) + x-tenant-id / body.tenantId (API) ; tenant-scope | Backend GET /api/v1/marketplaces/amazon/inbound-connection (connection READY + addresses[].status) ; product DB existant | product DB : inbound_connections (ON CONFLICT tenantId,marketplace), inbound_addresses (ON CONFLICT tenantId,marketplace,country, PROMOTE-ONLY) ; activation canaux + inbound_email | OUI (ON CONFLICT DO UPDATE, promote-only, converge) | faible : 1 tenant, jamais de downgrade VALIDATED, promotion seulement si Backend READY+VALIDATED | SUR pour trigger DEV scope |

Garde : ligne 133 `if (backendConnection && backendConnection.status === 'READY' && backendConnection.id)`.
Effet attendu post-PH-20.52 : si Backend addr.status=VALIDATED, la ligne product/API correspondante
est promue (ou creee) VALIDATED -> le worker outbound passe ensuite le gate.

## 7. Dry-run as0yom (E4, raisonnement, NON execute)

Sur la base PH-20.51 (PROD : Backend as0yom VALIDATED / product PENDING) + code PH-20.52 : un
re-trigger du bridge propagerait VALIDATED vers la product/API DB (ON CONFLICT DO UPDATE CASE WHEN
VALIDATED), le worker outbound passerait alors le gate et tenterait l'envoi SMTP. NON execute ici
(as0yom est PROD ; PH-20.56 ne touche pas PROD).

| option | action | mutations | risque | rollback | recommendation |
|---|---|---|---|---|---|
| A | re-declencher le bridge applicatif (POST /channels/activate-amazon via activate-channels) sous phase GO dediee | inbound_addresses promote-only (VALIDATED si Backend VALIDATED) | faible (idempotent, tenant-scope, promote-only, jamais de downgrade) | re-trigger inverse impossible mais promote-only = pas de regression ; sinon revert image | RECOMMANDEE |
| B | backfill SQL cible UPDATE product inbound_addresses | UPDATE direct | moyen/eleve (contourne la logique applicative, risque humain) | UPDATE inverse documente | a eviter sauf urgence |
| C | Ludovic retire + reconnecte OAuth Amazon (flux produit) | via pipeline normal | faible mais action utilisateur lourde + deja faite en PROD | n/a | acceptable si flux produit choisi |

Recommandation : **Option A** (bridge idempotent + tenant/canal-scope + promote-only). Eviter le SQL
manuel (Option B) sauf urgence. En DEV, cas exploitable pour exercer la promotion = tenant_test_dev/FR
(Backend VALIDATED, Product absent -> le bridge creerait la ligne product VALIDATED).

## 8. No side-effect (E5)

| signal | before/ref (PH-20.55) | now (PH-20.56) | delta | interpretation |
|---|---:|---:|---:|---|
| outbound_deliveries (product DEV) | 310 | 310 | 0 | aucun outbound declenche par cette phase |
| ai_suggestion_events (product DEV) | 2718 | 2718 | 0 | aucune generation IA |
| ai_actions_ledger (product DEV) | 550 | 550 | 0 | aucun debit |
| inbound_addresses (product DEV) | 23 | 23 | 0 | aucune mutation inbound |
| messages (product DEV) | n/a | 1872 | n/a | reference (read-only) |
| API DEV restarts | 0 | 0 | 0 | pod stable |

Aucun POST applicatif, aucun trigger sync, aucun reconnect OAuth, aucun backfill, aucune mutation DB,
aucun fake event. SELECT/get/logs/exec lecture uniquement.

## 9. PROD intact (E6)

| signal | expected | observed | verdict |
|---|---|---|---|
| API PROD image | v3.5.259-ai-assist-notification-scope-prod | v3.5.259-...-prod (1/1) | intact |
| manifests PROD | inchanges | aucun touche | OK |
| as0yom PROD | reste split (non corrige ici) | non touche | OK (hors scope) |

## 10. Prochaine action

Option A confirmee : GO TRIGGER AMAZON INBOUND ADDRESS VALIDATION SYNC DEV PH-SAAS-T8.12AS.20.57
(mutation DEV explicite, scopee tenant/canal, before/after DB, rollback/compensation, sans SQL manuel
si le bridge applicatif suffit). Cible DEV d'exercice : tenant_test_dev/FR (Backend VALIDATED, Product
absent). PROD/as0yom reste bloquee jusqu'a validation DEV complete et GO PROD explicite.

## 11. Phrase cible

GO READONLY VERIFY AMAZON INBOUND ADDRESS VALIDATION SYNC DEV READY PH-SAAS-T8.12AS.20.56

STOP.
