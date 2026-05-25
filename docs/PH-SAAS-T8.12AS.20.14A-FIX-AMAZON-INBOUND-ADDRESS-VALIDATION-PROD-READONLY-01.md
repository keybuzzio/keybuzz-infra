# PH-SAAS-T8.12AS.20.14A-FIX-AMAZON-INBOUND-ADDRESS-VALIDATION-PROD-READONLY-01

> Date : 2026-05-25
> Linear : KEY-337 parent PH-20 ; KEY-323 mail.keybuzz.io incident ; references KEY-231 / KEY-263 / KEY-302 / KEY-312 / KEY-348 / KEY-349
> Phase : PH-SAAS-T8.12AS.20.14A-FIX-AMAZON-INBOUND-ADDRESS-VALIDATION-PROD (READ-ONLY FIRST)
> Environnement : PROD INCIDENT / READ-ONLY (aucune mutation, aucun deploy, aucun retry, aucun email envoye, aucun flip DB)

## 1. Verdict

GO FIX AMAZON INBOUND ADDRESS VALIDATION PROD READY READONLY PH-SAAS-T8.12AS.20.14A

Cause racine identifiee avec preuves et REVISEE par rapport a PH-20.14. La validation d une adresse inbound Amazon est un self-test email loop : le backend s envoie a lui-meme un email de validation via SMTP SORTANT (mail.keybuzz.io), qui doit revenir par le MX entrant (webhook /inbound-email) pour marquer VALIDATED. La jambe ENTRANTE fonctionne (webhook recoit des emails Amazon reels en ce moment). La jambe SORTANTE (SMTP send via mail.keybuzz.io) est cassee = KEY-323. Donc l email de validation ne part jamais, la boucle ne se ferme jamais, l adresse reste PENDING, et l outbound Amazon reste bloque par le guard (conforme au design).

Le blocage NE concerne PAS tout Amazon : les tenants valides avant la panne mail fonctionnent (271 deliveries delivered). Seuls 2 tenants recents (3 adresses, creees 2026-05-05/06) sont bloques.

PH-20.13B push Client reste SUSPENDU. Aucune action de remediation executee.

## 2. Resume executif

- Le flow de validation est un self-test loop (code backend confirme) :
  - `sendValidationEmail` cree un OutboundEmail (from `validator@inbound.keybuzz.io`, to l adresse inbound `amazon.<tenant>.<country>.<token>@inbound.keybuzz.io`, subject `KeyBuzz Validation <token>`) et enqueue un job `OUTBOUND_EMAIL_SEND`.
  - Le job envoie via nodemailer `host=SMTP_HOST` (mail.keybuzz.io), port 587.
  - L email revient par le MX entrant (mail-mx-01/02.keybuzz.io) -> webhook backend `POST /api/v1/webhooks/inbound-email` -> `processValidationEmail` -> `validationStatus='VALIDATED'` + `lastInboundAt`.
- La jambe ENTRANTE marche : le webhook recoit des emails Amazon reels maintenant (log PROD : `Amazon forward detected, marketplaceStatus updated for ecomlg-001/FR`, ExternalMessage crees, requetes POST recentes).
- La jambe SORTANTE est cassee : mail.keybuzz.io SMTP send = KEY-323 (timeout 49.13.35.167:25, 0 email envoye, SES fallback non configure). Bannieres SMTP absentes (mail + MX TCP ouverts mais pas de greeting applicatif).
- Resultat : l email de validation self-test ne part pas -> pas de retour -> adresse PENDING -> guard outbound bloque.
- NON bug code, NON probleme inbound, NON guard a contourner. Blocage unique = SMTP sortant (KEY-323).

## 3. PH-20.13B push suspendu

Confirme. Image Client DEV `v3.5.216-kbactions-anxiety-ux-dev` reste locale, NON pushee, NON deployee. Aucune action GHCR pendant cet incident. Reprise sur GO explicite ulterieur.

## 4. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| Date UTC | 2026-05-25 11:47 | OK |
| Infra HEAD | main 66a8423 dirty 0 | OK |
| API source | ph147.4/source-of-truth 38c048c0 = origin, src dirty 0 | OK |
| keybuzz-backend | main b183817 | OK (autorite validation) |
| Deploy keybuzz-api / outbound-worker | 1/1 / 1/1 Running | OK |

## 5. KEY-323 context

- Statut Linear : Backlog, derniere mise a jour 2026-05-17.
- Cause racine KEY-323 : SMTP primary connection timeout vers 49.13.35.167:25 ; SES fallback credentials non configures (DEV+PROD). 0 email envoye avec succes.
- Les commentaires recents (2026-05-15/16) portent surtout sur l incident securite Hetzner imbrique (containment, Vault token, SSH forensic) ; le fix du serveur mail lui-meme n est PAS marque resolu.
- mail.keybuzz.io (49.13.35.167) ports 25/587 : TCP OPEN mais AUCUNE banniere SMTP (15s) -> service SMTP degrade, coherent avec KEY-323 toujours ouvert.

## 6. Code validation flow (backend keybuzz-backend, autorite)

| Step | File/line | Behavior | Verdict |
|---|---|---|---|
| Trigger | marketplaces/amazon/amazon.routes.ts:564 | appelle sendValidationEmail(connection.id, country) | OK |
| Self-test send | inboundEmail/inboundEmailValidation.service.ts:18-70 | cree OutboundEmail from validator@inbound.keybuzz.io to l adresse inbound, subject "KeyBuzz Validation <token>", enqueue OUTBOUND_EMAIL_SEND | depend SMTP sortant |
| SMTP transport | outbound/outboundEmail.service.ts:26-115 | nodemailer host=SMTP_HOST (mail.keybuzz.io) port 587, sendMail | CASSE (KEY-323) |
| Inbound receive | webhooks/inboundEmailWebhook.routes.ts:19-179 | POST /inbound-email (auth X-Internal-Key, "Dedicated webhook endpoint for Postfix"), updateMany lastInboundAt | FONCTIONNE |
| Validate | inbound/inbound.service.ts:195-244 (processValidationEmail) | si token subject == token adresse -> validationStatus='VALIDATED' + lastInboundAt | OK (jamais atteint pour PENDING) |
| API mirror | keybuzz-api channels/channelsRoutes.ts:157-168 | INSERT inbound_addresses PENDING ; ON CONFLICT n update PAS validationStatus | mirror lecture worker |
| Guard outbound | keybuzz-api workers/outboundWorker.ts:252-335 | exige validationStatus='VALIDATED' sinon throw | conforme design |

Note : keybuzz-api n ecrit jamais validationStatus='VALIDATED' ni lastInboundAt ; c est le backend (Prisma) qui est autoritaire. Les 8 lignes VALIDATED presentes dans la product DB prouvent que la propagation backend -> product DB a fonctionne (a verifier en phase remediation que la propagation reste OK apres une nouvelle validation).

## 7. Client Settings flow

| Surface | Reference | Role |
|---|---|---|
| API trigger | keybuzz-api compat/routes.ts:154 POST /api/v1/marketplaces/amazon/inbound-address/send-validation (proxy legacy backend) | re-declenche le self-test |
| Client BFF | keybuzz-client app/api/amazon/inbound-address/send-validation/route.ts | appel UI |
| Client status | keybuzz-api messages/routes.ts:1120 GET /inbound/amazon/status | affiche validated/PENDING dans Settings > Channels |

Une action "renvoyer la validation" existe cote produit (send-validation). Elle reste inoperante tant que le SMTP sortant est casse.

## 8. Mail / DNS / port checks

| Check | Result | Verdict |
|---|---|---|
| mail.keybuzz.io A | 49.13.35.167 | resolve OK |
| keybuzz.io MX | 10 mail-mx-01, 20 mail-mx-02 | OK |
| inbound.keybuzz.io MX / A | mail-mx-01/02 / 49.13.35.167 | OK |
| mail-mx-01.keybuzz.io | 91.99.66.6 | OK |
| mail-mx-02.keybuzz.io | 91.99.87.76 | OK |
| TCP 25 (mail + mx-01 + mx-02) | OPEN | port ouvert |
| TCP 587 mail | OPEN | port ouvert |
| TCP 465 mail | CLOSED | - |
| SMTP banner (mail + mx-01, 15s) | AUCUNE banniere | service SMTP degrade |

Interpretation : ports TCP ouverts mais aucune reponse SMTP applicative -> le daemon mail ne sert pas correctement (coherent KEY-323). L inbound fonctionne malgre tout (preuve logs webhook), mais le SEND sortant echoue.

## 9. Logs evidence

- Backend PROD (keybuzz-backend-84996c47fd-rhzrf) : multiples `POST /api/v1/webhooks/inbound-email` recents ; `[Webhook] Amazon forward detected, marketplaceStatus updated for ecomlg-001/FR` ; ExternalMessage + Inbox conversation crees -> jambe ENTRANTE operationnelle.
- Aucune trace send-validation / SMTP send recente -> pas de tentative de revalidation recente (et le SEND echouerait de toute facon).
- Worker outbound PROD (PH-20.14) : `Using UNIFIED SMTP` puis `Amazon inbound address not validated` x20, 0 delivered -> bloque au guard avant SMTP.

## 10. DB masked evidence (product keybuzz DB, lue par le worker)

| Status | Count | lastInboundAt | Verdict |
|---|---|---|---|
| VALIDATED | 8 (4 tenants) | 6 non-null (mar-avr 2026), 2 null | valides AVANT panne mail, fonctionnent |
| PENDING | 3 (2 tenants) | 3 NULL | bloques, jamais valides |

Adresses PENDING (masquees) : `ecomlg-mot...` FR (creee 2026-05-06), `bon-kb-mos...` ES + FR (creees 2026-05-05/06). Toutes lastInboundAt=null, lastError vide. Le tenant `ecomlg-001` (different) est VALIDATED (IT/ES/FR) et recoit des emails en ce moment. Les VALIDATED datent du 2026-01-15 au 2026-03-30 (avant la panne mail KEY-323).

## 11. Root cause

Chaine causale confirmee :

1. Validation = self-test email loop (backend). Email de validation envoye via SMTP SORTANT mail.keybuzz.io:587, doit revenir par MX entrant -> webhook -> VALIDATED.
2. Jambe SORTANTE cassee (KEY-323) : mail.keybuzz.io SMTP send timeout, 0 email envoye. L email de validation ne part jamais.
3. Donc lastInboundAt reste null, validationStatus reste PENDING pour les adresses creees pendant/apres la panne (2026-05-05/06).
4. Le guard outbound (outboundWorker.ts) exige VALIDATED -> throw -> 0 envoi Amazon pour ces tenants. Guard conforme a la doctrine produit.
5. Jambe ENTRANTE OK (webhook recoit), donc une fois le SMTP sortant restaure + send-validation redeclenche, la boucle se fermera et l adresse passera VALIDATED.

Revision vs PH-20.14 : PH-20.14 supposait "mail.keybuzz.io down". Precision : l ENTRANT marche, c est le SORTANT (SMTP send) qui bloque la validation. Meme dependance KEY-323, diagnostic affine.

## 12. Remediation options

| Option | Action | Risk | GO required |
|---|---|---|---|
| A (recommandee) | Restaurer le SMTP SORTANT mail.keybuzz.io (KEY-323) puis redeclencher send-validation par tenant | moyen (infra mail) | OUI (KEY-323) |
| B | Verifier propagation backend -> product DB de validationStatus apres une nouvelle validation (read-only) | faible | OUI (sous-etape) |
| C | Configurer SES fallback pour outbound email (deblocage SMTP alternatif) | moyen (deliverability historique) | OUI (decision produit) |
| D | Flip DB validationStatus PENDING->VALIDATED | ELEVE (bypass guardrail, From non verifie) | NON (refuse, viole doctrine) |
| E | Retry des 4 deliveries Amazon bloquees | ELEVE | NON (post-fix dedie, avec GO) |
| F | Activer SP-API messaging (contourner SMTP) | ELEVE (scopes SP-API) | NON sans audit dedie |

Recommandation : option A. Le blocage est entierement explique par le SMTP sortant (KEY-323). Restaurer le mail sortant puis redeclencher la validation self-test. Ne pas flip DB, ne pas contourner le guard.

## 13. Recommended next GO

GO FIX MAIL SERVER MAIL.KEYBUZZ.IO PROD KEY-323

Justification : la validation inbound Amazon et l outbound Amazon dependent du meme SMTP sortant mail.keybuzz.io, casse depuis KEY-323. Restaurer ce service debloque a la fois (a) la validation self-test des adresses inbound (PENDING -> VALIDATED) et (b) l envoi outbound reel. Apres restauration : redeclencher send-validation par tenant impacte, verifier propagation product DB, puis (phase dediee, GO separe) retry des deliveries bloquees.

## 14. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Patch source / build / deploy | OUI | 0 (lecture seule) |
| kubectl apply/set/patch/edit/rollout | OUI | 0 |
| Mutation DB / UPDATE / INSERT / DELETE | OUI | requetes SELECT only, scripts supprimes |
| Flip PENDING->VALIDATED | OUI | refuse, non execute |
| Retry outbound / simulate / message marketplace | OUI | 0 |
| Email de validation envoye | OUI | 0 (aucun POST send-validation) |
| Appel POST validation | OUI | 0 |
| LLM / KBActions / fake metric | OUI | 0 |
| Secret / token affiche | OUI | aucun (noms d env uniquement, jamais SMTP_PASS/PGPASSWORD) |
| Lecture /opt/keybuzz/credentials ni secrets / dump env complet | OUI | 0 |
| PII brute (email/handle/order/body) | OUI | tenant/email tronques, jamais d email brut complet |
| Changement statut Linear / ticket | OUI | 0 / 0 |
| Push Client PH-20.13B | OUI | suspendu, non repris |
| Bastion install-v3 (46.62.171.61) | OUI | verifie E0 |

## 15. Rollback

N/A - phase read-only. Aucune mutation runtime/DB/manifest/Git applicative. Seul artefact : ce rapport docs commit dans keybuzz-infra/main.

STOP.
