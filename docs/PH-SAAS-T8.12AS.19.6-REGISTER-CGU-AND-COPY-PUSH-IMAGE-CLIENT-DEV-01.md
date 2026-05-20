# PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-PUSH-IMAGE-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-PUSH-IMAGE-CLIENT-DEV
> Environnement : DEV image push only / aucun build / aucun deploy

## VERDICT

GO PUSH IMAGE CLIENT REGISTER CGU + COPY F.9 DEV READY PH-SAAS-T8.12AS.19.6

- Image Client DEV poussee sur GHCR : `ghcr.io/keybuzzio/keybuzz-client:v3.5.204-register-cgu-and-copy-dev`
- Manifest digest GHCR : `sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3` (size 2631)
- Config digest : `sha256:256f2d822338ff63aad7b471f8c530fd24ad8361dd2af24f0d2622d7e27561c3` MATCH image ID local
- Repo digest pulled-back : `ghcr.io/keybuzzio/keybuzz-client@sha256:17a31829c644...`
- Layers : 11 (5 nouveaux pousses, 6 reutilises, total 100.39 MB compresse)
- Push exit 0
- OCI labels KEY-308 : 5/5 preserves (revision bae77de)
- Runtime DEV/PROD inchange (6/6)
- AUCUN build, AUCUN deploy, AUCUN kubectl

Prochaine phrase GO attendue : GO APPLY CLIENT REGISTER CGU + COPY F.9 DEV PH-SAAS-T8.12AS.19.6

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Image locale ID | sha256:256f2d822338ff63aad7b471f8c530fd24ad8361dd2af24f0d2622d7e27561c3 | OK |
| OCI revision label | bae77de5b064c7edb7f6cb98440fd7710697f8e0 | OK |
| Image locale Size | 280001769 bytes (280 MB) | OK |
| GHCR collision pre-push (try 1) | manifest unknown | tag FREE |
| GHCR collision pre-push (try 2) | manifest unknown | confirmation tag FREE |

## PUSH CLIENT DEV

| Param | Valeur |
|---|---|
| image locale | sha256:256f2d822338... (280 MB) |
| tag pousse | v3.5.204-register-cgu-and-copy-dev |
| push exit | 0 |
| layers nouveaux pousses | 5 (dba35097b1e6, 2f2033e96adf, 73d43b717837, e4e79ae4c62b, 69b60483580a) |
| layers reutilises | 6 (4cbec844eef7, afa543f85b46, e10358715ead, 4983b93ee796, 29df493baa13, ff88504cd133) |
| manifest digest GHCR | sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3 |
| manifest size | 2631 bytes |
| config digest | sha256:256f2d822338ff63aad7b471f8c530fd24ad8361dd2af24f0d2622d7e27561c3 |
| config size | 12980 bytes |
| layers count | 11 |
| layers total compresse | 105264064 bytes (100.39 MB) |
| repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-client@sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3 |

## DIGEST VERIFY (config digest = image ID local)

| Image | Manifest digest GHCR | Config digest | Image ID local | Match | Verdict |
|---|---|---|---|---|---|
| Client DEV v3.5.204-register-cgu-and-copy-dev | sha256:17a31829c644... | sha256:256f2d822338... | sha256:256f2d822338... | OUI prefix 12c | OK |

## OCI LABELS KEY-308 (5/5 preserves)

| Label | Valeur |
|---|---|
| org.opencontainers.image.revision | bae77de5b064c7edb7f6cb98440fd7710697f8e0 |
| org.opencontainers.image.created | 2026-05-20T18:49:31Z |
| org.opencontainers.image.version | v3.5.204-register-cgu-and-copy-dev |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client |
| org.opencontainers.image.title | keybuzz-client |

## BUNDLE PROOF (verifications faites en phase BUILD-CLIENT-DEV-01)

L image poussee correspond bit-pour-bit a celle verifiee en phase PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-BUILD-CLIENT-DEV-01 (config digest sha256:256f2d822338 match Image ID local) :

| Pattern bundle pre-push | Occurrences |
|---|---|
| api-dev.keybuzz.io (isolation DEV KEY-263) | 87 |
| api.keybuzz.io (sans -dev) | 0 |
| client-dev.keybuzz.io | 3 |
| kb_signup_cgu_accepted (PH-19.6 persist) | 2 |
| register-cgu-accepted-note (PH-19.6 encart accepte) | 2 |
| register-cgu-plan-checkbox (PH-19.6 checkbox step plan) | 2 |
| Voir les CGU (lien encart accepte) | 2 |
| 0 EUR pendant 14 jours (PH-19.6 titre + variante) | 4 |
| Aucun debit avant la fin de l essai (phrase principale) | 2 |
| Carte demandee a l activation | 2 |
| capacites Autopilot | 2 |
| le plan selectionne devient actif | 2 |
| votre plan prend le relais | 2 |
| register-lead-shell (PH-19.3) | 2 |
| register-reassurance-panel (PH-19.3) | 2 |
| register-confirm-plan (PH-19.3) | 2 |
| register-autopilot-trial-note (PH-19.3 data-testid + contenu PH-19.6) | 2 |
| data-selected (PH-19.4) | 2 |
| aria-pressed (PH-19.4) | 2 |
| invalid_marketing_owner_tenant_id (PH-19.4) | 2 |
| Le plus populaire (sur Autopilot) | 7 |
| Autopilot (id + nom) | 127 |
| data-clarity-mask (PII) | 26 |
| clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx | 0 / 0 / 0 |
| AW-XXXXXXXXXX direct | 0 |
| plan_selected | 4 (1 emit source unique x SSR + chunks refs) |
| tout le monde teste Autopilot (vieux PH-19.5) | 0 (supprime) |
| CB requise a cette etape uniquement (vieux PH-19.5) | 0 (supprime) |

## RUNTIME PRESERVE READ-ONLY

| Service | Image runtime | Ready | Verdict |
|---|---|---|---|
| keybuzz-client-dev | v3.5.203-register-autopilot-trial-copy-dev | 1/1 | INCHANGE - sera bump vers v3.5.204 en phase APPLY |
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
- AUCUN nouveau tag autre que v3.5.204-register-cgu-and-copy-dev
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

> **KEY-335 (primary)** : Image Client DEV v3.5.204-register-cgu-and-copy-dev poussee sur GHCR. Manifest digest sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3 (size 2631). Config digest sha256:256f2d822338... match image ID local. OCI labels KEY-308 5/5 preserves (revision bae77de, created 2026-05-20T18:49:31Z). 11 layers (5 nouveaux + 6 reutilises), 100.39 MB compresse. Push exit 0. STOP avant apply DEV. Prochaine etape : bump manifest k8s/keybuzz-client-dev/deployment.yaml v3.5.203 -> v3.5.204 + commit/push keybuzz-infra + kubectl apply + rollout + smoke.

> **KEY-334** : Image post-CGU fix + copy F.9 publiee GHCR. Tunnel lead-first preserve (register-lead-shell + register-reassurance-panel + register-confirm-plan + register-autopilot-trial-note avec nouveau contenu 0 EUR).

> **KEY-329** : Image CRO post-CGU fix + factuel SaaS pro publiee GHCR. Bundle ne contient aucun fake review / fake logo / fake chiffre.

> **KEY-331** : plan_selected reste unique cote source (1 emit canonique). 4 refs bundle.

> **KEY-330** : No fake events ajoutes par PH-19.6. AW- direct = 0.

> **KEY-325** : Clarity client toujours non activee. 26 data-clarity-mask PII preserves.

## ROLLBACK PREP

Si la phase APPLY ulterieure echoue ou est annulee :
- Tag rollback Client DEV : `v3.5.203-register-autopilot-trial-copy-dev`
- Digest rollback : `sha256:7e471e7489a44bcc5978b2c3ad28dc793ab574197e105b9ea4344920a29d78f9`

Push GHCR realise (irreversible cote registry sauf garbage collection). Pour ne pas utiliser cette image : ne pas bumper le manifest DEV.

INTERDIT : git reset --hard, git clean.

## GAPS

1. Tag `v3.5.204-register-cgu-and-copy-dev` desormais public sur GHCR. Image existe en local + remote.
2. Comportement "0 EUR pendant 14 jours" et "le plan selectionne devient actif" : a valider QA fonctionnel post-apply (Stripe trial_period_days=14, absence capture pre-trial, UI Facturation pour change/cancel).
3. Email logo template magic-link `client.keybuzz.io/branding/keybuzz-icon.png` preexistant hors scope.
4. Worktree `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.19.6/keybuzz-client` reste sur disque ; cleanup possible post-PROD.
5. Marketing IDs (GA4/Meta/TikTok/SGTM) toujours omis du build DEV (iso baseline v3.5.203).
6. Clarity activation client.keybuzz.io reste decision post-QA.

## VERDICT FINAL

GO PUSH IMAGE CLIENT REGISTER CGU + COPY F.9 DEV READY PH-SAAS-T8.12AS.19.6

| Composant | Tag | Manifest digest GHCR | Config digest | Repo digest |
|---|---|---|---|---|
| Client DEV | v3.5.204-register-cgu-and-copy-dev | sha256:17a31829c644fa7e5d4eceba70e177642e9bdd18a9a82a34e5f1c5c43f7857a3 | sha256:256f2d822338ff63aad7b471f8c530fd24ad8361dd2af24f0d2622d7e27561c3 | ghcr.io/keybuzzio/keybuzz-client@sha256:17a31829c644... |

- Push exit 0
- Image ID local match config digest GHCR (sha256:256f2d822338)
- OCI labels 5/5 preserves
- Runtime DEV/PROD inchanges (6/6)
- NO BUILD
- NO DEPLOY
- NO kubectl
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.6-REGISTER-CGU-AND-COPY-PUSH-IMAGE-CLIENT-DEV-01.md (untracked main)

Prochaine phrase GO attendue :

GO APPLY CLIENT REGISTER CGU + COPY F.9 DEV PH-SAAS-T8.12AS.19.6

STOP.
