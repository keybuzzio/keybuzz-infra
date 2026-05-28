# PH-SAAS-T8.12AS.20.48-PUSH-IMAGE-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.48 (PUSH IMAGE ONLY PROD du correctif PH-20.42-TER)
> Environnement : PROD preparation ; PUSH IMAGE ONLY (aucun build, aucun deploy, aucun kubectl)

## 1. Verdict

GO PUSH IMAGE AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD DONE PH-SAAS-T8.12AS.20.48

Les deux images PROD construites en PH-20.47 sont poussees sur GHCR. Pull-back frais confirme que
le config digest remote == Image ID local pour chacune, RepoDigest = manifest digest documente,
OCI labels conformes. Bundle Client PROD pull-back re-audite (api.keybuzz.io present, api-dev
absent, Clarity present). latest des deux repos INCHANGE. Runtime DEV/PROD inchanges, restarts=0,
manifests GitOps non modifies.

## 2. Synthese claire pour Ludovic

- Les deux images PROD sont POUSSEES sur GHCR (tags v3.5.259-ai-assist-notification-scope-prod).
- Digests prouves par pull-back : ce qui est sur le registry == ce qui a ete construit en PH-20.47.
- latest intact (api + client), runtime PROD/DEV intacts (rien deploye, restarts=0).
- Prochaine action : PH-20.49 APPLY GitOps PROD (bump manifests api+client PROD, commit+push avant
  apply, kubectl apply -f, rollout, verify runtime=manifest=digest), avec GO explicite de Ludovic.

## 3. API push / pull-back

| signal | local | remote / pull-back | verdict |
|---|---|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.259-ai-assist-notification-scope-prod | idem | OK |
| Image ID (config digest) | sha256:c0de6f0d9c8b709157a2a480baa5c95b4fa0938fb63ad25ac032be17529a89b0 | sha256:c0de6f0d9c8b... (manifest config + pull-back inspect Id) | MATCH |
| manifest digest | - | sha256:7203e247b13a4754110eb016d67c3e484813e14c00b748b5880f6d6fcfb7e633 | documente |
| RepoDigest | - | ghcr.io/keybuzzio/keybuzz-api@sha256:7203e247b13a... | OK |
| OCI revision | 15f0e5e570c26286bcf394d55718684a5574bec5 | idem | OK |
| OCI version | v3.5.259-ai-assist-notification-scope-prod | idem | OK |

Push API : layers 4 shared (already exists) + 3 pushed. Pull-back = rmi tag local puis docker pull
frais ; Image ID identique au local. Aucun retag, aucun latest.

## 4. Client push / pull-back

| signal | local | remote / pull-back | verdict |
|---|---|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | idem | OK |
| Image ID (config digest) | sha256:9f46a7a88f83e15333b4e0106ac740b0571a8e4f38743b6c09d964e4566f5b69 | sha256:9f46a7a88f83... (manifest config + pull-back inspect Id) | MATCH |
| manifest digest | - | sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | documente |
| RepoDigest | - | ghcr.io/keybuzzio/keybuzz-client@sha256:e63494dbe833... | OK |
| OCI revision | ad4e862a2e635de251757f382a6d00b8fd063748 | idem | OK |
| OCI version | v3.5.259-ai-assist-notification-scope-prod | idem | OK |
| bundle api.keybuzz.io | 2 occ | 2 occ (pull-back) | OK |
| bundle api-dev.keybuzz.io | 0 | 0 (pull-back) | OK |
| Clarity wuk12h9i33 | present | present (pull-back) | OK |

Push Client : layers 4 shared + 3 pushed. Bundle PROD re-audite sur l'image pull-back :
https://api.keybuzz.io inline, https://api-dev.keybuzz.io absent -> incident KEY-302 evite.
Aucun retag, aucun latest.

## 5. AI parity (audit image avant push)

- API determineAiAssistNotificationSkip present (2 fichiers dist).
- API BUYER_AMAZON_IDS_PRESENT (garde amazonIds.messageId -> skip false) present.
- API NO_REPLY_PLATFORM_NOTIFICATION present (4). debitKBActions present (hors skip).
- Client bundle PROD API base = api.keybuzz.io, pas api-dev.
- Client Clarity wuk12h9i33 present ; marker skip neutre (Notification systeme) present.

## 6. Latest / no side-effect

| signal | attendu | resultat |
|---|---|---|
| latest keybuzz-api | inchange | sha256sum manifest 71d7e988869441ff avant == apres |
| latest keybuzz-client | inchange | sha256sum manifest 151a4fde8c1afc29 avant == apres |
| runtime api-dev | inchange | v3.5.259-ai-assist-notification-scope-dev, restarts=0 |
| runtime client-dev | inchange | v3.5.259-ai-assist-notification-scope-dev, restarts=0 |
| runtime backend-dev | inchange | v1.0.57-amazon-notification-classification-dev, restarts=0 |
| runtime api-prod | inchange | v3.5.257-autopilot-no-reply-kbactions-prod, restarts=0 |
| runtime client-prod | inchange | v3.5.217-clarity-client-restore-prod, restarts=0 |
| runtime backend-prod | inchange | v1.0.56-amazon-inbound-dedup-prod, restarts=0 |
| manifests GitOps | sans tags PROD cibles | MANIFEST_NONE |
| build / kubectl / DB mutation | aucun | aucun |
| no fake metrics/events | aucun | aucun |

Seules deux operations effectuees : docker push des deux tags cibles + pull-back de verification.
Aucun deploiement, aucune mutation runtime/DB.

## 7. Rapport + commit

- Rapport infra : docs/PH-SAAS-T8.12AS.20.48-PUSH-IMAGE-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-PROD-01.md (ASCII strict, no BOM).
- Commit/push docs-only keybuzz-infra/main documente dans le retour CE (E9).

## 8. Prochaine etape

GO APPLY AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD GITOPS PH-SAAS-T8.12AS.20.49 :
- keybuzz-api PROD v3.5.257-autopilot-no-reply-kbactions-prod -> v3.5.259-ai-assist-notification-scope-prod
- keybuzz-client PROD v3.5.217-clarity-client-restore-prod -> v3.5.259-ai-assist-notification-scope-prod
- commit+push manifests AVANT apply ; kubectl apply -f uniquement ; rollout ;
  runtime=manifest=last-applied=digest ; verify Client bundle/runtime ; no unintended processing.
- GO explicite de Ludovic requis (mutation runtime PROD). Hardening LiteLLM = phase separee.

## 9. Phrase cible

GO PUSH IMAGE AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD DONE PH-SAAS-T8.12AS.20.48

STOP.
