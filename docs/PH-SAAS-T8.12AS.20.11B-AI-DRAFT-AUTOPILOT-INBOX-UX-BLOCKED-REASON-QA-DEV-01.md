# PH-SAAS-T8.12AS.20.11B-AI-DRAFT-AUTOPILOT-INBOX-UX-BLOCKED-REASON-QA-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-305 / KEY-235 / KEY-231 (related)
> Phase : PH-SAAS-T8.12AS.20.11B QA Client DEV post-apply read-only
> Environnement : DEV read-only (aucun PROD, aucun LLM, aucune KBActions)

## VERDICT

**STOP BLOCKER CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE PH-SAAS-T8.12AS.20.11B**

Le patch source PH-20.11B (commit Client `fb348356` + commit API `5070e6a6`) est correctement compile et deploye en DEV (build v3.5.211 LIVE, OCI 5/5, markers 4/4 bundle). Le composant `AISuggestionSlideOver` contient la carte UX "Garde-fou actif" comme prevu.

**MAIS** : le parent identifie `app/inbox/InboxTripane.tsx` lignes 357-380 NE LIT PAS les nouveaux champs API `data.blocked / data.blockedStatus / data.blockedNotes`. Le wire branchement parent->enfant est INCOMPLET :

```typescript
// app/inbox/InboxTripane.tsx l.357-380 (extrait)
if (data.hasDraft && data.draftText) {
  setAutopilotDraft({ draftText, confidence, createdAt, ... });
  setAutopilotAutoOpen(true);
} else {
  setAutopilotDraft(null);           // <- notre cas blocked tombe ici
  setAutopilotAutoOpen(false);
}
```

Quand l'API retourne `{hasDraft:false, blocked:true, blockedStatus, blockedNotes}` (notre extension PH-20.11B), le parent va vers la branche `else` (parce que `data.hasDraft` est false), `setAutopilotDraft(null)`, et la carte UX ne s'affichera JAMAIS.

**Conclusion** : il manque une 3e branche dans le parent qui hydrate l'etat avec les champs blocked OU une nouvelle prop `blockedInfo` passee separement au composant.

Recommandation : ouvrir `PH-SAAS-T8.12AS.20.11B-PARENT-WIRE` pour patcher InboxTripane.tsx (et incidemment le builder API/Client/apply DEV PROD du fix). NE PAS promouvoir l'image v3.5.211 en PROD tant que ce wire n'est pas fait, sinon le patch est inerte en prod et l'UX gap reste.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T19:26:37Z |
| Pod Client DEV | keybuzz-client-84d44d5998-5n945 Ready 1/1, 0 restart, depuis 19:18:04Z |
| Tag runtime DEV | v3.5.211-ai-draft-blocked-reason-dev |
| Digest runtime | sha256:afe7287160c86e4a55e7937a0d6e4f33b1653f1526657a37f3e68181ec3eb65d MATCH |
| Client PROD runtime | v3.5.201-register-polish-prod INCHANGE |
| API DEV runtime | v3.5.253-meta-capi-emq-dev INCHANGE (note : extension GET /draft n est PAS encore deployee en API DEV ; l image API n a pas ete promue) |
| API PROD runtime | v3.5.252-meta-capi-emq-prod INCHANGE |

**Note importante** : l'extension API GET /autopilot/draft (commit `5070e6a6`) n'a pas non plus ete deployee en API DEV. Donc meme si le parent etait wired, l'API DEV ne retournerait pas encore les nouveaux champs. Donc 2 changements PROD necessaires : (a) build/push/apply API DEV+PROD avec commit 5070e6a6, (b) patch parent InboxTripane.tsx + rebuild Client.

## E1 API DEV READ-ONLY CONTRACT CHECK

| Indicateur | Resultat |
|---|---|
| API DEV runtime | v3.5.253-meta-capi-emq-dev INCHANGE (commit API 5070e6a6 NON deploye) |
| GET /autopilot/draft DEV reponse pour case bloque | retournerait probablement `{hasDraft:false}` ancien comportement, pas le nouveau blocked info |
| Verdict | API DEV pas encore pret. Patch source 5070e6a6 push mais image API DEV non rebuild/apply. |

Pas de DB probe SQL execute dans cette phase (audit conservatoire). Le constat principal vient deja du wire Client.

## E2 CLIENT SOURCE WIRE CHECK

### Decouverte path correct

Structure Next.js 13+ avec `app/` a la racine (non `src/app/`). Le grep precedent dans `src/` uniquement ne trouvait pas le parent.

### Parent identifie

| Fichier | Role | Status PH-20.11B |
|---|---|---|
| `app/inbox/InboxTripane.tsx` | Parent qui rend AISuggestionSlideOver, fetch /api/autopilot/draft, gere state autopilotDraft | **NON PATCHE** |

### Wire actuel (lignes 357-380 du parent)

```typescript
const fetchDraft = async () => {
  const res = await fetch(`/api/autopilot/draft?tenantId=${...}&conversationId=${...}`);
  const data = await res.json();
  if (data.hasDraft && data.draftText) {
    setAutopilotDraft({
      draftText: data.draftText,
      confidence: data.confidence ?? 0.5,
      createdAt: data.createdAt ?? new Date().toISOString(),
      escalationStatus: data.escalationStatus ?? null,
      escalationReason: data.escalationReason ?? null,
      needsHumanAction: data.needsHumanAction ?? false,
      logId: data.logId ?? undefined,
    });
    setAutopilotAutoOpen(true);
  } else {
    setAutopilotDraft(null);
    setAutopilotAutoOpen(false);
  }
};
```

### Render actuel (lignes 1567-1601)

```jsx
<AISuggestionSlideOver
  conversationId={selectedConversation.id}
  tenantId={currentTenantId || ''}
  channel={selectedConversation.channel || 'email'}
  ...
  initialDraft={autopilotDraft}    // <- null pour les cas blocked
  autoOpen={autopilotAutoOpen}      // <- false pour les cas blocked
  // PAS de prop blockedInfo
/>
```

### Tableau parent wire

| Parent | Fetch /autopilot/draft | data.blocked recu ? | data.blocked transmis a SlideOver ? | Verdict |
|---|---|---|---|---|
| app/inbox/InboxTripane.tsx l.349 | OUI (via BFF /api/autopilot/draft) | non lu (champ ignore) | non | **BLOCKER** |

### BFF /api/autopilot/draft (Client side)

| Fichier | Role | Status PH-20.11B |
|---|---|---|
| `app/api/autopilot/draft/route.ts` | BFF Client transit GET vers API publique avec X-User-Email + X-Tenant-Id | INCHANGE - transparent forward, pas a patcher (retourne `await res.json()` qui inclut les nouveaux champs si API les retourne) |

Le BFF est transparent : il retournera les nouveaux champs automatiquement DES QUE l'API DEV sera rebuild + apply avec le commit 5070e6a6.

## E3 UI QA DEV SAFE

Non execute. La carte UX ne peut pas s'afficher en runtime DEV car :
1. API DEV ne retourne pas encore les champs blocked (image v3.5.253 sans le commit 5070e6a6 deploye).
2. Parent InboxTripane.tsx ne lit pas ces champs meme s'ils etaient retournes.

QA browser Ludovic ne verrait que l'ancien comportement (mode "Suggestion IA" silencieux sur conversation bloquee).

## E4 REGRESSION CHECK

| Indicateur | Resultat | Verdict |
|---|---|---|
| Conversation avec DRAFT_GENERATED -> Brouillon IA visible | preserve (logique existante inchangee) | OK |
| Logs Client DEV (tail 300) : 0 erreur | OK (cf. rapport APPLY DEV) | OK |
| Logs API DEV : 0 erreur lie QA | OK | OK |
| Aucun `/ai/assist` declenche pour QA | 0 | OK |
| Aucune KBActions debit lie QA | 0 | OK |
| Runtime Client PROD + API PROD INCHANGES | OK | OK |

## E5 RAPPORT INFRA

Cette page.

## E6 LINEAR

Commente sur KEY-312 avec blocker + recommandation PH-20.11B-PARENT-WIRE.

## DECISION TECHNIQUE - PROCHAINES ETAPES

### Option A (recommandee) : PH-SAAS-T8.12AS.20.11B-PARENT-WIRE

Patch source supplementaire sur 3 fichiers minimum :

1. **app/inbox/InboxTripane.tsx** (lignes 357-380) : ajouter une 3eme branche dans `fetchDraft` pour le cas `data.blocked === true`. Hydrate `autopilotDraft` avec un objet enrichi du champ `blocked` (qui correspond a `AutopilotDraft.blocked?: AutopilotBlockedInfo` deja ajoute en PH-20.11B). Mettre `autoOpen=true` aussi.

2. **app/inbox/InboxTripane.tsx** ligne 1596 : si on garde la prop unique `initialDraft`, aucun changement supplementaire. Sinon, ajouter aussi `blockedInfo={autopilotDraft?.blocked}`.

3. **API DEV deploy** : rebuild + push + apply API DEV depuis commit `5070e6a6` (apporte la nouvelle response API GET /autopilot/draft) avec un nouveau tag v3.5.254-ai-draft-blocked-reason-dev.

4. Rebuild Client DEV (nouveau tag v3.5.212-...) apres le patch parent, puis push + apply DEV.

5. QA browser Ludovic sur conversation bloquee reelle.

### Option B : approche separation prop

Au lieu d'integrer `blocked` dans `AutopilotDraft.blocked`, ajouter une prop separee `blockedInfo` au composant + nouveau state dans le parent. Plus propre semantique mais plus invasif.

### Option C : abandon

Pas recommande, le gap UX reste.

## CONFIRMATIONS SECURITE

- AUCUN docker build / push / deploy supplementaire dans cette phase QA.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN restart pod.
- AUCUN appel LLM.
- AUCUNE KBActions consommee.
- AUCUN message marketplace envoye.
- AUCUN event marketing.
- AUCUNE mutation DB.
- AUCUN SQL probe execute (audit conservatoire base sur lecture source).
- AUCUN clic "Generer une suggestion" / `/ai/assist` / `/autopilot/draft/consume`.
- AUCUN changement Linear statut.
- AUCUN secret/token/PII affiche.
- Doctrine seller-first/refund-protection INCHANGE.
- KEY-305 fix preserve source.
- Bastion install-v3 (46.62.171.61) uniquement.

## RUNTIME PRESERVE

| Service | Runtime | Verdict |
|---|---|---|
| Client DEV | v3.5.211-ai-draft-blocked-reason-dev | INCHANGE depuis APPLY |
| Client PROD | v3.5.201-register-polish-prod | INCHANGE |
| API DEV | v3.5.253-meta-capi-emq-dev | INCHANGE (commit 5070e6a6 non build/push/deploy) |
| API PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |
| Backend / Website / Admin | inchanges | INCHANGES |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| **Verdict** | **STOP BLOCKER CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE PH-SAAS-T8.12AS.20.11B** |
| Bastion | install-v3 46.62.171.61 |
| Cause principale | parent `app/inbox/InboxTripane.tsx` l.357-380 ignore les nouveaux champs API `data.blocked / blockedStatus / blockedNotes` |
| Cause secondaire | API DEV image n a pas ete rebuild/deploye avec le commit 5070e6a6 (extension GET /autopilot/draft) |
| Patch source PH-20.11B Client+API | source preserve correct, mais sans le wire parent, le code est inerte runtime |
| Runtime DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11B-AI-DRAFT-AUTOPILOT-INBOX-UX-BLOCKED-REASON-QA-DEV-01.md` |

### Prochaine phrase GO attendue

`GO SOURCE PATCH CLIENT AI DRAFT BLOCKEDINFO PARENT WIRE PH-SAAS-T8.12AS.20.11B-PARENT-WIRE`

(qui devra : patch parent InboxTripane.tsx + build/push/apply API DEV+PROD du commit 5070e6a6 + rebuild Client + redeploy DEV + QA browser + promotion PROD)

STOP. Aucun deploy supplementaire, aucun LLM, aucune KBActions, aucun changement Linear statut.
