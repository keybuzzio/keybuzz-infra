# PH-SAAS-T8.12AS.20.39-BUILD-AMAZON-NOTIFICATION-CLASSIFICATION-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.39 (BUILD AMAZON NOTIFICATION CLASSIFICATION DEV)
> Environnement : DEV build-only, build-from-git, AUCUN push/deploy/kubectl/DB

## 1. Verdict

GO BUILD AMAZON NOTIFICATION CLASSIFICATION DEV PARTIAL PH-SAAS-T8.12AS.20.39

Les deux images DEV sont construites localement depuis Git (worktrees detaches propres aux commits exacts), avec labels OCI conformes (revision/version/created), markers source ET dist verifies, et zero side-effect (GHCR cibles absents, runtime DEV/PROD inchanges, manifests inchanges, restarts=0, images NON poussees). Le build lui-meme est entierement READY. Verdict PARTIAL (et non READY) sur UN seul point d'audit non bloquant : la suite de tests API ph119 (noReplyClassifier, PH-20.12B) n'a PAS pu etre RE-EXECUTEE dans cette phase faute de runner disponible (ni ts-node ni tsx dans le node_modules committe du repo api, ni dist compile committe). Cette couverture est assuree autrement : (a) tsc --noEmit = 0 erreur sur le commit api exact 8f050f06 (gate de compilation faisant autorite) ; (b) le classifier noReplyClassifier est INCHANGE par 8f050f06 (qui ne touche que ai-assist-routes.ts) et etait deja valide + deploye en PH-20.12B ; (c) le portage backend du meme jeu de regex passe 8/8 tests unitaires. Aucune regression detectee. message_source=SYSTEM confirme NON introduit par ce patch.

## 2. Preflight (E0)

| repo | branche | HEAD | origin | ahead | dirty | verdict |
|---|---|---|---|---:|---|---|
| keybuzz-backend | main | c38583a | c38583a | 0 | 1 (.bak untracked historique) | OK |
| keybuzz-api | ph147.4/source-of-truth | 8f050f06 | 8f050f06 | 0 | dist/ pre-existant (0 non-dist) | OK |
| keybuzz-infra | main | 277a7f3 | 277a7f3 | 0 | 0 | OK |

| service | namespace | image runtime | restarts |
|---|---|---|---:|
| keybuzz-backend | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | n/a |
| keybuzz-backend | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | 0 |
| keybuzz-api | keybuzz-api-dev | v3.5.256-autopilot-no-reply-kbactions-dev | n/a |
| keybuzz-api | keybuzz-api-prod | v3.5.257-autopilot-no-reply-kbactions-prod | n/a |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 ~15:47Z. GHCR tags cibles absents (skopeo) ; aucune image locale cible preexistante ; manifests ne referencent pas les tags cibles. latest non touche.

## 3. Verification commits source (E1)

- backend c38583a = c38583a8548e60d21d817b85f028cb1868aea532 ; fichiers : platformNotificationClassifier.ts (nouveau, 132) + inboxConversation.service.ts (21) + tests/platformNotificationClassifier.test.ts (81). 1 commit ahead origin (deja pousse PH-20.38).
- api 8f050f06 = 8f050f0644c0a1fb98d9b2d1430db03a956713b9 ; fichier : ai-assist-routes.ts (28).
- infra 277a7f3 (avant ce rapport).

## 4. Worktrees detaches (E2)

| worktree | commit (full SHA) | porcelain | node_modules symlink |
|---|---|---|---|
| /opt/keybuzz/build-worktrees/PH-20.39-backend-... | c38583a8548e60d21d817b85f028cb1868aea532 | 0 | none |
| /opt/keybuzz/build-worktrees/PH-20.39-api-... | 8f050f0644c0a1fb98d9b2d1430db03a956713b9 | 0 | none |

Note repo api : node_modules est COMMITE dans le repo keybuzz-api (16981 fichiers, pas de .gitignore) -> present dans le worktree, c'est le pattern de build etabli (builds v3.5.x). Mon symlink temporaire de test a ete retire ; porcelain=0 reconfirme. Mon .bak untracked PH-20.38 (amazon.routes.ts.bak) N'EST PAS dans le worktree detache (non committe). 9 fichiers .bak COMMITES (pre-existants, lignee v1.0.56) presents dans l'arbre backend ; non importes par du code ; tsc compile uniquement les .ts -> absents fonctionnellement de dist.

## 5. Audit source pre-build (E3)

| repo | marker | attendu | resultat |
|---|---|---|---|
| backend | classifyAmazonPlatformNotification | present | 3 fichiers |
| backend | AMAZON_SELLER_CENTRAL_NOTIFICATION | present | 2 |
| backend | platformNotification / Subtype | present | 3 / 1 |
| backend | stableAmazonMessageKey (guard buyer-first) | present | 2 |
| backend | pg_advisory_xact_lock (amzmsg) | INTACT | 1 |
| backend | computeInboundDedupLockScope (amzmsg) | INTACT | 2 |
| backend | OUTBOUND_EMAIL_SEND | INTACT | 3 |
| backend | message_source=SYSTEM | 0 | 0 |
| backend | hardcode ecomlg/4xfub8/3jcpvk/cp2hat/as0yom | 0 (hors fallback existant) | 1 (amazonFees.routes.ts default tenant, PRE-EXISTANT hors patch) |
| api | classifyNoReplyPlatformNotification | present | 4 |
| api | NO_REPLY_PLATFORM_NOTIFICATION (skip ai-assist) | present | 4 |
| api | debitKBActions (chemin normal) | present | 4 |
| api | autopilot skip engine.ts (PH-20.12B) | non regresse | 2 |
| api | hardcode dans ai-assist-routes.ts (fichier touche) | 0 | 0 |

## 6. Tests pre-build (E4)

| repo | test | attendu | resultat |
|---|---|---|---|
| backend | ts-node platformNotificationClassifier.test.ts | 8/8 | PASS 8/8 |
| backend | tsc --noEmit -p tsconfig.json | 0 erreur | PASS (0, 0 sur fichiers touches) |
| api | tsc --noEmit | 0 erreur | PASS (0, 0 sur fichiers touches) |
| api | ph119 noReplyClassifier re-run | re-executer si possible | NON EXECUTE (ni ts-node/tsx ni dist committe dans le toolchain api) -> couvert par tsc-clean + classifier inchange depuis PH-20.12B + miroir backend 8/8 |

node_modules symlinke uniquement pour les tests backend puis RETIRE avant docker build (porcelain=0). Incident PH-20.18 evite.

## 7. Images construites (E5/E6)

| image | tag | Image ID | revision | version | created |
|---|---|---|---|---|---|
| keybuzz-backend | v1.0.57-amazon-notification-classification-dev | sha256:5d965707a087b3e93c8fb2925bf2c07de11de1f1d30fb6fb2db67c9ac30a3f6c | c38583a8548e60d21d817b85f028cb1868aea532 | v1.0.57-amazon-notification-classification-dev | 2026-05-27T15:52:38Z |
| keybuzz-api | v3.5.258-amazon-notification-classification-dev | sha256:cb6f3601e97de61d7cc364f7e5ea5a628dff9b945039647a353f246e2611b4eb | 8f050f0644c0a1fb98d9b2d1430db03a956713b9 | v3.5.258-amazon-notification-classification-dev | 2026-05-27T15:53:01Z |

Build-args OCI injectes (IMAGE_REVISION/IMAGE_VERSION/IMAGE_CREATED) ; pas latest ; build depuis worktree detache uniquement ; aucun docker push.

## 8. Audit dist embarque (E7)

| image | marker dist | resultat |
|---|---|---|
| backend | platformNotificationClassifier | present (2) |
| backend | AMAZON_SELLER_CENTRAL_NOTIFICATION | present (2) |
| backend | platformNotification metadata | present (3) |
| backend | stableAmazonMessageKey (guard) | present (2) |
| backend | pg_advisory_xact_lock (amzmsg) | present (1) INTACT |
| backend | computeInboundDedupLockScope (amzmsg) | present (2) INTACT |
| backend | "Dedup lock acquired" | present (1) |
| backend | "Idempotent skip" | present (1) |
| backend | OUTBOUND_EMAIL_SEND | present (3) INTACT |
| backend | message_source=SYSTEM | 0 (non introduit) |
| api | classifyNoReplyPlatformNotification | present (4) |
| api | NO_REPLY_PLATFORM_NOTIFICATION (skip ai-assist-routes.js) | present (2 occ) |
| api | debitKBActions (chemin normal) | present (4) |
| api | ai_generation (non supprime globalement) | present (2) |
| api | message_source=SYSTEM dans ai-assist-routes.js | 0 |
| api | message_source=SYSTEM ailleurs | 1 = octopiaImport.service.js (PRE-EXISTANT, flux Octopia, hors patch) |

## 9. No side-effect (E8)

| signal | attendu | resultat |
|---|---|---|
| GHCR tag backend v1.0.57-amazon-notification | absent | ABSENT |
| GHCR tag api v3.5.258-amazon-notification | absent | ABSENT |
| runtime backend DEV/PROD | inchange | v1.0.56-*-dev / -prod (inchange) |
| runtime api DEV/PROD | inchange | v3.5.256-*-dev / v3.5.257-*-prod (inchange) |
| backend pod restarts | 0 / inchange | 0 |
| manifests references tags cibles | aucune | aucune |
| docker push | aucun | aucun |
| kubectl apply/set/patch/edit | aucun | aucun |
| DB mutation / migration / trigger / fake event | aucun | aucun |
| latest | non touche | non touche |
| worktrees | retires proprement | git worktree remove (sans --force ; porcelain=0) -> 0 restant |

## 10. AI feature parity / no fake metrics

- Messages buyer Amazon (metadata.amazonIds.messageId) : jamais classes notification (guard !stableAmazonMessageKey) ; restent message client, SLA arme.
- BUYER_HANDLE_RX / buyer-wins : present (classifier porte + api).
- Advisory lock amzmsg PH-20.26 (pg_advisory_xact_lock + computeInboundDedupLockScope) : present source ET dist backend (INTACT).
- Outbound KEY-323 + jobs-worker OUTBOUND_EMAIL_SEND : present dist (INTACT).
- Autopilot skip PH-20.12B : present (engine.ts 2 occ) non regresse.
- Ai-assist skip nouveau : uniquement no-reply notification (0 LLM / 0 KBActions) ; debitKBActions + ai_generation conserves pour le chemin normal.
- Classification niveau message/contexte ; conversations mixtes non masquees.
- message_source=SYSTEM NON introduit (confirme dist).
- Aucun fake event/metric/webhook/ledger : phase build-only, aucune ecriture DB ni emission.

## 11. Limites restantes

- API ph119 non re-execute (toolchain) : a relancer via ts-node dans un env outille, ou via le build CI ; couverture actuelle = tsc-clean + classifier inchange + miroir backend 8/8.
- message_source=SYSTEM : decision Client-aware deferee (hors scope).
- Images locales uniquement ; non poussees ; aucun deploy. Forward-looking (notifications futures ; pas de cleanup historique).
- .bak committes backend (9) + node_modules committe api : dette d'hygiene repo pre-existante, faithful-to-git, sans impact fonctionnel dist.

## 12. Rollback futur theorique

Aucun rollback necessaire (rien deploye). Images locales supprimables par docker rmi. Le runtime reste v1.0.56 (backend) / v3.5.256-257 (api). Un futur deploy DEV reste 100% reversible (GitOps : revenir au tag precedent dans le manifest).

## 13. Prochaine etape recommandee

GO PUSH IMAGE AMAZON NOTIFICATION CLASSIFICATION DEV PH-SAAS-T8.12AS.20.40 : docker push GHCR des 2 images + pull-back digest match, pour backend v1.0.57-amazon-notification-classification-dev (5d965707a087) et api v3.5.258-amazon-notification-classification-dev (cb6f3601e97d). (Option : relancer ph119 dans un env outille avant ou pendant push.)

## 14. Phrase cible

GO BUILD AMAZON NOTIFICATION CLASSIFICATION DEV PARTIAL PH-SAAS-T8.12AS.20.39

STOP.
