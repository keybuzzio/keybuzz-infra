# PH-SAAS-T8.12AS.21.85 - Readonly design onboarding trial_page_viewed Meta tracking PROD promotion safety

Date UTC: 2026-06-22T10:26:34Z

Verdict: READY_FOR_SOURCE_PATCH

Phrase finale:

`GO READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED META TRACKING PROD PROMOTION SAFETY READY_FOR_SOURCE_PATCH PH-SAAS-T8.12AS.21.85`

## Scope

Mode execute: READONLY DESIGN.

Aucune action de mutation runtime ou source applicative n'a ete effectuee. Aucun patch source/config applicatif, aucun build, aucun docker push, aucun deploy, aucun kubectl apply, aucune mutation DB, aucun POST /funnel/event, aucun formulaire /register, aucun checkout Stripe, aucun test CAPI, aucun fake event, aucun Webflow, aucun Linear.

Un rapport docs-only a ete produit dans keybuzz-infra, conformement a la mission.

## Sources relues

- C:\DEV\KeyBuzz\tmp\PH-21.85_CE_MISSION.md
- AI_MEMORY: CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP, CE_PROMPTING_STANDARD
- Modele prompt KeyBuzz PH-T8.10J
- Retours PH-21.78 a PH-21.84
- SERVER_SIDE_TRACKING_CONTEXT.md
- MEDIA_BUYER_LP_TRACKING_CONTRACT.md
- PH-WEBSITE-T8.12AQ.4-MEDIA-BUYER-LP-AUTONOMY-TRACKING-CONTRACT-01.md
- Repos bastion API, Client, Infra, Website, Admin, Backend en lecture seule
- Runtime Kubernetes DEV/PROD en lecture seule
- DB PROD via transaction read-only et ROLLBACK, sans secret ni PII affiche

## Preflight bastion

| Point | Observe | Verdict |
| --- | --- | --- |
| Hostname | install-v3 | OK |
| IPv4 publique | 46.62.171.61 | OK |
| Date UTC | 2026-06-22T10:26:34Z | OK |
| Kube context | kubernetes-admin@kubernetes | READONLY |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4 | https://github.com/keybuzzio/keybuzz-api.git | 0/0 | 223 | DIRTY_DOCUMENTED |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862a2e63 | https://github.com/keybuzzio/keybuzz-client.git | 0/0 | 1 | DIRTY_DOCUMENTED |
| keybuzz-infra | main | d6915785b34f | https://github.com/keybuzzio/keybuzz-infra.git | 0/0 | 0 | OK |
| keybuzz-website | main | bd32fc8bc9d9 | https://github.com/keybuzzio/keybuzz-website.git | 0/0 | 0 | OK |
| keybuzz-admin-v2 | main | 3707c834d7bf | https://github.com/keybuzzio/keybuzz-admin-v2.git | 0/0 | 0 | OK |
| keybuzz-backend | main | c38583a8548e | https://github.com/keybuzzio/keybuzz-backend.git | 0/0 | 1 | DIRTY_DOCUMENTED |

## Chaine DEV close PH-21.79 a PH-21.84

| Phase | Verdict | Preuve cle | Limite |
| --- | --- | --- | --- |
| PH-21.79 | DONE | API commit 35673e3b, event Meta custom trial_page_viewed derive de register_started | pas de trafic naturel |
| PH-21.80 | DONE | image locale DEV v3.5.264 construite depuis Git | aucun push dans cette phase |
| PH-21.81 | DONE | image DEV poussee, digest sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | aucun deploy dans cette phase |
| PH-21.82 | DONE | API DEV runtime v3.5.264, ready 1/1, restarts 0 | pas de owner env ajoutee |
| PH-21.83 | READY_WITH_LIMITS | verification read-only OK, DB deltas 0 | NO_NATURAL_TRAFFIC |
| PH-21.84 | READY_WITH_LIMITS | close DEV OK | owner routing/config a trancher avant PROD |

Conclusion DEV: techniquement clos pour le code API v3.5.264, mais sans trafic naturel trial_page_viewed et avec owner routing a garantir avant promotion PROD.

## Runtime baseline

| Surface | Image observee | Verdict |
| --- | --- | --- |
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | reference DEV PH-21.84 |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod | baseline PROD pre-promotion |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | baseline Client |

## Audit source API

Fichier audit interne: /tmp/ph2185/api_audit.json sur bastion, sans secret.

| Brique API | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| trial_page_viewed custom event | present | occurrences source: 8 | OK |
| Source emission | premier register_started | helper emitTrialPageViewedMetaFromRegisterStarted present | OK |
| Duplicate guard | pas d'emission sur duplicate | logique dedupe/skip inspectee en source PH-21.79 | OK |
| Owner from properties | supporte | marketing_owner_tenant_id via properties | OK |
| Owner from env | supporte optionnel | TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID | OK |
| Skip safe | supporte | absence owner => pas d'emission non routee | OK |
| conversion_events pollution | aucune | detection trial_page_viewed proche conversion_events | OK |
| StartTrial | intact | marqueur StartTrial present | OK |
| Purchase | intact | marqueur Purchase present | OK |
| Token redaction/encryption | compatible | metadata token non affichee, PH-21.15 conserve | OK |

Conclusion API: le patch API est structurellement sain, mais depend d'une source owner explicite dans register_started ou d'une decision config env globale.

## Audit Client /register owner payload

Fichier audit interne: /tmp/ph2185/client_audit.json sur bastion.

| Point Client | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Query marketing_owner_tenant_id capturee | oui | presence du param dans le code Client | OK |
| Transmise a create-signup | oui | create-signup voit marketing_owner_tenant_id | OK |
| Transmise a register_started properties | oui pour Option A | tranche register_started sans marketing_owner_tenant_id | KO |
| UTM transmis a funnel event | oui | tranche register_started UTM | KO |
| click IDs preserves | oui | tranche register_started click IDs | KO |
| Protected pages no ads tracking | preserve | pas de marqueur fbq/gtag/ttq global detecte dans sources inspectees | OK |

Conclusion Client: le code capture l'owner pour l'inscription produit, mais ne prouve pas sa presence dans les properties de register_started. Dans cet etat, l'API PROD v3.5.264 risquerait un skip-safe pour trial_page_viewed KBC si aucune env globale n'est posee. Une promotion API directe ne garantit donc pas le routage owner KBC.

## Audit URL contract Antoine / Webflow

| Contrat URL | Attendu | Statut |
| --- | --- | --- |
| plan | present | requis dans le contrat |
| cycle | present | requis dans le contrat |
| utm_source | present | requis dans le contrat |
| utm_medium | present | requis dans le contrat |
| utm_campaign | present | requis dans le contrat |
| utm_content | recommande | recommande pour creative/ad |
| marketing_owner_tenant_id | present pour owner routing | requis pour KBC |
| fbclid forwarding | via script plateforme/LP | requis |
| fake conversion LP | interdit | confirme |

URL canonique a donner a Antoine, sans la charger ni la declencher:

`https://client.keybuzz.io/register?plan=autopilot&cycle=monthly&utm_source=meta&utm_medium=cpc&utm_campaign=<CAMPAIGN>&utm_content=<CREATIVE>&marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk`

Conclusion URL: le pixel Meta seul est insuffisant. Le contrat URL doit porter marketing_owner_tenant_id et les UTM/click IDs. Mais le contrat URL ne suffit pas tant que le Client ne propage pas l'owner dans register_started properties.

## Audit destination Meta CAPI PROD owner KBC

Audit DB PROD effectue en read-only avec ROLLBACK. Aucune valeur de token, Secret.data ou PII n'a ete lue ou affichee.

| Point PROD KBC | Attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Owner tenant existe | oui | voir metadata DB read-only | OK si present dans JSON audit |
| Meta CAPI destination active | oui | activeMetaDestinationCount=1 | OK |
| Token non null | oui | tokenPresentCount=2 | OK |
| Token chiffre/masque | oui | metadata uniquement, valeur jamais affichee | OK |
| Destination deleted_at | null | filtre not_deleted dans audit | OK si count actif > 0 |
| Delivery logs leaks token | 0 | 0 | OK |
| trial_page_viewed delivery logs | 0 attendu avant promotion | 0 | OK |

Conclusion destination: KBC Meta CAPI destination = OK. La destination n'est pas le blocage principal si OK; le blocage est le payload owner register_started.

## Options de promotion PROD

### Option A - URL/property-driven owner routing

| Critere | Verdict |
| --- | --- |
| Multi-tenant safe | OK |
| Depend du contrat URL | OUI |
| Depend du Client payload register_started | OUI |
| Risque skip-safe | ELEVE tant que register_started properties owner = KO |
| Risque attribution organique polluee | faible sans env globale |
| Recommandation | pas encore executable en build PROD direct |

### Option B - Env globale PROD TRIAL_PAGE_VIEWED_META_OWNER_TENANT_ID

| Critere | Verdict |
| --- | --- |
| Simplicite | OK |
| Risque multi-tenant | ELEVE si tout trafic sans owner part vers KBC |
| Risque organique routed to KBC | ELEVE |
| Besoin decision produit | OUI |
| Besoin GitOps config patch | OUI |
| Recommandation | non recommandee par defaut |

### Option C - Source patch Client/API avant PROD

| Critere | Verdict |
| --- | --- |
| Robustesse | OK |
| Scope | Client register_started properties, API probablement intacte |
| Risque | limite si patch source minimal + tests offline |
| Besoin DEV revalidation | OUI |
| Recommandation | RECOMMANDEE |

### Option D - Action media buyer URL only

| Critere | Verdict |
| --- | --- |
| Suffisant si Client properties OK | oui |
| Insuffisant si Client properties KO | oui, insuffisant aujourd'hui |
| Besoin QA URL | oui |
| Recommandation | necessaire mais pas suffisante |

Option recommandee: Option C. Patch source Client pour inclure marketing_owner_tenant_id, UTM et click IDs utiles dans les properties de register_started, puis DEV build/push/apply/verify, puis promotion PROD.

## Plan de promotion propose

Prochain GO recommande:

`GO SOURCE PATCH CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV PH-SAAS-T8.12AS.21.86`

Sequence ensuite, sans execution dans PH-21.85:

1. Source patch Client DEV pour register_started owner payload.
2. Tests offline/mock, sans POST reel.
3. Build/push/apply/verify DEV Client selon protocole KeyBuzz.
4. Revalider API DEV v3.5.264 avec payload owner naturellement produit par Client DEV, sans fake event CE.
5. Promotion PROD separee API/Client selon GO explicites.
6. Vrai test trafic uniquement avec URL Antoine conforme et validation humaine.

## Non-regression et risques

| Surface | Risque | Mitigation |
| --- | --- | --- |
| StartTrial | confusion avec page view | maintenir Stripe-only |
| Purchase | fake payment | interdit |
| conversion_events | pollution micro-event | rester 0 trial_page_viewed |
| Meta token | fuite | redaction/encryption, aucune valeur affichee |
| Multi-tenant | owner hardcode | URL/property-driven |
| Organic signup | routed to KBC a tort | eviter env globale sans decision |
| Webflow | CTA nu | URL contract obligatoire |
| Ads Manager | absence preuve read-only | vrai trafic uniquement |

## No fake metrics / no fake events

| Signal | Statut |
| --- | --- |
| POST /funnel/event | 0 |
| Formulaire /register | 0 |
| Checkout Stripe | 0 |
| CAPI test | 0 |
| Fake event tracking | 0 |
| DB mutation | 0 |
| Build/deploy | 0 |

## Verdict final

Verdict: READY_FOR_SOURCE_PATCH

Raison: la destination KBC Meta CAPI est OK, le contrat URL Antoine/Webflow est clair, mais le Client ne prouve pas la transmission de marketing_owner_tenant_id dans register_started properties. Une promotion API PROD directe ne garantit donc pas l'emission Meta CAPI KBC et peut produire un skip-safe silencieux.

Prochain GO:

`GO SOURCE PATCH CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV PH-SAAS-T8.12AS.21.86`
