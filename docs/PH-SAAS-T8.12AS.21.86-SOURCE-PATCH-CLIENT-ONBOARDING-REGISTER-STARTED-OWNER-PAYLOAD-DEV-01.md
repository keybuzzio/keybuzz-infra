# PH-SAAS-T8.12AS.21.86 - Source patch Client onboarding register_started owner payload DEV

Date UTC: 2026-06-22T11:36:39Z

Verdict: READY_FOR_PUSH

Phrase finale:

`GO SOURCE PATCH CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV READY_FOR_PUSH PH-SAAS-T8.12AS.21.86`

## Resume Ludovic

Le patch Client DEV est applique et committe localement. `register_started.properties` porte maintenant l'owner marketing, les UTM et les click IDs disponibles via une allowlist explicite. Aucun push, build, deploy, DB mutation, event reel/fake, formulaire, checkout, Webflow ou Linear n'a ete effectue.

## Scope

Mode respecte: SOURCE PATCH CLIENT DEV.

Hors scope respecte:

- aucun push Git;
- aucun build Docker;
- aucun docker push;
- aucun deploy;
- aucun kubectl apply;
- aucune mutation DB;
- aucun POST /funnel/event;
- aucun formulaire /register;
- aucun checkout Stripe;
- aucun fake event CAPI/Meta/GA4/TikTok/LinkedIn;
- aucun Webflow;
- aucun Linear.

## Preflight bastion

| Point | Resultat | Verdict |
| --- | --- | --- |
| Hostname | install-v3 | OK |
| IPv4 | 46.62.171.61 | OK |
| Date UTC | 2026-06-22T11:36:39Z | OK |

## Repos

| Repo | Branche | Remote | HEAD avant | HEAD apres | Ahead/behind | Dirty avant | Dirty apres | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-client | ph148/onboarding-activation-replay | https://github.com/keybuzzio/keybuzz-client.git | ad4e862a2e63 | d9631ca087f1 | 0/1 | tsconfig.tsbuildinfo preexistant |  M tsconfig.tsbuildinfo | OK, dirty hors scope non stage |
| keybuzz-infra | main | https://github.com/keybuzzio/keybuzz-infra.git | e80e8543b5ce | pending docs commit | 0/0 | 0 | pending | OK |
| keybuzz-api | ph147.4/source-of-truth | https://github.com/keybuzzio/keybuzz-api.git | 35673e3b16f4 | lecture seule | 0/0 | dist deletions preexistantes | non modifie | READONLY |

## Sources relues

| Source | Existe | Resultat utile |
| --- | --- | --- |
| PH-21.86 mission | oui | patch Client DEV uniquement, commits locaux |
| AI_MEMORY CURRENT_STATE/RULES/DOCUMENT_MAP/CE_PROMPTING_STANDARD | oui | regles DEV avant PROD, no fake events, GitOps strict |
| Modele PH-T8.10J | oui | format long et verrous source |
| PH-21.78 rapport | nom equivalent hyphen trouve | snippet browser insuffisant, server-side recommande |
| PH-21.79 rapport | nom equivalent hyphen trouve | API trial_page_viewed derive de register_started |
| PH-21.80 a PH-21.84 | oui | API DEV v3.5.264 close, NO_NATURAL_TRAFFIC |
| PH-21.85 | oui | Client register_started.properties owner/UTM/click IDs KO avant patch |

## Rappel PH-21.85

| Point | Etat PH-21.85 |
| --- | --- |
| API source | trial_page_viewed present, owner via properties ou env |
| Client capture owner | OK |
| Client create-signup owner | OK |
| Client register_started.properties owner | KO |
| Client register_started UTM/click IDs | KO |
| Decision | source patch Client requis avant promotion PROD |

## Audit source Client

| Element | Fichier | Etat avant | Etat apres |
| --- | --- | --- | --- |
| Emission register_started | app/register/page.tsx | plan/cycle uniquement | plan/cycle + properties allowlist |
| Attribution capture | src/lib/attribution.ts | owner/UTM/click IDs deja captures | helper expose un payload safe |
| create-signup owner | app/register/page.tsx | deja present | intact |
| funnel event helper | src/lib/funnel.ts | accepte properties | inchange |

## Design patch

| Decision | Choix | Justification | Risque |
| --- | --- | --- | --- |
| Source attribution | reutiliser AttributionContext existant | evite duplication et hardcode | faible |
| Allowlist | helper buildRegisterStartedAttributionProperties | exclut PII/secrets/cookies bruts | faible |
| Payload | injecte dans register_started.properties | API PH-21.79 lit properties.marketing_owner_tenant_id | faible |
| Idempotence | emission et dedupe inchanges | pas de nouvel event ni duplication | faible |
| landing_url/referrer | exclus du payload | peut contenir email/query sensible | dette documentee |

## Patch applique

| Fichier | Changement | Risque | Test |
| --- | --- | --- | --- |
| app/register/page.tsx | importe le helper et passe properties a register_started | faible | lint + test static |
| src/lib/attribution.ts | ajoute helper allowlist owner/UTM/click IDs/plan/cycle/promo | faible | node test + tsc cible |
| scripts/ph2186-register-started-attribution.test.cjs | test offline du helper et de l'injection source | nul runtime | node local |

## Champs payload

| Champ | Source Client | Inclus si disponible | PII risk | Resultat |
| --- | --- | --- | --- | --- |
| marketing_owner_tenant_id | AttributionContext | oui | non | OK |
| utm_source | AttributionContext | oui | non | OK |
| utm_medium | AttributionContext | oui | non | OK |
| utm_campaign | AttributionContext | oui | non | OK |
| utm_content | AttributionContext | oui | non | OK |
| utm_term | AttributionContext | oui | non | OK |
| fbclid | AttributionContext | oui | click ID autorise | OK |
| gclid | AttributionContext | oui | click ID autorise | OK |
| ttclid | AttributionContext | oui | click ID autorise | OK |
| li_fat_id | AttributionContext | oui | click ID autorise | OK |
| plan | opts/context | oui | non | OK |
| cycle | opts/context | oui | non | OK |
| promo | AttributionContext | oui | non | OK |
| landing_url | AttributionContext | non | possible PII query | EXCLU |
| referrer | AttributionContext | non | possible PII query | EXCLU |
| fbc/fbp/_gl | AttributionContext/cookies/linker | non | cookie/linker | EXCLU |

## Tests offline/mock

| Test | Commande | Attendu | Resultat |
| --- | --- | --- | --- |
| Diff whitespace | git diff --check | PASS | PASS |
| Test helper offline | node scripts/ph2186-register-started-attribution.test.cjs | payload owner+UTM+click IDs, exclusions PII | PASS |
| Lint cible | npm run lint -- --file app/register/page.tsx --file src/lib/attribution.ts | 0 erreur | PASS |
| TypeScript cible | npx tsc --noEmit --incremental false --pretty false src/lib/attribution.ts | 0 erreur | PASS |
| TypeScript global | npx tsc --noEmit --incremental false --pretty false | ideal PASS | FAIL_PREEXISTING: .next/types/app/api/debug-env/route.ts module absent |

## No fake metrics / no fake events

| Controle | Resultat |
| --- | --- |
| POST /funnel/event | 0 |
| Formulaire /register | 0 |
| Checkout Stripe | 0 |
| CAPI test | 0 |
| Fake event Meta/GA4/TikTok/LinkedIn | 0 |
| DB mutation | 0 |
| Build/deploy | 0 |

## Non-regression tracking

| Surface | Attendu | Resultat |
| --- | --- | --- |
| register_started | meme nom, meme dedupe | OK |
| StartTrial | non modifie | OK |
| Purchase | non modifie | OK |
| CompletePayment / InitiateCheckout / Lead | non modifie | OK |
| Stripe checkout | non modifie | OK |
| create-signup | owner existant preserve | OK |
| API helper trial_page_viewed | lecture seule, compatible properties | OK |
| conversion_events | aucune modification | OK |
| Webflow / Website | non touche | OK |

## API read-only

| Point API lu | Resultat | Impact sur PH-21.86 |
| --- | --- | --- |
| emitTrialPageViewedMetaFromRegisterStarted | present | Client properties consommees |
| properties.marketing_owner_tenant_id | present | patch Client suffisant |
| env fallback | present | pas utilise par ce patch |
| StartTrial/Purchase | presents | intacts |

## Commits locaux

| Repo | Commit local | Message | Push |
| --- | --- | --- | --- |
| keybuzz-client | d9631ca087f1 | fix(tracking): include owner attribution in register_started | non |
| keybuzz-infra | ce rapport, hash final dans le retour CE | docs(PH-21.86): source patch register_started owner payload | non |

## Dettes / limites

- Aucun trafic naturel DEV observe dans cette phase.
- Pas de preuve Ads Manager ou CAPI live, volontairement hors scope.
- Pas de build/deploy dans PH-21.86.
- Dirty preexistant Client conserve: `tsconfig.tsbuildinfo`.
- TypeScript global echoue sur dette preexistante `.next/types/app/api/debug-env/route.ts`, hors patch.
- Promotion API/Client PROD separee.
- Test sans CB reporte/hors scope.

## Prochain GO recommande

`GO PUSH SOURCE PATCH CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV PH-SAAS-T8.12AS.21.86`
