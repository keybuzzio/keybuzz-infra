# PH-SAAS-T8.12AS.21.113 - READONLY DESIGN META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD PROMOTION SAFETY

Date UTC: 2026-06-24
Mode: READONLY DESIGN PROD PROMOTION SAFETY
Scope: design de promotion PROD de l'observability Meta CAPI trial_page_viewed delivery error
Verdict: READY_FOR_BUILD_PROD

## Objectif

Determiner si la chaine DEV PH-21.107 a PH-21.112 prouve suffisamment le patch
`v3.5.265-meta-capi-error-observability-dev` pour autoriser la phase suivante:
build API PROD de l'image immutable
`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod`.

Cette phase ne construit pas, ne pousse pas d'image, ne deploie pas, ne rejoue aucun
event, ne fait aucun POST `/funnel/event`, ne fait aucune mutation DB et ne touche pas
a Linear.

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | Relu pour contraintes KeyBuzz et GitOps |
| PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01 | Relu comme modele de protocole CE |
| PH-21.104 | NO_GO_CAPI_DELIVERY_FAILED, pas de fake event |
| PH-21.105 | READY_RCA_EVIDENCE_INSUFFICIENT, read-only, aucun retry/replay |
| PH-21.106 | READY_DEEP_RCA_OBSERVABILITY_PATCH_REQUIRED |
| PH-21.107 | Source patch API commit 547648fd |
| PH-21.108 | Build DEV image ID sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 |
| PH-21.109 | Push DEV digest sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb |
| PH-21.110 | Apply DEV manifest commit 05b7e71, runtime digest OK |
| PH-21.111 | Verify DEV docs commit fe0c65c, READY_WITH_LIMITS |
| PH-21.112 | Close DEV docs commit 350a183, READY_WITH_LIMITS |

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| Bastion | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite 51.159.99.247 | absente |
| Date UTC audit | 2026-06-24T13:35:15Z puis 2026-06-24T14:27:28Z |

## Etat des repos

| Repo | Branche | HEAD | Upstream | Ahead/behind | Dirty | Note |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | 350a183 | 350a183 | 0/0 | 0 | clean avant rapport PH-21.113 |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223 | dirty dist only, non-dist dirty 0 |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | d9631ca | 0/0 | 1 | hors scope, non touche |
| keybuzz-website | main | bd32fc8 | bd32fc8 | 0/0 | 0 | hors scope |
| keybuzz-admin-v2 | main | 3707c83 | 3707c83 | 0/0 | 0 | hors scope |
| keybuzz-backend | main | c38583a | c38583a | 0/0 | 1 | hors scope, non touche |

Conclusion source: le commit API source `547648fd` est aligne avec
`origin/ph147.4/source-of-truth`. Pour PH-21.114, le build PROD doit partir d'un clone ou
worktree propre depuis Git, pas du repo avec dist dirty.

## Readiness source API

| Controle | Resultat |
| --- | --- |
| API HEAD | 547648fd |
| API origin | 547648fd |
| Non-dist dirty | 0 |
| provider-error-normalizer.ts | present |
| meta-capi.ts | present |
| emitter.ts | present |
| normalizeMetaCapiProviderError | 19 occurrences |
| buildSafeMetaCapiDeliveryErrorMessage | 4 occurrences |
| META_MISSING_USER_DATA | 6 occurrences |
| UNKNOWN_SAFE_ERROR | 6 occurrences |
| outbound_conversion_delivery_logs | 19 occurrences |
| error_message | 16 occurrences |
| trial_page_viewed | 11 occurrences |
| StartTrial | 15 occurrences |
| Purchase | 37 occurrences |
| PROVIDER_CREDIT_EXHAUSTED | 20 occurrences |
| llm-provider-errors | 6 occurrences |
| Tests provider/meta-capi | 5 fichiers detectes |
| Tests trial_page_viewed/register_started | 1 fichier detecte |

StartTrial et Purchase restent presents dans la source. Le patch observability Meta CAPI
ne requiert pas de migration DB nouvelle pour PROD, car la colonne de persistence
`outbound_conversion_delivery_logs.error_message` existe deja en PROD.

## DEV consolidee

| Phase | Resultat |
| --- | --- |
| Source | API commit 547648fd |
| Build | Image ID sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 |
| Push | GHCR digest sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb |
| Apply DEV | Manifest commit 05b7e71 |
| Runtime DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` |
| Runtime digest DEV | sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb |
| Ready/restarts DEV | ready True, restarts 0 |
| Health DEV | status ok |
| Logs DEV strong secret count | 0 |
| Limite DEV | aucune nouvelle livraison failed naturelle prouvant la persistence live post-patch |

Verdict DEV conserve: READY_WITH_LIMITS. La limite n'est pas bloquante pour un build PROD
si la promotion est separee en build, push, apply, verify, close, et si aucun event n'est
rejoue.

## Baseline PROD read-only

### API PROD

| Controle | Resultat |
| --- | --- |
| Deployment generation | 424 |
| Observed generation | 424 |
| Ready replicas | 1/1 |
| Image spec | `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod` |
| Last-applied image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod` |
| Pod | keybuzz-api-6854bc98db-9mhjv |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad` |
| Ready | True |
| Restarts | 0 |
| Health | status ok |

### Client PROD

| Controle | Resultat |
| --- | --- |
| Deployment generation | 428 |
| Observed generation | 428 |
| Ready replicas | 1/1 |
| Image spec | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod` |
| Last-applied image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod` |
| Pod | keybuzz-client-748446795b-xqmr5 |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115` |
| Ready | True |
| Restarts | 0 |

## Logs PROD read-only

| Controle | Resultat |
| --- | --- |
| Fenetre logs API PROD | 2h, tail 2000 |
| Crash/panic/fatal/uncaught/unhandled | 0 |
| Strong secret pattern count | 0 |
| CAPI/meta count | 1 |
| CAPI storm count | 0 |
| LLM related count | 34 |

Le compteur LLM est hors scope de cette promotion Meta CAPI et n'indique pas de blocage
pour PH-21.114. Aucun secret brut ou PII n'a ete affiche.

## DB PROD read-only

Lecture effectuee en transaction READ ONLY depuis le pod API PROD. Aucune mutation.

| Table | Resultat |
| --- | --- |
| outbound_conversion_delivery_logs | existe, total 21 |
| outbound_conversion_delivery_logs.error_message | colonne presente |
| delivery logs failed | 6 |
| error_message non null | 6 |
| delivery id 99541c23fe41 | 0 ligne |
| funnel_events | existe, total 308 |
| conversion_events | existe, total 3 |
| ai_usage | existe, total 365 |

Conclusion DB: aucune migration PROD nouvelle n'est requise pour PH-21.114. La
persistence live d'une nouvelle erreur provider Meta CAPI reste non observee sans trafic
naturel ou incident reel. Ne pas rejouer `99541c23fe41` sans GO explicite.

## Registry safety

| Tag | Resultat |
| --- | --- |
| `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` | absent |
| `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev` | present |
| DEV manifest JSON sha256 | 77a6ad30d2dbe5a37ee585ffe0b1fad93fc9aab1f57ec928cfbadea5a74a9e88 |
| keybuzz-api:latest manifest JSON sha256 | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 |

Le tag PROD cible est libre. Il peut etre construit en PH-21.114 depuis Git. Aucun digest
PROD ne doit etre invente avant build/push.

## No fake metrics / no fake events

| Controle | Resultat |
| --- | --- |
| POST /funnel/event | 0 |
| Retry/replay | 0 |
| CAPI test event | 0 |
| Formulaire /register | 0 |
| Checkout Stripe | 0 |
| DB mutation volontaire | 0 |
| LLM call | 0 |
| Linear mutation | 0 |

## Plan PROD recommande

1. PH-21.114 BUILD API PROD depuis Git propre `547648fd`.
2. PH-21.115 PUSH IMAGE PROD du tag immutable, pull-back obligatoire.
3. PH-21.116 APPLY API PROD GITOPS, manifest API PROD uniquement, commit + push avant
   `kubectl apply -f`, rollout status, runtime equality.
4. PH-21.117 READONLY VERIFY PROD, sans POST, sans event fake, sans formulaire.
5. PH-21.118 READONLY CLOSE PROD.

## Rollback design

Rollback uniquement via GitOps strict si une phase apply PROD future echoue:

| Element | Valeur rollback |
| --- | --- |
| Image API PROD actuelle | `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod` |
| Digest API PROD actuel | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad |
| Methode | revert/commit/push manifest GitOps puis `kubectl apply -f` du manifest API PROD |

Interdit durable: pas de commande imperative de changement d'image ou d'environnement.

## Verdict

`GO READONLY DESIGN META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD PROMOTION SAFETY READY_FOR_BUILD_PROD PH-SAAS-T8.12AS.21.113`

Raison: DEV est consolidee, PROD baseline est stable, le tag PROD cible est absent, la DB
PROD a deja la colonne `error_message`, aucun event fake ou replay n'a ete produit, et la
promotion peut maintenant avancer vers un build PROD local separe.

## Prochain GO exact

`GO BUILD API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD PH-SAAS-T8.12AS.21.114`
