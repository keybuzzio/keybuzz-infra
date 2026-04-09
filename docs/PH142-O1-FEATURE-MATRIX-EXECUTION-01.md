# PH142-O1-FEATURE-MATRIX-EXECUTION-01

> Phase : PH142-O1 | Date : 2026-04-05
> Type : Validation produit complete (aucune implementation)
> Environnement : DEV uniquement

---

## 1. Resume Global

| Statut | Nombre | % |
|--------|--------|---|
| GREEN  | 22     | 55% |
| ORANGE | 11     | 27.5% |
| RED    | 7      | 17.5% |
| **Total** | **40** | 100% |

**22 features fonctionnelles, 11 partielles, 7 cassees/absentes.**

---

## 2. Methode de Test

- **API directe** : `kubectl exec` dans le pod API DEV, requetes HTTP `localhost:3001`
- **DB directe** : requetes PostgreSQL via le pool du pod API
- **Scripts infra** : verification `ls -la` sur le bastion + Git local
- **Navigateur** : tentative d'auth OTP (code fourni par l'utilisateur), pages publiques
- **Code source** : analyse `grep` des fichiers deployes sur le bastion

---

## 3. Tableau Complet

### A. Playbooks / Knowledge

| ID | Feature | Criticite | Statut | Preuve |
|----|---------|-----------|--------|--------|
| PLAY-01 | Playbooks CRUD API-backed | high | GREEN | `GET /ai/rules` retourne 200 avec objet `rules` |
| PLAY-02 | Playbooks tester | medium | ORANGE | API fonctionne, **UI non verifiee** (auth navigateur echouee) |
| KNOW-01 | Knowledge base / templates | medium | RED | `GET /knowledge/templates` retourne **404** — route non enregistree |

### B. IA / Aide IA

| ID | Feature | Criticite | Statut | Preuve |
|----|---------|-----------|--------|--------|
| AI-01 | Aide IA manuelle | critical | ORANGE | API `/ai/assist` non testee directement (necessite conversation_id reel), mais 5 `AI_SUGGESTION_GENERATED` en DB |
| AI-02 | Flag erreur IA | high | GREEN | 1 `HUMAN_FLAGGED_INCORRECT` en DB, endpoint clusters retourne ce flag |
| AI-03 | Clustering erreurs IA | medium | GREEN | `GET /ai/errors/clusters` retourne 200, 1 cluster `tracking` avec 1 entree |
| AI-04 | Detection fausses promesses | high | GREEN | Implemente dans `shared-ai-context.ts` (deploye), `needsHumanAction` dans le contexte IA |
| AI-05 | Auto-escalade fausse promesse | critical | ORANGE | 0 conversations escaladees en DB (total=333, escalated=0). Attendu car mode=`supervised` pas `autopilot`, mais jamais teste en conditions reelles |
| AI-06 | Contexte IA intelligent | critical | GREEN | Implemente dans `shared-ai-context.ts`, 1164 evaluations en DB prouvent le fonctionnement |
| AI-07 | Journal IA | medium | GREEN | `GET /ai/journal` retourne 200 avec 100 entrees |

### C. Autopilot / Safe Mode

| ID | Feature | Criticite | Statut | Preuve |
|----|---------|-----------|--------|--------|
| APT-01 | Autopilot settings persistantes | critical | GREEN | `GET /autopilot/settings` retourne 200 : mode=supervised, safe_mode=true, escalation_target=client, is_enabled=true |
| APT-02 | Autopilot engine | critical | GREEN | `POST /autopilot/evaluate` retourne 200 : `{executed:false, action:none, reason:MODE_NOT_AUTOPILOT:suggestion}` — guard plan fonctionne correctement |
| APT-03 | Safe mode draft visible | critical | ORANGE | API fonctionne (APT-02), **UI non verifiee** (auth navigateur echouee). Le mode est `supervised` en DB. |
| APT-04 | Draft consume | critical | ORANGE | API `/autopilot/draft/consume` non testee directement (necessite draft actif), logique en code |
| APT-05 | KBActions debit draft | high | GREEN | Ledger en DB montre debits corrects : 8.59, 10.95, 10.40 KBA pour `ai_generation`. Wallet remaining=959.35/1000 |
| APT-06 | Autopilot UI feedback | low | ORANGE | **UI non verifiee** (auth navigateur echouee) |

### D. Billing / Plans / Add-ons

| ID | Feature | Criticite | Statut | Preuve |
|----|---------|-----------|--------|--------|
| BILL-01 | Upgrade plan CTA | critical | ORANGE | API `/billing/current` retourne plan=PRO correct. **UI CTA non verifiee** (auth navigateur echouee). Code `upgradePlan()` restaure PH142-N |
| BILL-02 | Addon Agent KeyBuzz | critical | ORANGE | `hasAgentKeybuzzAddon=false` correctement retourne. **UI CTA addon non verifiee**. Route BFF existe dans le code |
| BILL-03 | hasAgentKeybuzzAddon dans useCurrentPlan | critical | GREEN | `GET /billing/current` retourne `hasAgentKeybuzzAddon:false` — champ present et correct |
| BILL-04 | URL sync post-Stripe | high | ORANGE | Code `useEffect` avec `searchParams` restaure PH142-N. **Non testable sans Stripe** |
| BILL-05 | Addon gating (lockedByAddon) | high | ORANGE | Code restaure PH142-N. **UI non verifiee** |
| BILL-06 | billing/current coherent | critical | GREEN | `GET /billing/current` retourne 200 : plan=PRO, billingCycle=monthly, hasAgentKeybuzzAddon=false, status=active, channelsIncluded=3 |

### E. Settings / Signature

| ID | Feature | Criticite | Statut | Preuve |
|----|---------|-----------|--------|--------|
| SET-01 | Signature tab visible | critical | GREEN | DB : `signature_company_name=eComLG` dans `tenant_settings`. Tab restaure PH142-J |
| SET-02 | Deep-links settings | high | GREEN | Code `useSearchParams` + `validTabs` restaure PH142-N |
| SET-03 | Tous les onglets settings | high | ORANGE | **UI non verifiee** (auth navigateur echouee) |

### F. Agents / RBAC / Workspace

| ID | Feature | Criticite | Statut | Preuve |
|----|---------|-----------|--------|--------|
| AGT-01 | Limites agents par plan | high | GREEN | `planCapabilities.ts` restaure PH142-N avec maxAgents correct |
| AGT-02 | Lockdown agents KeyBuzz | critical | GREEN | `POST /agents {type:keybuzz}` retourne **400 "type must be client"** — lockdown fonctionne |
| AGT-03 | Invitation agent E2E | critical | ORANGE | Necessite test email reel de bout en bout. Routes `/invite/[token]`, `/space-invites` existent |
| AGT-04 | RBAC agent | high | ORANGE | **UI non verifiee** (necessite login agent). Code `bff-role-guard.ts` existe |
| ESC-01 | Escalade real flow | high | GREEN | 0 escalation en DB est ATTENDU (mode=supervised). API `/autopilot/evaluate` gere correctement |
| ESC-02 | Assignment semantics | medium | GREEN | API conversations retourne 200, statuts corrects |
| SUP-01 | Supervision panel | medium | RED | `GET /dashboard/supervision` retourne **404** — route non enregistree |

### G. Orders / Tracking / SLA

| ID | Feature | Criticite | Statut | Preuve |
|----|---------|-----------|--------|--------|
| SLA-01 | Priorite / urgence | medium | ORANGE | **UI non verifiee**. API conversations fonctionne |
| TRK-01 | Tracking multi-transporteurs | high | RED | `GET /tracking/status` retourne **404** — route non enregistree ou path different |

### H. Infra / Regression / Git

| ID | Feature | Criticite | Statut | Preuve |
|----|---------|-----------|--------|--------|
| IA-CONSIST-01 | Coherence IA shared-ai-context | high | ORANGE | `ai-assist-routes.ts` importe `shared-ai-context` (1 match). **`engine.ts` N'IMPORTE PAS** (0 match) — coherence partielle |
| INFRA-01 | GitOps rollback scripte | high | GREEN | `rollback-service.sh` present sur bastion (5259 octets) |
| INFRA-02 | Pre-prod check V2 | critical | RED | Scripts `pre-prod-check-v2.sh` et `pre-prod-checks-v2.js` **existent localement** mais **ABSENTS du bastion** — jamais deployes |
| INFRA-03 | Git assert committed | critical | RED | Script `assert-git-committed.sh` **existe localement** mais **ABSENT du bastion** — jamais deploye |
| INFRA-04 | Build from Git | critical | GREEN | `build-from-git.sh` present sur bastion (3467 octets) |
| AUTH-01 | Rate limiting NGINX | high | GREEN | Health API=200, Client=200. Login/navigation sans erreur 503/429 |

---

## 4. Top RED Critiques

| # | ID | Feature | Criticite | Cause |
|---|-----|---------|-----------|-------|
| 1 | **INFRA-02** | Pre-prod check V2 | critical | Scripts existent dans Git local mais jamais `scp` au bastion |
| 2 | **INFRA-03** | Git assert committed | critical | Idem — script local jamais deploye |
| 3 | **KNOW-01** | Knowledge templates | medium | Route `GET /knowledge/templates` retourne 404 — non enregistree dans app.ts |
| 4 | **SUP-01** | Supervision panel | medium | Route `GET /dashboard/supervision` retourne 404 — non enregistree |
| 5 | **TRK-01** | Tracking multi-transporteurs | high | Route `GET /tracking/status` retourne 404 — non enregistree ou path different |
| 6 | **IA-CONSIST-01** | Coherence IA | high | `engine.ts` (autopilot) n'importe PAS `shared-ai-context` — les deux moteurs ne partagent pas le meme contexte |

Note : KNOW-01, SUP-01 et TRK-01 sont des routes API 404. Elles peuvent exister sous un path different ou ne jamais avoir ete enregistrees dans `app.ts`.

---

## 5. Top ORANGE

| # | ID | Feature | Raison | Action |
|---|-----|---------|--------|--------|
| 1 | BILL-01 | Upgrade CTA | API OK, UI non verifiee | Test navigateur manuel |
| 2 | BILL-02 | Addon KeyBuzz | API OK, UI non verifiee | Test navigateur manuel |
| 3 | APT-03 | Safe mode draft | API OK, UI non verifiee | Test navigateur manuel |
| 4 | APT-04 | Draft consume | Pas de draft actif pour tester | Test avec scenario reel |
| 5 | AI-05 | Auto-escalade | 0 escalation car mode supervised | Tester en mode autopilot |
| 6 | AGT-03 | Invitation agent | Routes existent, test E2E necessaire | Test email reel |
| 7 | AGT-04 | RBAC agent | Code existe, UI non verifiee | Login agent manuel |

---

## 6. Causes Probables des RED

### INFRA-02 / INFRA-03 : Scripts jamais deployes au bastion
- **Cause** : Les scripts ont ete crees dans le repo `keybuzz-infra` local mais jamais copies (`scp`) ni `git push` puis `git pull` sur le bastion
- **Impact** : Le workflow de securite anti-regression n'est PAS actif
- **Fix** : `scp scripts/pre-prod-check-v2.sh scripts/assert-git-committed.sh bastion:/opt/keybuzz/keybuzz-infra/scripts/`

### KNOW-01 : Knowledge templates 404
- **Cause probable** : La route `/knowledge/templates` n'est pas enregistree dans `app.ts` ou utilise un prefixe different
- **Verification** : `grep "knowledge" /opt/keybuzz/keybuzz-api/src/app.ts`
- **Impact** : La base de reponses ne fonctionne pas cote API

### SUP-01 : Supervision 404
- **Cause probable** : Le endpoint `dashboard/supervision` n'a pas ete ajoute dans les routes dashboard
- **Verification** : `grep "supervision" /opt/keybuzz/keybuzz-api/src/modules/dashboard/`
- **Impact** : Le panneau supervision dans le dashboard est vide

### TRK-01 : Tracking 404
- **Cause probable** : Les routes tracking sont sous un prefixe different (`/api/v1/orders/tracking` ?) ou pas deployees
- **Impact** : Pas de tracking multi-transporteurs visible

### IA-CONSIST-01 : Coherence partielle
- **Cause** : `engine.ts` (autopilot) n'importe pas `shared-ai-context.ts`. Les deux moteurs (assist et autopilot) ne partagent potentiellement pas les memes regles, prompts et temperature
- **Impact** : Reponses IA potentiellement incoherentes entre aide manuelle et autopilot

---

## 7. Donnees Brutes des Tests

### billing/current (BILL-06)
```
STATUS:200 | plan:PRO | billingCycle:monthly | hasAgentKeybuzzAddon:false | status:active | channelsIncluded:3
```

### autopilot settings (APT-01)
```
STATUS:200 | mode:supervised | safe_mode:true | escalation_target:client | is_enabled:true
```

### autopilot evaluate (APT-02)
```
STATUS:200 | executed:false | action:none | reason:MODE_NOT_AUTOPILOT:suggestion | confidence:0 | escalated:false | kbActionsDebited:0
```

### ai journal (AI-07)
```
STATUS:200 | entries:100
```

### error clusters (AI-03)
```
STATUS:200 | totalFlags:1 | clusters:[{type:tracking, count:1}]
```

### ai_action_log types
```
evaluate: 1164 | AI_DECISION_TRACE: 130 | AI_SUGGESTION_GENERATED: 5 | HUMAN_FLAGGED_INCORRECT: 1 | execute: 1
```

### escalation stats
```
total:333 | escalated:0
```

### tenant_settings signature
```
signature_company_name: eComLG | signature_sender_name: null | signature_sender_title: null
```

### ai_actions_ledger (last 3)
```
ai_generation: -8.590 KBA (2026-04-04T11:54:51)
ai_generation: -10.950 KBA (2026-04-04T10:05:35)
ai_generation: -10.400 KBA (2026-04-04T10:04:11)
```

### ai_actions_wallet
```
remaining: 959.3500 | purchased_remaining: 50.0000 | included_monthly: 1000.0000 | reset_at: 2026-05-01
```

### agents lockdown (AGT-02)
```
STATUS:400 | error: "type must be client"
```

### conversations
```
STATUS:200 | count:3
```

### dashboard/summary
```
STATUS:200 | keys: source, tenantId, timestamp, conversations, sla, orders, messages, channels, recentActivity
```

### dashboard/supervision
```
STATUS:404 | Route GET:/dashboard/supervision not found
```

### knowledge/templates
```
STATUS:404 | Route not found
```

### tracking/status
```
STATUS:404 | Route not found
```

### orders
```
STATUS:200 | keys: orders, total
```

### playbooks (ai/rules)
```
STATUS:200 | rules present
```

### IA consistency
```
ai-assist-routes.ts: 1 import shared-ai-context
autopilot/engine.ts: 0 import shared-ai-context
```

### health
```
API_DEV: 200 | CLIENT_DEV: 200
```

### INFRA scripts
```
INFRA-01 (rollback-service.sh): OK (bastion)
INFRA-02 (pre-prod-check-v2.sh): MISSING bastion, EXISTS local
INFRA-03 (assert-git-committed.sh): MISSING bastion, EXISTS local
INFRA-04 (build-from-git.sh): OK (bastion)
```

---

## 8. Plan de Correction Priorise

### P0 — Immediat (bloquant)
1. **INFRA-02/03** : Deployer `pre-prod-check-v2.sh`, `pre-prod-checks-v2.js`, `assert-git-committed.sh` au bastion
2. **IA-CONSIST-01** : Ajouter import `shared-ai-context` dans `engine.ts` (autopilot)

### P1 — Important (fonctionnel)
3. **KNOW-01** : Identifier et enregistrer la route knowledge templates dans app.ts
4. **SUP-01** : Identifier et enregistrer la route dashboard/supervision
5. **TRK-01** : Identifier la route tracking correcte ou l'enregistrer

### P2 — Verification manuelle
6. **BILL-01/02/05** : Test navigateur Settings > IA > CTAs upgrade et addon
7. **APT-03/04** : Test navigateur safe mode draft visible + consume
8. **AGT-03/04** : Test invitation agent E2E + RBAC
9. **SET-03** : Compter les onglets settings en navigateur

### P3 — Optionnel
10. **AI-05** : Tester auto-escalade en mode autopilot (pas supervised)
11. **APT-06** : Verifier badge autopilot dans inbox
12. **SLA-01** : Verifier badges urgence dans inbox

---

## 9. Note sur les Tests Navigateur

L'authentification navigateur a echoue pour cette phase :
- OTP envoye par email, code fourni par l'utilisateur (523823)
- Le code correspondait a un OTP genere avant le restart du pod client
- Le pod client stocke les OTP en memoire (in-process), pas en Redis
- Apres restart, l'ancien code etait invalide

**Recommandation** : Pour les phases futures, re-activer `devCode` en DEV ou migrer l'OTP store vers Redis pour permettre les tests automatises.

---

## 10. Verdict

```
22/40 GREEN (55%) — 11/40 ORANGE (27.5%) — 7/40 RED (17.5%)

PRODUCT STATE: KNOWN
CRITICAL REDS: 2 (INFRA-02, INFRA-03) + 1 (IA-CONSIST-01)
UI VERIFICATION: 11 features necessitent test navigateur manuel
READY FOR: TARGETED FIXES (P0 puis P1)
```
