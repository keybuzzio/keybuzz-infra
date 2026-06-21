# PH-SAAS-T8.12AS.21.79 - SOURCE PATCH ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV

## RESUME LUDOVIC - TERMINAL

Verdict: READY_WITH_DEBTS - SOURCE PATCH DEV LOCAL DONE PH-SAAS-T8.12AS.21.79

API patch local: commit 35673e3b `feat(tracking): add server-side trial_page_viewed meta event`.

Signal ajoute: Meta CAPI custom event `trial_page_viewed`, derive uniquement du premier `register_started` client insere par `/funnel/event`.

StartTrial/Purchase: intacts. Aucun changement du webhook billing, aucun changement `emitOutboundConversion('StartTrial'|'Purchase')`, aucune pollution `conversion_events`.

Tests offline/mock: `tsc -p tsconfig.build.json --noEmit` OK; test PH-21.79 compile + Node OK; `git diff --check` OK.

Runtime: aucune mutation. Aucun push, build, deploy, DB mutation, event reel/fake, formulaire `/register`, checkout Stripe, Webflow ou Linear.

Dette bloquante activation: pour emettre en runtime, il faut une source fiable de `marketing_owner_tenant_id` via properties ou env `TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID`, puis deploy DEV en phase separee.

Prochain GO recommande: GO PUSH SOURCE PATCH ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PH-SAAS-T8.12AS.21.79

STOP

## Scope

Mode execute: SOURCE PATCH DEV uniquement.

Objectif: partir sur SERVER_SIDE_CAPI_FROM_REGISTER_STARTED, pas sur le snippet browser Antoine.

Hors scope respecte:

| Interdit | Resultat |
| --- | --- |
| Push Git | Non execute |
| Build Docker | Non execute |
| Deploy / kubectl apply | Non execute |
| DB mutation | Non execute |
| Event reel ou fake event | Non execute |
| Formulaire `/register` | Non soumis |
| Checkout Stripe | Non execute |
| Webflow / Linear | Non touche |
| Secret/token/PII brut | Non affiche |

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.79_CE_MISSION.md` | Lu |
| `AI_MEMORY/CURRENT_STATE.md` | Lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | Lu |
| `AI_MEMORY/DOCUMENT_MAP.md` | Lu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | Lu |
| Modele `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | Lu |
| `PH-21.55_CE_RETURN.md` | Lu |
| `PH-21.56_CE_RETURN.md` | Lu |
| `PH-21.78_CE_RETURN.md` | Lu |

## Preflight

| Repo | Branche | HEAD avant | Dirty avant | Verdict |
| --- | --- | --- | --- | --- |
| keybuzz-api | `ph147.4/source-of-truth` | `76483e3a` | dirty preexistant `dist/` deletions | OK, source patch cible |
| keybuzz-infra | `main` | observe avant rapport | clean attendu | OK docs-only |

Dirty API connu et preserve: suppressions preexistantes sous `dist/`, deja documentees par les phases precedentes. Aucune commande destructive, aucun reset/clean.

## Patch API

| Fichier | Changement | Risque / garde-fou |
| --- | --- | --- |
| `src/modules/funnel/routes.ts` | Accroche non bloquante apres insertion nouvelle de `register_started` client | Duplicate ignore: pas d'emission si `ON CONFLICT` retourne `already_recorded` |
| `src/modules/outbound-conversions/emitter.ts` | Helper Meta-only `emitTrialPageViewedMetaFromRegisterStarted` + payload custom `trial_page_viewed` | Owner tenant requis via properties/env, skip safe sinon |
| `src/modules/outbound-conversions/adapters/meta-capi.ts` | Mapping explicite `trial_page_viewed` + support `custom_data` generique | `StartTrial` et `Purchase` mappings inchanges |
| `src/tests/ph2179-trial-page-viewed-meta-tests.ts` | Tests offline sur gate, owner, attribution, payload, adapter Meta | Aucun appel reseau/DB |

## Design applique

| Point | Decision |
| --- | --- |
| Signal source | `register_started` insere par `/funnel/event` |
| Emission | Server-side Meta CAPI custom event |
| Nom event Meta | `trial_page_viewed` |
| Idempotence | Garde par `ON CONFLICT (funnel_id,event_name)` puis event_id stable `tpv_<sha256>` |
| Destinations | Meta CAPI uniquement, pas TikTok/LinkedIn/webhook |
| Conversion business | Non utilisee, pas d'insertion `conversion_events` |
| Source URL DEV | `https://client-dev.keybuzz.io/register` par defaut hors production |
| Source URL PROD | `https://client.keybuzz.io/register` si `NODE_ENV=production` ou env explicite |
| Owner routing | `marketing_owner_tenant_id` properties/nested ou `TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID` |
| Skip safe | owner absent, tenant owner introuvable, destination Meta inactive/absente |

## StartTrial / Purchase non-regression

| Controle | Resultat |
| --- | --- |
| `emitOutboundConversion` signature | Inchangee: accepte seulement `StartTrial` ou `Purchase` |
| Webhook billing | Non modifie |
| `conversion_events` business | Non modifie, non utilise par `trial_page_viewed` |
| Meta mapping `StartTrial` | Inchange |
| Meta mapping `Purchase` | Inchange |
| Payload `trial_page_viewed` | Ne contient pas `StartTrial` ni `Purchase` |

## Tests offline

| Test | Attendu | Resultat |
| --- | --- | --- |
| `./node_modules/.bin/tsc -p tsconfig.build.json --noEmit` | Typecheck source sans build runtime | PASS |
| Targeted compile PH-21.79 vers `/tmp/ph2179-test-build` | Compilation test offline | PASS |
| `NODE_PATH=/opt/keybuzz/keybuzz-api/node_modules node /tmp/ph2179-test-build/tests/ph2179-trial-page-viewed-meta-tests.js` | 5 tests PASS | PASS |
| `git diff --check` | Aucun whitespace error | PASS |

Note: une premiere execution Node depuis `/tmp` sans `NODE_PATH` a echoue sur resolution locale `pg`; aucun code produit n'a ete change et aucun effet runtime. Le meme artefact compile a ensuite passe avec `NODE_PATH` pointe vers `node_modules` du repo, sans install/download.

## Commit API

| Point | Valeur |
| --- | --- |
| Commit | `35673e3b` |
| Message | `feat(tracking): add server-side trial_page_viewed meta event` |
| Fichiers | 4 |
| Push | Non execute |

Fichiers commit:

- `src/modules/funnel/routes.ts`
- `src/modules/outbound-conversions/adapters/meta-capi.ts`
- `src/modules/outbound-conversions/emitter.ts`
- `src/tests/ph2179-trial-page-viewed-meta-tests.ts`

## Dettes / limites

| Dette | Impact | Prochaine phase |
| --- | --- | --- |
| Source owner runtime | Si `marketing_owner_tenant_id` n'est pas fournie par properties ou env, emission skip safe | Config/source propagation a valider avant deploy |
| Activation runtime DEV | Non deployee dans cette phase | Build/deploy DEV phase separee apres push |
| Preuve Meta reelle | Aucun event reel/fake envoye | Observation uniquement apres vrai trafic et deploy |
| Browser snippet Antoine | Non applique | Decision conservee: server-side uniquement |

## Verdict final

READY_WITH_DEBTS - SOURCE PATCH ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV LOCAL DONE PH-SAAS-T8.12AS.21.79

Prochain GO recommande:

`GO PUSH SOURCE PATCH ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PH-SAAS-T8.12AS.21.79`

STOP
