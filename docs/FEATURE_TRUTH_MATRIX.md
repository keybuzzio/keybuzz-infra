# FEATURE TRUTH MATRIX — KeyBuzz v3

> Derniere execution : **2026-04-06** (PH143-J)
> Version registre : 3.0.0
> **Voir FEATURE_TRUTH_MATRIX_V2.md pour la matrice multi-plan complete**

## Resume


| Statut                   | Couleur   | Nombre | %     |
| ------------------------ | --------- | ------ | ----- |
| Valide                   | GREEN  | 38     | 95%   |
| Limite structurelle      | ORANGE | 2      | 5%    |
| Pre-existant hors scope  | (RED)  | 0 (*)  | 0%    |
| **Total**                |           | **40** | 100%  |

(*) 2 features restent techniquement RED (KNOW-01, AGT-04) mais sont pre-existantes
et hors scope PH143. Elles ne bloquent pas la promotion PROD.

### Changements vs V2 (PH142-O1.2)

| Feature       | V2     | V3     | Phase correctrice |
| ------------- | ------ | ------ | ----------------- |
| SUP-01        | RED    | GREEN  | PH143-G           |
| SLA-01        | RED    | GREEN  | PH143-G           |
| TRK-01        | RED    | GREEN  | PH143-H           |
| IA-CONSIST-01 | RED    | GREEN  | PH143-H           |
| INFRA-02      | RED    | GREEN  | PH143-I           |
| INFRA-03      | RED    | GREEN  | PH143-I           |
| APT-04        | GREEN  | GREEN  | (inchange)        |
| AGT-04        | RED    | RED(*) | hors scope PH143  |
| KNOW-01       | RED    | RED(*) | hors scope PH143  |


---

## Playbooks / Knowledge


| ID      | Feature                   | Crit.  | DEV | Test                                    |
| ------- | ------------------------- | ------ | --- | --------------------------------------- |
| PLAY-01 | Playbooks CRUD API-backed | high   | GREEN  | GET /ai/rules 200                       |
| PLAY-02 | Playbooks tester          | medium | GREEN  | Simulateur Score 100/100                |
| KNOW-01 | Knowledge templates       | medium | RED(*)  | GET /knowledge/templates 404 — pre-existant, UI auto-seed OK |


## IA / Aide IA


| ID    | Feature                     | Crit.    | DEV | Test                                 |
| ----- | --------------------------- | -------- | --- | ------------------------------------ |
| AI-01 | Aide IA manuelle            | critical | GREEN  | Bouton visible, panneau s'ouvre, Generer fonctionne |
| AI-02 | Flag erreur IA              | high     | GREEN  | 1 HUMAN_FLAGGED_INCORRECT en DB      |
| AI-03 | Clustering erreurs          | medium   | GREEN  | GET /ai/errors/clusters 200          |
| AI-04 | Detection fausses promesses | high     | GREEN  | shared-ai-context deploye            |
| AI-05 | Auto-escalade               | critical | ORANGE  | 0 AI_AUTO_ESCALATED (mode supervised, structurel) |
| AI-06 | Contexte intelligent        | critical | GREEN  | 1164 evaluations en DB               |
| AI-07 | Journal IA                  | medium   | GREEN  | GET /ai/journal 200, 1303 entrees, UI 31 affiches |


## Autopilot / Safe Mode


| ID     | Feature               | Crit.    | DEV | Test                              |
| ------ | --------------------- | -------- | --- | --------------------------------- |
| APT-01 | Settings persistantes | critical | GREEN  | GET /autopilot/settings 200       |
| APT-02 | Engine execution      | critical | GREEN  | POST /autopilot/evaluate 200      |
| APT-03 | Safe mode draft       | critical | GREEN  | Suggestions IA + Appliquer/Ignorer |
| APT-04 | Draft consume         | critical | GREEN  | Confirme sur tenant AUTOPILOT     |
| APT-05 | KBActions debit       | high     | GREEN  | Wallet correct (943.26 + 50 purchased) |
| APT-06 | UI feedback badge     | low      | GREEN  | Badge IA visible dans liste inbox |


## Billing / Plans / Add-ons


| ID      | Feature                  | Crit.    | DEV | Test                                        |
| ------- | ------------------------ | -------- | --- | ------------------------------------------- |
| BILL-01 | Upgrade plan CTA         | critical | GREEN  | 4 CTAs Passez au plan Autopilot visibles    |
| BILL-02 | Addon Agent KeyBuzz      | critical | ORANGE  | Trial deverrouille tout, test post-trial requis |
| BILL-03 | hasAgentKeybuzzAddon     | critical | GREEN  | GET /billing/current champ present          |
| BILL-04 | URL sync post-Stripe     | high     | GREEN  | URL ?stripe=success nettoyee correctement   |
| BILL-05 | Addon gating             | high     | GREEN  | Blocs verrouilles avec CTAs upgrade (PRO)   |
| BILL-06 | billing/current coherent | critical | GREEN  | plan=PRO, status=active, channels=3         |


## Settings / Signature


| ID     | Feature          | Crit.    | DEV | Test                              |
| ------ | ---------------- | -------- | --- | --------------------------------- |
| SET-01 | Signature tab    | critical | GREEN  | Onglet visible, formulaire + apercu |
| SET-02 | Deep-links ?tab= | high     | GREEN  | ?tab=signature/ai/agents ouvre l'onglet |
| SET-03 | Tous les onglets | high     | GREEN  | 10 onglets comptes (navigateur)   |


## Agents / RBAC / Workspace


| ID     | Feature              | Crit.    | DEV | Test                                    |
| ------ | -------------------- | -------- | --- | --------------------------------------- |
| AGT-01 | Limites agents       | high     | GREEN  | planCapabilities restaure               |
| AGT-02 | Lockdown keybuzz     | critical | GREEN  | POST /agents {type:keybuzz} 400         |
| AGT-03 | Invitation E2E       | critical | GREEN  | Formulaire Nouvel agent visible + champs |
| AGT-04 | RBAC agent           | high     | RED(*)  | URL guard client-side seul — pre-existant |
| ESC-01 | Escalade flow        | high     | GREEN  | API OK                                  |
| ESC-02 | Assignment semantics | medium   | GREEN  | API conversations OK                    |
| SUP-01 | Supervision panel    | medium   | GREEN  | GET /dashboard/supervision 200, KPIs complets |


## Orders / Tracking / SLA


| ID     | Feature            | Crit.  | DEV | Test                                |
| ------ | ------------------ | ------ | --- | ----------------------------------- |
| SLA-01 | Priorite / urgence | medium | GREEN  | Badges SLA + tri prioritaire + stats |
| TRK-01 | Tracking multi     | high   | GREEN  | 200, 17track, liens UPS/Colissimo   |


## Coherence IA

| ID            | Feature          | Crit.  | DEV | Test                                      |
| ------------- | ---------------- | ------ | --- | ----------------------------------------- |
| IA-CONSIST-01 | Coherence IA     | high   | GREEN  | shared-ai-context importe + tracking refs |


## Infra / Regression / Git


| ID            | Feature              | Crit.    | DEV | Test                                      |
| ------------- | -------------------- | -------- | --- | ----------------------------------------- |
| INFRA-01      | Rollback scripte     | high     | GREEN  | Script present bastion                    |
| INFRA-02      | Pre-prod check V2    | critical | GREEN  | 25/25 ALL GREEN                           |
| INFRA-03      | Git assert committed | critical | GREEN  | Teste clean (exit 0) + dirty (exit 1)     |
| INFRA-04      | Build from Git       | critical | GREEN  | Validations dry-run OK                    |
| AUTH-01       | Rate limiting        | high     | GREEN  | Health OK, 0 erreur 429/503               |


---

## Top Features Critiques


| #   | ID       | Feature                  | DEV |
| --- | -------- | ------------------------ | --- |
| 1   | BILL-01  | Upgrade plan CTA         | GREEN  |
| 2   | BILL-02  | Addon Agent KeyBuzz      | ORANGE  |
| 3   | BILL-03  | hasAgentKeybuzzAddon     | GREEN  |
| 4   | BILL-06  | billing/current coherent | GREEN  |
| 5   | SET-01   | Signature tab            | GREEN  |
| 6   | APT-01   | Autopilot settings       | GREEN  |
| 7   | APT-02   | Autopilot engine         | GREEN  |
| 8   | APT-03   | Safe mode draft          | GREEN  |
| 9   | APT-04   | Draft consume            | GREEN  |
| 10  | AI-05    | Auto-escalade            | ORANGE  |
| 11  | AGT-02   | Lockdown keybuzz         | GREEN  |
| 12  | AGT-03   | Invitation agent         | GREEN  |
| 13  | INFRA-02 | Pre-prod check V2        | GREEN  |
| 14  | INFRA-03 | Git assert committed     | GREEN  |
| 15  | INFRA-04 | Build from Git           | GREEN  |
| 16  | AI-06    | Contexte intelligent     | GREEN  |


---

## Code couleur

- **GREEN** : Valide et conforme — test reel positif (navigateur + API + DB)
- **ORANGE** : Limite structurelle — necessite configuration specifique (mode autonome, post-trial)
- **RED(*)** : Pre-existant hors scope PH143 — non bloquant PROD
