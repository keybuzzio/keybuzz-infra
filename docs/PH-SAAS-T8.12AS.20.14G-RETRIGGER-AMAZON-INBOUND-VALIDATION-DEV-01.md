# PH-SAAS-T8.12AS.20.14G-RETRIGGER-AMAZON-INBOUND-VALIDATION-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C-BIS / PH-20.14F-BIS / PH-20.14F-SMTP
> Phase : PH-SAAS-T8.12AS.20.14G-RETRIGGER-AMAZON-INBOUND-VALIDATION-DEV
> Environnement : DEV uniquement (une adresse, trigger legitime)

## 1. Verdict

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PARTIAL PH-SAAS-T8.12AS.20.14G

Le trigger a ete effectue via le flow DEV authentifie legitime (header X-User-Email, DEV-mode du produit, sans forge ni secret). La route a authentifie et trouve la connexion, mais le pipeline est bloque en amont du jobs-worker par une DERIVE DE SCHEMA Prisma<->DB : `prisma.outboundEmail.create()` echoue avec "column toAddress does not exist". La colonne reelle de la DB est `to` ; le champ Prisma `toAddress` n a PAS de `@map("to")`. Donc aucun OutboundEmail cree, aucun job OUTBOUND_EMAIL_SEND enqueue, le jobs-worker n a rien traite, l adresse reste PENDING. Aucun fake, aucun flip DB, aucun AMAZON_POLL consomme, mail-core stable. Cette derive est PRE-EXISTANTE et independante des patchs PH-20.14C..F (qui sont corrects vis-a-vis du schema).

## 2. Sources relues

PH-20.14F-BIS (jobs-worker scope deploye), PH-20.14F-SMTP (SMTP DEV), PH-20.14C-BIS (scope JOB_TYPES), PH-20.14B-PIPE (root cause initiale), KEY-323-APPLY (mail-core). Source : amazon.routes.ts (route send-validation = devAuthenticateOrJwt), devAuthMiddleware.ts, inboundEmailValidation.service.ts, outboundEmail.service.ts, prisma/schema.prisma.

## 3. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 | 46.62.171.61 | OK |
| infra | main / HEAD 40c3fb4 | OK |
| jobs-worker DEV | Running, 0 restart, scope types=OUTBOUND_EMAIL_SEND | OK |
| mail-core-01 | postfix active, queue stable | OK |

## 4. Snapshot before

| Source | Before |
|---|---|
| inbound_addresses amazon DEV | 35 PENDING (lowercase) + 4 VALIDATED + 4 PENDING (uppercase) |
| Job OUTBOUND_EMAIL_SEND | 9 DONE / 16 FAILED / 0 PENDING-RETRY |
| OutboundEmail (tenant_test_dev) | 9 |
| AMAZON_POLL lockedBy jobs-worker | 0 |

## 5. Adresse cible

| Ref | Tenant | Country | Email masque | Status | Choisie |
|---|---|---|---|---|---|
| A | tenant_test_dev | FR | amazon.<tenant>.fr.812g37@inbound.keybuzz.io | PENDING | OUI |

Connexion amazon cmk5caxwe0... (tenant_test_dev), 1 seule adresse FR PENDING, lastInboundAt=null. Tenant de test interne non critique. Seul candidat ayant un user en DB (requis par DEV-mode requireDbUser=true).

## 6. Auth / flow legitime

| Element | Valeur | Verdict |
|---|---|---|
| Endpoint | POST /api/v1/marketplaces/amazon/inbound-address/send-validation (backend DEV) | OK |
| Methode | node http vers 127.0.0.1:4000 dans le pod backend (route interne) | OK |
| Auth | devAuthenticateOrJwt Path 2 DEV-mode : header X-User-Email=dev@keybuzz.io, KEYBUZZ_DEV_MODE=true, user resolu en DB (requireDbUser=true) | LEGITIME |
| Tenant cible | tenant_test_dev (du user dev@keybuzz.io, SUPER_ADMIN) | OK |
| Payload | {"country":"FR"} | OK |
| Pourquoi pas un bypass | mecanisme DEV documente du produit (le BFF l utilise) ; pas de JWT forge, pas de secret lu, pas de bypass auth, pas d appel direct a sendValidationEmail | OK |

## 7. Trigger

| Ref | Trigger time (UTC) | HTTP | Response (redacted) | Verdict |
|---|---|---|---|---|
| A | 20:17:43 | 500 | "Failed to send validation email" / "column toAddress does not exist in the current database" | CHAIN BREAK |

## 8. OutboundEmail / Job

| Objet | Avant | Apres | Delta | Verdict |
|---|---|---|---|---|
| OutboundEmail (tenant_test_dev) | 9 | 9 | 0 | create() a echoue avant insert |
| Job OUTBOUND_EMAIL_SEND actif (PENDING/RETRY/RUNNING) | 0 | 0 | 0 | aucun job enqueue |
| jobs-worker logs (Processing/sent) | aucun | aucun | - | worker non sollicite |

## 9. SMTP / webhook

Aucun SMTP self-test (aucun OutboundEmail a envoyer). Aucun retour webhook. mail-core sans nouveau 421/454. Non applicable : le chain casse avant la creation de l email.

## 10. DB validation

| Ref | Status before | Status after | lastInboundAt | Verdict |
|---|---|---|---|---|
| A | PENDING | PENDING | null -> null | NON VALIDATED (chain break amont) |

Pas de flip DB. VALIDATED count amazon inchange.

## 11. Root cause (drift schema)

Colonnes reelles DEV DB OutboundEmail : id, tenantId, ticketId, **to**, from, subject, body, provider, status, error, sentAt, createdAt, updatedAt.
Schema Prisma : champ `toAddress String` SANS `@map("to")`.
-> Prisma genere un INSERT/SELECT sur une colonne `toAddress` inexistante. La colonne historique est `to`.

Impact : casse TOUTE ecriture/lecture OutboundEmail via Prisma (sendValidationEmail create, sendEmail create, sendOutboundEmailById select). C est la raison de fond pour laquelle OutboundEmail est quasi-vide/fige et la validation n a jamais aboutie. Les 9 lignes historiques datent d avant le renommage `to`->`toAddress` (commit sans @map ni migration). Pre-existant ; les patchs PH-20.14C..F (logique worker) sont corrects vis-a-vis du schema mais reposent sur ce mapping casse. PROD a la meme colonne `to` (vu en PH-20.14B-PIPE) -> meme drift.

Correctif recommande (le plus propre, conserve les donnees) : ajouter `@map("to")` au champ `toAddress` dans prisma/schema.prisma -> prisma generate -> tsc -> rebuild image -> redeploy keybuzz-backend (API) ET jobs-worker. Alternative (migration rename to->toAddress) plus risquee (colonne SQL + PROD), non recommandee.

## 12. Non-regression

| Check | Before | After | Verdict |
|---|---|---|---|
| jobs-worker healthy | Running | Running 0 restart | OK |
| AMAZON_POLL claim par jobs-worker | 0 | 0 | OK |
| OutboundEmail tenant | 9 | 9 | OK (aucun email) |
| adresse cible | PENDING | PENDING | OK (pas de flip) |
| mail-core | active/stable | active/stable | OK |
| outbound_deliveries / marketplace | non touche | non touche | OK |
| PROD | non touche | non touche | OK |

## 13. Anti-regression / AI feature parity

| Feature | Contrat | Change | Verdict |
|---|---|---|---|
| Amazon outbound From / guard VALIDATED | inchange, non bypasse | aucun | PRESERVE |
| Inbound webhook reel | non sollicite (chain amont) | aucun | PRESERVE |
| PH-20.11C / PH-20.12B | inchange | aucun | PRESERVE |
| PH-20.13B Client | suspendu | non repris | SUSPENDU |
| outbound deliveries | non retry | aucun | PRESERVE |

## 14. No fake metrics / events

Aucun fake validation/webhook/OutboundEmail/delivery. Aucun flip DB. Le 500 et l etat PENDING refletent l etat reel (chain break). validationStatus reflete la realite (NON valide).

## 15. Interdits respectes

PROD non touche ; pas de SQL UPDATE/INSERT ; pas de fake webhook ; pas de forge JWT / secret / bypass (DEV-mode documente) ; pas d appel direct sendValidationEmail ; pas de build/deploy/GitOps dans cette phase ; une seule requete, une seule adresse.

## 16. Gaps

- Drift schema OutboundEmail.toAddress (manque @map("to")) : bloque tout le pipeline OutboundEmail (DEV et PROD). A corriger avant tout re-trigger ou promotion.
- A verifier : autres modeles/champs renommes sans @map (audit cible OutboundEmail uniquement ici ; les autres champs OutboundEmail matchent).
- 34 autres adresses amazon DEV PENDING non testees (hors scope : une adresse a la fois).

## 17. Prochaine phrase GO

GO SOURCE PATCH OUTBOUNDEMAIL SCHEMA MAP DEV PH-SAAS-T8.12AS.20.14C-TER

Patch source minimal : ajouter `@map("to")` au champ toAddress de prisma/schema.prisma (keybuzz-backend), prisma generate + tsc + tests, build-from-git (tag v1.0.50-...), push, redeploy keybuzz-backend (API) + jobs-worker DEV, PUIS re-trigger PH-20.14G (re-essai sur tenant_test_dev). NE PAS proposer GO PROMOTE PROD : la validation DEV n est PAS aboutie (adresse PENDING). NE PAS retry outbound marketplace. NE PAS flip DB.

STOP.
