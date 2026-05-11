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

### 12.1 Linear (textes prepares disclosure-controlled, POSTING ON HOLD)

POSTING ON HOLD : aucun commentaire ne sera poste sur Linear tant que AS.5.5 audit verite complet n est pas livre et valide par Ludovic. Les textes ci-dessous sont prepares mais non publies. Decision Ludovic 2026-05-11.

Principes de disclosure :
- Pas de detail technique des mecanismes d implementation (wrappers Fastify, prefixes proteges, BFF mirror, etc.) susceptible d aider une reproduction.
- Pas de commandes git / revert / kubectl publiees.
- Hashes de commit autorises (audit interne) mais pas de noms de fichiers sources sensibles.
- Existence de la faille et son perimetre runtime sont declares ; trajectoire d exploit non detaillee.

KEY-305 (principal) : commentaire prepare
```
AS.5.4 closeout : Brouillon IA restaure en DEV apres rollback pre-AS.5 + reconciliation source/runtime.

- Runtime DEV stable : API v3.5.168 + Client v3.5.179. QA Ludovic : Brouillon IA visible auto sur SWITAA AUTOPILOT.
- Source keybuzz-api et keybuzz-client HEAD realignes byte-equivalents au runtime stable (perimetre code applicatif). Risque rebuild de regression eteint cote source.
- AS.5.2 invalidee : diagnostic fait sur le mauvais tenant (PRO au lieu d AUTOPILOT). KEY-305 reproduit reellement sur SWITAA en AS.5.3.
- Root cause exacte AS.5 -> Brouillon IA absent NON isolee par analyse statique. A investiguer en runtime (DevTools / network trace) AVANT toute nouvelle tentative security touchant Inbox / AI.

Statut suggere : Done (alignment AS.5.4) ou In Review selon workflow.
Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.5.4-...-01.md
```

KEY-304 : commentaire prepare
```
Tentative AS.5 (durcissement endpoint /messages) rollbackee en AS.5.3, source revertee en AS.5.4.

- Endpoint-by-endpoint security reste a refaire : la trajectoire AS.5 unifiee a casse le flux Brouillon IA SWITAA AUTOPILOT.
- Branches archive preservees sur origin pour reference future (non listees publiquement).
- Ne pas relancer la reprise avant une phase de design qui integre EXPLICITEMENT la QA Brouillon IA / Inbox messages / channels actifs / catalogue. AS.5 avait casse plusieurs flux successivement avant rollback complet.

Statut : reste Open.
```

KEY-301 : commentaire prepare
```
Faille tenantGuardPlugin non corrigee en runtime DEV et PROD apres rollback AS.5.

- AS.5 a tente une mitigation runtime sur /messages : effets de bord inacceptables (Brouillon IA SWITAA cassee), rollback complet.
- Faille initiale documentee internement reste ouverte. Pas de detail public de la trajectoire d exploit.
- AS.1 PROD reste bloquee tant que tenantGuard n est pas repris proprement.

Statut : reste Open.
```

KEY-263 (AS.1 PROD) : commentaire prepare
```
AS.1 notifications escalation : code DEV existe et fonctionne (runtime v3.5.168), promotion PROD reste BLOQUEE.

- Blockers : KEY-301 (faille tenantGuard runtime ouverte) + KEY-304 (security messages a refaire endpoint-by-endpoint).
- Aucun GO PROD tant que tenantGuard non corrige et QA Inbox / Brouillon IA non revalidee.

Statut suggere : Blocked (ou In Review selon workflow Linear).
```

### 12.2 Gaps restants

1. Root cause statique AS.5 -> Brouillon IA absent NON isolee. Necessite analyse runtime (DevTools network trace cote DEV en parallele v3.5.179 vs v3.5.180 sur la meme conversation SWITAA AUTOPILOT). Hors scope AS.5.4.
2. Faille tenant guard /messages reste ouverte en DEV et PROD. Trade-off explicite assume : priorite restauration flux Brouillon IA sur durcissement security.
3. AS.1 PROD reste bloquee (KEY-263). Pas de GO PROD avant reprise endpoint-par-endpoint de la security messages.
4. tsconfig.tsbuildinfo dirty cote keybuzz-client : artefact de build, non commit, non bloquant. A nettoyer si genant.

### 12.3 Prochaine etape : AS.5.5 audit verite complet (PRIORITE)

Ludovic 2026-05-11 : avant toute communication Linear additionnelle (statuts, commentaires, fermetures), livrer AS.5.5 = audit verite complet.

Perimetre attendu (a confirmer en kickoff AS.5.5) :
- Croisement exhaustif source HEAD / runtime DEV / runtime PROD / manifestes infra / images registry / annotations rollout.
- Etat tenant guard runtime DEV et PROD endpoint par endpoint (audit propagation Fastify scope sans publier la mecanique).
- Etat Brouillon IA / Suggestion IA / Autopilot draft worker / playbooks / escalades : parite DEV vs PROD au bundle pres + au comportement pres.
- Audit dette : AS.5.2 invalidee, KEY-305 root cause non isolee, KEY-304 security non reprise, KEY-301 faille ouverte, KEY-263 PROD bloque, archives non listees.
- Sortie : carte verite source <-> runtime <-> Linear, et liste ordonnee des actions de reprise (security messages, root cause Brouillon IA, AS.1 PROD).

AS.5.5 doit etre une phase audit-only : lecture exhaustive, zero ecriture code applicatif, zero deploy, zero apply. Rapport AS.5.5 conditionne ensuite : (i) la publication des 4 commentaires Linear de AS.5.4, (ii) la prochaine phase de reprise security.

### 12.4 Phrase cible finale

Source keybuzz-api HEAD ph147.4/source-of-truth = b8613f0f et keybuzz-client HEAD ph148/onboarding-activation-replay = 8cdc04a sont byte-equivalents aux anchors safe (070707a1 / f244a58) ; runtime DEV inchange ; runtime PROD inchange ; trois branches archive preservent l experimentation AS.5 / AS.5.1 sur origin ; aucun build ; aucun deploy ; aucun apply ; aucune mutation DB ; AS.5.4 GO SOURCE RUNTIME ALIGNED READY.

STOP
