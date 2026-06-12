# PH-SAAS-T8.12AS.21.56 - READONLY VERIFY WEBSITE TO STRIPE PRECHECKOUT TRACKING PROD

## 1. Verdict

Verdict final:

`GO READONLY VERIFY WEBSITE TO STRIPE PRECHECKOUT TRACKING PROD EXPECTED_ABSENT_STARTTRIAL PH-SAAS-T8.12AS.21.56`

Le parcours de Ludovic du 2026-06-11 soir a bien ete observe dans les traces internes PROD sur la fenetre cible.

Conclusion courte:

- Parcours observe entre 2026-06-11T19:28:36Z et 2026-06-11T19:29:35Z.
- Funnel pre-checkout observe: register_started, email_submitted, otp_verified, company_completed, user_completed, tenant_created.
- Tenant cree en `pending_payment`, tenant masque dans les logs et reference ici uniquement par hash safe `1f377a794d`.
- Session checkout Stripe creee cote Client/BFF: log `billing/checkout-session` puis `Success: url=YES`.
- Aucun paiement/trial finalise: 0 `checkout.session.completed`, 0 `customer.subscription.created`, 0 `billing_subscriptions`.
- Donc 0 `StartTrial` est normal et attendu.
- Sans lien Meta, pas d'attribution campaign attendue; `_fbp` present indique seulement un cookie/browser id, pas un click campaign.

## 2. Objectif

Verifier en lecture seule si le parcours direct de Ludovic depuis `www.keybuzz.pro` vers Stripe, sans paiement finalise, laisse des traces coherentes dans KeyBuzz PROD.

Fenetre cible imposee:

| Timezone | Debut | Fin |
| --- | --- | --- |
| Europe/Paris | 2026-06-11 21:00 | 2026-06-11 22:15 |
| UTC | 2026-06-11 19:00 | 2026-06-11 20:15 |

Fenetre elargie observee: 2026-06-11 18:00 -> 21:00 UTC.

## 3. Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.56_CE_MISSION.md` | Lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.55_CE_RETURN.md` | Lu |
| `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.55-READONLY-RCA-SERVER-SIDE-TRACKING-STARTTRIAL-DEV-PROD-01.md` | Present cote bastion |
| `AI_MEMORY/CURRENT_STATE.md` | Lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | Lu cible |
| `AI_MEMORY/DOCUMENT_MAP.md` | Lu cible |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | Lu cible |
| Modele `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | Relu cible |
| Sorties bastion `/tmp/ph2156_20260612T120836Z/*` | Relues |

## 4. Preflight runtime/repos

| Controle | Resultat |
| --- | --- |
| Bastion | `install-v3` |
| IPv4 obligatoire | `46.62.171.61` presente |
| IP interdite | Non utilisee |
| Date audit UTC | `2026-06-12T12:08:36Z` |
| Kube context | `kubernetes-admin@kubernetes` |
| Mode | Read-only verify |

| Repo/service | Branche/image attendue | Observe | Dirty/ready | Verdict |
| --- | --- | --- | --- | --- |
| `keybuzz-infra` | `main` | HEAD/origin `aa894ac0`, ahead/behind `0/0` | dirty `0` au preflight | OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | HEAD/origin `76483e3a`, ahead/behind `0/0` | dirty preexistant `223` | Read-only, pas touche |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | HEAD/origin `ad4e862a`, ahead/behind `0/0` | dirty preexistant `1` | Read-only, pas touche |
| `keybuzz-website` | attendu docs `main` | observe `redesign/light-business`, HEAD/origin `020794b8` | dirty `0` | Runtime PROD audite |
| `keybuzz-backend` | `main` | HEAD/origin `c38583a8`, ahead/behind `0/0` | dirty preexistant `1` | Read-only, pas touche |
| API PROD | `v3.5.262-llm-provider-credit-alerting-prod` | digest `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6` | ready 1/1, restarts 0 | OK |
| Client PROD | `v3.5.259-ai-assist-notification-scope-prod` | digest `sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791` | ready 1/1, restarts 0 | OK |
| Website PROD | `v0.6.22-clarity-restore-prod` | digest `sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac` | ready 2/2, restarts 0 | OK |
| Backend PROD | `v1.0.56-amazon-inbound-dedup-prod` | digest `sha256:9689875ca55677d80ef122a2bbd6209fd5071da2fac51f15cd182f8d7f1dcdd2` | ready 1/1, restarts 0 | OK |

Dette SRE preexistante observee, hors scope: `amazon-orders-worker` PROD restarts 10 et `backfill-scheduler` Pending.

## 5. Hypothese PH-21.55 + parcours Ludovic

PH-21.55 a etabli que `StartTrial` CAPI server-side n'est pas un micro-event de signup: il depend d'un vrai checkout/subscription Stripe finalise.

| Fait | Impact attendu |
| --- | --- |
| StartTrial historique PROD existe et a deja ete livre aux destinations CAPI | Chemin server-side non prouve casse |
| Aucun vrai checkout/trial recent observe en PH-21.55 | Absence recente de StartTrial classable `TRAFFIC_REQUIRED` |
| Ludovic a fait un parcours direct vers Stripe sans paiement finalise | Attendre signup/funnel/checkout session, mais pas StartTrial |
| Pas de lien Meta dans le parcours | Pas d'attribution campaign Meta attendue; event non attribue ou absent si non envoye |
| Arret sur page Stripe | `checkout_started` / session possible; `checkout_completed` attendu absent |

## 6. Logs Website/Client/API

Source: `kubectl logs` read-only sur pods PROD, fenetre cible 19:00 -> 20:15 UTC et fenetre elargie 18:00 -> 21:00 UTC. Les exemples ci-dessous sont volontairement masques: pas d'email brut, pas d'URL complete, pas de tenant brut.

| Service | Fenetre UTC | Marker | Count | Exemple safe | Verdict |
| --- | --- | --- | ---: | --- | --- |
| Website PROD | cible | checkout / signup / StartTrial / conversion | 0 | Aucun marker utile | Pas bloquant: le parcours bascule ensuite Client/register |
| Website PROD | cible | erreurs | 1 sample Server Action `x` | Erreur Server Action isolee | Sans lien prouve avec le parcours |
| Client PROD | cible | signup | 1 | `[Create-Signup] Proxying to https://[url] for [email]` | OBSERVED |
| Client PROD | cible | checkout / checkout.session | 2 / 2 | `[billing/checkout-session] tenantId=[masked] plan=PRO cycle=monthly successUrl=https://[url] promo=none` | OBSERVED |
| Client PROD | cible | checkout session result | 1 | `[billing/checkout-session] Success: url=YES` | OBSERVED session URL creee |
| Client PROD | cible | StartTrial | 0 | Aucun marker | EXPECTED_ABSENT |
| Client PROD | cible | 500 | 1 | `[tenant-context/me] Backend error: 500 {"error":"Failed to get user"}` | Non fatal: signup et checkout suivent |
| API PROD | cible | checkout / signup / StartTrial / conversion | 0 | Aucun marker | Route visible surtout cote Client/BFF dans les logs |
| Backend PROD | cible | checkout / signup / StartTrial / conversion | 0 | Aucun marker utile | Non implique dans ce parcours |
| Backend PROD | cible | erreurs 4xx/5xx generiques | 400=146, 401=2, 403=3, 404=4, 500=3, 502=4, 503=5 | Pas d'exemple relie au parcours | Bruit runtime hors parcours |

Lecture importante: le log Client prouve la creation d'une URL de checkout Stripe, mais aucun log ne montre un checkout finalise ni un webhook Stripe de completion.

## 7. DB read-only

Transactions DB executees en read-only avec `BEGIN TRANSACTION READ ONLY` puis `ROLLBACK`.

| Table/signal | Count fenetre cible | Count fenetre elargie | Derniere trace safe | Verdict |
| --- | ---: | ---: | --- | --- |
| `funnel_events.register_started` | 1 | 1 | 2026-06-11T19:28:36.790Z, funnel_hash `939c809b9d` | OBSERVED |
| `funnel_events.email_submitted` | 1 | 1 | 2026-06-11T19:28:51.044Z, funnel_hash `939c809b9d` | OBSERVED |
| `funnel_events.otp_verified` | 1 | 1 | 2026-06-11T19:29:10.622Z, funnel_hash `939c809b9d` | OBSERVED |
| `funnel_events.company_completed` | 1 | 1 | 2026-06-11T19:29:21.757Z, funnel_hash `939c809b9d` | OBSERVED |
| `funnel_events.user_completed` | 1 | 1 | 2026-06-11T19:29:29.319Z, funnel_hash `939c809b9d` | OBSERVED |
| `funnel_events.tenant_created` | 1 | 1 | 2026-06-11T19:29:32.449Z, tenant_hash `1f377a794d` | OBSERVED |
| `signup_attribution` | 1 | 1 | plan `pro`, cycle `monthly`, tenant_hash `1f377a794d` | OBSERVED |
| `signup_attribution.stripe_session_present` | 0 | 0 | `false` | Gap de persistance, pas preuve d'absence de session car log Client dit `url=YES` |
| `tenants` | 1 | 1 | status `pending_payment`, plan `PRO`, selected_plan `PRO` | OBSERVED |
| `billing_customers` | 1 | 1 | count only, no PII | OBSERVED |
| `billing_subscriptions` | 0 | 0 | Aucun | EXPECTED_ABSENT si paiement non finalise |
| `tenant_billing_exempt` | 0 | 0 | Aucun | OK |
| `billing_events.checkout.session.completed` | 0 | 0 | Aucun | EXPECTED_ABSENT |
| `billing_events.customer.subscription.created` | 0 | 0 | Aucun | EXPECTED_ABSENT |
| `billing_events.customer.subscription.updated` | 0 | 0 | Aucun | EXPECTED_ABSENT |
| `conversion_events` | 0 | 0 | Aucun StartTrial/Purchase | EXPECTED_ABSENT |
| `outbound_conversion_delivery_logs` | 0 | 0 | Aucun CAPI delivery | EXPECTED_ABSENT |

Timeline safe:

| UTC | Event | Source | Plan | Tenant |
| --- | --- | --- | --- | --- |
| 2026-06-11T19:28:36.790Z | `register_started` | client | pro/monthly | pre-tenant |
| 2026-06-11T19:28:51.044Z | `email_submitted` | api | pro/monthly | pre-tenant |
| 2026-06-11T19:29:10.622Z | `otp_verified` | client | pro/monthly | pre-tenant |
| 2026-06-11T19:29:21.757Z | `company_completed` | client | pro/monthly | pre-tenant |
| 2026-06-11T19:29:29.319Z | `user_completed` | client | pro/monthly | pre-tenant |
| 2026-06-11T19:29:32.449Z | `tenant_created` | api | pro/monthly | tenant_hash `1f377a794d` |
| 2026-06-11T19:29:34.196Z | `billing/checkout-session` log | client | PRO/monthly | tenant masque |
| 2026-06-11T19:29:35.266Z | checkout session result `url=YES` | client | PRO/monthly | tenant masque |

## 8. Stripe/checkout interne

Aucun appel Stripe API externe n'a ete effectue. Verification limitee aux traces internes DB/logs.

| Signal Stripe interne | Observe | Impact StartTrial |
| --- | --- | --- |
| Checkout route appelee | Oui, log Client `billing/checkout-session` a 19:29:34Z | Pre-checkout atteint |
| Checkout session URL retournee | Oui, log Client `Success: url=YES` a 19:29:35Z | Stripe page probablement atteinte |
| `signup_attribution.stripe_session_id` persiste | Non | Dette observabilite precheckout/abandon, pas preuve d'absence de session |
| `billing_customers` cree | Oui, count 1 dans fenetre | Coherent avec preparation checkout |
| `checkout.session.completed` | Non | StartTrial ne doit pas etre emis |
| `customer.subscription.created` | Non | StartTrial ne doit pas etre emis |
| `billing_subscriptions` | Non | StartTrial ne doit pas etre emis |
| `conversion_events.StartTrial` | Non | EXPECTED_ABSENT |
| Delivery CAPI StartTrial | Non | EXPECTED_ABSENT |

Conclusion Stripe interne: le niveau d'arret observe est `checkout session / Stripe page`, pas `checkout completed`.

## 9. Funnel/browser tracking haut de funnel

| Event haut de funnel | Observe fenetre | Source | Verdict |
| --- | --- | --- | --- |
| `page_view` interne | Non observe dans les tables candidates | Source interne non disponible | UNKNOWN / dashboard externe si preuve pageview exacte requise |
| Landing URL | Presente | `signup_attribution.has_landing_url=true` | OBSERVED |
| `register_started` | 1 | `funnel_events` | OBSERVED |
| `email_submitted` | 1 | `funnel_events` | OBSERVED |
| `otp_verified` | 1 | `funnel_events` | OBSERVED |
| `company_completed` | 1 | `funnel_events` | OBSERVED |
| `user_completed` | 1 | `funnel_events` | OBSERVED |
| `tenant_created` | 1 | `funnel_events` + `tenants` | OBSERVED |
| `signup_complete` | 0 marker log | Pas le nom canonique stocke ici | Remplace fonctionnellement par `tenant_created` |
| `checkout_started` | Oui via log `billing/checkout-session` | Client PROD logs | OBSERVED |
| `checkout_session_created` | Oui via `Success: url=YES` | Client PROD logs | OBSERVED |
| `checkout_completed` | 0 | `billing_events` / subscriptions | EXPECTED_ABSENT |
| `StartTrial` | 0 | `conversion_events` / delivery logs | EXPECTED_ABSENT |

Le signal haut de funnel cle n'est pas absent: les micro-steps register -> tenant_created sont presents et cousus par le meme `funnel_hash`.

## 10. Attribution Meta/direct

| Attribution signal | Present | Impact |
| --- | --- | --- |
| `fbclid` | Non | Pas de preuve de click Meta campaign |
| `_fbc` | Non | Pas de preuve de click Meta campaign |
| `_fbp` | Oui | Browser cookie/pixel id possible; ne suffit pas a attribuer a une campagne |
| `gclid` | Non | Pas de click Google Ads |
| `ttclid` | Non | Pas de click TikTok |
| `li_fat_id` | Non | Pas de click LinkedIn |
| UTM source | Non | Pas de source campaign interne |
| Referrer | Non | Direct/none probable cote traces internes |
| Landing URL | Oui | Le parcours a conserve une landing URL |
| marketing owner tenant | Non | Pas de routing owner observe sur ce tenant pending_payment |

Conclusion attribution:

- Sans lien Meta, Antoine peut normalement ne pas voir d'attribution campaign dans Ads Manager.
- Un event CAPI pourrait etre visible dans Events Manager s'il etait envoye, mais il ne doit pas etre envoye sans checkout finalise.
- Dans ce cas, l'absence de StartTrial Meta est coherente avec l'absence de paiement/trial finalise.

## 11. Conclusion temporelle

| Question | Reponse | Preuve |
| --- | --- | --- |
| Le parcours de Ludovic est-il observe ? | Oui | Sequence unique 19:28:36Z -> 19:29:35Z dans DB/logs |
| A quel niveau s'arrete-t-il ? | Checkout session / Stripe page | Client log `Success: url=YES`, tenant status `pending_payment` |
| Quel event pre-checkout existe ? | Register/signup/funnel + checkout session | `funnel_events` et Client logs |
| Quel event ne devait pas etre emis ? | `StartTrial` | Aucun checkout completed ni subscription created |
| Est-ce normal qu'Antoine ne voie pas StartTrial ? | Oui | `conversion_events=0`, delivery logs=0, paiement non finalise |
| Est-ce un bug CAPI StartTrial ? | Non prouve | PH-21.55 prouve historique StartTrial delivered; ici pas de trigger metier |
| Y a-t-il un bug haut de funnel distinct ? | Pas de bug bloquant observe | Micro-steps presents; dette: session id non persistee dans `signup_attribution` |

## 12. No fake metrics / no fake events

Classification des signaux:

| Signal | Classe | Justification |
| --- | --- | --- |
| register_started -> tenant_created | OBSERVED | DB `funnel_events` |
| checkout route appelee | OBSERVED | Client logs PROD |
| checkout session URL creee | OBSERVED | Client log `Success: url=YES` |
| checkout_completed | EXPECTED_ABSENT | Aucun paiement finalise |
| StartTrial | EXPECTED_ABSENT | Aucun checkout/subscription finalise |
| CAPI delivery StartTrial | EXPECTED_ABSENT | Pas de StartTrial a livrer |
| Pageview exacte dashboard | EXTERNAL_DASHBOARD_REQUIRED si demandee | Pas de table pageview interne identifiee |
| Meta campaign attribution | EXPECTED_ABSENT / limitee | Pas de fbclid/fbc/UTM/referrer; `_fbp` seulement |

Aucun KPI n'a ete invente. Aucun faux event n'a ete cree.

## 13. Non-regression / side-effect

| Interdit | Resultat |
| --- | --- |
| POST | Non execute |
| Event test / fake signup / fake trial / fake checkout / fake purchase | Non execute |
| Endpoint test CAPI | Non appele |
| Stripe API externe | Non appelee |
| DB mutation | Non |
| Build / docker push / deploy / kubectl apply | Non |
| Secret/token affiche | Non |
| Email brut / PII brute dans rapport | Non |
| Secret Kubernetes decode | Non |
| Linear | Non |
| PROD runtime mutation | Non |
| DB deltas read-only | 0: counts before/after identiques sur tables auditees |

Counts DB read-only before/after identiques:

| Table | Before | After |
| --- | ---: | ---: |
| `funnel_events` | 243 | 243 |
| `signup_attribution` | 18 | 18 |
| `billing_events` | 189 | 189 |
| `tenants` | 20 | 20 |
| `conversion_events` | 3 | 3 |
| `outbound_conversion_delivery_logs` | 19 | 19 |

## 14. Dettes

| Dette | Statut | Impact |
| --- | --- | --- |
| Persistance `stripe_session_id` dans `signup_attribution` absente pour ce parcours | Ouverte | Rend l'analyse abandon checkout dependante des logs Client; pas un bug StartTrial |
| Persistance canonique `checkout_started`/`checkout_session_created` en DB | A designer si besoin produit | Meilleure observabilite precheckout/abandoned checkout |
| Pageview website exacte | Dashboard externe requis si besoin | Les traces internes prouvent le signup, pas la pageview brute |
| Preuve dashboard Meta/GA4/Stripe | Hors scope | Necessite acces dashboard externe, sans fake event |
| Dette GA4 Client runtime PH-21.55 | Ouverte | Separee de StartTrial CAPI |
| Dette SRE worker/backfill | Ouverte | Hors tracking |

## 15. Prochain GO recommande

Si Ludovic veut cloturer cette RCA:

`GO READONLY CLOSE WEBSITE TO STRIPE PRECHECKOUT TRACKING RCA PH-SAAS-T8.12AS.21.57`

Si Ludovic veut traiter la dette d'observabilite abandon checkout:

`GO READONLY DESIGN PRECHECKOUT CHECKOUT_SESSION OBSERVABILITY DEV PROD PH-SAAS-T8.12AS.21.57B`

## LINEAR_PREPARED_TEXT

PH-21.56 confirme en read-only PROD que le parcours direct du 2026-06-11 21:00-22:15 Europe/Paris a ete observe: funnel register -> tenant_created, tenant pending_payment, checkout session URL creee cote Client/BFF. Aucun paiement Stripe finalise n'est present: 0 checkout.session.completed, 0 subscription created, 0 billing_subscriptions. StartTrial et CAPI StartTrial sont donc EXPECTED_ABSENT, pas un bug CAPI. Attribution Meta campaign non attendue sans lien Meta; `_fbp` seul ne prouve pas une attribution campaign. Dette separee: mieux persister checkout_started/session_created pour les abandons precheckout.

## VERDICT FINAL

`GO READONLY VERIFY WEBSITE TO STRIPE PRECHECKOUT TRACKING PROD EXPECTED_ABSENT_STARTTRIAL PH-SAAS-T8.12AS.21.56`

STOP
