# PH-SAAS-T8.12AS.20.14B-VERIFY-AMAZON-INBOUND-VALIDATION-PROD-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14 / PH-20.14A / PH-20.14B
> Phase : PH-SAAS-T8.12AS.20.14B-VERIFY-AMAZON-INBOUND-VALIDATION-PROD
> Environnement : PROD (READ-ONLY STRICT ; aucune mutation)

## 1. Verdict

GO READONLY VERIFY AMAZON INBOUND VALIDATION PROD DONE KEY-323 -- RESULTAT : VALIDATION NON ABOUTIE

Les 3 adresses Amazon restent PENDING (lastInboundAt=null). Aucune n est passee VALIDATED. La boucle self-test de validation NE s est PAS executee de bout en bout : aucune ligne OutboundEmail creee, aucun SMTP self-test, aucun retour webhook, aucune transition VALIDATED. Mail stable (containment KEY-323 tient). Aucune mutation effectuee.

NE PAS enchainer sur le retry outbound (PH-20.14C) : aucune adresse VALIDATED. Le pipeline de validation lui-meme presente un gap (jobsWorker OUTBOUND_EMAIL_SEND absent + table OutboundEmail vide) a diagnostiquer avant tout nouveau trigger.

PH-20.13B push Client reste SUSPENDU.

## 2. Preflight + mail gate

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| infra main | 73c1dff | OK |
| API / outbound-worker / backend PROD | 1/1 | OK |
| mail-core postfix | active | OK |
| mail-core queue | drainage continu (1910 -> 1118) | STABLE |
| 454/421 storm | 0 | CONTENU |
| transport inbound.keybuzz.io | -> webhook: | PRESERVE |

## 3. Etat DB des adresses (product DB lue par le worker, read-only)

| Ref | Tenant masque | Pays | validationStatus | lastInboundAt | updatedAt |
|---|---|---|---|---|---|
| A3 | ecomlg-mot... | FR | PENDING | null | 2026-05-25T14:02:43 (touche) |
| A1 | bon-kb-mos... | ES | PENDING | null | 2026-05-06 (inchange) |
| A2 | bon-kb-mos... | FR | PENDING | null | 2026-05-06 (inchange) |

Total amazon : PENDING=3, VALIDATED=8 (inchange). Seul ecomlg-mot FR a un updatedAt recent (14:02) ; bon-kb-mos non touches -> trigger limite a ecomlg-mot FR. Mais updatedAt bump SANS validationStatus->VALIDATED ni lastInboundAt -> ce n est PAS une validation aboutie (probablement un re-sync channel via activate-amazon ON CONFLICT updatedAt=NOW()).

## 4. Preuves self-test (read-only)

| Preuve attendue | Observe | Verdict |
|---|---|---|
| Ligne OutboundEmail "KeyBuzz Validation" creee | OutboundEmail table VIDE (0 ligne, tout historique) | ABSENT |
| Log backend send-validation / Queued email | aucun (API pod, 30 min) | ABSENT |
| SMTP sortant self-test mail-core (validator@ / amazon.*) | aucun (12 min) | ABSENT |
| relay=webhook retour validation | aucun | ABSENT |
| processValidationEmail -> VALIDATED | aucun | ABSENT |

## 5. Gap pipeline identifie (cause probable)

| Composant | Etat observe | Impact |
|---|---|---|
| sendValidationEmail -> OutboundEmail.create | table OutboundEmail VIDE | aucun email de validation cree |
| jobsWorker (dist/workers/jobsWorker.js, traite OUTBOUND_EMAIL_SEND) | AUCUN process dans le pod API ; aucun deploy backend ne lance jobsWorker | meme si enqueue, l email ne partirait pas |
| backfill-scheduler deploy | ImagePullBackOff (v1.0.42-...-prod) | deploy backend casse (a verifier si lie aux jobs) |
| Route send-validation | aucun hit dans les logs API | trigger UI n a pas (ou pas abouti) atteint sendValidationEmail |

Interpretation : le pipeline de validation inbound Amazon (UI -> send-validation -> OutboundEmail -> jobsWorker -> SMTP self-test -> webhook -> VALIDATED) n est pas operationnel de bout en bout en PROD. Le mail-core (KEY-323) est repare/contenu, mais la jambe applicative (creation OutboundEmail + worker d envoi) ne fonctionne pas dans l etat actuel.

## 6. Non-regression

| Check | Etat | Verdict |
|---|---|---|
| mail-core storm | 0 nouveau 454/421 | STABLE |
| inbound.keybuzz.io webhook | preserve | OK |
| MX mail-mx-01/02 | non touches | INTACT |
| Amazon PENDING/VALIDATED | 3 / 8 (inchange) | OK |
| outbound_deliveries | non touche | OK |
| Guard outbound / From contract | inchange | PRESERVE |

## 7. No fake metrics / events

Aucun flip DB, aucun fake validation, aucun fake webhook, aucun OutboundEmail force. Toutes les preuves sont des lectures reelles (DB SELECT, logs, postqueue). validationStatus reflete l etat reel (NON valide).

## 8. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Mutation DB / flip VALIDATED | OUI | SELECT only |
| retry outbound / send-validation / message marketplace | OUI | 0 |
| Postfix/MX/DNS/postsuper/postqueue -f | OUI | 0 |
| build/push/deploy/kubectl mutation | OUI | 0 (kubectl cp script read-only + rm, exec node read-only) |
| secret/PII brut / DATABASE_URL affiche | OUI | connectionString non imprime, emails masques |
| Push Client PH-20.13B | OUI | suspendu |
| Bastion install-v3 + IP internes | OUI | verifie |

## 9. Gaps / questions ouvertes

- jobsWorker (OUTBOUND_EMAIL_SEND) : ou doit-il tourner en PROD ? Deploy manquant/casse (backfill-scheduler ImagePullBackOff) ?
- OutboundEmail vide all-time : le flow de validation actuel ecrit-il bien dans cette table, ou un autre mecanisme ? (les 8 VALIDATED historiques datent de jan-mars, pipeline d alors).
- Le trigger UI de Ludovic a-t-il retourne une erreur (404 no connection / 500) ? A confirmer cote UI.
- Propagation backend Prisma -> product DB (worker) : non testable tant que rien ne valide.

## 10. Rollback

N/A - phase read-only, aucune mutation.

## 11. Prochaine phrase GO recommandee

GO READONLY TRACE AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14B-PIPE

Objet : diagnostiquer en read-only pourquoi la validation ne s execute pas (jobsWorker OUTBOUND_EMAIL_SEND deploy/etat, table OutboundEmail jamais ecrite, route send-validation reponse, deploy backfill-scheduler ImagePullBackOff), AVANT tout nouveau trigger. Ne PAS retry outbound, ne PAS flip DB. Outbound Amazon reste bloque (guard correct) tant qu aucune adresse n est VALIDATED legitimement.

STOP.
