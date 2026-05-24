# PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-PUSH-IMAGE-PROD-01

> Date : 2026-05-24
> Linear : KEY-337 parent PH-20 ; KEY-231 KBActions trial value/anxiety ; KEY-270 cloture audits IA ; references KEY-312 / KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.12B
> Environnement : PUSH GHCR API PROD (no build, no deploy, no kubectl mutation)

## VERDICT

GO PUSH IMAGE API AUTOPILOT NO-REPLY KBACTIONS PROD READY PH-SAAS-T8.12AS.20.12B

Prochaine phrase GO recommandee : GO APPLY API AUTOPILOT NO-REPLY KBACTIONS PROD PH-SAAS-T8.12AS.20.12B

## Resume executif

Image API PROD PH-20.12B pushe sur GHCR avec succes depuis l'image locale precedemment buildee from-git (rapport build PROD : commit infra 014c25b). Pull-back confirme : config digest local == GHCR. Manifest digest GHCR documente. OCI revision preserve. Parite bit-for-bit DEV/PROD sur 5 fichiers critiques deja prouvee (rapport build PROD).

Aucun build, aucun deploy, aucun kubectl mutation, aucun runtime change.

Image disponible sur GHCR :
- Tag : ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod
- Config digest : sha256:6a426a52780a490d0682a8bd7a0ad5d0149cee0ebed381147335e5fed86bc477
- Manifest digest GHCR : sha256:52ec1bcf01de49803d56f17badd25ae558f7777eb59016824706f6f7d72d3ba3
- Repo digest : ghcr.io/keybuzzio/keybuzz-api@sha256:52ec1bcf01de49803d56f17badd25ae558f7777eb59016824706f6f7d72d3ba3
- OCI revision : 38c048c07fb98543437228657564ef4de388bdfb (MATCH commit source PH-20.12B)
- Push delta : 6 layers pushed + 4 layers reused
- Manifest size : 2416 bytes
- Layers count : 10 (5 base node:lts-alpine + 5 app)

KEY-308 OCI labels 6/6 preserves. KEY-309 tag immuable respecte.

## Sources lues

1. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
2. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
3. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
4. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
5. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-READONLY-AUDIT-01.md (0f23944)
6. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-SOURCE-PATCH-DEV-01.md (84fe251)
7. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-QA-DEV-01.md (baf7254)
8. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-BUILD-PROD-01.md (014c25b)

## Preflight E0

| Item | Attendu | Constate | Verdict |
|---|---|---|---|
| Bastion hostname | install-v3 | install-v3 | OK |
| Bastion IP externe | 46.62.171.61 | 46.62.171.61 | OK |
| Date UTC | 2026-05-24 | 2026-05-24 10:29 UTC | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD | 014c25b (build PROD report) | 014c25bc92c8abce792fe424538eee3e1fa06834 | OK |
| keybuzz-infra dirty | clean | clean | OK |

Runtime baseline (E0 + E4) :

| Service | Image | Pod | Uptime | Restarts | Verdict |
|---|---|---|---|---|---|
| keybuzz-api DEV | v3.5.256-autopilot-no-reply-kbactions-dev | kpbjg | 70m -> 71m | 0 | LIVE INCHANGE |
| keybuzz-client DEV | v3.5.214-ai-draft-blocked-reason-dev | (preserve) | preserve | 0 | LIVE INCHANGE |
| keybuzz-api PROD | v3.5.255-ai-draft-blocked-reason-prod | qv4jd | 25h | 0 | LIVE INCHANGE |
| keybuzz-client PROD | v3.5.215-ai-draft-blocked-reason-prod | (preserve) | preserve | 0 | LIVE INCHANGE |

## E1 - Image locale + GHCR collision

| Item | Local | GHCR avant push | Verdict |
|---|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod | absent (manifest unknown) | LIBRE |
| Image ID | sha256:6a426a52780a490d0682a8bd7a0ad5d0149cee0ebed381147335e5fed86bc477 | N/A | OK MATCH build report |
| Size | 343 519 201 bytes (327 MiB) | N/A | OK IDENTIQUE DEV (parite source) |
| OCI revision | 38c048c07fb98543437228657564ef4de388bdfb | N/A | OK MATCH commit source = MATCH DEV |
| OCI version | v3.5.257-autopilot-no-reply-kbactions-prod | N/A | OK MATCH tag |
| Created | 2026-05-24T09:53:18.681730404Z | N/A | OK |
| KEY-309 tag immuable | OK (jamais :latest) | N/A | COMPLIANT |

## E2 - Docker push GHCR

| Item | Valeur | Verdict |
|---|---|---|
| Commande | docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod | EXECUTE |
| Layers pushed | 6 (bb28d7412d98, 72198770a9dd, 7c6cbbb86d36, 3490c8bdf16b, f2be53877b09, 1f49c656067c) | OK app layers nouvelles |
| Layers reused | 4 (7a7517ab2e5a, 9cc01943aa82, 1162d08df74c, 29df493baa13) | OK base node:lts-alpine deja en cache GHCR depuis push DEV |
| Manifest size apres push | 2416 bytes | OK identique DEV (memes layers de base) |
| Manifest digest GHCR | sha256:52ec1bcf01de49803d56f17badd25ae558f7777eb59016824706f6f7d72d3ba3 | OK nouveau, distinct DEV (metadata image differente) |
| Result | v3.5.257-autopilot-no-reply-kbactions-prod: digest: sha256:52ec1bcf01de49803d56f17badd25ae558f7777eb59016824706f6f7d72d3ba3 | PUSH SUCCESS |

Aucun rebuild, aucun retag, aucun push d autre tag.

## E3 - Pull-back + GHCR audit

| Item | Valeur | Verdict |
|---|---|---|
| Manifest schema | v2 application/vnd.docker.distribution.manifest.v2+json | OK |
| Manifest config size | 12956 bytes | OK |
| Manifest config digest (GHCR) | sha256:6a426a52780a490d0682a8bd7a0ad5d0149cee0ebed381147335e5fed86bc477 | OK |
| Local image ID | sha256:6a426a52780a490d0682a8bd7a0ad5d0149cee0ebed381147335e5fed86bc477 | OK |
| **Config digest local == GHCR** | OUI | MATCH ABSOLU |
| Pull-back result | "Image is up to date" | OK preserve local |
| Repo digest apres pull | ghcr.io/keybuzzio/keybuzz-api@sha256:52ec1bcf01de49803d56f17badd25ae558f7777eb59016824706f6f7d72d3ba3 | OK |
| Manifest digest GHCR | sha256:52ec1bcf01de49803d56f17badd25ae558f7777eb59016824706f6f7d72d3ba3 | OK (repo digest == manifest digest) |
| OCI revision label apres pull | 38c048c07fb98543437228657564ef4de388bdfb | OK PRESERVE MATCH commit source PH-20.12B |
| Layers count | 10 (5 base node:lts-alpine + 5 app) | OK conforme structure attendue Dockerfile multi-stage |

Parite DEV vs PROD (heritage build PROD report 014c25b) :

| Indicateur | DEV v3.5.256 | PROD v3.5.257 | Parite |
|---|---|---|---|
| Manifest digest GHCR | sha256:5f50cc82ce6452bb2de35c129020348c6ea8d2dd47522f1d6061e81188116b92 | sha256:52ec1bcf01de49803d56f17badd25ae558f7777eb59016824706f6f7d72d3ba3 | DIFFERENT (metadata image differente : tag + version + description + created) |
| Config digest | sha256:14060c7fab3496ab14788234497dc6fba383a28a4edc8b7498b84a744e7620b8 | sha256:6a426a52780a490d0682a8bd7a0ad5d0149cee0ebed381147335e5fed86bc477 | DIFFERENT (metadata image differente) |
| OCI revision | 38c048c07fb98543437228657564ef4de388bdfb | 38c048c07fb98543437228657564ef4de388bdfb | IDENTIQUE MATCH commit source |
| Image size | 343 519 201 bytes | 343 519 201 bytes | IDENTIQUE preuve mathematique parite source |
| Dist sha256 noReplyClassifier.js | 92765d7c8c80... | 92765d7c8c80... | IDENTIQUE bit-for-bit |
| Dist sha256 engine.js | ffea0ec1ed6f... | ffea0ec1ed6f... | IDENTIQUE bit-for-bit |
| Dist sha256 kbactions.js | 8fa8b5de4a58... | 8fa8b5de4a58... | IDENTIQUE bit-for-bit |
| Dist sha256 ph119-tests.js | e2b6da3e00fd... | e2b6da3e00fd... | IDENTIQUE bit-for-bit |
| Dist sha256 autopilotGuardrails.js | 74e4da5b6d37... | 74e4da5b6d37... | IDENTIQUE bit-for-bit (doctrine preserve) |

## E4 - Runtime preserve

| Service | Avant push | Apres push | Pod restart pendant push | Verdict |
|---|---|---|---|---|
| keybuzz-api DEV | v3.5.256 pod kpbjg 70m 0 restart | v3.5.256 pod kpbjg 71m 0 restart | 0 | PRESERVE |
| keybuzz-api PROD | v3.5.255 pod qv4jd 25h 0 restart | v3.5.255 pod qv4jd 25h 0 restart | 0 | PRESERVE |
| keybuzz-client DEV | v3.5.214 | v3.5.214 | 0 | PRESERVE |
| keybuzz-client PROD | v3.5.215 | v3.5.215 | 0 | PRESERVE |
| Manifests GitOps | INCHANGE | INCHANGE | N/A | PRESERVE |

Aucun deploy, aucun kubectl mutation, aucun rollout restart. Image v3.5.257 disponible sur GHCR mais NON deployee.

## AI feature parity / anti-regression

Image PROD pushee herite des memes garanties que QA DEV 25/25 PASS (sha256 dist IDENTIQUE entre DEV et PROD = parite mathematique du comportement runtime) :

| Feature | Image PROD pushed v3.5.257 | Runtime PROD actuel v3.5.255 | Verdict |
|---|---|---|---|
| noReplyClassifier.js (dist sha256 92765d7c8c80...) | present (parite DEV bit-for-bit) | absent | NEW READY mais NON deploye |
| autopilot_skipped_no_reply weight 0.0 (dist sha256 8fa8b5de...) | present | absent | NEW READY |
| classifyNoReplyPlatformNotification wired (dist sha256 ffea0ec1...) | present | absent | NEW READY |
| ph119-tests.js (dist sha256 e2b6da3e...) | present | absent | NEW READY |
| KBActions no-reply notifications cible 0 | OUI (parite DEV prouvee QA 25/25) | actuellement 6-12 KBA debites (audit PH-20.12) | NEW cible post-deploy |
| PH-20.11C blockedInfo preserve | PRESERVE (sha256 engine.js IDENTIQUE DEV, dist markers 5+2+5) | LIVE | PARITE preserve |
| autopilotGuardrails source hash 3b85a276 + dist sha256 74e4da5b6d37 | IDENTIQUE (parite source + dist DEV bit-for-bit) | INCHANGE | PRESERVE 100% doctrine |
| refundProtectionLayer + 15 refund refs | PRESERVE dist | LIVE | PRESERVE |
| ai-assist-routes.js / autopilot/routes.js | PRESERVE dist | LIVE | PRESERVE |
| Brouillon IA cout normaux (inbox_suggestion 6.0 / inbox_contextualized 10.0) | PRESERVE (test QA DEV 6.16 / 9.79 dans fourchette ; dist kbactions.js IDENTIQUE) | LIVE | PRESERVE |
| /ai/assist / /ai/execute / /autopilot/draft/consume | PRESERVE routes (dist files preserve) | LIVE | PRESERVE |
| LLM calls pendant push | 0 | LIVE | OK |
| Drafts generes pendant push | 0 | LIVE | OK |
| Messages marketplace pendant push | 0 | LIVE | OK |
| Runtime change pendant push | 0 | INCHANGE | OK |
| KEY-305 race UI Client | preserve | preserve | PRESERVE |
| KEY-263 DEV/PROD isolation | preserve | preserve | PRESERVE |
| KEY-302 build args sentinel | preserve (Dockerfile inchange) | preserve | PRESERVE |
| KEY-308 OCI labels 6/6 | OK | OK | COMPLIANT |
| KEY-309 tag immuable | OK (v3.5.257-...-prod unique) | OK | COMPLIANT |
| KEY-312 PH-20.11C Done | preserve doctrine | preserve doctrine | PRESERVE |

## No fake metrics / no fake events / no fake KBActions

| Risque | Verification | Verdict |
|---|---|---|
| Fake event tracking | aucun (push image registry, hors runtime apps) | OK |
| Fake lead/register/checkout | aucun | OK |
| Fake message marketplace | aucun | OK |
| Fake KBActions debit | aucun (push n appelle pas wallet) | OK |
| Fake conversation INSERT | aucun (aucune connexion DB) | OK |
| Fake KPI / dashboard | aucun | OK |
| Mutation DB | aucune | OK |
| Backfill stats | aucun | OK |
| Push utilise wallet ou LLM | NON (Docker registry I/O uniquement) | OK |

## Confirmations securite

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build | OUI | 0 commande build (push only) |
| docker tag vers latest | OUI | jamais utilise |
| push d autre tag | OUI | seul v3.5.257-autopilot-no-reply-kbactions-prod push |
| kubectl apply / set / patch / edit / delete / rollout restart | OUI | uniquement kubectl get pour preflight + runtime preserve |
| modifier manifest GitOps | OUI | aucun keybuzz-infra/k8s/ touche |
| modifier source applicatif | OUI | aucun |
| LLM call | OUI | 0 |
| KBActions consommee | OUI | 0 |
| mutation DB | OUI | 0 (push GHCR, aucune connexion DB) |
| message marketplace | OUI | 0 |
| fake event/metric/conversation/KBActions | OUI | 0 |
| secret/token/PII brut | OUI | aucun dans logs push (layer digests + manifest digest seulement) |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| dump env de pods | OUI | 0 |
| /ai/assist / /ai/execute / /autopilot/draft/consume | OUI | 0 appel |
| Bastion install-v3 (46.62.171.61) | OUI | hostname + IP verifies E0 |
| git reset --hard / git clean | OUI | 0 commande destructive |
| Modification Client/Admin/Website/Backend | OUI | aucune (push API PROD only) |
| Creation ticket Linear | OUI | 0 |
| Changement statut Linear | OUI | 0 transition |
| Authentification docker | OK | session GHCR pre-configuree, aucun token affiche dans logs |

## Rollback

| Element | Plan | Verdict |
|---|---|---|
| Runtime DEV/PROD | N/A (aucun deploy) | RUNTIME PRESERVE |
| Manifest GitOps | N/A (aucun modifie) | INCHANGE |
| Image GHCR pousee | Ne pas referencer le tag dans aucun deployment ; supprimer le tag GHCR uniquement avec GO Ludovic explicite (action irreversible cote registry mais sans impact runtime tant que non deploye) | RECOVERABLE par non-deploy |
| Image locale | docker rmi possible (preserve si futur deploy PROD) | OK |
| Source commit 38c048c0 | git revert dans phase separee si necessaire | OK plan documente |

## Linear

Commentaires sur tickets pertinents (statut INCHANGE 100%, 0 ticket cree) :
- KEY-337 (parent PH-20) : push GHCR PROD success
- KEY-231 (KBActions trial value/anxiety) : image PROD dispo GHCR, pas encore runtime
- KEY-270 (cloture audits IA) : court rattachement
- KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-312 : NON commentes (preserves)

## Gaps restants / V2 ideas (NON engages)

1. GitOps PROD apply : phase PH-20.12B-APPLY-PROD (GO Ludovic requis, modifie manifest API PROD + kubectl apply + rollout)
2. Validation negative read-only smoke PROD post-deploy
3. QA browser Ludovic PROD sur conv reelle bloquee / notif Amazon entrante
4. Observation runtime 24-48h PROD : compter via SQL read-only les ai_action_log nouveaux entries avec reason=NO_REPLY_PLATFORM_NOTIFICATION:<subtype> et confirmer kbaCost=0
5. Closeout PH-20.12B end-to-end + transition KEY-337 / KEY-270 / KEY-231 statut (avec GO Ludovic explicite)
6. Client UI enrichissement noReplyInfo dans AISuggestionSlideOver (PH-20.12B-CLIENT optionnel)
7. V2 metric dashboard "Notifications skippees ce mois (KBActions economisees)"
8. V2 atoz-guarantee : workflow specifique Litige A-Z (subtype AMAZON_ATOZ_NOREPLY deja prepare)

## Prochaine phrase GO

**GO APPLY API AUTOPILOT NO-REPLY KBACTIONS PROD PH-SAAS-T8.12AS.20.12B**

STOP.
