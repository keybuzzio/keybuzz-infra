# PH-SAAS-T8.12AS.19.1-REGISTER-CRO-PUSH-IMAGE-DEV-01

> Date : 2026-05-20
> Linear : KEY-329 (primary), KEY-331, KEY-332, KEY-325, KEY-330
> Phase : PH-SAAS-T8.12AS.19.1-REGISTER-CRO-PUSH-IMAGE-DEV-01
> Environnement : DEV image push only / aucun build / aucun deploy

## VERDICT

GO PUSH IMAGE REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.1

- API DEV image poussee sur GHCR : ghcr.io/keybuzzio/keybuzz-api:v3.5.251-register-cro-dev
- Client DEV image poussee sur GHCR : ghcr.io/keybuzzio/keybuzz-client:v3.5.199-register-cro-dev
- Manifest digest GHCR API : sha256:a05e9b83d3d7a48fd261b37eaa4533ea4d55c96eadfd1fca31fb0e6f28b8706a (size 2416)
- Manifest digest GHCR Client : sha256:969558287b908ab4ecb9060b0fdb42fff344ac5a372105396d0efaa5a22e199c (size 2631)
- Config digests = image IDs locaux 85d1ef9f2e84 + f4dae38ff884 (match prefix 12c)
- Runtime DEV/PROD inchanges (6/6 deployments preserve)
- NO BUILD, NO DEPLOY, NO kubectl

Prochaine phrase GO attendue : GO APPLY REGISTER CRO DEV PH-SAAS-T8.12AS.19.1

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| API image locale | 85d1ef9f2e84 | OK |
| Client image locale | f4dae38ff884 | OK |
| API revision label | 39e332eaa49a53433f403742837e56a75dda49cc | OK |
| Client revision label | 1b29903db0a6544f88c9050618d7fc75237f320c | OK |
| API version label | v3.5.251-register-cro-dev | OK |
| Client version label | v3.5.199-register-cro-dev | OK |
| GHCR collision API v3.5.251-register-cro-dev | manifest unknown | tag FREE |
| GHCR collision Client v3.5.199-register-cro-dev | manifest unknown | tag FREE |

## PUSH API DEV

| Param | Valeur |
|---|---|
| image locale | 85d1ef9f2e84 (343 MB) |
| tag pousse | v3.5.251-register-cro-dev |
| push exit | 0 |
| layers nouveaux pousses | 3 (3af6d6fcc360, b9317ead8996, 27e6674d685b) |
| layers reutilises | 7 (couches base node:lts, deps node_modules) |
| manifest digest GHCR | sha256:a05e9b83d3d7a48fd261b37eaa4533ea4d55c96eadfd1fca31fb0e6f28b8706a |
| manifest size | 2416 |
| config digest | sha256:85d1ef9f2e84a26f0bf7d809009b0b3d31e272360acc3eb75ec50c5f2bfab08a |
| layers count | 10 |
| layers total size compresse | 112040711 bytes (106.85 MB) |
| repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-api@sha256:a05e9b83d3d7a48fd... |

OCI labels KEY-308 (5/5 preserves) :

| Label | Valeur |
|---|---|
| revision | 39e332eaa49a53433f403742837e56a75dda49cc |
| created | 2026-05-20T06:58:49Z |
| version | v3.5.251-register-cro-dev |
| source | https://github.com/keybuzzio/keybuzz-api |
| title | keybuzz-api |

## PUSH CLIENT DEV

| Param | Valeur |
|---|---|
| image locale | f4dae38ff884 (280 MB) |
| tag pousse | v3.5.199-register-cro-dev |
| push exit | 0 |
| layers nouveaux pousses | 5 (9934c044e16a, ab26c7a1eeaa, b4dcf764a1b3, 571cfc27c0eb, cfcdd194d986) |
| layers reutilises | 6 |
| manifest digest GHCR | sha256:969558287b908ab4ecb9060b0fdb42fff344ac5a372105396d0efaa5a22e199c |
| manifest size | 2631 |
| config digest | sha256:f4dae38ff884a02df564c802dd2a37c46ab5e67a87f1562a314b5cb09d9d9144 |
| layers count | 11 |
| layers total size compresse | 105259133 bytes (100.38 MB) |
| repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-client@sha256:969558287b908ab4... |

OCI labels KEY-308 (5/5 preserves) :

| Label | Valeur |
|---|---|
| revision | 1b29903db0a6544f88c9050618d7fc75237f320c |
| created | 2026-05-20T07:00:12Z |
| version | v3.5.199-register-cro-dev |
| source | https://github.com/keybuzzio/keybuzz-client |
| title | keybuzz-client |

## DIGEST VERIFY (config digest = image ID local)

| Image | Manifest digest GHCR | Config digest | Image ID local | Match prefix 12c | Verdict |
|---|---|---|---|---|---|
| API DEV | sha256:a05e9b83d3d7a48f... | sha256:85d1ef9f2e84a26f... | 85d1ef9f2e84 | sha256:85d1ef9f2e84 | OK |
| Client DEV | sha256:969558287b908ab4... | sha256:f4dae38ff884a02d... | f4dae38ff884 | sha256:f4dae38ff884 | OK |

## RUNTIME PRESERVE (read-only)

| Cluster | Image runtime | Verdict |
|---|---|---|
| keybuzz-client-dev | v3.5.198-debug-env-disabled-dev | INCHANGE |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | INCHANGE |
| keybuzz-api-dev | v3.5.250-ad-spend-sync-all-dev | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |

| Artefact | Valeur |
|---|---|
| keybuzz-infra HEAD | 6bf9bbb = origin/main |
| keybuzz-infra working tree | rapport build-dev-01 untracked (non commit) |
| kubectl apply | NON execute |
| kubectl set / patch / edit | NON execute |
| Modification manifest infra | aucune |
| Commit infra additionnel | aucun |
| docker build | NON execute |
| git push application | NON execute (sources deja poussees phase precedente) |

## LINEAR BROUILLONS (NON postes, token Linear hors-chat)

> KEY-329 (primary) : Images DEV poussees sur GHCR. API tag v3.5.251-register-cro-dev manifest digest sha256:a05e9b83d3d7a48f... ; Client tag v3.5.199-register-cro-dev manifest digest sha256:969558287b908ab4... . Config digests matchent image IDs locaux 85d1ef9f2e84 + f4dae38ff884. Aucun deploy. Runtime DEV/PROD inchanges. STOP avant apply DEV.

> KEY-331 : Client DEV image GHCR pousse. plan_selected preserve cote source 1b29903 + verifie bundle phase precedente. Events ads browser-side preexistants documentes.

> KEY-332 : API DEV image GHCR pousse. tenant_created emit post-COMMIT preserve cote source 39e332ea + verifie dist phase precedente.

> KEY-325 : Client image GHCR pousse sans activation Clarity. data-clarity-mask 13 attributs source/26 bundle. NEXT_PUBLIC_CLARITY=0, clarity.ms=0, wrff07upjx=0 dans bundle.

> KEY-330 : Pas de nouvel event fake ajoute par la phase. Events ads browser-side existants src/lib/tracking.ts preserves. Decision retrait/migration server-side a prendre.

## CONFIRMATIONS NO BUILD / NO DEPLOY

- AUCUN docker build
- AUCUN rebuild
- AUCUN nouveau tag
- AUCUN docker push autre que les 2 tags scope
- AUCUN deploy DEV/PROD
- AUCUN kubectl apply / set / patch / edit
- AUCUN changement manifest infra
- AUCUN git commit/push application
- AUCUN secret expose dans logs / labels
- AUCUN changement Admin / Backend / Studio / Website / Stripe / Vault / ESO
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUNE activation Clarity client.keybuzz.io
- Bastion : install-v3 (46.62.171.61) uniquement

## ROLLBACK

Push GHCR realise (irreversible cote registry, sauf garbage collection registry future). Pour rollback applicatif :
- Aucun deploy effectue, donc rien a defaire cote runtime.
- Pour invalider les tags pousses : actions GitHub Packages depuis l UI ou via API (delete package version). Non recommande car le runtime n a pas encore consomme l image.
- Pour ignorer simplement les images : ne pas bumper le manifest DEV.

INTERDIT : git reset --hard, git clean.

## VERDICT FINAL

GO PUSH IMAGE REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.1

| Composant | Tag | Manifest digest GHCR | Config digest |
|---|---|---|---|
| API DEV | v3.5.251-register-cro-dev | sha256:a05e9b83d3d7a48fd261b37eaa4533ea4d55c96eadfd1fca31fb0e6f28b8706a | sha256:85d1ef9f2e84a26f0bf7d809009b0b3d31e272360acc3eb75ec50c5f2bfab08a |
| Client DEV | v3.5.199-register-cro-dev | sha256:969558287b908ab4ecb9060b0fdb42fff344ac5a372105396d0efaa5a22e199c | sha256:f4dae38ff884a02df564c802dd2a37c46ab5e67a87f1562a314b5cb09d9d9144 |

- Runtime DEV/PROD inchanges (6/6 deployments preserve)
- NO BUILD
- NO DEPLOY
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.1-REGISTER-CRO-PUSH-IMAGE-DEV-01.md (untracked sur main)

Prochaine phrase GO attendue :

GO APPLY REGISTER CRO DEV PH-SAAS-T8.12AS.19.1

STOP.
