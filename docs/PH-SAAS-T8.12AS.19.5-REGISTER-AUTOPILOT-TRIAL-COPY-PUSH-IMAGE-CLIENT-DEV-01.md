# PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-PUSH-IMAGE-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-PUSH-IMAGE-CLIENT-DEV
> Environnement : DEV image push only / aucun build / aucun deploy

## VERDICT

GO PUSH IMAGE CLIENT REGISTER AUTOPILOT TRIAL COPY DEV READY PH-SAAS-T8.12AS.19.5

- Image Client DEV poussee sur GHCR : `ghcr.io/keybuzzio/keybuzz-client:v3.5.203-register-autopilot-trial-copy-dev`
- Manifest digest GHCR : `sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9` (size 2631)
- Config digest : `sha256:faa09d39e47d1b9ae724a471208cd6fcca14227e328a87a2eb0cc50cfeb6c22c` MATCH image ID local
- Repo digest pulled-back : `ghcr.io/keybuzzio/keybuzz-client@sha256:7e471e7489a4...`
- Layers : 11 (5 nouveaux pousses, 6 reutilises, total 100.39 MB compresse)
- Push exit 0
- OCI labels KEY-308 : 5/5 preserves (revision fc4a43e)
- Runtime DEV/PROD inchange (6/6)
- AUCUN build, AUCUN deploy, AUCUN kubectl

Prochaine phrase GO attendue : GO APPLY CLIENT REGISTER AUTOPILOT TRIAL COPY DEV PH-SAAS-T8.12AS.19.5

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Image locale ID | sha256:faa09d39e47d1b9ae724a471208cd6fcca14227e328a87a2eb0cc50cfeb6c22c | OK |
| OCI revision label | fc4a43eb455cb0a0206110b4ccaa497344c38c6e | OK |
| Image locale Size | 279999003 bytes (280 MB) | OK |
| GHCR collision pre-push (try 1) | manifest unknown | tag FREE |
| GHCR collision pre-push (try 2) | manifest unknown | confirmation tag FREE |

## PUSH CLIENT DEV

| Param | Valeur |
|---|---|
| image locale | sha256:faa09d39e47d... (280 MB) |
| tag pousse | v3.5.203-register-autopilot-trial-copy-dev |
| push exit | 0 |
| layers nouveaux pousses | 5 (2a7370b1c8c4, 2cc836f0d380, 7df9079ae8af, 9f1c172c847f, 0aae06f3cae7) |
| layers reutilises | 6 (4cbec844eef7, afa543f85b46, e10358715ead, 4983b93ee796, 29df493baa13, ff88504cd133) |
| manifest digest GHCR | sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9 |
| manifest size | 2631 bytes |
| config digest | sha256:faa09d39e47d1b9ae724a471208cd6fcca14227e328a87a2eb0cc50cfeb6c22c |
| config size | 13021 bytes |
| layers count | 11 |
| layers total compresse | 105263484 bytes (100.39 MB) |
| repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-client@sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9 |

## DIGEST VERIFY (config digest = image ID local)

| Image | Manifest digest GHCR | Config digest | Image ID local | Match | Verdict |
|---|---|---|---|---|---|
| Client DEV v3.5.203-register-autopilot-trial-copy-dev | sha256:7e471e7489a4... | sha256:faa09d39e47d... | sha256:faa09d39e47d... | OUI prefix 12c match | OK |

## OCI LABELS KEY-308 (5/5 preserves)

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | fc4a43eb455cb0a0206110b4ccaa497344c38c6e |
| org.opencontainers.image.created | 2026-05-20T17:13:45Z |
| org.opencontainers.image.version | v3.5.203-register-autopilot-trial-copy-dev |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client |
| org.opencontainers.image.title | keybuzz-client |

## BUNDLE PROOF (verifications faites en phase BUILD-CLIENT-DEV-01)

L image poussee correspond bit-pour-bit a celle verifiee en phase PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-BUILD-CLIENT-DEV-01 (config digest sha256:faa09d39e47d match Image ID local) :

| Pattern bundle pre-push | Occurrences |
|---|---|
| api-dev.keybuzz.io (isolation DEV KEY-263) | 87 |
| api.keybuzz.io (sans -dev) | 0 |
| client-dev.keybuzz.io | 3 |
| register-autopilot-trial-note (PH-19.5) | 2 |
| Essai 14 jours sur Autopilot (PH-19.5) | 2 |
| 14 jours d essai gratuit sur Autopilot (PH-19.5) | 2 |
| bascule sur le plan choisi (PH-19.5) | 4 |
| register-lead-shell (PH-19.3) | 2 |
| register-reassurance-panel (PH-19.3) | 2 |
| register-confirm-plan (PH-19.3) | 2 |
| Confirmer ce plan et activer (PH-19.3) | 2 |
| data-selected (PH-19.4) | 2 |
| aria-pressed (PH-19.4) | 2 |
| invalid_marketing_owner_tenant_id (PH-19.4) | 2 |
| Le plus populaire (sur Autopilot) | 7 |
| Autopilot (id + nom) | 129 |
| data-clarity-mask (PII) | 26 |
| clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx | 0 / 0 / 0 |
| AW-XXXXXXXXXX direct | 0 |
| plan_selected | 4 (1 emit source unique x SSR + chunks refs) |

## RUNTIME PRESERVE READ-ONLY

| Service | Image runtime | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-dev | v3.5.202-register-qa-fix-dev | 1/1 | INCHANGE - sera bump vers v3.5.203 en phase APPLY |
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
- AUCUN nouveau tag autre que v3.5.203-register-autopilot-trial-copy-dev
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

## LINEAR BROUILLONS (NON postes, token hors-chat ; reauth Codex 401)

> **KEY-335 (primary)** : Image Client DEV v3.5.203-register-autopilot-trial-copy-dev poussee sur GHCR. Manifest digest sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9 (size 2631). Config digest sha256:faa09d39e47d... match image ID local. OCI labels KEY-308 5/5 preserves (revision fc4a43e, created 2026-05-20T17:13:45Z). 11 layers (5 nouveaux + 6 reutilises), 100.39 MB compresse. Push exit 0. STOP avant apply DEV. Prochaine etape : bump manifest k8s/keybuzz-client-dev/deployment.yaml v3.5.202 -> v3.5.203 + commit/push keybuzz-infra + kubectl apply + rollout + smoke.

> **KEY-334** : Image lead-first preserve apres ajout copy Autopilot trial. Patterns tunnel preserves (register-lead-shell 2, register-reassurance-panel 2, register-confirm-plan 2, CTAs). API DEV v3.5.251 candidate preserve.

> **KEY-329** : Image CRO post-clarify Autopilot trial publiee GHCR. Bundle ne contient toujours aucun fake review / fake logo / fake chiffre.

> **KEY-331** : plan_selected reste unique cote source (1 emit canonique). 4 refs bundle = SSR + chunks.

> **KEY-330** : No fake events ajoutes dans l image poussee. AW- direct = 0.

> **KEY-325** : Clarity client toujours non activee dans l image poussee (clarity.ms 0 / NEXT_PUBLIC_CLARITY 0 / wrff07upjx 0). 26 data-clarity-mask PII preserves.

## ROLLBACK PREP

Si la phase APPLY ulterieure echoue ou est annulee :
- Tag rollback Client DEV : `v3.5.202-register-qa-fix-dev`
- Digest rollback : `sha256:b2bc34a2f6c6d371c3bf26ac2f728ee305353861f2ed75106cddb865b7344f40`

Push GHCR realise (irreversible cote registry sauf garbage collection). Pour ne pas utiliser cette image : ne pas bumper le manifest DEV.

INTERDIT : git reset --hard, git clean.

## GAPS

1. Tag `v3.5.203-register-autopilot-trial-copy-dev` desormais public sur GHCR. Image existe en local + remote.
2. Comportement produit "essai sur Autopilot quel que soit le plan" : a valider cote API/Stripe/billing apres apply DEV.
3. Email logo template magic-link `client.keybuzz.io/branding/keybuzz-icon.png` toujours present (preexistant hors scope KEY-263).
4. Worktree `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.5/keybuzz-client` reste sur disque pour eventuelle phase PROD ulterieure ; cleanup possible post-PROD.
5. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline v3.5.202).
6. Clarity activation client.keybuzz.io reste decision post-QA.

## VERDICT FINAL

GO PUSH IMAGE CLIENT REGISTER AUTOPILOT TRIAL COPY DEV READY PH-SAAS-T8.12AS.19.5

| Composant | Tag | Manifest digest GHCR | Config digest | Repo digest |
|---|---|---|---|---|
| Client DEV | v3.5.203-register-autopilot-trial-copy-dev | sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9 | sha256:faa09d39e47d1b9ae724a471208cd6fcca14227e328a87a2eb0cc50cfeb6c22c | ghcr.io/keybuzzio/keybuzz-client@sha256:7e471e7489a4... |

- Push exit 0
- Image ID local match config digest GHCR (sha256:faa09d39e47d)
- OCI labels 5/5 preserves
- Runtime DEV/PROD inchanges (6/6)
- NO BUILD
- NO DEPLOY
- NO kubectl
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.5-REGISTER-AUTOPILOT-TRIAL-COPY-PUSH-IMAGE-CLIENT-DEV-01.md (untracked main)

Prochaine phrase GO attendue :

GO APPLY CLIENT REGISTER AUTOPILOT TRIAL COPY DEV PH-SAAS-T8.12AS.19.5

STOP.
