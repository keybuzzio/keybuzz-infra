# PH-SAAS-T8.12AS.20.14-READONLY-INCIDENT-AMAZON-OUTBOUND-DELIVERY-BLOCKED-PROD-01

> Date : 2026-05-25
> Linear : KEY-337 parent PH-20 (incident) ; references KEY-231 / KEY-263 / KEY-302 / KEY-312 / KEY-323 / KEY-348 / KEY-349
> Phase : PH-SAAS-T8.12AS.20.14-READONLY-INCIDENT-AMAZON-OUTBOUND-DELIVERY-BLOCKED-PROD
> Environnement : PROD READ-ONLY INCIDENT AUDIT (aucune mutation, aucun deploy, aucun retry, aucun message marketplace)

## 1. Verdict

GO READONLY INCIDENT AMAZON OUTBOUND DELIVERY BLOCKED PROD READY PH-SAAS-T8.12AS.20.14

Cause probable identifiee avec preuves. Le blocage outbound Amazon ne touche PAS tout Amazon : il est limite a des tenants dont l adresse inbound Amazon est en statut PENDING (jamais VALIDATED). Le guard outbound bloque correctement, par design. La cause racine sous-jacente est que la validation de l adresse inbound n a jamais aboutie (lastInboundAt = null : aucun email entrant de validation recu), ce qui est coherent avec la panne du serveur mail mail.keybuzz.io (KEY-323).

PH-20.13B push Client reste SUSPENDU. Aucune action de remediation executee dans cette phase.

## 2. Resume executif

- 4 deliveries Amazon ont echoue dans les dernieres 24h, toutes avec la meme erreur : "Amazon inbound address not validated - configure and validate in Settings > Channels".
- Ces 4 deliveries appartiennent a UN SEUL tenant (masque : ecomlg-m...).
- Ce tenant possede une unique adresse inbound Amazon en statut PENDING (jamais VALIDATED). lastInboundAt = null.
- Le worker tente l envoi via SMTP unifie (AMAZON_SPAPI_MESSAGING_ENABLED=false par design), exige une adresse inbound Amazon VALIDATED comme From, n en trouve aucune, et bloque (throw) AVANT toute tentative SMTP reelle.
- Le reste d Amazon fonctionne : 271 deliveries Amazon historiques en statut delivered sur 4 tenants (dernier livre le 2026-05-22), grace a 8 adresses inbound Amazon VALIDATED.
- Donc : ce n est PAS une regression globale, ni un bug de code, ni un mauvais tenantId. C est un blocage de configuration / validation de canal pour des tenants recents.
- Observation secondaire : le CronJob outbound-tick-processor tape POST https://api.keybuzz.io/debug/outbound/tick qui repond 404 (route absente), mais le worker poll en propre (OUTBOUND_POLL_INTERVAL_MS=2000) donc le tick casse n est PAS la cause du blocage.

## 3. Incident scope

- Service : keybuzz-outbound-worker, namespace keybuzz-api-prod, pod keybuzz-outbound-worker-7bfb4944c4-tnsl6.
- Canal : amazon uniquement (aucune autre activite outbound en 24h).
- Tenants impactes (masques) : ecomlg-m... (4 deliveries failed, attempt_count=5). Un second tenant bon-kb-m... a aussi des adresses Amazon PENDING (ES + FR) mais sans delivery failed dans la fenetre 24h.
- Portee : PARTIELLE / par tenant. PAS "tout Amazon PROD".

## 4. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| Date UTC | 2026-05-25 11:33 | OK |
| Infra HEAD | main e906d49 dirty 0 | OK |
| API source | ph147.4/source-of-truth 38c048c0 = origin, src dirty 0 | OK |
| Client source preserve | ph148 ef239e8, dirty 1 (tsconfig.tsbuildinfo) | OK (preserve) |
| Deploy keybuzz-api | 1/1 Running | OK |
| Deploy keybuzz-outbound-worker | 1/1 Running (2 restarts il y a 2j4h) | OK |
| Image worker runtime | ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod | OK |
| Image api runtime | ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod | OK |
| CronJob outbound-tick-processor | */1 * * * *, jobs Complete | OK (mais route cible 404) |

## 5. Logs evidence

Logs worker (tail 5000), signaux masques :

| Signal | Count/sample | Verdict |
|---|---|---|
| AMAZON_SPAPI_MESSAGING_ENABLED=false | present (repete) | flag SP-API desactive (design) |
| Using UNIFIED SMTP for Amazon | 20 | fallback SMTP unifie actif |
| Amazon inbound address not validated | 20 | guard bloque |
| delivered | 0 | aucune livraison reussie dans la fenetre |
| SMTP failed | 0 | jamais arrive au SMTP (bloque avant) |
| SP-API failed | 0 | SP-API non emprunte |
| orderIds observes | 4 distincts (407-...-7741964, 406-...-7910768, 407-...-8465119, 403-...-3946703) | 4 deliveries rejouees en boucle |

CronJob tick jobs (3 derniers) : "Route POST:/debug/outbound/tick not found","statusCode":404 -> tick inoperant, mais worker independant.

## 6. Code path evidence

src/workers/outboundWorker.ts (HEAD 38c048c0 ; messages identiques au runtime v3.5.165) :

- L16 : const AMAZON_SPAPI_MESSAGING_ENABLED = process.env.AMAZON_SPAPI_MESSAGING_ENABLED === 'true' (false si absent).
- L252-265 : getInboundAddressForTenant -> SELECT "emailAddress" FROM inbound_addresses WHERE "tenantId"=$1 AND marketplace='amazon' AND "validationStatus"='VALIDATED' ORDER BY "updatedAt" DESC LIMIT 1 ; retourne null si aucune ligne.
- L331-335 : inboundFromAddress = getInboundAddressForTenant(...) ; GUARD : if (!inboundFromAddress) throw new Error("Amazon inbound address not validated - configure and validate in Settings > Channels").
- L438-457 : si AMAZON_SPAPI_MESSAGING_ENABLED && orderId -> SP-API (legacy, desactive) ; sinon si handle @marketplace.amazon -> "Using UNIFIED SMTP for Amazon" -> sendAmazonViaSMTP (qui applique le guard ci-dessus).

Manifest worker (k8s/keybuzz-api-prod/outbound-worker-deployment.yaml) : variable AMAZON_SPAPI_MESSAGING_ENABLED ABSENTE -> defaut false (coherent design). env SMTP_HOST=mail.keybuzz.io, SMTP_PORT=25, SMTP_SECURE=false.

Doctrine produit respectee par le code : pour Amazon, le From doit etre l adresse inbound auto-generee VALIDATED du tenant ; pas d envoi si non validee ; pas de bypass.

## 7. DB aggregate evidence

Requetes SELECT only, executees dans le pod worker (env implicite PG*), masquage tenant/id, aucun email/corps/token affiche, script supprime apres execution. DB : keybuzz.

| Table | Check | Result | Verdict |
|---|---|---|---|
| outbound_deliveries | deliveries 24h channel/provider/status | amazon / spapi / failed = 4 (seule activite) | blocage isole |
| outbound_deliveries | last_error 24h | "Amazon inbound address not validated..." = 4 | cause unique |
| outbound_deliveries | amazon recent masque | 4 rows, tenant ecomlg-m..., attempt_count=5, provider=spapi (valeur enqueue, pas runtime) | 1 tenant |
| outbound_deliveries | amazon all-time par statut | delivered=271 (4 tenants, dernier 2026-05-22) ; failed=9 (2 tenants, 2026-05-15 -> 2026-05-25) | systeme fonctionnel hors PENDING |
| inbound_addresses | amazon par validationStatus | VALIDATED=8 (4 tenants) ; PENDING=3 (2 tenants) | 4 tenants OK, 2 bloques |
| inbound_addresses | join deliveries amazon 24h -> inbound status | tenant ecomlg-m..., failed, inbound_status=PENDING, n=4 | correlation directe |
| inbound_addresses | detail PENDING amazon | 3 rows (ecomlg-m... FR ; bon-kb-m... ES + FR), tous lastInboundAt=null, lastError vide | validation jamais aboutie |

Note provider : les lignes failed portent provider='spapi' (valeur posee a l enqueue), alors que le runtime a choisi la branche SMTP unifie ; le provider runtime n est jamais persiste car le throw intervient avant l envoi. provider='spapi' n est donc PAS une preuve d usage SP-API.

## 8. Impact

| Scope | Count | Evidence | Verdict |
|---|---|---|---|
| Tout Amazon PROD | non | 271 delivered sur 4 tenants, dernier 2026-05-22 | NON impacte globalement |
| Tenant unique (ecomlg-m...) | 4 deliveries / 24h | Q4 + Q5 join inbound PENDING | P0 tenant (messages bloques) |
| Second tenant PENDING (bon-kb-m...) | 0 failed 24h, 2 adresses PENDING | detail PENDING | a risque (canal non valide) |
| Adresse inbound presente mais non VALIDATED | 3 adresses PENDING / 2 tenants | inbound_addresses | cause de configuration / canal |
| SP-API disabled fallback SMTP | flag false par design | manifest + code | comportement attendu (non bug) |

## 9. Root cause probable

Chaine causale :

1. DIRECT : le tenant ecomlg-m... n a aucune adresse inbound Amazon VALIDATED (1 seule adresse, en PENDING). getInboundAddressForTenant retourne null -> le guard L335 throw -> 0 envoi. C est le candidat 2 du prompt (adresse presente mais non VALIDATED). Le guard fonctionne comme prevu (doctrine produit : pas d envoi sans From valide).

2. POURQUOI PENDING : lastInboundAt = null sur les 3 adresses PENDING -> aucun email entrant de validation n a jamais ete recu. La validation d une adresse inbound Amazon se fait par reception d un email a l adresse auto-generee KeyBuzz (route via mail.keybuzz.io). Sans email entrant, le statut reste PENDING.

3. SOUS-JACENT PROBABLE : la reception d email entrant depend de mail.keybuzz.io, identifie HS dans l incident KEY-323 (serveur mail down). Les 8 adresses VALIDATED datent d avant la panne (dernier updatedAt 2026-03-30) ; les 3 PENDING ont ete creees les 2026-05-05/06 (apres) et n ont jamais recu d email -> validation impossible. Forte coherence temporelle : KEY-323 (mail HS) bloque la validation inbound -> bloque l outbound Amazon des tenants recents.

4. RISQUE COMPLEMENTAIRE : meme si le guard etait satisfait, l envoi outbound passe par SMTP mail.keybuzz.io:25 (down per KEY-323). Donc deux blocages dependants du serveur mail se superposent ; restaurer mail.keybuzz.io adresse les deux.

NON retenus : candidat 1 (adresse absente : faux, l adresse existe) ; candidat 3 (mismatch tenantId : faux, le join correle exactement) ; candidat 4 (champ marketplace/status different : non, marketplace='amazon' correct, status simplement PENDING) ; candidat 6 (regression code large : faux, 271 livraisons historiques OK, code inchange).

## 10. Remediation options

| Option | Type | Risk | Requires GO |
|---|---|---|---|
| A - Reparer / restaurer mail.keybuzz.io (KEY-323) puis re-declencher validation inbound | Infra mail | moyen (depend KEY-323) | OUI (phase dediee) |
| B - Investiguer le flow de validation inbound Amazon (route validation, dependance lastInboundAt, pipeline) en read-only avant tout fix | Audit cible | faible (read-only) | OUI (PH-20.14A) |
| C - Validation manuelle / admin de l adresse (Settings > Channels) si le flow le permet sans email | Action produit/admin | moyen | OUI |
| D - Flip DB validationStatus PENDING->VALIDATED | Mutation DB | ELEVE (bypass guardrail, From non verifie) | NON recommande (viole doctrine) |
| E - SP-API messaging (AMAZON_SPAPI_MESSAGING_ENABLED=true) | Runtime/manifest/deploy | ELEVE (scopes SP-API, audit complet requis) | NON sans audit dedie |
| F - Retry / mark delivered des 4 deliveries bloquees | Mutation queue | ELEVE | NON (phase dediee post-fix, avec GO) |
| G - Corriger CronJob outbound-tick (route 404) | Manifest cron | faible | optionnel (non bloquant) |

Recommandation : ne PAS bypasser le guardrail (option D refusee). Prioriser l investigation read-only du flow de validation (option B) en lien avec la restauration mail (KEY-323, option A). Aucun retry avant fix valide.

## 11. Actions interdites non realisees

| Interdit | Respecte | Preuve |
|---|---|---|
| Patch source | OUI | 0 modification (lecture seule) |
| Build / docker push | OUI | 0 |
| Deploy / kubectl apply / set / patch / edit | OUI | 0 |
| Rollout restart | OUI | 0 |
| Changement manifest | OUI | 0 (lecture grep uniquement) |
| Retry outbound / simulate delivery | OUI | 0 |
| Message marketplace | OUI | 0 |
| Mutation DB / outbound_deliveries / inbound_addresses | OUI | requetes SELECT only, scripts supprimes |
| Appel API validation envoyant un email | OUI | 0 |
| LLM / KBActions | OUI | 0 |
| Fake event / metric | OUI | 0 |
| Secret / token affiche | OUI | aucun (env names only, jamais PGPASSWORD) |
| Lecture /opt/keybuzz/credentials ou secrets | OUI | 0 |
| Dump env pod complet | OUI | filtre noms de variables uniquement |
| PII brute (email/handle/order/body) | OUI | tenant/id/orderId masques ou tronques, email jamais selectionne |
| Changement statut Linear / creation ticket | OUI | 0 / 0 |
| Push GHCR Client PH-20.13B | OUI | suspendu, non repris |
| Bastion install-v3 (46.62.171.61) | OUI | verifie E1 |

## 12. Linear

- KEY-337 (parent PH-20) : commentaire incident read-only (cause probable, scope, options). Aucun changement de statut.
- KEY-231 : commentaire signalant que le push PH-20.13B reste suspendu par incident prioritaire. Aucun changement de statut.
- Aucun ticket cree (KEY-323 deja ouvert pour le serveur mail ; lien a confirmer avec GO si besoin de creer un sous-ticket Amazon validation).

## 13. Rollback

N/A - phase read-only. Aucune mutation runtime/DB/manifest/Git applicative. Seul artefact : ce rapport docs commit dans keybuzz-infra/main.

## 14. Prochaine phrase GO recommandee

GO FIX AMAZON INBOUND ADDRESS VALIDATION PROD PH-SAAS-T8.12AS.20.14A

Objet : investiguer en read-only le flow de validation de l adresse inbound Amazon (route de validation, dependance email entrant / lastInboundAt, pipeline) et son couplage avec la restauration de mail.keybuzz.io (KEY-323), AVANT toute action. Ne pas flip DB. Ne pas bypasser le guardrail. Ne pas retry avant adresse VALIDATED par voie legitime.

STOP.
