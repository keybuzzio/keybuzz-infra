# PH-SAAS-T8.12AS.20.60-APPLY-API-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-PROD-GITOPS-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.60 (APPLY GITOPS PROD API uniquement)
> Environnement : PROD ; commit+push manifest AVANT apply ; AUCUN build, docker push, trigger bridge, OAuth, mutation DB manuelle, kubectl set/patch/edit/env, push latest

## 1. Verdict

GO APPLY API AMAZON INBOUND ADDRESS VALIDATION SYNC PROD GITOPS READY PH-SAAS-T8.12AS.20.60

Manifest keybuzz-api PROD bumpe de v3.5.259-ai-assist-notification-scope-prod vers
v3.5.260-amazon-inbound-address-sync-prod via GitOps strict (commit+push avant apply). Rollout reussi.
Runtime equality prouvee : spec = last-applied = pod image = v3.5.260, pod imageID = digest GHCR
PH-20.59 sha256:778f7556c5aa.... Boot propre, markers patch presents en runtime. Aucune mutation DB
causee par l'apply (compteurs before == after, as0yom Product/API reste PENDING). DEV / Client PROD /
Backend PROD / outbound-worker PROD inchanges. latest intact.

## 2. Rappel UX

Pas de bouton de validation Amazon dans Channels (n'existe pas). Cette phase ne demande aucune action
utilisateur, aucun reconnect OAuth. Le sujet est la synchronisation de statut Backend -> Product/API.

## 3. Preflight (E0)

| repo/service | branche/image attendue | reel | dirty/restarts | verdict |
|---|---|---|---|---|
| keybuzz-infra | main, origin sync | main 3ea3587 (avant) | dirty 0 | OK |
| keybuzz-api | ph147.4/source-of-truth, origin contient 798db37c | origin HEAD 798db37ca108... | - | OK |
| API PROD | v3.5.259-ai-assist-notification-scope-prod | idem (1/1) | restarts=0 | OK |
| API DEV | v3.5.260-amazon-inbound-address-sync-dev | idem | - | OK |
| Client PROD | v3.5.259-ai-assist-notification-scope-prod | idem | - | OK |
| Backend PROD | v1.0.56-amazon-inbound-dedup-prod | idem | - | OK |
| outbound-worker PROD | keybuzz-outbound-worker v3.5.165-escalation-flow-prod | idem (1/1) | - | OK |

Bastion install-v3 / 46.62.171.61 (aucune trace 51.159.99.247). Manifest API PROD :
k8s/keybuzz-api-prod/deployment.yaml (doc unique Deployment/keybuzz-api, ligne image 106). Aucun manifest
ne reference le tag cible avant apply. outbound-worker est un Deployment separe (autre fichier), non
touche.

## 4. GHCR digests (cible PH-20.59)

| champ | attendu | remote | verdict |
|---|---|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod | present | OK |
| manifest digest | sha256:778f7556c5aa187be21b8a72a5246594c83e561c68abfaa053600fa7cbda43b8 | identique | MATCH |
| config digest | sha256:ac854f025cdfba6aed7e731fb4839180593a5f6614ac471566d8782cd8239888 | identique | MATCH |

## 5. Manifest diff (E2)

| fichier | changement | risque | verdict |
|---|---|---|---|
| k8s/keybuzz-api-prod/deployment.yaml | ligne 106 image v3.5.259 -> v3.5.260, commentaire PH-20.60 + rollback v3.5.259 | faible (1 ligne, indent 10 espaces preserve) | OK |

1 fichier, 1 ligne, 0 :latest, 0 manifest DEV/Client/Backend/outbound-worker modifie.

## 6. Dry-run (E3)

| action | attendu | resultat | verdict |
|---|---|---|---|
| kubectl apply --dry-run=client | configured | deployment.apps/keybuzz-api configured (dry run) | OK |
| kubectl apply --dry-run=server | configured | deployment.apps/keybuzz-api configured (server dry run) | OK |
| git diff --check | clean | clean | OK |

## 7. Deploy commit (E3)

| action | resultat | verdict |
|---|---|---|
| git add (fichier cible uniquement) | M k8s/keybuzz-api-prod/deployment.yaml | OK |
| git commit | 7f9e7ac1c0ce6e99a715ab30aab45b043c530182 | OK |
| git push origin main | 3ea3587..7f9e7ac main -> main | OK |
| origin/main == HEAD | 7f9e7ac... == 7f9e7ac... | OK |
| ahead/behind | 0 / 0 | OK |

## 8. Apply / rollout (E4)

| deployment | before | after | rollout | verdict |
|---|---|---|---|---|
| keybuzz-api (keybuzz-api-prod) | pod dcf5c978b-5pxch v3.5.259 | pod cf778495d-pfmls v3.5.260 | successfully rolled out | OK |

kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml -> deployment.apps/keybuzz-api configured.
rollout status timeout 180s : successfully rolled out. Aucun kubectl set/patch/edit.

## 9. Runtime equality (E5)

| signal | attendu | resultat | verdict |
|---|---|---|---|
| spec image | v3.5.260-amazon-inbound-address-sync-prod | idem | OK |
| last-applied image | v3.5.260-amazon-inbound-address-sync-prod | idem | OK |
| pod runtime image | v3.5.260-amazon-inbound-address-sync-prod | idem | OK |
| pod imageID digest | sha256:778f7556c5aa... | ghcr.io/keybuzzio/keybuzz-api@sha256:778f7556c5aa... | MATCH |
| ready | true | true | OK |
| restarts | 0 | 0 | OK |
| generation/observed | egales | gen 420 / observed 420, ready 1/1 | OK |

L'imageID runtime egale le manifest digest GHCR PH-20.59. L'image etant byte-identique a celle auditee
en PH-20.58/59 (config digest = Image ID), les markers dist (promote-only CASE=1, gates=1, helper) sont
deja prouves dans cette image.

## 10. Logs boot (E5)

Boot propre : "Server listening at http://0.0.0.0:3001". Logs [CHANNELS-SAFETY] : connecteurs amazon
status=READY (statut connexion OAuth, distinct du validationStatus DB) dont ecomlg-motxke32 status=READY.
Un seul warn niveau 40 pre-existant et benin : "must be owner of table ai_journal_events ... Could not
ensure table" (la table existe deja ; l'app continue ; present aussi avant cet apply ; non bloquant).
Aucune erreur Prisma/DB fatale au boot.

Markers patch presents dans le runtime dist du nouveau pod :

| marker | presence runtime | verdict |
|---|---|---|
| normalizeInboundValidationStatus | fichiers=2, refs=7 | OK |
| determineAmazonProvider | refs=10 | OK |
| determineAiAssistNotificationSkip (AI Assist skip) | refs=4 | OK |
| ON CONFLICT (sync promote-only inclus) | present (49 occurrences dist) | OK |
| VALIDATED gates (modules) | refs=12 | OK |

## 11. Before / after - no unintended processing (E6)

| signal | before | after | delta | interpretation |
|---|---|---|---|---|
| as0yom Product/API (ecomlg-motxke32/amazon/FR) | PENDING/PENDING | PENDING/PENDING | 0 | apply ne declenche PAS le bridge ; statut inchange (attendu) |
| inbound_addresses total | 13 | 13 | 0 | stable |
| inbound_addresses by status | VALIDATED 8 / PENDING 5 | VALIDATED 8 / PENDING 5 | 0 | stable |
| ai_suggestion_events | 3582 | 3582 | 0 | aucun event cree par l'apply |
| ai_actions_ledger | 270 | 270 | 0 | aucune action/generation creee par l'apply |
| outbound_deliveries | 308 | 308 | 0 | aucun outbound cree par l'apply |
| Backend DB as0yom | VALIDATED/VALIDATED | inchange (aucun chemin de mutation via restart API) | 0 | split confirme, source du futur sync |
| pods API PROD | dcf5c978b-5pxch | cf778495d-pfmls (seul Running) | rollout | OK |

No fake metrics / no fake events : aucun event GA4/CAPI/marketing, aucun ai_suggestion_events, aucun
ai_actions_ledger, aucun message ni outbound_delivery cree par cette phase.

## 12. AI feature parity / anti-regression (E5/E15)

| feature | source de verite | preuve runtime | verdict |
|---|---|---|---|
| advisory lock Amazon inbound (PH-20.26/34-BIS) | backend | hors scope apply API, non touche | OK |
| AI Assist notification skip message-level (PH-20.42-TER/49) | API | determineAiAssistNotificationSkip present runtime (4) | OK |
| generation AI Assist + KBActions (PH-20.46-QUATER) | API | non touches par l'apply | OK |
| worker outbound gate VALIDATED (PH-20.50/51) | outboundWorker | gate VALIDATED present, non contourne | OK |
| sync validation status (PH-20.52) | channelsRoutes + helper | helper + ON CONFLICT promote-only presents runtime | OK |
| determineAmazonProvider | provider unifie SMTP | present runtime (10) | OK |
| bouton validation Channels | n/a | aucun invente | OK |
| Client UI / Autopilot / escalade / playbooks / billing / tracking | hors scope | non touches | OK |

## 13. PROD modifie : API uniquement

| service | etat | verdict |
|---|---|---|
| API PROD | v3.5.259 -> v3.5.260 (cible de la phase) | MODIFIE (attendu) |
| API DEV | v3.5.260-amazon-inbound-address-sync-dev | inchange |
| Client PROD | v3.5.259-ai-assist-notification-scope-prod | inchange |
| Backend PROD | v1.0.56-amazon-inbound-dedup-prod | inchange |
| outbound-worker PROD | v3.5.165-escalation-flow-prod | inchange |
| latest API | sha256sum manifest 71d7e988869441ff... | inchange |

## 14. Limites

- PH-20.60 deploie le patch en PROD ; ne re-declenche PAS le bridge ; ne corrige PAS encore la ligne
  Product/API as0yom tant qu'une phase dediee n'a pas declenche le flux produit/session.
- as0yom Product/API reste PENDING ; ne pas conclure que l'outbound ecomlg-motxke32 est repare.
- Aucune action utilisateur requise dans PH-20.60.

## 15. Rollback GitOps

- git revert 7f9e7ac1c0ce6e99a715ab30aab45b043c530182 dans keybuzz-infra
- git push origin main
- kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
- kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
- verification retour v3.5.259-ai-assist-notification-scope-prod
- jamais kubectl set image. Ne pas executer sauf GO explicite ou incident critique.

## 16. Prochain GO recommande

GO TRIGGER AMAZON INBOUND ADDRESS VALIDATION SYNC PROD PH-SAAS-T8.12AS.20.61 : re-declenchement du
bridge/flux produit as0yom avec session valide, sans SQL manuel ni exposition de secret, puis before/after
DB pour prouver la promotion Product/API as0yom de PENDING vers VALIDATED. Mutation/verification PROD
separee, GO explicite requis.

## 17. Fichier retour CE

C:\DEV\KeyBuzz\tmp\PH-20.60_CE_RETURN.md

## 18. Phrase cible

GO APPLY API AMAZON INBOUND ADDRESS VALIDATION SYNC PROD GITOPS READY PH-SAAS-T8.12AS.20.60

STOP.
