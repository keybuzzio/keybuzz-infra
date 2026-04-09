# PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01 — Verite Documentaire

> Date : 1er mars 2026
> Agent : Cursor Executor
> Environnement : DEV uniquement
> Phase : PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01

---

## 1. Sources de verite consultees

| Document | Derniere MAJ | Localisation |
|----------|-------------|-------------|
| PH-PLAYBOOKS-TRUTH-RECOVERY-01-REPORT.md | 1 mars 2026 | `keybuzz-infra/docs/` |
| PH-PLAYBOOKS-TRUTH-RECOVERY-01-AUDIT.md | 1 mars 2026 | `keybuzz-infra/docs/` |
| PROMPT-NOUVEL-AGENT.md | 27 mars 2026 | `keybuzz-infra/docs/` |
| RECAPITULATIF PHASES.md | 27 mars 2026 | `keybuzz-infra/docs/` |
| keybuzz-v3-context.mdc (.cursor/rules) | 28 fev 2026 | `.cursor/rules/` |
| Code source live (client + API bastion) | 1 mars 2026 | Git + bastion |
| DB DEV (tables ai_rules, etc.) | 1 mars 2026 | `10.0.0.10:5432` / `keybuzz` |

---

## 2. Verite documentaire actuelle

### Ce que disent les documents

**PH-PLAYBOOKS-TRUTH-RECOVERY-01-REPORT.md** :
- "Fix 100% client-side (4 fichiers UI uniquement)"
- "Impact API : Aucun"
- "Impact DB : Aucun"

**PH-PLAYBOOKS-TRUTH-RECOVERY-01-AUDIT.md** :
- "100% localStorage (client-side)"
- "Table DB | NON | Aucune table `playbooks` en DB"
- "API Fastify | NON | Aucun endpoint `/playbooks` cote API"
- "Routes BFF | EXISTANTES mais INUTILISEES"

**keybuzz-v3-context.mdc** (section dette technique) :
- "D25 : Simulateur playbooks client-side uniquement | Feature marketing sans backend reel"

**PROMPT-NOUVEL-AGENT.md** (section 3, Playbooks) :
- Non mentionne comme ayant un backend

---

## 3. CONTRADICTION MAJEURE IDENTIFIEE

### La realite technique contredit CHAQUE affirmation documentaire ci-dessus.

| Affirmation documentaire | Realite verifiee | Verdict |
|-------------------------|------------------|---------|
| "Aucune table `playbooks` en DB" | **4 tables existent** : `ai_rules`, `ai_rule_conditions`, `ai_rule_actions`, `playbook_suggestions` | **FAUX** |
| "Aucun endpoint `/playbooks` cote API" | **API Fastify a un module complet** : `src/modules/playbooks/routes.ts` avec CRUD + suggestions + toggle, enregistre dans `app.ts` sous `/playbooks` | **FAUX** |
| "100% localStorage" | **NON** — la page `/playbooks` est localStorage, MAIS le moteur de suggestions inbox utilise le backend (DB), et le seed se fait cote API au moment de la creation du tenant | **PARTIELLEMENT FAUX** |
| "Impact API : Aucun" | L'API a un module playbooks complet avec 15 starters differents des 5 du client | **VERITE INCOMPLETE** |
| "D25 : sans backend reel" | Le backend EXISTE, il est deploye, les tables sont remplies (15 rules/tenant, 7 tenants = 105 rules en DB) | **OBSOLETE** |

### Resume de la contradiction

**Deux systemes paralleles coexistent sans le savoir :**

1. **Systeme CLIENT (localStorage)** — utilise par la page `/playbooks`
   - 5 starters (delivery_delay, tracking_request, damaged_item, supplier_escalation, unanswered_2h)
   - IDs : `pb-starter-1` a `pb-starter-5`
   - Status : `enabled: true` (sauf supplier_escalation)
   - Persistance : `localStorage` cle `kb_client_playbooks:v1:<tenantId>`

2. **Systeme BACKEND (DB)** — utilise par l'inbox et le seed tenant
   - 15 starters (ou_est_ma_commande, suivi_indisponible, retard, retour, client_agressif, paiement_refuse, produit_defectueux, mauvaise_description, facture, annulation, incompatible, hors_sujet, client_vip, sans_reponse, escalade)
   - IDs : `pb-<timestamp>-<random>` (generes dynamiquement)
   - Status : tous `disabled` + `is_starter: true`
   - Tables DB : `ai_rules` + `ai_rule_conditions` + `ai_rule_actions`
   - Moteur d'evaluation : `playbook-engine.service.ts` avec detection par keywords + synonyms + regex
   - Service de seed : `playbook-seed.service.ts` appele dans `tenant-context-routes.ts`

---

## 4. Verite business sur le gating par plan

| Plan | `hasBasicPlaybooks` | `hasAdvancedPlaybooks` | `canAutoExecute` | Page accessible | Suggestion inbox |
|------|--------------------|-----------------------|------------------|----------------|-----------------|
| STARTER | `true` | `false` | `false` | OUI (pas de FeatureGate) | NON (FeatureGate PRO) |
| PRO | `true` | `true` | `false` | OUI | OUI |
| AUTOPILOT | `true` | `true` | `true` | OUI | OUI |
| ENTERPRISE | `true` | `true` | `true` | OUI | OUI |

**Coherence business :**
- La page `/playbooks` n'a PAS de `FeatureGate` → accessible a TOUS les plans
- C'est COHERENT avec `hasBasicPlaybooks: true` pour tous les plans
- Le `PlaybookSuggestionBanner` dans InboxTripane est gate par `requiredPlan="PRO"` → COHERENT avec `hasAdvancedPlaybooks` PRO+
- Le moteur autopilot utilise `computeKBActions('playbook_auto')` → COHERENT avec `canAutoExecute: true` pour AUTOPILOT+

**Verdict business : ALIGNED** — mais seulement si on considere la page client seule. La separation des 2 systemes cree une confusion pour l'utilisateur.

---

## 5. Existe-t-il une contradiction entre code live et documentation ?

**OUI — 3 contradictions majeures :**

1. **Contradiction 1** : La documentation dit "pas de backend playbooks" — le backend a un module complet deploye et actif
2. **Contradiction 2** : La page `/playbooks` affiche les 5 starters localStorage, mais l'inbox suggestions utilise les 15 starters DB — l'utilisateur voit des playbooks differents selon l'endroit
3. **Contradiction 3** : Le seed backend cree 15 playbooks `disabled` pour chaque tenant, mais l'utilisateur voit 5 playbooks `enabled` sur la page (venant de localStorage)

---

## 6. Impact sur la dette technique D25

La dette technique D25 stipule : "Simulateur playbooks client-side uniquement | Feature marketing sans backend reel".

**D25 est OBSOLETE.** Le backend existe et est fonctionnel. La vraie dette est :
- **La page `/playbooks` ignore le backend** alors que tout le reste l'utilise
- **Les 2 systemes ont des starters differents** (5 vs 15, noms differents, status differents)
- **Les modifications faites par l'utilisateur sur la page ne sont PAS synchronisees** avec le moteur de suggestions ni l'autopilot

La dette D25 devrait etre reclassee en :
> **D25-v2** : Page /playbooks desynchronisee du backend — les playbooks affiches et modifies par l'utilisateur ne sont PAS les memes que ceux utilises par le moteur IA inbox et l'autopilot

---

## CONCLUSION

La verite documentaire etablie par PH-PLAYBOOKS-TRUTH-RECOVERY-01 est **techniquement incorrecte**.
Le fix applique (passer `tenantIdOverride` dans `getPlaybooks()`) etait correct pour le probleme de tenantId null, mais l'audit sous-jacent a manque le fait que le backend a un systeme complet de playbooks qui coexiste en parallele.

La priorite n'est PAS un nouveau fix, mais une migration planifiee de la page `/playbooks` pour utiliser le backend existant au lieu de localStorage.
