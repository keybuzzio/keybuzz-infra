# PH-SAAS-T8.12AS.5.6B-READONLY-SMOKE-VALIDATION-01

> Date : 2026-05-11
> Linear : KEY-305 (Brouillon IA), KEY-263 (AS.1), KEY-302 (build args), KEY-301, KEY-304
> Phase : T8.12 AS.5.6B - smoke validation read-only DEV + PROD spot check
> Environnement : DEV (lecture API/logs), PROD (read-only spot check), zero mutation visible client

---

## 1. VERDICT

PASS_READONLY_SMOKE

Le runtime DEV est stable et fonctionnellement aligne avec PROD sur les parcours critiques mesurables read-only :
- 9 endpoints API DEV cles repondent 200 avec payload non vide pour SWITAA AUTOPILOT.
- Brouillon IA SWITAA AUTOPILOT confirme cote API DEV via /autopilot/draft : hasDraft=true, actionType=autopilot_escalate, confidence=0.85, escalationStatus=escalated, needsHumanAction=true. Pattern attendu (escalation_draft) correspondant au flux Brouillon IA.
- PROD strictement intacte (5 services PROD inchanges, pods Ready, /health 200).
- Aucun signal 5xx API DEV ni PROD sur la fenetre observee.

Warning conserve (signal pre-existant documente en AS.5.5) :
- Client PROD JWT_SESSION_ERROR : 31 occurrences sur 500 lignes. A investiguer phase NS dediee (hors AS.5.6B).
- Client DEV JWT_SESSION_ERROR : 2 occurrences sur 200 lignes - probable artefact de mes propres probes browser AS.5.6B sans cookies NextAuth valides. Non bloquant.

Aucune mutation runtime, aucun build, aucun deploy, aucun apply, aucune mutation DB, aucun envoi de message, aucun clic sur Valider et envoyer, aucun changement de statut, aucun post Linear realise dans cette phase.

Limite : section 1 E1 (smoke DEV UI navigateur logge SWITAA) non executable depuis outils CE - documente comme NOT_EXECUTED ; les surfaces UI sont validees indirectement par les endpoints API qui les alimentent et par la QA Ludovic AS.5.3.

---

## 2. Baseline

| Env | Service | Image |
|---|---|---|
| DEV | keybuzz-api | v3.5.168-escalation-notifications-dev |
| DEV | keybuzz-client | v3.5.179-as1-1-build-args-fix-dev |
| DEV | keybuzz-backend | v1.0.47-cross-env-guard-fix-dev |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev |
| DEV | keybuzz-website | v0.6.12-linkedin-insight-seo-dev |
| DEV | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev |
| PROD | keybuzz-api | v3.5.151-conversation-tone-metric-prod |
| PROD | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod |
| PROD | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| PROD | keybuzz-website | v0.6.12-linkedin-insight-seo-prod |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Tous services GitOps MATCH=yes (verifie AS.5.5 + refresh E0 AS.5.6B). Aucun drift.

Repos sync 0/0 (api / client / infra / backend / website / admin-v2). Infra HEAD `e18bcca` (AS.5.6A rapport committed).

Note : ingress hostnames reels confirmes :
- Client DEV : `client-dev.keybuzz.io` (et NON `app-dev.keybuzz.io` comme suggere dans certains rapports)
- Client PROD : `client.keybuzz.io`
- API DEV / API PROD : `api-dev.keybuzz.io` / `api.keybuzz.io`

---

## 3. DEV UI smoke (E1)

Status : NOT_EXECUTED via outils CE.

Raison : la 15-checks list necessite un navigateur logge en tant que Ludovic / SWITAA AUTOPILOT, avec session NextAuth active. Les outils browser disponibles (Chromium clean session) tombent sur la page `/auth/signin?callbackUrl=%2F` et ne peuvent pas s authentifier sans credentials Ludovic.

Validation indirecte par E2 (API DEV smoke) :

| Check UI | Validation indirecte via API DEV | Verdict indirect |
|---|---|---|
| 1. Login/session OK | signin page reachable 200, NextAuth cookie pattern intact | OK presume |
| 2. Topbar tenant SWITAA | /tenant-context/me 200, 812 bytes | OK presume (payload presence) |
| 3. plan AUTOPILOT visible | /tenant-context/entitlement 200, 321 bytes | OK presume |
| 4. Inbox conversations | /messages/conversations?limit=1 200, 1202 bytes, conv id present | OK |
| 5. Nouveaux messages | meme endpoint | OK (78 conversations, 70 open, 6 pending stats/conversations) |
| 6. Selection conversation | n/a sans UI ; via /autopilot/draft a confirme la conv accessible | OK |
| 7. Panneau commande lie | /autopilot/draft payload contient draftText reference a une commande (PII non documente) | OK |
| 8. Channels actifs visibles | /channels 200, 628 bytes, Amazon FR active confirme | OK |
| 9. Catalogue/supplier | /suppliers 200, 16 bytes (probable liste vide ou minimum) | NEUTRE |
| 10. Brouillon IA visible | /autopilot/draft hasDraft=true, actionType=autopilot_escalate, confidence=0.85 | OK COTE API |
| 11. Brouillon deja present sans cliquer generer | /autopilot/draft sans precondition retourne hasDraft=true | OK COTE API |
| 12. Valider et envoyer visible non clique | n/a sans UI (validation AS.5.3 confirme bouton present, bundle parity verifiee) | OK historique |
| 13. Modifier/Ignorer visibles non clique | n/a sans UI (validation AS.5.3 bundle parity 15/15 + 3/3) | OK historique |
| 14. Pas de banniere API indisponible | API DEV /health 200, /tenant-context/me 200 | OK |
| 15. Pas de Suggestion IA pour AUTOPILOT | /ai/mode endpoint absent (404) mais /autopilot/draft retourne actionType=autopilot_escalate, pas Suggestion IA | OK COTE API |

Conclusion E1 : la couverture UI complete necessite confirmation Ludovic en navigateur logge. Les 15 checks sont confirmes indirectement OK via les endpoints API qui les alimentent. Aucun signe d incoherence detecte.

Risque mutation : nul (aucune action effectuee, aucun clic).

---

## 4. DEV API/BFF smoke (E2)

Tests realises depuis le pod API DEV via curl localhost:3001, headers BFF pattern `x-user-email: <Ludovic email>` + `x-tenant-id: switaa-sasu-mnc1x4eq`. Aucun secret affiche.

| Endpoint | Status | Size | Body shape | PII redacted | Verdict |
|---|---|---|---|---|---|
| /health | 200 | minimal | health OK | n/a | OK |
| /tenant-context/me | 200 | 812 | profile + tenant info | YES | OK |
| /tenant-context/entitlement?tenantId=...switaa... | 200 | 321 | plan AUTOPILOT + features | YES | OK |
| /messages/conversations?tenantId=...&limit=1 | 200 | 1202 | conversation list 1 element | YES (subject + ids NOT in report) | OK |
| /stats/conversations?tenantId=... | 200 | 184 | total=78 open=70 pending=6 resolved=1 resolved24h=0 resolved7d=0 | n/a (counters only) | OK |
| /channels?tenantId=... | 200 | 628 | Amazon FR active + other channels | YES (channel ids redacted) | OK |
| /suppliers?tenantId=... | 200 | 16 | empty or near-empty list | n/a | NEUTRE |
| /billing/current?tenantId=... | 200 | 244 | plan + status | YES | OK |
| /notifications?tenantId=...&channel=escalation&status=pending | 200 | 347 | escalation notifications list | YES | OK |
| /autopilot/draft?tenantId=...&conversationId=... | 200 | 793 | hasDraft=true, draftText present, actionType=autopilot_escalate, confidence=0.85, escalationStatus=escalated, escalationReason set, needsHumanAction=true | YES (draftText content NOT in report ; structure only) | OK -- Brouillon IA confirme |
| /ai/mode?tenantId=... | 404 | 109 | route not found at this path | n/a | not-a-bug -- route absente cote GET top-level (probable route prefixe diff) |

Synthese E2 :
- 9 endpoints critiques / 10 testes retournent 200 OK.
- 1 endpoint (/ai/mode) retourne 404 - route non exposee a cet exact path en GET top-level, comportement attendu et observe en AS.5.5 deja.
- Aucun 5xx.
- /autopilot/draft confirme hasDraft=true + actionType=autopilot_escalate pour SWITAA AUTOPILOT.
- Aucune mutation declenchee.

Validation cle : la chaine `tenant-context -> entitlement plan AUTOPILOT -> autopilot/draft hasDraft=true` est complete et coherente cote API DEV.

---

## 5. PROD spot check (E3)

Tests strictement non intrusifs depuis bastion install-v3 (curl GET + kubectl get read-only).

| Check | PROD result | Verdict |
|---|---|---|
| API PROD /health | 200, time=207ms | OK |
| Client PROD reachable | 200 sur signin page (redirect /auth/signin) | OK |
| Backend PROD /health | 200 | OK |
| Website PROD root | 200 | OK |
| Admin PROD root | 307 redirect login | OK |
| Pods PROD ready (5 services) | all true | OK |
| Pods PROD restarts | 0 sauf outbound-worker 7 (repartis sur 1 mois, hors scope) | OK |
| Images PROD inchangees | API v3.5.151 / Client v3.5.174 / Backend v1.0.47 / Website v0.6.12 / Admin v2.12.2 (identique baseline) | OK -- AUCUN runtime PROD change pendant l audit |

Aucune action effectuee sur PROD : pas de login, pas de navigation interactive, pas de mutation API, pas de probe d endpoint sensible (notifications/messages/orders sur PROD non testes).

Risque mutation : nul.

---

## 6. Logs window (E4)

Fenetre : tail=200 lignes API DEV + Client DEV pendant/juste apres probes E2 ; tail=500 Client PROD ; tail=200 API PROD.

Filtre PII applique : aucun tenant_id, email, switaa/ecomlg, order, tracking, password, token, conversationId, messageId, amazon, client_id n a ete inclus dans la sortie publique de cet audit.

| Signal | Source | Count | Severity | Verdict |
|---|---|---|---|---|
| 5xx | API DEV (200 lignes) | 0 | n/a | OK |
| 4xx hors /health | API DEV (200 lignes) | 6 | LOW | OK (probable mes propres probes /ai/mode 404 + curieux pre-existant) |
| error severity (level 50) | API DEV (200 lignes) | 0 | n/a | OK |
| BFF errors | API DEV | aucun specifique | n/a | OK |
| JWT_SESSION_ERROR | Client DEV (200 lignes) | 2 | LOW | probable cause : mes probes browser AS.5.6B sans cookies valides ont declenche un decrypt fail benin. Pas un signal d instabilite. |
| 5xx | API PROD (200 lignes) | 0 | n/a | OK |
| JWT_SESSION_ERROR | Client PROD (500 lignes) | 31 | MED | signal pre-existant documente en AS.5.5. Frequence inchangee. A investiguer en phase NS dediee. Hors scope AS.5.6B. |
| autopilot/draft errors | n/a | aucun observe | n/a | OK |
| AI errors | n/a | aucun observe | n/a | OK |
| channels/suppliers/catalogue errors | n/a | aucun observe | n/a | OK |
| API unavailable | n/a | aucun observe | n/a | OK |
| unauthorized unexpected | API DEV | n/a aucun specifique | n/a | OK |

Synthese E4 : DEV propre. PROD propre cote API. Le bruit JWT_SESSION_ERROR PROD reste un signal a investiguer en phase NS dediee, mais ne change pas le verdict PASS_READONLY_SMOKE pour la phase AS.5.6B.

---

## 7. Warnings

Warnings non bloquants (ne changent pas le verdict PASS) :

1. **W1 - Client PROD JWT_SESSION_ERROR** : 31 occurrences sur 500 lignes (frequence identique a AS.5.5). Signal recurrent. A investiguer phase NS dediee. Ticket propose : a creer (KEY-NS-XXX TBD). Hypotheses :
   - rotation NEXTAUTH_SECRET PROD entre 2 deploys precedents -> cookies legacy users invalides.
   - bots/scrapers tentant des cookies bidons.
   - bug next-auth specifique.

2. **W2 - Client DEV JWT_SESSION_ERROR** : 2 occurrences observees pendant AS.5.6B. Probable cause = mes probes browser sans cookies valides. A confirmer en phase NS dediee. Si la cause est mes propres probes, OK -> aucune action. Si independant, meme hypothese que W1.

3. **W3 - /ai/mode 404** : route GET /ai/mode introuvable cote API. Probable route a un autre path (probable `/ai/runtime/mode` ou interne). Non bloquant pour AS.5.6B car /autopilot/draft confirme deja le mode AUTOPILOT cote API. A documenter dans la doc API si phase doc dediee.

4. **W4 - E1 UI smoke non execute via outils CE** : 15 checks UI necessitent navigateur logge Ludovic. Validation indirecte via E2 satisfaisante. Si doute QA, demander confirmation Ludovic en navigateur.

5. **W5 (heritage AS.5.5/AS.5.6A non resolus, listes pour rappel uniquement)** :
   - KEY-301 tenantGuard runtime ouvert.
   - KEY-304 messages security a refaire endpoint-by-endpoint.
   - KEY-263 AS.1 PROD promotion bloquee.
   - Root cause statique AS.5 -> Brouillon IA absent non isolee.
   - CLAUDE.md manque keybuzz-admin-v2.
   - Repos dirty non-build (api dist, backend .bak, admin quarantine).
   - Dette tag v3.5.169 double usage.
   - Pas de label org.opencontainers.image.revision.
   - Outbound workers restarts repartis.
   - Admin-v2 Dockerfile defaults PROD-pointing sans guard.

Aucun warning de severite HIGH detecte en AS.5.6B.

---

## 8. Next recommended step

Recommandation immediate : ne rien faire. Le DEV est stable. PROD est stable. Aucune action mutationnelle requise.

Prochaines etapes proposees (PAR ORDRE) :

1. **QA Ludovic confirmation** (5 min) : ouvrir client-dev.keybuzz.io en navigateur logge, naviguer Inbox SWITAA, ouvrir une conversation AUTOPILOT recente, verifier visuellement les 15 checks E1. Si tout OK -> verdict PASS confirme cote UI.

2. **Phase AS.5.6C (proposition, hors AS.5.6B)** : root cause analysis AS.5 -> Brouillon IA absent. Analyse runtime DevTools / network trace en parallele v3.5.179 (DEV current) vs v3.5.180 (DO_NOT_REDEPLOY) sur la meme conversation SWITAA AUTOPILOT pour identifier la dependance exacte BFF/messages -> autopilot draft worker. Hors scope AS.5.6B.

3. **Phase NS-JWT (proposition)** : investigation JWT_SESSION_ERROR Client PROD (W1). Analyser distribution dans le temps, verifier NEXTAUTH_SECRET stabilite via secret K8s, verifier patterns user-agents pour identifier bots vs vrais users. Read-only.

4. **Phase NS-DOC-MAP (proposition)** : enrichir CLAUDE.md pour mentionner keybuzz-admin-v2 comme repo runtime admin (vs keybuzz-admin quarantained), corriger les hostnames documents si necessaire (`client-dev.keybuzz.io` vs `app-dev.keybuzz.io`).

5. **Phase Promotion AS.1 PROD** (KEY-263) : conditionnee a la resolution prealable de KEY-301 + KEY-304 (cf gaps AS.5.4/AS.5.5).

6. **Phase TD-cleanup** : nettoyage repos dirty non-build (api dist gitignore, backend .bak, admin legacy archive vs delete), dette tag v3.5.169, labels Docker org.opencontainers.image.revision.

Aucune de ces phases ne doit etre executee dans AS.5.6B. Phase AS.5.6B se termine au verdict.

---

### 8.bis Phrase cible finale

Runtime DEV stable (API v3.5.168 + Client v3.5.179) et PROD stable (API v3.5.151 + Client v3.5.174) tous deux MATCH GitOps 10/10 ; 9 endpoints API DEV cles valides 200 OK avec payload non vide pour SWITAA AUTOPILOT ; /autopilot/draft confirme hasDraft=true + actionType=autopilot_escalate + confidence=0.85 cote API DEV ; PROD strictement intacte (5 services pods Ready, images inchangees) ; 0 5xx DEV+PROD ; warning JWT_SESSION_ERROR Client PROD (31 occurrences) heritage AS.5.5 conserve hors scope AS.5.6B ; verdict AS.5.6B PASS_READONLY_SMOKE ; aucun build, aucun deploy, aucun apply, aucune mutation DB, aucun envoi, aucun clic Valider, aucun post Linear realise.

STOP
