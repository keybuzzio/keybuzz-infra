# PH-SAAS-T8.12AS.20.57-TRIGGER-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-DEV-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.57 (TRIGGER DEV via bridge applicatif)
> Environnement : DEV uniquement ; aucun POST emis ; aucune mutation DB ; aucun SQL ; PROD intacte

## 1. Verdict

GO TRIGGER AMAZON INBOUND ADDRESS VALIDATION SYNC DEV ACTION_REQUIRED PH-SAAS-T8.12AS.20.57

Le trigger DEV n'a PAS ete execute, pour deux blocages independants identifies en preflight read-only.
Aucun POST, aucune mutation, aucun SQL, aucun secret affiche. PROD strictement intacte. Une decision
Codex/Ludovic est requise (cf QUESTIONS_FOR_CODEX) avant tout trigger.

## 2. Rappel UX (important)

Pas de bouton de validation Amazon dans Channels. Le sujet reste la synchronisation Backend ->
Product/API DB. Aucune action UX inexistante n'est demandee.

## 3. Preflight (E0)

| repo/service | attendu | reel | dirty/restarts | verdict |
|---|---|---|---|---|
| keybuzz-api-dev/keybuzz-api | v3.5.260-amazon-inbound-address-sync-dev | v3.5.260-amazon-inbound-address-sync-dev | ready, restarts=0 | OK |
| keybuzz-api-prod/keybuzz-api | v3.5.259-ai-assist-notification-scope-prod | v3.5.259-...-prod | 1/1 | intact |
| keybuzz-infra | main propre | main 5ab45b6 | dirty=0 | OK |

Bastion install-v3 / 46.62.171.61 (aucune trace 51.159.99.247). Aucun build/deploy requis.

## 4. Source/runtime contract du bridge (E1)

| brique | fichier/route | point verifie | resultat |
|---|---|---|---|
| API trigger | app.post("/activate-amazon") channelsRoutes.ts:122 | auth | tenant via header x-tenant-id ou body.tenantId ; AUCUN x-internal-token requis ; ne lit PAS le Backend lui-meme |
| API mount | app.ts:206 register(channelsRoutes, prefix /channels) ; app.ts:104 tenantGuardPlugin | hook auth global | pas de hook JWT global ; seul tenantGuard (scope channels, cf PROTECTED_ROUTES PH-20.49/AS.14.1) |
| sync AM.9.1 | channelsRoutes.ts:133 | garde | `if (backendConnection && backendConnection.status === 'READY' && backendConnection.id)` -> ne synchronise QUE si la connexion Backend transmise est READY |
| BFF orchestrateur | keybuzz-client app/api/amazon/activate-channels/route.ts | auth + lecture Backend | exige getServerSession (401 si pas de session.user.email) ; lit Backend GET /api/v1/marketplaces/amazon/inbound-connection (source de verite) ; ne forwarde backendConnection que si status === 'READY' |
| promote-only | channelsRoutes.ts ON CONFLICT (PH-20.52) | downgrade | jamais de downgrade VALIDATED -> PENDING (verifie PH-20.55/56) |
| outbound | bridge | envoi email | le trigger n'envoie aucun outbound (insert/upsert inbound seulement + activation canaux + inbound_email) |

Conclusion contrat : le seul point qui lit le VRAI statut Backend est le BFF, protege par session
navigateur. L'API /channels/activate-amazon consomme un payload (backendConnection+backendAddresses)
fabrique par le BFF a partir d'une lecture Backend reelle.

## 5. Snapshot BEFORE DEV (E2, read-only)

| tenant | country | backend addr status | backend conn status | product/api status | action attendue |
|---|---|---|---|---|---|
| tenant_test_dev | FR | VALIDATED (marketplaceStatus PENDING, lastInboundAt 2026-05-26) | DRAFT (PAS READY) | absent (0 ligne) | bridge NE synchroniserait PAS (garde READY non satisfaite) |

Compteurs securite product DEV (baseline, aucune mutation faite) : outbound_deliveries=310,
ai_actions_ledger=550, inbound_addresses=23 (tous == PH-20.55/56).

## 6. Blocages identifies (raison de ACTION_REQUIRED)

Blocage 1 - AUTH : le bridge end-to-end (lecture Backend reelle -> propagation Product/API) passe
obligatoirement par le BFF `POST /api/amazon/activate-channels`, qui exige une session NextAuth
navigateur (session.user.email). CE n'a pas de session sure ; en obtenir/fabriquer une serait
inventer/exposer une auth -> interdit (HORS SCOPE + ETAPE 3 + ETAPE 4 401/403). Appeler l'API
/channels/activate-amazon en direct obligerait a reconstruire a la main backendConnection +
backendAddresses (donc inventer/diverger du statut Backend reel, le BFF transformant pipelineStatus
-> status et filtrant sur connection READY) et a contourner la session = bricolage interdit.

Blocage 2 - CIBLE NON ELIGIBLE : la cible DEV imposee `tenant_test_dev/FR` a bien une adresse Backend
VALIDATED et est absente cote Product/API, MAIS sa connexion inbound Backend est en status `DRAFT`
(pas `READY`). La garde du bridge (`backendConnection.status === 'READY'`) ne serait donc pas
satisfaite : meme un trigger via BFF avec session ne creerait PAS la ligne Product/API VALIDATED. La
cible DEV ne permet pas d'exercer l'INSERT VALIDATED attendu.

Aucun changement de cible n'a ete fait sans accord (ETAPE 2/10) ; aucune autre cible DEV n'a une
connexion Backend READY + adresse VALIDATED + Product/API PENDING/absent (cf audit PH-20.56 :
ecomlg-001 FR deja SYNC_OK ; les autres Product VALIDATED sont deja en avance ou Backend absent).

## 7. Trigger DEV (E4) : NON EXECUTE

Aucun POST emis (ni BFF, ni API). Aucun SQL. Aucun envoi. Aucun OAuth/reconnect. Aucun fake event.
Conforme : "un seul POST autorise" mais non emis car les preconditions d'auth et d'etat cible ne sont
pas reunies de facon sure.

## 8. Snapshot AFTER : sans objet (aucun trigger). Etat DB inchange (identique au BEFORE).

## 9. Non-regression DEV/PROD (E6)

| feature/signal | baseline | apres | verdict |
|---|---|---|---|
| API DEV image/restarts | v3.5.260, restarts=0 | inchange | OK |
| API PROD image | v3.5.259-...-prod | inchange | intact |
| Client/backend/outbound-worker DEV+PROD | inchanges | inchanges | OK |
| outbound_deliveries DEV | 310 | 310 | OK (aucun outbound) |
| ai_actions_ledger DEV | 550 | 550 | OK (aucun debit) |
| inbound_addresses DEV | 23 | 23 | OK (aucune mutation) |
| AI Assist skip / gate worker VALIDATED | presents/intacts (PH-20.56) | inchanges | OK |
| as0yom PROD | split connu | non touche | OK (hors scope) |

## 10. Limites

- PH-20.57 ne prouve PAS le bridge en DEV (non declenche). La preuve runtime du patch reste celle de
  PH-20.56 (markers presents, promote-only en source/runtime, tests 23/23 PH-20.52).
- as0yom PROD reste non corrige ; ne pas conclure que l'outbound ecomlg-motxke32 est repare.

## 11. Rollback / compensation

Aucune mutation effectuee -> aucun rollback necessaire. Aucun deploy -> aucun rollback applicatif.

## 12. Prochain GO recommande (a arbitrer par Codex/Ludovic)

Option A (DEV, action utilisateur) : un utilisateur DEV connecte declenche l'activation de canaux
Amazon via le Client DEV (le BFF lit alors le Backend avec une session legitime), POUR un tenant DEV
dont la connexion Backend est READY + une adresse Backend VALIDATED encore absente/PENDING cote
Product/API. A ce jour, aucun tenant DEV ne remplit ces 3 conditions (tenant_test_dev = connexion
DRAFT). Il faudrait d'abord amener un tenant DEV a cet etat (connexion READY) via le flux produit
normal, ce qui sort du scope read/write actuel.

Option B (PROD, sous phase dediee + GO explicite) : c'est le cas reel exploitable (as0yom :
connexion Backend READY apres reconnect OAuth + adresse VALIDATED + Product/API PENDING). Sequence :
build/push/apply API PROD v3.5.260 (phases dediees), puis re-declenchement du bridge PROD via le flux
produit (session) sous GO explicite, avec before/after DB et non-regression. Eviter tout SQL manuel.

Option C (backfill SQL) : a eviter ; contourne la logique applicative.

Recommandation : ne pas forcer un trigger DEV non representatif. Valider le patch via PH-20.56
(deja READY) et planifier la correction reelle en PROD (Option B) sous GO explicite, OU, si une preuve
DEV est exigee, prevoir une phase qui amene d'abord un tenant DEV a l'etat connexion READY par le flux
produit, puis declenche le bridge avec session DEV.

## 13. PROD intacte

API PROD v3.5.259-ai-assist-notification-scope-prod inchangee, aucun manifest PROD touche, aucune
mutation DB PROD, as0yom non touche.

## 14. Fichier retour CE

C:\DEV\KeyBuzz\tmp\PH-20.57_CE_RETURN.md

## 15. Phrase cible

GO TRIGGER AMAZON INBOUND ADDRESS VALIDATION SYNC DEV ACTION_REQUIRED PH-SAAS-T8.12AS.20.57

STOP.
