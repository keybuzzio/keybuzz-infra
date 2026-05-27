# PH-SAAS-T8.12AS.20.45-APPLY-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.45 (APPLY GITOPS DEV AI ASSIST NOTIFICATION SKIP SCOPE FIX)
> Environnement : DEV runtime, GitOps strict ; aucun build/docker push/apply PROD/DB/fake event

## 1. Verdict

GO APPLY AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV GITOPS READY PH-SAAS-T8.12AS.20.45

Les 2 images PH-20.44 (v3.5.259) sont deployees en DEV via GitOps strict (commit+push manifest
AVANT apply, kubectl apply -f uniquement, rollout OK). runtime = manifest = last-applied =
digest GHCR pour api et client. Le Client DEV runtime sert le bundle v3.5.259 avec API DEV seul
(api.keybuzz.io PROD=0), Clarity wuk12h9i33 et le marker skipped presents. No unintended
processing (before==after). PROD strictement intact. PH-20.43 promotion PROD reste bloque
jusqu'a verify fonctionnel DEV (PH-20.46).

## 2. GitOps deploy commit

| repo | branche | commit deploy | fichiers |
|---|---|---|---|
| keybuzz-infra | main | 1d7c305 | k8s/keybuzz-api-dev/deployment.yaml, k8s/keybuzz-client-dev/deployment.yaml |

Commit+push AVANT apply (a55f58b..1d7c305). 2 fichiers, lignes image seules (+commentaire
rollback). dry-run client+server : configured OK pour les 2.

## 3. Services before / after

| service | namespace | image AVANT | image APRES | ready | restarts |
|---|---|---|---|---:|---:|
| keybuzz-api | keybuzz-api-dev | v3.5.258-amazon-notification-classification-dev | v3.5.259-ai-assist-notification-scope-dev | true | 0 |
| keybuzz-client | keybuzz-client-dev | v3.5.214-ai-draft-blocked-reason-dev | v3.5.259-ai-assist-notification-scope-dev | true | 0 |

Boot : api CHANNELS-SAFETY READY (8 connexions Amazon) + Server listening 3001 ; client Next.js
14.2.35 Ready, aucune erreur critique.

## 4. Runtime equality

| service | namespace | manifest | last-applied | runtime | imageID digest | ready | restarts |
|---|---|---|---|---|---|---:|---:|
| keybuzz-api | keybuzz-api-dev | v3.5.259 | v3.5.259 | v3.5.259 | sha256:e31ff645deed... | true | 0 |
| keybuzz-client | keybuzz-client-dev | v3.5.259 | v3.5.259 | v3.5.259 | sha256:019dea6325fc... | true | 0 |

imageID digests == digests GHCR PH-20.44 (api e31ff645deed, client 019dea6325fc).

## 5. Client bundle runtime verification (in-pod .next/static)

| marker runtime client | attendu | resultat |
|---|---|---|
| https://api-dev.keybuzz.io | present | PRESENT |
| https://api.keybuzz.io (base PROD) | 0 | 0 |
| Clarity wuk12h9i33 | present | PRESENT |
| marker skipped | present | PRESENT |
| ancien cache v3.5.214 | absent | absent (pod sert exactement l'image v3.5.259, imageID 019dea6325fc) |

Verification faite directement dans le pod client DEV en cours d'execution (grep .next/static),
pas de fake user event, pas de navigateur. Incident KEY-302 evite (aucune API PROD comme base
DEV) ; KEY-325 Clarity conserve.

## 6. No unintended processing (snapshot before/after)

| signal | before | after | verdict |
|---|---:|---:|---|
| ai_suggestion_events | 2668 | 2668 | stable |
| ai_actions_ledger | 538 | 538 | stable |
| ai_actions_ledger reason=ai_generation | 445 | 445 | stable (aucune generation spontanee) |
| Job OUTBOUND_EMAIL_SEND DONE/FAILED | 13/16 | 13/16 | stable |
| OutboundEmail SENT/PENDING/FAILED | 13/1/14 | 13/1/14 | stable |
| MarketplaceOutboundMessage | 2 | 2 | stable |
| jobs-worker claimed (OUTBOUND_EMAIL_SEND) | 0 | 0 | stable (no job this poll) |
| AMAZON_POLL lockedBy worker-1 | 0 | 0 | stable |

Aucun appel AI spontane, aucun job declenche par l'apply, aucune mutation DB.

## 7. PROD intact

| service PROD | image | verdict |
|---|---|---|
| keybuzz-api | v3.5.257-autopilot-no-reply-kbactions-prod | inchange |
| keybuzz-client | v3.5.217-clarity-client-restore-prod | inchange |
| keybuzz-backend | v1.0.56-amazon-inbound-dedup-prod | inchange |

Aucun manifest PROD modifie, aucun apply PROD.

## 8. AI feature parity

- API skip message-level actif dans le runtime v3.5.259 (determineAiAssistNotificationSkip +
  garde amazonIds, audite image PH-20.43/44).
- Client skipped:true rendu en etat neutre actif (bundle runtime contient le marker skipped).
- AI Assist normal non volontairement appele dans cette phase (0 KBActions, 0 ai_generation delta).
- Backend v1.0.57 inchange, jobs-worker OUTBOUND_EMAIL_SEND inchange, advisory lock amzmsg /
  outbound / autopilot non touches (hors scope apply image api+client).
- Client bundle pointe api-dev (PROD=0), Clarity wuk12h9i33 conserve.

## 9. No fake metrics / events

Aucun ai_suggestion_events, KBActions, ledger, webhook, replay, trigger, appel AI artificiel.
Phase = GitOps apply image + verification read-only.

## 10. Rollback

git revert 1d7c305 (keybuzz-infra/main) puis kubectl apply -f des 2 manifests DEV restaures :
- keybuzz-api DEV -> v3.5.258-amazon-notification-classification-dev (imageID e/sha256 PH-20.41)
- keybuzz-client DEV -> v3.5.214-ai-draft-blocked-reason-dev
Tags precedents documentes dans le commentaire de chaque ligne image.

## 11. Limites

- Validation fonctionnelle UI a faire en PH-20.46 (Ludovic reteste conversation mixte +
  notification ; CE verifie read-only logs/DB).
- Credits LiteLLM/Anthropic DEV hors scope : peuvent encore bloquer la generation buyer en DEV
  (distinguer env credit du bug classifier, deja corrige).
- PROD reste bloque jusqu'a verify DEV complet.
- ph119 API non relance (toolchain), deja documente PH-20.39 ; couvert par tsc+tests+dist.

## 12. Phrase cible

GO APPLY AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV GITOPS READY PH-SAAS-T8.12AS.20.45

Prochaine etape : GO VERIFY AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV PH-SAAS-T8.12AS.20.46.

STOP.
