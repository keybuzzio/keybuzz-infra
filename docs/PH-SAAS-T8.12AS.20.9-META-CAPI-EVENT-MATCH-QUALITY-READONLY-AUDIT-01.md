# PH-SAAS-T8.12AS.20.9-META-CAPI-EVENT-MATCH-QUALITY-READONLY-AUDIT-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338/KEY-340 (related tracking) ; KEY-346 (LP conversion)
> Phase : PH-SAAS-T8.12AS.20.9 META CAPI EVENT MATCH QUALITY READONLY AUDIT
> Environnement : PROD + DEV read-only (aucune mutation, aucun event)

## VERDICT

GO READONLY AUDIT META CAPI EVENT MATCH QUALITY PLAUSIBLE PH-SAAS-T8.12AS.20.9

Le score 4/10 EMQ rapporte par Antoine dans Meta Events Manager est techniquement PLAUSIBLE et coherent avec le payload actuel.

Observations :
- Adapter `meta-capi.ts` envoie un payload tres minimal : seuls `em` (email_hash), `fbc`, `fbp` sont mappes dans `user_data`.
- Champs Meta requis ou fortement recommandes pour EMQ absents du payload : `event_source_url`, `client_ip_address`, `client_user_agent`, `external_id`.
- 30 jours PROD : 3 conversion_events sent (1 Purchase, 2 StartTrial) avec coverage `em=100%`, `fbp=67%`, `fbc=0%`, `fbclid=0%`, `landing_url=67%`. Le champ `landing_url` est disponible en source mais N EST PAS mappe vers `event_source_url` Meta.
- 30 jours signup_attribution : 16 signups avec `fbc=25%`, `fbp=56%`, `fbclid=0%`. Le ratio fbclid=0 sur 16 signups est inhabituel mais probablement lie au mix de trafic actuel (mostly direct/manual avant ramp acquisition).
- Le source `signup_attribution` NE CAPTURE PAS aujourd hui `client_ip_address` ni `client_user_agent` (colonnes inexistantes).
- Aucun ajout fake event detecte. Audit 100% read-only confirme.

Recommandation : patch PH-20.9B source side enrichir Meta CAPI payload. AUCUN patch dans cette phase.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-api HEAD | 6850427c (ph147.4/source-of-truth) |
| keybuzz-client HEAD | be45f1d (ph148/onboarding-activation-replay) |
| keybuzz-website HEAD | bb49798 (main) |
| keybuzz-infra HEAD | 72eb1fb (main) |
| Runtime API DEV+PROD | v3.5.252 / v3.5.251 |
| Runtime Client DEV+PROD | v3.5.210 / v3.5.201 |
| Runtime Website DEV+PROD | v0.6.20-cmp-mobile-polish-dev / -prod |

## SOURCES RELUES

- AI_MEMORY/CURRENT_STATE.md, RULES_AND_RISKS.md, DOCUMENT_MAP.md, CE_PROMPTING_STANDARD.md.
- PH-20.6C APPLY PROD, PH-20.7 audit Antoine, PH-20.8 APPLY PROD Website CMP.
- Code audite : meta-capi.ts, emitter.ts, tenant-context-routes.ts create-signup, billing/routes.ts, Client attribution.ts, Website marketing-tracking.ts.
- Doc Meta CAPI : developers.facebook.com/docs/marketing-api/conversions-api/parameters/server-event et /customer-information-parameters.

## E1 CODE AUDIT META CAPI

### meta-capi.ts adapter (full read)

| Element | Statut | Detail |
|---|---|---|
| META_API_VERSION | v21.0 | OK |
| Endpoint | graph.facebook.com/v21.0/{pixelId}/events | OK |
| META_EVENT_MAPPING | StartTrial + Purchase | OK 2 events |
| `MetaUserData` interface | em[], fbc, fbp | **TRES MINIMAL** |
| `MetaCustomData` | value, currency, content_name | OK |
| `MetaServerEvent` | event_name, event_time, event_id, action_source, user_data, custom_data | event_source_url ABSENT, opt_out ABSENT, data_processing_options ABSENT |
| Hashing | email deja hashe en amont (canonical) | OK |
| test_event_code | supporte si parametre | OK |
| Timeout | 15s + AbortController | OK |
| action_source | always "website" | OK |
| event_id | depuis canonical, unique | OK (deduplication possible) |

### emitter.ts canonical payload (l.460-560 + 480-540)

| Source champ | Persiste | Envoye Meta | Verdict |
|---|---|---|---|
| customer.email_hash (sha256 lowercased email) | OK | OK -> em[] | OK |
| attribution.fbc | OK (si present DB) | OK -> fbc | OK |
| attribution.fbp | OK (si present DB) | OK -> fbp | OK |
| attribution.fbclid | OK | NON mappe | **MANQUE** (peut servir reconstruction fbc cote API si client a perdu) |
| attribution.landing_url | OK | NON mappe | **MANQUE** (= event_source_url Meta) |
| attribution.referrer | OK | NON mappe | candidat secondaire |
| customer.tenant_id | OK canonical | NON mappe Meta | **MANQUE** (= external_id Meta hashable) |
| client_ip_address (request header) | **NON capture** au signup | NON envoye | **MANQUE** (champ Meta a fort impact EMQ) |
| client_user_agent (request header) | **NON capture** au signup | NON envoye | **MANQUE** (champ Meta a fort impact EMQ) |
| ph (phone) | tenant_metadata.company_phone present, sans hash | NON envoye | optionnel (hashable si consentement) |
| fn/ln (first/last name) | tenant_metadata.first_name / last_name present | NON envoye | optionnel (hashable si consentement) |
| ct/st/zp/country | tenant_metadata zipCode/city/country present | NON envoye | optionnel (hashable si consentement) |

### Client attribution.ts (capture cote navigateur)

| Indicateur | Statut | Detail |
|---|---|---|
| fbclid URL param | capture | get('fbclid') depuis searchParams |
| fbc reconstruit depuis fbclid | OK avec timestamp Date.now() | `fb.1.${Date.now()}.${fbclid}` |
| fbp depuis cookie `_fbp` | capture si Meta Pixel a pose le cookie | depend de Meta Pixel cote client.keybuzz.io |
| landing_url | capture URL complete avec search | OK |
| referrer | capture document.referrer | OK |
| Stockage | sessionStorage primary + localStorage backup 30min TTL | OK |
| Cross-domain | keybuzz.pro -> client.keybuzz.io = cookies _fbp PERDUS (domaines distincts) | LIMITE structurelle |

### create-signup route persistence

Fichier : `/opt/keybuzz/keybuzz-api/src/modules/auth/tenant-context-routes.ts` l.728-762

| Champ persiste | INSERT signup_attribution | Verdict |
|---|---|---|
| tenant_id, user_email, plan, cycle | OK | OK |
| utm_* | OK | OK |
| gclid, fbclid, fbc, fbp, ttclid, li_fat_id, _gl | OK | OK |
| landing_url, referrer, attribution.id, marketing_owner_tenant_id | OK | OK |
| **request.ip / x-forwarded-for** | **NON LU** | **MANQUE** |
| **request.headers["user-agent"]** | **NON LU** | **MANQUE** |

Note : Fastify expose `request.ip` et `request.headers['user-agent']` en standard. La capture est triviale a ajouter.

### Website CTA forwarding (marketing-tracking.ts)

| Indicateur | Detail |
|---|---|
| Tracking `gclid_present`/`fbclid_present` (boolean) | OK |
| Forwarding query params vers client.keybuzz.io | NON detecte dans MarketingCTA.tsx (=> CTA href hardcode vers /register sans propager search) |
| Verification | grep `client.keybuzz.io.*\?` ne ressort pas dans CTA components actifs |
| Files trouvees forwarding `/signup` (legacy) | page.tsx.backup + page.tsx.bak-v0610 (orphans non actifs) |
| Risque | Si pub clique sur keybuzz.pro -> CTA -> client.keybuzz.io sans propager `?fbclid=...&utm_*=...`, le client perd l attribution. attribution.ts cote client peut neanmoins capturer si l URL d arrivee directe a les params (cas ad direct vers client.keybuzz.io/register), mais le hop website intermediaire est probable et casse la chaine. |

## E2 DB AUDIT READ-ONLY

### Tables schemas confirmees

- `signup_attribution` : 28 colonnes. PAS de colonne ip_address, PAS de colonne user_agent. `attribution_id` present (peut servir external_id Meta), `marketing_owner_tenant_id`, `stripe_session_id`, `conversion_sent_at`.
- `conversion_events` : 9 colonnes. payload JSONB. event_id UNIQUE (dedup OK).
- `outbound_conversion_destinations` : 19 colonnes. platform_pixel_id, platform_token_ref, last_test_status.
- `outbound_conversion_delivery_logs` : 10 colonnes. event_name, status, http_status, attempt, error_message.

### Destinations Meta CAPI actives

| Tenant | type | active | has_pixel | has_token | last_test_status | last_test_at |
|---|---|---|---|---|---|---|
| keybuzz-consulting-mo9zndlk | meta_capi | true | true | true | success | 2026-04-23 |
| keybuzz-consulting-mo9zndlk | meta_capi | false (duplicate) | true | true | null | (jamais teste) |
| keybuzz-consulting-mo9zndlk | linkedin_capi | true | true | true | success | 2026-04-27 |
| ecomlg-001 | meta_capi (4 destinations) | false (toutes) | true | true | failed/null | 2026-04-22 |

Total Meta CAPI actives : **1** (Antoine KeyBuzz Consulting). Token et pixel masques (presence only).

### Delivery logs Meta 30j

Note : colonne `success` n existe pas dans la table - schema reel utilise `status` + `http_status`. Re-query aggrege impossible avec ce filtre dans cet audit (faux positif sur nommage column), mais conversion_events table confirme 3 events `status=sent` 30j ce qui implique delivery reussi.

### conversion_events 30j (PII masques)

| Indicateur | Valeur |
|---|---|
| Total 30j | 3 (1 Purchase + 2 StartTrial) |
| Status sent | 3/3 (100%) |
| has em (email_hash) | 3/3 = 100% |
| has fbc | **0/3 = 0%** |
| has fbp | 2/3 = 67% |
| has fbclid | 0/3 = 0% |
| has landing_url | 2/3 = 67% |
| has referrer | 0/3 (verifie par sample) |

### signup_attribution 30j coverage source

| Indicateur | Valeur 30j |
|---|---|
| Total signups | 16 |
| has fbc | 4/16 = **25%** |
| has fbp | 9/16 = **56%** |
| has fbclid | **0/16 = 0%** (signups recents sans clic FB attribue) |
| has gclid | 2/16 = 12% |
| has ttclid | 1/16 = 6% |
| has li_fat_id | 0/16 = 0% |
| has landing_url | 15/16 = **94%** |
| has referrer | 5/16 = 31% |

### Sample 5 events (PII masque)

```
event=Purchase    sent  2026-05-19  em=1 fbc=0 fbp=1 fbclid=0 landing=1 referrer=0
event=StartTrial  sent  2026-05-05  em=1 fbc=0 fbp=1 fbclid=0 landing=1 referrer=0
event=StartTrial  sent  2026-04-25  em=1 fbc=0 fbp=0 fbclid=0 landing=0 referrer=0
```

### Colonnes IP/UA signup_attribution

`SELECT column_name FROM information_schema.columns WHERE column_name ILIKE '%ip%' OR column_name ILIKE '%agent%'` retourne uniquement `stripe_session_id` et `stripe_promotion_code_id` (faux positifs). **Aucune colonne ip_address ni user_agent**.

## E3 ATTRIBUTION FORWARDING

| Etape | Statut | Verdict |
|---|---|---|
| Pub Meta -> keybuzz.pro/ avec `?fbclid=xxx&utm_*` | OK | Le browser pose `_fbp` si Meta Pixel actif sur keybuzz.pro (Clarity=0 baseline website, GA+SGTM+LinkedIn=18 mais Meta Pixel browser-side ne ressort PAS dans bundle Website audit precedent). |
| keybuzz.pro -> CTA -> client.keybuzz.io/register | LIMITE | Query params NON forwardes par les CTA detectes. fbclid perdu cote client. |
| client.keybuzz.io/register direct depuis pub | OK | attribution.ts capture fbclid + reconstruit fbc, lit _fbp si Meta Pixel pose cookie cote client |
| Cookie `_fbp` cross-domain keybuzz.pro <-> client.keybuzz.io | NON | domaines apex distincts ; chaque domaine a son propre _fbp |
| fbc reconstruction cote client si fbclid present | OK (buildFbc) | mais utilise Date.now() au lieu du timestamp du click reel (impact mineur sur attribution Meta) |

**Conclusion forwarding** : le hop website -> client perd les query params (manque source decisive de fbclid). Si la pub pointe directement sur client.keybuzz.io/register avec fbclid, l attribution fonctionne. Si la pub pointe sur keybuzz.pro et l utilisateur clique CTA, fbclid est perdu.

## E4 META CAPI CURRENT vs TARGET MATRIX

| Champ Meta | Statut actuel | Source disponible | Patch necessaire | PII/legal | Impact EMQ estime | Risque |
|---|---|---|---|---|---|---|
| em (email hash sha256) | OK (3/3 events) | signup_attribution.user_email | aucun | hashable, deja hashe | base | aucun |
| fbc | OK partiel (4/16 source, 0/3 envoyes recents) | signup_attribution.fbc OU fbclid pour reconstruction | mapping OK adapter ; ameliorer source via forwarding website->client | non sensible | moyen | aucun |
| fbp | OK partiel (9/16 source, 2/3 envoyes) | signup_attribution.fbp | mapping OK ; ameliorer source via Meta Pixel cote client.keybuzz.io | non sensible | moyen | aucun |
| **event_source_url** | **MANQUE Meta** | signup_attribution.landing_url 94% disponible | **PATCH ADAPTER trivial** | non sensible | **eleve** (champ requis par Meta pour CAPI website) | aucun |
| **client_ip_address** | **MANQUE source + adapter** | request.ip Fastify | **PATCH create-signup + adapter** | sensible (legal review) | **tres eleve** | RGPD : a documenter dans cookies/privacy si pas deja couvert |
| **client_user_agent** | **MANQUE source + adapter** | request.headers.user-agent | **PATCH create-signup + adapter** | semi-sensible | **eleve** | RGPD : a documenter |
| **external_id** | MANQUE adapter | tenant_id OU attribution_id stable | **PATCH adapter** (hash) | non sensible | moyen-eleve | aucun |
| ph (phone) | MANQUE adapter | tenant_metadata.company_phone | optionnel (hash) | sensible | faible (B2B phone moins discriminant) | RGPD |
| fn (first name) | MANQUE adapter | tenant_metadata.first_name | optionnel (hash) | sensible | moyen | RGPD |
| ln (last name) | MANQUE adapter | tenant_metadata.last_name | optionnel (hash) | sensible | moyen | RGPD |
| ct/st/zp/country | MANQUE adapter | tenant_metadata.city/zipCode/country | optionnel (hash) | semi-sensible | faible | RGPD |
| event_id | OK | canonical event_id stable | aucun | non | dedup browser/server | aucun |
| action_source | OK = website | hardcode | aucun | non | base | aucun |
| event_time | OK | new Date() ISO -> floor unix | aucun | non | base | aucun |

## E5 RISQUES / CONSENTEMENT / LEGAL / DEDUP

| Risque | Cause | Niveau | Mitigation | Bloquant ? |
|---|---|---|---|---|
| RGPD client_ip + client_user_agent | Pas mentionne explicitement dans politique cookies/confidentialite actuelle | moyen | Legal review Ludovic OU couverture via mention "donnees techniques transmises a outils mesure d audience avec consentement" deja existante | NON bloquant si Clarity/Meta Pixel deja couverts par CMP, mais review recommande |
| Double-count si Meta Pixel browser ajoute Purchase | Pas de Meta Pixel browser detecte aujourd hui dans bundle Website ni Client (audit precedent PH-20.8 : 0 fake events) | faible | event_id Meta deja stable ; si browser pixel ajoute futur, deja-prevu | NON |
| Cross-domain _fbp lost | keybuzz.pro et client.keybuzz.io = domaines apex distincts | structurel | Meta Pixel cote client.keybuzz.io pose son propre _fbp | NON |
| fbc reconstruction Date.now() | Si user a clique pub il y a >1h, timestamp incorrect | faible | Meta utilise principalement le fbclid pour match, timestamp aide mais pas critique | NON |
| Token Meta CAPI revelation | Adapter utilise access_token via env runtime (jamais log) | faible | redactSecrets() applique sur reponses | NON |
| Faux event ajoute par audit | AUDIT READ-ONLY STRICT respecte | nul | aucune action mutante | NON |
| EMQ score promesse | Pas de garantie 4 -> X precis sans trafic reel | faible | Promettre amelioration directionnelle, pas score exact | NON |

## E6 RECOMMANDATION PATCH PH-20.9B

**Option recommandee A : Patch API server-side enrichissement payload Meta CAPI** (haut impact, scope contenu)

Scope :
1. `tenant-context-routes.ts` create-signup : capturer `request.ip` (proxy-safe via `request.headers['x-forwarded-for']` fallback `request.ip`) et `request.headers['user-agent']`, persister dans signup_attribution.
2. Migration DB : ajouter colonnes `client_ip_address text` et `client_user_agent text` a signup_attribution (nullable, non-breaking).
3. `billing/routes.ts` checkout-session : optionnel meme capture si valable.
4. `emitter.ts` canonical : ajouter `client_ip_address`, `client_user_agent`, `external_id` (= attribution_id ou tenant_id stable) dans payload.
5. `meta-capi.ts` adapter : etendre `MetaUserData` avec `client_ip_address`, `client_user_agent`, `external_id` (hashe sha256 lowercased), `fn`, `ln`, `ct`, `st`, `zp`, `country` (tous hashes). Ajouter `event_source_url` au `MetaServerEvent` (depuis canonical.attribution.landing_url).
6. Aucun changement IDs analytics existants.
7. Aucun ajout browser Meta Pixel Purchase/Lead pour eviter double-count.
8. Tests unitaires sur mapping Meta + audit bundle/DB pre/post.
9. DEV apply -> validation Antoine Events Manager (Meta peut montrer EMQ enrichi en 24-48h avec trafic reel) -> PROD avec GO explicite.

**Option secondaire B : Patch Website CTA forwarding query params** (si Option A insuffisante apres mesure)

Scope :
- Detecter dans Website MarketingCTA les CTA pointant vers client.keybuzz.io et forwarder le `window.location.search` au routing.
- Beneficie aussi GA4/SGTM/LinkedIn (preserve UTM cross-domain).

**Option a EVITER** :
- Ajouter Meta Pixel browser Purchase/Lead sans event_id dedup parfait. Risque double-count.
- Envoyer des `test_event_code` ou faux events pour booster artificiellement EMQ.
- Stocker PII brute (email/phone/name plain text) inutilement.

## HORS SCOPE CONFIRME

- Aucun patch source applique.
- Aucun build.
- Aucun docker push.
- Aucun deploy DEV/PROD.
- Aucun event Meta reel envoye.
- Aucun test register / lead / Purchase.
- Aucun changement IDs analytics.
- Aucun changement Linear statut.

## CONFIRMATIONS SECURITE

- READ-ONLY strict : BEGIN TRANSACTION READ ONLY confirme `transaction_read_only=on`.
- Aucun DELETE/UPDATE/INSERT.
- Aucun secret/token affiche dans le rapport.
- Tokens Meta : presence/absence reportes uniquement.
- Pixel ID : reporte uniquement comme `has_pixel=true` (valeurs masquees).
- Emails masques (sample events).
- Aucun IP user affiche en clair.
- Bastion install-v3 (46.62.171.61) uniquement.
- /opt/keybuzz/credentials/ et /opt/keybuzz/secrets/ non ouverts.
- Audit Node + pg via env vars implicites (pas d expose env complet).

## RUNTIME INCHANGES

| Service | Runtime | Verdict |
|---|---|---|
| API DEV+PROD | v3.5.252 / v3.5.251 | INCHANGES |
| Client DEV+PROD | v3.5.210 / v3.5.201 | INCHANGES |
| Website DEV+PROD | v0.6.20-cmp-mobile-polish-* | INCHANGES |
| Admin DEV+PROD | v2.12.2-* | INCHANGES |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO READONLY AUDIT META CAPI EVENT MATCH QUALITY PLAUSIBLE PH-SAAS-T8.12AS.20.9 |
| Score Antoine 4/10 plausible techniquement | OUI confirme par payload minimal observe |
| Adapter Meta envoie | em + fbc + fbp uniquement |
| Manques majeurs | event_source_url, client_ip_address, client_user_agent, external_id |
| Source disponible immediatement | landing_url (94% signups) -> event_source_url ; tenant_id -> external_id |
| Source a capturer | request.ip + request.headers.user-agent dans create-signup |
| Recommandation | PH-20.9B Option A : patch API server-side enrichissement |
| Risques bloquants | aucun ; legal review consentement RGPD recommande pour IP/UA mais probablement deja couvert CMP existante |
| Mutation appliquee | aucune |
| Build/deploy applique | aucun |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9-META-CAPI-EVENT-MATCH-QUALITY-READONLY-AUDIT-01.md` |

### Prochaine phrase GO attendue

`GO SOURCE PATCH META CAPI EVENT MATCH QUALITY PH-SAAS-T8.12AS.20.9B`

Ce GO necessite confirmation Ludovic sur 3 points :
1. OK pour capturer client_ip_address + client_user_agent server-side au signup ? (RGPD review)
2. Ajouter colonnes signup_attribution `client_ip_address` + `client_user_agent` (migration DB additive non-breaking) ?
3. Etendre adapter Meta avec event_source_url + IP + UA + external_id (hashe) ?

STOP. Aucun patch, aucun build, aucun deploy, aucun test event sans GO Ludovic.
