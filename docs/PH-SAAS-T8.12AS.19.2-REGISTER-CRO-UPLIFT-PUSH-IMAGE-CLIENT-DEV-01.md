# PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-PUSH-IMAGE-CLIENT-DEV-01

> Date : 2026-05-20
> Linear : KEY-329 (primary), KEY-333 (benchmark), KEY-325, KEY-330, KEY-331
> Phase : PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-PUSH-IMAGE-CLIENT-DEV
> Environnement : DEV image push only / aucun build / aucun deploy

## VERDICT

GO PUSH IMAGE CLIENT REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.2

- Client DEV image poussee sur GHCR : ghcr.io/keybuzzio/keybuzz-client:v3.5.200-register-cro-uplift-dev
- Manifest digest GHCR : sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18 (size 2631)
- Config digest : sha256:64143df05da4beefb121888772c13bbebc0447125f91ac1a9bb220a66e4f3822 (prefix 12c match image ID local 64143df05da4)
- Repo digest pulled-back : ghcr.io/keybuzzio/keybuzz-client@sha256:6b199ef2e548...
- Layers : 11 (3 nouveaux pousses, 8 reutilises, total 100.39 MB compresse)
- Push exit 0
- Runtime DEV/PROD inchanges
- NO BUILD, NO DEPLOY, NO kubectl

Prochaine phrase GO attendue : GO APPLY CLIENT REGISTER CRO DEV PH-SAAS-T8.12AS.19.2

## PREFLIGHT

| Element | Valeur | Verdict |
|---|---|---|
| host | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Image locale | 64143df05da4 (280 MB) | OK |
| revision label | 20737fd0aa8ee793ac7b522df6884c394caa5615 | OK |
| version label | v3.5.200-register-cro-uplift-dev | OK |
| created label | 2026-05-20T09:51:03Z | OK |
| GHCR collision pre-push | manifest unknown | tag FREE |

## PUSH CLIENT DEV v3.5.200

| Param | Valeur |
|---|---|
| image locale | 64143df05da4 (280 MB) |
| tag pousse | v3.5.200-register-cro-uplift-dev |
| push exit | 0 |
| layers nouveaux pousses | 5 (1bc20c52d8db, 1ed68e3a218c, 00a2c7ba6e63, 0d1f1284f9f7, 214dec545937) |
| layers reutilises | 5 (ff88504cd133, afa543f85b46, e10358715ead, 4983b93ee796, 29df493baa13, 4cbec844eef7) |
| manifest digest GHCR | sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18 |
| manifest size | 2631 |
| config digest | sha256:64143df05da4beefb121888772c13bbebc0447125f91ac1a9bb220a66e4f3822 |
| layers count | 11 |
| layers total size compresse | 105261655 bytes (100.39 MB) |
| repo digest pulled-back | ghcr.io/keybuzzio/keybuzz-client@sha256:6b199ef2e548... |

## DIGEST VERIFY (config digest = image ID local prefix 12c)

| Image | Manifest digest GHCR | Config digest | Image ID local | Match prefix 12c | Verdict |
|---|---|---|---|---|---|
| Client DEV v3.5.200-register-cro-uplift-dev | sha256:6b199ef2e548... | sha256:64143df05da4... | 64143df05da4 | sha256:64143df05da4 | OK |

## OCI LABELS KEY-308 (5/5 preserves)

| Label | Valeur |
|---|---|
| revision | 20737fd0aa8ee793ac7b522df6884c394caa5615 |
| created | 2026-05-20T09:51:03Z |
| version | v3.5.200-register-cro-uplift-dev |
| source | https://github.com/keybuzzio/keybuzz-client |
| title | keybuzz-client |

## BUNDLE PROOF (verifications faites en phase BUILD-CLIENT-DEV-01)

L image poussee correspond bit-pour-bit a celle verifiee en phase BUILD-CLIENT-DEV-01 :

| Pattern | Resultat bundle pre-push |
|---|---|
| api-dev.keybuzz.io | 87 occurrences (DEV isolation) |
| api.keybuzz.io (sans -dev) | 0 (pas de PROD leak) |
| Activez votre cockpit SAV marketplace | 2 (SSR + chunk) |
| Choisissez votre plan / Creez votre espace / Lancez l essai 14 jours | 6 / 2 / 2 |
| register-how-it-works / plan-card / cycle-toggle / plan-recap | 2 / 2 / 2 / 2 |
| data-clarity-mask | 26 (13 source x 2) |
| data-cta-id register_plan_select / register_cycle_toggle | 2 / 2 |
| data-promo-state | 2 |
| plan_selected emit | 4 |
| clarity.ms / NEXT_PUBLIC_CLARITY / wrff07upjx | 0 / 0 / 0 |
| AW-XXXXXXXXXX direct | 0 |

## RUNTIME PRESERVE (read-only)

| Cluster | Image runtime | Verdict |
|---|---|---|
| keybuzz-client-dev | v3.5.199-register-cro-dev (PH-19.1) | INCHANGE - sera bump vers v3.5.200 a la prochaine phase APPLY |
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

> **KEY-329 (primary)** : Image Client DEV v3.5.200-register-cro-uplift-dev pousse sur GHCR. Manifest digest sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18. Config digest sha256:64143df05da4... match image ID local. OCI labels KEY-308 5/5 preserves (revision 20737fd). STOP avant apply DEV. Prochaine etape : bump manifest k8s/keybuzz-client-dev/deployment.yaml + commit/push keybuzz-infra + kubectl apply + rollout + smoke.

> **KEY-333 (benchmark)** : Image benchmark uplift publiee GHCR. Bundle PH-19.2 deja verifie phase BUILD-CLIENT-DEV-01.

> **KEY-325 (Clarity)** : Clarity client toujours non activee dans l image poussee.

> **KEY-330 / KEY-331** : No fake events ajoutes. plan_selected preserve unique. Events ads browser-side existants src/lib/tracking.ts inchanges.

## CONFIRMATIONS NO BUILD / NO DEPLOY

- AUCUN docker build / rebuild
- AUCUN nouveau tag autre que v3.5.200-register-cro-uplift-dev
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
- Aucun deploy effectue, donc rien a defaire cote runtime (v3.5.199-register-cro-dev reste actif).
- Pour ne pas utiliser cette image : ne pas bumper le manifest DEV.

INTERDIT : git reset --hard, git clean.

## VERDICT FINAL

GO PUSH IMAGE CLIENT REGISTER CRO DEV READY PH-SAAS-T8.12AS.19.2

| Composant | Tag | Manifest digest GHCR | Config digest | Repo digest |
|---|---|---|---|---|
| Client DEV | v3.5.200-register-cro-uplift-dev | sha256:6b199ef2e5481e09aa057950e0e711b9b16008f3ced2b6a43d186c95c714ac18 | sha256:64143df05da4beefb121888772c13bbebc0447125f91ac1a9bb220a66e4f3822 | ghcr.io/keybuzzio/keybuzz-client@sha256:6b199ef2e548... |

- Push exit 0
- Runtime DEV/PROD inchanges
- NO BUILD
- NO DEPLOY
- Rapport local : keybuzz-infra/docs/PH-SAAS-T8.12AS.19.2-REGISTER-CRO-UPLIFT-PUSH-IMAGE-CLIENT-DEV-01.md (untracked main)

Prochaine phrase GO attendue :

GO APPLY CLIENT REGISTER CRO DEV PH-SAAS-T8.12AS.19.2

STOP.
