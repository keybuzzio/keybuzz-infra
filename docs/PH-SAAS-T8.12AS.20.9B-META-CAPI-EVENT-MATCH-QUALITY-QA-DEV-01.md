# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-QA-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking) ; KEY-346 (LP conversion)
> Phase : PH-SAAS-T8.12AS.20.9B QA API DEV Meta CAPI EMQ
> Environnement : DEV read-only (aucun PROD, aucun event Meta reel)

## VERDICT

GO QA API META CAPI EVENT MATCH QUALITY DEV READY PH-SAAS-T8.12AS.20.9B

- Runtime API DEV pod `keybuzz-api-86f86f8c58-tpwr2` Ready 1/1 avec digest `sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4` MATCH GHCR.
- Schema DB DEV signup_attribution : `client_ip_address text NULL` + `client_user_agent text NULL` presents, 10 rows preserves.
- 12/12 markers PH-20.9B LIVE dans /app/dist runtime.
- Logs API DEV --tail=200 : 1 occurrence "errors" detectee = FAUX POSITIF `[OCTOPIA-SYNC] Completed: ...errors=0`. 0 column-not-exist, 0 Meta send error, 0 secret leak.
- Smoke /health : HTTP 200 OK.
- **Dry-run mock payload Meta CAPI : 18/18 checks OK** (sans appel reseau Meta) : em/fn/ln/ph/external_id sha256 64 hex, fbc/fbp/IP/UA non hashes, event_source_url https, action_source website, event_id present, custom_data.value+currency OK, access_token/test_event_code absents.
- Runtime API PROD `v3.5.251` INCHANGE.
- Runtime Client + Website + Admin INCHANGES.
- 0 event Meta envoye. 0 test register/checkout. 0 mutation DB. 0 PROD touche.

STOP avant BUILD PROD.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T12:52:19Z |
| keybuzz-api HEAD | d88aa7d0 (PH-20.9B source) |
| keybuzz-infra HEAD | 897358b (post-rapport APPLY DEV) |
| Dirty infra | 0 |

### Runtime

| Service | Env | Runtime | Digest | Verdict |
|---|---|---|---|---|
| keybuzz-api | DEV | v3.5.253-meta-capi-emq-dev | sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 | OK MATCH GHCR |
| keybuzz-api | PROD | v3.5.251-billing-tenant-id-fallback-prod | n/a | INCHANGE |
| keybuzz-client | DEV+PROD | v3.5.210 / v3.5.201 | n/a | INCHANGES |
| keybuzz-website | DEV+PROD | v0.6.20-cmp-mobile-polish-* | n/a | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | n/a | INCHANGES |

Pod : keybuzz-api-86f86f8c58-tpwr2 Ready 1/1 Running.

## E1 SCHEMA DEV VERIFICATION READ-ONLY

| Colonne | Type | Nullable | Present | Verdict |
|---|---|---|---|---|
| signup_attribution.client_ip_address | text | YES | OUI | OK |
| signup_attribution.client_user_agent | text | YES | OUI | OK |

| Indicateur | Valeur |
|---|---|
| signup_attribution rows total | 10 (inchange depuis APPLY DEV) |
| Mutation DB hors lecture | 0 |
| Transaction | BEGIN READ ONLY (ROLLBACK) |
| PII affichee | NON |

Verification via Node + pg dans pod runtime (env vars implicites, PGPASSWORD jamais affiche).

## E2 LOGS RUNTIME API DEV (tail 200)

| Pattern | Count | Verdict |
|---|---|---|
| "error" (case-insensitive) | 1 | FAUX POSITIF (`[OCTOPIA-SYNC] Completed: tenants=0 imported=0 skipped=0 errors=0` = compteur affiche 0) |
| "column.*does not exist" | 0 | OK |
| "signup_attribution.*not" | 0 | OK |
| "Meta send error" / "graph.facebook.*error" | 0 | OK |
| Secret-like / token leak | 0 | OK |
| Startup OK | logs sans crash, pod Running stable | OK |

Aucun vrai error. Aucun missing column. Aucun Meta error.

## E3 AUDIT DIST RUNTIME MARKERS PH-20.9B

| Marker | Count /app/dist | Verdict |
|---|---|---|
| client_ip_address | 8 | OK LIVE |
| client_user_agent | 8 | OK LIVE |
| event_source_url | 6 | OK LIVE |
| external_id_hash | 3 | OK LIVE |
| metaCapiHash | 6 | OK LIVE |
| first_name_hash | 3 | OK LIVE |
| last_name_hash | 3 | OK LIVE |
| phone_hash | 3 | OK LIVE |
| safeEventSourceUrl | 2 | OK LIVE |
| x-forwarded-for | 4 | OK LIVE |
| x-real-ip | 2 | OK LIVE |
| META_EVENT_MAPPING (preserve) | 3 | OK preserve |

12/12 patterns confirmes LIVE.

## E4 DRY-RUN MOCK PAYLOAD META CAPI

Methode : require local `/app/dist/modules/outbound-conversions/adapters/meta-capi.js` dans pod API DEV. Import uniquement `buildMetaServerEvent` (fonction pure) + helpers `metaCapiHash`. **AUCUN appel `sendToMetaCapi`** (qui ferait fetch vers graph.facebook.com). **AUCUN test_event_code**. Donnees TEST-NET-3 / example.invalid (RFC2606).

### Fixtures fake utilisees (jamais envoyees)

- email : `test@example.invalid` (RFC2606 reserved)
- first_name : `Antoine`
- last_name : `Test`
- phone : `+33123456789`
- fbc : `fb.1.1710000000000.fakefbclid`
- fbp : `fb.1.1710000000000.1234567890`
- ip : `203.0.113.10` (TEST-NET-3 RFC5737)
- ua : `KeyBuzz-QA-DryRun/1.0`
- landing_url : `https://client-dev.keybuzz.io/register?fbclid=fake`
- tenant_id : `test-tenant-qa` (fake)

### Checks payload genere (18/18 OK)

| Champ payload | Attendu | Observe | Verdict |
|---|---|---|---|
| event_name | StartTrial | StartTrial | OK |
| event_id present | OUI | OUI | OK |
| event_time | unix int > 1700000000 | unix number | OK |
| action_source | "website" | "website" | OK |
| event_source_url | https:// schema | https://client-dev.keybuzz.io/... | OK |
| em [array hex64] | sha256 64 chars | hex64 | OK |
| fn [array hex64] | sha256 64 chars | hex64 | OK |
| ln [array hex64] | sha256 64 chars | hex64 | OK |
| ph [array hex64] | sha256 64 chars digits-only | hex64 | OK |
| external_id [array hex64] | sha256 64 chars | hex64 | OK |
| fbc | string non hashe fb.* | "fb.1...fakefbclid" | OK |
| fbp | string non hashe fb.* | "fb.1...1234567890" | OK |
| client_ip_address | non hashe | "203.0.113.10" | OK |
| client_user_agent | non hashe | "KeyBuzz-QA-DryRun/1.0" | OK |
| custom_data.value | 39 | 39 | OK |
| custom_data.currency | "EUR" | "EUR" | OK |
| access_token in event | ABSENT (jamais dans server event) | absent | OK |
| test_event_code in event | ABSENT | absent | OK |

### Structure summary

```
event_name        : StartTrial
event_time_type   : number
action_source     : website
event_source_url  : https://
user_data_keys    : [client_ip_address, client_user_agent, em, external_id, fbc, fbp, fn, ln, ph]
custom_data_keys  : [content_name, currency, value]
```

### Hash lengths sha256

| Champ | length |
|---|---|
| em | 64 chars |
| fn | 64 chars |
| ln | 64 chars |
| ph | 64 chars |
| external_id | 64 chars |

Aucune valeur PII affichee, uniquement longueur du hash et conformite hex regex.

## E5 SMOKE READ-ONLY

| Endpoint | HTTP | Body | Verdict |
|---|---|---|---|
| /health (via pod exec) | 200 | `{"status":"ok","timestamp":"2026-05-22T12:53:17.111Z","service":"keybuzz-api","version":"1.0.0"}` | OK |

Aucun appel register / checkout / outbound-conversions send. Aucun event genere.

## E6 NON-REGRESSION RUNTIME

| Service | Runtime | Verdict |
|---|---|---|
| keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-website-dev | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-website-prod | v0.6.20-cmp-mobile-polish-prod | INCHANGE |
| keybuzz-admin-v2 | v2.12.2-* | INCHANGES |

Aucun deploy supplementaire. Aucun manifest GitOps modifie.

## NO FAKE METRICS / NO FAKE EVENTS

| Controle | Resultat | Verdict |
|---|---|---|
| Meta Graph API call | 0 | OK (dry-run pure function, jamais fetch) |
| test_event_code | 0 | OK (absent dry-run payload) |
| Register test | 0 | OK |
| Checkout test | 0 | OK |
| Stripe call | 0 | OK |
| DB mutation | 0 | OK (BEGIN READ ONLY) |
| PROD touched | 0 | OK |
| Browser Pixel ajoute | 0 | OK |
| Faux Lead/Purchase/StartTrial reel | 0 | OK (StartTrial est event_name validatif dans dry-run, jamais envoye) |

## CONFIRMATIONS SECURITE

- AUCUN docker build / docker push.
- AUCUN deploy DEV ni PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUNE migration DB (BEGIN READ ONLY confirme).
- AUCUN event Meta reel. AUCUN appel graph.facebook.com (dry-run pure function uniquement).
- AUCUN secret / token / PGPASSWORD affiche.
- AUCUN PII brut (emails masques, IP/UA fakes RFC reserved, hashes lengths uniquement).
- AUCUN Linear ticket statut modifie.
- Bastion install-v3 (46.62.171.61) uniquement.

## GAPS

1. Aucun blocker.
2. EMQ score Meta final non observable depuis cette QA : amelioration directionnelle confirmee techniquement (payload enrichi pret). Score final visible Antoine Events Manager apres 24-48h trafic reel post-deploy PROD (avec destination Meta CAPI active sur tenant keybuzz-consulting-mo9zndlk).
3. Pas de test "Test Event" Meta Graph API envoye, par design. Si Antoine souhaite valider visuellement dans Events Manager avec test_event_code avant deploy PROD : phase dediee a creer avec GO explicit (eventuelle PH-20.9B-TEST-EVENT) ; non requise pour proceder a BUILD PROD vu que les 18/18 checks dry-run mock sont OK.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO QA API META CAPI EVENT MATCH QUALITY DEV READY PH-SAAS-T8.12AS.20.9B |
| Bastion | install-v3 46.62.171.61 |
| API DEV runtime tag | v3.5.253-meta-capi-emq-dev |
| API DEV runtime digest | sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 |
| Pod DEV | keybuzz-api-86f86f8c58-tpwr2 Ready 1/1 |
| Source commit | d88aa7d0 (PH-20.9B) |
| Schema DEV migration 032 | 2/2 colonnes presentes (client_ip_address, client_user_agent) |
| Logs API DEV | 0 error reelle (1 "errors=0" faux positif), 0 column-not-exist |
| Markers PH-20.9B LIVE pod /app/dist | 12/12 OK |
| Smoke /health | HTTP 200 OK |
| Dry-run mock payload Meta CAPI | **18/18 checks OK** (sans appel reseau) |
| Hash lengths sha256 | 64 chars conformes (em, fn, ln, ph, external_id) |
| Runtime API PROD | INCHANGE |
| Runtime Client + Website + Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-QA-DEV-01.md` |

### Prochaine phrase GO attendue

`GO BUILD API META CAPI EVENT MATCH QUALITY PROD PH-SAAS-T8.12AS.20.9B`

Sequencing PROD (rappel) :
1. BUILD PROD depuis commit d88aa7d0 avec tag immuable distinct -prod.
2. PUSH IMAGE PROD GHCR (GO requis).
3. **MIGRATION 032 sur DB PROD** AVANT rollout image (GO PROD explicit Ludovic, RGPD review valide).
4. APPLY PROD GitOps strict (commit manifest + push + kubectl apply + rollout).
5. Smoke /health PROD + audit dist runtime PROD.
6. QA PROD read-only puis observation 24-48h EMQ Meta Events Manager.

STOP. Aucun PROD, aucun event Meta reel, aucun register/checkout, aucun deploy supplementaire.
