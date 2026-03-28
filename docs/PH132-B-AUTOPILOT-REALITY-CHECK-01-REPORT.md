# PH132-B: AUTOPILOT REALITY CHECK — RAPPORT COMPLET

> Date : 2026-03-28
> Phase : PH132-B-AUTOPILOT-REALITY-CHECK-01
> Type : Audit systeme reel (aucune modification)
> Environnements audites : DEV + PROD

---

## VERDICT

**AUTOPILOT REALITY VERIFIED — ISSUES DETECTED — CORRECTIONS REQUISES AVANT NEXT PHASE**

Le moteur Autopilot est **fonctionnel en DEV** (escalation, status_change, safe_mode, low_confidence).
Cependant, **5 bugs/anomalies critiques** ont ete detectes et **0 auto-reply n'a jamais ete execute**.
Le moteur est **inactif en PROD** malgre une configuration active.

---

## 1. VERSIONS DEPLOYEES

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.51-playbooks-suggestions-live-dev` | `v3.5.51-playbooks-suggestions-live-prod` |
| Client | `v3.5.127-kba-checkout-fix-dev` | `v3.5.127-kba-checkout-fix-prod` |

---

## 2. ETAT D'ACTIVATION (Etape 1)

### Table `autopilot_settings` (separee de `ai_settings`)

**DEV (6 entrees) :**

| Tenant | Plan | is_enabled | mode | safe_mode | auto_reply | auto_assign | auto_escalate |
|--------|------|------------|------|-----------|------------|-------------|---------------|
| ecomlg-001 | PRO | true | supervised | true | false | false | false |
| ecomlg07-gmail-com-mn7pn69e | AUTOPILOT | true | autonomous | true | true | true | true |
| srv-performance-mn7ds3oj | AUTOPILOT | true | autonomous | true | true | true | true |
| switaa-mn9ioy5j | AUTOPILOT | true | autonomous | true | true | true | true |
| switaa-sasu-mn9fjcvk | **ORPHELIN** | true | autonomous | true | true | true | true |
| switaa-sasu-mn9if5n2 | AUTOPILOT | true | autonomous | true | true | true | true |

**PROD (3 entrees) :**

| Tenant | Plan | is_enabled | mode | safe_mode | auto_reply | auto_assign | auto_escalate |
|--------|------|------------|------|-----------|------------|-------------|---------------|
| ecomlg-001 | PRO | true | off | true | false | false | false |
| romruais-gmail-com-mn7mc6xl | AUTOPILOT | false | off | true | false | false | false |
| switaa-sasu-mn9c3eza | AUTOPILOT | true | autonomous | true | true | true | true |

### Table `ai_settings` (parametres IA generaux)

Seulement ecomlg-001 a une entree (DEV et PROD identiques) :
- mode=supervised, ai_enabled=true, safe_mode=true, daily_budget=0
- kill_switch=false, max_actions_per_hour=20

### AI Rules / Playbooks

| Tenants | Total | Actives | Desactivees | Mode auto | Mode suggest |
|---------|-------|---------|-------------|-----------|--------------|
| 7 tenants DEV | 15 chacun | 8 | 7 | **0** | **15** |

**CONSTAT : Aucun playbook n'est en mode `auto`. Tous sont en mode `suggest`.**

---

## 3. BUGS ET ANOMALIES CRITIQUES

### BUG 1 — PLAN GUARD ABSENT SUR PATCH /autopilot/settings (CRITIQUE)

**Preuve :** Un PATCH `mode: autonomous` sur ecomlg-001 (plan PRO) a retourne **200 OK** et a effectivement change le mode en autonomous. Le backend N'A PAS verifie le plan avant d'accepter le changement.

**Impact :** N'importe quel tenant, quel que soit son plan, peut activer le mode autonomous.

**Test :**
```
PATCH /autopilot/settings?tenantId=ecomlg-001
Body: { "mode": "autonomous" }
=> 200 OK, mode changed to autonomous
```

**Action requise :** Ajouter un plan guard sur la route PATCH `/autopilot/settings` qui refuse `mode: autonomous` si plan != AUTOPILOT && plan != ENTERPRISE.

**Remediation immédiate :** Mode reverte a `supervised` apres le test.

### BUG 2 — ZERO AUTO-REPLY EXECUTE (MAJEUR)

Malgre 4 tentatives d'auto-reply (confidence 0.85-0.90), **toutes ont ete bloquees par SAFE_MODE**.
`safe_mode = true` est actif sur **100% des tenants** (DEV et PROD).

**Consequence :** Le mode Autopilot ne repond **jamais** automatiquement aux clients.
Les seules actions executees sont des escalations (6) et des changements de statut (1).

### BUG 3 — PROD INACTIF MALGRE CONFIGURATION ACTIVE (MAJEUR)

`switaa-sasu-mn9c3eza` est configure en mode `autonomous` avec `is_enabled=true` en PROD.
Cependant, **ZERO activite autopilot en PROD** (aucun log `autopilot_*` dans `ai_action_log`).

Le moteur ne semble pas etre declenche par les messages inbound en PROD.

### BUG 4 — DONNEES ORPHELINES (MOYEN)

- **`switaa-sasu-mn9fjcvk`** : a des `autopilot_settings` mais N'EXISTE PAS dans la table `tenants`. Donnees orphelines.
- **Wallet `tenant_id = "null"`** : Existe dans DEV et PROD. La string "null" (pas SQL NULL) pollue les donnees.

### BUG 5 — GITOPS DRIFT MAJEUR (CRITIQUE)

| Env | Manifest | Cluster reel | Delta |
|-----|----------|-------------|-------|
| DEV | `v3.5.110-ph-amz-multi-country-dev` | `v3.5.51-playbooks-suggestions-live-dev` | **DRIFT** |
| PROD | `v3.5.110-ph-amz-multi-country-prod` | `v3.5.51-playbooks-suggestions-live-prod` | **DRIFT** |

Les manifests GitOps sont completement desynchronises du cluster. La version dans les manifests est POSTERIEURE a celle du cluster, ce qui suggere un rollback non documente.

---

## 4. ACTIONS AUTOPILOT (Etape 3)

### Resume des actions en DEV

| Action | Status | Count | Avg Confidence | KBA Debite |
|--------|--------|-------|----------------|------------|
| autopilot_escalate | completed | 6 | 0.90 | 56.42 |
| autopilot_status_change | completed | 1 | 1.00 | 6.87 |
| autopilot_reply | **skipped** | 4 | 0.88 | 0 |
| autopilot_none | **skipped** | 5 | 0.18 | 0 |

### Detail par action

| Action | Verifie | Resultat |
|--------|---------|----------|
| **reply** | Message envoye ? | **NON** — 4 tentatives, toutes bloquees par SAFE_MODE |
| **assign** | assigned_agent_id mis ? | **NON TESTE** — Aucun log `autopilot_assign` detecte |
| **escalate** | escalation OK ? | **OUI** — 6 executions reussies, KBA debite (8.2-8.91 KBA/action) |
| **status** | changement OK ? | **OUI** — 1 execution reussie, KBA debite (6.87 KBA) |

### PROD

**ZERO action autopilot en PROD.** Seuls des `AI_DECISION_TRACE` (PH44.5, DRY_RUN) existent pour ecomlg-001.

---

## 5. SAFE MODE (Etape 4)

| Test | Resultat |
|------|----------|
| safe_mode = true → reply BLOQUE | **OK** — 4 reply bloques avec reason `SAFE_MODE_BLOCKED` |
| safe_mode = false → reply autorise | **NON TESTABLE** — Aucun tenant n'a safe_mode=false |

**Constat :** safe_mode=true est un defaut **immutable en pratique** — aucun tenant ne l'a jamais desactive.
L'auto-reply est **structurellement bloque** tant que safe_mode reste true partout.

---

## 6. KBACTIONS (Etape 5)

### Debit correct

| Tenant | Action | Executions | Total KBA |
|--------|--------|------------|-----------|
| srv-performance-mn7ds3oj | autopilot_escalate | 5 | 41.16 |
| srv-performance-mn7ds3oj | autopilot_status_change | 1 | 6.87 |
| ecomlg07-gmail-com-mn7pn69e | autopilot_escalate | 1 | 8.39 |

### Ledger (ai_actions_ledger)

Les debits sont correctement traces dans le ledger avec :
- `reason: "ai_generation"`
- `request_id` unique (idempotent)
- `conversation_id` lie
- `delta` negatif (debit)

### Wallet balance

| Tenant | Remaining | Plan | Mode | Risque |
|--------|-----------|------|------|--------|
| ecomlg-001 | **4.11 KBA** | PRO | supervised | **LOW_BALANCE** |
| ecomlg07 | 1929.51 | AUTOPILOT | autonomous | OK |
| ecomlg-mmiyygfg | 1000.00 | PRO | N/A | OK |
| srv-performance | 2451.97 | AUTOPILOT | autonomous | OK |
| switaa-mn9ioy5j | 1990.72 | AUTOPILOT | autonomous | OK |
| switaa-sasu-mn9if5n2 | 2000.00 | AUTOPILOT | autonomous | OK |

### Tests

| Test | Resultat |
|------|----------|
| wallet > 0 → debit OK | **OK** — Debits fonctionnent correctement |
| wallet = 0 → blocage OK | **NON TESTE** — Aucun tenant n'a atteint 0 via autopilot |
| idempotence OK | **OK** — Chaque action a un requestId unique |
| Blocked actions → pas de debit | **OK** — `kbaCost: 0` sur tous les blocked |

---

## 7. LOGS ET ERREURS (Etapes 6-7)

### ai_action_log

| Type | Detail |
|------|--------|
| `blocked_reason` | SAFE_MODE_BLOCKED (4), LOW_CONFIDENCE:0 (5), ACTION_NOT_ALLOWED:none (1) |
| `confidence_score` | 0.00 a 1.00, coherent avec les decisions |
| `payload` | Contient `reason`, `source: "autopilot_engine"`, `kbaCost`, `requestId` |

### Tests d'erreurs

| Test | Resultat |
|------|----------|
| confidence < threshold → escalade | **OK** — 5 actions `LOW_CONFIDENCE:0` bloquees |
| rate limit → bloque | **NON TESTE** — Aucun rate limit atteint (max 20/h, 0 actions recentes) |
| plan insuffisant → bloque | **BUG** — Le PATCH accepte le mode autonomous pour un PRO |

### Evaluate endpoint

Le endpoint `POST /autopilot/evaluate` fonctionne :
- Conversation inexistante → `CONVERSATION_NOT_FOUND`, `executed: false`, `kbActionsDebited: 0`
- Reponse coherente avec confidence=0 et escalated=false

---

## 8. MULTI-TENANT (Etape 8)

### Activite par tenant (DEV)

| Tenant | Actions | KBA debite |
|--------|---------|------------|
| srv-performance-mn7ds3oj | 9 (6 completed, 3 blocked) | 48.03 |
| switaa-mn9ioy5j | 2 (blocked, safe_mode) | 0 |
| ecomlg07-gmail-com-mn7pn69e | 1 (completed) | 8.39 |

### Isolation

- Chaque requete SQL inclut `tenant_id`
- Les logs sont correctement associes au bon tenant
- Pas de contamination cross-tenant detectee

---

## 9. DETTES RESTANTES (Etape 9)

### GitOps Drift

**CRITIQUE :** Les manifests K8s sont desynchronises du cluster.

| Composant | Manifest | Cluster | Verdict |
|-----------|----------|---------|---------|
| API DEV | `v3.5.110-ph-amz-multi-country-dev` | `v3.5.51-playbooks-suggestions-live-dev` | **DRIFT** |
| API PROD | `v3.5.110-ph-amz-multi-country-prod` | `v3.5.51-playbooks-suggestions-live-prod` | **DRIFT** |

### Donnees polluees

| Probleme | Detail |
|----------|--------|
| Wallet "null" | `tenant_id = "null"` (string) dans `ai_actions_wallet` DEV + PROD |
| Orphelin | `switaa-sasu-mn9fjcvk` dans `autopilot_settings` sans tenant correspondant |
| PROD pending_payment | `ecomlg-mn3rdmf6` et `ecomlg-mn3roi1v` en status `pending_payment` |

### Playbooks

Les 15 playbooks (ai_rules) par tenant sont tous en mode `suggest` (0 en `auto`).
Le lien entre playbooks et autopilot n'est pas exploite — le moteur autopilot fonctionne independamment des playbooks.

---

## 10. RESUME DES CONSTATS

### Ce qui FONCTIONNE

| Fonctionnalite | Preuve |
|----------------|--------|
| Escalation automatique | 6 executions reussies en DEV |
| Status change automatique | 1 execution reussie en DEV |
| Safe mode (blocage reply) | 4 reply bloques correctement |
| Low confidence (blocage) | 5 actions bloquees a confidence=0 |
| KBA debit correct | 56.42 KBA debites avec ledger coherent |
| KBA non-debit si bloque | kbaCost=0 sur toutes les actions bloquees |
| Idempotence | requestId unique par action |
| Multi-tenant isolation | 3 tenants actifs, pas de contamination |
| Evaluate endpoint | Retourne des decisions coherentes |
| History endpoint | Liste les actions par tenant |
| Settings GET/PATCH | Lecture et modification fonctionnelles |

### Ce qui NE FONCTIONNE PAS

| Probleme | Severite | Impact |
|----------|----------|--------|
| **Plan guard absent sur PATCH** | CRITIQUE | N'importe quel tenant peut activer autonomous |
| **ZERO auto-reply execute** | MAJEUR | La feature "reply automatique" n'a jamais fonctionne |
| **PROD moteur inactif** | MAJEUR | Aucune action autopilot en PROD malgre config active |
| **safe_mode toujours true** | MAJEUR | L'auto-reply est structurellement bloque |
| **GitOps drift** | CRITIQUE | Manifests completement desynchronises |
| **Donnees orphelines** | MOYEN | Pollution DB (wallet "null", tenant orphelin) |
| **assign jamais teste** | MOYEN | Aucun log d'auto-assign detecte |

---

## 11. RECOMMANDATIONS

### Priorite 1 — Corrections critiques

1. **Ajouter plan guard sur `PATCH /autopilot/settings`**
   - Refuser `mode: autonomous` si `tenant.plan` != `AUTOPILOT` et != `ENTERPRISE`
   - Retourner 403 `PLAN_REQUIRED` sinon

2. **Aligner GitOps**
   - Mettre a jour les manifests avec les versions reellement deployees
   - Documenter le rollback de `v3.5.110` a `v3.5.51`

### Priorite 2 — Fonctionnalite auto-reply

3. **Investiguer pourquoi le moteur ne tourne pas en PROD**
   - Verifier le hook inbound → autopilot evaluate
   - Verifier si le trigger est actif dans le pipeline PROD

4. **Planifier un test safe_mode=false controle**
   - Sur un tenant AUTOPILOT de test en DEV
   - Verifier que l'auto-reply s'execute effectivement
   - Documenter le resultat

### Priorite 3 — Nettoyage donnees

5. **Supprimer wallet "null"** (DEV + PROD)
6. **Supprimer autopilot_settings orpheline** (`switaa-sasu-mn9fjcvk`)
7. **Auditer tenants `pending_payment`** en PROD

---

## 12. ROLLBACK

Aucune modification n'a ete apportee au systeme pendant cet audit.
Le seul changement (mode ecomlg-001 PRO → autonomous) a ete immediatement reverte a `supervised`.

---

## VERDICT FINAL

```
AUTOPILOT REALITY VERIFIED — ISSUES DETECTED — 5 BUGS/ANOMALIES IDENTIFIES

Moteur : FONCTIONNEL en DEV (escalation + status_change)
Auto-reply : JAMAIS EXECUTE (safe_mode always true)
PROD : INACTIF (zero action autopilot)
Plan guard : ABSENT (bug critique)
GitOps : DRIFT MAJEUR

CORRECTIONS REQUISES AVANT NEXT PHASE
```
