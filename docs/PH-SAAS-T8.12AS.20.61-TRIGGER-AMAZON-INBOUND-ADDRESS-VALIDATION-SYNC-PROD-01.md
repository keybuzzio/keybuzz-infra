# PH-SAAS-T8.12AS.20.61-TRIGGER-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-PROD-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.61 (trigger bridge applicatif PROD cible, via flux produit/session)
> Environnement : PROD ; AUCUN build, docker push, deploy, kubectl apply, SQL manuel, outbound send/retry, OAuth/reconnect par CE

## 1. Verdict

GO TRIGGER AMAZON INBOUND ADDRESS VALIDATION SYNC PROD READY PH-SAAS-T8.12AS.20.61

Le bridge applicatif a ete declenche via le flux produit/BFF avec une vraie session navigateur (mode
user-assisted, HTTP 200). Le sync promote-only a propage le statut Backend vers Product/API : la ligne
as0yom (ecomlg-motxke32/amazon/FR) est passee PENDING/PENDING -> VALIDATED/VALIDATED. Aucune autre ligne
modifiee, aucun downgrade, aucun outbound/message/event cree par le trigger. Aucun SQL manuel. PROD stable
(API restarts=0). L'envoi Amazon reel reste a tester separement (PH-20.62).

## 2. Rappel UX

Pas de bouton de validation Amazon dans Channels (n'existe pas). Le trigger est passe par le BFF
POST /api/amazon/activate-channels (meme route que le flux post-OAuth), avec la session navigateur PROD.
Aucun cookie/token copie ou expose.

## 3. Preflight (E0)

| repo/service | branche/image attendue | reel | dirty/restarts | verdict |
|---|---|---|---|---|
| keybuzz-infra | main | main 0b75d66 | dirty 0 | OK |
| keybuzz-api | ph147.4/source-of-truth, origin contient 798db37c | origin contient 798db37c | - | OK |
| keybuzz-client | ph148/onboarding-activation-replay | HEAD ad4e862 | - | OK |
| API PROD | v3.5.260-amazon-inbound-address-sync-prod | spec=last-applied=pod=v3.5.260 ; imageID sha256:778f7556c5aa... | restarts=0 | OK |
| Client PROD | v3.5.259-ai-assist-notification-scope-prod | idem | - | OK |
| Backend PROD | v1.0.56-amazon-inbound-dedup-prod | idem | - | OK |
| outbound-worker PROD | keybuzz-outbound-worker v3.5.165-escalation-flow-prod | idem (ready 1) | - | OK |

Bastion install-v3 / 46.62.171.61 (aucune trace 51.159.99.247). Aucun deploy/build/push requis ni effectue.

## 4. Source contract BFF/API

| brique | fichier/route | point verifie | resultat |
|---|---|---|---|
| BFF | keybuzz-client app/api/amazon/activate-channels/route.ts (b2bba25 = runtime v3.5.259) | getServerSession | 401 si pas de session ; session NextAuth obligatoire |
| BFF | idem | tenantId | body.tenant_id / body.tenantId / header X-Tenant-Id |
| BFF | idem | lecture Backend | GET /api/v1/marketplaces/amazon/inbound-connection ; retient connection seulement si status==='READY' |
| BFF | idem | forward | POST {API}/channels/activate-amazon { tenantId, backendConnection?, backendAddresses? } ; X-Internal-Token ajoute COTE SERVEUR |
| API | keybuzz-api channelsRoutes.ts:122 (798db37c = runtime v3.5.260) | garde | if (backendConnection.status === 'READY' && backendConnection.id) |
| API | idem l.161/169 | promote-only | normalizeInboundValidationStatus + ON CONFLICT CASE WHEN $7=VALIDATED THEN VALIDATED ELSE existing |
| API | idem | outbound | aucun enqueue/send (bridge n'envoie pas) |

## 5. Before snapshots PROD (read-only)

| signal | before |
|---|---|
| Backend inbound_connections ecomlg-motxke32/amazon | status=READY, countries [FR], id present |
| Backend inbound_addresses as0yom (ecomlg-motxke32/FR) | validationStatus=VALIDATED, marketplaceStatus=VALIDATED |
| Product/API as0yom | PENDING / PENDING (lastInboundAt null) |
| Product/API inbound_addresses total / by status | 13 (VALIDATED 8 / PENDING 5) |
| Product/API ai_suggestion_events | 3582 |
| Product/API ai_actions_ledger | 270 |
| Product/API outbound_deliveries | 308 |

Etat conforme a l'attendu pour declencher.

## 6. Trigger mode / status (E3/E4)

Mode : USER-ASSISTED. CE n'avait pas de session produit sure (copie de cookie/token interdite ; API
directe avec payload reconstruit interdite). Ludovic a execute un seul fetch BFF same-origin depuis le
navigateur PROD connecte au tenant ecomlg-motxke32.

| route | tenant | status | body sanitize | verdict |
|---|---|---|---|---|
| POST /api/amazon/activate-channels (BFF) | ecomlg-motxke32 | 200 | {"activated":[],"connectionId":"cmotxn8b600047r01ysh17drm","countries":["FR"]} | OK |

Logs API PROD (sanitize) autour de l'appel :
- POST /channels/activate-amazon recu (reqId req-2ax)
- [Channels] Synced backend connection cmotxn8b600047r01ysh17drm for ecomlg-motxke32: countries=["FR"]
- [Channels] Synced address FR: amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io (status=VALIDATED)

activated=[] signifie qu'aucun NOUVEAU canal n'a ete cree (le canal existait deja) ; le sync d'adresse a
bien promu le statut (log "status=VALIDATED").

## 7. After snapshots PROD + diff

| table/signal | before | after | delta | attendu ? |
|---|---|---|---|---|
| Product/API as0yom validationStatus | PENDING | VALIDATED | promu | OUI (cible) |
| Product/API as0yom marketplaceStatus | PENDING | VALIDATED | promu | OUI |
| Product/API inbound_addresses VALIDATED | 8 | 9 | +1 | OUI (la cible) |
| Product/API inbound_addresses PENDING | 5 | 4 | -1 | OUI (la cible) |
| Product/API inbound_addresses total | 13 | 13 | 0 | OUI (promotion, pas de nouvelle ligne) |
| autre tenant inbound_address | - | - | 0 | OUI (aucun autre change ; aucun downgrade) |
| Backend inbound_connections / as0yom | READY / VALIDATED | READY / VALIDATED | 0 | OUI (source, non mutee) |
| outbound_deliveries | 308 | 308 | 0 | OUI (aucun outbound cree) |
| ai_suggestion_events | 3582 | 3582 | 0 | OUI (aucun event cree) |
| ai_actions_ledger | 270 | 271 | +1 | trafic reel concurrent (session navigateur Ludovic : GET dashboard/stats/entitlement ecomlg-motxke32 dans les logs) ; le bridge n'ecrit pas de ledger |
| API PROD restarts | 0 | 0 | 0 | OK |

La transition de compteurs (VALIDATED +1 / PENDING -1 / total 0) prouve exactement UNE promotion (la cible
as0yom), sans creation ni downgrade d'aucune autre ligne.

## 8. No unintended processing (E6)

| signal | before | after | delta | interpretation |
|---|---|---|---|---|
| outbound email envoye | - | - | 0 | aucun (le bridge n'envoie pas ; gate worker non sollicite ici) |
| outbound_deliveries | 308 | 308 | 0 | aucun retry/cree |
| message Amazon cree | - | - | 0 | aucun |
| ai_suggestion_events | 3582 | 3582 | 0 | aucun |
| ai_actions_ledger | 270 | 271 | +1 | trafic reel concurrent (navigation app), pas le bridge |
| restart API/Client/Backend/outbound-worker | - | - | 0 | aucun |
| DEV / latest / manifests | - | - | 0 | intacts |

No fake metrics / no fake events : aucun event marketing, aucun ai_suggestion_events, aucun message ni
outbound_delivery cree par cette phase. Le seul delta (ai_actions_ledger +1) est du trafic produit reel
concurrent pendant la session navigateur, documente via les logs (requetes dashboard/stats du tenant).

## 9. AI feature parity / anti-regression

| feature | source de verite | preuve runtime | verdict |
|---|---|---|---|
| advisory lock Amazon inbound (PH-20.26/34-BIS) backend | backend | non touche par le trigger API | OK |
| AI Assist notification skip (PH-20.42-TER/49) | API | present runtime v3.5.260 | OK |
| generation AI Assist + KBActions (PH-20.46-QUATER) | API | non touches | OK |
| worker outbound gate VALIDATED (PH-20.50/51) | outboundWorker | gate intact ; la cible le SATISFAIT desormais (validationStatus=VALIDATED) ; validation non contournee | OK |
| sync validation status (PH-20.52) | channelsRoutes + helper | a FONCTIONNE : promote-only as0yom PENDING -> VALIDATED, aucun downgrade | OK |
| bouton validation Channels | n/a | aucun invente | OK |
| Client UI / Autopilot / escalade / playbooks / billing / tracking | hors scope | non touches | OK |

## 10. Limites

- READY = synchronisation de statut faite (as0yom Product/API VALIDATED). Cela LEVE le blocage
  "Amazon inbound address not validated" du worker outbound, mais NE PROUVE PAS encore qu'un message
  KeyBuzz part reellement vers Amazon : aucun envoi reel n'a ete declenche dans cette phase.
- Ne pas conclure que les messages Amazon ecomlg-motxke32 arrivent a nouveau tant qu'un vrai outbound
  post-sync n'a pas ete teste (PH-20.62).

## 11. Compensation / rollback

- Aucun rollback DB. La cible as0yom VALIDATED est l'etat correct attendu (promotion conforme).
- Promote-only : un re-trigger serait idempotent (ne downgrade jamais). Aucune compensation requise.
- Aucun deploy/rollback dans cette phase.

## 12. Prochain GO recommande

GO VERIFY AMAZON OUTBOUND DELIVERY AFTER VALIDATION SYNC PROD PH-SAAS-T8.12AS.20.62 : declencher/tester un
vrai envoi ou retry controle d'un message Amazon pour ecomlg-motxke32 (via flux produit, sans SQL manuel),
puis verifier outbound_deliveries SMTP_* sending/delivered + logs worker + visibilite Seller Central.

## 13. Fichier retour CE

C:\DEV\KeyBuzz\tmp\PH-20.61_CE_RETURN.md

## 14. Phrase cible

GO TRIGGER AMAZON INBOUND ADDRESS VALIDATION SYNC PROD READY PH-SAAS-T8.12AS.20.61

STOP.
