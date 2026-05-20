# PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-PUSH-IMAGE-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-PUSH-IMAGE-CLIENT-DEV
> Environnement : DEV image push only / aucun build / aucun deploy

## VERDICT

GO PUSH IMAGE CLIENT REGISTER QA FIX DEV READY PH-SAAS-T8.12AS.19.4

- Image Client DEV poussee sur GHCR : `ghcr.io/keybuzzio/keybuzz-client:v3.5.202-register-qa-fix-dev`
- Manifest digest GHCR : `sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40` (size 2631)
- Config digest : `sha256:1a2c23edc0bc5044e1a4cf04da84953d1c2eeb1d889946b80de231fb0f06e87f` MATCH image ID local
- Repo digest pulled-back : `ghcr.io/keybuzzio/keybuzz-client@sha256:b2bc34a2f6c6...`
- Layers : 11 (5 nouveaux pousses, 6 reutilises, total 100.39 MB compresse)
- Push exit 0
- OCI labels KEY-308 : 5/5 preserves (revision d363c38)
- Runtime DEV/PROD inchange (6/6)
- AUCUN build, AUCUN deploy, AUCUN kubectl, AUCUN manifest change

Prochaine phrase GO attendue : GO APPLY CLIENT REGISTER QA FIX DEV PH-SAAS-T8.12AS.19.4

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Image locale ID | sha256:1a2c23edc0bc5044e1a4cf04da84953d1c2eeb1d889946b80de231fb0f06e87f | OK |
| OCI revision label | d363c387af20c26a400613e3a777d542d368eed4 | OK |
| Image locale Size | 279997543 bytes (280 MB) | OK |
| Image locale Created | 2026-05-20T13:57:29Z | OK |
| GHCR collision pre-push (try 1) | manifest unknown | tag FREE |
| GHCR collision pre-push (try 2) | manifest unknown | confirmation tag FREE |

## PUSH CLIENT DEV

| Param | Valeur |
|---|---|
| image locale | sha256:1a2c23edc0bc... (280 MB) |
| tag pousse | v3.5.202-register-qa-fix-dev |
| push exit | 0 |
| layers nouveaux pousses | 5 (7cc92260bc64, ed6a78bfc380, 4af674cfcec5, 0d3d3ac164ac, ed8cfd311a23) |
| layers reutilises | 6 (4cbec844eef7, afa543f85b46, e10358715ead, 4983b93ee796, 29df493baa13, ff88504cd133) |
| manifest digest GHCR | sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40 |
| manifest size | 2631 bytes |
| config digest | sha256:1a2c23edc0bc5044e1a4cf04da84953d1c2eeb1d889946b80de231fb0f06e87f |
| config size | 12951 bytes |
| layers count | 11 |
| layers total compresse | 105263505 bytes (100.39 MB) |
| repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-client@sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40 |

## DIGEST VERIFY (config digest = image ID local)

| Image | Manifest digest GHCR | Config digest | Image ID local | Match | Verdict |
|---|---|---|---|---|---|
| Client DEV v3.5.202-register-qa-fix-dev | sha256:b2bc34a2f6c6... | sha256:1a2c23edc0bc... | sha256:1a2c23edc0bc... | OUI prefix 12c match | OK |

## OCI LABELS KEY-308 (5/5 preserves)

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | d363c387af20c26a400613e3a777d542d368eed4 |
| org.opencontainers.image.created | 2026-05-20T13:54:47Z |
| org.opencontainers.image.version | v3.5.202-register-qa-fix-dev |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client |
| org.opencontainers.image.title | keybuzz-client |

## BUNDLE PROOF (verifications faites en phase BUILD-CLIENT-DEV-01)

L image poussee correspond bit-pour-bit a celle verifiee en phase PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-BUILD-CLIENT-DEV-01 (config digest sha256:1a2c23edc0bc match Image ID local) :

| Pattern bundle pre-push | Occurrences |
|---|---|
| api-dev.keybuzz.io (isolation DEV) | 87 |
| api.keybuzz.io (sans -dev) (KEY-263) | 0 |
| register-lead-shell | 2 |
| register-reassurance-panel | 2 |
| register-confirm-plan | 2 |
| Confirmer ce plan et activer | 2 |
| Activez votre cockpit SAV | 2 |
| data-selected (PH-19.4) | 2 |
| aria-pressed (PH-19.4) | 2 |
| invalid_marketing_owner_tenant_id (PH-19.4 fallback) | 2 |
| marketing_owner_tenant_id (toutes) | 9 |
| Le plus populaire (badge sur Autopilot) | 7 |
| Autopilot (id + nom) | 119 |
| data-clarity-mask (PII inputs) | 26 |
| clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx | 0 / 0 / 0 |
| AW-XXXXXXXXXX direct | 0 |
| plan_selected | 4 (1 emit source unique x SSR + chunks refs) |

## RUNTIME PRESERVE READ-ONLY

| Service | Image runtime | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-dev | v3.5.201-register-lead-first-dev | 1/1 | INCHANGE - sera bump vers v3.5.202 en phase APPLY |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | 1/1 | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE (candidate API valide) |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |

| Artefact | Valeur |
|---|---|
| docker build | NON execute |
| nouveau tag autre que scope | aucun |
| kubectl apply / set / patch / edit | NON execute |
| Modification manifest infra | aucune |
| Commit applicatif | aucun |
| Commit infra additionnel | aucun (rapport docs PH untracked apres mv) |

## CONFIRMATIONS NO BUILD / NO DEPLOY

- AUCUN docker build / rebuild
- AUCUN nouveau tag autre que v3.5.202-register-qa-fix-dev
- AUCUN deploy DEV / PROD
- AUCUN kubectl apply / set / patch / edit
- AUCUN changement manifest infra
- AUCUN git commit/push source application
- AUCUN secret expose dans logs / labels
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN changement Admin / Backend / Studio / Website / Stripe / Vault / ESO
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- AUCUN Linear ticket close
- Bastion install-v3 (46.62.171.61) uniquement

## LINEAR BROUILLONS (NON postes, token hors-chat)

> **KEY-335 (primary)** : Image Client DEV v3.5.202-register-qa-fix-dev poussee sur GHCR. Manifest digest sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40 (size 2631). Config digest sha256:1a2c23edc0bc... match image ID local. OCI labels KEY-308 5/5 preserves (revision d363c38, created 2026-05-20T13:54:47Z). 11 layers (5 nouveaux + 6 reutilises), 100.39 MB compresse. Push exit 0. STOP avant apply DEV. Prochaine etape : bump manifest k8s/keybuzz-client-dev/deployment.yaml + commit/push keybuzz-infra + kubectl apply + rollout + smoke.

> **KEY-334** : Image post-QA-fix lead-first publiee GHCR. Bundle PH-19.4 deja verifie phase BUILD-CLIENT-DEV-01 (data-selected 2, aria-pressed 2, invalid_marketing_owner_tenant_id 2, register-lead-shell + register-reassurance-panel + register-confirm-plan preserves). API DEV v3.5.251 candidate preserve.

> **KEY-329** : Image CRO post-QA fix publiee GHCR. Bundle ne contient aucun fake review / fake logo / fake chiffre.

> **KEY-331** : plan_selected reste unique cote source (1 emit canonique). Bundle = 4 refs = SSR + chunks (pas 4 emits).

> **KEY-330** : No fake events ajoutes dans l image poussee. AW- direct = 0.

> **KEY-325** : Clarity client toujours non activee dans l image poussee (clarity.ms 0 / NEXT_PUBLIC_CLARITY 0 / wrff07upjx 0). data-clarity-mask 26 PII preserves.

## ROLLBACK PREP

Si la phase APPLY ulterieure echoue ou est annulee :
- Tag rollback Client DEV : `v3.5.201-register-lead-first-dev`
- Digest rollback : `sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de`

Push GHCR realise (irreversible cote registry sauf garbage collection). Pour ne pas utiliser cette image : ne pas bumper le manifest DEV.

INTERDIT : git reset --hard, git clean.

## GAPS

1. Tag `v3.5.202-register-qa-fix-dev` desormais public sur GHCR. Image existe en local + remote.
2. Email logo template magic-link `client.keybuzz.io/branding/keybuzz-icon.png` toujours present (preexistant PH-19.1+, hors scope KEY-263 qui concerne api.keybuzz.io dans bundle).
3. Worktree `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.4/keybuzz-client` reste sur disque pour eventuelle phase PROD ulterieure ; cleanup possible post-PROD.
4. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline `v3.5.201-register-lead-first-dev`).
5. Clarity activation client.keybuzz.io reste decision post-QA lead-first + QA-fix.

## VERDICT FINAL

GO PUSH IMAGE CLIENT REGISTER QA FIX DEV READY PH-SAAS-T8.12AS.19.4

| Composant | Tag | Manifest digest GHCR | Config digest | Repo digest |
|---|---|---|---|---|
| Client DEV | v3.5.202-register-qa-fix-dev | sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40 | sha256:1a2c23edc0bc5044e1a4cf04da84953d1c2eeb1d889946b80de231fb0f06e87f | ghcr.io/keybuzzio/keybuzz-client@sha256:b2bc34a2f6c6... |

- Push exit 0
- Image ID local match config digest GHCR (sha256:1a2c23edc0bc)
- OCI labels 5/5 preserves
- Runtime DEV/PROD inchanges (6/6)
- NO BUILD
- NO DEPLOY
- NO kubectl
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.4-REGISTER-QA-FIX-PUSH-IMAGE-CLIENT-DEV-01.md (untracked main)

Prochaine phrase GO attendue :

GO APPLY CLIENT REGISTER QA FIX DEV PH-SAAS-T8.12AS.19.4

STOP.
