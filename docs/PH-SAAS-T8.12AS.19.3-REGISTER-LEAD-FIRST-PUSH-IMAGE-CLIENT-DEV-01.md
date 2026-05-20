# PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-PUSH-IMAGE-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-334 (primary), KEY-329, KEY-333, KEY-325, KEY-330, KEY-331
> Phase : PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-PUSH-IMAGE-CLIENT-DEV
> Environnement : DEV image push only / aucun build / aucun deploy

## VERDICT

GO PUSH IMAGE CLIENT REGISTER LEAD FIRST DEV READY PH-SAAS-T8.12AS.19.3

- Client DEV image poussee sur GHCR : ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-lead-first-dev
- Manifest digest GHCR : sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de (size 2631)
- Config digest : sha256:4c58fbe7ce9335714e5af1935f8715f2e32fa1d4cf185546df49551546ad4efd (prefix 12c match image ID local 4c58fbe7ce93)
- Repo digest pulled-back : ghcr.io/keybuzzio/keybuzz-client@sha256:8d82660f52af...
- Layers : 11 (5 nouveaux pousses, 6 reutilises, total 100.39 MB compresse)
- Push exit 0
- Runtime DEV/PROD inchanges
- NO BUILD, NO DEPLOY, NO kubectl

Prochaine phrase GO attendue : GO APPLY CLIENT REGISTER LEAD FIRST DEV PH-SAAS-T8.12AS.19.3

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Image locale | 4c58fbe7ce93 (280 MB) | OK |
| revision label | 397687a8320fdada7b924dfe124659db9d6e81d0 | OK |
| version label | v3.5.201-register-lead-first-dev | OK |
| created label | 2026-05-20T12:21:01Z | OK |
| GHCR collision pre-push | manifest unknown (both try 1 + try 2) | tag FREE |

## PUSH CLIENT DEV v3.5.201

| Param | Valeur |
|---|---|
| image locale | 4c58fbe7ce93 (280 MB) |
| tag pousse | v3.5.201-register-lead-first-dev |
| push exit | 0 |
| layers nouveaux pousses | 5 (82fb94c0a4eb, 75de1098cb26, 14074aff2492, 34f55680f839, 765425e2199c) |
| layers reutilises | 6 (4cbec844eef7, afa543f85b46, e10358715ead, ff88504cd133, 29df493baa13, 4983b93ee796) |
| manifest digest GHCR | sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de |
| manifest size | 2631 |
| config digest | sha256:4c58fbe7ce9335714e5af1935f8715f2e32fa1d4cf185546df49551546ad4efd |
| layers count | 11 |
| layers total size compresse | 105262712 bytes (100.39 MB) |
| repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-client@sha256:8d82660f52af... |

## DIGEST VERIFY (config digest = image ID local prefix 12c)

| Image | Manifest digest GHCR | Config digest | Image ID local | Match prefix 12c | Verdict |
|---|---|---|---|---|---|
| Client DEV v3.5.201-register-lead-first-dev | sha256:8d82660f52af... | sha256:4c58fbe7ce93... | 4c58fbe7ce93 | sha256:4c58fbe7ce93 | OK |

## OCI LABELS KEY-308 (5/5 preserves)

| Label | Valeur |
|---|---|
| revision | 397687a8320fdada7b924dfe124659db9d6e81d0 |
| created | 2026-05-20T12:21:01Z |
| version | v3.5.201-register-lead-first-dev |
| source | https://github.com/keybuzzio/keybuzz-client |
| title | keybuzz-client |

## BUNDLE PROOF (verifications faites en phase BUILD-CLIENT-DEV-01)

L image poussee correspond bit-pour-bit a celle verifiee en phase BUILD-CLIENT-DEV-01 :

| Pattern | Resultat bundle pre-push |
|---|---|
| api-dev.keybuzz.io | 87 occurrences (DEV isolation) |
| api.keybuzz.io (sans -dev) | 0 (pas de PROD leak) |
| register-lead-shell | 2 (SSR + chunk) |
| register-reassurance-panel | 2 |
| register-lead-form | 2 |
| register-confirm-plan | 2 |
| "Continuer vers le plan" (CTA step user) | 2 |
| "Confirmer ce plan et activer" (CTA step plan) | 2 |
| "Ce que KeyBuzz va gerer" (ReassurancePanel header) | 2 |
| "Activez votre cockpit SAV" (h1) | 2 |
| data-clarity-mask | 26 (13 source x 2) |
| data-cta-id register_continue_to_plan | 2 |
| data-cta-id register_confirm_plan_and_checkout | 2 |
| plan_selected | 4 |
| clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx | 0 / 0 / 0 |
| AW-XXXXXXXXXX direct | 0 |

## RUNTIME PRESERVE (read-only)

| Cluster | Image runtime | Verdict |
|---|---|---|
| keybuzz-client-dev | v3.5.200-register-cro-uplift-dev (PH-19.2) | INCHANGE - sera bump vers v3.5.201 a la prochaine phase APPLY |
| keybuzz-client-prod | v3.5.198-debug-env-disabled-prod | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE (candidate API valide) |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |

| Artefact | Valeur |
|---|---|
| docker build | NON execute |
| nouveau tag autre que scope | aucun |
| kubectl apply | NON execute |
| kubectl set / patch / edit | NON execute |
| Modification manifest infra | aucune |
| Commit infra additionnel | aucun (rapport docs PH untracked apres mv) |

## LINEAR BROUILLONS (NON postes, token hors-chat)

> **KEY-334 (primary)** : Image Client DEV v3.5.201-register-lead-first-dev pousse sur GHCR. Manifest digest sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de. Config digest sha256:4c58fbe7ce93... match image ID local. OCI labels KEY-308 5/5 preserves (revision 397687a). STOP avant apply DEV. Prochaine etape : bump manifest k8s/keybuzz-client-dev/deployment.yaml + commit/push keybuzz-infra + kubectl apply + rollout + smoke.

> **KEY-329** : Image Client DEV v3.5.201 lead-first publiee GHCR. Bundle PH-19.3 deja verifie phase BUILD-CLIENT-DEV-01. API v3.5.251 candidate unchanged.

> **KEY-333 (benchmark)** : Image benchmark lead-first publiee GHCR.

> **KEY-325 (Clarity)** : Clarity client toujours non activee dans l image poussee.

> **KEY-330 / KEY-331** : No fake events ajoutes. plan_selected preserve unique. Events ads existants src/lib/tracking.ts inchanges.

## CONFIRMATIONS NO BUILD / NO DEPLOY

- AUCUN docker build / rebuild
- AUCUN nouveau tag autre que v3.5.201-register-lead-first-dev
- AUCUN deploy DEV/PROD
- AUCUN kubectl apply / set / patch / edit
- AUCUN changement manifest infra
- AUCUN git commit/push source application
- AUCUN secret expose dans logs / labels
- AUCUNE activation Clarity client.keybuzz.io
- AUCUN changement Admin / Backend / Studio / Website / Stripe / Vault / ESO
- AUCUN changement /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Bastion install-v3 (46.62.171.61) uniquement

## ROLLBACK

Push GHCR realise (irreversible cote registry sauf garbage collection). Pour rollback applicatif :
- Aucun deploy effectue, donc rien a defaire cote runtime (v3.5.200-register-cro-uplift-dev reste actif).
- Pour ne pas utiliser cette image : ne pas bumper le manifest DEV.

INTERDIT : git reset --hard, git clean.

## VERDICT FINAL

GO PUSH IMAGE CLIENT REGISTER LEAD FIRST DEV READY PH-SAAS-T8.12AS.19.3

| Composant | Tag | Manifest digest GHCR | Config digest | Repo digest |
|---|---|---|---|---|
| Client DEV | v3.5.201-register-lead-first-dev | sha256:8d82660f52af460194c12161847aed004f55ca62c340b9bb35f52c9954d0b5de | sha256:4c58fbe7ce9335714e5af1935f8715f2e32fa1d4cf185546df49551546ad4efd | ghcr.io/keybuzzio/keybuzz-client@sha256:8d82660f52af... |

- Push exit 0
- Runtime DEV/PROD inchanges
- NO BUILD
- NO DEPLOY
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.3-REGISTER-LEAD-FIRST-PUSH-IMAGE-CLIENT-DEV-01.md (untracked main)

Prochaine phrase GO attendue :

GO APPLY CLIENT REGISTER LEAD FIRST DEV PH-SAAS-T8.12AS.19.3

STOP.
