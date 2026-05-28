# PH-SAAS-T8.12AS.20.49-APPLY-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-PROD-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.49 (APPLY GITOPS PROD du correctif PH-20.42-TER)
> Environnement : PROD ; GitOps strict ; API PROD + Client PROD uniquement

## 1. Verdict

GO APPLY AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD GITOPS READY PH-SAAS-T8.12AS.20.49

Le correctif classifier message-level (API) + UX skipped neutre (Client) est promu en PROD via
GitOps strict. Runtime = manifest = last-applied = digest GHCR attendu pour les deux services.
Client PROD sert le bundle PROD (api.keybuzz.io, pas api-dev, Clarity present). Aucun unintended
processing, DEV intact, backend PROD intact, latest non touche.

## 2. GO explicite Ludovic

GO APPLY AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD GITOPS PH-SAAS-T8.12AS.20.49 (fichier mission
PH-20.49, section GO EXPLICITE).

## 3. Preflight repos

| repo | branche | HEAD | origin | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 15f0e5e5 | 15f0e5e5 | dist/ pre-existant tolere (hors scope apply) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862 | ad4e862 | tsconfig.tsbuildinfo pre-existant tolere | OK |
| keybuzz-infra | main | 18ab951 (avant) | 18ab951 | 0 | OK |
| keybuzz-backend | main | (read-only, hors scope) | - | - | non touche |

## 4. GHCR

| image | tag | manifest digest | config digest | revision | verdict |
|---|---|---|---|---|---|
| keybuzz-api | v3.5.259-ai-assist-notification-scope-prod | sha256:7203e247b13a4754110eb016d67c3e484813e14c00b748b5880f6d6fcfb7e633 | sha256:c0de6f0d9c8b709157a2a480baa5c95b4fa0938fb63ad25ac032be17529a89b0 | 15f0e5e570c26286bcf394d55718684a5574bec5 | PRESENT |
| keybuzz-client | v3.5.259-ai-assist-notification-scope-prod | sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | sha256:9f46a7a88f83e15333b4e0106ac740b0571a8e4f38743b6c09d964e4566f5b69 | ad4e862a2e635de251757f382a6d00b8fd063748 | PRESENT |

## 5. Manifest diff

| fichier | changement | rollback | risque |
|---|---|---|---|
| k8s/keybuzz-api-prod/deployment.yaml | ligne image L106 v3.5.257-autopilot-no-reply-kbactions-prod -> v3.5.259-ai-assist-notification-scope-prod (+ commentaire PH-20.49) | v3.5.257-autopilot-no-reply-kbactions-prod | faible (image only) |
| k8s/keybuzz-client-prod/deployment.yaml | ligne image L76 v3.5.217-clarity-client-restore-prod -> v3.5.259-ai-assist-notification-scope-prod (+ commentaire PH-20.49) | v3.5.217-clarity-client-restore-prod | faible (image only) |

git diff = 2 lignes changees (1/fichier), uniquement image+commentaire. Aucun env/secret/port/probe/
resource/replica modifie. Dry-run client + server OK pour les deux. Deploy commit **934a7f2** push
sur origin/main AVANT apply (ahead/behind=0/0, dirty=0).

## 6. Runtime avant / apres

| service | namespace | image avant | image apres | imageID digest | ready | restarts |
|---|---|---|---|---|---:|---:|
| keybuzz-api | keybuzz-api-prod | v3.5.257-autopilot-no-reply-kbactions-prod (52ec1bcf) | v3.5.259-ai-assist-notification-scope-prod | sha256:7203e247b13a | true | 0 |
| keybuzz-client | keybuzz-client-prod | v3.5.217-clarity-client-restore-prod (e75ac3ad) | v3.5.259-ai-assist-notification-scope-prod | sha256:e63494dbe833 | true | 0 |

Runtime equality (E8) : pour chaque service spec image = last-applied image = pod runtime image =
tag cible ; pod imageID = manifest digest GHCR attendu ; anciens pods termines ; restarts=0.
API boot OK (OCTOPIA-SYNC completed, 0 FATAL/uncaught/credit-error sur 5m). Client Next.js ready
(log applicatif 404 import-order = trafic utilisateur naturel, pas erreur de boot).

## 7. Bundle Client PROD runtime (in-pod)

| marker | attendu | resultat | verdict |
|---|---|---|---|
| https://api.keybuzz.io | present | 2 occ | OK |
| https://api-dev.keybuzz.io | absent | 0 | OK (KEY-302) |
| Clarity wuk12h9i33 | present | 1 fichier | OK (KEY-325) |
| marker skip neutre (Notification systeme / brouillon IA) | present | 1 fichier chacun | OK |
| chemin erreur reelle (Impossible de g) | present | 1 fichier | OK |

Extraction in-pod du bundle .next/static du pod Client PROD courant (dtrpj). Aucune API DEV inlinee.

## 8. No unintended processing (before / after read-only)

| signal | before | after | delta | interpretation |
|---|---:|---:|---:|---|
| product ai_suggestion_events | 3552 | 3552 | 0 | aucun event cree par l'apply |
| product ai_actions_ledger total | 265 | 265 | 0 | aucun debit |
| product ai_actions_ledger ai_generation | 231 | 231 | 0 | aucune generation declenchee |
| backend Job OUTBOUND_EMAIL_SEND | 0 | 0 | 0 | aucun job outbound |
| backend OutboundEmail | 0 | 0 | 0 | aucun email |
| backend MarketplaceOutboundMessage | 0 | 0 | 0 | aucun MOM |
| jobs-worker claimed | 0 | 0 | 0 | heartbeat, aucun job |

Aucun appel IA fabrique par CE. Aucun fake event/KBActions/webhook. PROD live : aucun compteur n'a
bouge pendant la fenetre d'apply.

## 9. DEV intact

| service | namespace | runtime | verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.259-ai-assist-notification-scope-dev | inchange |
| keybuzz-client | keybuzz-client-dev | v3.5.259-ai-assist-notification-scope-dev | inchange |
| keybuzz-backend | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | inchange |

Aucun manifest DEV dans le deploy commit 934a7f2 (scope = 2 manifests PROD uniquement).

## 10. Backend PROD intact

keybuzz-backend-prod/keybuzz-backend = v1.0.56-amazon-inbound-dedup-prod (restarts=0) ;
keybuzz-backend-prod/jobs-worker = v1.0.56-amazon-inbound-dedup-prod (restarts=0). Backend
notification classifier (v1.0.57) NON promu (hors scope PH-20.49). amzmsg advisory lock PROD
v1.0.56 en place. Aucun outbound declenche.

## 11. AI feature parity

- API : determineAiAssistNotificationSkip present (dist image, audit PH-20.47/PH-20.48) ; garde
  amazonIds.messageId => no skip ; skip seulement dernier inbound notification sans amazonIds ;
  debitKBActions chemin succes intact ; aucune mutation budget/provider/model.
- Client : skipped:true rendu etat neutre ; vraies erreurs conservees (Impossible de generer) ;
  bundle PROD api.keybuzz.io ; Clarity wuk12h9i33 ; pas de retour incident KEY-302.
- Backend non touche ; jobs-worker OUTBOUND_EMAIL_SEND non touche ; aucun outbound.

## 12. Rollback documente (non execute)

En cas d'incident :
- git revert 934a7f2 sur keybuzz-infra/main ; push ;
- kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml (revenu a v3.5.257-autopilot-no-reply-kbactions-prod) ;
- kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml (revenu a v3.5.217-clarity-client-restore-prod) ;
- rollout status ; verifier runtime equality.
Interdit : kubectl set image. Aucune migration DB associee a ce correctif.

## 13. PROD / DEV final

| env | api | client | backend |
|---|---|---|---|
| PROD | v3.5.259-ai-assist-notification-scope-prod | v3.5.259-ai-assist-notification-scope-prod | v1.0.56-amazon-inbound-dedup-prod (inchange) |
| DEV | v3.5.259-ai-assist-notification-scope-dev | v3.5.259-ai-assist-notification-scope-dev | v1.0.57-amazon-notification-classification-dev (inchange) |

## 14. Gaps restants

- Backend notification classifier PROD (v1.0.57) reste a promouvoir dans une phase dediee si decide
  (hors scope PH-20.49).
- Hardening LiteLLM (alerting credit + fallback multi-provider) = phase separee.
- QA navigateur PROD (clic AI Assist reel sur notification + buyer) recommandee par Ludovic pour
  confirmer l'UX en conditions reelles (le runtime/bundle sont prouves cote infra).

## 15. Phrase cible

GO APPLY AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD GITOPS READY PH-SAAS-T8.12AS.20.49

STOP.
