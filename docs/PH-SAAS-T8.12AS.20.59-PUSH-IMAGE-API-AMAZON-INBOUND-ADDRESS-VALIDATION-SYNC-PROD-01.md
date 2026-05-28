# PH-SAAS-T8.12AS.20.59-PUSH-IMAGE-API-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-PROD-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.59 (PUSH IMAGE ONLY - image API PROD PH-20.58 sur GHCR)
> Environnement : PROD preparation / PUSH IMAGE ONLY ; AUCUN build, deploy, kubectl, mutation DB, trigger, OAuth, push latest

## 1. Verdict

GO PUSH IMAGE API AMAZON INBOUND ADDRESS VALIDATION SYNC PROD DONE PH-SAAS-T8.12AS.20.59

Image API PROD PH-20.58 poussee sur GHCR (tag cible uniquement, non-force, jamais latest). Digest
prouve par pull-back : config digest remote == Image ID local PH-20.58, pull frais Image ID identique,
RepoDigest = manifest digest pousse, labels OCI conformes. latest intact, runtime DEV/PROD inchange,
manifests GitOps inchanges, PROD strictement intacte. Reste : revue + GO APPLY GITOPS PROD (PH-20.60).

## 2. Rappel UX

Pas de bouton de validation Amazon dans Channels (n'existe pas). Le sujet est la synchronisation de
statut Backend -> Product/API DB. Cette phase ne demande aucune action utilisateur, aucun reconnect
OAuth.

## 3. Preflight (E0)

| repo/service | branche/image attendue | reel | dirty/restarts | verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth, origin contient 798db37c | origin HEAD = 798db37ca108... | - | OK |
| keybuzz-infra | main | main c44d225 | dirty 0 | OK |
| API DEV | v3.5.260-amazon-inbound-address-sync-dev | idem (1/1) | - | OK |
| API PROD | v3.5.259-ai-assist-notification-scope-prod | idem (1/1) | restarts=0 | intact |
| outbound-worker PROD | v3.5.165-escalation-flow-prod | idem (1/1) | - | intact |

Bastion install-v3 / 46.62.171.61 (aucune trace 51.159.99.247). GHCR tag PROD cible : ABSENT avant
push. Aucun manifest k8s ne reference le tag. latest API snapshot avant push : sha256sum manifest
71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549.

## 4. Image locale avant push (E1)

| champ | attendu | resultat | verdict |
|---|---|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod | idem | OK |
| Image ID | sha256:ac854f025cdfba6aed7e731fb4839180593a5f6614ac471566d8782cd8239888 | identique | MATCH |
| OCI revision | 798db37ca108c792a79749b939d9f7420120b7a5 | idem | OK |
| OCI version | v3.5.260-amazon-inbound-address-sync-prod | idem | OK |
| OCI created | 2026-05-28T10:58:20Z | idem | OK |

Markers dist re-audit : helper=2, route utilise helper=2, ON CONFLICT promote-only CASE=1, worker gate
validationStatus='VALIDATED'=1, messages gate=1, determineAmazonProvider=3, determineAiAssistNotificationSkip=2,
message_source=SYSTEM=0, hardcode patch files=0. Image conforme PH-20.58.

## 5. Docker push (E2)

docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod
- 3 layers Pushed (52b687bdd680, e004618f94a5, fdc4e6a5590a), 6 Layer already exists (couches
  partagees avec l'image DEV v3.5.260 deja sur GHCR).
- manifest digest : sha256:778f7556c5aa187be21b8a72a5246594c83e561c68abfaa053600fa7cbda43b8 (size 2416).
- latest NON pousse ; aucun autre tag ; aucun retag.

## 6. Pull-back digest match (E3)

| signal | local attendu | remote/pull-back | verdict |
|---|---|---|---|
| config digest | sha256:ac854f025cdf... (Image ID PH-20.58) | docker manifest inspect config.digest = sha256:ac854f025cdf... | MATCH |
| Image ID pull-back | sha256:ac854f025cdf... | apres rmi + docker pull frais = sha256:ac854f025cdf... | MATCH |
| manifest digest | - | RepoDigest = ghcr.io/keybuzzio/keybuzz-api@sha256:778f7556c5aa... | OK |
| OCI labels pull-back | revision 798db37ca108..., version v3.5.260-amazon-inbound-address-sync-prod | identiques | OK |

L'image PROD sur GHCR est exactement l'image construite en PH-20.58 (config digest = Image ID local) ;
le pull frais redonne le meme Image ID -> aucune alteration.

## 7. Latest / no side-effect (E4)

| signal | before | after | delta | verdict |
|---|---|---|---|---|
| latest API (sha256sum manifest) | 71d7e988869441ff... | 71d7e988869441ff... | 0 | OK (intact) |
| GHCR tag cible PROD | absent | present | +1 (attendu) | OK |
| autre tag cree | - | aucun | 0 | OK |
| runtime API PROD | v3.5.259, 1/1, restarts=0 | idem | 0 | OK |
| runtime API DEV | v3.5.260-dev | idem | 0 | OK |
| Client PROD | v3.5.259-...-prod | idem | 0 | OK |
| Backend PROD | v1.0.56-amazon-inbound-dedup-prod | idem | 0 | OK |
| outbound-worker PROD | v3.5.165-escalation-flow-prod | idem | 0 | OK |
| manifests GitOps | sans tag cible | aucun ref | 0 | OK |
| mutation DB / trigger / outbound / OAuth | aucun | aucun | 0 | OK |
| fake metric/event/KBActions | aucun | aucun | 0 | OK |

## 8. AI feature parity / anti-regression

| feature | source de verite | preuve image | verdict |
|---|---|---|---|
| AI Assist notification skip message-level (PH-20.42-TER/49) | noReplyClassifier | determineAiAssistNotificationSkip present dist (2) | OK |
| worker outbound gate VALIDATED (PH-20.50/51) | outboundWorker | gate present dist (1), non contourne | OK |
| sync validation status (PH-20.52) | channelsRoutes + helper | helper + ON CONFLICT promote-only presents | OK |
| determineAmazonProvider | provider unifie SMTP | present dist (3) | OK |
| advisory lock Amazon inbound (PH-20.26/34-BIS) | backend | hors scope push API, non touche | OK |
| Client UI / Autopilot / KBActions / billing / tracking | hors scope | non touches | OK |
| bouton validation Channels | n/a | aucun invente | OK |

## 9. Limites

- PUSH IMAGE ONLY : aucune preuve runtime PROD (image poussee mais non deployee). Le fix PROD ne prend
  effet qu'apres apply GitOps PROD (PH-20.60, GO explicite) + trigger bridge PROD as0yom (phase dediee,
  flux produit/session, GO explicite).
- as0yom PROD reste non corrige ; ne pas conclure que l'outbound ecomlg-motxke32 est repare.

## 10. Rollback futur

Aucun rollback runtime necessaire dans PH-20.59 (aucun deploy). Si deploy PROD futur : rollback GitOps
par revert du commit manifest futur vers v3.5.259-ai-assist-notification-scope-prod ; jamais
kubectl set image.

## 11. Prochain GO recommande

GO APPLY API AMAZON INBOUND ADDRESS VALIDATION SYNC PROD GITOPS PH-SAAS-T8.12AS.20.60 : bump manifest
keybuzz-api PROD vers v3.5.260-amazon-inbound-address-sync-prod (commit+push AVANT apply), kubectl
apply -f, rollout, runtime=manifest=last-applied=digest, before/after read-only. Mutation runtime PROD
-> exige un GO explicite separe. Puis phase dediee re-declenchement bridge PROD as0yom (flux produit,
0 SQL manuel) + before/after DB.

## 12. Fichier retour CE

C:\DEV\KeyBuzz\tmp\PH-20.59_CE_RETURN.md

## 13. Phrase cible

GO PUSH IMAGE API AMAZON INBOUND ADDRESS VALIDATION SYNC PROD DONE PH-SAAS-T8.12AS.20.59

STOP.
