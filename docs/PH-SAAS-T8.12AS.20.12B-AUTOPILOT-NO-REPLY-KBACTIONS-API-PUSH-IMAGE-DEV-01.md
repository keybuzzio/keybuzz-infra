# PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-PUSH-IMAGE-DEV-01

> Date : 2026-05-24
> Linear : KEY-337 parent PH-20 ; KEY-231 KBActions trial value/anxiety ; KEY-270 cloture audits IA ; references KEY-308 / KEY-309 / KEY-312 / KEY-235 / KEY-305 / KEY-263 / KEY-302
> Phase : PH-SAAS-T8.12AS.20.12B
> Environnement : PUSH GHCR API DEV (no build, no deploy, no kubectl mutation)

## VERDICT

GO PUSH IMAGE API AUTOPILOT NO-REPLY KBACTIONS DEV READY PH-SAAS-T8.12AS.20.12B

Prochaine phrase GO recommandee : GO APPLY API AUTOPILOT NO-REPLY KBACTIONS DEV PH-SAAS-T8.12AS.20.12B

## Resume executif

Image API DEV PH-20.12B pushe sur GHCR avec succes depuis l'image locale precedemment buildee from-git (rapport build : commit infra 841d0d8). Pull-back confirme : config digest local == GHCR. Manifest digest GHCR documente. OCI revision preserve. Aucun build, aucun deploy, aucun kubectl mutation, aucun runtime change.

Image disponible sur GHCR :
- Tag : ghcr.io/keybuzzio/keybuzz-api:v3.5.256-autopilot-no-reply-kbactions-dev
- Config digest : sha256:14060c7fab3496ab14788234497dc6fba383a28a4edc8b7498b84a744e7620b8
- Manifest digest GHCR : sha256:5f50cc82ce6452bb2de35c129020348c6ea8d2dd47522f1d6061e81188116b92
- Repo digest : ghcr.io/keybuzzio/keybuzz-api@sha256:5f50cc82ce6452bb2de35c129020348c6ea8d2dd47522f1d6061e81188116b92
- OCI revision : 38c048c07fb98543437228657564ef4de388bdfb (MATCH commit source PH-20.12B)
- Push delta : 6 layers pushed + 4 layers reused

KEY-308 OCI labels 6/6 preserves. KEY-309 tag immuable respecte (jamais :latest, version unique reservee).

Doctrine seller-first/refund-protection / PH-20.11C blockedInfo preserves dans le dist construit (audit precedent PH-20.12B-BUILD).

## Sources lues

1. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
2. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
3. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
4. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
5. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-READONLY-AUDIT-01.md (commit infra 0f23944)
6. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-SOURCE-PATCH-DEV-01.md (commit infra 84fe251)
7. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-BUILD-DEV-01.md (commit infra 841d0d8)

## Preflight E0

| Item | Attendu | Constate | Verdict |
|---|---|---|---|
| Bastion hostname | install-v3 | install-v3 | OK |
| Bastion IP externe | 46.62.171.61 | 46.62.171.61 | OK |
| Date UTC | 2026-05-24 | 2026-05-24 08:47 UTC | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD | 841d0d8 (PH-20.12B build rapport) | 841d0d8fdcaccff44a4dd5f995a52b01489d41f9 | OK |
| keybuzz-infra dirty | clean | clean | OK |

Runtime baseline (E0 + E4) :

| Service | Image | Pod | Uptime | Restarts | Verdict |
|---|---|---|---|---|---|
| keybuzz-api DEV | v3.5.254-ai-draft-blocked-reason-dev | mh5d5 | 35h | 0 | LIVE INCHANGE |
| keybuzz-client DEV | v3.5.214-ai-draft-blocked-reason-dev | (preserve) | preserve | 0 | LIVE INCHANGE |
| keybuzz-api PROD | v3.5.255-ai-draft-blocked-reason-prod | qv4jd | 23h | 0 | LIVE INCHANGE |
| keybuzz-client PROD | v3.5.215-ai-draft-blocked-reason-prod | (preserve) | preserve | 0 | LIVE INCHANGE |

## E1 - Image locale + GHCR collision

| Item | Local | GHCR avant push | Verdict |
|---|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.256-autopilot-no-reply-kbactions-dev | absent (manifest unknown) | LIBRE |
| Image ID | sha256:14060c7fab3496ab14788234497dc6fba383a28a4edc8b7498b84a744e7620b8 | N/A | OK MATCH build report |
| Size | 343 519 201 bytes (327 MiB) | N/A | OK |
| OCI revision | 38c048c07fb98543437228657564ef4de388bdfb | N/A | OK MATCH commit source |
| Created | 2026-05-23T23:20:17.3658794Z | N/A | OK (build report) |
| KEY-309 tag immuable | OK (jamais :latest) | N/A | COMPLIANT |

## E2 - Docker push GHCR

| Item | Valeur | Verdict |
|---|---|---|
| Commande | docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.256-autopilot-no-reply-kbactions-dev | EXECUTE |
| Layers pushed | 6 (1736facf0967, 6697c280e3f1, 9036b2d33f56, c3e32e9cf8ce, 72146397702f, 1ad2f60956d5) | OK |
| Layers reused | 4 (7a7517ab2e5a, 9cc01943aa82, 1162d08df74c, 29df493baa13) | OK (cache GHCR layer fan-out) |
| Manifest size apres push | 2416 bytes | OK |
| Manifest digest GHCR | sha256:5f50cc82ce6452bb2de35c129020348c6ea8d2dd47522f1d6061e81188116b92 | OK |
| Result | v3.5.256-autopilot-no-reply-kbactions-dev: digest: sha256:5f50cc82... | PUSH SUCCESS |

Aucun rebuild, aucun retag, aucun docker push d'autre tag.

## E3 - Pull-back + GHCR audit

| Item | Valeur | Verdict |
|---|---|---|
| Manifest schema | v2 application/vnd.docker.distribution.manifest.v2+json | OK |
| Manifest config size | 12934 bytes | OK |
| Manifest config digest (GHCR) | sha256:14060c7fab3496ab14788234497dc6fba383a28a4edc8b7498b84a744e7620b8 | OK |
| Local image ID | sha256:14060c7fab3496ab14788234497dc6fba383a28a4edc8b7498b84a744e7620b8 | OK |
| **Config digest local == GHCR** | OUI | MATCH ABSOLU |
| Pull-back result | "Image is up to date" | OK preserve local |
| Repo digest apres pull | ghcr.io/keybuzzio/keybuzz-api@sha256:5f50cc82ce6452bb2de35c129020348c6ea8d2dd47522f1d6061e81188116b92 | OK |
| Manifest digest GHCR | sha256:5f50cc82ce6452bb2de35c129020348c6ea8d2dd47522f1d6061e81188116b92 | OK (repo digest == manifest digest) |
| OCI revision label apres pull | 38c048c07fb98543437228657564ef4de388bdfb | OK PRESERVE MATCH commit source PH-20.12B |
| Layers count | 10 (5 base node:lts-alpine + 5 app layers) | OK conforme attendu Dockerfile multi-stage |

Premiere layer base node:lts-alpine (52 MiB / sha256:d7319775d025...) compressee reutilisable cross-images.

## E4 - Runtime preserve

| Service | Avant push | Apres push | Pod restart pendant push | Verdict |
|---|---|---|---|---|
| keybuzz-api DEV | v3.5.254 pod mh5d5 35h 0 restart | v3.5.254 pod mh5d5 35h 0 restart | 0 | PRESERVE |
| keybuzz-api PROD | v3.5.255 pod qv4jd 23h 0 restart | v3.5.255 pod qv4jd 23h 0 restart | 0 | PRESERVE |
| keybuzz-client DEV | v3.5.214 | v3.5.214 | 0 | PRESERVE |
| keybuzz-client PROD | v3.5.215 | v3.5.215 | 0 | PRESERVE |
| Manifests GitOps | INCHANGE | INCHANGE | N/A | PRESERVE |

Aucun deploy, aucun kubectl mutation, aucun rollout restart. Image v3.5.256 disponible sur GHCR mais NON deployee.

## AI feature parity / anti-regression

Image pushee herite des memes garanties que le build audite precedent (rapport build commit 841d0d8) :

| Feature | Image pushee v3.5.256 | Runtime actuel | Verdict |
|---|---|---|---|
| noReplyClassifier.js | present 5407 bytes dist | absent (v3.5.254) | NEW READY mais NON deploye |
| autopilot_skipped_no_reply weight 0.0 | present dist/config/kbactions.js | absent (v3.5.254) | NEW READY |
| classifyNoReplyPlatformNotification wired | present dist/modules/autopilot/engine.js | absent (v3.5.254) | NEW READY |
| ph119-tests.js | present 12014 bytes dist | absent (v3.5.254) | NEW READY |
| KBActions no-reply notifications cible 0 | OUI dans image pushee | actuellement 6-12 KBA debites (audit PH-20.12) | NEW cible post-deploy |
| PH-20.11C blockedInfo (PRE_LLM_BLOCKED + blockedStatus + blockedNotes + guardrailNotes) | PRESERVE (5+2+5 markers dist) | LIVE v3.5.254 | PRESERVE |
| autopilotGuardrails source hash 3b85a2763f5b... | INCHANGE | INCHANGE | PRESERVE 100% |
| refundProtectionLayer + 15 refund refs | PRESERVE dist | LIVE v3.5.254 | PRESERVE |
| ai-assist-routes.js / autopilot/routes.js | PRESERVE dist | LIVE v3.5.254 | PRESERVE |
| Brouillon IA cout normaux (inbox_suggestion 6.0 / inbox_contextualized 10.0) | PRESERVE (test PH119) | LIVE | PRESERVE |
| /ai/assist / /ai/execute / /autopilot/draft/consume | PRESERVE routes | LIVE | PRESERVE |
| LLM calls pendant push | 0 | LIVE | OK |
| Drafts generes pendant push | 0 | LIVE | OK |
| Messages marketplace pendant push | 0 | LIVE | OK |
| Runtime change pendant push | 0 | INCHANGE | OK |
| KEY-305 race UI Client | preserve | preserve | PRESERVE |
| KEY-263 DEV/PROD isolation | preserve | preserve | PRESERVE |
| KEY-302 build args sentinel | preserve (Dockerfile inchange) | preserve | PRESERVE |
| KEY-308 OCI labels 6/6 | OK | OK | COMPLIANT |
| KEY-309 tag immuable | OK (jamais :latest) | OK | COMPLIANT |
| KEY-312 (PH-20.11C Done) | preserve doctrine | preserve doctrine | PRESERVE |

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
| push d autre tag | OUI | seul v3.5.256-autopilot-no-reply-kbactions-dev push |
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
| Modification Client/Admin/Website/Backend | OUI | aucune (push API DEV only) |
| Creation ticket Linear | OUI | 0 |
| Changement statut Linear | OUI | 0 transition |
| Authentification docker | OK | session GHCR pre-configuree, aucun token affiche dans logs |

## Rollback

| Element | Plan | Verdict |
|---|---|---|
| Runtime DEV/PROD | N/A (aucun deploy) | RUNTIME PRESERVE |
| Manifest GitOps | N/A (aucun modifie) | INCHANGE |
| Image GHCR pousee | Ne pas referencer le tag dans aucun deployment ; supprimer le tag GHCR uniquement avec GO Ludovic explicite (action irreversible cote registry mais sans impact runtime tant que non deploye) | RECOVERABLE par non-deploy |
| Image locale | docker rmi possible (preserve si futur deploy DEV) | OK |
| Source commit 38c048c0 | git revert dans phase separee si necessaire | OK plan documente |

## Linear

Commentaires sur tickets pertinents (statut INCHANGE 100%, 0 ticket cree) :
- KEY-337 (parent PH-20) : commentaire push success
- KEY-231 (KBActions trial value/anxiety) : commentaire court image dispo GHCR, pas encore runtime
- KEY-270 (cloture audits IA) : commentaire court rattachement
- KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-312 : NON commentes (inchanges)

## Gaps restants / V2 ideas (NON engages)

1. GitOps DEV apply : phase PH-20.12B-DEV-APPLY (GO Ludovic requis, modifie manifest + kubectl apply + rollout)
2. Validation negative read-only smoke DEV post-deploy
3. QA browser Ludovic sur conv reelle bloquee / notif Amazon
4. Build PROD from-git + push GHCR + deploy (phase PH-20.12B-PROD avec GO Ludovic explicite)
5. Client UI enrichissement noReplyInfo (PH-20.12B-CLIENT optionnel)
6. V2 metric dashboard "Notifications skippees ce mois"

## Prochaine phrase GO

**GO APPLY API AUTOPILOT NO-REPLY KBACTIONS DEV PH-SAAS-T8.12AS.20.12B**

STOP.
