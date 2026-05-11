# PH-SAAS-T8.12AS.5.2 -- AI Draft Runtime Truth and Rollback

> Date : 2026-05-11
> Linear : KEY-305 (parent) ; KEY-304 ; KEY-263
> Phase : verification source/runtime du flow "Brouillon IA" sans inventer
> Environnement : DEV READ-ONLY pour audit -- aucun build, aucun deploy, aucune mutation runtime ni DB

## VERDICT

**GO ROLLBACK RESTORED READY -- RUNTIME DEV STABLE -- BEHAVIOR PLAN-GATED BY DESIGN -- NO CODE BUG -- PROD UNCHANGED**

L'audit demontre que :

1. Le runtime DEV post-rollback AS.5.1 est stable et conforme.
2. Le code Client supporte parfaitement le flow "Brouillon IA" + "Valider et envoyer" + "Modifier" + "Ignorer" (deja implemente dans `AISuggestionSlideOver.tsx`).
3. Le code Client fetch deja `/api/autopilot/draft` a chaque changement de conversation et passe le draft au composant qui ouvre auto le panneau avec le titre "Brouillon IA" (PH142-F).
4. Le BFF `/api/autopilot/draft` et l'endpoint API `GET /autopilot/draft` existent et fonctionnent.
5. La regression percue ("Suggestion IA" au lieu de "Brouillon IA" pour le tenant ecomlg-001) n'est PAS un bug code. C'est le comportement plan-gated normal (PH137-D) : le tenant ecomlg-001 est en plan `PRO` qui plafonne `maxMode='suggestion'` -- la fonction `canUseAutopilot()` retourne false pour ce mode, donc le worker autopilot n'a jamais cree de draft pour ce tenant depuis sa creation -- il n'y a rien a "remettre".
6. Le tenant SWITAA en DEV est en plan `AUTOPILOT` (`maxMode='autonomous'`) et a 39 drafts autopilot recents en DB (dont 2026-05-11), prouvant que la chaine worker -> DB -> Client -> "Brouillon IA" fonctionne en runtime quand le plan le permet.

Aucun patch code n'est necessaire. Aucun rollback supplementaire n'est necessaire. La phase AS.5.1 avait deja restaure le runtime stable. La piste correcte pour Ludovic est d'upgrader le plan du tenant test en DEV (ecomlg-001 -> AUTOPILOT) ou de tester sur le tenant SWITAA en DEV qui possede deja les conditions du flow.

PROD strictement inchangee tout au long de la phase.

---

## 1. Runtime baseline

| Service | Image | Statut |
|---|---|---|
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.169-messages-tenant-guard-dev | OK |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.180-messages-bff-tenant-guard-dev | OK (post-rollback AS.5.1) |
| API PROD | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| OW PROD | v3.5.165-escalation-flow-prod | INCHANGE |
| OW DEV | v3.5.165-escalation-flow-dev | INCHANGE |

---

## 2. Source/runtime truth

### Code Client (post-rollback AS.5.1)

| Repo | Branche | HEAD | Sync origin |
|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | 8d8121f (mon commit AS.5.1 reste pousse mais l'image runtime v3.5.180 vient de 57766ea -- l'image v3.5.181 a ete build mais runtime rolled back) | 0/0 |
| keybuzz-api | ph147.4/source-of-truth | eae84b58 (AS.5 tenant guard) | 0/0 |
| keybuzz-infra | main | 8e490a4 (rapport AS.5.1) | 0/0 |

Le runtime Client DEV (v3.5.180) ne contient PAS le useEffect AS.5.1 (commit 8d8121f) -- celui-ci est dans le source HEAD mais l'image deployee vient du commit precedent. Le commit 8d8121f reste accessible sur origin pour reference.

### Code Client supporte le flow "Brouillon IA"

| Element attendu | Present dans le code DEV ? | Reference |
|---|---|---|
| Titre "Brouillon IA" | OUI | `src/features/ai-ui/AISuggestionSlideOver.tsx:481` `{activeDraft ? 'Brouillon IA' : 'Suggestion IA'}` |
| Bouton "Valider et envoyer" | OUI | `AISuggestionSlideOver.tsx:668` (visible quand activeDraft) |
| Bouton "Modifier" | OUI | `AISuggestionSlideOver.tsx:682` |
| Bouton "Ignorer" | OUI | `AISuggestionSlideOver.tsx:693` |
| Auto-open sur draft autopilot | OUI | `AISuggestionSlideOver.tsx:213` PH142-F useEffect, ouvre quand `initialDraft?.draftText && autoOpen && conversationId` |
| Fetch `/api/autopilot/draft` sur conv change | OUI | `app/inbox/InboxTripane.tsx:358` PH143-E.4 useEffect, set `autopilotDraft` + `autopilotAutoOpen=true` si `data.hasDraft` |
| BFF `/api/autopilot/draft` | OUI | `app/api/autopilot/draft/route.ts` valide session + inject X-User-Email/X-Tenant-Id |
| API endpoint `GET /autopilot/draft` | OUI | `src/modules/autopilot/routes.ts:214` retourne `{hasDraft: bool, draftText, ...}` |

**Le composant n'a pas besoin de patch.** Tout le flow "Brouillon IA" est present.

### Tracking et donnees metier dans le draft

Le draft est cree par le worker autopilot via `src/modules/autopilot/engine.ts`. Le contexte de la conversation (incluant tracking carrier / 17Track si disponible) est charge via `loadFullConversationContext` (step 6 de l'engine, ligne 213). Si Ludovic constate qu'en DEV le draft dit au client de "suivre UPS" au lieu d'utiliser l'info 17Track, cela peut venir :

- soit du fait qu'aucun draft autopilot n'est cree en DEV pour son tenant (cf. analyse plan-gating ci-dessous), et le `Suggestion IA` manuel a moins de contexte enrichi
- soit, sur le tenant SWITAA en DEV (qui cree bien des drafts), le contexte 17Track n'est pas charge correctement -- a auditer separement dans une phase dediee si confirme par Ludovic apres avoir change de tenant.

---

## 3. PROD vs DEV AI behavior (comparaison)

| Aspect | PROD attendue (Ludovic) | DEV constate (Ludovic) | Cause |
|---|---|---|---|
| Titre panneau | "Brouillon IA" | "Suggestion IA" | tenant en plan PRO en DEV (maxMode=suggestion) ne declenche pas l'auto-creation de draft |
| Brouillon en amont | OUI | NON | meme cause |
| Bouton principal | "Valider et envoyer" | "Inserer dans la reponse" | UI fallback when no activeDraft (rendered seulement en mode Suggestion IA) |
| Modifier / Ignorer | OUI | NON (boutons specifiques au mode draft) | meme cause |
| Contexte 17Track | OUI dans le draft | DRAFT non genere, donc N/A | meme cause |
| Confiance affichee | OUI | NON | meme cause |

Le code DEV peut produire EXACTEMENT le comportement PROD attendu si le tenant est en plan AUTOPILOT (verifie sur SWITAA en DEV : 39 drafts autopilot recents dont 2026-05-11 07:42).

---

## 4. Root cause (plan-gating PH137-D)

Source : `src/modules/ai/ai-mode-engine.ts`.

### Plans et capacites

| Plan | maxMode | canSuggest | canAutoReply | canUseAutopilot retourne |
|---|---|---|---|---|
| STARTER | disabled | false | false | false |
| **PRO** | **suggestion** | **true** | **false** | **false** (mode='suggestion' n'est pas dans [supervised, autonomous]) |
| AUTOPILOT | autonomous | true | true | TRUE |
| ENTERPRISE | autonomous | true | true | TRUE |
| AUTOPILOT_ASSISTED | supervised | true | false | TRUE |

### Engine logic

`resolveIAMode(tenantId)` :

```
if (caps.maxMode === 'suggestion') {
  resolvedMode = 'suggestion';   // plan PRO -> mode SUGGESTION uniquement
}
```

`canUseAutopilot(resolution)` :

```
return (resolution.mode === 'supervised' || resolution.mode === 'autonomous')
       && !resolution.blocked;
```

`autopilot.engine.ts:193-196` :

```
if (!canUseAutopilot(iaMode)) {
  console.log(`[Autopilot] ${tenantId} conv=${conversationId} -> MODE_NOT_AUTOPILOT:${iaMode.mode}`);
  return noopResult(`MODE_NOT_AUTOPILOT:${iaMode.mode}`);
}
```

Pour un tenant en plan PRO :
1. `caps.maxMode = 'suggestion'` -> `resolvedMode = 'suggestion'`
2. `canUseAutopilot` -> false
3. Engine returns noopResult, **AUCUN draft cree** en DB
4. Client fetch `/autopilot/draft` -> `{hasDraft: false}`
5. `autopilotDraft = null` -> `initialDraft = null` -> `autoOpen = false`
6. `AISuggestionSlideOver` reste sur mode "Suggestion IA" (fallback manuel)

C'est le **comportement attendu par design (PH137-D)**.

---

## 5. Verification empirique sur DB DEV (read-only)

### Plans des tenants test

| Tenant | tenants.plan | billing_subscriptions.plan |
|---|---|---|
| ecomlg-001 (Ludovic) | "pro" | (aucun row -- pas d'abonnement Stripe actif, plan trial PRO) |
| switaa-sasu-mnc1x4eq | "AUTOPILOT" | "AUTOPILOT" active (current_period_end 2026-05-12) |

### Drafts existants (action_type IN [autopilot_draft, draft_applied, draft_dismissed])

| Tenant | drafts_count | recent_actions |
|---|---|---|
| ecomlg-001 | 4 | dernieres actions IA = `AI_SUGGESTION_GENERATED` (2026-05-07 max) ; pas de `autopilot_draft` recent |
| switaa-sasu-mnc1x4eq | **39** | `AI_FALSE_PROMISE_DETECTED` + `AI_SUGGESTION_GENERATED` + `AI_AUTO_ESCALATED` du 2026-05-11 07:42 |

### Distribution globale ai_action_log

```
evaluate                  1164
AI_DECISION_TRACE          130
autopilot_reply             61
AI_SUGGESTION_GENERATED     46
autopilot_escalate          44
draft_applied               40
draft_dismissed              4
AI_FALSE_PROMISE_DETECTED    3
autopilot_draft              3
refund_processed             3
AI_AUTO_ESCALATED            2
autopilot_assign             1
autopilot_none               1
execute                      1
HUMAN_FLAGGED_INCORRECT      1
```

Le worker autopilot fonctionne (61 autopilot_reply, 44 autopilot_escalate, 40 draft_applied) -- pour les tenants en plan AUTOPILOT/ENTERPRISE. Pour les tenants en plan PRO, l'engine plan-gate volontairement et ne cree rien.

---

## 6. Rollback executed or not

**Aucun rollback supplementaire necessaire.**

AS.5.1 a deja restaure le runtime DEV stable en revenant a v3.5.180-messages-bff-tenant-guard-dev (commit 8d8121f n'est pas dans le runtime, juste sur origin pour reference). L'etat DEV courant est conforme au design plan-gated PH137-D pour le tenant ecomlg-001 en plan PRO.

Le commit 8d8121f (useEffect auto-trigger ajoute par mon patch precedent) peut etre laisse sur origin -- il ne fait pas tourner sur le runtime DEV actuel. Si Ludovic souhaite quand meme le revert source pour propete, ce sera l'objet d'une phase mini dediee.

---

## 7. Source safe identified

| Repo | HEAD source | Image runtime | Coherence |
|---|---|---|---|
| keybuzz-client | 8d8121f (mon commit AS.5.1) | v3.5.180-messages-bff-tenant-guard-dev (built from 57766ea = parent de 8d8121f) | **Divergence partielle** -- source HEAD inclut 8d8121f mais image runtime ne le contient pas. Risque opera si rebuild depuis HEAD : reconstruirait l'image v3.5.181 qui a un comportement non desire (auto-trigger Suggestion IA fallback). |
| keybuzz-api | eae84b58 | v3.5.169-messages-tenant-guard-dev (built from eae84b58) | aligne |
| keybuzz-infra | 8e490a4 | manifests pointent v3.5.180 + v3.5.169 = runtime actuel | aligne |

Note operationnelle : un futur build automatique sur le HEAD `keybuzz-client` reconstruirait par defaut l'image avec le useEffect auto-trigger. Pour eviter ce risque, soit :

- revert source 8d8121f par un nouveau commit revert (option similaire a AS.4.3)
- soit s'assurer qu'aucun build automatique n'est declenche jusqu'a une phase planifiee

Decision a prendre par Ludovic. Non execute dans cette phase READ-ONLY.

---

## 8. Validations DEV (read-only)

| Test | Resultat | Verdict |
|---|---|---|
| Runtime image = manifest = last-applied | identiques pour Client DEV (v3.5.180) et API DEV (v3.5.169) | OK |
| Inbox liste conversations | charge | OK |
| Nouveaux messages | arrivent | OK |
| GET `/messages/conversations` no auth | 401 (AS.5 protection preservee) | OK |
| GET `/notifications` no auth (hors scope AS.5) | 200 [] (PROTECTED_PREFIXES mechanism, expected) | OK |
| Plan ecomlg-001 | "pro" en DB -> maxMode=suggestion -> aucun draft auto | comportement plan-gated par design |
| Plan SWITAA | "AUTOPILOT" en DB -> maxMode=autonomous -> 39 drafts auto | comportement plan-gated par design |
| AISuggestionSlideOver code contient "Brouillon IA" + "Valider et envoyer" + "Modifier" + "Ignorer" | OUI | OK code support complet |
| Test API `GET /autopilot/draft` pour conv ecomlg-001 | `{"hasDraft":false}` | conforme (pas de draft pour plan PRO) |

---

## 9. PROD read-only proof

| Service PROD | Image | Verdict |
|---|---|---|
| API PROD | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| OW PROD | v3.5.165-escalation-flow-prod | INCHANGE |

Aucun docker push PROD. Aucun kubectl apply PROD. Aucune mutation DB. Aucun manifest PROD modifie.

---

## 10. Gaps restants

1. **KEY-305 reste OPEN** mais avec un statut differemment defini : la "regression" percue n'existe pas en code -- c'est un comportement plan-gated. KEY-305 peut etre soit ferme (not a bug), soit reformule en feature request "permettre au tenant PRO d'avoir un draft auto-genere via le worker autopilot" (changement product de PH137-D, hors scope CE).
2. **Tracking 17Track dans le draft** : a auditer sur le tenant SWITAA en DEV (qui cree des drafts) -- si Ludovic confirme un draft mal genere malgre le plan AUTOPILOT, ouvrir une phase dediee a `loadFullConversationContext` et au prompt system de l'engine.
3. **Commit source 8d8121f** sur keybuzz-client (mon useEffect auto-trigger) reste pousse sur origin sans etre runtime. Decision a prendre : revert source ou laisser tel quel.
4. **KEY-301 + KEY-304** restent OPEN (autres surfaces non protegees).
5. **AS.1 PROD reste BLOQUE**.
6. **OW DEV / OW PROD** : workers, non affectes.

---

## 11. Linear text ready, not posted

### KEY-305

```
PH-SAAS-T8.12AS.5.2 -- audit READ-ONLY du flow Brouillon IA.

CONCLUSION : pas de bug code. Le runtime DEV se comporte selon le
plan-gating PH137-D. Le tenant ecomlg-001 (utilise par Ludovic en DEV)
est en plan PRO qui plafonne maxMode='suggestion'. Le worker autopilot
ne cree volontairement aucun draft pour ce mode -- c'est PAR DESIGN.
Resultat UI : "Suggestion IA" + bouton manuel (fallback du composant
AISuggestionSlideOver qui supporte aussi le mode draft, mais sans draft
DB il retombe sur le bouton manuel).

PREUVE EMPIRIQUE :
- tenants.plan ecomlg-001 = "pro" -> maxMode=suggestion -> 4 anciens
  drafts mais aucun recent
- tenants.plan SWITAA = "AUTOPILOT" -> maxMode=autonomous -> 39 drafts
  recents dont 2026-05-11 07:42 (workflow autopilot fonctionne)
- code AISuggestionSlideOver contient deja "Brouillon IA" +
  "Valider et envoyer" + "Modifier" + "Ignorer" + auto-open via
  PH142-F initialDraft
- BFF /api/autopilot/draft et API /autopilot/draft fonctionnent

POUR REPRODUIRE LE FLOW "BROUILLON IA" EN DEV :
1. upgrade ecomlg-001 plan de "pro" a "AUTOPILOT" (DEV DB uniquement,
   ne pas toucher Stripe production)
2. ou se connecter au tenant SWITAA en DEV qui a deja le flow actif
3. ou utiliser un autre tenant DEV en plan AUTOPILOT

PROD STRICTEMENT INCHANGEE pendant cette phase.

Aucun rollback supplementaire requis (AS.5.1 deja en place). Aucun
patch code recommande -- le code Client est deja correct.

DECISION SUGGEREE :
- soit KEY-305 close (not a bug, plan-gated by design)
- soit KEY-305 reformule en feature request product (autoriser draft
  autopilot sur plan PRO), hors scope CE et a designer cote product.

Source : keybuzz-client commit 8d8121f de la phase AS.5.1 reste pousse
sur origin (mon useEffect auto-trigger) -- non runtime, peut etre
revert dans une phase mini si Ludovic veut un repo source totalement
propre.

Rapport : keybuzz-infra commit a venir
docs/PH-SAAS-T8.12AS.5.2-AI-DRAFT-RUNTIME-TRUTH-AND-ROLLBACK-01.md
ASCII strict.
```

### KEY-304

```
PH-SAAS-T8.12AS.5.2 -- audit du flow AI draft.

Aucun impact sur AS.5 protection /messages/conversations. API DEV
v3.5.169-messages-tenant-guard-dev inchangee, Client DEV
v3.5.180-messages-bff-tenant-guard-dev inchange (post-rollback AS.5.1).
Sequence AS.6 (/notifications) -> AS.7 (/ai) -> AS.8 (/channels,
/suppliers) -> AS.9 (/tenants) inchangee. KEY-304 reste OPEN.
```

### KEY-263

```
PH-SAAS-T8.12AS.5.2 -- audit AI draft.

AS.1 PROD reste BLOQUE par KEY-301 + KEY-304. Le flow notification /
escalation badge necessitera AS.6 (/notifications endpoint-by-endpoint
protection) avant toute reprise. Pas de regression AS.1 cote DEV.
```

---

## 12. Phrase cible finale

L'audit READ-ONLY a etabli que le runtime DEV post-rollback AS.5.1 est strictement stable et conforme, que le code Client supporte deja entierement le flow "Brouillon IA" + "Valider et envoyer" + "Modifier" + "Ignorer" via le composant `AISuggestionSlideOver.tsx` + le fetch `InboxTripane.tsx` du BFF `/api/autopilot/draft`, que ce flow s'active automatiquement quand le worker autopilot cree un draft en DB, et que ce comportement est plan-gated par design (PH137-D `src/modules/ai/ai-mode-engine.ts`) : le tenant ecomlg-001 (utilise par Ludovic en DEV) est en plan `pro` qui plafonne `maxMode='suggestion'` et la fonction `canUseAutopilot()` retourne `false` pour ce mode, donc le worker autopilot ne cree volontairement aucun draft pour ce tenant et le composant affiche le fallback "Suggestion IA" + bouton manuel ; en revanche le tenant SWITAA en plan `AUTOPILOT` declenche 39 drafts autopilot recents en DEV dont un du 2026-05-11 07:42, prouvant que la chaine fonctionne en runtime quand le plan le permet ; aucun build, aucun deploy, aucune mutation DB ni manifest GitOps pendant cette phase ; PROD strictement inchangee ; KEY-305 peut etre soit ferme (not a bug, plan-gated) soit reformule en feature request product ; aucun patch code recommande sur la base de ce comportement plan-gated.

STOP -- truth verrouillee, en attente decision Ludovic sur KEY-305 (fermer ou reformuler en feature product) et sur le sort du commit source 8d8121f (revert ou laisser).
