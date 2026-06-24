# PH-SAAS-T8.12AS.21.114 - BUILD API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD

Date UTC: 2026-06-24
Mode: BUILD API PROD local only
Verdict: READY_WITH_DEBTS

## Objectif

Construire localement, sans push ni deploy, l'image API PROD:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod`

depuis le commit source API valide en DEV:

`547648fd1fcb05d291157a5119cd35d141905cdf`

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY CURRENT_STATE | relu, 974 lignes |
| AI_MEMORY RULES_AND_RISKS | relu, 169 lignes |
| AI_MEMORY DOCUMENT_MAP | relu, 165 lignes |
| AI_MEMORY CE_PROMPTING_STANDARD | relu, 233 lignes |
| PH-T8.10J modele canonique local | relu |
| PH-21.104 -> PH-21.113 retours CE locaux | relus |
| PH-21.107 rapport infra | relu |
| PH-21.112 rapport infra | relu |
| PH-21.113 rapport infra | relu |

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| Hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite 51.159.99.247 | absente |
| Date UTC preflight | 2026-06-24T20:38:07Z |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223, non-dist 0 | ne pas nettoyer, build depuis source temporaire propre |
| keybuzz-infra | main | 16c94e3 | 16c94e3 | 0/0 | 0 | rapport docs-only autorise |

Dette conservee: le repo API courant garde des suppressions tracked `dist/` preexistantes.
Elles n'ont pas ete nettoyees ni revert. Le build Docker a ete fait depuis une deuxieme
source Git propre dediee.

## Source Git propre

| Usage | Path | HEAD | Dirty |
| --- | --- | --- | --- |
| Tests pre-build | `/tmp/ph21114-build-20260624T203907Z/keybuzz-api` | 547648fd | 0 avant npm ci, 1 apres npm ci dans node_modules uniquement |
| Build Docker | `/tmp/ph21114-docker-build-20260624T204703Z/keybuzz-api` | 547648fd | 0 |

La source Docker est separee de la source de test afin d'eviter de construire depuis une
copie modifiee par `npm ci`.

## Audit source API

| Marqueur | Resultat source |
| --- | --- |
| provider-error-normalizer | 3 |
| normalizeMetaCapiProviderError | 19 |
| buildSafeMetaCapiDeliveryErrorMessage | 4 |
| META_MISSING_USER_DATA | 6 |
| UNKNOWN_SAFE_ERROR | 6 |
| meta-capi | 4 |
| outbound_conversion_delivery_logs | 19 |
| error_message | 16 |
| trial_page_viewed | 11 |
| StartTrial | 15 |
| Purchase | 37 |
| PROVIDER_CREDIT_EXHAUSTED | 20 |
| llm-provider-errors | 6 |

Fichiers critiques presents:

- `src/modules/outbound-conversions/lib/provider-error-normalizer.ts`
- `src/modules/outbound-conversions/adapters/meta-capi.ts`
- `src/modules/outbound-conversions/emitter.ts`

## Tests pre-build

| Test | Attendu | Resultat | Preuve courte |
| --- | --- | --- | --- |
| git diff --check | PASS | PASS | rc 0 |
| PH21.107 | PASS | PASS | `PH21.107 Meta CAPI error observability tests PASS` |
| PH21.79 | PASS | PASS | `PH21.79 trial_page_viewed Meta tests PASS` |
| tsc --noEmit | PASS | PASS | rc 0 |

Notes:

- le repo n'a pas de runner test dedie dans `package.json`;
- les tests TypeScript ont ete compiles dans `/tmp/ph21114-test-dist` et executes par Node;
- `NODE_PATH` a ete pointe vers les dependances de la copie de test;
- aucun event reel, aucun POST et aucun CAPI test n'ont ete emis.

## Registry safety avant build

| Image/tag | Etat attendu | Resultat |
| --- | --- | --- |
| `v3.5.265-meta-capi-error-observability-prod` distant | absent | absent |
| `keybuzz-api:latest` | hash note, intact | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |
| tag local cible avant build | absent | absent |

## Build local API PROD

| Champ | Valeur |
| --- | --- |
| Source path build propre | `/tmp/ph21114-docker-build-20260624T204703Z/keybuzz-api` |
| Source commit | `547648fd1fcb05d291157a5119cd35d141905cdf` |
| Image locale | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Image ID / config digest | `sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9` |
| RepoDigest | absent, attendu avant push |
| OCI revision | `547648fd1fcb05d291157a5119cd35d141905cdf` |
| OCI version | `v3.5.265-meta-capi-error-observability-prod` |
| Docker push | 0 |

Note environnement: une premiere tentative avec BuildKit a stoppe avant build car le
composant buildx est absent. Le build final PASS a ete realise avec le builder Docker
classique `DOCKER_BUILDKIT=0`, sans push ni latest.

## Audit image

| Audit image | Attendu | Resultat |
| --- | --- | --- |
| provider-error-normalizer runtime file | present | present |
| meta-capi adapter runtime file | present | present |
| emitter/persistence runtime file | present | present |
| llm-provider-errors runtime file | present | present |
| normalizeMetaCapiProviderError | present | 4 |
| buildSafeMetaCapiDeliveryErrorMessage | present | 3 |
| META_MISSING_USER_DATA | present | 1 |
| UNKNOWN_SAFE_ERROR | present | 3 |
| outbound_conversion_delivery_logs | present | 19 |
| error_message | present | 16 |
| trial_page_viewed | present | 7 |
| StartTrial | present | 9 |
| Purchase | present | 31 |
| PROVIDER_CREDIT_EXHAUSTED | present | 13 |
| llm-provider-errors | present | 4 |
| dist/tests | absent | 0 |
| artefacts tests PH21.107/PH21.79 | absent | 0 |
| secret/PII exposure logs build | 0 | 0 |

## Registry safety apres build

| Controle registry | Attendu | Resultat |
| --- | --- | --- |
| tag PROD cible distant | absent | absent |
| latest | inchange | inchange |
| latest hash apres build | meme hash | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |
| docker push effectue | 0 | 0 |

## Runtime read-only non-regression

| Service | Image | Digest runtime | Ready | Restarts | Mutation |
| --- | --- | --- | --- | --- | --- |
| API PROD | `v3.5.264-onboarding-trial-page-viewed-meta-prod` | `sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad` | 1/1 | 0 | non |
| API DEV | `v3.5.265-meta-capi-error-observability-dev` | `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | 1/1 | 0 | non |
| Client PROD | `v3.5.260-onboarding-register-started-owner-payload-prod` | `sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115` | 1/1 | 0 | non |
| Client DEV | `v3.5.260-onboarding-register-started-owner-payload-dev` | `sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9` | 1/1 | 0 | non |
| Website PROD | `v0.7.2-visual-hero-parity-prod` | `sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4` | 2/2 | 0 | non |
| Website DEV | `v0.7.1-hero-copy-prod-body-parity-dev` | `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | 1/1 | 0 | non |
| Admin DEV | `v2.12.2-media-buyer-lp-domain-qa-dev` | `sha256:c747ee93d25a81e43f44e04d2c845b51a3eab0ede51f050df1375e6009abaa09` | 1/1 | 0 | non |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | `sha256:ecc2080ff7fe5031eab812b1c32d330e4f7eea902d2a98e4d7bd7b409e0d5037` | 1/1 | 0 | non |
| Backend DEV | `v1.0.57-amazon-notification-classification-dev` | `sha256:ab583b9c57bb47bddb35be594ffb8938bf7bd57d6f79b6f8906c341083c5d806` | 1/1 | 0 | non |
| Backend PROD | `v1.0.56-amazon-inbound-dedup-prod` | `sha256:9689875ca55677d80ef122a2bbd6209fd5071da2fac51f15cd182f8d7f1dcdd2` | 1/1 | 0 | non |

## AI feature parity / anti-regression

| Surface IA | Attendu | Resultat |
| --- | --- | --- |
| PROVIDER_CREDIT_EXHAUSTED | present dans image | present, 13 occurrences |
| llm-provider-errors | present dans image | present, 4 occurrences |
| dist/tests | absent | 0 |
| appel LLM | 0 | 0 |
| DB ai_usage/ledger mutation volontaire | 0 | 0 |

## No fake metrics / no fake events

| Controle | Attendu | Resultat |
| --- | --- | --- |
| POST /funnel/event CE | 0 | 0 |
| retry/replay CAPI | 0 | 0 |
| CAPI test endpoint | 0 | 0 |
| DB mutation volontaire | 0 | 0 |
| StartTrial/Purchase/CompletePayment pollues | 0 | 0 |
| formulaire /register | 0 | 0 |
| checkout Stripe | 0 | 0 |

## Dettes / limites

- Dette preexistante non bloquante: repo API courant dirty `dist/` tracked deletions,
  non touche, build fait depuis source propre separee.
- Dette environnement non bloquante: BuildKit active mais buildx absent; builder Docker
  classique utilise avec succes.
- Limite produit conservee: aucune nouvelle erreur provider Meta CAPI live n'a ete
  observee ni rejouee dans cette phase.
- Ne pas rejouer `99541c23fe41` sans GO explicite.

## Verdict

`GO BUILD API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD READY_WITH_DEBTS PH-SAAS-T8.12AS.21.114`

## Prochain GO exact

`GO PUSH IMAGE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD PH-SAAS-T8.12AS.21.115`
