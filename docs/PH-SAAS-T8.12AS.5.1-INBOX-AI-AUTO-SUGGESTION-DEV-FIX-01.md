# PH-SAAS-T8.12AS.5.1 -- Inbox AI Auto-Suggestion DEV Fix

> Date : 2026-05-11
> Linear : KEY-305 (Inbox AI auto-suggestion)
> Phase : bugfix UX -- auto-suggestion IA Inbox
> Environnement : DEV uniquement -- PROD READ-ONLY

## VERDICT

**NO GO CLIENT REGRESSION -- ROLLBACK EXECUTED -- RUNTIME RESTORED -- WRONG APPROACH IDENTIFIED**

L'approche retenue (useEffect auto-trigger dans `AISuggestionSlideOver.tsx`) declenche bien une auto-generation IA sur changement de conversation, mais le comportement obtenu n'est pas celui attendu par Ludovic :

- l'auto-trigger se declenche a l'ouverture du panneau et affiche le titre "Suggestion IA" (mode manuel slide-over avec icone Sparkles)
- le comportement attendu est "Brouillon IA" : un draft autopilot auto-cree par le worker autopilot serveur, affiche dans le meme panneau avec icone Bot et le flow "valider / refuser le brouillon"

Le composant AISuggestionSlideOver supporte deja le mode "Brouillon IA" via la prop `initialDraft` + `autoOpen` (PH142-F) ; ce flow s'active quand un autopilot draft existe en DB pour la conversation. Comme le tenant SWITAA DEV est en mode `MODE_NOT_AUTOPILOT:suggestion` (vu dans les logs `/autopilot/evaluate` API DEV), aucun draft n'est cree automatiquement par le worker, donc le flow "Brouillon IA" ne se declenche pas et le panneau retombe sur le bouton manuel "Generer une suggestion".

Rollback DEV execute : Client DEV revenu sur `v3.5.180-messages-bff-tenant-guard-dev` (etat stable post-AS.5). La phase suivante doit cibler le flow autopilot draft (probable reactivation du mode autopilot sur le tenant test ou reparation de la chaine de creation de draft cote worker) plutot qu'un useEffect cote slide-over.

PROD strictement inchangee. AS.5 protection `/messages/conversations` reste OK (API DEV `v3.5.169-messages-tenant-guard-dev` inchangee).

---

## 0. Preflight

| Repo | Branche | HEAD initial | HEAD final | Sync origin | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | eae84b58 | eae84b58 (non touche) | 0/0 | 223 D dist artifacts (compris) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | 57766ea | 8d8121f (pousse sur origin, mais runtime rolled back) | 0/0 | tsbuildinfo (artifact) | OK |
| keybuzz-infra | main | f6479a5 | 46fd43f (incluant rollback) | 0/0 | clean | OK |

---

## 1. Runtime baseline

### Avant phase

| Service | Image |
|---|---|
| API DEV | v3.5.169-messages-tenant-guard-dev (AS.5) |
| Client DEV | v3.5.180-messages-bff-tenant-guard-dev (AS.5) |
| PROD all | inchanges depuis AS.5 |

### Apres phase (post-rollback)

| Service | Image |
|---|---|
| API DEV | v3.5.169-messages-tenant-guard-dev (INCHANGE) |
| Client DEV | v3.5.180-messages-bff-tenant-guard-dev (RESTORED) |
| PROD all | INCHANGE |

L'image experimentale v3.5.181-inbox-ai-auto-suggestion-dev a ete construite, poussee, deployee, puis rolled back -- elle reste disponible dans le registry pour reference mais n'est pas runtime.

---

## 2. Reproduction du symptome (avant patch)

Symptome rapporte par Ludovic : "panneau Suggestion IA s'ouvre mais affiche un bouton 'Generer une suggestion' a cliquer manuellement -- pas le comportement normal, il est cense se faire automatiquement".

| Check | Resultat |
|---|---|
| `/ai/assist` reachable sans auth depuis curl bastion | 200 + suggestion generee (API DEV repond bien) |
| Logs API DEV `/ai/*` 10 min de QA | uniquement `/ai/settings` et `/ai/wallet/status` -- aucun hit `/ai/assist`, `/ai/evaluate`, `/ai/execute` |
| Conclusion | le browser ne declenche pas l'appel auto-suggestion ; 100% cote Client |

---

## 3. Audit auto-trigger (Client)

| Composant inspecte | Auto-trigger observe ? | Notes |
|---|---|---|
| AISuggestionSlideOver.tsx (panneau slide-over visible dans Inbox) | NON pour `generateSuggestion` | seul auto-trigger existant : PH142-F autoOpen + initialDraft pour le flow "Brouillon IA" autopilot |
| AISuggestionsPanel.tsx (PRO+ panel) | NON | utilise `generateSuggestions` mais via boutons / useMemo, pas useEffect auto |
| AIAssistant.tsx | NON | composant bouton manuel (ligne 143 fetch direct `${API_URL}/ai/assist`) |
| AIDecisionPanel.tsx | NON | orchestrateur evaluateAI + assistAI, mais via boutons uniquement |

Recherche historique `git log -p --all -- AISuggestionSlideOver.tsx | grep auto.*generate` : **AUCUN resultat**. Le composant n'a jamais eu d'auto-trigger pour generateSuggestion dans son historique git.

---

## 4. Diff historique

Aucun commit n'a retire un useEffect d'auto-trigger pour `generateSuggestion`. Le comportement "Brouillon IA auto" attendu par Ludovic etait fourni par le **flow autopilot draft** (PH142-F) :

1. Worker autopilot (backend / outbound worker) cree un draft dans la DB pour une conversation eligible.
2. Le draft est recupere par le Client via une route notifications ou polling autopilot.
3. La prop `initialDraft` + `autoOpen` sont passes a `AISuggestionSlideOver`.
4. Le useEffect L213 (PH142-F) detecte `initialDraft?.draftText && autoOpen && conversationId`, set `activeDraft` et `setIsOpen(true)`.
5. Le panneau s'ouvre avec titre "Brouillon IA" (icone Bot) au lieu de "Suggestion IA" (icone Sparkles).

Tenant SWITAA DEV est en `MODE_NOT_AUTOPILOT:suggestion` (vu dans les logs `[Autopilot] ecomlg-001 conv=... MODE_NOT_AUTOPILOT:suggestion`). Aucun draft n'est cree pour SWITAA, donc le flow "Brouillon IA" ne s'active pas et le panneau retombe sur le mode "Suggestion IA" manuel.

---

## 5. Audit API /ai/assist

| Endpoint | Methode | Payload requis | Auth runtime | Effet cout | Verdict |
|---|---|---|---|---|---|
| /ai/assist | POST | tenantId + conversationId + contextType ('conversation','order','playbook') + ... | tenantGuard non actif sur /ai (PROTECTED_PREFIXES = ['/messages'] uniquement post-AS.5) | consomme KBactions par appel | endpoint fonctionnel, l'API ne rejette pas |

L'API n'est PAS le probleme. L'API fonctionne et repond avec une suggestion valable. Aucun patch API n'a ete fait dans cette phase.

---

## 6. Design patch (tente)

Cas A choisi (selon prompt) : restaurer un auto-trigger Client cote `AISuggestionSlideOver.tsx`.

Garde-fous integres :
- `autoTriggeredRef` : 1 auto-generation max par conversationId
- skip si `activeDraft` ou `response` deja present (preserve flow Brouillon IA)
- skip si `isLoading`, `exhausted`, ou KBactions <= 0 (anti-cost-loop)
- debounce 500 ms (absorbe navigation rapide)
- bouton manuel conserve comme fallback

Diff : 1 fichier, 36 insertions, 0 deletions (insertion apres la definition de `generateSuggestion`).

---

## 7. Patch source applique

| Fichier | Changement | Scope | Risque |
|---|---|---|---|
| src/features/ai-ui/AISuggestionSlideOver.tsx | +36 lignes (1 useRef, 2 useEffect) | scope strict slide-over | faible (skips + debounce) |

Aucun autre fichier modifie. Aucun changement API, aucun changement BFF, aucun impact AS.5 messages tenant guard, aucun impact KEY-302 build args.

---

## 8. Checks source

| Repo | Check | Resultat |
|---|---|---|
| keybuzz-client | npx tsc --noEmit | exit 0 |

---

## 9. Commits

| Repo | Commit | Sujet | Push |
|---|---|---|---|
| keybuzz-client | 8d8121f | fix(inbox): restore automatic AI suggestion trigger (KEY-305) | 57766ea..8d8121f sur ph148/onboarding-activation-replay |
| keybuzz-infra | 57c0f33 | deploy(dev): restore Inbox AI auto-suggestion (KEY-305) | f6479a5..57c0f33 sur main |
| keybuzz-infra (rollback) | 46fd43f | rollback(client-dev): AI auto-suggestion useEffect rolled back -- wrong approach (KEY-305) | 57c0f33..46fd43f sur main |

Le commit source 8d8121f reste sur origin pour reference -- aucun revert source executif (le code Client est techniquement correct, c'est juste la mauvaise approche UX). Si Ludovic souhaite revert la source, ce sera l'objet d'une phase suivante.

---

## 10. Build DEV

| Image | Source commit | Tag | Image ID | Digest registry |
|---|---|---|---|---|
| keybuzz-client | 8d8121f | v3.5.181-inbox-ai-auto-suggestion-dev | 31c7fbe4bf23 | sha256:950943cfffe6786a4e3cc6ff496a35db3888c774e8156432f271516abe2073ba |

Build avec KEY-302 build args explicites. Bundle check manuel :
- 0 occurrence PROD URL https://api.keybuzz.io
- 12 occurrences /api/messages/conversations (BFF AS.5 preservee)

L'image reste en cache local Docker bastion + registry, mais n'est pas runtime DEV apres rollback.

---

## 11. GitOps DEV

| Manifest | Image avant | Image apres deploy | Image apres rollback |
|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | v3.5.180-messages-bff-tenant-guard-dev | v3.5.181-inbox-ai-auto-suggestion-dev | v3.5.180-messages-bff-tenant-guard-dev (RESTORE) |
| k8s/keybuzz-api-dev/deployment.yaml | v3.5.169-messages-tenant-guard-dev | v3.5.169-messages-tenant-guard-dev (non touche) | v3.5.169-messages-tenant-guard-dev (INCHANGE) |

3 commits infra : deploy (57c0f33) -> rollback (46fd43f). Tous applique en kubectl apply -f + rollout status OK.

---

## 12. Validation DEV (resultats QA Ludovic)

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| Inbox liste | charge | OK | OK |
| Nouveaux messages | arrivent | OK | OK |
| Auto-trigger sur selection conversation | suggestion auto-generee | OUI (apres ~500ms debounce) | technique OK |
| Comportement UX correspond a l'attendu | "Brouillon IA" avec icone Bot, flow validation draft | NON -- s'affiche "Suggestion IA" avec icone Sparkles, mode manuel slide-over | **WRONG UX** |
| Pas de boucle d'appels | 1 appel par conversation | OK (autoTriggeredRef enforce) | OK |
| KBactions decrementent | 1 fois par conversation | OK | OK |
| Pas de message externe envoye | aucun envoi auto | OK | OK |
| AS.5 protection /messages | 401/403 sans auth | OK (non touche) | OK |
| PROD inchangee | toutes images PROD identiques | OK | OK |

Ludovic a explicitement demande le rollback : "C'est automatique, mais ca se genere a l'ouverture et ce n'est pas le comportement normale, de plus ce n'est plus Brouillon IA, mais Suggestion IA que tu as remis et ce n'est pas bon non plus ! Donc il faut rollback."

---

## 13. Rollback DEV (EXECUTE)

| Surface | Avant rollback | Apres rollback |
|---|---|---|
| Client DEV runtime | v3.5.181-inbox-ai-auto-suggestion-dev | v3.5.180-messages-bff-tenant-guard-dev (RESTORED) |
| Pods | 1/1 Running 8s | 1/1 Running 16s (nouveau pod) |
| API DEV | v3.5.169-messages-tenant-guard-dev | INCHANGE |
| GitOps state | manifest pointe v3.5.181 + commit 57c0f33 | manifest pointe v3.5.180 + commit rollback 46fd43f |

Mecanisme : edit manifest -> commit -> push -> kubectl apply -f -> rollout status. Pas de force, pas de reset. Manifest = runtime = annotation post-rollback.

---

## 14. PROD read-only

| Service PROD | Image | Verdict |
|---|---|---|
| API PROD | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website PROD | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| OW PROD | v3.5.165-escalation-flow-prod | INCHANGE |

Aucune mutation PROD pendant la phase.

---

## 15. Cause racine identifiee a posteriori

Le comportement attendu "Brouillon IA auto" n'a JAMAIS ete fourni par un auto-trigger cote Client. Il est fourni par le **flow autopilot draft serveur** :

1. Le worker autopilot (keybuzz-outbound-worker ou autre) doit etre ACTIF pour le tenant.
2. Le tenant doit etre dans un mode autopilot autonome (non `MODE_NOT_AUTOPILOT:suggestion`).
3. Quand un nouveau message inbound arrive, le worker autopilot evalue + cree un draft en DB.
4. Le Client recupere le draft (via un mecanisme a auditer -- probable polling notifications ou query autopilot/history).
5. Le draft est passe en `initialDraft` + `autoOpen=true` a AISuggestionSlideOver.
6. PH142-F useEffect (deja present) detecte et ouvre le panneau avec titre "Brouillon IA" et flow validation/refus.

Le bon fix doit donc :
- soit reactiver le mode autopilot pour le tenant SWITAA DEV
- soit reparer la chaine worker -> DB -> Client recuperation draft si elle est cassee
- soit re-implementer le flow draft autopilot independamment du worker

Hors scope de cette phase de bugfix UI.

---

## 16. Gaps restants

1. **AI auto-suggestion (KEY-305)** reste non fonctionnelle en DEV. Le rollback restaure l'etat AS.5 (bouton manuel uniquement). Le vrai fix est cote autopilot draft worker.
2. **AS.5 protection /messages** reste OK et inchangee.
3. **KEY-301 + KEY-304 restent OPEN** pour les autres surfaces (/notifications, /ai, /channels, /suppliers, /tenants).
4. **AS.1 PROD reste BLOQUE** jusqu'a AS.6 (/notifications).
5. **Commit source 8d8121f** reste sur origin et pourra etre revert lors d'une phase dediee si Ludovic le souhaite.
6. **Image v3.5.181-inbox-ai-auto-suggestion-dev** reste dans le registry mais hors runtime. Peut etre purgee plus tard.

---

## 17. Plan rollback documente

Le rollback runtime a deja ete execute. Rollback supplementaire possible :

Si Ludovic souhaite aussi annuler le commit source 8d8121f :

```
cd /opt/keybuzz/keybuzz-client
git revert --no-edit 8d8121f
git push origin ph148/onboarding-activation-replay
```

Non execute dans cette phase. A faire sur GO explicite.

---

## 18. Textes Linear -- NON POSTES

### Texte KEY-305 (a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5.1 -- Inbox AI auto-suggestion fix tente, ROLLBACK
EXECUTE en DEV.

APPROCHE TENTEE
useEffect auto-trigger dans AISuggestionSlideOver.tsx avec garde-fous :
autoTriggeredRef (1 trigger par conv), skip si activeDraft / response /
isLoading / exhausted / KBactions=0, debounce 500ms, bouton manuel
conserve en fallback.

PROBLEME UX IDENTIFIE
Le useEffect declenche bien l'auto-generation, mais le panneau s'affiche
toujours avec le titre "Suggestion IA" (mode manuel slide-over, icone
Sparkles). Le comportement attendu est "Brouillon IA" (icone Bot, flow
validation draft) qui n'est fourni QUE par le flow autopilot draft
serveur (PH142-F initialDraft + autoOpen). Sur le tenant SWITAA DEV
configure en MODE_NOT_AUTOPILOT:suggestion, aucun draft n'est cree par
le worker, donc le flow "Brouillon IA" ne s'active jamais.

ROLLBACK
Client DEV revenu sur v3.5.180-messages-bff-tenant-guard-dev. API DEV
inchangee v3.5.169-messages-tenant-guard-dev. PROD strictement
inchangee. AS.5 protection /messages preserve.

PROCHAINES ETAPES POSSIBLES
1. Reactiver / verifier le mode autopilot sur le tenant test (changer
   le mode tenant_settings ou similaire pour permettre la creation
   automatique de draft par le worker).
2. Auditer la chaine worker -> DB -> Client recuperation draft pour
   verifier qu'elle n'est pas cassee.
3. Si autopilot ne doit pas etre la solution, re-implementer un flux
   draft dedie cote backend qui cree un draft DB sur conversation
   eligible meme sans autopilot autonome.

Hors scope de cette phase bugfix UI.

Source : keybuzz-client commit 8d8121f reste sur origin (pas revert).
Image v3.5.181-inbox-ai-auto-suggestion-dev reste dans registry mais
hors runtime. Phase 5.2 a designer pour le vrai fix.
```

### Texte KEY-304 (info update, a coller sur GO Ludovic)

```
PH-SAAS-T8.12AS.5.1 (sous-phase KEY-305) tente puis rollback en DEV.
AS.5 protection /messages/conversations reste OK (API DEV
v3.5.169-messages-tenant-guard-dev inchangee). Client DEV revenu sur
v3.5.180. PROD strictement inchangee. KEY-304 reste OPEN. Sequence
AS.6 (/notifications) -> AS.7 (/ai) -> AS.8 (/channels, /suppliers)
-> AS.9 (/tenants) inchangee.
```

---

## 19. Phrase cible finale

L'approche useEffect cote `AISuggestionSlideOver.tsx` declenche techniquement une auto-generation IA mais affiche le panneau avec le titre "Suggestion IA" (mode manuel slide-over avec icone Sparkles) au lieu du "Brouillon IA" (icone Bot, flow validation draft autopilot) attendu par Ludovic ; le vrai flow "Brouillon IA" est fourni par le worker autopilot serveur qui doit creer un draft DB et le pousser au Client via initialDraft + autoOpen (PH142-F) -- cette chaine n'est pas active pour le tenant SWITAA DEV en mode `MODE_NOT_AUTOPILOT:suggestion` ; rollback DEV execute, Client DEV revenu sur `v3.5.180-messages-bff-tenant-guard-dev`, API DEV `v3.5.169-messages-tenant-guard-dev` inchangee, PROD strictement inchangee, AS.5 protection /messages preserve ; commit source 8d8121f reste sur origin pour reference et image v3.5.181 reste dans le registry hors runtime ; KEY-305 OPEN, prochaine phase doit cibler le flow autopilot draft serveur plutot qu'un useEffect cote slide-over.

STOP -- rollback livre, en attente nouvelles instructions Ludovic pour design correct du flux Brouillon IA.
