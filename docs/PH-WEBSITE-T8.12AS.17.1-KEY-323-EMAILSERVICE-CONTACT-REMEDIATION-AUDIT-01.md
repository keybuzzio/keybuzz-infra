# PH-WEBSITE-T8.12AS.17.1-KEY-323-EMAILSERVICE-CONTACT-REMEDIATION-AUDIT-01

> Date : 2026-05-15
> Linear : KEY-323 (Backlog, High, related KEY-322)
> Phase : AS.17.1 emailService + contact form remediation audit
> Environnement : DEV + PROD audit read-only, aucune mutation, aucun secret lu

---

## VERDICT

GO PARTIAL KEY-323 AUDIT READY WITH BLOCKERS

Audit read-only complet. Cause racine confirmee : mail.keybuzz.io
(49.13.35.167) repond plus sur aucun port SMTP (25/587/465/2525) depuis
bastion ET pod cluster. Egress Hetzner port 25 OK (smtp.gmail.com:25
joignable depuis bastion), donc le probleme est cote SERVEUR mail
KeyBuzz, pas cote firewall sortie.

Impact global confirme : aucun email envoye avec succes (PROD logs
Email sent = 0 sur fenetre 50000 lignes / 24h). emailService est partage
par 6 modules + 12 call sites incluant flux critiques SaaS (billing,
lifecycle, outbound worker marketplace, invitations auth). Tous casses,
pas seulement contact form.

Patch local contact form (destinataire info@keybuzz.pro) sans risque,
mais ne resout pas le bug global emailService.

Remediation provider doit etre decidee separement par Ludovic. Aucun
patch, build, deploy, secret ou changement Linear effectue. NO GO PROD
PROMOTION AS.17.0 + AS.17.0.1 maintenu.

---

## Preflight (E0)

| Surface | Verifie | Resultat |
|---|---|---|
| Bastion identite | hostname + IP | install-v3 / 46.62.171.61 |
| keybuzz-api branche/HEAD | git rev-parse | ph147.4/source-of-truth / 7a09c00 |
| keybuzz-api worktree | git status | dirty (dist/* tracked deletions, build artefacts, hors scope audit) |
| keybuzz-website branche/HEAD | git rev-parse | main / f5c2b260 (clean, post AS.17.0.1) |
| keybuzz-infra branche/HEAD | git rev-parse | main / a486ee89 (clean, post RCA push) |
| API DEV runtime | kubectl spec.image | v3.5.190-channels-tenantguard-dev (pods Ready 1/1) |
| API PROD runtime | kubectl spec.image | v3.5.190-channels-tenantguard-prod (pods Ready 1/1) |
| website DEV runtime | kubectl spec.image | v0.6.14-cta-tracking-pass-dev |
| website PROD runtime | kubectl spec.image | v0.6.13-clarity-website-prod (pre-AS.17.0, non promu) |

---

## RCA reread (E1)

Rapport AS.17.0.1-RCA present :
`keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.0.1-RCA-CONTACT-SENDEMAIL-DEV-PROD-01.md`
commit a486ee89.

Confirme : AS.17.0 (CTA tracking) et AS.17.0.1 (contact API URL env-driven)
techniquement valides cote routing/CORS/source. Aucun rapport avec le bug
sendEmail downstream. NO GO PROD promotion maintenu.

Note : memoire personnelle agent `project_key323_contact_sendemail_ko.md`
est dans C:\Users\ludov\.claude\... (pas dans AI_MEMORY/ keybuzz-infra).
Si necessaire de la promouvoir vers AI_MEMORY pour visibilite equipe,
phase separee.

---

## E2 - Call graph emailService

6 modules consomment `sendEmail` / `emailService` (11 call sites
sendEmail + 1 getEmailServiceStatus) :

| Module | Fichier | Lignes | Type email | Criticite | Risque si provider change |
|---|---|---|---|---|---|
| Auth invites | src/modules/auth/space-invites-routes.ts | 4, 78 | invitation seller a tenant | Haute (onboarding) | Casse l'onboarding si provider KO |
| Debug email-test | src/modules/debug/email-test.ts | 7, 44 | endpoint debug DEV-only | Faible | Hors PROD |
| Contact form | src/modules/public/contact.ts | 8, 110 | lead marketing public | Haute (lead gen) | Casse capture lead website |
| Trial lifecycle | src/modules/lifecycle/trial-lifecycle.service.ts | 20, 285 | emails J+N trial (rappels, fin essai) | Tres haute (revenue) | Casse upsell automatique |
| Billing | src/modules/billing/routes.ts | 10, 1025, 1066, 1823 | echecs prelevement, dunning, factures | Tres haute (revenue + cash collection) | Clients ne savent pas que CB est rejetee |
| Outbound worker | src/workers/outboundWorker.ts | 9, 359, 469, 621 | replies marketplace clients vers seller | Tres haute (SAV operationnel) | Casse SAV Inbox replies cote vendeur |

Tous les call sites passent un objet typique `{ to, subject, html, text,
from?, replyTo?, headers? }`. Aucun caller ne specifie le provider.

`getEmailServiceStatus()` exporte au worker un health-check (smtp.configured,
ses.configured, host, port, region) sans appeler reellement. Lecture des
env vars uniquement.

---

## E3 - Source emailService

Fichier `src/services/emailService.ts` (PH11-SES-01 + PH15) 10.8 KB.

### Architecture

Primary `SMTP` (nodemailer) -> fallback `AWS SES` (@aws-sdk/client-ses) si SMTP throw.

Exception : si `email.to.includes("@marketplace.amazon")` (replies Amazon
marketplace) -> SES bypass force, SMTP only. Si SMTP echoue : retourne
success=false sans tenter SES (logiquement, SES ne peut pas livrer aux
adresses Amazon internes).

### Flow

1. Try sendViaSMTP(email)
2. On success : return { success:true, provider:"SMTP", messageId }
3. On error :
   - if isAmazonAddress : return { success:false, provider:"SMTP", error }
   - else try sendViaSES(email)
     - on success : return { success:true, provider:"SES", messageId }
     - on error : return { success:false, provider:"SES",
       error: "SMTP: ${smtpError.message} | SES: ${sesError.message}" }

### Configuration source

SMTP_CONFIG (lecture process.env) :
- host : SMTP_HOST || "localhost"
- port : parseInt(SMTP_PORT || "587", 10)
- secure : SMTP_SECURE === "true"
- auth : if SMTP_USER && SMTP_PASS, else undefined
- rejectUnauthorized : SMTP_TLS_REJECT_UNAUTHORIZED !== "false"
- pool : true, maxConnections : 5
- timeouts : connectionTimeout 10s, greetingTimeout 5s, socketTimeout 30s
- from default : "KeyBuzz" <noreply@keybuzz.io>

SES_CONFIG (lecture process.env) :
- accessKeyId : AWS_SES_ACCESS_KEY_ID
- secretAccessKey : AWS_SES_SECRET_ACCESS_KEY
- region : AWS_SES_REGION || "eu-west-1"
- fromEmail : AWS_SES_FROM_EMAIL || "noreply@keybuzz.io"

Healthcheck `getEmailServiceStatus()` : retourne { smtp: { configured,
host, port, tlsRejectUnauthorized }, ses: { configured, region } }.

### Failure behaviors documentees

| Provider | Behavior si echec |
|---|---|
| SMTP | Throw vers caller emailService (sendViaSMTP), catche par main sendEmail() |
| SES manquant credentials | getSesClient() throw "AWS SES credentials not configured" |
| SES API call error | catche par main sendEmail(), retourne { success:false, provider:"SES", error } |
| Combined log line | "[Contact] Failed to send email: SMTP: ... | SES: AWS SES credentials not configured" |

### Risks identifies

- Pas de retry per attempt (un seul shot)
- Pas de circuit breaker (chaque appel retente SMTP meme si echoue 100x)
- Pas de queue durable (si crash entre validation et send, perte)
- Pas de feature flag pour forcer un provider
- Pas de monitoring/alerting structure (depend de logs)
- Pool nodemailer maxConnections 5 partage entre TOUS les callers (contact + billing + worker + lifecycle + invites + debug)

---

## E4 - Runtime env names (DEV + PROD)

Aucune valeur affichee. Source spec.template.spec.containers[0].env name only.

| Env var | DEV present | PROD present | Source visible |
|---|---|---|---|
| SMTP_HOST | OUI | OUI | env literale (pas valueFrom) |
| SMTP_PORT | OUI | OUI | env literale |
| SMTP_SECURE | OUI | OUI | env literale |
| SMTP_TLS_REJECT_UNAUTHORIZED | OUI | OUI | env literale |
| SMTP_FROM | OUI | OUI | env literale |
| SMTP_USER | NON | NON | absent |
| SMTP_PASS | NON | NON | absent |
| AWS_SES_ACCESS_KEY_ID | NON | NON | absent |
| AWS_SES_SECRET_ACCESS_KEY | NON | NON | absent |
| AWS_SES_REGION | NON | NON | absent (default eu-west-1) |
| AWS_SES_FROM_EMAIL | NON | NON | absent (default noreply@keybuzz.io) |
| CONTACT_FORM_RECIPIENT | NON | NON | env-var locale non implementee (proposition) |
| SMTP_FORCE_FAIL | NON | NON | absent (DEV-only test flag) |

envFrom (secret/configmap names) : aucun.

Constat structurel :
- SMTP_HOST literal dans le manifest deployment (pas en secret -> valeur
  publiquement lisible dans le repo keybuzz-infra). Hors scope diagnostic
  de lire le manifest mais le pattern est explicite.
- SMTP_USER/SMTP_PASS absents -> SMTP sans auth (compatible avec un mail
  server interne ouvert sur port submission sans auth).
- AWS SES totalement absent -> fallback inoperant pour TOUS les flux non
  Amazon.

---

## E5 - SMTP network probes (read-only, aucun mail envoye)

### TCP probes vers 49.13.35.167 (mail.keybuzz.io confirme par DNS reverse)

| Source | Port | Resultat | Duree |
|---|---|---|---|
| Bastion install-v3 | 25 | TIMEOUT | >5s |
| Bastion install-v3 | 587 | TIMEOUT | >4s |
| Bastion install-v3 | 465 | TIMEOUT | >4s |
| Bastion install-v3 | 2525 | TIMEOUT | >4s |
| Pod API PROD | 25 | TIMEOUT (Node.js net) | 5s |

### Controles egress Hetzner (test hosts externes neutres)

| Cible | Port | Resultat |
|---|---|---|
| 8.8.8.8 | 53 (DNS) | OK |
| smtp.gmail.com | 587 | OK |
| smtp.gmail.com | 25 | OK |

**Conclusion E5 : le bastion sort sur port 25 vers Internet sans blocage
Hetzner. Le timeout vers 49.13.35.167:25 / 587 / 465 / 2525 vient donc
du SERVEUR mail.keybuzz.io lui-meme** (down, iptables, firewall serveur)
**et non d'une regle egress sortie Hetzner**.

DNS resolution OK : mail.keybuzz.io -> 49.13.35.167.

---

## E6 - Logs historiques emailService

### API DEV (deploy/keybuzz-api ns keybuzz-api-dev, tail 50000)

| Pattern | Count DEV |
|---|---|
| [Contact] | 0 |
| [EmailService] | 0 |
| SMTP failed | 0 |
| SES credentials | 0 |
| SMTP sending | 0 |
| Email sent | 0 |
| Failed to send email | 0 |
| outboundWorker | 0 |
| trial-lifecycle | 0 |

Note : pods DEV ages (2026-05-14T21:17 et 2026-05-15T10:59) -> fenetre
courte. Soit pas d'activite email DEV recente, soit logs trop courts pour
voir.

### API PROD (deploy/keybuzz-api ns keybuzz-api-prod, tail 50000)

| Pattern | Count PROD |
|---|---|
| [Contact] | 1 |
| [EmailService] | 8 |
| SMTP failed | 1 |
| SES credentials not configured | 2 |
| SMTP sending | 1 |
| Email sent | 0 |
| Failed to send email | 1 |
| outboundWorker | 0 |
| trial-lifecycle | 0 |

### Interpretation PROD

- [Contact] = 1 occurrence = mes propres curls + QA Ludovic tentative.
- [EmailService] = 8 occurrences = traces sendEmail diverses (sending,
  failed, fallback SES, etc.).
- SMTP sending = 1, SMTP failed = 1 : symetrie attendue (1 tentative qui
  echoue). Email sent = 0 -> AUCUN email envoye avec succes sur la fenetre.
- SES credentials not configured = 2 : SES fallback throw 2 fois (1 par
  tentative POST + 1 dans la phrase combined log).
- Failed to send email = 1 : reponse 500 retournee a 1 client (la requete
  ma QA RCA).
- outboundWorker / trial-lifecycle = 0 : ces workers n'ont pas appele
  emailService sur la fenetre (soit pas declenches, soit pas de traces
  par leurs noms). Pods PROD ages 6h-10h -> fenetre courte.

### Conclusion E6

Aucun email PROD envoye avec succes sur la derniere fenetre observable.
Impact global confirme : pas seulement contact form, l'ensemble des flux
email passant par emailService est casse depuis au moins le dernier
redemarrage pod.

Si billing/lifecycle/outbound worker tentent un envoi, ils echouent
silencieusement (logs seulement). Aucune metrique d'alerte presente.

---

## E7 - Patch local contact recipient : options comparees

Hardcode actuel :
- src/modules/public/contact.ts line 111 : `to: 'contact@keybuzz.pro'`
- src/modules/public/contact.ts line 120 : log "to contact@keybuzz.pro"
- src/modules/public/contact.ts line 115 : `from: 'noreply@keybuzz.io'` (a garder)

### Option 1 - Remplacement direct hardcode

| Critere | Valeur |
|---|---|
| Fichiers touches | contact.ts (2 lignes : 111, 120) |
| Risque | Nul (isole, pas d'impact emailService) |
| Avantage | Minimal, lisible, pas d'env var supplementaire |
| Inconvenient | Si destinataire change a nouveau, rebuild requis |
| Recommandation | Privilegier si destinataire stable |

### Option 2 - Env-driven CONTACT_FORM_RECIPIENT

| Critere | Valeur |
|---|---|
| Fichiers touches | contact.ts (3 lignes) + manifest API DEV + manifest API PROD (env var) |
| Risque | Faible (env var optionnelle avec default safe "info@keybuzz.pro") |
| Avantage | Pas besoin de rebuild si destinataire change, configurable per env |
| Inconvenient | Plus de surface manifest + reapply GitOps DEV puis PROD |
| Recommandation | Surdimensionne pour ce besoin actuel |

### Option 3 - Config centralisee

| Critere | Valeur |
|---|---|
| Fichiers touches | nouveau src/config/contact.ts + contact.ts + ... |
| Risque | Moyen (refactor) |
| Avantage | Centralise tous les recipients KeyBuzz (support, info, contact) |
| Inconvenient | Surdimensionne, hors scope KEY-323 |
| Recommandation | Eviter |

### Recommandation E7

**Option 1** : remplacement direct hardcode `contact@keybuzz.pro` ->
`info@keybuzz.pro` dans contact.ts lignes 111 et 120. Pas touche au from
(noreply@keybuzz.io reste valide comme expediteur SMTP technique).

Risque : zero. Le patch reste local au formulaire contact uniquement.
Aucun impact sur emailService global ni sur les 5 autres modules
consommateurs.

Limitation : ce patch ne resout PAS le bug downstream emailService. Il
permet juste que QUAND le SMTP/SES sera repare, les nouveaux emails
contact aillent vers info@keybuzz.pro et non vers contact@keybuzz.pro
trop generique.

---

## E8 - Provider remediation options

### B1 - Reparer SMTP existant (mail.keybuzz.io)

| Critere | Valeur |
|---|---|
| Scope | Infrastructure serveur mail.keybuzz.io (49.13.35.167) |
| Risque SaaS | Nul si serveur revient en etat fonctionnel (architecture inchangee) |
| Time-to-fix | Court si simple restart/firewall. Indetermine si hardware/DNS |
| Secrets | Aucun secret a changer (SMTP sans auth actuellement) |
| Tests | Test TCP probe + envoi email DEV controle |
| Avantage | Aucun changement code, aucun changement provider, infra historique a refonctionner |
| Inconvenient | Necessite acces au serveur 49.13.35.167 + diagnostic infra. Reputation historique a verifier (deliverability) |
| Recommandation | Premier essai si serveur peut etre relance rapidement |

### B2 - Configurer SES fallback (en attendant SMTP fix)

| Critere | Valeur |
|---|---|
| Scope | Secrets API DEV + PROD (AWS_SES_ACCESS_KEY_ID, AWS_SES_SECRET_ACCESS_KEY) + validation domaine SES |
| Risque SaaS | Moyen-haut. Ludovic a documente que SES historique = reputation/deliverability insuffisante. Re-activer aveuglement peut casser deliverability. Aussi : SES bypass pour emails Amazon marketplace force par code (bonne pratique deja en place) |
| Time-to-fix | Moyen. Necessite compte AWS actif, domaine verifie SES, ouverture sandbox SES si applicable |
| Secrets | AWS_SES_ACCESS_KEY_ID + AWS_SES_SECRET_ACCESS_KEY (secret k8s) |
| Tests | Test envoi DEV controle vers info@keybuzz.pro + verification headers SPF/DKIM/DMARC |
| Avantage | Architecture deja code-ready. Fallback automatique des que SMTP echoue. Resilient. |
| Inconvenient | Reputation SES (historique KeyBuzz). Necessite verification domaine cote AWS. Pas garantie de meilleure deliverability que SMTP |
| Recommandation | Bon plan B si B1 indisponible. A activer DEV avant PROD. |

### B3 - Migration provider HTTP API moderne

Options : Resend, Postmark, Mailgun, SendGrid.

| Critere | Valeur |
|---|---|
| Scope | Reecriture emailService partielle ou complete |
| Risque SaaS | TRES HAUT si remplace emailService global (6 modules + 12 sites). Risque de regression billing/lifecycle/outbound worker/invites |
| Time-to-fix | Long (audit + tests + DEV + PROD) |
| Secrets | API key provider (un secret par env) |
| Tests | Test exhaustif par module consommateur, monitoring deliverability |
| Avantage | Provider moderne, deliverability + monitoring + analytics + webhooks status. Robuste contre infra interne KO |
| Inconvenient | Migration globale = risque + temps. Cout subscription |
| Recommandation | A garder en option strategique LONG TERME, pas pour fix urgent KEY-323 |

### B4 - Isoler le contact form avec provider dedie

| Critere | Valeur |
|---|---|
| Scope | Contact form uniquement (1 module). Nouveau provider HTTP API isole de emailService |
| Risque SaaS | Nul pour autres modules. emailService inchange |
| Time-to-fix | Moyen. Necessite nouveau secret API + integration |
| Secrets | API key provider (1 secret par env, isole contact) |
| Tests | Test contact form DEV uniquement |
| Avantage | Decouple lead gen marketing du pipeline SaaS. Si emailService casse a nouveau, contact form continue. |
| Inconvenient | Doubles up infra email (2 providers a maintenir). Cout supplementaire. Architecture moins simple |
| Recommandation | Bon plan tactique court terme si Ludovic veut isoler le lead gen marketing du SaaS operationnel |

### Recommandation E8

Sequence proposee (sans engager) :
1. B1 d'abord (verifier le serveur mail.keybuzz.io 49.13.35.167) -
   minimal disruption, infra historique.
2. Si B1 indisponible / >2h : activer B2 (SES) en DEV pour debloquer
   contact form rapidement, valider deliverability test.
3. B4 (provider isole contact) si Ludovic veut decoupler durablement le
   lead gen du SaaS et eviter de toucher emailService.
4. B3 (migration globale) hors scope KEY-323, decision strategique
   separee.

---

## E9 - Plan de correction propose

Sub-phases AS.17.1A-E (zero action effectuee dans ce rapport).

### AS.17.1A - Patch local contact recipient DEV

| Etape | Action | Pre-conditions |
|---|---|---|
| 1 | Patch contact.ts lignes 111+120 contact@ -> info@keybuzz.pro | GO Ludovic |
| 2 | Commit + push keybuzz-api ph147.4/source-of-truth | GO Ludovic |
| 3 | Build API DEV from-git tag versionne (proposition v3.5.191-contact-recipient-info-dev) | GO Ludovic |
| 4 | docker push DEV | GO Ludovic |
| 5 | GitOps DEV apply | GO Ludovic |
| 6 | Verifier triplet coherent + log "to info@keybuzz.pro" sur prochain submit | post-deploy |
| 7 | Important : ne prouve PAS l'envoi reel tant que SMTP/SES casse. Validation = log line uniquement |

Risque : tres faible (patch isole). Mais ne suffit pas seul.

### AS.17.1B - Decision provider (B1/B2/B3/B4)

Decision business + technique Ludovic. Hors execution CE.

### AS.17.1C - DEV provider fix selon decision B*

| Sous-cas | Action |
|---|---|
| B1 | Diagnostiquer + reparer serveur 49.13.35.167. Hors GitOps. |
| B2 | Generer credentials AWS SES, ajouter secret k8s keybuzz-api-dev, manifest envFrom, GitOps apply, test envoi DEV controle vers info@keybuzz.pro contenu "TEST DEV - ignorer" |
| B4 | Integrer provider HTTP API isole contact.ts, secret k8s contact-form-provider-dev, manifest, GitOps |

### AS.17.1D - PROD provider fix selon decision B*

GO Ludovic separe + rollback documente + monitoring.

### AS.17.1E - Promote AS.17.0 + AS.17.0.1 PROD

GO separe si contact form vert. Ou decouplage AS.17.0 (CTA tracking) en
PROD independamment du fix contact form si Ludovic decide d'accepter le
risque temporaire.

---

## Tests effectues (read-only synthese)

| Test | Cible | Methode | Resultat | Statut |
|---|---|---|---|---|
| Health API DEV | api-dev.keybuzz.io/health | curl | 200 | PASS |
| Health API PROD | api.keybuzz.io/health | curl | 200 | PASS |
| TCP mail.keybuzz.io:25 bastion | 49.13.35.167:25 | bash /dev/tcp | TIMEOUT | EXPECTED (cause racine) |
| TCP mail.keybuzz.io:587 bastion | 49.13.35.167:587 | bash /dev/tcp | TIMEOUT | EXPECTED |
| TCP mail.keybuzz.io:465 bastion | 49.13.35.167:465 | bash /dev/tcp | TIMEOUT | EXPECTED |
| TCP mail.keybuzz.io:2525 bastion | 49.13.35.167:2525 | bash /dev/tcp | TIMEOUT | EXPECTED |
| TCP mail.keybuzz.io:25 pod PROD | 49.13.35.167:25 | Node net.Socket | TIMEOUT | EXPECTED |
| TCP egress neutre 8.8.8.8:53 | DNS | bash /dev/tcp | OK | proof egress fonctionnel |
| TCP egress neutre smtp.gmail.com:587 | gmail | bash /dev/tcp | OK | proof port 587 sort |
| TCP egress neutre smtp.gmail.com:25 | gmail | bash /dev/tcp | OK | proof port 25 sort (Hetzner ne bloque pas) |
| DNS mail.keybuzz.io | reverse 49.13.35.167 | nslookup | OK | proof DNS valide |
| Logs PROD Email sent succes count | tail 50000 | grep | 0 | PROVES global emailService KO |

---

## Non-regression PROD

| Surface | Etat avant | Etat apres audit |
|---|---|---|
| api.keybuzz.io ingress + pods | UP 1/1 | UP 1/1 (inchange) |
| Website PROD pods | UP | UP (inchange) |
| Linear KEY-322 | Open | Open (non touche) |
| Linear KEY-323 | Backlog High | Backlog High (non touche) |
| Branches Git | clean / a486ee89 / 7a09c00 / f5c2b260 | inchange |
| Manifests k8s | inchange | inchange |
| Secrets k8s | non lus | non lus |

Aucune mutation effectuee pendant l'audit.

---

## Brouillon commentaire Linear KEY-323 (en attente GO, NON poste)

```
Audit AS.17.1 read-only termine. Rapport docs-only :
keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1-KEY-323-EMAILSERVICE-CONTACT-REMEDIATION-AUDIT-01.md

Cause racine confirmee :
- mail.keybuzz.io (49.13.35.167) repond plus sur ports 25/587/465/2525
  depuis bastion install-v3 ET pod API PROD.
- Egress Hetzner port 25 OK (test smtp.gmail.com:25 reussi depuis bastion).
- Donc bug = serveur mail KeyBuzz down/firewall, pas blocage egress.

Impact reel : tous les flux email passant par emailService sont casses,
pas seulement le contact form. PROD logs montrent 0 email envoye avec
succes sur fenetre 50000 lignes / >6h. Impact business :
- billing : echec prelevement non communique au client (cash collection)
- lifecycle trial : rappels J+N et fin essai non envoyes (revenue)
- outbound worker : replies marketplace SAV non delivrees aux clients
- invitations seller : onboarding casse
- contact form : lead gen casse

Risque cross-module : toute modification globale emailService (provider
switch, SES reconfig, SMTP fix) doit etre auditee pour ne pas casser ces
flux SaaS critiques.

Options provider :
- B1 : reparer mail.keybuzz.io (minimal disruption, premier essai)
- B2 : configurer AWS SES fallback (rapide, mais reputation historique
  insuffisante a verifier)
- B3 : migration globale provider HTTP API (LONG terme, hors KEY-323)
- B4 : provider isole contact form (tactique court terme, decouple
  lead gen du SaaS)

Decision business actee : contact form doit envoyer vers
info@keybuzz.pro (pas contact@keybuzz.pro trop generique). Patch local 2
lignes propose dans le rapport, isole, sans risque. Mais ne suffit pas
seul tant que SMTP/SES KO.

Recommandation : essayer B1 d'abord (relancer/diagnostiquer le serveur
49.13.35.167) avant tout changement code/secret. Si B1 indisponible
sous quelques heures, activer B2 en DEV pour debloquer rapidement.

Plan de correction propose : AS.17.1A (patch recipient DEV), AS.17.1B
(decision provider), AS.17.1C (DEV provider fix), AS.17.1D (PROD provider
fix), AS.17.1E (promote AS.17.0 + AS.17.0.1 PROD).

NO GO PROD promotion AS.17.0 + AS.17.0.1 maintenu tant que contact rouge.
```

A NE PAS poster sans GO Ludovic. Pas de changement status KEY-323.

---

## Gaps restants

| Gap | Hors scope audit | Suivi |
|---|---|---|
| Acces serveur 49.13.35.167 pour diagnostic infra | Oui | Ludovic decide acces / methode |
| Reputation/deliverability historique SES KeyBuzz | Oui | A verifier avant B2 |
| Monitoring/alerting structure sur Failed to send email | Oui | A ajouter dans phase B* |
| Test envoi reel DEV vers info@keybuzz.pro | Oui | GO Ludovic separe |
| Validation domaine SES si B2 | Oui | Phase B2 |
| Cout subscription provider si B3/B4 | Oui | Decision business |
| Promotion personal memory KEY-323 dans AI_MEMORY infra | Oui | Phase doc si Ludovic veut visibilite equipe |
| Audit modules consommateurs si B3 migration globale | Oui | Phase B3 si decidee |
| Manifest website-dev env block casse (NEXT_PUBLIC_SITE_MODE etc.) | Oui | Phase "website manifest hygiene DEV/PROD" |

---

## Phrase cible finale

GO PARTIAL KEY-323 AUDIT READY WITH BLOCKERS. Cause racine = serveur
mail.keybuzz.io (49.13.35.167) injoignable sur tous ports SMTP depuis
bastion ET pod cluster, egress Hetzner OK. Impact global emailService :
0 email envoye avec succes recemment, 6 modules SaaS critiques affectes.
Patch local contact recipient info@keybuzz.pro safe (2 lignes, isole).
Remediation provider necessite decision Ludovic entre B1 (reparer mail
server), B2 (SES), B3 (migration globale - long terme), B4 (provider
isole contact). Aucun patch, build, deploy, secret, ni commentaire Linear
effectue. NO GO PROD PROMOTION AS.17.0 + AS.17.0.1 maintenu. STOP avant
toute action sans GO Ludovic explicite.

---
