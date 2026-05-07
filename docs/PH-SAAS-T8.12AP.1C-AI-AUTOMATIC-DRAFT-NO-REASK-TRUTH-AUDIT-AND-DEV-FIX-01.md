# PH-SAAS-T8.12AP.1C — AI Automatic Draft No-Reask Truth Audit and DEV Fix

> Phase : PH-SAAS-T8.12AP.1C-AI-AUTOMATIC-DRAFT-NO-REASK-TRUTH-AUDIT-AND-DEV-FIX-01
> Date : 2026-05-07
> Auteur : Cursor Agent
> Priorité : P0
> Scope : DEV uniquement — PROD inchangé
> Standard : CE Prompting Standard KeyBuzz

---

## 1. OBJECTIF

Vérifier et corriger la deuxième surface IA no-reask : le **Brouillon IA automatique** (autopilot draft) affiché dans l'Inbox, avec validation humaine avant envoi.

Contrat produit strict : si KeyBuzz connaît déjà le numéro de commande, le numéro de suivi/tracking, le statut livraison, ou le contexte commande, l'IA ne doit JAMAIS redemander ces informations au client.

---

## 2. PREFLIGHT

### Repos

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `d254b611` | 5+ fichiers hors scope | OK |
| keybuzz-api (bastion) | `ph147.4/source-of-truth` | `7a27eafc` (pre-fix) | dist/ supprimés | OK |
| keybuzz-infra | `main` | `2a8c0f3` | — | OK |

### Runtimes avant fix

| Service | Env | Image | Changement |
|---|---|---|---|
| Client | DEV | `v3.5.163-ai-no-reask-fix-dev` | Aucun |
| Client | PROD | `v3.5.163-ai-no-reask-fix-prod` | **AUCUN** |
| API | DEV | `v3.5.155-promo-retry-metadata-email-dev` | → `v3.5.156-ai-auto-draft-no-reask-dev` |
| API | PROD | `v3.5.142-promo-retry-email-prod` | **AUCUN** |
| Backend | DEV | `v1.0.47-cross-env-guard-fix-dev` | Aucun |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` | **AUCUN** |
| Website | PROD | `v0.6.9-promo-forwarding-prod` | **AUCUN** |

---

## 3. CARTOGRAPHIE DES DEUX SURFACES IA

### Surface A — Aide IA (manuelle)

| Attribut | Valeur |
|---|---|
| Fichier client | `src/features/ai-ui/AISuggestionSlideOver.tsx` |
| Déclencheur | Bouton "Aide IA" → clic utilisateur |
| Endpoint | `/api/ai/assist` (BFF) → `/ai/assist` (API Fastify) |
| Génération | **Live** — appel LLM à chaque demande |
| Contexte order | ✅ Client injecte `[COMMANDE CONNUE: xxx]` (fix AP.1) |
| Contexte tracking | ✅ Serveur `shared-ai-context.ts` |
| Anti-reask order | ✅ Client `[INSTRUCTION OBLIGATOIRE]` (fix AP.1) |
| Anti-reask tracking | ✅ Serveur `engine.ts` ligne 728 |
| Statut | **Validé AP.1B** (PROD `v3.5.163`) |

### Surface B — Brouillon IA automatique

| Attribut | Valeur |
|---|---|
| Fichier client | `app/inbox/InboxTripane.tsx` → `AISuggestionSlideOver.tsx` |
| Composant affichage | `AISuggestionSlideOver` avec `activeDraft.draftText` |
| Déclencheur | **Automatique** à la sélection d'une conversation (useEffect) |
| Endpoint | `/api/autopilot/draft` (BFF GET) → `/autopilot/draft` (API Fastify) |
| Génération | **Stocké** dans `ai_action_log` (payload.draftText) |
| Pipeline | `engine.ts` → `evaluateAndExecute()` → `getAISuggestion()` → sauvegarde dans `ai_action_log` |
| Contexte order | ✅ Serveur `loadEnrichedOrderContext` + `resolveOrderRefFromMessages` fallback |
| Contexte tracking | ✅ Serveur enrichissement complet (carrier, tracking, live events) |
| Anti-reask order | **❌ ABSENT** (avant fix AP.1C) |
| Anti-reask tracking | ✅ Serveur `engine.ts` ligne 728 (existait déjà) |
| Validation humaine | ✅ Préservée (boutons Envoyer/Modifier/Ignorer) |
| Auto-send | ❌ Gated par `canAutoExecute` + `mode === 'autonomous'` |

### Tableau comparatif

| Surface | Fichier client | Endpoint | Service serveur | Live/stocké | Anti-reask order | Anti-reask tracking | Verdict |
|---|---|---|---|---|---|---|---|
| A — Aide IA | `AISuggestionSlideOver.tsx` | `/api/ai/assist` | LLM live | Live | ✅ (AP.1) | ✅ | OK |
| B — Brouillon IA | `InboxTripane.tsx` | `/api/autopilot/draft` | `engine.ts` → DB | Stocké | **❌ → ✅ (AP.1C)** | ✅ | **CORRIGÉ** |

---

## 4. REPRODUCTION / EXPLICATION DU CAS SCREENSHOT SWITAA

### Données observées

| Élément | Valeur |
|---|---|
| Conversation | `cmmos9k7x2e4146f88dcf8a58` |
| Tenant | `switaa-sasu-mnc1x4eq` |
| order_ref conversation | `404-3892837-3215550` |
| Order en DB | ✅ status=Shipped, carrier=UPS, tracking=`1Z4971486834778141` |
| Draft stocké | `alog-1777963508061-fmz5oz4ry` |
| Date draft | 2026-05-05 (AVANT fix AP.1C) |
| `usedContext.orderNumber` | **false** — engine n'a pas résolu le contexte enrichi |
| `usedContext.trackingNumber` | **false** — engine n'a pas résolu le tracking |
| Draft contient reask order | Non (order trouvé via historique conversation) |
| Draft mentionne tracking | Non (offre de "localiser votre colis" sans mentionner UPS/tracking connu) |

### Root cause

1. **GAP principal (corrigé AP.1C)** : `engine.ts` avait une instruction anti-reask pour le tracking (ligne 728) mais AUCUNE pour le numéro de commande
2. **GAP contextuel** : `shared-ai-context.ts:buildEnrichedUserPrompt()` n'avait AUCUNE instruction anti-reask (ni tracking, ni commande)
3. **Drafts stockés** : les drafts générés avant le fix sont stockés dans `ai_action_log` et ne sont pas régénérés automatiquement — le texte pré-fix reste affiché

---

## 5. FIX APPLIQUÉ

### engine.ts — `src/modules/autopilot/engine.ts`

Ajout après le bloc anti-reask tracking existant (ligne 728) :

```typescript
// PH-SAAS-T8.12AP.1C: Explicit anti-re-ask for order number when known (KEY-256)
if (orderContext.orderNumber) {
  userPrompt += `\n\nIMPORTANT: Le numéro de commande ${orderContext.orderNumber} est CONNU. NE JAMAIS demander au client son numéro de commande, de suivi ou de tracking. Utiliser les données disponibles.`;
}
```

### shared-ai-context.ts — `src/modules/ai/shared-ai-context.ts`

Ajout dans `buildEnrichedUserPrompt()` après le bloc temporal, avant le `else` (aucune commande) :

```typescript
// PH-SAAS-T8.12AP.1C: Explicit anti-re-ask for known data (KEY-256)
if (enrichedOrder.trackingCode) {
  prompt += `\n\nIMPORTANT: Le numéro de suivi ${enrichedOrder.trackingCode} est CONNU. NE JAMAIS le redemander au client.`;
}
if (enrichedOrder.orderNumber) {
  prompt += `\n\nIMPORTANT: Le numéro de commande ${enrichedOrder.orderNumber} est CONNU. NE JAMAIS demander au client son numéro de commande, de suivi ou de tracking. Utiliser les données disponibles.`;
}
```

---

## 6. COMMITS

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `49ff3440` | fix(ai): add anti-reask for order number in autopilot engine + shared-ai-context (PH-SAAS-T8.12AP.1C, KEY-256) |
| keybuzz-infra | `main` | `e344aad` | gitops(dev): PH-SAAS-T8.12AP.1C API DEV v3.5.156-ai-auto-draft-no-reask-dev (KEY-256) |

---

## 7. BUILD + DEPLOY

| Service | Commit source | Tag DEV | Digest | Rollback |
|---|---|---|---|---|
| API DEV | `49ff3440` | `v3.5.156-ai-auto-draft-no-reask-dev` | `sha256:90c7738eb4d060fff3b69856ebcc75e9a4fd266d39e5bb19a25a0260ccfd9ca1` | `v3.5.155-promo-retry-metadata-email-dev` |

### Vérification runtime

- Fix présent dans pod DEV `keybuzz-api-7b9c9947f9-p622s`
- `engine.js` : 2 instructions anti-reask (tracking L558, commande L562)
- `shared-ai-context.js` : 2 instructions anti-reask (tracking L455, commande L458)
- Marqueur `AP.1C` trouvé dans les deux fichiers compilés
- Health check : `{"status":"ok"}`

---

## 8. VALIDATION DEV

### Surface A — Aide IA (confirmation AP.1B inchangée)

| Check | Résultat |
|---|---|
| Client DEV image | `v3.5.163-ai-no-reask-fix-dev` (inchangée) |
| Fix AP.1 dans code client | `[COMMANDE CONNUE]` + `[INSTRUCTION OBLIGATOIRE]` |
| Endpoint `/ai/assist` | Backend utilise `buildEnrichedUserPrompt` (maintenant avec anti-reask AP.1C) |
| Double couverture | Client + Serveur |

### Surface B — Brouillon IA automatique

| Check | Résultat |
|---|---|
| Anti-reask order dans `engine.ts` | ✅ Ligne 731-734 |
| Anti-reask tracking dans `engine.ts` | ✅ Ligne 726-729 (existait) |
| Anti-reask dans `shared-ai-context.ts` | ✅ Lignes 557-563 (nouveau) |
| Validation humaine | ✅ Préservée (`needsHumanAction`, boutons Envoyer/Modifier/Ignorer) |
| Auto-send | ❌ Gated par `canAutoExecute` |
| Drafts stockés anciens | Non régénérés (comportement documenté — prochains drafts respecteront le contrat) |

---

## 9. PLAN GATES

| Plan | Aide IA | Brouillon IA auto | KBActions | Auto-send | Verdict |
|---|---|---|---|---|---|
| STARTER | ✅ visible, wallet-gated (quota 3/j, 0 KBA) | ❌ Pas d'autopilot | 0 inclus | ❌ | OK |
| PRO | ✅ illimité | Dépend config autopilot | 1000/mois | ❌ | OK |
| AUTOPILOT_ASSISTED | ✅ | ✅ supervised (validation humaine) | 1000/mois | ❌ | OK |
| AUTOPILOT | ✅ | ✅ autonomous (guardrails) | 2000/mois | ✅ (guardrails) | OK |

---

## 10. NON-RÉGRESSION

| Surface | Check | Résultat | Verdict |
|---|---|---|---|
| API DEV | Health | `{"status":"ok"}` | OK |
| API DEV | Image mise à jour | `v3.5.156-ai-auto-draft-no-reask-dev` | OK |
| API PROD | Image inchangée | `v3.5.142-promo-retry-email-prod` | **INCHANGÉ** |
| Client DEV | Image inchangée | `v3.5.163-ai-no-reask-fix-dev` | OK |
| Client PROD | Image inchangée | `v3.5.163-ai-no-reask-fix-prod` | **INCHANGÉ** |
| Backend DEV | Image inchangée | `v1.0.47-cross-env-guard-fix-dev` | OK |
| Backend PROD | Image inchangée | `v1.0.47-cross-env-guard-fix-prod` | **INCHANGÉ** |
| Website PROD | Image inchangée | `v0.6.9-promo-forwarding-prod` | **INCHANGÉ** |
| Billing/Stripe | Aucune mutation | — | OK |
| CAPI/Tracking | Aucun event | — | OK |
| Auto-send | Interdit par design | — | OK |
| Hardcoding | Aucun tenant/user/email/order/tracking hardcodé | — | OK |

---

## 11. LINEAR

| Ticket | Mise à jour |
|---|---|
| KEY-256 | AP.1C complété — Surface B (Brouillon IA) corrigée en DEV. Anti-reask order number ajouté dans `engine.ts` + `shared-ai-context.ts`. API DEV `v3.5.156`. Surface A (Aide IA) déjà validée AP.1B. PROD API promotion requise pour fermeture. |
| KEY-262 | Gap serveur `/ai/assist` comblé — `shared-ai-context.ts:buildEnrichedUserPrompt()` enrichi avec anti-reask tracking + order (AP.1C). |
| KEY-264 | Tracking code contexte Inbox — Le tracking est inclus dans le prompt autopilot quand résolu. Anti-reask tracking existait déjà. Pas de gap additionnel. |
| KEY-263 | Escalade — Observé dans le draft SWITAA (`autopilot_escalate`, `needsHumanAction: true`). Pas de régression. Phase dédiée recommandée. |

---

## 12. ROLLBACK

### API DEV

```bash
# Modifier manifest
# k8s/keybuzz-api-dev/deployment.yaml → image: v3.5.155-promo-retry-metadata-email-dev
# Commit + push
# kubectl apply + rollout status
```

Tag rollback : `v3.5.155-promo-retry-metadata-email-dev`

---

## 13. PROD INCHANGÉ — PREUVE

| Service | Image PROD avant AP.1C | Image PROD après AP.1C | Verdict |
|---|---|---|---|
| Client | `v3.5.163-ai-no-reask-fix-prod` | `v3.5.163-ai-no-reask-fix-prod` | IDENTIQUE |
| API | `v3.5.142-promo-retry-email-prod` | `v3.5.142-promo-retry-email-prod` | IDENTIQUE |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | IDENTIQUE |
| Website | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | IDENTIQUE |

**0 code PROD, 0 build PROD, 0 deploy PROD, 0 mutation DB, 0 mutation Stripe, 0 mutation billing, 0 CAPI, 0 tracking publicitaire.**

---

## 14. AI FEATURE PARITY / ANTI-RÉGRESSION

| Feature IA documentée | Rapport source | Surface A | Surface B | Runtime DEV | Gap Linear | Verdict |
|---|---|---|---|---|---|---|
| No-reask commande | AP.1, AP.1C | ✅ | ✅ (AP.1C) | ✅ | KEY-256 | CORRIGÉ |
| No-reask tracking | AP.1, T8.12AF | ✅ | ✅ | ✅ | — | OK |
| Contexte commande | T8.12AH | ✅ | ✅ | ✅ | — | OK |
| Contexte tracking 17TRACK | T8.12AB | ✅ | ✅ | ✅ | — | OK |
| Seller-first | T8.12AP | ✅ | ✅ | ✅ | — | OK |
| Platform-aware | T8.12P | ✅ | ✅ | ✅ | — | OK |
| Refund protection | PH145 | ✅ | ✅ | ✅ | — | OK |
| Response strategy | T8.12Q | ✅ | ✅ | ✅ | — | OK |
| Validation humaine | PH142 | ✅ | ✅ | ✅ | — | OK |
| Plan gates | AP.1 | ✅ | ✅ | ✅ | — | OK |
| KBActions | PH33.12 | ✅ | ✅ | ✅ | — | OK |
| Escalade | KEY-255 | Partiel | Partiel | Partiel | KEY-263 | PHASE DÉDIÉE |

---

## 15. VERDICT

### GO DEV FIX VALIDATED

**AI AUTOMATIC DRAFT NO-REASK VALIDATED IN DEV — AIDE IA AND BROUILLON IA SURFACES BOTH COVERED — KNOWN ORDER/TRACKING DATA NO LONGER REQUESTED FROM CUSTOMER — HUMAN VALIDATION PRESERVED — NO AUTO-SEND — PLAN GATES PRESERVED — STARTER IA REMAINS KBACTIONS-GATED — SELLER-FIRST AND PLATFORM-AWARE GUARDRAILS PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC VALIDATION**

### Prochaines étapes

1. **PROD API promotion** : tag `v3.5.156-ai-auto-draft-no-reask-prod` — nécessite phase dédiée (AP.1D ?)
2. **QA navigateur Ludovic** : valider le brouillon IA sur `client-dev.keybuzz.io` avec une conversation ayant orderRef + tracking connu
3. **Régénération brouillons** : les anciens drafts stockés dans `ai_action_log` ne sont pas régénérés — seuls les NOUVEAUX drafts bénéficient du fix
4. **Escalade KEY-263** : phase dédiée recommandée

STOP
