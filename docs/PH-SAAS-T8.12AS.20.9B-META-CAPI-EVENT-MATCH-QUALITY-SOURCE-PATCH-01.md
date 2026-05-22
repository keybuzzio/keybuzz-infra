# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-SOURCE-PATCH-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking) ; KEY-346 (LP conversion)
> Phase : PH-SAAS-T8.12AS.20.9B META CAPI EMQ SOURCE PATCH
> Environnement : SOURCE PATCH only (aucun build, aucun docker push, aucun deploy, aucune migration appliquee)

## VERDICT

GO SOURCE PATCH META CAPI EVENT MATCH QUALITY READY PH-SAAS-T8.12AS.20.9B

- 4 fichiers API patches : `meta-capi.ts`, `emitter.ts`, `tenant-context-routes.ts`, migration additive `032_signup_attribution_client_metadata.sql`.
- Commit API `d88aa7d0` push origin `ph147.4/source-of-truth`.
- 0 changement Client/Website/Admin (forwarding query params deja en place via Navbar.signupHref + pricing/page.tsx utmSuffix : audit PH-20.9 conclu a tort manquant ; verifie en PH-20.9B = OK).
- TSC noEmit avec project config = 0 erreurs.
- Aucun appel reseau Meta. Aucun event reel envoye. Aucun test event_code.
- Aucune migration appliquee live (fichier SQL stage uniquement).
- Cibles Antoine respectees dans l ordre : fbclid -> fbc (deja envoye, source preservee), email hash (em, deja), prenom/nom hash (fn/ln, NOUVEAU), telephone hash (ph, NOUVEAU), event_source_url (NOUVEAU), client_ip_address (NOUVEAU), client_user_agent (NOUVEAU), external_id sha256(tenant_id) (NOUVEAU).

## CONTEXTE ANTOINE

Antoine signale Event Match Quality 4/10 dans Meta Events Manager. Priorite verbatim :
"Le plus important c est le fbclid, prenom/nom email, puis si dispo numero de tel, et ensuite tu peux rajouter d autres infos en plus."

Audit PH-20.9 a confirme :
- Adapter envoie em + fbc + fbp uniquement.
- event_source_url ABSENT.
- client_ip_address ABSENT (source + adapter).
- client_user_agent ABSENT (source + adapter).
- external_id ABSENT.
- signup_attribution n a pas de colonnes IP / UA.

## SOURCES RELUES

- AI_MEMORY/CURRENT_STATE.md, RULES_AND_RISKS.md, DOCUMENT_MAP.md, CE_PROMPTING_STANDARD.md.
- PH-SAAS-T8.12AS.20.9-META-CAPI-EVENT-MATCH-QUALITY-READONLY-AUDIT-01.md.
- PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-APPLY-PROD-01.md.
- PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-APPLY-PROD-01.md.
- Meta Conversions API server-event + customer-information-parameters.

## REPOS / BRANCHES / HEAD

| Repo | Branche | HEAD avant | HEAD apres | Dirty final attendu | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 6850427c | **d88aa7d0** | dist/ + autres pre-existing (non touches par PH-20.9B) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | be45f1d | be45f1d (INCHANGE) | tsconfig.tsbuildinfo pre-existing | OK pas touche |
| keybuzz-website | main | bb49798 | bb49798 (INCHANGE) | 0 | OK pas touche (forwarding deja OK) |
| keybuzz-infra | main | d34042f | (post-rapport) | 0 | OK |

## FICHIERS MODIFIES

| Repo | Fichier | Changement | Risque | Verdict |
|---|---|---|---|---|
| keybuzz-api | `src/modules/outbound-conversions/adapters/meta-capi.ts` | +89 -5 : MetaUserData etendu (fn, ln, ph, external_id, client_ip_address, client_user_agent), MetaServerEvent + event_source_url, helpers hash exportes metaCapiHash, safeEventSourceUrl gate http/https | nul (additif, redaction logs preserve) | OK |
| keybuzz-api | `src/modules/outbound-conversions/emitter.ts` | +52 -5 : ConversionPayload etendu, SELECT signup_attribution + IP/UA, SELECT tenant_metadata first_name/last_name/phone, hashes via metaCapiHash, external_id sha256(tenant_id) | faible (try/catch non-blocking sur DB queries, fallback null) | OK |
| keybuzz-api | `src/modules/auth/tenant-context-routes.ts` | +18 -2 : capture x-forwarded-for / x-real-ip / request.ip + user-agent, INSERT signup_attribution etendu 22 colonnes | faible (try/catch SAVEPOINT preserve, jamais logge) | OK |
| keybuzz-api | `migrations/032_signup_attribution_client_metadata.sql` | +17 -0 : ALTER TABLE ADD COLUMN IF NOT EXISTS client_ip_address TEXT, client_user_agent TEXT | nul (additif nullable, reversible, NE PAS appliquer en live) | OK |

## CHAMPS META AJOUTES

| Champ Meta | Avant PH-20.9B | Apres PH-20.9B | Source | Hash | PII | Verdict |
|---|---|---|---|---|---|---|
| em (email) | OK | OK preserve | signup_attribution.user_email | sha256 lowercased trim (deja en place) | OUI | OK |
| **fn (first name)** | ABSENT | **OK** | tenant_metadata.first_name | sha256 normalizeText | OUI | NOUVEAU |
| **ln (last name)** | ABSENT | **OK** | tenant_metadata.last_name | sha256 normalizeText | OUI | NOUVEAU |
| **ph (phone)** | ABSENT | **OK** | tenant_metadata.phone | sha256 normalizePhone (digits only) | OUI | NOUVEAU |
| **external_id** | ABSENT | **OK** | tenant_id (stable) | sha256 | NON (identifiant interne) | NOUVEAU |
| fbc | OK partiel | OK preserve | signup_attribution.fbc | non hashe | NON | OK |
| fbp | OK partiel | OK preserve | signup_attribution.fbp | non hashe | NON | OK |
| **client_ip_address** | ABSENT | **OK** | request.ip / x-forwarded-for / x-real-ip | non hashe | OUI sensible | NOUVEAU |
| **client_user_agent** | ABSENT | **OK** | request.headers user-agent | non hashe | semi-sensible | NOUVEAU |
| **event_source_url** | ABSENT | **OK** | signup_attribution.landing_url | non hashe | non PII directe | NOUVEAU |
| event_id (dedup) | OK | OK preserve | canonical event_id stable | non | non | OK |
| action_source | OK = website | OK preserve | hardcode | non | non | OK |
| event_time | OK | OK preserve | new Date() floor unix | non | non | OK |

## TABLE ATTRIBUTION

| Signal | Source | Capture | Persistance | Envoi Meta | Verdict |
|---|---|---|---|---|---|
| fbclid | query Website (Navbar/pricing) -> Client attribution.ts | OK (deja en place) | signup_attribution.fbclid | via fbc (reconstruit Client) | preserve priorite max |
| fbc | cookie _fbc Client + reconstruction depuis fbclid | OK | signup_attribution.fbc | OK fbc (non hashe) | preserve |
| fbp | cookie _fbp Client | OK partiel cross-domain | signup_attribution.fbp | OK fbp (non hashe) | preserve |
| email | signup form Client | OK | signup_attribution.user_email | em (sha256 lowercased) | hash |
| prenom | signup form Client (firstName) | OK | tenant_metadata.first_name | fn (sha256 normalized) | hash NOUVEAU |
| nom | signup form Client (lastName) | OK | tenant_metadata.last_name | ln (sha256 normalized) | hash NOUVEAU |
| phone | signup form Client (phone) | OK si fourni | tenant_metadata.phone | ph (sha256 digits) | hash NOUVEAU |
| IP | request.ip + headers proxy | OK NOUVEAU | signup_attribution.client_ip_address | client_ip_address (non hashe) | nullable NOUVEAU |
| UA | request.headers.user-agent | OK NOUVEAU | signup_attribution.client_user_agent | client_user_agent (non hashe) | nullable NOUVEAU |
| event_source_url | signup_attribution.landing_url | OK existant | reutilise | event_source_url (http/https gate) | NOUVEAU mapping |
| external_id | tenant_id (stable post-signup) | OK | tenants.id | external_id (sha256) | hash NOUVEAU |

## DONNEES DISPONIBLES vs NON DISPONIBLES

### Disponibles maintenant cote signup (transmises automatiquement)

- em (email)
- fn (first_name si signup le fournit) - obligatoire dans tenant-context-routes
- ln (last_name si signup le fournit) - obligatoire dans tenant-context-routes
- ph (phone si signup le fournit) - optionnel dans signup
- external_id (tenant_id stable)
- client_ip_address (request server)
- client_user_agent (request server)
- event_source_url (landing_url)
- fbc/fbp (selon attribution Client)

### Disponibles mais non envoyes

- ct (city), st (state), zp (zip), country : presents dans tenant_metadata mais NON envoyes pour rester conservatif sur le scope PH-20.9B. Peuvent etre ajoutes dans une future PH-20.9C si EMQ reste sous 7/10 apres PH-20.9B en PROD.

### Non disponibles aujourd hui

- db (date of birth) : non collecte (B2B, non pertinent).
- ge (gender) : non collecte (B2B, non pertinent).
- subscription_id Meta : non applicable (KeyBuzz est cote demandeur, pas Meta).
- fb_login_id, lead_id : non applicable (pas de Meta Login KeyBuzz).

## MIGRATION SOURCE AJOUTEE, NON APPLIQUEE

Fichier : `keybuzz-api/migrations/032_signup_attribution_client_metadata.sql`

Contenu :
```
ALTER TABLE signup_attribution
  ADD COLUMN IF NOT EXISTS client_ip_address TEXT,
  ADD COLUMN IF NOT EXISTS client_user_agent TEXT;
```

Statut : commit dans le repo seulement. **AUCUNE execution sur DB live (DEV ni PROD)**. Application pendant phase BUILD/DEPLOY DEV avec GO Ludovic explicite.

Reversibilite : `ALTER TABLE signup_attribution DROP COLUMN client_ip_address, DROP COLUMN client_user_agent;`

## TESTS RESULTATS

| Repo | Test | Resultat | Verdict |
|---|---|---|---|
| keybuzz-api | npx tsc --noEmit (project config tsconfig.json) | 0 erreurs | OK |
| keybuzz-api | git diff --stat scope (4 fichiers seulement) | 4 files, +171 -5 | OK scope strict |
| keybuzz-api | grep no fake events dans patches | aucun Lead/Purchase/StartTrial ajoute artificiellement | OK |
| keybuzz-api | grep no secrets dans patches | aucun token/pixel hardcode | OK |
| keybuzz-api | grep no Meta network test | aucun fetch direct Meta dans patches (utilise sendToMetaCapi existant) | OK |

Pas de tests unitaires Jest/Vitest dans le repo (audit `find -name "*.test.ts" -not -path "node_modules"` = aucun hors node_modules). Tests source validation = tsc + grep + diff.

## NO FAKE METRICS / NO FAKE EVENTS

- Aucun nouvel event marketing genere par les patches.
- Aucun compteur artificiel.
- Aucun test_event_code envoye.
- event_id stable preserve (deduplication browser/server intacte).
- Aucun Meta Pixel browser ajoute (eviter double-count).
- Aucun appel reseau Meta dans les tests source.

## PII / LOGGING / SECRETS GUARDRAILS

- IP/UA capture server-side mais **jamais logge en clair** (commentaire explicite dans tenant-context-routes.ts).
- Helpers metaCapiHash exportes : retourne null si entree vide, sinon sha256 hex 64 chars.
- safeEventSourceUrl rejette URL non http/https + cap 512 chars.
- redactSecrets() preserve sur erreurs Meta CAPI (token jamais log).
- tokens Meta CAPI : lus depuis env runtime, jamais touche dans les patches.
- Pixel ID : passe en argument sans modification.
- Aucun PII brut dans le rapport.

## RISQUES RESTANTS

| Risque | Niveau | Mitigation actuelle | Action future |
|---|---|---|---|
| RGPD client_ip + user_agent server-side | moyen | CMP existante mention "outils mesure d audience" probablement couvre | Legal review Ludovic avant PROD recommande |
| Migration 032 oubliee avant deploy | moyen | Rapport documente explicitement le sequencing | Phase BUILD DEV doit appliquer migration AVANT deploy emitter |
| signup_attribution.client_ip_address / user_agent absent en DB live actuellement | resolu par patch | emitter try/catch SELECT echoue silencieux et continue | Avant deploy : appliquer migration 032 |
| Cross-domain _fbp lost keybuzz.pro / client.keybuzz.io | structurel | Meta Pixel cote client.keybuzz.io pose son propre _fbp | Aucune action requise dans PH-20.9B |
| fbc reconstruction Date.now() au lieu timestamp click | mineur | Meta accepte, fbclid match primaire | Optionnel PH-20.9C ameliorer si EMQ stagne |
| EMQ score promesse | faible | Documentation explicite "amelioration directionnelle, score final visible 24-48h trafic reel" | Mesure Antoine post-deploy |
| Tests automatiques absents pour meta-capi | faible | tsc + audit bundle | Optionnel PH-20.9C ajouter jest si jamais introduit |

## ROLLBACK SOURCE

Si patch source pose probleme avant deploy (rare car aucun runtime touche) :

```bash
cd /opt/keybuzz/keybuzz-api
git revert d88aa7d0 --no-edit
git push origin ph147.4/source-of-truth
```

Apres rollback : meta-capi/emitter/create-signup reviennent a HEAD precedent 6850427c. Migration file restera dans le repo mais n affecte aucun runtime (aucune DB n a applique).

## SEQUENCING POST-PATCH (PHASES SUIVANTES)

1. **PH-20.9B-BUILD-DEV** : `GO BUILD API META CAPI EVENT MATCH QUALITY DEV PH-SAAS-T8.12AS.20.9B`
2. **PH-20.9B-MIGRATION-DEV** : appliquer migration 032 sur DB DEV (via tooling existant ou kubectl exec API DEV) AVANT deploy.
3. **PH-20.9B-PUSH-DEV** + **APPLY-DEV** : promotion image DEV.
4. **PH-20.9B-VALIDATION-DEV** : signup test + verifier delivery Meta CAPI logs (DEV destination), payload contient bien new fields.
5. **PH-20.9B-MIGRATION-PROD** : GO PROD explicit Ludovic + RGPD review confirme.
6. **PH-20.9B-BUILD-PROD** / **PUSH-PROD** / **APPLY-PROD** : standard cycle.
7. **PH-20.9B-VALIDATION-PROD** : 24-48h trafic reel, verifier EMQ Events Manager Antoine.

## CONFIRMATIONS SECURITE

- AUCUN build effectue.
- AUCUN docker push.
- AUCUN deploy DEV/PROD.
- AUCUNE migration appliquee live.
- AUCUN event Meta reel envoye.
- AUCUN faux event ajoute.
- AUCUN test register/lead/Purchase.
- AUCUN appel checkout Stripe.
- AUCUN secret/token/PGPASSWORD log.
- AUCUN PII brut dans rapport.
- AUCUN tracking ID change.
- AUCUN changement Client/Website/Admin.
- AUCUN changement CMP.
- AUCUN changement Linear statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH META CAPI EVENT MATCH QUALITY READY PH-SAAS-T8.12AS.20.9B |
| Repo touche | keybuzz-api uniquement |
| Branche | ph147.4/source-of-truth |
| Commit | d88aa7d0 push OK |
| Files patched | 4 (meta-capi.ts, emitter.ts, tenant-context-routes.ts, migrations/032_*) |
| Lines diff | +171 -5 |
| TSC noEmit project | 0 erreurs |
| Champs Meta ajoutes | fn, ln, ph, external_id, client_ip_address, client_user_agent, event_source_url |
| Migration | additive nullable, non appliquee |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-SOURCE-PATCH-01.md` |

### Prochaine phrase GO attendue

`GO BUILD API META CAPI EVENT MATCH QUALITY DEV PH-SAAS-T8.12AS.20.9B`

GO Ludovic requis pour confirmer :
1. RGPD review IP/UA capture (probablement deja couvert CMP) ;
2. Migration 032 sera appliquee DB DEV avant deploy image API DEV ;
3. Pas de test_event_code en PROD sans plan dedie.

STOP. Aucun build. Aucun docker push. Aucun deploy. Aucun event Meta reel. Aucune migration appliquee live.
