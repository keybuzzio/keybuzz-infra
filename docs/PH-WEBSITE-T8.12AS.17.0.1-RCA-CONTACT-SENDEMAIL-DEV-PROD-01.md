# PH-WEBSITE-T8.12AS.17.0.1-RCA-CONTACT-SENDEMAIL-DEV-PROD-01

> Date : 2026-05-15
> Linear : KEY-322 (parent), ticket dedie a creer (brouillon en attente GO)
> Phase : AS.17.0.1-RCA contact form sendEmail downstream KO
> Environnement : DEV + PROD diagnostic read-only, aucune mutation

---

## VERDICT

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu tant que /contact rouge.

Cause racine identifiee, hors scope AS.17.0.1 source code : downstream
emailService SMTP + SES tous deux KO en PROD (et probablement DEV).
Bug pre-existant a AS.17.0.x, expose par la QA Ludovic post-AS.17.0.1.

AS.17.0 (CTA tracking pass website) et AS.17.0.1 (contact API URL
env-driven website) techniquement valides cote routing/CORS/source.
Aucun rollback recommande.

---

## Preflight (read-only)

| Repo | Branche | HEAD | Etat |
|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 7a09c0058b383196681af68a472d8610ca8ce254 | clean |
| keybuzz-website | main | f5c2b260a4022faac630d601fdd9445bb390fb70 | clean (post AS.17.0.1) |
| keybuzz-backend | main | b183817d3bf6e708896d8fe65f34e1ca1d08ae27 | clean (hors scope) |
| keybuzz-infra | main | cc489e3560ad96f9409949f435454f3d835c1b44 | clean (post AS.17.0.1 manifest bump) |

Bastion : install-v3 (46.62.171.61). Aucun secret lu. Aucun deploiement.

---

## Symptome observe (QA Ludovic)

Surface : preview.keybuzz.pro/contact (DEV) ET keybuzz.pro/contact (PROD direct).

Action : submit form avec payload valide via navigateur (champs name, email,
subject, message remplis avec contenu reel).

Resultat UI : alerte rouge "Erreur de connexion. Veuillez reessayer." au-dessus
du champ Nom complet. Pas de message succes. Reproductible DEV ET PROD.

Network DevTools : non capture par Ludovic (HTTP code et body inconnus).

Hypothese client-side : ce message provient EXCLUSIVEMENT du bloc catch (err)
dans src/app/contact/page.tsx, jamais du else qui afficherait "Une erreur est
survenue. Veuillez reessayer." (= data.error retourne par API).

Lecture catch :
- Le fetch() lui-meme a throw (network failure cote browser, timeout, abort,
  certificate, CORS browser-side, mixed content), OU
- res.json() a throw (reponse vide ou non-JSON).

---

## Diagnostic D1-D11 (read-only, payload invalide uniquement)

### D1 - Source endpoint API

Fichier : src/modules/public/contact.ts (PH26-CONTACT-01)
Route Fastify : app.post('/api/public/contact', ...)
Registration : src/app.ts:51 (import) + src/app.ts:208 (mount comment)

Comportement :
- Rate limit : 5 par IP par 10 min (in-memory)
- Honeypot : champ body.website (silent reject avec 200 success si rempli)
- Validation server-side :
  * name >= 2 chars sinon 400 "Nom requis (min 2 caracteres)"
  * email regex sinon 400 "Email invalide"
  * subject >= 3 chars sinon 400 "Sujet requis (min 3 caracteres)"
  * message >= 10 chars && <= 5000 sinon 400 "Message ..."
- Envoi : sendEmail() vers services/emailService
  * destinataire HARDCODE : to: 'contact@keybuzz.pro' (line 111)
  * expediteur : 'noreply@keybuzz.io'
  * replyTo : body.email
- Succes : reply.send({ success: true })
- Echec sendEmail : reply.status(500).send({ error: 'Erreur lors de
  lenvoi. Veuillez reessayer.' })
- Exception : reply.status(500).send({ error: 'Erreur interne. Veuillez
  reessayer plus tard.' })

### D2 - Ingress runtime API DEV + PROD

| Env | Namespace | Ingress | Host | LB IP |
|---|---|---|---|---|
| DEV | keybuzz-api-dev | keybuzz-api | api-dev.keybuzz.io | 10.111.50.244 |
| PROD | keybuzz-api-prod | keybuzz-api | api.keybuzz.io | 10.111.50.244 |

### D3 - CORS preflight tests (curl externe depuis bastion)

| Origin | Cible | OPTIONS HTTP | allow-origin echo |
|---|---|---|---|
| https://preview.keybuzz.pro | api-dev.keybuzz.io/api/public/contact | 204 | https://preview.keybuzz.pro |
| https://www.keybuzz.pro | api.keybuzz.io/api/public/contact | 204 | https://www.keybuzz.pro |
| https://keybuzz.pro | api.keybuzz.io/api/public/contact | 204 | https://keybuzz.pro |

allow-methods : GET, POST, PATCH, PUT, DELETE, OPTIONS
allow-credentials : true
allow-headers : Content-Type, Authorization, X-KB-Debug, stripe-signature,
                X-User-Email, X-Tenant-Id

CORS gere par @fastify/cors (pas annotations ingress). Origins website
preview.keybuzz.pro (DEV) et www.keybuzz.pro / keybuzz.pro (PROD) acceptes.

### D4 - POST minimal payload invalide (zero email envoye)

| Env | Methode | Body | HTTP | Response body |
|---|---|---|---|---|
| DEV | POST | {} | 400 | {"error":"Nom requis (min 2 caracteres)"} |
| PROD | POST | {} | 400 | {"error":"Nom requis (min 2 caracteres)"} |
| DEV | GET | n/a | 404 | Route non declaree (POST uniquement) |

Validation server-side opere identiquement DEV et PROD.

### D5 - Health probes

| Env | URL | HTTP |
|---|---|---|
| DEV | /health | 200 |
| PROD | /health | 200 |

API service operationnel.

### D6 - Source emailService (PH11-SES-01 + PH15-AMAZON-OUTBOUND-DELIVERY-01)

Fichier : src/services/emailService.ts (10869 bytes)

Architecture :
- Primary : SMTP via nodemailer (host:port depuis env SMTP_HOST/SMTP_PORT)
- Fallback : AWS SES (region eu-west-1) si SMTP throw
- Lazy init transporter SMTP avec pool=true, maxConnections=5
- Timeouts : connectionTimeout 10s, greetingTimeout 5s, socketTimeout 30s

Env vars consommees (sans lire valeurs) :
- SMTP : SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS, SMTP_FROM,
  SMTP_TLS_REJECT_UNAUTHORIZED
- SES : AWS_SES_ACCESS_KEY_ID, AWS_SES_SECRET_ACCESS_KEY, AWS_SES_REGION,
  AWS_SES_FROM_EMAIL

### D7 - Env vars deployment API DEV + PROD (noms seuls, valeurs NON lues)

DEV (kubectl -n keybuzz-api-dev get deploy keybuzz-api -o jsonpath env) :
- SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_TLS_REJECT_UNAUTHORIZED, SMTP_FROM

PROD (kubectl -n keybuzz-api-prod get deploy keybuzz-api) :
- SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_TLS_REJECT_UNAUTHORIZED, SMTP_FROM

Constat : AWS_SES_* totalement ABSENTES des deux deployments. SMTP_USER /
SMTP_PASS aussi absents (donc SMTP auth = undefined dans transporter,
acceptable si serveur ne demande pas d'auth).

### D8 - Logs API PROD : preuve formelle cause racine

Extract logs deploy/keybuzz-api ns keybuzz-api-prod :

  [EmailService] Sending email to contact@keybuzz.pro via SMTP...
  [EmailService] SMTP sending to contact@keybuzz.pro from noreply@keybuzz.io
                 via 49.13.35.167:25
  [EmailService] SMTP failed: Connection timeout
  [Contact] Failed to send email: SMTP: Connection timeout |
                                  SES: AWS SES credentials not configured

Conclusion :
- SMTP primary : timeout connection sur 49.13.35.167:25 (port 25, non securise)
- SES fallback : throw "AWS SES credentials not configured" car
  AWS_SES_ACCESS_KEY_ID absent du deployment
- API retourne 500 avec {"error":"Erreur lors de lenvoi. Veuillez reessayer."}

### D9 - Logs API DEV

Tail fenetre courte : pas de trace [Contact] / [EmailService] recente.
Requete POST 188.245.45.242 -> /api/public/contact bien recue (req-379).
Suite execution sendEmail non visible dans la fenetre tail (probablement
hors window ou tentative anterieure a la rotation logs).

Hypothese : meme architecture SMTP/SES en DEV, donc meme echec attendu.
A confirmer par logs DEV plus large ou par tentative reelle controlee (hors
scope read-only).

### D10 - Decalage UX cote client

API renvoie 500 avec body JSON {"error":"Erreur lors de lenvoi..."}. Le code
client src/app/contact/page.tsx attend :

  if (res.ok && data.success) { ... succes }
  else { setErrorMsg(data.error || "Une erreur est survenue..."); }

Si la reponse 500 + body JSON arrive entiere au browser, l'UI doit afficher
"Erreur lors de lenvoi. Veuillez reessayer." (data.error), pas "Erreur de
connexion. Veuillez reessayer." (catch).

Ludovic voit "Erreur de connexion" = catch. Causes possibles :
- (a) la requete fetch() est interrompue cote browser ou ingress avant que
  le 500+body soient delivres (timeout proxy, keep-alive coupe, browser
  abort sur duree elevee)
- (b) la reponse 500 arrive avec body vide ou non-JSON, et res.json() throw
- (c) erreur CORS browser-side (rare avec preflight 204 + allow-origin OK)
- (d) mixed content, ad blocker, CSP browser-side

Sans capture DevTools Network, impossible de differencier (a) vs (b) vs (c)
vs (d). Hypothese principale : (a) timeout cumule SMTP 10-30s + ingress
nginx proxy-read-timeout. Hypothese secondaire : (b) reponse partielle.

### D11 - Cartographie usages sendEmail dans keybuzz-api

| Caller | Fichier | Lignes | Type |
|---|---|---|---|
| Auth invitations | src/modules/auth/space-invites-routes.ts | 4, 78 | feature |
| Debug | src/modules/debug/email-test.ts | 7, 44 | DEV-only debug |
| Contact form | src/modules/public/contact.ts | 8, 110 | feature |
| Trial lifecycle | src/modules/lifecycle/trial-lifecycle.service.ts | 20, 285 | feature critical |
| Billing | src/modules/billing/routes.ts | 10, 1025, 1066, 1823 | feature critical |
| Outbound worker | src/workers/outboundWorker.ts | 9, 359, 469, 621 | feature critical (Inbox replies) |

Total : 6 modules + 11 call sites consomment emailService. Tout fix global
emailService (SMTP, SES, provider switch) impacte ces 6 modules. Hors scope
fix minimal contact form.

### D12 - Audit hardcodes contact@keybuzz.pro

keybuzz-api (recipients SMTP) :
- src/modules/public/contact.ts:111  to: 'contact@keybuzz.pro'  [HARDCODE]
- src/modules/public/contact.ts:120  log "to contact@keybuzz.pro"  [HARDCODE]

keybuzz-api ailleurs : aucun autre hardcode contact@keybuzz.pro recipient.

keybuzz-website (mailto: et affichage public, pas envoi) :
- src/app/legal/page.tsx:146         mailto affichage
- src/app/sla/page.tsx:292           mailto affichage
- src/app/terms/page.tsx:319         mailto affichage
- src/app/contact/page.tsx:132-133   mailto affichage (panneau coordonnees)

keybuzz-backend (Prisma) :
- src/modules/outbound/outboundEmail.service.ts : sendEmail interne backend
  (pas le meme service que keybuzz-api), aucun contact@keybuzz.pro

info@keybuzz.pro : 0 occurrence dans keybuzz-api, keybuzz-website,
keybuzz-backend. Adresse non encore utilisee dans le code.

---

## Cause racine

Pipeline contact form casse au stade downstream sendEmail :

1. Website -> POST /api/public/contact OK (CORS, routing, validation OK)
2. API contact.ts -> sendEmail(...) OK
3. emailService SMTP -> tente 49.13.35.167:25 -> TIMEOUT 10s+
4. emailService SES fallback -> THROW "AWS SES credentials not configured"
5. contact.ts catche l'echec -> retourne 500 + body JSON
6. Cote client : fetch() ou res.json() throw (sub-cause exacte indeterminee
   sans DevTools Network capture)
7. UI affiche "Erreur de connexion. Veuillez reessayer." (message catch)

Bug PRE-EXISTANT a AS.17.0.x. AS.17.0.1 a expose ce probleme via la QA
Ludovic, mais ne l'a pas cree. Le hardcode contact@keybuzz.pro et la config
SMTP/SES sont anterieurs.

---

## Patch propose (en attente GO Ludovic, hors scope ce rapport)

### Fix LOCAL au formulaire contact (destinataire info@keybuzz.pro)

Fichier : keybuzz-api src/modules/public/contact.ts

| Ligne | Avant | Apres | Impact |
|---|---|---|---|
| 111 | to: 'contact@keybuzz.pro', | to: 'info@keybuzz.pro', | destinataire form contact uniquement |
| 120 | log "to contact@keybuzz.pro" | log "to info@keybuzz.pro" | log message |

Risque : nul (changement isole, 2 lignes, pas d'impact sur emailService global,
pas d'impact sur les 5 autres modules consommateurs). Hors scope : autres
hardcodes mailto: affichage public (legal, sla, terms, contact page coordonnees)
restent contact@keybuzz.pro pour l'instant. A decider separement.

Alternative possible (non recommandee pour fix minimal) : rendre le
destinataire env-driven via CONTACT_FORM_RECIPIENT ou similaire. Avantage :
flexibilite. Inconvenient : ajout d'un env var + manifest + secret/configmap
=> moins minimal. A garder en option si besoin futur.

### Ce qui N'EST PAS resolu par ce fix destinataire seul

Le bug SMTP + SES KO reste entier. Changer destinataire info@keybuzz.pro
n'envoie pas l'email tant que SMTP/SES ne fonctionnent pas. Le fix downstream
provider est un SUJET SEPARE (option B du diagnostic) a traiter dans un
ticket dedie : reparer SMTP host 49.13.35.167:25 OU configurer AWS SES
credentials OU migrer provider (Resend, Postmark, Mailgun, SendGrid) selon
decision separee Ludovic.

---

## Tests effectues (read-only)

| Test | Origin | Cible | Methode | Body | HTTP attendu | HTTP recu | Statut |
|---|---|---|---|---|---|---|---|
| T1 | preview.keybuzz.pro | api-dev.keybuzz.io/api/public/contact | OPTIONS | n/a | 204 | 204 | PASS |
| T2 | www.keybuzz.pro | api.keybuzz.io/api/public/contact | OPTIONS | n/a | 204 | 204 | PASS |
| T3 | keybuzz.pro | api.keybuzz.io/api/public/contact | OPTIONS | n/a | 204 | 204 | PASS |
| T4 | preview.keybuzz.pro | api-dev.keybuzz.io/api/public/contact | POST | {} | 400 | 400 | PASS |
| T5 | www.keybuzz.pro | api.keybuzz.io/api/public/contact | POST | {} | 400 | 400 | PASS |
| T6 | n/a | api-dev.keybuzz.io/health | GET | n/a | 200 | 200 | PASS |
| T7 | n/a | api.keybuzz.io/health | GET | n/a | 200 | 200 | PASS |

Aucun payload valide envoye. Aucun email reel cree.

---

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres diagnostic |
|---|---|---|
| api.keybuzz.io ingress | UP | UP (inchange) |
| keybuzz-api-prod pods | Running 1/1 | Running 1/1 (inchange) |
| /health | 200 | 200 (inchange) |
| /api/public/contact validation | 400 sur invalide | 400 sur invalide (inchange) |
| keybuzz-website-prod | UP | UP (non touche) |
| Linear KEY-322 | Open | Open (aucun comment poste) |

Aucune mutation pendant le diagnostic. Diagnostic 100% read-only.

---

## Linear (brouillon, en attente GO)

Ticket Linear dedie a creer (brouillon, NE PAS publier sans GO Ludovic) :

Titre propose :
  Contact form sendEmail downstream KO DEV+PROD : SMTP timeout + SES not configured

Description proposee :
  Issue parente : KEY-322
  Surface : keybuzz.pro/contact et preview.keybuzz.pro/contact
  Symptome : submit form -> alerte rouge "Erreur de connexion. Veuillez
             reessayer." (catch fetch cote client)
  Cause racine : downstream emailService SMTP+SES tous deux KO
    - SMTP primary : Connection timeout 49.13.35.167:25
    - SES fallback : AWS_SES_ACCESS_KEY_ID absent des deployments
                     keybuzz-api-dev et keybuzz-api-prod
  Bug pre-existant a AS.17.0.x, expose par QA Ludovic post-AS.17.0.1.
  Aucun rapport avec AS.17.0 (CTA tracking) ni AS.17.0.1 (contact API
  URL env-driven).
  Rapport diagnostic complet :
    keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.0.1-RCA-CONTACT-SENDEMAIL-DEV-PROD-01.md
  Decisions a prendre :
    (1) Fix LOCAL minimal : change destinataire contact@keybuzz.pro vers
        info@keybuzz.pro dans contact.ts (2 lignes, hors scope downstream)
    (2) Fix downstream : choisir 1 parmi
        - reparer SMTP host 49.13.35.167:25 (infra/firewall/mail server)
        - configurer AWS SES credentials (secret keybuzz-api-* / value)
        - migrer vers provider HTTP API (Resend / Postmark / Mailgun /
          SendGrid) avec audit usages 6 modules consommateurs
    (3) Ameliorer UX client : distinguer "network failure" vs "API 500 avec
        body" dans le catch (cosmetique, optionnel)
    (4) Monitoring : alerte sur log "[Contact] Failed to send email"
  Priorite : haute (impact direct lead generation marketing)
  NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu tant que contact form
  rouge.

---

## Gaps restants

| Gap | Hors scope diagnostic | A traiter |
|---|---|---|
| Capture DevTools Network du symptome QA reel | Oui | Optionnel : si refaire QA pour confirmer hypothese (a) timeout vs (b) body vide. Sinon dispensable car cause racine etablie cote API/logs PROD |
| Decision provider email (reparer SMTP vs configurer SES vs migrer) | Oui | Ticket Linear dedie + decision Ludovic |
| Manifest env block keybuzz-website-dev casse (NEXT_PUBLIC_SITE_MODE sans value, NEXT_PUBLIC_CLIENT_APP_URL duplicate key) | Oui | Phase dediee "website manifest hygiene DEV/PROD" |
| Helper website src/lib/tracking.ts sans consent check (pre-existant AS.17.0) | Oui | Phase future post AS.17.0 |
| Autres usages emailService (auth invites, trial, billing, outbound worker) potentiellement impactes par meme SMTP/SES KO | Oui | Audit dans ticket dedie provider, hors AS.17.0.x |
| mailto: affichage public contact@keybuzz.pro sur legal/sla/terms/contact pages | Oui | Decision separee Ludovic si tout doit basculer vers info@keybuzz.pro |

---

## Phrase cible finale

NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu. Cause racine SMTP+SES KO
identifiee avec preuve logs PROD. Fix destinataire contact.ts vers
info@keybuzz.pro propose comme patch minimal isole, en attente GO Ludovic.
Fix downstream provider hors scope, ticket Linear dedie a creer. STOP avant
tout patch, build, deploy, secret ou comment Linear engageant.

---
