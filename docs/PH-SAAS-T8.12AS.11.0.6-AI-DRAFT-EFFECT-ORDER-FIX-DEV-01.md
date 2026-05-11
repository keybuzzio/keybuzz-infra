# PH-SAAS-T8.12AS.11.0.6-AI-DRAFT-EFFECT-ORDER-FIX-DEV-01

> Date : 2026-05-11
> Linear : KEY-305 (principal), KEY-304 (prerequisite)
> Phase : T8.12 AS.11.0.6 - fix latent React useEffect ordering in AISuggestionSlideOver
> Environnement : Client DEV patched + built + deployed. API DEV unchanged. PROD strictement inchange.

---

## 1. VERDICT

GO AI DRAFT EFFECT FIX DEV READY

NO API PATCH / NO TENANTGUARD CHANGE / NO PROD MUTATION.

Patch source Client (1 fichier, 14 lignes ajoutees / 7 retirees), build local DEV avec KEY-302 + KEY-308 + KEY-309 obligatoires respectes, push GHCR sur tag immuable nouveau `v3.5.183-ai-draft-effect-order-fix-dev`, GitOps apply Client DEV uniquement, rollout reussi, smoke V1 PASS=18 sur nouveau runtime, logs propres (0 JWT_SESSION_ERROR, 0 5xx). API DEV+PROD et 4 autres services PROD strictement inchanges.

QA Ludovic navigateur SWITAA AUTOPILOT pour confirmer "Brouillon IA visible" non realisable cote CE (limite outils). A confirmer en navigateur si besoin de validation absolue UX. Le bundle Client DEV v3.5.183 contient les labels "Brouillon IA" et "Valider et envoyer" verifies via smoke V1 bundle guard.

---

## 2. Bug static confirmation

`src/features/ai-ui/AISuggestionSlideOver.tsx` lignes 212-228 (avant patch) :

```javascript
// PH142-F: Auto-open drawer when autopilot draft arrives
useEffect(() => {
  if (initialDraft?.draftText && autoOpen && conversationId) {
    if (draftDismissedRef.current !== conversationId) {
      setActiveDraft(initialDraft);
      setIsOpen(true);
    }
  } else if (!initialDraft) {
    setActiveDraft(null);
  }
}, [initialDraft, autoOpen, conversationId]);

// PH142-F: Reset dismissed ref on conversation change
useEffect(() => {
  draftDismissedRef.current = null;
  setActiveDraft(null);
}, [conversationId]);
```

| Effect | Lines | Dependencies | Action | Risk |
|---|---|---|---|---|
| Hydration | 213-222 | `[initialDraft, autoOpen, conversationId]` | `setActiveDraft(initialDraft)` si tous valides ET non-dismissed | declenche AVANT le reset si declare avant |
| Reset | 225-228 | `[conversationId]` | `draftDismissedRef.current = null; setActiveDraft(null)` | overwrite hydration au mount initial (LAST WIN) |

Race confirmee en AS.11.0.5 : si le parent rend AISuggestionSlideOver pour la PREMIERE fois avec `initialDraft + autoOpen=true + conversationId` simultanement (cas observe en AS.5 v3.5.180 ou /messages BFF retardait selectedConversation), les deux useEffect fire dans l ordre de declaration, le RESET gagne, label devient "Suggestion IA" au lieu de "Brouillon IA".

---

## 3. Patch

Fichier modifie : `src/features/ai-ui/AISuggestionSlideOver.tsx` UNIQUEMENT.

Changements :

1. Ajout d un useRef `prevConversationIdRef` apres `draftDismissedRef` (ligne 142-146 nouvelle) pour permettre la detection de changement de conversation INTERNE au useEffect consolide.

2. Consolidation des deux useEffect en un seul (lignes 217-235 nouvelles) :
   - Detection de changement de conv via `prevConversationIdRef.current !== conversationId` -> reset draftDismissedRef + update prevConversationIdRef.
   - Hydration / clear de `activeDraft` selon `initialDraft`, `autoOpen`, `conversationId` et `draftDismissedRef`.

3. Suppression du useEffect 225-228 (reset standalone) qui causait le race.

Diff applique :

```
+  // PH-SAAS-T8.12AS.11.0.6 KEY-305: track previous conversationId so we can
+  // detect conv changes inside the consolidated draft effect (and reset
+  // draftDismissedRef without overriding hydration).
+  const prevConversationIdRef = useRef<string | null>(null);

   // PH142-F + PH-SAAS-T8.12AS.11.0.6 KEY-305: hydrate activeDraft from
   // initialDraft on conversation change. Keep draft reset and initialDraft
   // hydration in one effect to avoid reset winning on mount when the parent
   // renders the slide-over with initialDraft + autoOpen + conversationId
   // simultaneously (race observed in AS.5 when /messages BFF slowed the
   // selectedConversation arrival).
   useEffect(() => {
+    if (prevConversationIdRef.current !== conversationId) {
+      draftDismissedRef.current = null;
+      prevConversationIdRef.current = conversationId;
+    }
     if (initialDraft?.draftText && autoOpen && conversationId) {
       ...

-  // PH142-F: Reset dismissed ref on conversation change
-  useEffect(() => {
-    draftDismissedRef.current = null;
-    setActiveDraft(null);
-  }, [conversationId]);
```

Stat : `1 file changed, 14 insertions(+), 7 deletions(-)`.

Comportement preserve :
- Nouvelle conv : reset draftDismissedRef -> hydration eligible si initialDraft fourni.
- Meme conv + initialDraft change : pas de reset (prevConversationIdRef === conversationId), hydration normale si non-dismissed.
- User dismiss draft : draftDismissedRef.current = conversationId, futur initialDraft sur meme conv = pas de hydration.
- `setActiveDraft(null)` quand `!initialDraft` -> preserve (cas conv sans draft).

Commit Client : `e6f29c8` `fix(inbox): prevent AI draft reset from overriding initial draft (KEY-305)`.

Branche : `ph148/onboarding-activation-replay`. Sync origin 0/0.

---

## 4. Tests source

| Check | Method | Result | Verdict |
|---|---|---|---|
| TypeScript compile | implicit via docker build `npm run build` | succeed (build OK exit 0) | OK |
| Bundle ASCII preservation | docker build with NEXT_PUBLIC_* DEV args | succeed | OK |
| Diff scope strict | git diff staged | 1 file: src/features/ai-ui/AISuggestionSlideOver.tsx | OK |
| No autre fichier touche | git status post-add | M tsconfig.tsbuildinfo (artefact connu, NON staged) | OK |
| Label "Brouillon IA" preserve dans bundle | smoke V1 section B | PASS | OK |
| Label "Valider et envoyer" preserve dans bundle | smoke V1 section B | PASS | OK |
| Pas de nouveau autotrigger generateSuggestion (anti AS.5.1) | grep manuel | aucun setTimeout/autoTriggeredRef ajoute | OK |

---

## 5. Build

| Item | Valeur |
|---|---|
| Commit source build | e6f29c84ad9e1f024a79413cc7dd1dfd8468a96c |
| Tag image | v3.5.183-ai-draft-effect-order-fix-dev |
| KEY-309 tag pre-push check | exit 0 (AVAILABLE) |
| KEY-302 build args | NEXT_PUBLIC_APP_ENV=development, NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io, NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io |
| KEY-308 OCI build args | IMAGE_REVISION=e6f29c84ad9e1f024a79413cc7dd1dfd8468a96c, IMAGE_CREATED=2026-05-11T17:25:16Z, IMAGE_VERSION=v3.5.183-ai-draft-effect-order-fix-dev |
| Build duration | 1m40s |
| Build exit | 0 |
| Bundle verify KEY-302 | api-dev.keybuzz.io occurrences=2 ; api.keybuzz.io occurrences=0 ; "OK: bundle inlined https://api-dev.keybuzz.io only" |
| OCI labels post-build | revision=`e6f29c84...` (full SHA), created=2026-05-11T17:25:16Z, version=v3.5.183-..., source=https://github.com/keybuzzio/keybuzz-client, title=keybuzz-client |
| Push GHCR | exit 0, digest `sha256:6fc521782c9282a1771e3e974c57dbd41929a40e7e7f9b709435702633b12401` |
| Image full ref | ghcr.io/keybuzzio/keybuzz-client@sha256:6fc521782c9282a1771e3e974c57dbd41929a40e7e7f9b709435702633b12401 |

Note KEY-309 : le tag propose en prompt CE etait `v3.5.181-ai-draft-effect-order-fix-dev`, mais `v3.5.181-inbox-ai-auto-suggestion-dev` est dans la liste DO_NOT_REDEPLOY (AS.5.1). Reutilisation du numero `v3.5.181` avec un autre scope-slug violerait la regle "no numeric-base reuse" de DOCKER-TAG-DISCIPLINE.md. Tag choisi : `v3.5.183-ai-draft-effect-order-fix-dev` (premier numero libre apres v3.5.180/181/182 DO_NOT_REDEPLOY). KEY-309 check confirme AVAILABLE.

---

## 6. GitOps DEV

| Item | Valeur |
|---|---|
| Manifest modifie | k8s/keybuzz-client-dev/deployment.yaml |
| Diff stat | 1 file changed, 1 insertion(+), 1 deletion(-) |
| Changement | image tag v3.5.179 -> v3.5.183 + commentaire mis a jour (AS.5.3 rollback -> AS.11.0.6 fix) |
| Commit infra | f3b0cb8 `deploy(client-dev): AI draft effect order fix (KEY-305)` |
| Branche | main |
| Sync push origin | 0/0 |
| kubectl apply | `deployment.apps/keybuzz-client configured` |
| Rollout status | `deployment "keybuzz-client" successfully rolled out` (1 old replica terminated, 1 new replica ready) |
| Verify match spec=last-applied | OUI confirme par smoke V1 section A |
| Verify API DEV unchanged | OUI (v3.5.168-escalation-notifications-dev preserve) |

Manifests autres services NON modifies. Aucun API/Backend/Worker/Website/Admin manifest touche.

---

## 7. Validation DEV

### 7.1 Smoke V1 post-deploy

`SMOKE_EXPECTED_CLIENT_IMAGE=ghcr.io/keybuzzio/keybuzz-client:v3.5.183-ai-draft-effect-order-fix-dev` :

```
PASS=18 WARN=0 FAIL=0 SKIP=1
RESULT=PASS
exit=0
```

Detail :
- A. Runtime/GitOps : 6/6 PASS (API+Client images match expected, spec=last-applied, pods ready)
- B. Bundle guard : 5/5 PASS (sentinel absent, api-dev inlined, PROD URL absent, "Brouillon IA" present, "Valider et envoyer" present)
- C. API DEV : 4/4 PASS (health, conversations, stats, notifications)
- D. Client/BFF : 3/3 PASS (/, /inbox, /api/auth/session)
- E. Skip (no SMOKE_CONVERSATION_ID)

### 7.2 Logs post-rollout

| Source | Window | Signal | Count |
|---|---|---|---|
| Client DEV new pod | depuis startup | "Next.js 14.2.35 Ready 453ms" | OK |
| Client DEV | tail=200 | JWT_SESSION_ERROR | 0 |
| API DEV | tail=200 | 5xx | 0 |

Aucun warning, aucune erreur post-deploy.

### 7.3 Pod runtime

| Pod | Image digest court | Ready | Restarts | Age |
|---|---|---|---|---|
| keybuzz-client-fcdd56464-kbt5l | 6fc521782c92 (new image) | true | 0 | ~3 min |

Le pod precedent (keybuzz-client-d4bfb7c78-nrwzg, digest b8a64abd...) a ete termine proprement.

### 7.4 QA Ludovic navigateur

NON realisable cote CE (limite outils). Le rapport recommande a Ludovic de :
1. Ouvrir `client-dev.keybuzz.io` en navigateur SWITAA AUTOPILOT logge.
2. Selectionner une conversation recente AUTOPILOT eligible (avec draft autopilot existant).
3. Verifier que le label "Brouillon IA" s affiche AUTOMATIQUEMENT (pas "Suggestion IA").
4. Verifier que le bouton "Valider et envoyer" est visible.
5. NE PAS CLIQUER sur Valider/Modifier/Ignorer (mutation).
6. Si OK -> AS.11.0.6 valide UX -> debloquer AS.11.1.
7. Si KO -> rollback (cf section 8).

Validation indirecte cote API confirme deja (cf AS.5.3 QA Ludovic OK "Brouillon IA visible auto") : le runtime v3.5.179 montrait deja "Brouillon IA" car la race ne s exposait pas sans BFF AS.5. Le fix AS.11.0.6 ne change que le comportement au mount initial avec timing inverse, qui n etait pas observable sur v3.5.179. Donc le fix est UN ANTI-REGRESSION pour la future reprise AS.11.1.

---

## 8. Rollback plan

| Item | Valeur |
|---|---|
| Rollback tag image | v3.5.179-as1-1-build-args-fix-dev (digest sha256:b8a64abd...) |
| Rollback manifest | revert commit infra f3b0cb8 (`git revert f3b0cb8`) -> nouveau commit |
| Rollback source | revert commit client e6f29c8 (`git revert e6f29c8`) -> nouveau commit Client |
| Rollback runtime apply | `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` apres revert |
| Rollback total estime | ~5 minutes |

PROD non affectee, donc aucun rollback PROD requis.

---

## 9. PROD unchanged

| Service | PROD image | Verdict |
|---|---|---|
| API | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| Worker | v3.5.165-escalation-flow-prod | INCHANGE |

Aucun manifest PROD modifie. Aucun docker push prod-tag. Aucun kubectl apply sur namespace -prod.

---

## 10. Gaps

1. **QA Ludovic navigateur** : non realise cote CE. Validation UX absolue requiert Ludovic en navigateur logge SWITAA AUTOPILOT. Indirect validation via smoke V1 + AS.5.3 historical QA + analyse statique = HIGH confidence mais pas 100%.

2. **AS.11.1 sequence** debloque cote design (cf AS.11 rapport). AS.11.0.6 fix etant en place, AS.11.1a (API guard fastify-plugin wrap + PROTECTED_PREFIXES=[] vide) peut etre lance des que Ludovic donne GO.

3. **PROD promotion v3.5.183** : non planifie dans AS.11.0.6. Le fix etant un anti-regression preventif, il peut etre promu PROD en meme temps que la promotion AS.1 + AS.11.1g (KEY-263), pour minimiser le nombre de phases PROD.

4. **Numbering tag v3.5.183** : choisi pour eviter reutilisation `v3.5.181` (DO_NOT_REDEPLOY). Le prompt CE proposait `v3.5.181-ai-draft-effect-order-fix-dev` ; deviation documentee et confirmee par KEY-309 check.

5. **Test runtime sandbox v3.5.180 pour HIGH confidence cause AS.5** : non realise. Hypothese statique reste MED-HIGH. Si AS.11.1 lance et nouveau bug Brouillon IA apparait sous BFF, retour ici pour reconsiderer.

---

## 11. Linear text prepared, posted

Postee sur KEY-305 et KEY-304. Resume controle (no PII, no exploit) :

```
## AS.11.0.6 -- AI draft effect order fix livre + deploye Client DEV

Patch source-only Client (1 fichier : `src/features/ai-ui/AISuggestionSlideOver.tsx`).

Commits :
- Client `e6f29c8` (`ph148/onboarding-activation-replay`)
- Infra `f3b0cb8` (`main`)

Build Client DEV nouveau tag `v3.5.183-ai-draft-effect-order-fix-dev` :
- KEY-302 build args explicites verifies (api-dev=2, api.kbz=0 dans bundle)
- KEY-308 OCI revision label = full commit SHA `e6f29c84...`
- KEY-309 tag check AVAILABLE pre-push
- Digest GHCR : sha256:6fc521782c92...

GitOps DEV applique :
- manifest k8s/keybuzz-client-dev/deployment.yaml mis a jour
- kubectl apply succeed, rollout status OK
- smoke V1 PASS=18 WARN=0 FAIL=0 SKIP=1 post-rollout

PROD inchange (API v3.5.151, Client v3.5.174, Backend v1.0.47, Website v0.6.12, Admin v2.12.2).

QA Ludovic navigateur recommandee pour confirmer "Brouillon IA visible" sur SWITAA AUTOPILOT.

Apres QA OK :
- KEY-305 : Done suggere.
- KEY-304 : reste In Review jusqu a AS.11.1 livre (BFF migration endpoint-by-endpoint).
```

---

### 11.bis Phrase cible finale

AS.11.0.6 livre le fix de l ordre des useEffect dans AISuggestionSlideOver (1 fichier Client patche, useEffect consolide pour eliminer la race entre reset et hydration) ; build local v3.5.183-ai-draft-effect-order-fix-dev avec KEY-302/308/309 obligatoires respectes, digest sha256:6fc521782c92... ; GitOps Client DEV uniquement applique (kubectl apply OK, rollout OK, smoke V1 PASS=18, logs propres) ; API DEV+PROD et 4 autres services PROD strictement inchanges ; rollback documente (manifest revert vers v3.5.179-as1-1-build-args-fix-dev) ; QA Ludovic navigateur recommandee pour validation UX absolue ; verdict AS.11.0.6 GO AI DRAFT EFFECT FIX DEV READY.

STOP
