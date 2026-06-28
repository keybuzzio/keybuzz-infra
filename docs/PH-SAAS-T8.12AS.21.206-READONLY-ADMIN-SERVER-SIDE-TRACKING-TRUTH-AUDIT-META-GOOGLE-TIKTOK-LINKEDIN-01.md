# PH-SAAS-T8.12AS.21.206 - Admin server-side tracking truth audit Meta Google TikTok LinkedIn

Date UTC: 2026-06-28
Mode: READONLY PROD
Scope: Admin + API + DB + runtime tracking, ordre demande: Meta, Google, TikTok, LinkedIn.

## Resume Ludovic

Verdict: `READY_WITH_ACTION_REQUIRED_META_ADS_SPEND`

Le tracking server-side conversion n'est pas globalement casse.

Ordre demande:

1. Meta
   - Meta CAPI conversion: OK.
   - Destination active unique: `b9c038ec...4761`.
   - Last test: success le 2026-06-26.
   - Real traffic recent: `trial_page_viewed` delivered HTTP 200 le 2026-06-28T18:39:48Z.
   - Meta Pixel runtime: present dans Client PROD et Website PROD.
   - Dette distincte Admin metrics/spend: Meta Ads token expire depuis le 2026-06-19, donc spend Meta plus rafraichi depuis le 2026-06-19.

2. Google
   - Google Ads account: OK.
   - Last sync: 2026-06-28T18:00:04Z.
   - Spend 7j: present.
   - Spend 30j: present.
   - GA4/sGTM runtime: present dans Client PROD et Website PROD.
   - Tag Google Ads direct `AW-`: absent, conforme architecture KeyBuzz.
   - Google ne doit pas etre cherche dans Delivery Logs: architecture GA4/sGTM + Google Ads import.

3. TikTok
   - TikTok Events API destination: active.
   - Destination active: `75a3c56a...1877`.
   - Last test: success le 2026-05-01.
   - Success historique business: StartTrial delivered HTTP 200 le 2026-05-05, Purchase delivered HTTP 200 le 2026-05-19.
   - TikTok Pixel runtime: present dans Client PROD et Website PROD.
   - Pas de spend TikTok dans Admin Ad Accounts: documente comme hors scope Business API/approval.
   - Limite actuelle: pas d'evenement TikTok recent car pas de conversion eligible recente.

4. LinkedIn
   - LinkedIn CAPI destination: active.
   - Destination active: `b530ffdc...76c2`.
   - Last test: success le 2026-04-27.
   - Success historique business: StartTrial delivered HTTP 201 le 2026-05-05, Purchase delivered HTTP 201 le 2026-05-19.
   - LinkedIn Insight Tag runtime: present dans Client PROD et Website PROD.
   - Pas de spend LinkedIn dans Admin Ad Accounts: documente comme hors scope Ads Reporting.
   - Limite actuelle: pas d'evenement LinkedIn recent car pas de conversion eligible recente.

## Interdits respectes

| Controle | Resultat |
| --- | --- |
| Fake conversion event | 0 |
| POST `/funnel/event` | 0 |
| Provider test call | 0 |
| DB mutation | 0 |
| Secret/token lu ou affiche | 0 |
| Build/deploy/apply | 0 |
| Webflow/Meta/TikTok/LinkedIn/Google UI mutation | 0 |
| Linear mutation | 0 |

## Sources relues

| Source | Resultat |
| --- | --- |
| `AI_MEMORY/CURRENT_STATE.md` | relu |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu |
| `AI_MEMORY/DOCUMENT_MAP.md` | relu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu |
| `KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-UNIFIED.md` | relu |
| `PH-ADMIN-T8.12AS.15.0-SERVER-SIDE-TRACKING-ADS-ACCOUNTS-TRUTH-AUDIT-01.md` | relu |
| `PH-ADMIN-T8.12AS.15.3-CAPI-DELIVERY-PIPELINE-TRUTH-AUDIT-01.md` | relu |
| `PH-SAAS-T8.12AS.21.123-READONLY-CLOSE-META-CAPI-TRIAL_PAGE_VIEWED-REAL-TRAFFIC-PROD-01.md` | relu |

## Preflight

| Surface | Valeur |
| --- | --- |
| Bastion | `install-v3` |
| IP publique | `46.62.171.61` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-prod`, ready 1/1 |
| Admin PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod`, ready 1/1 |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.270-remove-dev-advanced-banner-prod`, ready 1/1 |
| Outbound worker PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod`, ready 1/1 |

## Runtime browser markers

| Surface | Meta pixel | TikTok pixel | LinkedIn partner | GA4 | sGTM | Google Ads direct `AW-` |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Client PROD bundle | 1 | 1 | 1 | 1 | 1 | 0 |
| Website PROD bundle | 1 | 1 | 1 | 1 | 1 | 0 |

## DB read-only truth

### Destinations activees

| Provider | Destination | ID safe | Token metadata | Last test |
| --- | --- | --- | --- | --- |
| Meta CAPI | `KeyBuzz Consulting - Meta CAPI - 2026-06 cutover` | `b9c038ec...4761` | present_long | success 2026-06-26 |
| TikTok Events | `KeyBuzz Consulting - TikTok - 2026-05 cutover` | `75a3c56a...1877` | present_long | success 2026-05-01 |
| LinkedIn CAPI | `KeyBuzz Consulting - LinkedIn CAPI` | `b530ffdc...76c2` | present_long | success 2026-04-27 |

### Delivery logs 30 jours

| Provider | Status | Count | Dernier |
| --- | --- | ---: | --- |
| Meta CAPI | delivered | 4 | 2026-06-28T18:39:48Z |
| Meta CAPI | failed | 6 | 2026-06-26T07:41:25Z, avant cutover token |
| Meta CAPI | success | 1 | 2026-06-26T07:43:33Z, test PageView cutover |

Derniers succes historiques hors 30j glissant strict delivery table:

| Provider | Event | Status | HTTP | Date |
| --- | --- | --- | ---: | --- |
| TikTok | Purchase | delivered | 200 | 2026-05-19 |
| LinkedIn | Purchase | delivered | 201 | 2026-05-19 |
| TikTok | StartTrial | delivered | 200 | 2026-05-05 |
| LinkedIn | StartTrial | delivered | 201 | 2026-05-05 |

### Ad accounts / spend

| Platform | Status | Last sync | Last error | Verdict |
| --- | --- | --- | --- | --- |
| Google | active | 2026-06-28T18:00:04Z | NULL | OK |
| Meta | active | 2026-06-19T10:00:05Z | token expired 2026-06-19 | ACTION_REQUIRED |

Spend:

| Window | Google | Meta | TikTok | LinkedIn |
| --- | ---: | ---: | ---: | ---: |
| 30j | 1985.58 | 1749.26 | 0 | 0 |
| 7j | 416.72 | 0 | 0 | 0 |

Interpretation:

- Google spend est actif.
- Meta spend est stoppe depuis expiration token.
- TikTok/LinkedIn spend ne sont pas connectes par design actuel; verifier conversions via Delivery Logs, pas Ad Accounts.

### Attribution / click IDs 30 jours

| Total signups | With owner | fbclid | gclid | ttclid | li_fat_id | GA4 conversion_sent |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 11 | 1 | 0 | 0 | 0 | 0 | 2 |

Interpretation:

- Les URLs de test internes ne prouvent pas les click IDs provider.
- Pour Ads Manager reel, il faut un clic publicitaire reel ou un test provider officiel.
- Le tracking KeyBuzz ne doit pas inventer de click IDs.

## Admin/source truth

| Surface Admin | Etat |
| --- | --- |
| `/marketing/ad-accounts` | Meta + Google spend uniquement |
| `/marketing/destinations` | Meta CAPI, TikTok Events, LinkedIn CAPI |
| `/marketing/delivery-logs` | Meta/TikTok/LinkedIn CAPI uniquement |
| `/marketing/google-tracking` | Google observability / GA4 conversion_sent |
| `/marketing/campaign-qa` | Documente correctement: Google pas dans Delivery Logs, TikTok/LinkedIn CAPI dans Delivery Logs |

## Finding secondaire hors plateforme

`k8s/keybuzz-api-prod/outbound-tick-processor-cronjob.yaml` appelle encore `POST https://api.keybuzz.io/debug/outbound/tick`.

Constat runtime:

- API PROD loggue des 404 repetes sur `/debug/outbound/tick`.
- La source API contient un module `debugOutbound/routes.ts`, mais le runtime PROD courant ne sert pas cette route.
- Ce bruit ne prouve pas une casse CAPI Meta/Google/TikTok/LinkedIn.
- C'est une dette SRE/runtime a traiter separement pour nettoyer les logs et verifier l'utilite du CronJob.

## Verdict par plateforme

| Ordre | Plateforme | Tracking conversion | Spend/Admin metrics | Verdict |
| ---: | --- | --- | --- | --- |
| 1 | Meta | OK, delivered recent HTTP 200 | KO token Ads expire | ACTION_REQUIRED_META_ADS_SPEND |
| 2 | Google | OK via GA4/sGTM/import, pas Delivery Logs | OK sync 2026-06-28 | READY |
| 3 | TikTok | OK configure + succes historiques | Hors scope | READY_WITH_TRAFFIC_REQUIRED |
| 4 | LinkedIn | OK configure + succes historiques | Hors scope | READY_WITH_TRAFFIC_REQUIRED |

## Actions recommandees

1. Meta Ads spend: renouveler le token Meta Ads dans Admin > Marketing > Ad Accounts pour le compte Meta `148...5668`, puis lancer un sync manuel et verifier `last_error=NULL`, `last_sync_at` recent, spend 7j present.
2. CAPI provider tests: ne pas lancer de test automatique sans code de test provider, car les endpoints ecrivent des logs et envoient des events provider. Si Ludovic veut une validation provider UI, utiliser les boutons Test Admin avec un `test_event_code` fourni par Events Manager / TikTok Events Manager / LinkedIn.
3. Real traffic validation: pour TikTok et LinkedIn, attendre ou provoquer un vrai StartTrial/Purchase eligible via URL de campagne avec `marketing_owner_tenant_id`, puis verifier Delivery Logs.
4. Dette SRE: traiter separement le CronJob `/debug/outbound/tick` 404.

## Conclusion

Le systeme n'est pas a reconstruire. La configuration conversion server-side existe et fonctionne. Le seul blocage concret actuel dans Admin est Meta Ads spend, distinct de Meta CAPI, qui necessite un nouveau token Meta Ads ou un refresh via l'UI/Admin. TikTok et LinkedIn ne peuvent pas etre declares "recents" sans trafic eligible recent, mais leur configuration est active et a deja livre des conversions business avec succes.

STOP
