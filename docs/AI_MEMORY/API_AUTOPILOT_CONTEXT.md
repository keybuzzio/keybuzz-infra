# Contexte API et Autopilot KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : point d'entree pour API SaaS, IA, Autopilot, billing et integrations support.

## Surface

API principale du SaaS client.

Hosts :

- DEV : `api-dev.keybuzz.io`
- PROD : `api.keybuzz.io`

Stack documentee dans les rapports :

- Fastify
- Node.js
- TypeScript
- PostgreSQL

Sources locales partielles :

- `C:\DEV\KeyBuzz\V3\backend-src`
- `C:\DEV\KeyBuzz\V3\src`
- rapports `PH-*` dans `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs`
- manifests `keybuzz-api-dev` / `keybuzz-api-prod`

## Domaines API

- conversations/messages
- inbound/outbound
- autopilot
- IA engines
- orders/tracking
- billing/KBActions/Stripe
- tenant context
- agents/RBAC/escalation
- connectors Amazon/Octopia/Shopify
- metrics/admin internal endpoints

## Etat Autopilot courant

Sources cles :

- `PH-AUTOPILOT-E2E-TRUTH-AUDIT-01.md`
- `PH-AUTOPILOT-REAL-TENANT-BEHAVIOR-AUDIT-01.md`
- `PH-INBOUND-PIPELINE-TRUTH-04-REPORT.md`
- `PH-AUTOPILOT-BACKEND-CALLBACK-01.md`
- `PH-AUTOPILOT-BACKEND-DEV-INBOUND-RECEPTION-RECOVERY-01.md`
- `PH-AUTOPILOT-BACKEND-REAL-EMAIL-READINESS-01.md`
- `PH-AUTOPILOT-BACKEND-CALLBACK-PROD-PROMOTION-01.md`
- `PH-AUTOPILOT-CONSUME-PROMISE-ESCALATION-TRUTH-01.md`
- `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-FIX-01.md`
- `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-PROD-PROMOTION-01.md`
- `PH-AUTOPILOT-GITOPS-DRIFT-RECONCILIATION-01.md`

Ancien audit partiel au 2026-04-21 :

- Client OK.
- BFF OK.
- API OK.
- Consume escalation compile et est promu.
- Handoff escalation est deja fixe DEV + PROD.
- Tenant AUTOPILOT `switaa-sasu-mnc1x4eq` prouve que le pipeline fonctionne en DEV.
- `ecomlg-001` est bien bloque par le plan PRO, mais ce cas ne represente pas les tests reels de Ludovic.

Nuance utilisateur importante :

- Ludovic signale que la verite terrain n'est pas celle d'un simple plan gate.
- DEV : le volet de reponse automatique s'ouvre, mais l'escalade ne se materialise pas, y compris apres reponse via "Aide IA".
- PROD : le volet ne s'ouvre pas automatiquement, donc le message ne peut pas etre valide, et l'escalade ne peut pas se concretiser.
- PH152.2 avait restaure un `AutopilotDraftBanner`, mais Ludovic avait signale que ce n'etait pas le design attendu : il prenait trop de place dans la conversation au lieu d'un volet a droite.
- Donc les rapports PH147.5/PH152.2/PH-AUTOPILOT-E2E ne doivent pas etre lus comme une validation UX finale. Pour la prochaine phase, il faut une reouverture audit E2E lecture seule centree sur la divergence entre observation utilisateur et rapports CE.

Nouvelle verite etablie par `PH-AUTOPILOT-REAL-TENANT-BEHAVIOR-AUDIT-01.md` :

- Les tenants de test reels de Ludovic (`SWITAA` et `compta.ecomlg@gmail.com`) sont AUTOPILOT en DEV et PROD.
- Le plan n'est donc pas le bloqueur pour ces tests.
- L'Aide IA manuelle fonctionne en DEV et PROD pour ces tenants, avec escalade via PH142-D / promise detection.
- L'Autopilot auto-open fonctionne en DEV mais est bloque en PROD.
- Cause racine PROD : les messages Amazon reels sont crees par `keybuzz-backend` via `POST /api/v1/webhooks/inbound-email` et `inboxConversation.service.ts`, qui insere conversations/messages en DB sans declencher `evaluateAndExecute` dans `keybuzz-api`.
- Ancien point a verifier : `PH-INBOUND-PIPELINE-TRUTH-04-REPORT.md` avait deja documente un callback backend -> API dans `inboundEmailWebhook.routes.ts` en DEV. La prochaine phase doit verifier pourquoi ce callback est absent/perdu/non porte/non actif en PROD avant de repatcher.
- Nuance produit importante : le fix ne doit pas etre Amazon-only. Amazon PROD est le cas observe, mais le besoin est connector-agnostic : tout chemin backend qui cree une conversation/message inbound doit declencher ensuite l'evaluation Autopilot via l'API, sinon Shopify/Cdiscount/Fnac/autres connecteurs auront le meme bug.

Preflight CE du 2026-04-21 pour `PH-AUTOPILOT-BACKEND-INBOUND-TRIGGER-BRIDGE-01` :

- `keybuzz-api` : branche `ph147.4/source-of-truth`, HEAD `7265d29a`.
- `keybuzz-backend` : repo distinct, branche `main`, HEAD `68aa2dd`; la branche `ph147.4/source-of-truth` n'existe pas dans ce repo.
- Le fix `PH-INBOUND-PIPELINE-TRUTH-04` est perdu dans la source backend actuelle : aucune reference `autopilot/evaluate`, aucune reference `API_INTERNAL_URL` dans `src/`.
- Drift GitOps backend DEV : manifest DEV `v1.0.40-ph145.6-tenant-fk-fix-dev`, deploy reel DEV `v1.0.44-ph150-thread-fix-prod`.
- Backend PROD/DEV runtime : image `v1.0.44-ph150-thread-fix-prod`.
- `API_INTERNAL_URL` PROD pointe vers `:3001` alors que le service K8s PROD expose `80`; ce port doit etre corrige lors de la promotion PROD, pas dans la phase DEV-only.

Rapport final `PH-AUTOPILOT-BACKEND-CALLBACK-01.md` :

- Verdict DEV : `AUTOPILOT BACKEND CALLBACK RESTORED IN DEV - CONNECTOR-AGNOSTIC - BACKEND MAIN SOURCE LOCKED - PROD UNTOUCHED`.
- Source backend : `keybuzz-backend/main`, remote officiel, image DEV `v1.0.45-autopilot-backend-callback-dev`, digest `sha256:9ff366d1d86cd7ecd3c1c72f95746eb3e8c5830d5b75770f4eb13bdae21d5b51`.
- Callback restaure dans `src/modules/webhooks/inboxConversation.service.ts`, dans `createInboxConversation()`, donc plus generique que PH-04 qui etait dans une route webhook.
- Callback : `POST ${API_INTERNAL_URL}/autopilot/evaluate`, headers `X-Tenant-Id` et `X-User-Email` quand disponible.
- Validation DEV sur `amazon`, `octopia`, `email` via `createInboxConversation()` : callback `status=200`, logs API `[Autopilot]`, preuve non Amazon-only.
- Important : le webhook HTTP complet `POST /api/v1/webhooks/inbound-email` echoue encore en DEV avec Prisma `P2021` (`ExternalMessage` table inexistante dans DB backend). C'est documente comme pre-existant. Ne pas conclure que le chemin HTTP inbound complet est valide tant que ce point n'est pas audite.
- PROD non touchee. Promotion PROD devra au minimum corriger `API_INTERNAL_URL` vers `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80` et verifier le sujet `ExternalMessage P2021`.

Rapport final `PH-AUTOPILOT-BACKEND-DEV-INBOUND-RECEPTION-RECOVERY-01.md` :

- Verdict : `DEV INBOUND RECEPTION RESTORED - PROD UNTOUCHED - PROD PROMOTION BLOCKED UNTIL TRUE HTTP INBOUND VALIDATED`.
- Cause racine : `inboundEmailWebhook.routes.ts` utilisait `prisma.externalMessage` vers `keybuzz_backend`, alors que PH-TD-05 a migre `ExternalMessage` vers la product DB `keybuzz`; consequence `P2021`, `createInboxConversation()` jamais atteint.
- Fix DEV : migration de `prisma.externalMessage.findUnique/create` vers `productDb.query()` dans `inboundEmailWebhook.routes.ts`.
- Image DEV : `v1.0.46-ph-recovery-01-dev`, digest `sha256:6aae45da06e556fb74d1bd04d23f434020c59695f4cab634d8dc8ca9326382ed`.
- Callback PH-CALLBACK-01 reste present et fonctionnel apres recovery.
- Validation CE : webhook HTTP 200, ExternalMessage product DB cree, conversation/message crees, idempotence OK, callback Autopilot `status=200`, API `[Autopilot]`.
- Validation utilisateur terrain apres rapport : Ludovic a envoye un vrai email a `amazon.switaa-sasu-mnc1x4eq.fr.ulnllr@inbound.keybuzz.io` et l'a bien recu dans KeyBuzz DEV. Ce tenant SWITAA est AUTOPILOT, donc cette validation est plus pertinente que `ecomlg-001` PRO pour l'auto-open, mais CE doit encore consigner les preuves logs/DB du callback/draft sur ce vrai message.

Rapport final `PH-AUTOPILOT-BACKEND-REAL-EMAIL-READINESS-01.md` :

- Verdict : `REAL EMAIL DEV AUTOPILOT PIPELINE VALIDATED - PROD READINESS ESTABLISHED - GO PROD PROMOTION`.
- Vrai email SWITAA DEV valide : expediteur `switaa26@gmail.com`, inbound `amazon.switaa-sasu-mnc1x4eq.fr.ulnllr@inbound.keybuzz.io`, tenant AUTOPILOT `switaa-sasu-mnc1x4eq`.
- Pipeline valide : ExternalMessage product DB, conversation/message inbound, `autopilot_reply` 7s apres inbound, draft applique, reponse outbound envoyee.
- Reponse Autopilot coherent : commande `171-544451-556985`, colis `1Z121122512368`, contexte reparation, ton professionnel.
- PROD readiness : v1.0.44 PROD ne contient ni check ExternalMessage ni callback Autopilot; promotion doit builder `v1.0.46-ph-recovery-01-prod` depuis commit `f0f0d18` et corriger `API_INTERNAL_URL` PROD vers le port service `:80`.
- Attention : le rapport mentionne des exemples `kubectl set env` / `kubectl set image`, mais les regles KeyBuzz courantes imposent GitOps strict. La promotion PROD doit passer par manifests + commit/push/apply GitOps, pas par mutation imperative.

Rapport final `PH-AUTOPILOT-BACKEND-CALLBACK-PROD-PROMOTION-01.md` :

- Verdict CE : `AUTOPILOT BACKEND CALLBACK PROMOTED TO PROD - TRUE INBOUND VALIDATED - CONNECTOR-AGNOSTIC - NON REGRESSION OK`.
- Image backend PROD : `v1.0.46-ph-recovery-01-prod`, digest `sha256:37d8798f6e082eaec7d735bb47afe4d4a9a81a7d70aa955f24260ac992269cd3`.
- `API_INTERNAL_URL` PROD corrige vers `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80`.
- Validation CE : webhook -> ExternalMessage -> conversation -> callback -> Autopilot -> draft en ~6s, `DRAFT_GENERATED`, 6.43 KBA.
- Observation utilisateur apres promotion : PROD ouvre bien le volet automatiquement et genere une suggestion coherente, mais apres validation/envoi d'un message contenant une promesse d'escalade, l'escalade ne se materialise pas. Il faut donc investiguer cote API Autopilot consume/classification/promise-detection, pas cote backend callback.
- Hypothese forte a verifier : le draft est cree en `DRAFT_GENERATED` alors que le contenu contient une promesse humaine; ou bien le flow consume d'un draft normal bypass la detection de promesse qui existe sur le flow Aide IA/reply.

Rapport final `PH-AUTOPILOT-CONSUME-PROMISE-ESCALATION-TRUTH-01.md` :

- Verdict : `AUTOPILOT CONSUME PROMISE ESCALATION ROOT CAUSE IDENTIFIED`.
- Cas PROD : conversation `cmmo8sz5rd8f173c865e32cb4`, tenant SWITAA PROD `switaa-sasu-mnc1ouqu`, draft `DRAFT_GENERATED`, contenu avec promesses ("je transmets immediatement", "notre equipe va verifier", "s'assurer que vous receviez"), consume effectue, outbound envoye, `escalation_status=none`.
- Cause A : `engine.ts:detectFalsePromises` regex trop etroites, surtout `je vais + infinitif`; ne couvre pas present (`je transmets`), futur simple (`je verifierai`), 3eme personne (`notre equipe va verifier`), reflexif/infinitif lie.
- Cause B : `/autopilot/draft/consume` fait confiance a `blocked_reason`; si `DRAFT_GENERATED`, aucune redetection et aucune escalade.
- Cause C : filet `messages/routes.ts` PH143-E.8 a la meme lacune regex.
- Fix recommande : etendre la detection de promesses et ajouter un guardrail consume. Preferer un helper partage minimal pour eviter trois listes divergentes; si refactor trop large, patcher au minimum engine + consume + reply avec les memes patterns et tests.

Rapport final `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-FIX-01.md` :

- Verdict DEV : `AUTOPILOT PROMISE DETECTION GUARDRAIL FIXED IN DEV - PROD UNTOUCHED`.
- Source API : branche `ph147.4/source-of-truth`, image DEV `v3.5.92-autopilot-promise-detection-guardrail-dev`, digest `sha256:27fbc3dd71d831ef3ff81f0e8438e30ebc276cb1188fe5301f2ce018363dc303`.
- Commits API : `f833b4c8` helper partage + guardrail, puis `fcf8d67c` fix SQL.
- Helper partage cree : `src/lib/promise-detection.ts`, 37 patterns, source de verite pour engine, consume, reply classique et AI assist.
- Guardrail consume ajoute : un `DRAFT_GENERATED` applique contenant une promesse est re-detecte et escalade (`escalation_status=escalated`, `status=pending`, event `autopilot_escalate`).
- Validation DEV : phrases reelles detectees (`je transmets`, `je transmettrai`, `je verifierai`, `notre equipe va verifier`, `nous organiserons`, etc.), cas non-promesse non escalades.
- Bug critique corrige : un commentaire JS `//` dans la requete SQL de `routes.ts` cassait l'escalade `ESCALATION_DRAFT` depuis `7265d29a`. Cela signifie que PROD `v3.5.91` peut etre cassee meme pour des drafts deja classes `ESCALATION_DRAFT`; promotion API recommandee apres validation Ludovic.

Rapport final `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-PROD-PROMOTION-01.md` :

- Verdict : `AUTOPILOT PROMISE DETECTION GUARDRAIL PROMOTED TO PROD - ESCALATION HANDOFF VALIDATED - NON REGRESSION OK`.
- Image API PROD : `v3.5.92-autopilot-promise-detection-guardrail-prod`, digest `sha256:d4a26f468e11c13a7c0db9ba1afcdb1c24709a4e9ae426d433f17d36e3fa92ad`.
- Source API : branche `ph147.4/source-of-truth`, commit `fcf8d67c`.
- DEV/PROD API alignees sur le meme codebase : DEV `v3.5.92-autopilot-promise-detection-guardrail-dev`, PROD `v3.5.92-autopilot-promise-detection-guardrail-prod`.
- Validation PROD :
  - Cas A guardrail : `DRAFT_GENERATED` avec "je transmets / recontacter" -> consume `escalated:true`, `escalation_status=escalated`, `status=pending`.
  - Cas B `ESCALATION_DRAFT` -> consume OK, pas d'erreur SQL, `escalation_status=escalated`, `status=pending`.
  - Cas C non-promesse -> pas d'escalade, zero faux positif.
- Non-regression PROD OK selon rapport : API/backend health, backend callback, billing, metrics/tracking, client/admin non touches.
- Ecart process a noter : le rapport mentionne `kubectl set image` pendant le deploy, malgre la regle demandant GitOps strict. Le manifest GitOps a ete mis a jour (`e0d3681`), mais les prochains prompts doivent continuer d'interdire les mutations imperatives et demander un deploy manifest/GitOps strict.

Rapport final `PH-AUTOPILOT-GITOPS-DRIFT-RECONCILIATION-01.md` :

- Verdict : `GITOPS DRIFT RECONCILED - RUNTIME MATCHES MANIFEST - IMPERATIVE DEPLOYMENT DEBT CLOSED`.
- Manifest PROD `e0d3681` contenait deja la bonne image API `v3.5.92-autopilot-promise-detection-guardrail-prod`; runtime cluster aligne, zero drift fonctionnel.
- Dette constatee : annotation `kubectl.kubernetes.io/last-applied-configuration` obsolete (pointait vers `v3.5.90`) a cause des promotions imperatives precedentes.
- Reconciliation : `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml` et DEV equivalent, sans rollout, meme pod, 0 restart, meme digest.
- Durcissement : `.cursor/rules/process-lock.mdc` enrichi avec interdiction explicite `kubectl set image`, `kubectl set env`, `kubectl edit`, `kubectl patch` sauf reconciliation depuis manifest.

Fix deja fait :

- Rapport DEV : `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01.md`
- Rapport PROD : `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-PROD-PROMOTION-01.md`
- Changement : `status='pending'` au lieu de `status='escalated'` dans `src/modules/autopilot/routes.ts`
- Images : `v3.5.91-autopilot-escalation-handoff-fix-dev` et `v3.5.91-autopilot-escalation-handoff-fix-prod`

## Prochaine phase probable

Surveillance post-promotion Autopilot / aucun prompt de fix immediat

Objectif probable :

- Autopilot inbound backend, auto-open, detection promesse, consume guardrail et handoff escalation sont valides DEV/PROD.
- GitOps drift ferme : runtime = manifest = annotation DEV/PROD pour l'API.
- Prochaine action immediate : surveiller les retours terrain et ne pas relancer de fix sans nouveau symptome concret.
- Si nouveau prompt CE : inclure chemin complet du rapport final et rappeler interdiction `kubectl set image` / `kubectl set env`.
- verrouiller la branche/source de build par service avant toute image : `keybuzz-backend` sur `main`, `keybuzz-api` en lecture seule sur `ph147.4/source-of-truth` si besoin;
- ne toucher ni client, ni API engine, ni plan/settings;
- valider le vrai chemin inbound backend, pas seulement un appel direct a `createInboxConversation()`;
- PROD uniquement sur validation explicite.

## Billing / KBActions

Regles durables :

- le client voit des KBActions, pas les couts LLM;
- STARTER : gate fort;
- PRO : suggestions IA, pas Autopilot autonome;
- AUTOPILOT : mode autonome/supervise avance;
- attention aux anomalies historiques `pro` vs `PRO`;
- `ecomlg-001` est pilote/internal_admin/billing exempt selon rapports.

## Connecteurs

Amazon :

- SP-API, OAuth, inbound address, orders sync, outbound messaging, threading.
- Attention au payload `{}` truthy : verifier contenu reel et `OrderStatus`.

Octopia :

- connect, import, sync, adapter readonly/outbound selon phases.

Shopify :

- integration recente, a recouper avec rapports `PH-SHOPIFY-*`.

## Regles

- DEV avant PROD.
- Branche/source de build obligatoire avant toute image, par repo/service : repo exact, branche autorisee, commit attendu, repo clean, tag immuable, digest et rollback.
- Ne pas hardcoder tenant, URL ou secret.
- Ne jamais activer Autopilot pour tous les PRO sans decision produit.
- Ne pas refaire une phase deja terminee si un rapport recent prouve qu'elle est promue.
- Toujours fournir rollback SQL/code quand une decision DB est appliquee.
