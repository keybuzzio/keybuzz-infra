# PH-SAAS-T8.12AS.20.55-APPLY-API-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-DEV-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.55 (APPLY GITOPS DEV - image API DEV sync validation inbound)
> Environnement : DEV / GitOps strict API DEV uniquement ; AUCUN build, push, PROD, Client, backend, outbound-worker, mutation DB, backfill, trigger sync

## 1. Verdict

GO APPLY API AMAZON INBOUND ADDRESS VALIDATION SYNC DEV GITOPS READY PH-SAAS-T8.12AS.20.55

API DEV deployee via GitOps strict sur l'image PH-20.54. Commit+push AVANT apply (deploy commit
43085df). runtime = manifest = last-applied = digest GHCR. Markers du patch presents dans le pod.
Aucun traitement involontaire (compteurs DB DEV identiques before/after). PROD, Client, backend,
outbound-worker intacts. Aucun backfill as0yom (hors scope, non execute). Reste : GO READONLY VERIFY
DEV (PH-20.56).

## 2. Rappel UX (important)

Il n'existe PAS de bouton de validation Amazon dans Channels et cette phase n'en cree aucun. Le sujet
est la synchronisation de statut Backend -> product DB API. Cette phase deploie le correctif de sync
dans API DEV ; elle ne corrige PAS encore la ligne existante as0yom en PROD et ne tente pas de le
faire.

## 3. Runtime avant / apres

| service | namespace | image avant | image apres | imageID digest | ready | restarts |
|---|---|---|---|---|---:|---:|
| keybuzz-api | keybuzz-api-dev | v3.5.259-ai-assist-notification-scope-dev | v3.5.260-amazon-inbound-address-sync-dev | sha256:b05da3d78801... | 1/1 | 0 |
| keybuzz-outbound-worker | keybuzz-api-dev | v3.5.165-escalation-flow-dev | (inchange) | - | 1/1 | - |
| keybuzz-api | keybuzz-api-prod | v3.5.259-...-prod | (inchange) | - | 1/1 | - |

Bastion install-v3 / 46.62.171.61 (aucune trace 51.159.99.247). infra avant 1528252, dirty 0.
GHCR cible presente, config digest sha256:87c8d01b49fa... (== PH-20.54).

## 4. Manifest diff

| fichier | changement | rollback | risque |
|---|---|---|---|
| k8s/keybuzz-api-dev/deployment.yaml (ligne image) | v3.5.259-ai-assist-notification-scope-dev -> v3.5.260-amazon-inbound-address-sync-dev (+ commentaire PH-20.55/digests) | v3.5.259-ai-assist-notification-scope-dev | faible : 1 ligne image, aucune env/probe/resource/replica touchee |

git diff = 1 insertion / 1 suppression, aucun autre fichier dirty.

## 5. Dry-run

- kubectl apply --dry-run=client : deployment.apps/keybuzz-api configured (dry run).
- kubectl apply --dry-run=server : deployment.apps/keybuzz-api configured (server dry run).

## 6. Deploy commit + apply + rollout

- Commit+push AVANT apply : keybuzz-infra/main 1528252 -> 43085df (ahead 0, dirty 0).
- kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml -> deployment.apps/keybuzz-api configured.
- kubectl rollout status -> successfully rolled out.
- nouveau pod : keybuzz-api-59b88c85fb-mlvhc ; boot "Server listening at http://0.0.0.0:3001" ; aucune
  erreur/fatal/unhandled ; CHANNELS-SAFETY status=READY normal.

## 7. Runtime equality

| service | manifest | last-applied | pod image | imageID digest | verdict |
|---|---|---|---|---|---|
| keybuzz-api DEV | v3.5.260-amazon-inbound-address-sync-dev | v3.5.260-amazon-inbound-address-sync-dev | v3.5.260-amazon-inbound-address-sync-dev | sha256:b05da3d78801a432851d2cd14c58cc6a4141f314c8539c12cc3a126b821b7a7e | MATCH (ready=true, restarts=0) |

## 8. Markers runtime (pod courant)

| marker | resultat | verdict |
|---|---|---|
| dist/lib/normalizeInboundValidationStatus.js | 2 | present |
| ON CONFLICT promote-only validationStatus CASE (channelsRoutes.js) | 1 | present |
| marketplaceStatus (channelsRoutes.js) | 2 | present |
| worker gate validationStatus='VALIDATED' (outboundWorker.js) | 1 | intact |
| determineAmazonProvider | 3 | present |
| determineAiAssistNotificationSkip | 2 | present |

Le fix PH-20.52 est donc EN RUNTIME dans API DEV.

## 9. No side-effect (snapshots before/after)

| signal | before | after | delta | interpretation |
|---|---:|---:|---:|---|
| ai_suggestion_events (product DB DEV) | 2718 | 2718 | 0 | aucune generation IA spontanee |
| ai_actions_ledger (product DB DEV) | 550 | 550 | 0 | aucun debit/action spontane |
| outbound_deliveries (product DB DEV) | 310 | 310 | 0 | aucun outbound declenche par le deploy |
| inbound_addresses amazon (product DB DEV) | 23 | 23 | 0 | aucune mutation inbound (pas de backfill) |
| Job OUTBOUND_EMAIL_SEND (backend DB DEV) | 29 | 29 | 0 | aucun job outbound cree |
| OutboundEmail (backend DB DEV) | 28 | 28 | 0 | inchange |
| MarketplaceOutboundMessage (backend DB DEV) | 2 | 2 | 0 | inchange |

Aucun appel applicatif POST, aucun trigger sync/reconnect, aucun fake event. Le deploy est une simple
rotation d'image API DEV.

## 10. PROD intact + autres services

| service | namespace | runtime | verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.259-ai-assist-notification-scope-prod (1/1) | intact |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod (1/1) | intact |
| keybuzz-outbound-worker | keybuzz-api-dev | v3.5.165-escalation-flow-dev | intact |
| keybuzz-client | keybuzz-client-dev | v3.5.259-ai-assist-notification-scope-dev | intact |
| keybuzz-client | keybuzz-client-prod | v3.5.259-ai-assist-notification-scope-prod | intact |
| keybuzz-backend (dev/prod) | keybuzz-backend-* | v1.0.57-dev / v1.0.56-prod | intact |

Aucun manifest PROD modifie. Seul k8s/keybuzz-api-dev/deployment.yaml a change.

## 11. Rollback (documente, NON execute)

En cas d'incident :
1. git revert 43085df dans keybuzz-infra/main (restaure la ligne image v3.5.259-ai-assist-notification-scope-dev) ;
2. git push origin main ;
3. kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml ;
4. kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev ;
5. verifier runtime = v3.5.259-ai-assist-notification-scope-dev (imageID sha256:e31ff645deed...).
Jamais kubectl set image.

## 12. Prochaine action

GO READONLY VERIFY AMAZON INBOUND ADDRESS VALIDATION SYNC DEV PH-SAAS-T8.12AS.20.56 : verifier en
read-only que l'API DEV contient le fix et definir comment declencher proprement la sync/backfill
as0yom sans mutation non autorisee. PROD reste bloquee jusqu'a validation DEV complete.

## 13. Phrase cible

GO APPLY API AMAZON INBOUND ADDRESS VALIDATION SYNC DEV GITOPS READY PH-SAAS-T8.12AS.20.55

STOP.
