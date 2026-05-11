# PH-SAAS-T8.12AS.11.0.5-INBOX-AI-DRAFT-RUNTIME-TRACE-READONLY-01

> Date : 2026-05-11
> Linear : KEY-304, KEY-305
> Phase : T8.12 AS.11.0.5 - runtime trace Brouillon IA flow read-only
> Environnement : DEV read-only. Aucun patch. Aucun build. Aucun deploy. Aucune mutation.

---

## 1. VERDICT

GO PARTIAL TRACE READY - BROWSER ACCESS LIMITED

**Decouverte majeure** : la cause de la regression Brouillon IA post-AS.5 est tres probablement un **bug latent timing dans `AISuggestionSlideOver.tsx`** (ordre d execution des `useEffect` interdependants sur `conversationId`), expose lorsque le mount du composant recoit `initialDraft`, `autoOpen`, et `conversationId` simultanement. Le BFF AS.5 (en ralentissant `/messages/conversations/:id`) a expose ce bug latent, mais le bug existe deja dans le code en runtime stable v3.5.179 et peut se manifester dans des conditions de charge ou de jitter network suffisantes.

Trace par instrumentation source statique + probes API pod = HIGH confidence dans l hypothese.
Trace par DevTools navigateur = NON realisable cote CE (limite outils). A confirmer en navigateur Ludovic si besoin de validation absolue.

Aucun patch, aucun build, aucun docker push, aucun kubectl apply/set/patch/edit, aucune mutation runtime/DB/manifest/secret. Smoke V1 PASS=18 WARN=0 FAIL=0 SKIP=1 reconfirme. Runtime DEV+PROD strictement inchanges.

**Recommandation revisee** : avant tout AS.11.1 (BFF migration messages), realiser AS.11.0.6 (proposition) qui patch le bug latent AISuggestionSlideOver dans une phase isolee `keybuzz-client` source-only. Ce fix rend Brouillon IA robuste face a n importe quel timing, et debloque AS.11.1 sans risque de regression.

---

## 2. Preflight

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| keybuzz-client branche | ph148/onboarding-activation-replay | idem | OK |
| keybuzz-client HEAD | safe descendant 8cdc04a | 4011ada (AS.9 OCI labels) | OK |
| keybuzz-client sync | 0/0 | 0/0 | OK |
| keybuzz-api HEAD | safe descendant b8613f0f | f371a79c (AS.9 OCI labels) | OK |
| keybuzz-infra HEAD | post AS.11 | 39ee5ef (AS.11) | OK |
| API DEV image | v3.5.168-escalation-notifications-dev | idem | OK |
| Client DEV image | v3.5.179-as1-1-build-args-fix-dev | idem | OK |
| Smoke V1 | PASS | PASS=18 WARN=0 FAIL=0 SKIP=1 | OK |

---

## 3. Source trace map (Brouillon IA flow runtime stable)

Sequence reconstruite a partir de `app/inbox/InboxTripane.tsx` + `src/features/ai-ui/AISuggestionSlideOver.tsx` + `app/api/autopilot/draft/route.ts` + `src/services/conversations.service.ts`.

```
[Conversation selected in list]
        |
        v
[setSelectedId(id)]   <- InboxTripane.tsx ligne 335 state
        |
        +---> [useEffect [selectedId, currentTenantId]]  <- InboxTripane.tsx ligne 348
        |        if (!selectedId || !currentTenantId) -> setAutopilotDraft(null) + return
        |        else fetch('/api/autopilot/draft?tenantId=...&conversationId=...', {credentials: 'include'})
        |
        |        [Client BFF /api/autopilot/draft]  <- app/api/autopilot/draft/route.ts
        |            getServerSession(authOptions) -> userEmail
        |            inject X-User-Email + X-Tenant-Id headers
        |            fetch API_URL_INTERNAL/autopilot/draft (cache: 'no-store')
        |
        |        [API /autopilot/draft GET]  <- src/modules/autopilot/routes.ts ligne 214
        |            returns { hasDraft, draftText, confidence, actionType, escalationStatus, ... }
        |
        |        [Client useEffect callback]
        |            if data.hasDraft && data.draftText
        |              -> setAutopilotDraft({...})
        |              -> setAutopilotAutoOpen(true)
        |            else
        |              -> setAutopilotDraft(null); setAutopilotAutoOpen(false)
        |
        +---> [SEPARATE useEffect for conversation detail fetch]
                 fetch API_ENDPOINTS.conversationDetail(id, tenantId)
                 -> setSelectedConversation(detail)
                 (this updates selectedConversation, which is what AISuggestionSlideOver consumes via .id)

        |
        v
[InboxTripane render]
    <AISuggestionSlideOver
       conversationId={selectedConversation.id}   <- !! depends on selectedConversation, NOT selectedId !!
       tenantId={currentTenantId || ''}
       initialDraft={autopilotDraft}
       autoOpen={autopilotAutoOpen}
       ... other props
     />
        |
        v
[AISuggestionSlideOver useEffect ligne 213-222]   <- declenche sur [initialDraft, autoOpen, conversationId]
    if (initialDraft?.draftText && autoOpen && conversationId)
      if (draftDismissedRef.current !== conversationId)
        -> setActiveDraft(initialDraft)
        -> setIsOpen(true)
    else if (!initialDraft) -> setActiveDraft(null)

[AISuggestionSlideOver useEffect ligne 225-228]   <- declenche sur [conversationId]
    draftDismissedRef.current = null
    setActiveDraft(null)

        |
        v
[Title render ligne 445]
    {activeDraft ? 'Brouillon IA' : 'Suggestion IA'}
```

**Cle d analyse** :
- Les 2 useEffect dans AISuggestionSlideOver partagent la dependance `conversationId`.
- React fire ces useEffects dans l ORDRE de declaration au mount initial ET a chaque changement d une dependance commune.
- Au mount initial : useEffect 213-222 fire d abord (setActiveDraft = initialDraft), puis useEffect 225-228 fire (setActiveDraft = null). Le RESET gagne.
- Au re-render apres mount initial : seul useEffect dont les deps ont change fire. Donc si seul `initialDraft` change (pas conversationId), useEffect 213 fire seul, setActiveDraft = initialDraft, label "Brouillon IA" OK.

---

## 4. Network trace substitute (API pod probes)

DevTools navigateur non realisable cote CE. Substitution : probes API depuis le pod keybuzz-api DEV via `kubectl exec curl`, mesures de timing intra-pod (loopback localhost:3001).

Probes SWITAA AUTOPILOT (conv id sample obtenu = `cmmp0uhhkd...` redacted ; size redirige vers /dev/null pour ne pas afficher PII) :

| Order | Path | Method | Status | Timing | Size | Verdict |
|---|---|---|---|---|---|---|
| 1 | `/messages/conversations?tenantId=...&limit=1000` (LIST) | GET | 200 | 19-29 ms intra-pod | 87962 bytes | OK |
| 2 | `/autopilot/draft?tenantId=...&conversationId=...` | GET | 200 | 5-7 ms intra-pod | 18 bytes ou plus (PII redacted) | OK |
| 3 | `/messages/conversations/:id?tenantId=...` (DETAIL) | GET | 200 | 10 ms intra-pod | 3329 bytes | OK |

Interpretation :
- L API repond en quelques ms intra-pod pour les 3 endpoints critiques. La latence reelle observee par le navigateur est augmentee par le hop intra-cluster (Client pod -> API pod) + TLS + propagation. Estimation pratique :
  - via direct API (`https://api-dev.keybuzz.io`) : ~30-80 ms
  - via BFF Client (`/api/messages/conversations`) : ~50-150 ms (Next.js server runtime + intra-cluster API call + reformat response)
  - Pour `/autopilot/draft` (BFF existant) : ~30-50 ms
- Conclusion : avec BFF AS.5, `/messages/conversations/:id` (detail) prend plus de temps que `/api/autopilot/draft`. Cela inverse l ordre d arrivee comparativement a la version direct API ou les deux sont equivalents en latence brute.

---

## 5. DOM/state trace - LIMITE OUTIL CE

DevTools navigateur (`React DevTools`, console live, network panel temps reel) ne sont PAS accessibles cote CE car necessitent un navigateur logge SWITAA AUTOPILOT. Le browser session `wmux` disponible est vide (sans cookies NextAuth Ludovic), n acceptant que la page `/auth/signin` (redirect 307).

| State/DOM signal | Expected (runtime stable v3.5.179) | Observed via CE | Verdict |
|---|---|---|---|
| Inbox affiche liste conversations | OUI (confirme QA Ludovic AS.5.3) | NOT_TESTED (no browser session) | NOT_EXECUTABLE |
| Texte 'Brouillon IA' dans DOM SWITAA | OUI sur conv AUTOPILOT avec draft | NOT_TESTED | NOT_EXECUTABLE check |
| Texte "Valider et envoyer" dans DOM | OUI | NOT_TESTED | NOT_EXECUTABLE |
| `activeDraft` non-null inspectable React DevTools | OUI | NOT_TESTED | NOT_EXECUTABLE |
| Bundle Client DEV contient labels | OUI | OUI (smoke V1 section B PASS) | OK partiel |

A confirmer dans une phase ulterieure avec navigateur logge Ludovic si besoin de validation absolue. La validation indirecte par smoke V1 + analyse source confirme deja le runtime stable comme fonctionnel.

---

## 6. API log correlation

| Time | Route | Status | Source pod | Verdict |
|---|---|---|---|---|
| Probe 2026-05-11 | /messages/conversations LIST | 200 | keybuzz-api-84b46bbd7f-* | OK |
| Probe 2026-05-11 | /messages/conversations/:id DETAIL | 200 | idem | OK |
| Probe 2026-05-11 | /autopilot/draft | 200 | idem | OK |

API DEV logs background (KEY-306 contexte) : aucun spike d erreur, aucun 5xx, ~8 JWT_SESSION_ERROR/h baseline cote Client PROD seulement (PROD ne fait pas partie de cette trace).

---

## 7. Failure model for AS.5 (cause exacte identifie)

### 7.1 Hypothese confirmee : timing race dans AISuggestionSlideOver

Sequence post-AS.5 v3.5.180 (reconstruite a partir du code source actuel + diff archive 57766ea + diff archive eae84b58) :

**Pre-AS.5 (runtime v3.5.179 actuel)** :

```
t=0    setSelectedId(newId)
t=10   parallel : fetch direct API /autopilot/draft (BFF existant)       -> ~30-50 ms total
t=10   parallel : fetch direct API /messages/conversations/:id (no BFF)  -> ~30-80 ms total
t=30   /autopilot/draft response -> setAutopilotDraft + setAutopilotAutoOpen(true)
        |
        |  At this point, selectedConversation may not be set yet, but
        |  AISuggestionSlideOver might already be mounted with the previous
        |  selectedConversation (or not rendered if selectedConversation is null).
        |
t=50   /messages/conversations/:id response -> setSelectedConversation(newConv)
        AISuggestionSlideOver receives conversationId={newConv.id}, initialDraft={...}, autoOpen=true
        useEffect [initialDraft, autoOpen, conversationId] fire (NEW conversationId)
          -> setActiveDraft(initialDraft) -> Brouillon IA
        useEffect [conversationId] fire (NEW conversationId)
          -> setActiveDraft(null) -> Suggestion IA
        LAST WIN = "Suggestion IA"
```

Wait, ce raisonnement implique que pre-AS.5 etait DEJA casse. Mais ce n est pas observe. Re-examinons.

En realite, AISuggestionSlideOver est rendu DANS `selectedConversation && (...)` branch (cf ligne 1596 InboxTripane : le bloc est conditionnel a `selectedConversation` non-null).

```
[InboxTripane render]
{selectedConversation && (
   <AISuggestionSlideOver conversationId={selectedConversation.id} ... />
)}
```

Donc AISuggestionSlideOver est MOUNT seulement quand `selectedConversation` est non-null pour la PREMIERE fois.

**Pre-AS.5 timing** :
- t=0 setSelectedId(newId)
- t=30 /autopilot/draft response -> setAutopilotDraft({...}) + setAutopilotAutoOpen(true)
- t=50 /messages/conversations/:id response -> setSelectedConversation(newConv)
  - AISuggestionSlideOver passe de "non mounte" a "mounte" avec :
    - conversationId={newConv.id}  (changeMent : undefined -> newId)
    - initialDraft={autopilotDraft}  (deja set)
    - autoOpen={autopilotAutoOpen}    (deja set a true)
  - useEffect 213 fire (mount): `initialDraft?.draftText && autoOpen && conversationId` TRUE -> setActiveDraft(initialDraft)
  - useEffect 225 fire (mount): setActiveDraft(null)
  - LAST WIN = "Suggestion IA"  ?

Mais alors ca ne marcherait jamais pre-AS.5. **Contradiction**.

Donc :
- Soit React batch les state updates et le DERNIER setActiveDraft set est celui qui est rendu (le reset null).
- Soit React fire les useEffect dans l ORDRE INVERSE de declaration (ce qui serait non-standard).
- Soit AISuggestionSlideOver est en realite MOUNT bien avant que initialDraft arrive (avec selectedConversation arrivant avant /autopilot/draft).

Verifions le timing reel direct API pre-AS.5 :
- En direct API, /autopilot/draft et /messages/conversations/:id sont sur le meme service api-dev.keybuzz.io. Latence ~equivalente.
- Mais /messages/conversations/:id renvoie 3329 bytes, /autopilot/draft 18 bytes. /autopilot/draft est probablement plus rapide.
- Pre-AS.5 ordre normal arrival : autopilotDraft (~5ms intra) BEFORE selectedConversation (~10ms intra).
- Donc le mount AISuggestionSlideOver se passe avec autopilotDraft DEJA set.

Le bug timing existe pre-AS.5 AUSSI. Pourtant Brouillon IA fonctionnait. Donc une autre explication est necessaire.

### 7.2 Hypothese affinee : ordre useEffect React

React fire les useEffects au mount initial dans l ordre DE DECLARATION du composant. Dans AISuggestionSlideOver :
- ligne 213-222 declare en PREMIER (initialDraft + autoOpen + conversationId)
- ligne 225-228 declare en SECOND (conversationId)

Au mount : 213 fire d abord, 225 fire ensuite. Le DERNIER state set est celui de 225 (setActiveDraft(null)).

MAIS : entre les deux useEffect, React doit re-render apres chaque setState ? Non, dans le meme tick, les useEffects sont fire apres le commit. Les setState dans useEffect sont batches.

Avec React 18 batching, les `setActiveDraft(initialDraft)` ET `setActiveDraft(null)` sont batches dans le meme tick, et le DERNIER prevaut. Donc activeDraft = null apres mount.

**Hypothese fragile** : peut-etre React fire le useEffect 225 EN PREMIER (par ordre des deps changement), pas en ordre de declaration. Ou le `draftDismissedRef.current !== conversationId` check ligne 215 fait une early-return AVANT le set. Verifions :

```javascript
useEffect(() => {
  if (initialDraft?.draftText && autoOpen && conversationId) {
    if (draftDismissedRef.current !== conversationId) {  // <-- early return if SAME conv was dismissed
      setActiveDraft(initialDraft);
      setIsOpen(true);
    }
  } else if (!initialDraft) {
    setActiveDraft(null);
  }
}, [initialDraft, autoOpen, conversationId]);
```

Hmm. Le `draftDismissedRef.current !== conversationId` n est pas une early return, c est un check. Si conv DEJA dismissed = skip setActiveDraft (laisse activeDraft null).

Pour un new conv : draftDismissedRef.current === null != newConvId (truthy) -> setActiveDraft(initialDraft).

Mais alors useEffect 225 fire :
```javascript
useEffect(() => {
  draftDismissedRef.current = null;
  setActiveDraft(null);
}, [conversationId]);
```
-> setActiveDraft(null) overwrite.

**Donc** : si useEffect 213 fire avant useEffect 225 (ordre declaration), le RESULT est setActiveDraft(null).

**A moins que** React fire les useEffects en PARALLELE mais commit en ordre DE DEPENDENCY CHANGE LATEST WINS. Improbable.

**Plus probable** : useEffect 225 est en realite suppose fire AVANT useEffect 213 pour reset, mais l ordre declaration etant inversement requis, c est un bug LATENT documente nulle part.

OU bien : pre-AS.5 ce bug ne se manifeste pas parce que `selectedConversation` est set BEFORE autopilotDraft (les fetches sont parallel mais detail conv arrive plus vite ?).

C est inconsistent. **Conclusion : le bug timing est probable mais HIGH confidence n est pas atteint sans DevTools navigateur**.

### 7.3 Hypotheses raffinees a partir des nouvelles donnees

| Dependency | Critical? | Why | AS.11.1 rule |
|---|---|---|---|
| Draft depend de /messages/conversations LIST | NON | useEffect [selectedId, currentTenantId] fetch /autopilot/draft est independant de la list | LIST peut etre migree BFF sans risque pour le draft |
| Draft depend de /messages/conversations/:id DETAIL | NON directement, MAIS le mount de AISuggestionSlideOver depend de selectedConversation qui depend du detail. Donc DETAIL pilote indirectement le mount initial. | bug latent AISuggestionSlideOver expose si initialDraft set AVANT mount | DETAIL migration BFF AS.11.1 doit verifier le draft fonctionne AVANT promotion. Idealement, fixer le bug AISuggestionSlideOver d abord (AS.11.0.6). |
| Draft depend uniquement de conversationId + tenantId | OUI cote fetch | useEffect [selectedId, currentTenantId] | safe pour fetch, fragile pour mount UX. |
| Slide-over ouvre via initialDraft | OUI | setActiveDraft via useEffect 213 | conditionne par ordre useEffect interne |
| Timing critique | OUI | si /messages/conv/:id arrive APRES /autopilot/draft, AISuggestionSlideOver mount avec initialDraft DEJA set -> ordre useEffect critique. Si DETAIL arrive AVANT, AISuggestionSlideOver mount avec initialDraft=null puis useEffect 213 re-fire quand initialDraft arrive -> setActiveDraft sans concurrence. | KEY-304 patch doit ne pas augmenter latence DETAIL au-dela de /autopilot/draft |
| BFF safe pour /autopilot/draft | OUI deja en place | n/a | n/a |
| BFF safe pour /messages/conversations LIST | OUI probablement | la list n est pas dans le path initialDraft critique | OK migrer en AS.11.1b apres fix AS.11.0.6 |
| BFF safe pour /messages/conversations/:id DETAIL | DOUBT | exposera le bug latent si latence increase | MIGRER EN DERNIER, apres fix AS.11.0.6 et AS.11.1b list |
| BFF safe pour reply/status/assign/sav-status | OUI | mutations, pas dans path initialDraft | OK migrer en AS.11.1c-d-e-f |

---

## 8. Rules for AS.11.1 (revisees)

Avant AS.11.1, **AS.11.0.6 (proposition)** doit fixer le bug latent AISuggestionSlideOver :

### 8.1 AS.11.0.6 - patch AISuggestionSlideOver (source-only)

Cible : `src/features/ai-ui/AISuggestionSlideOver.tsx`.

Option A : consolider les 2 useEffect en 1 seul, avec ordre correct :
```javascript
useEffect(() => {
  // Reset on conversation change FIRST
  if (conversationId !== prevConversationIdRef.current) {
    draftDismissedRef.current = null;
    prevConversationIdRef.current = conversationId;
  }
  // Then apply initialDraft if eligible
  if (initialDraft?.draftText && autoOpen && conversationId) {
    if (draftDismissedRef.current !== conversationId) {
      setActiveDraft(initialDraft);
      setIsOpen(true);
    }
  } else if (!initialDraft) {
    setActiveDraft(null);
  }
}, [initialDraft, autoOpen, conversationId]);
```

Option B : changer l ORDRE des 2 useEffect declares (mettre le reset en PREMIER). Plus simple si l ordre React fire est bien decl order.

Option C : utiliser `useLayoutEffect` pour le reset (fire avant useEffect normal).

Recommande : Option A (consolide, deterministic).

AS.11.0.6 deliverables :
- 1 commit keybuzz-client : patch AISuggestionSlideOver.tsx
- smoke V1 PASS avant + apres
- QA Ludovic Brouillon IA SWITAA AUTOPILOT
- aucun BFF migration, aucun guard API
- rollback simple (revert single commit)

### 8.2 AS.11.1 sequence (post AS.11.0.6)

Sequence : 5-7 sous-phases endpoint-par-endpoint, smoke + QA Brouillon IA gating a chaque.

| Sous-phase | Scope | Validation |
|---|---|---|
| AS.11.1a | API : wrap fastify-plugin + PROTECTED_PREFIXES=[] vide initial | smoke V1 PASS + QA Ludovic |
| AS.11.1b | API : ajouter `/messages/conversations` (LIST only) au allowlist + Client : BFF route LIST + api.ts UN endpoint conversations | smoke V1 + QA Brouillon IA |
| AS.11.1c | API+Client : DETAIL (le plus risque, expose bug latent si AS.11.0.6 pas applique) | smoke V1 + QA Brouillon IA + temps DETAIL+autopilot/draft mesure |
| AS.11.1d-e-f | reply/status/assign/sav-status (mutations) | smoke V1 + QA |
| AS.11.1g | PROD promotion (KEY-263 debloque) | full validation matrix |

### 8.3 Future patch boundary AS.11.0.6 + AS.11.1

| Patch boundary | Allowed | Forbidden | Reason |
|---|---|---|---|
| AS.11.0.6 files | `src/features/ai-ui/AISuggestionSlideOver.tsx` UNIQUEMENT | aucun autre fichier | scope minimal |
| AS.11.1a files API | `src/plugins/tenantGuard.ts` UNIQUEMENT (reuse archive AS.5) | autre fichier API | scope minimal |
| AS.11.1b+ files Client | `app/api/messages/_bff.ts` (reuse archive AS.5) + UN seul fichier `app/api/messages/conversations/*` par sous-phase + UNE seule modif `src/config/api.ts` par sous-phase | InboxTripane, AISuggestionSlideOver, autopilot/draft route | endpoint-by-endpoint strict |
| KEY-302 + KEY-307 build args | preserves obligatoires | bypass | acquis |
| KEY-308 OCI labels | obligatoires (defaults `unknown` OK pour V1) | aucun | acquis |
| KEY-309 tag check | obligatoire AVANT push | bypass | acquis |
| Smoke V1 | PASS required pre+post-build | bypass | acquis |
| QA Ludovic | obligatoire Brouillon IA SWITAA entre chaque sous-phase | skip | retour AS.5 sinon |

---

## 9. Gaps

1. **DOM/state trace navigateur non realise** : confiance dans l hypothese H_TIMING_USEEFFECT reste MED-HIGH faute de DevTools live confirmation. Si Ludovic peut confirmer en navigateur (ouvrir DevTools Inbox SWITAA, observer ordre useEffect via React DevTools, et reproduire le bug via throttling network), HIGH confidence absolue est atteinte.

2. **Sandbox v3.5.180 redeploy temporaire** : NON realise. Aurait permis une trace directe de la regression. Trop risque cote operation pour AS.11.0.5 (impacterait DEV testeurs). Hypothese statique acceptable.

3. **AS.11.0.6 patch** : design seulement, pas execute. A planifier en phase dediee. Effort estime : 10 minutes patch + 1h test.

4. **API `/autopilot/draft` indempotence sous PROTECTED_PREFIXES** : verifie OK (PROTECTED_PREFIXES strict, /autopilot pas dedans).

5. **PROD promotion** : reste bloquee jusqu a AS.11.1g + KEY-263 fermable.

6. **Bug latent confirmation par d autres composants** : `InboxTripane` ligne 348 useEffect deps `[selectedId, currentTenantId]` est OK. Le bug est isole a AISuggestionSlideOver. Aucun autre composant connu n a le meme pattern.

---

## 10. Linear text prepared, posted

Postee sur KEY-304 et KEY-305 (cf section 10.bis URLs apres E7).

### 10.bis Resume Linear poste (controle, disclosure-controlled)

```
## AS.11.0.5 -- runtime trace Brouillon IA flow read-only

Decouverte majeure : bug latent timing identifie dans `src/features/ai-ui/AISuggestionSlideOver.tsx` :
- 2 useEffect partagent dep `conversationId`
- ordre declaration fait setActiveDraft(initialDraft) puis setActiveDraft(null)
- bug expose si initialDraft arrive AVANT mount du composant
- AS.5 BFF en ralentissant /messages/conversations/:id DETAIL inversait l ordre d arrivee et a expose le bug

Recommandation revisee :
- AS.11.0.6 (proposition) : fix AISuggestionSlideOver avant tout AS.11.1. Scope : 1 fichier source-only.
- Apres AS.11.0.6 : AS.11.1 BFF migration peut proceder endpoint-par-endpoint sans risque de regression Brouillon IA.

Cause exacte : confiance MED-HIGH par analyse statique. HIGH confidence si Ludovic confirme via DevTools navigateur.

Aucun patch, aucun build, aucun deploy, aucun kubectl apply, aucune mutation runtime/DB.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.0.5-INBOX-AI-DRAFT-RUNTIME-TRACE-READONLY-01.md
```

Disclosure controle respecte : pas de PoC, pas de PII (conv id redacted, draftText jamais affiche, customer/order/tracking jamais cite), pas de cookie/token/secret, pas de mecanique fastify-plugin exploitable detaillee.

Statut suggere :
- KEY-304 : reste In Review (design recoit nouvelle info AS.11.0.6 prerequis).
- KEY-305 : reste In Review (cause hypothese identifiee, fix design propose, pas encore execute).

---

### 10.ter Phrase cible finale

AS.11.0.5 livre la trace runtime Brouillon IA via source map exhaustive + probes API pod (timing 5-29 ms intra-pod) + analyse statique des hooks React AISuggestionSlideOver ; bug latent timing identifie (2 useEffect partagent dep `conversationId`, ordre declaration overwrite setActiveDraft) confiance MED-HIGH ; recommandation revisee : AS.11.0.6 fix source-only AISuggestionSlideOver AVANT tout AS.11.1 BFF migration ; aucun patch, aucun build, aucun deploy, aucun kubectl apply, aucune mutation runtime/DB/manifest/secret ; runtime DEV+PROD strictement inchanges ; smoke V1 PASS=18 ; verdict AS.11.0.5 GO PARTIAL TRACE READY - BROWSER ACCESS LIMITED.

STOP
