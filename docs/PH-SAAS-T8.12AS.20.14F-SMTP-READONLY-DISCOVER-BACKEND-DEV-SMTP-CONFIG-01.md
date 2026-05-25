# PH-SAAS-T8.12AS.20.14F-SMTP-READONLY-DISCOVER-BACKEND-DEV-SMTP-CONFIG-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C / PH-20.14D / PH-20.14E / PH-20.14F (suspendu)
> Phase : PH-SAAS-T8.12AS.20.14F-SMTP (READ-ONLY discovery prealable a l apply jobsWorker DEV)
> Environnement : DEV (READ-ONLY STRICT ; aucun deploy, aucun secret cree, aucun trigger, aucune valeur de secret affichee)

## 1. Verdict

GO READONLY DISCOVER BACKEND DEV SMTP CONFIG DONE -- RECOMMANDATION : CAS 1 (SMTP DEV existant et reutilisable)

La config SMTP DEV legitime existe deja et tourne en production DEV via le worker sibling keybuzz-api / keybuzz-outbound-worker. Elle est reutilisable telle quelle (env inline, pas de secret) pour le jobsWorker backend. Aucune improvisation requise. PH-20.14F (apply jobsWorker) peut reprendre avec cette config SMTP explicite.

L apply du jobsWorker reste SUSPENDU jusqu au GO de reprise PH-20.14F.

## 2. Sources relues

| Source | Usage |
|---|---|
| keybuzz-backend-dev manifests + secrets (ExternalSecrets) | confirme : AUCUNE var SMTP cote backend |
| keybuzz-api-dev/deployment.yaml | SMTP inline (API) |
| keybuzz-api-dev/outbound-worker-deployment.yaml | SMTP inline (worker outbound, modele direct) |
| keybuzz-api-prod/outbound-worker-deployment.yaml | SMTP PROD = mail.keybuzz.io:25 (parite) |
| backend src/modules/outbound/outboundEmail.service.ts | vars SMTP lues : SMTP_HOST/PORT/SECURE (+USER/PASS optionnels) |

## 3. Constat backend DEV (gap)

| Element | Etat | Verdict |
|---|---|---|
| keybuzz-backend-db (DATABASE_URL + PG*) | present | DB OK |
| keybuzz-backend-secrets | JWT, internal tokens, INBOUND_WEBHOOK_KEY, MINIO, PRODUCT_DATABASE_URL | pas de SMTP |
| env inline backend API deployment | NODE_ENV, PORT, VAULT_ADDR, CLIENT_APP_URL, etc. | pas de SMTP |
| refs SMTP dans manifests backend-dev | aucune | SMTP ABSENT backend |

Consequence sans config : sendViaSMTP ferait defaut a localhost:587 -> echec. Le jobsWorker doit recevoir une config SMTP explicite.

## 4. Source de verite SMTP DEV (existante, reutilisable)

Le worker sibling keybuzz-outbound-worker (namespace keybuzz-api-dev, image keybuzz-api, command node dist/workers/outboundWorker.js) configure SMTP en ENV INLINE (valeurs plain, PAS des secrets) :

| Variable | Valeur DEV | Source |
|---|---|---|
| SMTP_HOST | 49.13.35.167 | keybuzz-api-dev outbound-worker + API deployment |
| SMTP_PORT | 25 | idem |
| SMTP_SECURE | false | idem |
| SMTP_TLS_REJECT_UNAUTHORIZED | false | idem (var specifique API ; NON lue par le backend) |
| SMTP_FROM | "KeyBuzz" <noreply@keybuzz.io> | keybuzz-api-dev/deployment.yaml |
| SMTP_USER / SMTP_PASS | ABSENTS | relais non authentifie sur port 25 |

49.13.35.167 = IP publique de mail-core-01 (serveur mail KEY-323). Relais SMTP interne port 25, non authentifie.

Preuve d usage : keybuzz-outbound-worker DEV est Running (READY=1) avec cette config -> le relais :25 est joignable depuis le cluster.

Parite PROD : keybuzz-api-prod/outbound-worker utilise SMTP_HOST=mail.keybuzz.io:25 (meme schema, hostname au lieu d IP).

## 5. Compatibilite backend

backend sendViaSMTP (outboundEmail.service.ts) lit :
- SMTP_HOST (defaut localhost), SMTP_PORT (defaut 587), SMTP_SECURE (=="true"), SMTP_USER+SMTP_PASS (auth seulement si les deux presents).

Les noms de variables sont identiques a ceux du worker API. La config DEV (HOST=49.13.35.167, PORT=25, SECURE=false, sans USER/PASS) est donc directement consommable par le backend. SMTP_TLS_REJECT_UNAUTHORIZED n est pas lu par le backend (sans effet, peut etre omis).

Note : pour le self-test de validation, le From est fixe par sendValidationEmail (validator@inbound.keybuzz.io) et preserve par sendOutboundEmailById -> SMTP_FROM n est qu un fallback non utilise sur ce chemin.

## 6. Recommandation (cas 1)

Reprendre PH-20.14F (apply jobsWorker DEV) avec, dans le Deployment jobs-worker :
- envFrom : secretRef keybuzz-backend-db + keybuzz-backend-secrets + vault-token (optional) (mirror backend API pour DB/Vault),
- env inline SMTP (reutilisation exacte du worker sibling) :
  - SMTP_HOST=49.13.35.167
  - SMTP_PORT=25
  - SMTP_SECURE=false
  - (SMTP_FROM facultatif pour parite ; non requis sur le chemin validation)
- command : node dist/workers/jobsWorker.js (worker:jobs),
- image : ghcr.io/keybuzzio/keybuzz-backend:v1.0.48-amazon-validation-pipeline-dev.

Cette config n est PAS une improvisation : valeurs identiques au worker outbound DEV existant et sain. Aucun secret a creer.

## 7. Dependance KEY-323 (a verifier a PH-20.14G)

La deliverabilite reelle du self-test depend de mail-core-01 (49.13.35.167:25) + du transport inbound.keybuzz.io -> webhook (preserve par KEY-323-APPLY). Le containment KEY-323 a maintenu mail-core up et le transport webhook. A re-verifier avant/apres le re-trigger PH-20.14G (mail stable, pas de nouvelle storm).

## 8. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| deploy / kubectl mutation | OUI | read-only get/jsonpath uniquement |
| creation secret | OUI | 0 |
| affichage valeur secret | OUI | seulement env plain (SMTP host/port) + noms de cles |
| invention host/port/creds | OUI | valeurs lues du worker existant |
| trigger validation / send | OUI | 0 |
| PROD mutation | OUI | 0 |

## 9. Rollback

N/A - phase read-only, aucune mutation.

## 10. Prochaine phrase GO

GO APPLY JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14F (reprise)

Avec la config SMTP cas 1 documentee en section 6 (SMTP_HOST=49.13.35.167, SMTP_PORT=25, SMTP_SECURE=false ; envFrom keybuzz-backend-db + keybuzz-backend-secrets + vault-token). Puis seulement apres worker healthy : GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14G (avec verif mail-core stable KEY-323).

STOP.
