# PH-SAAS-T8.12AS.20.51-READONLY-VERIFY-AMAZON-OUTBOUND-POST-OAUTH-RECONNECT-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.51 (READONLY VERIFY Amazon outbound post OAuth reconnect)
> Environnement : PROD prioritaire ; read-only strict (SELECT/logs/get/exec lecture) ; 0 mutation/0 envoi/0 fake

## 1. Verdict

GO READONLY VERIFY AMAZON OUTBOUND POST OAUTH RECONNECT READY PH-SAAS-T8.12AS.20.51

CRITICAL_FINDING : split de statut connecteur entre 2 bases. Le reconnect OAuth a bien revalide
`amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io` cote Backend (source de verite), mais le worker
outbound lit une COPIE figee dans la product DB API restee PENDING -> il bloque l'envoi avant meme
le SMTP. La reponse KeyBuzz n'atteint jamais Amazon. Ce n'est NI un probleme d'adresse From, NI un
250 OK invisible Amazon, NI SMTP : c'est un gap de synchronisation de statut entre Backend DB et
product DB API.

## 2. Rappel UX (important)

Il n'existe PAS de bouton de validation Amazon dans Channels. Ludovic a deja fait la seule action
disponible : retirer + reconnecter OAuth Amazon. Le connecteur EST valide cote Backend. La
conclusion n'est donc pas "cliquer valider" mais "reparer la synchro de statut Backend -> API DB".

## 3. Contexte utilisateur verifie

- Reconnect OAuth Amazon pour ecomlg-motxke32 -> a touche la ligne API DB a 07:51:06Z.
- Inbound SWITAA recu sur la conversation a 07:58:55Z (et 06:07:53Z) -> pipeline inbound OK.
- Reponse KeyBuzz envoyee a 08:00:01Z -> message outbound + delivery crees.
- Amazon ne montre toujours pas la reponse -> car la delivery est bloquee avant SMTP.

## 4. Runtime

| env | service | namespace | image | ready | restarts | verdict |
|---|---|---|---|---:|---:|---|
| PROD | keybuzz-api | keybuzz-api-prod | v3.5.259-...-prod | 1 | 0 | OK |
| PROD | keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | 1 | 2 (stable) | actif |
| PROD | keybuzz-backend/jobs-worker | keybuzz-backend-prod | v1.0.56-...-prod | 1 | 0 | OK |
| DEV | keybuzz-api/client | keybuzz-*-dev | v3.5.259-...-dev | 1 | 0 | OK |

## 5. Statut connecteur post OAuth reconnect (LE point cle)

| base | tenant | localpart | validationStatus | marketplaceStatus | lastInboundAt | updatedAt | lu par |
|---|---|---|---|---|---|---|---|
| Backend DB (keybuzz_backend) | ecomlg-motxke32 FR | amazon.ecomlg-motxke32.fr.as0yom | VALIDATED | VALIDATED | 2026-05-28T07:58:57Z | 07:58:57Z | UI/validation service |
| product DB API (keybuzz_prod) | ecomlg-motxke32 FR | amazon.ecomlg-motxke32.fr.as0yom | PENDING | PENDING | null | 07:51:06Z | outbound worker |

Comparaison de reference (tenant qui marche) :

| base | tenant | localpart | validationStatus |
|---|---|---|---|
| Backend DB | ecomlg-001 FR | amazon.ecomlg-001.fr.4xfub8 | VALIDATED |
| product DB API | ecomlg-001 FR | amazon.ecomlg-001.fr.4xfub8 | VALIDATED |

Classification : STATUS_SPLIT_BETWEEN_TABLES + INBOUND_ADDRESS_STATUS_SYNC_GAP +
WORKER_READS_STALE_API_DB_STATUS. Pour ecomlg-001 les deux bases sont VALIDATED (d'ou succes) ; pour
ecomlg-motxke32 la product DB API est restee PENDING.

## 6. Mecanisme (code read-only)

- keybuzz-api/src/modules/channels/channelsRoutes.ts:157 : "AM.9.1: Sync inbound addresses from
  Backend to API DB" -> INSERT inbound_addresses avec validationStatus='PENDING' ; le
  ON CONFLICT DO UPDATE met a jour connectionId/emailAddress/token/updatedAt mais PAS
  validationStatus. Aucun `UPDATE inbound_addresses SET validationStatus='VALIDATED'` dans le src
  API actif.
- keybuzz-api/src/workers/outboundWorker.ts:256 : getInboundAddressForTenant lit
  `... WHERE "tenantId"=$1 AND marketplace='amazon' AND "validationStatus"='VALIDATED'` dans la
  product DB API -> ne trouve pas la ligne PENDING -> le guard validateAmazonOutboundConfig leve
  "Amazon inbound address not validated".
- Resultat : la validation reelle vit dans le Backend (mis a jour par le reconnect + inbound), mais
  la product DB API lue par le worker n'est jamais promue a VALIDATED par la synchro actuelle.

## 7. Inbound / Outbound / Delivery (conv cmmpml7i1z7009a32c30c5de1)

| type | id | created_at | detail |
|---|---|---|---|
| inbound | cmmpp7by4y54f8c7599d720f0 | 07:58:55Z | buyer relay 43vfy...@marketplace.amazon.fr (SWITAA) -> a valide le connecteur Backend |
| outbound msg | msg-1779955201232-02kc3r5er | 08:00:01Z | "Nous avons bien pris en compte votre demande..." (Ludovic.G) = ENVOI reel |
| delivery | dlv-1779955201345-r9tmg83ka | 08:00:01Z | provider spapi, status queued, attempt 4, last_error "Amazon inbound address not validated" |

L'envoi n'est PAS un simple brouillon : il a cree message + delivery. Le worker la traite mais la
rejette (gate validation).

## 8. From / connecteur

| expected_from | observe | verdict |
|---|---|---|
| amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io | (jamais utilise : envoi bloque avant construction From/SMTP) | n/a (bloque amont) |

Le From aurait ete correct si le gate laissait passer (cf ecomlg-001 qui envoie depuis son adresse
connecteur). Aucun noreply@ implique. Le blocage est en amont du From.

## 9. Provider decision

| conversation | order_ref | customer_handle | expected | observed | verdict |
|---|---|---|---|---|---|
| cmmpml7i1z | oui (conv order) | 43vfy...@marketplace.amazon.fr | SPAPI_ORDER (fallback SMTP autorise) | spapi -> SMTP (AMAZON_SPAPI_MESSAGING_ENABLED=false) | OK provider, bloque ensuite par gate validation |

## 10. Worker logs

| timestamp | marker | interpretation |
|---|---|---|
| 08:00+ | [Worker] Processing dlv-1779955201345-r9tmg83ka (provider: spapi, attempt 1..4) | worker claim OK |
| 08:00+ | [Worker] dlv-...r9tmg83ka failed: Amazon inbound address not validated | gate bloque (API DB PENDING) |
| 6h | "SMTP sending ... as0yom" count = 0 | AUCUN envoi SMTP tente pour as0yom -> bloque AVANT SMTP |

## 11. Mail-core / SP-API

Non requis : la delivery est bloquee avant tout envoi SMTP (0 ligne SMTP sending pour as0yom). Ce
n'est donc PAS SMTP_ACCEPTED_BUT_NOT_VISIBLE. SP-API messaging desactive (fallback SMTP), mais le
fallback n'est jamais atteint car le gate validation echoue d'abord.

## 12. Cause racine

| primary_cause | evidence | next_action |
|---|---|---|
| INBOUND_ADDRESS_STATUS_SYNC_GAP (Backend VALIDATED, product DB API PENDING ; worker lit l'API DB) | Backend as0yom VALIDATED+lastInboundAt 07:58 ; API DB as0yom PENDING updatedAt 07:51 ; worker "not validated" ; 0 SMTP sending | phase patch/config (PH-20.52) : propager validationStatus/marketplaceStatus/lastInboundAt Backend -> product DB API (corriger le ON CONFLICT du sync channels OU faire lire le statut Backend au worker) + backfill ponctuel des tenants impactes. PAS de bouton Channels. |

## 13. Non-regression / no-side-effect

| signal | observe | verdict |
|---|---|---|
| DB mutation | aucune (SELECT only) | OK |
| envoi/POST/fake | aucun | OK |
| restart cause par la phase | 0 (api restarts=0 ; outbound-worker stable) | OK |
| runtime DEV/PROD | inchange | OK |
| inbound advisory lock / KBActions | non touches | OK |

## 14. Prochaine action recommandee

1. PH-20.52 (source/config, hors read-only) : reparer la synchro de statut connecteur
   Backend -> product DB API pour inbound_addresses (validationStatus/marketplaceStatus/lastInboundAt),
   soit en corrigeant le sync channelsRoutes (ON CONFLICT qui doit copier le statut), soit en faisant
   lire au worker le statut Backend, + backfill des lignes API DB deja PENDING alors que Backend est
   VALIDATED (ex : ecomlg-motxke32 as0yom). Apres fix : re-test envoi ecomlg-motxke32.
2. Ne jamais recommander de bouton de validation dans Channels (inexistant ; connecteur deja valide
   cote Backend).

## 15. Phrase cible

GO READONLY VERIFY AMAZON OUTBOUND POST OAUTH RECONNECT READY PH-SAAS-T8.12AS.20.51

STOP.
