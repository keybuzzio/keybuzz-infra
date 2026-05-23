# PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-SOURCE-PATCH-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20) ; KEY-312 (primary) ; KEY-235 (seller-first/refund) ; KEY-231 (KBActions anxiety) ; KEY-305 (race UI)
> Phase : PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE source patch Client UX
> Environnement : Source patch only (aucun build, aucun deploy, aucun LLM, aucune KBActions)

## VERDICT

GO SOURCE PATCH CLIENT GUARDRAIL GUIDANCE DEV READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE

- Patch source minimal applique sur `src/features/ai-ui/AISuggestionSlideOver.tsx` (+54 lignes / -0).
- Client commit `1a30ad9` push origin/ph148/onboarding-activation-replay.
- 3 patches dans 1 seul fichier :
  1. Constante module `SAFE_GUIDANCE_TEXT` (trame statique).
  2. Nouveau state local `safeGuidanceCopied` + handler `handleCopySafeGuidance`.
  3. Sous-bloc "Trame de reponse securisee" ajoute dans la card amber blockedInfo (visible uniquement quand `!activeDraft && blockedInfo.blocked === true`).
- tsc Client : exit 0 (0 erreur nouvelle).
- Aucun appel API, aucun LLM, aucune KBActions consommee, aucun send automatique.
- KEY-305 race fix preserve (draftDismissedRef=5, prevConversationIdRef=3 inchanges).
- Doctrine seller-first preserve : la trame statique n'engage NI remboursement, NI remplacement, NI delai.
- Markers PH-20.11B preserve : Garde-fou actif=1, Brouillon IA bloque=1, Validation humaine recommandee=1.
- Aucun hardcode tenant/case user (SWITAA/eComLG/Guilhem/Nordine = 0).

NE PAS rebuild/push/deploy dans cette phase. Sequence prochaine : build Client DEV depuis 1a30ad9.

## MOTIVATION PRODUIT (LUDOVIC)

### Etat DEV apres PH-20.11B-AUTOOPEN-FIX

- Drawer s'ouvre automatiquement pour conversations PRE_LLM_BLOCKED.
- Carte amber "Brouillon IA bloque par securite" + badge "Garde-fou actif" visible.
- Codes COMBINED_RISK_HIGH / PRE_LLM_BLOCKED affiches sanitizes.
- Aucun draft IA genere (preserve guardrails seller-first).

### Gap produit

L'agent humain voit la carte amber mais n'a aucune **guidance concrete** pour repondre. Le seul CTA est "Generer une suggestion" qui consomme des KBActions et qui peut etre derisoire si le message est sensible (ex : "Rembourse moi tout de suite").

### Objectif PH-20.11C

Donner une trame statique humaine, ASCII strict, sans promesse, qui aide l'agent a repondre prudemment :
- Sans appeler LLM
- Sans consommer KBActions
- Sans send automatique
- Sans bypasser guardrails

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-23T00:30:59Z |
| keybuzz-client branche | ph148/onboarding-activation-replay |
| HEAD avant | d132cc4 |
| HEAD apres | **1a30ad9** |
| Dirty avant | 1 (tsconfig.tsbuildinfo cache pre-existant, non lie) |

## E1 AUDIT SOURCE EXISTANTE

| Fichier | Bloc | Ligne | Role |
|---|---|---|---|
| `AISuggestionSlideOver.tsx` | useEffect autoOpen | 234-247 | Auto-open drawer (PH-20.11B-AUTOOPEN-FIX preserve) |
| `AISuggestionSlideOver.tsx` | handleCopy (draft) | 421-431 | Pattern clipboard existant (reutilise) |
| `AISuggestionSlideOver.tsx` | bloc amber blockedInfo | 696-733 | Card amber Garde-fou actif PH-20.11B |
| `AISuggestionSlideOver.tsx` | Pre-generation info (Obtenir une suggestion) | 736+ | KBActions consumer button (preserve) |
| `AISuggestionSlideOver.tsx` | Bouton "Generer une nouvelle suggestion" | 710 | Preserve |
| Imports lucide-react | Copy + Check | 19 | Reutilisables |

## E2 PATCH MINIMAL APPLIQUE

### `src/features/ai-ui/AISuggestionSlideOver.tsx` (+54 / -0 lignes)

#### Patch 1/3 : Constante module-level SAFE_GUIDANCE_TEXT

```typescript
// PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE KEY-312 / KEY-235 : trame de reponse securisee statique
// Non generee par LLM, ne consomme aucune KBActions, aucun send automatique.
// Ne promet ni remboursement ni remplacement ni delai avant verification.
const SAFE_GUIDANCE_TEXT = `Bonjour,

Je comprends votre inquietude concernant votre commande. Je vais verifier les informations disponibles afin de vous repondre de facon fiable.

Pour eviter toute erreur, je ne peux pas confirmer immediatement un remboursement ou un remplacement avant verification du dossier. Si un incident est confirme, nous vous indiquerons les options possibles selon les conditions de la commande et de la plateforme.

Merci pour votre patience,
[Signature]`;
```

#### Patch 2/3 : State + handler copy

```typescript
// PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE KEY-312 : copie de la trame statique securisee
// Aucun appel API, aucun LLM, aucune KBActions, aucun send.
const [safeGuidanceCopied, setSafeGuidanceCopied] = useState(false);
const handleCopySafeGuidance = useCallback(() => {
  navigator.clipboard.writeText(SAFE_GUIDANCE_TEXT);
  setSafeGuidanceCopied(true);
  setTimeout(() => setSafeGuidanceCopied(false), 2000);
}, []);
```

#### Patch 3/3 : Sous-bloc UI dans card amber blockedInfo

Ajoute juste avant le `</div>` de fermeture de la card amber blockedInfo :

```jsx
{/* PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE KEY-312 / KEY-235 : trame de reponse securisee statique, non-LLM, no KBActions */}
<div className="mt-3 pt-3 border-t border-amber-200 dark:border-amber-800">
  <div className="flex items-start justify-between gap-2 mb-1">
    <div className="flex-1">
      <p className="text-xs font-semibold text-gray-800 dark:text-gray-100">
        Trame de reponse securisee
      </p>
      <p className="text-[11px] text-gray-600 dark:text-gray-300 mt-0.5">
        Point de depart humain, sans generation IA ni consommation de KBActions.
      </p>
    </div>
    <button
      type="button"
      onClick={handleCopySafeGuidance}
      className="inline-flex items-center gap-1 text-[11px] text-amber-700 dark:text-amber-300 hover:text-amber-900 dark:hover:text-amber-100 flex-shrink-0"
      title="Copier la trame dans le presse-papier"
    >
      {safeGuidanceCopied ? (
        <><Check className="h-3 w-3 text-green-500" /><span className="text-green-500">Copie</span></>
      ) : (
        <><Copy className="h-3 w-3" /><span>Copier la trame</span></>
      )}
    </button>
  </div>
  <pre className="mt-2 text-[11px] text-gray-700 dark:text-gray-200 whitespace-pre-wrap font-sans leading-relaxed bg-amber-100/40 dark:bg-amber-900/30 rounded p-2 border border-amber-200/60 dark:border-amber-800/60">{SAFE_GUIDANCE_TEXT}</pre>
</div>
```

### Visibilite

La section est rendue uniquement dans la card amber blockedInfo (condition existante `!activeDraft && blockedInfo && blockedInfo.blocked`). Donc :
- **Visible** : conversation PRE_LLM_BLOCKED / ESCALATION_DRAFT (cas Ludovic SWITAA).
- **Invisible** : conversation avec draft normal (`activeDraft` existe) OR sans blockedInfo.

## E3 TESTS SOURCE

| Test | Resultat | Verdict |
|---|---|---|
| tsc Client | exit 0 | OK |
| Markers "Trame de reponse securisee" | 1 | OK |
| Markers "sans generation IA" | 1 | OK |
| Markers "ni consommation de KBActions" | 1 (texte legerement different du marker original) | OK |
| Markers "ne peux pas confirmer immediatement" | 1 | OK |
| Markers "remboursement ou un remplacement avant verification" | 1 | OK |
| Markers SAFE_GUIDANCE_TEXT | 3 (declaration + 2 usages) | OK |
| Markers safeGuidanceCopied | 2 (declaration + use) | OK |
| Markers handleCopySafeGuidance | 2 (declaration + use) | OK |

## E4 ANTI-REGRESSION

| Controle | Resultat | Verdict |
|---|---|---|
| AutoOpen fix preserve (`blockedInfo?.blocked` dans useEffect) | 2 (pattern compile) | OK |
| Carte amber blockedInfo preserve | OK | OK |
| Garde-fou actif texte | 1 | preserve |
| Brouillon IA bloque par securite | 1 | preserve |
| Validation humaine recommandee | 1 | preserve |
| `draftDismissedRef` (KEY-305) | 5 | preserve |
| `prevConversationIdRef` (KEY-305) | 3 | preserve |
| Bouton "Generer une nouvelle suggestion" | preserve l.710 (avec accent francais) | preserve |
| Bouton "Generer une suggestion" KBActions | preserve l.829 | preserve |
| Pattern autoOpen `(draftText \|\| blocked)` | preserve compile | preserve |
| Hardcode tenant/case user (ecomlg-motxke32/Guilhem/Nordine/SWITAA) | 0/0/0/0 | OK |
| Appel API/LLM ajoute | 0 | OK |
| `/ai/assist` / `/ai/execute` / `/autopilot/draft/consume` | inchanges | preserve |

## E5 DIFF REVIEW

| Fichier | + | - | Changement | Risque |
|---|---|---|---|---|
| `src/features/ai-ui/AISuggestionSlideOver.tsx` | 54 | 0 | constante + state + handler + sous-bloc UI dans card amber blockedInfo | bas (additif uniquement, condition `!activeDraft && blockedInfo.blocked`) |

Aucun autre fichier modifie. Scope strict respecte.

## E6 COMMIT + PUSH

| Repo | Branche | Commit | Push | Verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | **1a30ad925fed3fb0b237e7b82694c2f839bc0778** | OK d132cc4..1a30ad9 | OK |

Message commit : `feat(inbox): add safe guidance for blocked AI drafts PH-20.11C KEY-312`

## TRAME DE REPONSE STATIQUE

| Indicateur | Valeur |
|---|---|
| Type | Statique, hardcoded dans source Client |
| Generation LLM | NON |
| KBActions consommees | NON |
| Send automatique | NON |
| Inserer auto dans champ reponse | NON (copie clipboard seulement, action utilisateur explicite) |
| Promet remboursement | NON ("je ne peux pas confirmer immediatement un remboursement") |
| Promet remplacement | NON ("je ne peux pas confirmer immediatement un... remplacement") |
| Promet delai | NON ("avant verification du dossier") |
| Ton | Empathique, calme, professionnel |
| Compatible marketplace | OUI (Amazon, eBay, Cdiscount, generique) |
| ASCII strict | OK |

### Texte integral

```
Bonjour,

Je comprends votre inquietude concernant votre commande. Je vais verifier les informations disponibles afin de vous repondre de facon fiable.

Pour eviter toute erreur, je ne peux pas confirmer immediatement un remboursement ou un remplacement avant verification du dossier. Si un incident est confirme, nous vous indiquerons les options possibles selon les conditions de la commande et de la plateforme.

Merci pour votre patience,
[Signature]
```

## AI FEATURE PARITY / ANTI-REGRESSION

| Feature IA | Avant patch | Apres patch | Verdict |
|---|---|---|---|
| Brouillon IA normal (DRAFT_GENERATED auto-open) | OK | OK (logique conservation) | preserve |
| Brouillon IA blockedInfo auto-open (PH-20.11B-AUTOOPEN-FIX) | OK | OK + section trame ajoutee | enrichi |
| Suggestion IA fallback (sans draft) | OK | OK | preserve |
| Aide IA manuelle | OK | OK | preserve |
| Autopilot guardrails (autopilotGuardrails.ts) | INCHANGE 100% | INCHANGE 100% | preserve |
| Escalation flow | INCHANGE | INCHANGE | preserve |
| KBActions billing | INCHANGE | INCHANGE | preserve (trame statique, no consumption) |
| KEY-305 race UI fix | preserve (5+3) | preserve (5+3) | OK |
| KEY-235 refund protection | preserve | preserve + renforce (trame statique respect doctrine) | OK |
| KEY-231 no anxiety billing | preserve | preserve + ameliore (alternative sans KBActions visible) | OK |
| KEY-263 DEV/PROD isolation | INCHANGE | INCHANGE | preserve |
| KEY-302 build args | INCHANGE | INCHANGE | preserve |

## NO FAKE METRICS / NO FAKE EVENTS / NO FAKE KBACTIONS

| Controle | Resultat | Verdict |
|---|---|---|
| Aucun event marketing genere | 0 | OK |
| Aucun fake lead/register/checkout | 0 | OK |
| Aucun fake message envoye | 0 | OK |
| Aucun appel LLM | 0 | OK |
| Aucune KBActions consommee | 0 | OK |
| Aucune mutation DB | 0 | OK |
| Action utilisateur (copie clipboard) | navigator.clipboard.writeText local uniquement | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy DEV/PROD.
- AUCUN restart pod.
- AUCUN kubectl mutation.
- AUCUN changement API.
- AUCUN changement guardrails seller-first (autopilotGuardrails.ts INCHANGE 100%).
- AUCUN changement engine.ts.
- AUCUN changement billing/KBActions.
- AUCUN changement BFF.
- AUCUN changement InboxTripane.tsx.
- AUCUN changement aiSuggestions.ts.
- AUCUN /ai/assist / /ai/execute / /autopilot/draft/consume ajoute.
- AUCUN send automatique.
- AUCUNE KBActions consommee.
- AUCUN seuil guardrail modifie.
- AUCUN PRE_LLM_BLOCKED rendu eligible au draft.
- AUCUN secret/token/PII brut.
- AUCUN changement Linear statut.
- Doctrine seller-first INCHANGE 100%.
- KEY-305 fix preserve source.
- KEY-263 isolation respectee.
- Bastion install-v3 (46.62.171.61) uniquement.

## RUNTIME PRESERVE

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-client | DEV | v3.5.213-ai-draft-blocked-reason-dev | INCHANGE (source patch only) |
| keybuzz-client | PROD | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | DEV | v3.5.254-ai-draft-blocked-reason-dev | INCHANGE LIVE |
| keybuzz-api | PROD | v3.5.252-meta-capi-emq-prod | INCHANGE |

## TABLEAUX FINAUX

### 1. Repos / Git

| Repo | Branche | HEAD avant | HEAD apres | Dirty avant | Dirty apres | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | d132cc4 | **1a30ad9** | 1 (tsbuildinfo cache) | 0 sur source | OK |

### 2. Fichiers changes

| Fichier | Changement | Risque | Mitigation |
|---|---|---|---|
| `src/features/ai-ui/AISuggestionSlideOver.tsx` | +54 / -0 : constante SAFE_GUIDANCE_TEXT + state + handler + UI sous-bloc | bas | additif uniquement, condition `!activeDraft && blockedInfo.blocked` preserve, tsc OK, scope strict |

### 3. Guidance

| Guidance | Type | LLM | KBActions | Send auto | Verdict |
|---|---|---|---|---|---|
| Trame de reponse securisee | Statique hardcoded | NON | NON | NON (copie clipboard seulement) | OK |

### 4. Tests

| Test | Resultat | Verdict |
|---|---|---|
| tsc Client | exit 0 | PASS |
| Markers source patch | 8/8 attendus | PASS |
| Anti-regression PH-20.11B | preserves | PASS |
| KEY-305 race fix | 5+3 inchange | PASS |
| Scope strict | 1 fichier | PASS |

### 5. Features IA

| Feature | Avant | Apres | Verdict |
|---|---|---|---|
| Brouillon IA normal | OK | OK | preserve |
| Brouillon IA blockedInfo auto-open | OK | OK + trame statique | enrichi |
| Suggestion IA fallback | OK | OK | preserve |
| Aide IA manuelle | OK | OK | preserve |
| Doctrine seller-first | INCHANGE 100% | INCHANGE 100% | preserve |
| KBActions billing | inchange | inchange | preserve |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build/push | OUI | aucune commande build |
| deploy DEV/PROD | OUI | aucun kubectl apply |
| kubectl mutation | OUI | uniquement get/exec read-only |
| restart pod | OUI | uptime preserve |
| LLM call | OUI | trame statique, navigator.clipboard local |
| /ai/assist /ai/execute /draft/consume | OUI | 0 ajout |
| fake event/metric/KBActions | OUI | 0 |
| mutation DB | OUI | aucun acces DB |
| changement API/guardrails/engine/billing | OUI | aucun fichier hors AISuggestionSlideOver.tsx |
| changement Linear statut | OUI | comment only |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| **Verdict** | **GO SOURCE PATCH CLIENT GUARDRAIL GUIDANCE DEV READY PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE** |
| Bastion | install-v3 46.62.171.61 |
| Client commit | 1a30ad9 push ph148/onboarding-activation-replay |
| Client diff | +54 / 0 (1 fichier : AISuggestionSlideOver.tsx) |
| tsc Client | exit 0 |
| Doctrine seller-first | preserve 100% |
| KEY-305 race fix | preserve (5+3) |
| AI feature parity | preserve + enrichi (trame statique) |
| KBActions consommee | 0 (trame statique) |
| LLM call | 0 (trame statique) |
| Runtime DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-SOURCE-PATCH-01.md` |

### Prochaine phrase GO attendue

`GO BUILD CLIENT GUARDRAIL GUIDANCE DEV PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE`

(build Client DEV depuis commit 1a30ad9 -> nouveau tag v3.5.214-ai-draft-blocked-reason-dev)

STOP. Aucun build, aucun push image, aucun deploy, aucun LLM, aucune KBActions consommee, aucun changement Linear statut.
