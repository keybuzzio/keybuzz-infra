# PH-SAAS-T8.12AS.20.25-BIS-READONLY-VERIFY-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.25-BIS (READONLY VERIFY APRES VRAI MESSAGE)
> Environnement : PROD read-only (SELECT + logs ; aucun fake/replay/mutation)

## 1. Verdict

GO READONLY VERIFY AMAZON INBOUND DEDUP PROD PARTIAL PH-SAAS-T8.12AS.20.25-BIS

Le vrai message Amazon de Ludovic (Switaa -> eComLG) est ARRIVE et a ete INGERE en PROD a 2026-05-27T10:44:50-51Z (4 POST webhook). Le patch v1.0.55-prod est actif, mais il N'A PAS deduplique ce cas : ecomlg-001 a 3 messages logiques (dans 2 conversations) pour le MEME amazonIds.messageId A100493337L42M1RERYX6, 0 log "Idempotent skip". Cause = RACE confirmee : les 4 livraisons sont arrivees dans la MEME seconde (~190 ms), la dedup applicative est SELECT-puis-skip SANS contrainte unique DB -> les 3 livraisons ecomlg-001 ont toutes fait leur SELECT avant tout commit -> aucune n'a skip. La race a aussi defait la dedup CONVERSATION (2 conversations neuves creees pour le meme threadKey sc:). Conclusion : v1.0.55 est correct pour des redeliveries SEQUENTIELLES mais ne ferme pas la race ; la contrainte unique DB (tenant_id, amazonIds.messageId) est empiriquement NECESSAIRE. Non-regression OK, PROD intact, P0 KEY-323 non touche.

## 2. Preflight runtime (E0)

| Service | Image | Digest | Ready | Restarts |
|---|---|---|---|---|
| keybuzz-backend PROD (797978c57d-cn68k) | v1.0.55-amazon-inbound-dedup-prod | sha256:b21e524a...52e2 | true | 0 |
| jobs-worker PROD (75c884ffdc-nsfcp) | v1.0.55-amazon-inbound-dedup-prod | sha256:b21e524a...52e2 | true | 0 |
| backend + jobs-worker DEV | v1.0.55-amazon-inbound-dedup-dev | - | - | inchange |

Bastion install-v3 / 46.62.171.61.

## 3. Fenetre analysee (E1)

start = 2026-05-27 10:24:00Z (apres le verify PH-20.25 ACTION_REQUIRED) ; end = 2026-05-27 10:47Z. Vrai message ingere a 10:44:50-51Z.

## 4. DB evidence - messages Amazon posterieurs (E2)

amazon inbound messages depuis 10:24Z = 4. Groupes (tenant + amazonIds.messageId) :

| tenantId | amazonMessageId | countMessages | conversations | rawMimeCount | subject | verdict |
|---|---|---|---|---|---|---|
| ecomlg-001 | A100493337L42M1RERYX6 | 3 | 2 (cmmpnxtgye537 + cmmpnxtgyg0da, NEUVES) | 3 | Re: Demande de renseignements ... | DOUBLON intra-tenant NON collapse |
| ecomlg-motxke32 | A100493337L42M1RERYX6 | 1 | 1 (cmmpml7i1z existante) | 1 | idem | cross-tenant (attendu, non corrige) |

Lignes exactes (toutes created_at 10:44:50Z, raw_mime_sha256 distincts) :
- ecomlg-001 / cmmpnxtgze417 / conv cmmpnxtgyg0da / mime f5dfeaa4
- ecomlg-001 / cmmpnxtgzd49 / conv cmmpnxtgye537 / mime a15b195a
- ecomlg-001 / cmmpnxtgzjb / conv cmmpnxtgye537 / mime 01f54bd8
- ecomlg-motxke32 / cmmpnxtguze / conv cmmpml7i1z / mime 936387cb

## 5. Dedup intra-tenant (E3)

| tenantId | amazonMessageId | rawMimeCount | messageRows | skippedLogs | verdict |
|---|---|---|---|---|---|
| ecomlg-001 | A100493337L42M1RERYX6 | 3 | 3 | 0 | RACE : dedup non declenchee, 3 messages crees |
| ecomlg-motxke32 | A100493337L42M1RERYX6 | 1 | 1 | 0 | 1 seul (rien a dedup dans ce tenant) |

ms-precision : les 4 messages ont epoch created_at == 1779878690 (meme seconde). Les 4 POST webhook : time 1779878691597 / 632 / 689 / 787 (fenetre ~190 ms). SELECT-puis-skip sans contrainte unique -> race -> 0 skip.

## 6. Logs backend PROD (E4)

4 POST /api/v1/webhooks/inbound-email a 10:44:51Z (reqId 6h/6i/6j/6k). 4x AmazonDetection (1 ecomlg-motxke32 + 3 ecomlg-001). Message-ID mail SES distincts par livraison (0102019e69097ac3 / 7caf / 7891 / 79b9 @eu-west-1.amazonses). 4x MessageNormalizer amazonIds.messageId=A100493337L42M1RERYX6, threadKey sc:A08467981VCU78NJADWD5. Sequence InboxConversation : "Found existing" + "Created new conversation" x2 (meme threadKey, race conversation) + "Created message" x4. **0 "Idempotent skip"**. AmazonDetection : 1 ecomlg-001 "marked VALIDATED" (4xfub8) + 2 "Address not found - no validation" (tokens obsoletes 3jcpvk/cp2hat) + 1 ecomlg-motxke32 "marked VALIDATED" (as0yom).

Confirme : le triple ecomlg-001 = 3 adresses reply-to (4xfub8 + 3jcpvk + cp2hat) -> meme tenant, livrees quasi-simultanement.

## 7. Cross-tenant / stale reply-to (E5)

| amazonMessageId | tenantIds | countByTenant | verdict |
|---|---|---|---|
| A100493337L42M1RERYX6 | ecomlg-001, ecomlg-motxke32 | ecomlg-001=3 / motxke32=1 | cross-tenant persiste (4xfub8 vs as0yom) + intra-tenant triple via 3jcpvk/cp2hat obsoletes |

## 8. Non-regression (E6)

| Garantie | etat |
|---|---|
| ecomlg-001 FR amazon validationStatus / marketplaceStatus | VALIDATED / VALIDATED |
| Job OUTBOUND_EMAIL_SEND / OutboundEmail | 0 / 0 |
| AMAZON_POLL lockedBy worker-1 | 0 |
| PROD restarts (backend + jobs-worker) | 0 / 0 |
| outbound reply restaure (PH-20.14AE) | non touche |
| trigger / retry / cleanup / fake | 0 |
| DEV | inchange (v1.0.55-dev) |

Ingestion Inbox fonctionnelle (les vrais messages sont bien crees et visibles). Aucune mutation par le CE ; les 4 messages viennent du vrai message de Ludovic.

## 9. Limites restantes / analyse

- RACE (cause dominante prouvee ICI) : 4 POST en ~190 ms -> dedup applicative SELECT-puis-skip inoperante sans contrainte unique. La contrainte unique DB produit (tenant_id, amazonIds.messageId) est empiriquement NECESSAIRE pour fermer le triple ; c'est desormais le correctif decisif.
- MULTI-ADDRESS : ecomlg-001 recoit le meme message via 3 reply-to (4xfub8 actif + 3jcpvk/cp2hat obsoletes). Retirer les obsoletes cote Amazon reduit le fan-out a 1 livraison (supprime le triple a la source), mais ne protege pas contre des copies SES concurrentes vers une meme adresse.
- CROSS-TENANT : 4xfub8 (ecomlg-001) + as0yom (ecomlg-motxke32) = meme seller, 2 tenants -> non fusionne (decision produit).
- Cleanup des doublons existants : separe (jamais DELETE ad hoc).

## 10. Prochaine phase

Deux leviers complementaires, a sequencer :
1. **GO SOURCE/DB UNIQUE CONSTRAINT AMAZON INBOUND DEDUP** (prioritaire, ferme la race) : contrainte unique DB produit (tenant_id, amazonIds.messageId) et/ou (tenant_id, channel, thread_key) en SQL brut (conversations/messages = SQL brut, pas Prisma), APRES cleanup des doublons existants.
2. **GO READONLY AMAZON STALE REPLY_TO CLEANUP PLAN PROD PH-SAAS-T8.12AS.20.26** (reduit le fan-out multi-adresse 3jcpvk/cp2hat + reconciliation cross-tenant, plan read-only sans mutation).

## 11. Phrase cible

GO READONLY VERIFY AMAZON INBOUND DEDUP PROD PARTIAL PH-SAAS-T8.12AS.20.25-BIS

STOP.
