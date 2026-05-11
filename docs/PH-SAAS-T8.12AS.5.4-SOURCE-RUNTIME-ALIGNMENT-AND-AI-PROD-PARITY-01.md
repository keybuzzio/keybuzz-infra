# PH-SAAS-T8.12AS.5.4-SOURCE-RUNTIME-ALIGNMENT-AND-AI-PROD-PARITY-01

> Date : 2026-05-11
> Linear : KEY-305 (principal), KEY-304, KEY-301, KEY-263
> Phase : T8.12 AS.5.4 - alignement source / runtime apres rollback AS.5.3
> Environnement : DEV (lecture), PROD (lecture), sources Git keybuzz-api + keybuzz-client (ecriture par revert)

---

## 1. VERDICT

GO SOURCE RUNTIME ALIGNED READY

Source keybuzz-api (HEAD ph147.4/source-of-truth) et keybuzz-client (HEAD ph148/onboarding-activation-replay) sont desormais byte-equivalents aux anchors safe runtime stable (API anchor 070707a1 = v3.5.168 ; Client anchor f244a58 = v3.5.179) sur le perimetre code applicatif (src + app + scripts + docs + Dockerfile + package.json + package-lock.json + next.config.mjs). Tout rebuild depuis HEAD produirait des images functionally equivalentes au runtime DEV actuel - le risque de re-casser le flux Brouillon IA SWITAA AUTOPILOT par contamination AS.5 / AS.5.1 est eteint cote source. Aucun build, aucun deploy, aucun apply, aucune mutation runtime n a ete fait dans cette phase. Trois branches archive preservent l experimentation AS.5 / AS.5.1 sur origin.

---

## 2. Preflight

| Cible | Etat | Detail |
|---|---|---|
| Bastion | install-v3 (46.62.171.61) | alias SSH OK, cle id_rsa_keybuzz_v3 sans passphrase |
| keybuzz-api branch | ph147.4/source-of-truth | imposee par CLAUDE.md, remote OK |
| keybuzz-api HEAD avant phase | eae84b58 (AS.5) | tenant guard messages, divergent runtime |
| keybuzz-api anchor safe | 070707a1 (AS.1) | runtime v3.5.168 image-equivalent |
| keybuzz-client branch | ph148/onboarding-activation-replay | imposee par CLAUDE.md, remote OK |
| keybuzz-client HEAD avant phase | 8d8121f (AS.5.1) | useEffect auto-trigger, divergent runtime |
| keybuzz-client anchor safe | f244a58 (AS.1.2 closeout) | runtime v3.5.179 image-equivalent |
| keybuzz-infra branch | main | remote OK, sync origin |
| Runtime API DEV | v3.5.168-escalation-notifications-dev | inchange, pod age 24m antherieur revert |
| Runtime Client DEV | v3.5.179-as1-1-build-args-fix-dev | inchange, pod age 25m antherieur revert |
| Runtime API PROD | v3.5.151-conversation-tone-metric-prod | inchange |
| Runtime Client PROD | v3.5.174-conversation-tone-metric-ux-prod | inchange |
| QA Ludovic precedent | OK -- Brouillon IA visible auto | confirme AS.5.3 |
| Stop condition runtime | aucune | phase est lecture runtime + ecriture source uniquement |
| Stop condition prod | aucune | PROD non sollicitee |

---

## 3. Audit signaux source / runtime drift

Constat avant phase AS.5.4 :
- keybuzz-api HEAD = eae84b58, runtime DEV = v3.5.168 build a partir de 070707a1 -> 3 commits d ecart en source non presents en runtime (AS.5 tenant guard messages + dependances).
- keybuzz-client HEAD = 8d8121f, runtime DEV = v3.5.179 build a partir de f244a58 -> 2 commits d ecart en source non presents en runtime (AS.5 BFF conversations + AS.5.1 useEffect autotrigger).

Risque : tout rebuild depuis HEAD aurait reintroduit le defaut runtime AS.5 (Brouillon IA absent sur SWITAA AUTOPILOT) confirme par Ludovic et rollback en AS.5.3. La cause statique exacte AS.5 -> Brouillon IA absent n a pas ete identifiee en AS.5.3 par analyse statique seule, mais la correlation runtime est exhaustive (v3.5.180 + v3.5.181 = KO ; v3.5.179 = OK).

Decision AS.5.4 : reconcilier source = runtime par revert via NOUVEAUX commits (pattern AS.4.3 reproductible), archiver les commits experimentaux pour reprise future endpoint-par-endpoint plus tard.

---

## 4. Pattern de revert (Patch / fichier / changement / risque)

| Repo | Commit revert | Annule | Fichiers | Lignes | Risque |
|---|---|---|---|---|---|
| keybuzz-api | b8613f0f | eae84b58 (AS.5 tenant guard messages) | src/plugins/tenantGuard.ts | +3 / -57 | nul - retire fastify-plugin wrapper + PROTECTED_PREFIXES |
| keybuzz-client | d468991 | 8d8121f (AS.5.1 useEffect autotrigger) | src/features/ai-ui/AISuggestionSlideOver.tsx | -36 | nul - retire useEffect generateSuggestion |
| keybuzz-client | 8cdc04a | 57766ea (AS.5 BFF conversations) | src/config/api.ts + app/api/messages/_bff.ts + 6 routes BFF | +6 / -169 (7 fichiers supprimes) | nul - restaure urls directes ${API_CONFIG.baseUrl}/messages/conversations |

Pattern strictement reversible. Aucun reset --hard. Aucun clean. Aucun force push. Trois branches archive creees pour tracabilite et reprise future :
- archive/key-304-api-as5-messages-guard-eae84b58
- archive/key-304-client-as5-messages-bff-57766ea
- archive/key-305-client-as51-ai-autotrigger-8d8121f

Toutes les branches archive sont pushees sur origin.

---

## 5. Tests / verifications

### 5.1 Diff source vs anchor safe (doit etre vide)

```
git -C /opt/keybuzz/keybuzz-api diff 070707a1..HEAD -- src/
[empty]

git -C /opt/keybuzz/keybuzz-client diff f244a58..HEAD -- app src scripts docs Dockerfile package.json package-lock.json next.config.mjs
[empty]
```

Conclusion : code applicatif HEAD = anchor safe byte par byte.

### 5.2 Sync remote (doit etre 0 / 0)

```
keybuzz-api ph147.4/source-of-truth : behind=0 ahead=0
keybuzz-client ph148/onboarding-activation-replay : behind=0 ahead=0
```

### 5.3 Working tree clean (sauf artefact tsconfig.tsbuildinfo)

Aucun fichier code applicatif untracked. Seul tsconfig.tsbuildinfo dirty cote client (artefact de build, non commit, non bloquant).

### 5.4 Branches archive pushees

```
ssh install-v3 "git -C /opt/keybuzz/keybuzz-api branch -r | grep archive/key-304"
  origin/archive/key-304-api-as5-messages-guard-eae84b58

ssh install-v3 "git -C /opt/keybuzz/keybuzz-client branch -r | grep -E 'archive/key-(304|305)'"
  origin/archive/key-304-client-as5-messages-bff-57766ea
  origin/archive/key-305-client-as51-ai-autotrigger-8d8121f
```

---

## 6. Build (N/A - phase source-only)

Aucun build dans cette phase. Aucun docker push. Aucun tag immuable cree.

Justification : la phase porte sur l alignement source = runtime, pas sur la production d artefacts. Le runtime DEV stable existant (API v3.5.168 + Client v3.5.179) reste image de reference.

Prochaine etape build (hors AS.5.4) : possible mais non requise. Si un nouveau build depuis HEAD apres AS.5.4 est realise, il produira des images functionally equivalentes a v3.5.168 / v3.5.179 (perimetre src/app/scripts/docs/Dockerfile/package).

---

## 7. GitOps (N/A - phase source-only)

Aucun manifeste keybuzz-infra modifie dans cette phase. Aucun kubectl apply. Aucun rollout. Aucune annotation deployment.kubernetes.io/revision change. Aucun secret touche.

Manifestes runtime actuels (DEV et PROD) restent strictement inchanges depuis AS.5.3.

---

## 8. Validation runtime (READ-ONLY)

| Service | Namespace | Image runtime | Note |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.168-escalation-notifications-dev | inchange, pod 24m |
| keybuzz-client | keybuzz-client-dev | v3.5.179-as1-1-build-args-fix-dev | inchange, pod 25m |
| keybuzz-outbound-worker | keybuzz-api-dev | v3.5.165-escalation-flow-dev | inchange |
| keybuzz-api | keybuzz-api-prod | v3.5.151-conversation-tone-metric-prod | inchange |
| keybuzz-client | keybuzz-client-prod | v3.5.174-conversation-tone-metric-ux-prod | inchange |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | inchange |
| keybuzz-website | keybuzz-website-prod | v0.6.12-linkedin-insight-seo-prod | inchange |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | inchange |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | inchange |

Ages pods DEV (24-25 min) ANTERIEURS au timestamp des commits revert b8613f0f / d468991 / 8cdc04a : confirme zero restart pod cause par la phase. Phase 100% read-only cote cluster.

---

## 9. No fake metrics (N/A)

Aucune metric, KPI, event GA4/CAPI, tracking, billing, acquisition ou reporting modifie par cette phase. Section non applicable.

---

## 10. AI feature parity

Aucune feature IA modifiee en source applicatif au-dela des reverts qui annulent du code AS.5 et AS.5.1. Le perimetre IA / Inbox / Brouillon IA / Autopilot draft worker / playbooks / escalades est strictement neutre.

Confirmation parite bundle DEV v3.5.179 vs PROD v3.5.174 (documentee en AS.5.3) :
- Brouillon IA : 2/2
- Suggestion IA : 2/2
- Valider et envoyer : 1/1
- Modifier : 15/15
- Ignorer : 3/3

QA Ludovic AS.5.3 : OK -- Brouillon IA visible auto sur SWITAA AUTOPILOT. La phase AS.5.4 ne touche pas le runtime, donc cette confirmation reste valide.

---

## 11. Non-regression PROD

| Service | Avant phase | Apres phase | Status |
|---|---|---|---|
| keybuzz-api PROD | v3.5.151 | v3.5.151 | OK identique |
| keybuzz-client PROD | v3.5.174 | v3.5.174 | OK identique |
| keybuzz-backend PROD | v1.0.47 | v1.0.47 | OK identique |
| keybuzz-website PROD | v0.6.12 | v0.6.12 | OK identique |
| keybuzz-admin-v2 PROD | v2.12.2 | v2.12.2 | OK identique |
| keybuzz-outbound-worker PROD | v3.5.165 | v3.5.165 | OK identique |

PROD intacte. Aucune annotation kubectl rollout. Aucun secret touche. Aucune mutation namespace -prod.

---

## 12. Linear / Gaps / Phrase cible

### 12.1 Linear (textes prepares, NON postes - en attente GO Ludovic)

KEY-305 (principal) : commentaire propose
```
AS.5.4 closeout : source / runtime alignment apres AS.5.3 rollback.
- keybuzz-api HEAD ph147.4/source-of-truth = b8613f0f (revert eae84b58) ; diff vs 070707a1 src/ empty ; sync 0/0.
- keybuzz-client HEAD ph148/onboarding-activation-replay = 8cdc04a (revert 57766ea + d468991 revert 8d8121f) ; diff vs f244a58 empty ; sync 0/0.
- Runtime DEV inchange (API v3.5.168, Client v3.5.179). Runtime PROD inchange.
- Branches archive pushees : archive/key-304-api-as5-messages-guard-eae84b58, archive/key-304-client-as5-messages-bff-57766ea, archive/key-305-client-as51-ai-autotrigger-8d8121f.
- AS.5.2 conclusion (plan-gated not-a-bug sur ecomlg-001) invalidee : KEY-305 reproduit reellement sur SWITAA AUTOPILOT, root cause source statique non isolee. Rollback runtime AS.5.3 demeure la mesure corrective effective.
- Reprise endpoint-par-endpoint differee : a relancer apres analyse runtime DevTools / network trace ulterieure.
Status propose : Done pour AS.5.4 alignment ; KEY-305 root cause -> a investiguer ulterieurement.
```

KEY-304 : commentaire propose
```
AS.5 messages tenant guard / BFF conversations revert applique cote source.
- API : revert eae84b58 par b8613f0f. tenantGuard.ts retabli sans fastify-plugin wrapper et sans PROTECTED_PREFIXES.
- Client : revert 57766ea par 8cdc04a. Routes BFF app/api/messages/conversations supprimees, retour aux URLs directes API.
- Branche archive origin/archive/key-304-api-as5-messages-guard-eae84b58 + origin/archive/key-304-client-as5-messages-bff-57766ea preservent l implementation pour reprise.
- Faille runtime tenant guard /messages reste OUVERTE en DEV et PROD jusqu a une reprise endpoint-par-endpoint propre (AS.6 ou plus tard).
Status propose : Reopen ou tag "regression-rollback".
```

KEY-301 : commentaire propose
```
Faille runtime tenant guard reste ouverte cote /messages apres AS.5.4. AS.5 (tenant guard runtime sur /messages) a casse le flux Brouillon IA SWITAA AUTOPILOT et a ete rollback en AS.5.3 puis aligne en source en AS.5.4. Reprise prevue endpoint-par-endpoint apres analyse runtime ulterieure. Workaround actuel : aucun, faille connue documentee.
Status : reste ouvert.
```

KEY-263 (AS.1 PROD) : commentaire propose
```
PROMOTION PROD AS.1 reste BLOQUEE. La faille runtime tenant guard /messages (KEY-301 / KEY-304) doit etre adressee en DEV par une reprise endpoint-par-endpoint avant promotion PROD. AS.5.4 a aligne la source DEV sur le runtime stable v3.5.168 / v3.5.179 sans reactiver le guard. Pas de GO PROD a ce stade.
Status : reste bloque, en attente reprise.
```

### 12.2 Gaps restants

1. Root cause statique AS.5 -> Brouillon IA absent NON isolee. Necessite analyse runtime (DevTools network trace cote DEV en parallele v3.5.179 vs v3.5.180 sur la meme conversation SWITAA AUTOPILOT). Hors scope AS.5.4.
2. Faille tenant guard /messages reste ouverte en DEV et PROD. Trade-off explicite assume : priorite restauration flux Brouillon IA sur durcissement security.
3. AS.1 PROD reste bloquee (KEY-263). Pas de GO PROD avant reprise endpoint-par-endpoint de la security messages.
4. tsconfig.tsbuildinfo dirty cote keybuzz-client : artefact de build, non commit, non bloquant. A nettoyer si genant.

### 12.3 Phrase cible finale

Source keybuzz-api HEAD ph147.4/source-of-truth = b8613f0f et keybuzz-client HEAD ph148/onboarding-activation-replay = 8cdc04a sont byte-equivalents aux anchors safe (070707a1 / f244a58) ; runtime DEV inchange ; runtime PROD inchange ; trois branches archive preservent l experimentation AS.5 / AS.5.1 sur origin ; aucun build ; aucun deploy ; aucun apply ; aucune mutation DB ; AS.5.4 GO SOURCE RUNTIME ALIGNED READY.

STOP
