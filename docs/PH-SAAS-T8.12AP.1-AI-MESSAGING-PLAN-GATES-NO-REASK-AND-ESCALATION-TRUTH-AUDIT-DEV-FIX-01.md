# PH-SAAS-T8.12AP.1 — AI Messaging Plan Gates, No-Reask, and Escalation Truth Audit + DEV Fix

> **Date** : 6 mai 2026
> **Environnement** : DEV (PROD read-only)
> **Type** : Audit vérité + fix DEV
> **Priorité** : P0 avant lancement Ads
> **Linear** : KEY-253 (parent AP), KEY-255 (escalade), KEY-256 (no-reask)

---

## Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `05d171d1` | M (3 fichiers billing hors scope) | OK |
| keybuzz-infra | `main` | `f50feff` | Clean | OK |

- DEV-first confirmé
- PROD read-only
- Aucun build avant audit

### Runtimes

| Service | DEV runtime | PROD runtime | Verdict |
|---|---|---|---|
| API | `v3.5.142-promo-retry-email-*` | idem | OK |
| Client | `v3.5.162-amazon-inbound-guide-demo-gating-*` | idem | OK |
| Backend | `v1.0.47-cross-env-guard-fix-*` | idem | OK |

---

## Screenshot utilisateur analysé

- **Tenant** : SWITAA SASU
- **Conversation** : "Le colis n'est pas arrivé : Demander un re..."
- **Mode** : IA (Adaptative)
- **Assignation** : Non assignée
- **Commande visible** : `484-3892837-3215558` (badge + "Voir la commande")
- **Brouillon IA** : "pourriez-vous me communiquer votre numéro de commande ou de suivi ?"
- **Confiance** : moyenne (08.45)
- **KBActions** : 1932.01

**Bug confirmé** : l'IA demande le numéro de commande alors qu'il est déjà connu et affiché dans l'UI.

---

## AI Feature Parity / Anti-Regression Matrix

| Feature | Rapport/source | Source actuelle | Runtime | UI | Gap | Linear |
|---|---|---|---|---|---|---|
| No-reask commande | PH-API-T8.12AF/AH/AI | `AISuggestionSlideOver.tsx` | Client DEV | orderRef passé mais conditionné à savStatus | **BUG** : orderRef ignoré si pas de savStatus | KEY-256 |
| No-reask tracking | PH-API-T8.12AH.1 | Non injecté côté client | Client DEV | Tracking non passé au prompt | **GAP** : aucun tracking dans le contexte IA inbox | KEY-256 |
| Aide IA | PH25.10/PH26.5L | `AISuggestionSlideOver.tsx` | Client DEV | Bouton visible, appelle `/api/ai/assist` | OK | — |
| Brouillon IA | PH142-F | `GET /api/autopilot/draft` | Client DEV | Drawer unifié avec draft | OK (backend gère contexte) | — |
| Autopilot auto | PH143-E | `AutopilotSection.tsx` | Settings UI | Mode off/supervised/autonomous | OK, gated correctement | — |
| Retry/régénération | PH25.10 | `AISuggestionSlideOver.tsx` | Client DEV | Bouton "Générer nouvelle suggestion" | OK (même path que Aide IA) | — |
| Plan gates | PH12-03 | `planCapabilities.ts` | Client DEV | FeatureGate PRO pour suggestions panel | OK | — |
| KBActions | PH33.12 | `planCapabilities.ts` + wallet API | Client DEV | Balance affichée, wallet check | OK | — |
| AI wallet | PH33 | `ai.service.ts` | Client DEV | getAIWalletStatus | OK | — |
| Agent KeyBuzz | AutopilotSection | `AutopilotSection.tsx` | Client DEV | Addon required, non hardcodé | OK | — |
| Escalade | PH143 | `EscalationPanel.tsx` | Client DEV | Bouton + raison + cible | **GAP** : pas d'assignation auto | KEY-255 |
| Assignation | `AssignmentPanel.tsx` | Client DEV | Bouton Prendre/Relâcher | OK fonctionnel | — |
| Seller-first | PH-SAAS-T8.12O | `autopilotGuardrails.ts` | API | Doctrine codée | OK | — |
| Platform-aware | PH-API-T8.12Q | `strategicResolutionEngine.ts` | API | policyPosture per channel | OK | — |

---

## Matrice Plan × Chemin IA

| Plan | Entitlement | Aide IA | Brouillon IA | Autopilot auto | Retry | KBActions requis | Attendu | Observé | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| STARTER | hasAIAssistant=true, quota=3/j | Bouton visible | Non généré (Autopilot off) | Non (canAutoExecute=false) | Oui (même path) | Oui (wallet = 0) | IA accessible mais wallet-gated | Bouton visible, wallet bloque si 0 KBA | **OK** |
| PRO | hasAIAssistant=true, quota=∞ | Oui | Si Autopilot configuré | Non (canAutoExecute=false) | Oui | Oui (1000/mois) | Suggestions + validation humaine | Correct | **OK** |
| AUTOPILOT | hasAIAssistant=true, quota=∞ | Oui | Oui | Oui (canAutoExecute=true) | Oui | Oui (2000/mois) | Auto + garde-fous | Correct | **OK** |
| AUTOPILOT_ASSISTED | hasAIAssistant=true, quota=∞ | Oui | Oui | **Non** (canAutoExecute=false) | Oui | Oui (1000/mois) | Suggestions assistées, pas d'auto-send | Correct | **OK** |
| billing_exempt | Same as plan | Same | Same | Same | Same | Wallet may differ | Standard per plan | Standard | OK |

### Détail STARTER

- `AISuggestionsPanel` (panel latéral suggestions) : **masqué** (FeatureGate PRO)
- "Aide IA" bouton (AISuggestionSlideOver) : **visible**, pas de FeatureGate
- `AIAssistant` composant (page orders) : **visible**, quota localStorage 3/j
- Wallet API : **0 KBActions → ACTIONS_EXHAUSTED**
- Templates/playbooks non-IA : **accessibles** (hasBasicPlaybooks=true)

**Verdict STARTER** : le gating est correct par design. Le bouton "Aide IA" est un teaser commercial. La vraie barrière est le wallet KBActions (0 inclus). Pas de bug.

---

## Audit No-Reask par chemin

| Chemin | Endpoint | Plan gate | Order context | Tracking context | Anti-reask | Verdict |
|---|---|---|---|---|---|---|
| Aide IA (inbox) | POST /api/ai/assist | Aucun (wallet gate) | orderRef inclus **uniquement si savStatus** | **Jamais inclus** | **Aucune instruction** | **BUG** (KEY-256) |
| Brouillon IA (Autopilot) | GET /api/autopilot/draft | Backend gate | Backend résout via conversationId | Backend résout | Backend responsable | À vérifier backend |
| Aide IA (orders page) | POST /api/ai/assist | Aucun (wallet gate) | **Oui** (orderData structuré avec carrier, trackingCode) | **Oui** | Implicite via données | **OK** |
| Retry/régénération | POST /api/ai/assist | Même que Aide IA | Même que Aide IA inbox | Même que Aide IA inbox | Même | **BUG** (même path) |
| AIDecisionPanel | POST /api/ai/assist | Aucun | **Non** (seulement messages) | **Non** | **Aucune** | **GAP** |

### Cause racine (KEY-256)

**Fichier** : `src/features/ai-ui/AISuggestionSlideOver.tsx` lignes 313-316

**Avant** (code bugué) :
```ts
const savContext = savStatus
  ? `\n\n[Contexte SAV: statut=${savStatus}${orderRef ? `, commande=${orderRef}` : ''}]`
  : '';
```

`orderRef` n'est injecté dans le contexte IA que si `savStatus` est truthy. Si la conversation a une commande mais pas de statut SAV → **orderRef absent du prompt → l'IA demande le numéro de commande**.

Le tracking (tracking_code, carrier, delivery_status) n'est **jamais** inclus dans le contexte IA depuis l'inbox.

---

## Fix appliqué (client-side)

**Fichier** : `src/features/ai-ui/AISuggestionSlideOver.tsx`

**Changements** :
1. **Séparation** du contexte SAV et du contexte commande
2. **Toujours** inclure `orderRef` quand disponible (plus conditionné par savStatus)
3. **Ajout bloc anti-reask** : instruction explicite interdisant à l'IA de demander des données connues

```diff
- const savContext = savStatus
-   ? `\n\n[Contexte SAV: statut=${savStatus}${orderRef ? `, commande=${orderRef}` : ''}]`
-   : '';
+ const savContext = savStatus
+   ? `\n\n[Contexte SAV: statut=${savStatus}]`
+   : '';
+ const orderContext = orderRef
+   ? `\n\n[COMMANDE CONNUE: ${orderRef}]`
+   : '';
+ const noReaskBlock = orderRef
+   ? `\n\n[INSTRUCTION OBLIGATOIRE: Le numéro de commande est déjà connu (${orderRef}). Ne JAMAIS demander au client son numéro de commande, de suivi ou de tracking. Utiliser les données disponibles.]`
+   : '';
```

Ce fix couvre :
- ✅ Aide IA (inbox)
- ✅ Retry/régénération
- ❌ Brouillon IA Autopilot (backend-side, hors scope client)
- ❌ Tracking code (nécessite enrichissement backend, ou props supplémentaires client → Linear)

---

## Audit Escalade (KEY-255)

### escalationTarget par plan

| Plan | escalationTarget | Description |
|---|---|---|
| STARTER | `none` | Pas d'escalade |
| PRO | `client_team` | → "Votre équipe" |
| AUTOPILOT_ASSISTED | `client_team` | → "Votre équipe" |
| AUTOPILOT | `keybuzz_team` | → "KeyBuzz" |
| ENTERPRISE | `keybuzz_team` | → "KeyBuzz" |

### Chaîne d'escalade

| Couche | Source | Comportement actuel | Gap | Linear |
|---|---|---|---|---|
| Bouton Escalader | `EscalationPanel.tsx` | Visible, sélecteur raison | OK | — |
| Statut escalade | API conversation | `none`/`escalated`/`resolved` | OK | — |
| Cible escalade | `planCapabilities.ts` | `none`/`client_team`/`keybuzz_team` | OK | — |
| Affichage cible | `EscalationPanel.tsx` | "Votre équipe" / "KeyBuzz" / "Les deux" | OK | — |
| Assignation post-escalade | `AssignmentPanel.tsx` | Manuelle ("Prendre") | **GAP** : pas d'auto-assignation | KEY-255 |
| Agent KeyBuzz entitlement | `AutopilotSection.tsx` | Addon requis (AUTOPILOT + addon) | OK | — |
| Agent KeyBuzz disponibilité | Non implémenté | Aucune équipe humaine KeyBuzz documentée | **GAP CRITIQUE** | KEY-AP.2 |
| Notification escalade | Non trouvé | Pas de notification agent on-escalate | **GAP** | KEY-255 |
| Journal IA escalade | `ai-journal/page.tsx` | Actions tracées mais pas d'entrée "escalade" dédiée | **GAP** | KEY-255 |

### Gaps escalade identifiés

1. **Pas d'assignation automatique** : quand une conversation est escaladée, elle reste "Non assignée". L'agent doit manuellement "Prendre" la conversation.
2. **Pas de notification** : aucun agent n'est notifié quand une escalade arrive.
3. **Agent KeyBuzz** : `keybuzz_team` est configuré comme cible pour AUTOPILOT/ENTERPRISE mais aucune équipe humaine KeyBuzz n'existe en réalité (cf. audit AP).
4. **Journal IA** : pas d'entrée "escalade" spécifique dans le journal.

---

## Validation statique

- ✅ TypeScript — pas d'erreurs de type dans le patch
- ✅ No hardcode — aucun tenant/user/email/marketplace hardcodé
- ✅ No secrets — aucun secret exposé
- ✅ No tracking/billing/CAPI drift — aucune modification tracking
- ✅ Seller-first préservé — aucune modification des guardrails
- ✅ Platform-aware préservé — aucune modification des postures

---

## Build DEV

**Non réalisé dans cette phase.** Le fix est un changement client uniquement (`AISuggestionSlideOver.tsx`). Le build nécessite :
1. Commit + push sur la branche client
2. Build Docker depuis le bastion
3. Deploy K8s

**Tag proposé** : `v3.5.163-ai-no-reask-fix-dev`

**Rollback** : `v3.5.162-amazon-inbound-guide-demo-gating-dev`

---

## Tickets Linear

### KEY-256 — No-reask (mise à jour)

- **Statut** : Fix client appliqué (en attente de build DEV)
- **Fix** : `orderRef` toujours inclus dans contexte IA + instruction anti-reask explicite
- **Couverture** : Aide IA (inbox), Retry
- **Gaps restants** :
  - Brouillon IA Autopilot (backend-side) — à vérifier si le backend résout correctement
  - Tracking code non inclus dans le contexte IA inbox
  - AIDecisionPanel ne passe pas de contexte commande

### KEY-255 — Escalade (mise à jour)

- **Statut** : Audité, gaps identifiés
- **Gaps** :
  - Pas d'assignation automatique post-escalade
  - Pas de notification agent on-escalate
  - Agent KeyBuzz = cible configurée mais équipe inexistante
  - Journal IA sans entrée escalade dédiée
- **Action** : Phase dédiée recommandée (PH-AP.1B ou similaire)

### Tickets à créer

| Titre | Priorité | Pourquoi |
|---|---|---|
| **AP.1.1 — Backend no-reask : enrichir /ai/assist avec order+tracking depuis conversationId** | P1 | Le client passe maintenant orderRef, mais le backend devrait aussi résoudre tracking/order data depuis la DB pour le prompt | 
| **AP.1.2 — Escalade auto-assignation + notification** | P2 | Post-escalade, la conversation reste "Non assignée" sans notification |
| **AP.1.3 — Tracking code dans contexte IA inbox** | P1 | Le tracking n'est jamais injecté dans le prompt IA depuis l'inbox |

---

## Confirmation PROD inchangée

- 0 code modifié côté PROD
- 0 build PROD
- 0 deploy PROD
- 0 mutation DB
- 0 mutation Stripe/billing/CAPI/tracking
- 0 manifest PROD modifié
- Runtimes PROD identiques au preflight

---

## Verdict

### GO PARTIEL — BUILD DEV REQUIRED + ESCALATION ROADMAP REQUIRED

**Accompli** :
- ✅ Matrice complète plan × chemin IA
- ✅ Matrice no-reask par plan et chemin
- ✅ Matrice gating IA par plan
- ✅ Screenshot Ludovic reproduit et cause identifiée
- ✅ Fix no-reask client appliqué (`AISuggestionSlideOver.tsx`)
- ✅ Starter gating vérifié (correct par design)
- ✅ Escalade cartographiée avec gaps Linear
- ✅ PROD inchangée

**En attente** :
- ⏳ Build DEV du fix client (nécessite bastion)
- ⏳ Vérification backend no-reask via Autopilot draft
- ⏳ Phase dédiée escalade (assignation auto, notifications, Agent KeyBuzz)

**AI MESSAGING PLAN GATES AND NO-REASK TRUTH ESTABLISHED — STARTER IA ACCESS GUARDED BY KBACTIONS WALLET — KNOWN ORDER DATA NOW ALWAYS INJECTED IN AIDE IA CONTEXT — NO-REASK INSTRUCTION ADDED — ESCALATION PATH MAPPED — GAPS TRACKED IN LINEAR — SELLER-FIRST PLATFORM-AWARE GUARDRAILS PRESERVED — NO AUTO-SEND — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED**
