# PH-SAAS-T8.12AS.1.2 -- Client Build-Args Fix DEV

> Date : 2026-05-10
> Linear : KEY-263 (parent) ; KEY-302 a ouvrir ; KEY-301 reste ouvert
> Phase : closeout AS.1 sous-phase build-args-fix Client DEV
> Environnement : DEV uniquement -- PROD strictement intacte

## VERDICT

GO DEV CLIENT BUILD-ARGS FIX READY

CLIENT DEV INBOX RESTORED -- CLIENT BUNDLE POINTS TO API DEV -- API DEV ESCALATION NOTIFICATIONS PRESERVED -- PROD UNCHANGED -- BUILD ARGS INCIDENT DOCUMENTED -- KEY-302 OPEN TO PREVENT RECURRENCE -- KEY-301 OPEN BEFORE PROD PROMOTION

Confirmation QA Ludovic 2026-05-10 :
- Inbox DEV : liste centrale affichee, conversations visibles
- Topbar tenant SWITAA SASU + user/email : OK
- Bandeau bas Donnees API : vert
- PROD verifiee visuellement : intacte

---

## 0. Preflight bastion install-v3

| Repo | Branche attendue | Branche reelle | HEAD | Status | Sync origin | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | a69477a | clean (tsconfig.tsbuildinfo artifact only) | 0 ahead / 0 behind | OK |
| keybuzz-infra | main | main | b958002 | clean | 0/0 | OK |

Bastion : install-v3, IP 46.62.171.61.

---

## 1. Cause racine

Le Dockerfile keybuzz-client/Dockerfile declare des ARG par defaut pointant vers PROD :

```
ARG NEXT_PUBLIC_API_URL=https://api.keybuzz.io
ARG NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io
```

Ces ARG sont convertis en ENV puis inlines dans le bundle JS browser au moment de `next build`. Le runtime stage ne porte pas ces ENV, donc `docker inspect` final ne les revele pas. Il faut extraire `.next/static` du container et grep les bundles pour voir l'URL inlinee.

Sans `--build-arg` explicite au moment de `docker build`, le bundle est inline avec PROD URL. Tous les fetch directs cote browser (notamment fetchConversations qui cible `${API_CONFIG.baseUrl}/messages/conversations`) partent vers `https://api.keybuzz.io` PROD avec des cookies de session DEV. L'auth est rejetee (401/CORS), le catch silencieux dans conversations.service.ts retourne `{ conversations: [], source: 'error' }`, la liste centrale Inbox affiche 0.

Les BFF routes Next.js (`/api/...`) restent fonctionnelles car elles utilisent `process.env.API_URL_INTERNAL` qui est une env var runtime du pod presente sur DEV (`http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001`). Symptome typique : sidebar stats `/api/stats/conversations` montre 77/69 conversations, mais la liste centrale est vide.

Les images Client DEV affectees :
- v3.5.177-escalation-notifications-ux-dev (build initial AS.1, casse Inbox)
- v3.5.178-escalation-notifications-client-fix-dev (mon premier "fix", meme erreur build args, meme symptome)

Le code AS.1 (commit 37e70ac) et le code AS.1.1 (commit a69477a, suppression callsite) sont probablement innocents : la cause racine etait le build, pas le code.

---

## 2. Preuves bundle

Extraction `.next/static` depuis chaque image et grep `https://api[a-z\-]*\.keybuzz\.io` :

| Image | URL DEV presente | URL PROD presente | Verdict |
|---|---|---|---|
| v3.5.176-conversation-tone-metric-ux-dev (working baseline) | https://api-dev.keybuzz.io | (absente) | OK |
| v3.5.178-escalation-notifications-client-fix-dev (broken) | (absente) | https://api.keybuzz.io | KO -- PROD URL inlinee |
| v3.5.179-as1-1-build-args-fix-dev (rebuild propre) | https://api-dev.keybuzz.io (2 occurrences) | (absente, 0 occurrence) | OK |

---

## 3. Commits

| Repo | Commit | Sujet | Etat |
|---|---|---|---|
| keybuzz-client | a69477a | fix(inbox): unwire AS.1 escalation badge from InboxTripane to restore conversation list (PH-SAAS-T8.12AS.1.1, KEY-263) | pousse sur origin |
| keybuzz-infra | 190310f | deploy(client-dev): v3.5.178 (echec, premier fix incomplet) | historique |
| keybuzz-infra | e1d0f93 | rollback(client-dev): v3.5.178 -> v3.5.176 -- v3.5.178 buildee sans --build-arg, bundle browser inline PROD URL (KEY-263) | historique |
| keybuzz-infra | b958002 | deploy(client-dev): v3.5.179-as1-1-build-args-fix-dev -- rebuild propre avec --build-arg DEV (PH-SAAS-T8.12AS.1.2, KEY-263) | en place |

---

## 4. Images et digests

| Image | Tag | Image ID | Digest registry | Statut |
|---|---|---|---|---|
| Client DEV (working baseline) | v3.5.176-conversation-tone-metric-ux-dev | 7a0be0edb754 | (cache local + registry) | rollback target connu |
| Client DEV (broken first fix) | v3.5.178-escalation-notifications-client-fix-dev | 89c747754e0b | sha256:1e24a9ea562dbb916b1f429acfab8ec60f5e91cf93789ff1d112895161ac2dfd | a NE PLUS deployer (PROD URL inlinee) |
| Client DEV (clean fix) | v3.5.179-as1-1-build-args-fix-dev | 854cfc8c029c | sha256:b8a64abd378ac2b66dc9a4fd033390fe2a5430feafa0c143a55abe7d02990306 | runtime actuel DEV |

Build command pour v3.5.179 (a appliquer pour tout build Client DEV futur) :

```
docker build \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  -t ghcr.io/keybuzzio/keybuzz-client:<tag>-dev .
```

---

## 5. GitOps DEV

| Element | Valeur |
|---|---|
| Manifest | k8s/keybuzz-client-dev/deployment.yaml |
| Edit | image v3.5.176 -> v3.5.179-as1-1-build-args-fix-dev + commentaire mis a jour |
| Diff | 1 ligne |
| Commit | b958002 |
| Push | e1d0f93..b958002 sur main |
| Apply | kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml -> deployment.apps/keybuzz-client configured |
| Rollout | successfully rolled out |
| Runtime spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.179-as1-1-build-args-fix-dev |
| Last-applied annotation | identique au runtime spec, pas de drift GitOps |
| Pod status | 1/1 Running, age 21 min lors de la verification |
| Pod digest | sha256:b8a64abd378ac2b66dc9a4fd033390fe2a5430feafa0c143a55abe7d02990306 (identique au digest pousse) |

---

## 6. Validation Inbox Ludovic (QA visuel)

| Question | Reponse Ludovic | Verdict |
|---|---|---|
| Inbox DEV affiche la liste centrale ? | OK liste affichee | OK |
| Topbar tenant SWITAA SASU + user/email ? | OK | OK |
| Bandeau bas Donnees API vert ? | OK | OK |
| Liste centrale non vide ? | OK | OK |
| PROD intacte visuellement ? | OK PROD verifiee, intacte | OK |

---

## 7. Logs read-only post rollout

| Surface | Signal attendu | Resultat |
|---|---|---|
| API DEV -- hits /messages/conversations | au moins 1 GET liste apres refresh Inbox | OK : req-1lc GET /messages/conversations?tenantId=switaa-sasu-mnc1x4eq&limit=1000 (hostname api-dev.keybuzz.io), plus GET detail conversation |
| API DEV -- erreurs NextAuth / JWT / unauthor (10 min) | aucune nouvelle erreur | OK : 0 entree level 40/50 ni JWT/unauthor (seul log info OCTOPIA-SYNC tenants=0) |
| Appels DEV browser vers API PROD | aucun | OK : tous les hits API DEV ont hostname api-dev.keybuzz.io |
| Client DEV pod logs (10 min) | rien d'anormal | OK : aucun WARN/ERROR remonte |

Le browser appelle bien `https://api-dev.keybuzz.io/messages/conversations?...` ce qui confirme que le bundle inline DEV URL est utilise en runtime sans contournement.

---

## 8. Non-regression PROD et autres services

| Service | Avant fix v3.5.179 | Apres fix v3.5.179 | Verdict |
|---|---|---|---|
| Client DEV | v3.5.176-conversation-tone-metric-ux-dev | v3.5.179-as1-1-build-args-fix-dev | CHANGED (intentionnel, GO Ludovic) |
| API DEV | v3.5.168-escalation-notifications-dev | v3.5.168-escalation-notifications-dev | INCHANGE |
| API PROD | v3.5.151-conversation-tone-metric-prod | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | 2/2 ready | 2/2 ready | INCHANGE |
| Admin PROD | 1/1 ready | 1/1 ready | INCHANGE |
| DB / Stripe / billing / CAPI / tracking | non touches | non touches | INCHANGE |

---

## 9. Gaps restants (documentes, non corriges dans cette phase)

1. KEY-302 a ouvrir : rendre impossible un build Client sans build args explicites. Piste : remplacer le defaut Dockerfile par valeur invalide (`MUST_BE_OVERRIDDEN`) ou ajouter `RUN test -n "$NEXT_PUBLIC_API_BASE_URL"` qui casse le build si vide. Doit etre execute hors AS.1.2 dans une phase Dockerfile-hardening dediee.
2. KEY-301 reste ouvert : audit tenantGuardPlugin DEV/PROD requis avant toute promotion AS.1 PROD du badge escalation.
3. Badge escalation absent volontairement dans cette iteration. Le callsite useEscalationNotifsCount reste retire dans InboxTripane.tsx.
4. Code Client AS.1 partiellement orphelin conserve pour reintegration future : 4 fichiers en place (`app/api/notifications/route.ts`, `src/services/notifications.service.ts`, `src/features/inbox/hooks/useEscalationNotifsCount.ts`, prop optionnelle escalationNotifCount dans AgentWorkbenchBar.tsx).
5. Root cause runtime du badge AS.1 non confirmee. Hypothese tres forte : la regression v3.5.177 etait le meme bug build args, donc le code AS.1 est probablement innocent. Si confirmation souhaitee, extraire le bundle de l'image v3.5.177-escalation-notifications-ux-dev (encore en cache local Docker du bastion) et grep les URLs inlinees.
6. Dockerfile Client default PROD dangereux : adresse par KEY-302.

---

## 10. Rollback DEV documente (non execute sans GO)

Si v3.5.179 echoue plus tard :
- cible : v3.5.176-conversation-tone-metric-ux-dev
- via GitOps strict uniquement : edit k8s/keybuzz-client-dev/deployment.yaml -> commit + push + kubectl apply -f
- ne pas executer sans GO Ludovic
- l'image v3.5.176 est encore presente dans le cache local Docker du bastion ET dans le registry

---

## 11. Phrase cible finale

Inbox DEV restauree sur image v3.5.179-as1-1-build-args-fix-dev buildee avec les build args DEV explicites ; bundle browser inline `https://api-dev.keybuzz.io` (0 occurrence PROD) ; manifest = runtime = annotation = pod digest ; aucune regression API/Client/Backend PROD ni service connexe ; cause racine documentee (Dockerfile defaults PROD dangereux) ; KEY-302 a ouvrir pour rendre impossible la recurrence ; KEY-301 reste ouvert avant toute promotion PROD du badge AS.1.

STOP -- closeout AS.1.2 livre, en attente decisions sur KEY-301 et KEY-302.
