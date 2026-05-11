# PH-SAAS-T8.12AS.5.6A-DEV-PROD-ALIGNMENT-TRUTH-AUDIT-01

> Date : 2026-05-11
> Linear : KEY-263 (AS.1), KEY-302 (build args), KEY-292 (conversation tone), KEY-301, KEY-304, KEY-305
> Phase : T8.12 AS.5.6A - audit alignement DEV vs PROD, read-only zero mutation
> Environnement : DEV (lecture), PROD (lecture). Aucun build, aucun deploy, aucun apply, aucune mutation DB, aucun post Linear.

---

## 1. VERDICT

GO DEV AHEAD EXPECTED - KEEP CURRENT RUNTIME

Reponse a la question principale : DEV n est pas byte-identique a PROD, mais DEV est FONCTIONNELLEMENT ALIGNE avec PROD avec un delta volontaire et tracable :

- 4 services sur 6 sont byte-identiques entre DEV et PROD (Backend, Outbound worker, Website, Admin v2).
- 2 services (API et Client) ont un delta volontaire, controle, documente, qui correspond a 2 features DEV en attente de promotion PROD :
  1. AS.1 escalation notifications (KEY-263) : nouvelle feature DEV produite par commit API `070707a1` + commits Client `37e70ac` + `a69477a`. En attente de promotion PROD.
  2. KEY-302 client build args hardening : protection source-only contre l incident AS.1.1, livree par commit Client `f244a58`. Doit etre incluse dans toute prochaine promotion Client PROD.
- Source HEAD aligne avec runtime DEV (AS.5.4 anchors confirmes byte-equivalents).
- Aucun drift dangereux detecte.

Recommandation : Scenario A (garder DEV actuel) + planifier promotion AS.1+KEY-302 en PROD UNIQUEMENT apres resolution des bloquants KEY-301 (tenantGuard runtime) et KEY-304 (security messages).

---

## 2. Runtime DEV / PROD

Tous les services GitOps MATCH=yes (10/10) audites en AS.5.5 puis refresh AS.5.6A.

| Env | Service | Runtime image | Match | Pod ready | Restart |
|---|---|---|---|---|---|
| DEV | keybuzz-api | v3.5.168-escalation-notifications-dev | yes | 1/1 | 0 |
| DEV | keybuzz-client | v3.5.179-as1-1-build-args-fix-dev | yes | 1/1 | 0 |
| DEV | keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | yes | 1/1 | 0 |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev | yes | 1/1 | 8 (repartis sur 1 mois) |
| DEV | keybuzz-website | v0.6.12-linkedin-insight-seo-dev | yes | 1/1 | 0 |
| DEV | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | yes | 1/1 | 0 |
| PROD | keybuzz-api | v3.5.151-conversation-tone-metric-prod | yes | 1/1 | 0 |
| PROD | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | yes | 1/1 | 0 |
| PROD | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | yes | 1/1 | 0 |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod | yes | 1/1 | 7 |
| PROD | keybuzz-website | v0.6.12-linkedin-insight-seo-prod | yes | 1/1 + 1/1 (2 replicas) | 0 + 0 |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | yes | 1/1 | 0 |

Aucun drift GitOps. PROD intacte depuis AR.5.2 + KEY-285 (admin-v2) + AQ.3 (website).

Repos sync :
- keybuzz-api `ph147.4/source-of-truth` HEAD b8613f0f sync 0/0
- keybuzz-client `ph148/onboarding-activation-replay` HEAD 8cdc04a sync 0/0
- keybuzz-infra `main` HEAD 7c8e7cc sync 0/0
- keybuzz-backend `main` HEAD c62f376 sync 0/0
- keybuzz-website `main` HEAD 5fc6f2b sync 0/0
- keybuzz-admin-v2 `main` HEAD ad2bd4c sync 0/0

---

## 3. Version delta DEV vs PROD

| Service | DEV image | PROD image | DEV commit | PROD commit | Delta | Classification |
|---|---|---|---|---|---|---|
| keybuzz-api | v3.5.168-escalation-notifications-dev | v3.5.151-conversation-tone-metric-prod | 070707a1 (AS.1) | 0e26bfc3 (AR.5.1) | 17 versions | DEV_AHEAD_EXPECTED |
| keybuzz-client | v3.5.179-as1-1-build-args-fix-dev | v3.5.174-conversation-tone-metric-ux-prod | f244a58 (AS.1.2 closeout) | 0a7306a (AR.5.1) | 5 versions | DEV_AHEAD_EXPECTED |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | v1.0.47-cross-env-guard-fix-prod | c62f376 (AO.6.2) | c62f376 (AO.6.2) | SAME | SAME |
| keybuzz-outbound-worker | v3.5.165-escalation-flow-dev | v3.5.165-escalation-flow-prod | pre-AS.1 escalation flow | pre-AS.1 escalation flow | SAME | SAME |
| keybuzz-website | v0.6.12-linkedin-insight-seo-dev | v0.6.12-linkedin-insight-seo-prod | 5fc6f2b (AQ.3) | 5fc6f2b (AQ.3) | SAME | SAME |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-prod | ad2bd4c (AQ.4.1) | ad2bd4c (AQ.4.1) | SAME | SAME |

Synthese :
- 4 services sur 6 : SAME (byte-identiques entre DEV et PROD).
- 2 services sur 6 : DEV_AHEAD_EXPECTED (deltas controles et documentes).
- 0 service : PROD_AHEAD_UNEXPECTED.
- 0 service : DANGEROUS_DRIFT.
- 0 service : UNKNOWN.

Important : aucun service n a une regression DEV par rapport a PROD. Toutes les fonctions PROD sont presentes en DEV (DEV est superset).

Detail API DEV-ahead : entre PROD baseline `0e26bfc3` (AR.5.1) et DEV `070707a1` (AS.1), un seul commit applicatif separe les deux versions (AS.1 escalation notifications). Les 17 builds intermediaires (v3.5.152 a v3.5.167) sont des iterations DEV non promues en PROD (cycles internes de validation, intermediaires AR.6.x / AR.7 / etc.). Le runtime DEV consomme la baseline AR.5.1 + AS.1 (commit 070707a1).

Detail Client DEV-ahead : entre PROD baseline `0a7306a` (AR.5.1) et DEV `f244a58` (AS.1.2), 3 commits :
- `37e70ac` (AS.1) feat(inbox): escalation notifications badge + tenant-scoped client (PH-SAAS-T8.12AS.1, KEY-263)
- `a69477a` (AS.1.1) fix(inbox): unwire AS.1 escalation badge from InboxTripane to restore conversation list (KEY-263) - mitigation de la regression Inbox post-AS.1
- `f244a58` (AS.1.2) fix(client-build): require explicit API build args for safe bundles (KEY-302) - hardening anti-incident

---

## 4. Functional delta DEV vs PROD (18 surfaces)

Probes read-only realisees + heritage QA Ludovic AS.5.3 + analyse source.

| Surface | PROD expected | DEV observed | Difference | Classification | Action |
|---|---|---|---|---|---|
| 1. Auth / session | login + NextAuth standard | idem code | aucune | ALIGNED | aucune |
| 2. Tenant context | /tenant-context/entitlement?tenantId=X | idem (200 observe DEV logs) | aucune | ALIGNED | aucune |
| 3. Plan / entitlement | PRO + AUTOPILOT mapping | idem | aucune | ALIGNED | aucune |
| 4. Inbox conversations | liste conv via /messages/conversations | idem (400 sans tenant_id : comportement attendu) | aucune | ALIGNED | aucune |
| 5. Brouillon IA (AUTOPILOT) | drafts auto, label "Brouillon IA" | idem (QA Ludovic AS.5.3 confirme SWITAA) | aucune | ALIGNED | aucune |
| 6. Reply composer | Valider/envoyer, Modifier/Ignorer | idem (bundle parite confirme AS.5.3 : Brouillon IA 2/2, Suggestion IA 2/2, Valider 1/1, Modifier 15/15, Ignorer 3/3) | aucune | ALIGNED | aucune |
| 7. Orders / commande liee | tracking_events + autopilot delivery fields (AF) | idem (commit AF anterieur a AR.5.x deja en PROD) | aucune | ALIGNED | aucune |
| 8. Tracking / 17Track | resolveTrackingCodeFallback + AH | idem | aucune | ALIGNED | aucune |
| 9. Channels actifs | Amazon + Shopify (en attente) + email | idem | aucune | ALIGNED | aucune |
| 10. Suppliers / catalogue | catalogue panels | idem ("tout fonctionne comme avant" Ludovic post-AS.4.3) | aucune | ALIGNED | aucune |
| 11. SAV | SAV decision tree + policy | idem | aucune | ALIGNED | aucune |
| 12. Stats / dashboard | Performance SAV + conversation tone (AR.2/AR.3/AR.5.1) | idem | aucune | ALIGNED | aucune |
| 13. Notifications | absent en PROD | PRESENT en DEV (AS.1 escalation notifications, KEY-263) | DEV adds feature | EXPECTED_DEV_AHEAD | conserver, prevoir promotion PROD apres KEY-301/304 |
| 14. Billing / Plans display | Stripe + KBActions | idem (aucun changement billing dans v3.5.152-168) | aucune | ALIGNED | aucune |
| 15. Admin v2 | v2.12.2 media buyer LP domain QA | idem (DEV = PROD) | aucune | ALIGNED | aucune |
| 16. Website / signup / onboarding | v0.6.12 LinkedIn Insight + pricing SEO | idem (DEV = PROD) | aucune | ALIGNED | aucune |
| 17. Backend public flows (OAuth/inbound webhooks) | v1.0.47 cross-env guard | idem (DEV = PROD) | aucune | ALIGNED | aucune |
| 18. Outbound worker | v3.5.165 escalation flow | idem (DEV = PROD) | aucune | ALIGNED | aucune |

Classifications utilisees :
- ALIGNED : 17 surfaces sur 18
- EXPECTED_DEV_AHEAD : 1 surface (Notifications AS.1)
- MUST_ALIGN_WITH_PROD : 0
- DANGEROUS_DRIFT : 0
- NOT_TESTED_RISK : 0

Note : les probes UX complets (Inbox UI, Brouillon IA flow, dashboard, etc.) ne sont pas re-executees dans cet audit AS.5.6A car elles ont ete validees par QA Ludovic en AS.5.3 et confirmees en AS.5.5. Si un doute UX est exprime, une phase QA dediee sera planifiee.

---

## 5. Features DEV en avance sur PROD

| Feature | Present DEV | Present PROD | Validee | Safe a garder DEV | Bloque PROD | Notes |
|---|---|---|---|---|---|---|
| AS.1 escalation notifications API (commit 070707a1) | OUI v3.5.168 | NON v3.5.151 | OUI (code DEV stable, QA Ludovic AS.5.3 OK pour flux global, statut KEY-263 In Review) | OUI | OUI tant que KEY-301+KEY-304 non resolus | Promotion PROD attend resolution tenantGuard |
| AS.1 escalation notifications Client (commit 37e70ac) | OUI v3.5.179 | NON v3.5.174 | partielle (badge unwired par a69477a pour eviter regression Inbox) | OUI | meme dependance | Promotion conjointe avec API |
| AS.1.1 Client unwire badge (commit a69477a) | OUI v3.5.179 | NON v3.5.174 | OUI (Inbox listing restauree) | OUI | non | Mitigation a inclure dans toute promotion Client |
| KEY-302 build args hardening Client (commit f244a58) | OUI v3.5.179 | NON v3.5.174 | OUI (sentinels Dockerfile + scripts + docs) | OUI | non | A inclure obligatoirement dans toute prochaine promotion Client PROD |
| AR.6 / AR.6.1 / AR.6.1A enriched milestones (commits 462ec358, 881c2a38, fbb45c0c) | OUI dans HEAD source | inconnu PROD baseline | non determine dans cet audit | OUI | non | A documenter si promotion Stats PROD planifiee |
| AR.7 message_source enrichment AI-assisted (commit 03818fea) | OUI source | inconnu PROD | non determine | OUI | non | Idem |
| AR.2 Performance SAV metrics endpoint (commit dac5b790) | OUI source | inconnu PROD | non determine | OUI | non | Idem |
| AP.2.7 auto-assign conversation to human replier (commit 9521fb35) | OUI source | inconnu PROD | non determine | OUI | non | Idem |
| AP.2.4 clear escalation_status on resolve (commit a18a361d) | OUI source | inconnu PROD | non determine | OUI | non | Idem |

Limite traceability : les commits API anterieurs a AS.1 (AR.6, AR.7, AR.2, AP.2.x, AP.1.x, AN.x, AM.x, AK, AH) sont presents en source-of-truth `ph147.4` mais leur statut "promu en PROD ou non" n est pas tranchable sans audit de l historique complet des promotions PROD API. Vu que PROD runtime API consomme uniquement `v3.5.151-conversation-tone-metric-prod` (commit baseline `0e26bfc3`), tous les commits AVANT le 10 mai sur ph147.4 doivent avoir ete buildes en images promues PROD a un moment ou un autre - mais sans audit dedie cela reste un "inconnu PROD" formel. Hors scope AS.5.6A.

Conclusion section 5 : 2 features primaires DEV-ahead documentees (AS.1 + KEY-302). Les autres deltas potentiels sont des iterations internes attendues sur la branche ph147.4 et sont consideres comme safe a garder en DEV.

---

## 6. Dangerous drifts

| Drift | Evidence | Impact | Rollback possible | Fix possible | Recommendation |
|---|---|---|---|---|---|
| (aucun drift dangereux detecte a la date 2026-05-11 post-AS.5.4 alignment) | - | - | - | - | - |

Drifts historiques (eteints post-AS.5.4) :
- Bundle DEV pointant PROD (v3.5.177/178) : ELIMINE par v3.5.179 + KEY-302 guard.
- TenantGuard runtime tente AS.4.x/AS.5.x : runtime rollback AS.5.3 + source revert AS.5.4. Source HEAD aligne.
- AS.5.1 useEffect autotrigger : rollback runtime + source revert d468991.
- Source/runtime drift post-AS.5 : ELIMINE par AS.5.4 (diffs vs anchors vides).

Drifts laterals notes (non bloquants, hors AS.5.6A) :
- JWT_SESSION_ERROR PROD recurrent (31 occurrences / 500 lignes logs Client PROD) : note AS.5.5. A investiguer phase dediee NS.
- Repos dirty non-build (api dist, backend .bak, admin legacy quarantine) : note AS.5.5. Non bloquant.
- Tag v3.5.169 utilise pour 2 builds API differents (AS.4.1 scope-fix vs AS.5 messages-guard) : dette tag a clarifier.

---

## 7. Strategie d alignement (3 scenarios)

### 7.1 Scenario A - Garder DEV actuel (RECOMMANDE)

Conditions remplies :
- DEV stable : runtime MATCH=yes, pods Ready, source aligne.
- Ecarts DEV attendus : AS.1 + KEY-302 documentes, tracables, validees.
- Aucun drift dangereux.

Actions :
- Aucune mutation DEV runtime.
- Aucune mutation PROD runtime.
- Maintenir DEV (API v3.5.168 + Client v3.5.179) comme baseline de developpement.
- Maintenir PROD (API v3.5.151 + Client v3.5.174) comme baseline de production stable.
- Promotion PROD AS.1+KEY-302 conditionnee a la resolution explicite de KEY-301 + KEY-304 (tenantGuard runtime + security messages).

Risque residuel : la promotion AS.1 PROD attendra resolution KEY-301/304, donc KEY-263 reste In Review / Blocked. Acceptable.

### 7.2 Scenario B - Rapprocher DEV de PROD (NON RECOMMANDE en l etat)

Conditions non remplies :
- DEV n a pas trop d ecarts inconnus : seulement 2 deltas documentes.
- Pas de besoin reel de reprendre depuis une base proche PROD.

Si neanmoins envisage (par exemple decision produit), couts :
- Rebuild API DEV depuis commit `0e26bfc3` avec tag `v3.5.151-conversation-tone-metric-dev` (si pas deja present en registry, build neuf depuis worktree clean a partir de ce commit). Verification : digest doit etre fonctionnellement equivalent a v3.5.151-prod.
- Rebuild Client DEV depuis commit `0a7306a` avec tag `v3.5.174-conversation-tone-metric-ux-dev` (idem, build neuf avec build args DEV explicites cf KEY-302).
- Manifest infra : pointer DEV API + Client vers ces images.
- Apply GitOps.
- Risques :
  - Perte de AS.1 escalation notifications cote DEV : tests AS.1 inactifs en DEV jusqu a re-build.
  - Perte de KEY-302 hardening cote DEV : tout rebuild Client futur SANS build args reintroduirait l incident AS.1.1.
  - DEV perd la capacite de servir d environnement de pre-production pour les promotions futures.
- Rollback back : reapply images actuelles v3.5.168 / v3.5.179 (deja prouvees stables, manifest infra disponible en git history).
- Verdict : trop chere et destructif vu que DEV est stable.

### 7.3 Scenario C - Garder DEV mais ajouter garde-fous (COMPLEMENTAIRE recommande)

Conditions :
- DEV stable mais non couvert par tests automatises systematiques au-dela de QA Ludovic ad hoc.

Actions proposees (hors scope AS.5.6A, a kicker en phases dediees) :
- Phase tests-min : ajouter un smoke test e2e Inbox / Brouillon IA SWITAA AUTOPILOT en DEV qui tourne post-deploy.
- Phase pre-deploy checklist : verifier avant chaque deploy DEV+PROD que les 18 surfaces de la section 4 sont ALIGNED ou EXPECTED_DEV_AHEAD, jamais MUST_ALIGN_WITH_PROD ni DANGEROUS_DRIFT.
- Phase ticket creation : Linear tickets pour
  - JWT_SESSION_ERROR PROD investigation (NS dediee)
  - KEY-301 tenantGuard endpoint-by-endpoint design (apres root cause AS.5 isolee)
  - CLAUDE.md mise a jour pour keybuzz-admin-v2 (doc gap)
  - Tag v3.5.169 double usage (dette tag clarification)
  - org.opencontainers.image.revision label sur tous les Dockerfiles (traceability)
- Phase QA reguliere : Ludovic ou agent QA dedie verifie SWITAA AUTOPILOT + Inbox + Brouillon IA en DEV apres chaque deploy potentiellement sensible.

Recommande comme COMPLEMENT du Scenario A, pas comme alternative.

---

## 8. Rollback theoretical plan (Scenario B reference uniquement)

NE PAS EXECUTER. Plan strictement theorique pour le cas ou Ludovic devrait imposer un alignement runtime DEV vers PROD baseline.

### 8.1 Pre-requis
- Worktree clean sur keybuzz-api branche `ph147.4/source-of-truth` au commit `0e26bfc3` (AR.5.1).
- Worktree clean sur keybuzz-client branche `ph148/onboarding-activation-replay` au commit `0a7306a` (AR.5.1).
- Verification que les images de rollback ciblees existent en registry, sinon rebuild explicite avec tags immuables nouveaux.

### 8.2 Images cibles
- API DEV : `ghcr.io/keybuzzio/keybuzz-api:v3.5.151-conversation-tone-metric-dev` (si registry possede ce tag) OU rebuild depuis `0e26bfc3` avec tag neuf immuable `v3.5.151-rollback-dev-{date}` documente en infra commit.
- Client DEV : idem `v3.5.174-conversation-tone-metric-ux-dev` ou rebuild avec build args DEV explicites.

### 8.3 Manifests
- `keybuzz-infra/k8s/dev/keybuzz-api/deployment.yaml` : remplacer image tag.
- `keybuzz-infra/k8s/dev/keybuzz-client/deployment.yaml` : idem.
- Commit infra dedie : `gitops(dev): rollback API + Client DEV to PROD-equivalent baseline (KEY-XXX)`.

### 8.4 Ordre apply
1. API DEV manifest commit + push.
2. `kubectl apply -f` API DEV.
3. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev`.
4. Verifier MATCH=yes spec / last-applied / pod image.
5. Probe `/health` 200.
6. Client DEV manifest commit + push.
7. `kubectl apply -f` Client DEV.
8. `kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev`.
9. Verifier MATCH=yes.
10. Probe Client DEV via navigateur logged-in (QA Ludovic).

### 8.5 Validation post-rollback
- Inbox DEV affiche conversations.
- Brouillon IA SWITAA AUTOPILOT fonctionne (verifier sur conversation recente).
- channels actifs, catalogue, dashboard fonctionnels.
- Pas de regression UX par rapport a la baseline AR.5.x.

### 8.6 Rollback back (reapplication de l etat actuel)
Si le rollback Scenario B casse quelque chose et qu il faut revenir a v3.5.168 + v3.5.179 :
1. Manifest infra : retabir tag `v3.5.168-escalation-notifications-dev` et `v3.5.179-as1-1-build-args-fix-dev`.
2. `kubectl apply -f`.
3. `kubectl rollout status`.
4. Manifests historiques disponibles en git history `keybuzz-infra` (commits anterieurs au rollback). Tag immutable -> reapply identique.

### 8.7 Risques
- AS.1 indisponible cote DEV : tests AS.1 (escalation notifications) ne peuvent plus se faire en DEV jusqu a re-build forward.
- KEY-302 indisponible cote DEV : risque latent reintroduction de l incident AS.1.1 si un rebuild Client se fait ulterieurement sans build args.
- Confusion source HEAD vs runtime : HEAD post-AS.5.4 byte-equivalent au runtime ACTUEL ; un rollback runtime sans revert source HEAD reintroduit un drift source/runtime de signe inverse (HEAD AS.1 active vs runtime AR.5.x).
- Coordination GitOps : la branche `ph147.4/source-of-truth` doit etre revertee ou un nouveau commit doit etre fait pour pointer le HEAD vers `0e26bfc3` si l intention est de figer aussi la source. Sinon dette source/runtime nouvelle.

### 8.8 Coordination source revert (si rollback runtime decide)
Si scenario B est execute, il faut AUSSI proposer un revert source-only (pattern AS.5.4) :
- API : revert commit AS.1 `070707a1` par un nouveau commit revert dedie.
- Client : reverts 3 commits AS.1 (37e70ac + a69477a + f244a58) par 3 nouveaux commits.
- Pousser archives :
  - `archive/scenario-B-api-as1-070707a1`
  - `archive/scenario-B-client-as1-37e70ac` + a69477a + f244a58.
- Diff vs nouvelles anchors `0e26bfc3` et `0a7306a` doit etre vide (validation byte-equivalence).
- Cout : meme risque que rollback runtime + perte KEY-302 source guard.

---

## 9. Recommendation

Maintenir le runtime DEV actuel (API v3.5.168 + Client v3.5.179) + le runtime PROD actuel (API v3.5.151 + Client v3.5.174). Aucune action mutationnelle.

Suivre Scenario A + Scenario C complementaire.

Plan immediat :
1. Ne pas appliquer le Scenario B (rollback DEV vers PROD baseline) tant que Ludovic n a pas exprime de doute UX concret en DEV.
2. Ne pas relancer de phase tenantGuard / security messages tant que la root cause AS.5 -> Brouillon IA absent n est pas isolee runtime.
3. Conserver les branches archive AS.x sur origin (preservation experimentation rollbackee).
4. Conserver le rapport AS.5.5 + AS.5.6A comme references documentaires verite courante.

Plan moyen terme (hors AS.5.6A) :
- Phase AS.5.7 (proposition) : analyse runtime DevTools / network trace SWITAA AUTOPILOT pour isoler la cause AS.5 -> Brouillon IA absent.
- Phase AS.6 (proposition) : reprise endpoint-by-endpoint tenantGuard SI root cause isolee + design QA integre.
- Phase NS (proposition) : investigation JWT_SESSION_ERROR PROD.
- Phase TD (proposition) : nettoyage repos dirty + dette tag + label Docker traceability + CLAUDE.md update keybuzz-admin-v2.
- Phase Promotion AS.1 PROD (KEY-263) : seulement apres KEY-301 + KEY-304 resolus + KEY-302 hardening inclus.

---

## 10. Gaps

1. Traceability inverse PROD baseline (v3.5.151 / v3.5.174) -> commit precis : non documente formellement dans le registry (pas de label org.opencontainers.image.revision). Inference par commit message + rapport PH uniquement. Confiance MED.

2. Image registry tag v3.5.151-conversation-tone-metric-dev : non verifie present / absent. Si scenario B etait declenche, le pre-requis "image cible existe" doit etre verifie avant tout apply. Hors scope read-only AS.5.6A car cela necessiterait soit un docker pull soit un curl GHCR API.

3. Statut formel PROD des commits intermediaires `0e26bfc3` (AR.5.1), `462ec358` (AR.6), `03818fea` (AR.7), `dac5b790` (AR.2), etc. : non audite. Le runtime PROD pointe `v3.5.151-conversation-tone-metric-prod` mais quels commits anterieurs ont ete promus en PROD via quelles images intermediaires reste un audit historique non couvert ici.

4. KEY-292 PROD promotion (AR.5.2) : runtime PROD inclut, mais audit de la chaine complete des promotions PROD API depuis AR.5.2 jusqu a aujourd hui (hors AS.x) non couvert.

5. Outbound worker v3.5.165 escalation flow : aucun rapport PH AS.x ne couvre ce tag explicitement. Origin probable : phase pre-AS.1 escalation flow KEY-265. A retrouver via git log keybuzz-api ou via CURRENT_STATE.md complet.

6. JWT_SESSION_ERROR PROD (note AS.5.5) reste non investiguee dans AS.5.6A. Hors scope alignment DEV/PROD.

7. Repos dirty non-build identifies en AS.5.5 (keybuzz-api dist, keybuzz-backend .bak, keybuzz-admin quarantine) : non actionnes ici, hors scope alignment.

---

## 11. Linear texts prepared, NOT posted

POSTING ON HOLD. Conformite AS.5.4 / AS.5.5 : aucun post Linear. Textes disclosure-controlled prepares uniquement.

### KEY-263 - propose (Blocked / In Review)
```
AS.5.6A audit alignement DEV/PROD : KEY-263 (AS.1 escalation notifications) reste DEV uniquement. Code DEV stable (v3.5.168 API + v3.5.179 Client). Promotion PROD bloquee par KEY-301 + KEY-304. Aucun GO PROD a ce stade. Hardening KEY-302 a inclure dans toute prochaine promotion Client PROD.
Statut : reste Blocked.
```

### KEY-302 - propose (Done DEV / In Review)
```
AS.5.6A audit confirme : KEY-302 client build args hardening en place et durable cote source + bundle DEV v3.5.179. PROD Client v3.5.174 ne contient pas KEY-302 ; inclusion obligatoire dans toute prochaine promotion Client PROD pour eviter recurrence incident AS.1.1.
Statut suggere : Done DEV ou In Review.
```

### KEY-292 - propose (info-only, no action)
```
AS.5.6A confirme : AR.5.1/AR.5.2 conversation tone metric promu en PROD (runtime v3.5.151 API + v3.5.174 Client). Baseline stable.
```

### KEY-301 - propose (Open, no change)
```
AS.5.6A audit alignement DEV/PROD : KEY-301 tenantGuard runtime reste ouvert. Bloque promotion KEY-263. A reprendre apres root cause AS.5 isolee.
Statut : reste Open.
```

### KEY-304 - propose (Open, no change)
```
AS.5.6A audit confirme : security messages a refaire endpoint-by-endpoint apres phase design dediee. Branches archive sur origin preservent experimentation AS.5.
Statut : reste Open.
```

### KEY-305 - propose (info-only)
```
AS.5.6A : source DEV alignee runtime DEV. Brouillon IA SWITAA AUTOPILOT fonctionnel DEV v3.5.179 (confirme QA Ludovic AS.5.3). Aucun delta KEY-305 nouveau detecte.
```

POSTING ON HOLD : ne rien publier avant nouveau GO Ludovic explicite.

---

### 11.bis Phrase cible finale

DEV (API v3.5.168 + Client v3.5.179 + Backend v1.0.47 + Worker v3.5.165 + Website v0.6.12 + Admin v2.12.2) et PROD (API v3.5.151 + Client v3.5.174 + Backend v1.0.47 + Worker v3.5.165 + Website v0.6.12 + Admin v2.12.2) sont fonctionnellement alignes : 4 services SAME byte-identiques, 2 services DEV_AHEAD_EXPECTED traces (AS.1 + KEY-302) ; aucun drift dangereux ; verdict AS.5.6A GO DEV AHEAD EXPECTED - KEEP CURRENT RUNTIME ; aucun build, aucun deploy, aucun apply, aucune mutation DB, aucun post Linear realise dans cette phase.

STOP
