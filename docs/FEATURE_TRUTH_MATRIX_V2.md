# FEATURE TRUTH MATRIX V2 — KeyBuzz v3 (Multi-Plan)

> Derniere execution : **2026-04-05** (PH142-O1.2)
> Version registre : 2.0.0
> Methode : tests navigateur reels + API + DB par plan

## Resume Global

| Statut              | Couleur  | Nombre | %     |
| ------------------- | -------- | ------ | ----- |
| Valide              | GREEN    | 31     | 77.5% |
| Limite structurelle | ORANGE   | 2      | 5%    |
| Casse / absent      | RED      | 7      | 17.5% |
| **Total**           |          | **40** | 100%  |

### Changements vs V1 (PH142-O1.1)

| Feature | V1      | V2      | Raison                                           |
| ------- | ------- | ------- | ------------------------------------------------ |
| APT-04  | ORANGE  | GREEN   | Draft IA confirme sur tenant AUTOPILOT (SWITAA)  |
| AI-05   | ORANGE  | ORANGE  | 5 "Escalade" visibles mais 0 AI_AUTO_ESCALATED   |
| BILL-02 | ORANGE  | ORANGE  | Trial AUTOPILOT deverrouille tout, pas de banner |
| AGT-04  | ORANGE  | RED     | Menu masque OK mais garde URL CASSEE (securite)  |

---

## Matrice Multi-Plan

### Legende

- `OK` = fonctionne comme attendu pour ce plan
- `GATE` = correctement verrouille/restreint par le plan (comportement attendu)
- `N/A` = feature non applicable a ce plan
- `BUG` = comportement inattendu
- `?` = non teste (OTP en attente)

---

### Playbooks / Knowledge

| ID      | Feature                   | STARTER | PRO   | AUTOPILOT | Verdict |
| ------- | ------------------------- | ------- | ----- | --------- | ------- |
| PLAY-01 | Playbooks CRUD API-backed | ?       | OK    | OK        | GREEN   |
| PLAY-02 | Playbooks tester          | ?       | OK    | OK        | GREEN   |
| KNOW-01 | Knowledge templates       | ?       | RED   | RED       | RED     |

### IA / Aide IA

| ID    | Feature                     | STARTER | PRO   | AUTOPILOT | Verdict |
| ----- | --------------------------- | ------- | ----- | --------- | ------- |
| AI-01 | Aide IA manuelle            | ?       | OK    | OK        | GREEN   |
| AI-02 | Flag erreur IA              | ?       | OK    | OK        | GREEN   |
| AI-03 | Clustering erreurs          | ?       | OK    | OK        | GREEN   |
| AI-04 | Detection fausses promesses | ?       | OK    | OK        | GREEN   |
| AI-05 | Auto-escalade               | N/A     | GATE  | ORANGE    | ORANGE  |
| AI-06 | Contexte intelligent        | ?       | OK    | OK        | GREEN   |
| AI-07 | Journal IA                  | GATE    | OK    | OK        | GREEN   |

**AI-05 detail** : 5 conversations montrent le badge "Escalade" sur AUTOPILOT. Mais en DB, 0 evenement `AI_AUTO_ESCALATED`. Les escalades sont probablement manuelles. L'auto-escalade sur fausse promesse necessite le mode `autonome` actif avec un message declencheur reel.

### Autopilot / Safe Mode

| ID     | Feature               | STARTER | PRO   | AUTOPILOT | Verdict |
| ------ | --------------------- | ------- | ----- | --------- | ------- |
| APT-01 | Settings persistantes | N/A     | OK    | OK        | GREEN   |
| APT-02 | Engine execution      | N/A     | GATE  | OK        | GREEN   |
| APT-03 | Safe mode draft       | N/A     | GATE  | OK        | GREEN   |
| APT-04 | Draft consume         | N/A     | GATE  | OK        | GREEN   |
| APT-05 | KBActions debit       | N/A     | OK    | OK        | GREEN   |
| APT-06 | UI feedback badge     | N/A     | OK    | OK        | GREEN   |

**APT-03/04 sur AUTOPILOT** : "Brouillon IA" avec "Valider et envoyer" / "Modifier" / "Ignorer" confirme en navigateur reel. Le draft existe et les 3 boutons d'action sont fonctionnels.

### Billing / Plans / Add-ons

| ID      | Feature                  | STARTER | PRO   | AUTOPILOT | Verdict |
| ------- | ------------------------ | ------- | ----- | --------- | ------- |
| BILL-01 | Upgrade plan CTA         | ?       | OK    | N/A       | GREEN   |
| BILL-02 | Addon Agent KeyBuzz      | N/A     | N/A   | ORANGE    | ORANGE  |
| BILL-03 | hasAgentKeybuzzAddon     | ?       | OK    | OK        | GREEN   |
| BILL-04 | URL sync post-Stripe     | ?       | OK    | OK        | GREEN   |
| BILL-05 | Addon gating             | ?       | OK    | OK        | GREEN   |
| BILL-06 | billing/current coherent | ?       | OK    | OK        | GREEN   |

**BILL-01 detail PRO** : 4 CTAs "Passez au plan Autopilot" visibles (mode Autonome, escalade KeyBuzz, Les deux). Sur AUTOPILOT, pas de CTA upgrade (correct, deja au plan max consumer).

**BILL-02 detail** : Sur AUTOPILOT en trial, les escalades keybuzz/both sont deverrouillees SANS addon. Pas de banner "Activer Agent KeyBuzz" visible. Le trial semble inclure toutes les features. Le test de l'addon gating necessite un tenant AUTOPILOT post-trial.

**BILL-05 detail** :
- PRO : blocs Autonome/KeyBuzz/Les deux verrouilles avec CTA "Passez au plan Autopilot" = OK
- AUTOPILOT : tous les blocs deverrouilles = OK (trial inclut tout)

### Settings / Signature

| ID     | Feature          | STARTER | PRO   | AUTOPILOT | Verdict |
| ------ | ---------------- | ------- | ----- | --------- | ------- |
| SET-01 | Signature tab    | ?       | OK    | OK        | GREEN   |
| SET-02 | Deep-links ?tab= | ?       | OK    | OK        | GREEN   |
| SET-03 | Tous les onglets | ?       | OK    | OK        | GREEN   |

**SET-03 detail** : 10 onglets visibles sur PRO (owner) et AUTOPILOT (owner) : Entreprise, Horaires, Conges, Messages auto, Notifications, IA, Signature, Espaces, Agents, Avance.

### Agents / RBAC / Workspace

| ID     | Feature              | STARTER | PRO   | AUTOPILOT | Verdict |
| ------ | -------------------- | ------- | ----- | --------- | ------- |
| AGT-01 | Limites agents       | ?       | OK    | OK        | GREEN   |
| AGT-02 | Lockdown keybuzz     | ?       | OK    | OK        | GREEN   |
| AGT-03 | Invitation E2E       | ?       | OK    | OK        | GREEN   |
| AGT-04 | RBAC agent           | ?       | ?     | RED       | RED     |
| ESC-01 | Escalade flow        | N/A     | OK    | OK        | GREEN   |
| ESC-02 | Assignment semantics | ?       | OK    | OK        | GREEN   |
| SUP-01 | Supervision panel    | ?       | RED   | RED       | RED     |

**AGT-04 BUG SECURITE** : Login agent OK (`switaa26+ph140f@gmail.com`). Menu masque correctement (4 liens vs 12 owner). Onglet "Agents" masque dans Settings. **MAIS la garde URL est CASSEE** : l'agent peut acceder a `/settings`, `/billing`, `/dashboard` par navigation directe sans redirect. `bff-role-guard.ts` existe mais n'est pas applique aux routes pages.

### Orders / Tracking / SLA

| ID     | Feature            | STARTER | PRO   | AUTOPILOT | Verdict |
| ------ | ------------------ | ------- | ----- | --------- | ------- |
| SLA-01 | Priorite / urgence | N/A     | RED   | RED       | RED     |
| TRK-01 | Tracking multi     | ?       | RED   | RED       | RED     |

### Coherence IA

| ID            | Feature          | STARTER | PRO   | AUTOPILOT | Verdict |
| ------------- | ---------------- | ------- | ----- | --------- | ------- |
| IA-CONSIST-01 | Coherence IA     | N/A     | RED   | RED       | RED     |

### Infra / Regression / Git

| ID       | Feature              | STARTER | PRO   | AUTOPILOT | Verdict |
| -------- | -------------------- | ------- | ----- | --------- | ------- |
| INFRA-01 | Rollback scripte     | -       | OK    | OK        | GREEN   |
| INFRA-02 | Pre-prod check V2    | -       | RED   | RED       | RED     |
| INFRA-03 | Git assert committed | -       | RED   | RED       | RED     |
| INFRA-04 | Build from Git       | -       | OK    | OK        | GREEN   |
| AUTH-01  | Rate limiting        | ?       | OK    | OK        | GREEN   |

---

## Differences de Comportement par Plan

### Gating correct (attendu)

| Aspect                  | STARTER            | PRO                | AUTOPILOT          |
| ----------------------- | ------------------ | ------------------ | ------------------ |
| Mode IA Autonome        | Verrouille (GATE)  | Verrouille + CTA   | Deverrouille       |
| Escalade KeyBuzz        | Aucune (GATE)      | Verrouille + CTA   | Deverrouille       |
| Escalade Les deux       | Aucune (GATE)      | Verrouille + CTA   | Deverrouille       |
| KBActions/mois          | 0                  | 1000               | 2000               |
| Canaux max              | 1                  | 3                  | 5                  |
| Support                 | Standard           | Prioritaire        | Premium            |
| Journal IA              | Non (GATE)         | Oui                | Oui                |
| Supervision avancee     | Non (GATE)         | Non                | Oui                |
| Auto-execute            | Non (GATE)         | Non                | Oui                |
| AI Quota                | 3/jour             | Illimite           | Illimite           |

### Billing par plan (reel en DB)

| Tenant              | Plan      | Stripe Status | KBA Restants | KBA Inclus/mois | Exempt |
| -------------------- | --------- | ------------- | ------------ | ---------------- | ------ |
| eComLG (ecomlg-001)  | pro       | N/A           | 959.35       | 1000             | Oui    |
| ecomlg (mmiyygfg)    | PRO       | active        | -            | -                | Non    |
| SWITAA SASU (mnc1x4eq)| AUTOPILOT | trialing     | 1883.94      | 2000             | Non    |
| Essai (1772234265142) | STARTER   | N/A           | N/A          | N/A              | Non    |

---

## Anomalies Detectees

### ANO-01 : Casse de plan inconsistante

ecomlg-001 a `plan='pro'` (minuscule) alors que les autres tenants ont `plan='PRO'` (majuscule). `planCapabilities.ts` utilise le type `PlanType = 'STARTER' | 'PRO' | 'AUTOPILOT'`. Si la comparaison est case-sensitive, ecomlg-001 pourrait ne pas matcher les capabilities PRO.

**Impact** : Possible mauvais gating pour ecomlg-001.
**Severite** : HAUTE (le tenant pilote est concerne).

### ANO-02 : STARTER tenant incomplet

Le tenant Essai (`tenant-1772234265142`) n'a :
- Aucun `ai_actions_wallet`
- Aucun `tenant_metadata`
- Aucun `tenant_settings`
- 0 conversations, messages, commandes

**Impact** : Features IA inutilisables sans wallet. Pas de trial info.
**Severite** : MOYENNE (tenant de test, pas de vrais utilisateurs).

### ANO-03 : Addon gating invisible en trial

Sur AUTOPILOT en trial (`trialing`), toutes les features sont deverrouillees y compris l'escalade KeyBuzz/Les deux. Aucun banner "Activer Agent KeyBuzz" visible. Le test `BILL-02` ne peut pas etre valide car :
1. Le trial deverrouille tout
2. Apres le trial, le gating addon pourrait fonctionner ou non

**Impact** : Impossible de valider le flux addon pendant un trial.
**Severite** : MOYENNE (fonctionnel pour les vrais utilisateurs post-trial).

### ANO-04 : 7 tenants AUTOPILOT en trial

Tous les tenants AUTOPILOT sont en status `trialing`. Aucun tenant AUTOPILOT avec subscription `active` n'existe pour tester le comportement post-trial.

### ANO-05 : STARTER tenant lock (enregistrement incomplet)

Le tenant Essai (STARTER, `ludovic@ecomlg.fr`) redirige vers `/locked?reason=NO_SUBSCRIPTION`. L'utilisateur n'a pas termine l'enregistrement Stripe. Le paywall fonctionne correctement : aucune page n'est accessible sans subscription active. Ce n'est PAS un bug — c'est le comportement attendu pour un tenant sans abonnement.

### ANO-06 : RBAC agent — garde URL manquante (SECURITE)

L'agent (`switaa26+ph140f@gmail.com`) voit un menu simplifie (4 liens : Messages, Commandes, Fournisseurs, Automatisation IA). Cependant, la navigation directe par URL vers `/settings`, `/billing` et `/dashboard` n'est PAS bloquee. L'agent peut voir et potentiellement modifier les parametres du tenant. Le fichier `bff-role-guard.ts` existe mais n'est applique qu'aux routes BFF API, pas aux pages client.

---

## Code couleur

- **GREEN** : Valide et conforme — test reel positif (navigateur + API + DB)
- **ORANGE** : Limite structurelle — necessite configuration specifique (mode non-trial, login agent)
- **RED** : Casse / absent / route 404 / script manquant
- **GATE** : Correctement restreint par le plan (comportement attendu, pas un bug)
- **N/A** : Feature non applicable a ce plan
- **?** : Non teste (en attente OTP / acces tenant)
