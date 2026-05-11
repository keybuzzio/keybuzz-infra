# PH-SAAS-T8.12AS.5.3 -- AI Draft SWITAA Rollback and Source Truth

> Date : 2026-05-11
> Linear : KEY-305 (parent) ; KEY-304 ; KEY-301 ; KEY-263
> Phase : correction du mis-diagnostic AS.5.2 + rollback coordonne DEV pre-AS.5
> Environnement : DEV pour rollback ; PROD READ-ONLY

## VERDICT

**GO ROLLBACK PRE-AS5 RESTORED READY -- BROUILLON IA RESTORED IN DEV -- AS.5 IDENTIFIED AS REGRESSION SOURCE -- AS.5 TENANT GUARD TEMPORARILY DISABLED -- PROD UNCHANGED**

Apres rollback coordonne API v3.5.169 -> v3.5.168 + Client v3.5.180 -> v3.5.179, le tenant SWITAA en plan AUTOPILOT affiche a nouveau le panneau "Brouillon IA" automatique avec le flow attendu (bouton "Valider et envoyer", contenu draft pertinent y compris reference au tracking quand fourni). QA Ludovic confirme "OK -- Brouillon IA visible auto".

La regression visible cote IA est donc imputable au cycle AS.5 (commits keybuzz-api `eae84b58` + keybuzz-client `57766ea` + commit follow-up `8d8121f`). L'API source eae84b58 + le Client source 57766ea ne touchent pas directement le flow autopilot draft (ni `InboxTripane.tsx:354` PH143-E.4 fetch, ni `AISuggestionSlideOver.tsx:213` PH142-F auto-open), mais leur combinaison en runtime casse le comportement attendu d'une maniere non encore expliquee (analyse statique READ-ONLY n'a pas trouve la cause directe -- le draft API repond bien hasDraft=true mais le panneau ne s'ouvre pas en "Brouillon IA" cote Client v3.5.180).

Trade-off assume : la protection AS.5 du prefix `/messages` est temporairement desactivee en runtime DEV (KEY-301 et KEY-304 reouverts), pour donner priorite a la restauration du flow IA en DEV. Reprise endpoint-by-endpoint security a planifier dans une phase future avec QA AI complete avant chaque deploy.

PROD strictement inchangee tout au long de la phase.

---

## 1. Pourquoi AS.5.2 etait invalide

Le rapport AS.5.2 a teste l'autopilot draft uniquement sur le tenant `ecomlg-001` (plan PRO) qui est PAR DESIGN plan-gate a `maxMode='suggestion'`. La conclusion "not-a-bug / plan-gated" etait techniquement correcte pour ce tenant mais ne repondait PAS au bug signale par Ludovic, qui teste sur le tenant SWITAA en plan AUTOPILOT.

Cette phase AS.5.3 annule explicitement cette conclusion AS.5.2 :

- ecomlg-001 plan PRO : pas de draft auto (par design plan-gating PH137-D) -- ETAT NORMAL
- SWITAA plan AUTOPILOT : devrait avoir draft auto -- BUG REEL constate en DEV v3.5.180

AS.5.2 a teste le mauvais sujet. AS.5.3 le corrige et execute le rollback.

---

## 2. Tenant SWITAA truth

| Champ | Valeur | Source preuve |
|---|---|---|
| tenant id | `switaa-sasu-mnc1x4eq` | `tenants` table |
| name | "SWITAA SASU" | `tenants` table |
| plan in tenants table | "AUTOPILOT" | `tenants` table |
| plan in billing_subscriptions | "AUTOPILOT" active (current_period_end 2026-05-12) | `billing_subscriptions` table |
| autopilot_settings.mode | "autonomous" | `autopilot_settings` table id=150 |
| autopilot_settings.is_enabled | true | idem |
| ai_action_log autopilot_* recents | 39 entries avec payload draftText, dont 2026-05-11 06:52:56 (autopilot_escalate, blocked_reason=ESCALATION_DRAFT:0.85) | DB query |

Resultat : SWITAA est bien le tenant AUTOPILOT actif sur lequel le flow Brouillon IA devrait fonctionner.

Le user/email Ludovic est confirme membre de SWITAA par sa capacite a se connecter dessus en QA (et par le 401 retourne quand le test direct curl utilise un email non-membre comme `ludo.gonthier@gmail.com`).

---

## 3. Runtime baseline pre-rollback (v3.5.169 + v3.5.180)

| Service | Image avant rollback | Verdict |
|---|---|---|
| API DEV | v3.5.169-messages-tenant-guard-dev | AS.5 protection /messages active |
| Client DEV | v3.5.180-messages-bff-tenant-guard-dev | AS.5 BFF /api/messages active |
| API PROD | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend/Website/Admin/OW PROD | inchanges depuis longtemps | INCHANGE |

Test direct API READ-ONLY (depuis bastion, sans auth, /autopilot non protege par PROTECTED_PREFIXES) :

```
GET https://api-dev.keybuzz.io/autopilot/draft?tenantId=switaa-sasu-mnc1x4eq&conversationId=cmmp0uhhkd695e199f853a0a7
status=200 body_len=793
{"hasDraft":true,"draftText":"Bonjour Switaa 26, Merci pour votre message. Concernant votre commande 401-55212552-884666, je vois que vous avez mentionne un suivi UPS : 1Z4971486898667954. Je vais verifier le statut de votre colis. (...)","confidence":0.85,"actionType":"autopilot_escalate","createdAt":"2026-05-11T06:52:56.597Z","logId":"alog-1778482376594-r4hd0qpkn","escalationStatus":"escalated","escalationReason":"IA a detecte une promesse d'action non executable: je transmets","needsHumanAction":true}
```

Logs API DEV showed `req-1kv` (cluster-internal GET /autopilot/draft pour SWITAA conv depuis BFF Client). La chaine fonctionne techniquement. Mais Ludovic confirme que le panneau Client n'affiche pas "Brouillon IA".

---

## 4. Rollback executed

### Commits source code (restent pousses sur origin)

- keybuzz-api `eae84b58` (AS.5 fix(security)) -- non revert
- keybuzz-client `57766ea` (AS.5 fix(client) BFF) -- non revert
- keybuzz-client `8d8121f` (AS.5.1 fix(inbox) useEffect) -- non revert

### Manifests infra rolled back

| Commit | Action | Apply order |
|---|---|---|
| `a7a5f50` | rollback Client v3.5.180 -> v3.5.179 + tentative API echouee (sed bracket regex issue) | 2eme |
| `87e8c3c` | rollback API v3.5.169 -> v3.5.168 (followup correction python) | 1er apply final |

### Apply

| Etape | Action | Resultat |
|---|---|---|
| 1 | kubectl apply API manifest v3.5.168 | successfully rolled out |
| 2 | kubectl apply Client manifest v3.5.179 | successfully rolled out |

Pas de fenetre downtime : API rollback en premier desactive le guard /messages, puis Client rollback retire la BFF /api/messages mais peut faire browser-direct vers /messages sans guard -- accepte par v3.5.168.

---

## 5. Runtime post-rollback (v3.5.168 + v3.5.179)

| Service | Image apres rollback | Ready | Verdict |
|---|---|---|---|
| API DEV | v3.5.168-escalation-notifications-dev | 1/1 Running | RESTORED pre-AS.5 |
| Client DEV | v3.5.179-as1-1-build-args-fix-dev | 1/1 Running | RESTORED pre-AS.5 |

Aucun mutation runtime PROD, aucun docker push, aucun build, aucun DB mutation pendant la phase.

---

## 6. QA Ludovic post-rollback

Question posee : "Apres rollback DEV coordonne, connecte sur SWITAA AUTOPILOT et selectionne une conversation -- le panneau affiche-t-il maintenant 'Brouillon IA' avec bouton 'Valider et envoyer' ?"

Reponse Ludovic : **"OK -- Brouillon IA visible auto"**.

Cela confirme que :

1. Le rollback DEV pre-AS.5 restaure le comportement attendu pour SWITAA.
2. La regression visible cote IA est imputable au cycle AS.5 (eae84b58 + 57766ea + 8d8121f).
3. La cause exacte interne au cycle AS.5 n'est pas encore comprise par analyse statique READ-ONLY (le code des composants Brouillon IA et la fetch /api/autopilot/draft sont strictement inchanges par AS.5). Phase d'investigation source-side reservee a une iteration future.

---

## 7. PROD read-only

| Service PROD | Image | Verdict |
|---|---|---|
| API PROD | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| OW PROD | v3.5.165-escalation-flow-prod | INCHANGE |

Aucun docker push PROD. Aucun kubectl apply PROD. Aucune mutation DB PROD.

---

## 8. Source/runtime truth

| Repo | Source HEAD | Image runtime | Coherence | Risque rebuild HEAD |
|---|---|---|---|---|
| keybuzz-api | eae84b58 (AS.5 tenant guard) | v3.5.168 (built from 070707a1 = parent pre-AS.5) | DIVERGENCE | Rebuild HEAD reconstruirait v3.5.169 et reactiverait AS.5 -- pas immediatement dangereux mais reactive le scope strict |
| keybuzz-client | 8d8121f (AS.5.1 useEffect) -> contient aussi 57766ea (AS.5 BFF) | v3.5.179 (built from f244a58 = pre-AS.5) | DIVERGENCE | Rebuild HEAD reconstruirait v3.5.181 qui cause la regression Brouillon IA selon le diagnostic AS.5.3 -- RISQUE ELEVE |
| keybuzz-infra | a7a5f50 + 87e8c3c (manifests rolled back) | runtime = manifest | aligne | aucun |

Decision recommandee (NON EXECUTEE dans cette phase) : **revert source par nouveaux commits** pour aligner les branches source actives avec le runtime stable actuel, similaire a AS.4.3 :

- keybuzz-api : `git revert eae84b58` -> revient fonctionnellement a 070707a1
- keybuzz-client : `git revert 8d8121f 57766ea` (ordre inverse) -> revient fonctionnellement a f244a58

Conserver les commits experimentaux via branches archive AS.5 dediees :

- `archive/key-304-api-as5-tenant-guard-eae84b58`
- `archive/key-304-client-as5-bff-57766ea`
- `archive/key-305-client-as5-1-useeffect-8d8121f`

A executer dans une phase dediee (PH-SAAS-T8.12AS.5.4-AI-DRAFT-SOURCE-RECONCILIATION-01 par exemple), avec GO explicite Ludovic.

---

## 9. Validations securite et non-regression

### Non-regression PROD

PROD 8/8 services inchanges (cf section 7). Aucun risque PROD.

### Securite DEV : trade-off assume

**AS.5 protection /messages tenant guard n'est plus active en runtime DEV.**

Test post-rollback (read-only via curl bastion) :

```
GET https://api-dev.keybuzz.io/messages/conversations?tenantId=switaa-sasu-mnc1x4eq&limit=1
(sans auth header)
```

Comportement attendu post-rollback : 200 + data (guard inactif). C'est exactement l'etat KEY-301 originel, equivalent a pre-AS.5.

Implications :

- KEY-301 reste OPEN -- faille runtime tenantGuard non protegee
- KEY-304 reste OPEN -- patch endpoint-by-endpoint en standby
- AS.1 PROD reste BLOQUE -- /notifications expose en runtime PROD
- KEY-302 reste DONE -- Dockerfile Client build args hardening preserve

Ce trade-off securite/produit est **assume** : priorite donnee a la restauration du flow IA en DEV pour ne pas bloquer l'acquisition active. La reprise endpoint-by-endpoint securite devra integrer un QA complet du flow IA (Brouillon IA, evaluate, execute, assist) avant chaque deploy.

---

## 10. Gaps restants

1. **Cause exacte de la regression AS.5 sur le flow Brouillon IA** : non identifiee par analyse statique READ-ONLY. L'API draft repond hasDraft=true, le code Client `InboxTripane.tsx:354` et `AISuggestionSlideOver.tsx:213` sont inchanges par AS.5. Une investigation runtime cote Client (DevTools, network tab, console, React state) sera necessaire dans une phase d'observation dediee.
2. **Source HEAD diverge du runtime** : risque opera eleve si build HEAD lance sans plan. Revert source AS.5 par nouveaux commits recommande (cf section 8).
3. **AS.5 (KEY-304) endpoint-by-endpoint en standby** : la sequence /messages -> /notifications -> /ai -> /channels/suppliers -> /tenants reste planifiee mais doit etre revue pour eviter la regression Brouillon IA. QA AI obligatoire avant chaque deploy.
4. **AS.1 PROD reste BLOQUE** par KEY-301/304 reouverts.
5. **Image v3.5.180-messages-bff-tenant-guard-dev** + **v3.5.181-inbox-ai-auto-suggestion-dev** restent dans le registry mais hors runtime. A documenter comme "do not redeploy" ou a purger plus tard.
6. **KEY-302 verify-bundle script** : gap connu mode BFF non supporte, hors scope.

---

## 11. Linear text ready, not posted

### KEY-305 (a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5.3 -- correction AS.5.2 + rollback DEV coordonne.

CORRECTION AS.5.2
La conclusion AS.5.2 "not-a-bug / plan-gated" reposait sur le mauvais
tenant (ecomlg-001 PRO). Le bug reel concerne SWITAA AUTOPILOT. AS.5.2
est donc invalidee pour KEY-305.

ROLLBACK EXECUTE EN DEV
- API DEV : v3.5.169 -> v3.5.168-escalation-notifications-dev
- Client DEV : v3.5.180 -> v3.5.179-as1-1-build-args-fix-dev
- Ordre apply : API en premier, Client en second
- Commits infra : a7a5f50 (Client) + 87e8c3c (API followup python)

QA LUDOVIC POST-ROLLBACK : "OK -- Brouillon IA visible auto" sur
SWITAA AUTOPILOT. Flow restaure conforme PROD.

DIAGNOSTIC
- API /autopilot/draft repond hasDraft=true pour SWITAA conv recentes
  (10 drafts matchent les conditions handler, dont 2026-05-11 06:52)
- logs API DEV montrent req cluster-internal Client BFF -> API qui
  recoit bien la demande draft
- code AISuggestionSlideOver + InboxTripane pour le flow Brouillon IA
  est INCHANGE par AS.5
- mais en runtime v3.5.180 le panneau affiche "Suggestion IA" au lieu
  de "Brouillon IA". Cause statique non identifiee READ-ONLY.

Le rollback restaure le bon comportement. La cause exacte de
la regression introduite par AS.5 sur le flow IA reste a investiguer
dans une phase dediee (DevTools / network tab cote Client + diff
runtime bundle v3.5.179 vs v3.5.180).

TRADE-OFF SECURITE ASSUME
AS.5 protection /messages tenantGuard runtime est temporairement
desactivee. KEY-301 + KEY-304 sont re-ouverts comme avant AS.5. AS.1
PROD reste BLOQUE. La reprise endpoint-by-endpoint securite devra
integrer un QA AI complet avant chaque deploy futur.

PROD STRICTEMENT INCHANGEE.

Source code reste pousse sur origin :
- keybuzz-api eae84b58 (AS.5 tenant guard)
- keybuzz-client 57766ea (AS.5 BFF) + 8d8121f (AS.5.1 useEffect)

Recommandation : ouvrir une phase de revert source dediee (AS.5.4
proposee) avec branches archive avant rebuild.

Rapport : keybuzz-infra commit a venir
docs/PH-SAAS-T8.12AS.5.3-AI-DRAFT-SWITAA-ROLLBACK-AND-SOURCE-TRUTH-01.md
ASCII strict.
```

### KEY-304 (a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5.3 -- rollback DEV coordonne suite a regression IA
sous AS.5.

AS.5 protection /messages tenantGuard runtime est temporairement
desactivee en DEV (rollback API v3.5.169 -> v3.5.168). La sequence
endpoint-by-endpoint (AS.6 /notifications -> AS.7 /ai -> AS.8
/channels, /suppliers -> AS.9 /tenants) est mise en pause jusqu'a
identification de la cause AS.5 sur le flow Brouillon IA.

Reprise conditionnee a :
1. analyse runtime DevTools / network / state Client sur SWITAA
2. revert source des commits AS.5 (eae84b58, 57766ea, 8d8121f)
3. QA AI complet avant chaque deploy securite futur

KEY-304 reste OPEN.
```

### KEY-301 (a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5.3 -- AS.5 desactivee runtime DEV apres regression IA.

La faille runtime tenantGuard du audit AS.3 reste exposee en DEV et
en PROD (etat equivalent a pre-AS.5). KEY-301 reste OPEN. AS.1 PROD
reste BLOQUE.

La reprise securite necessitera resolution prealable de la
regression AS.5 sur le flow Brouillon IA (cf KEY-305).
```

### KEY-263 (a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5.3 -- AS.1 PROD reste BLOQUE.

Le rollback DEV pour restaurer le flow Brouillon IA implique le
desactivation temporaire d'AS.5 (KEY-304). La sequence prealable a
toute reprise AS.1 PROD reste : (1) revert source AS.5, (2) re-design
AS.5 avec QA AI integre, (3) AS.6 /notifications, puis (4) AS.1 PROD.
```

---

## 12. Phrase cible finale

Le rapport AS.5.2 avait diagnostique a tort sur le tenant `ecomlg-001` (plan PRO, plan-gate par design) au lieu du tenant SWITAA (plan AUTOPILOT) utilise par Ludovic ; AS.5.3 corrige ce mis-diagnostic et execute un rollback DEV coordonne API v3.5.169 -> v3.5.168 + Client v3.5.180 -> v3.5.179 (commits infra a7a5f50 + 87e8c3c) qui restaure immediatement le flow attendu sur SWITAA (QA Ludovic "Brouillon IA visible auto"), demontrant que la regression IA visible cote DEV avait bien ete introduite par le cycle AS.5 (commits keybuzz-api eae84b58 + keybuzz-client 57766ea + 8d8121f) -- la cause exacte interne au cycle AS.5 n'est pas identifiee par analyse statique READ-ONLY et necessite une phase d'investigation runtime separee ; trade-off securite assume : AS.5 protection /messages tenantGuard runtime est desactivee temporairement, KEY-301 + KEY-304 reouverts comme avant AS.5, AS.1 PROD reste BLOQUE ; PROD strictement inchangee tout au long ; la branche source keybuzz-client diverge du runtime stable (HEAD `8d8121f` au-dessus du commit `f244a58` qui correspond a v3.5.179) et un futur build depuis HEAD reconstruirait l'image qui casse le flow Brouillon IA -- revert source AS.5 par nouveaux commits recommande dans une phase dediee.

STOP -- runtime DEV stable et conforme PROD-attendu, en attente decision Ludovic sur revert source AS.5 et re-design futur AS.5.
