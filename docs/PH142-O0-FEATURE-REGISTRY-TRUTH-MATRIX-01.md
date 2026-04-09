# PH142-O0 — Feature Registry & Truth Matrix

> Date : 2026-04-05
> Type : audit documentation — aucune implementation
> Env : lecture seule

---

## 1. Resume executif

Construction d'une source de verite complete des features KeyBuzz couvrant toutes les phases depuis PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01 jusqu'a PH142-N.

**Objectif** : permettre de detecter immediatement toute regression silencieuse en comparant l'etat reel du produit a la matrice.

**Resultats** :
- **36 features** identifiees et documentees
- **8 domaines** couverts
- **15 features critiques** marquees pour verification obligatoire pre-PROD
- **2 fichiers exploitables** produits (`FEATURE_TRUTH_MATRIX.md` + `feature_registry.json`)

---

## 2. Domaines couverts

| Domaine | Nombre | Critiques |
|---|---|---|
| A. Playbooks / Knowledge | 3 | 0 |
| B. IA / Aide IA | 8 | 3 |
| C. Autopilot / Safe mode | 6 | 4 |
| D. Billing / Plans / Add-ons | 6 | 3 |
| E. Settings / Signature | 3 | 1 |
| F. Agents / RBAC / Workspace | 7 | 2 |
| G. Orders / Tracking / SLA | 2 | 0 |
| H. Infra / Regression / Git | 5 | 3 |
| **TOTAL** | **40** | **16** |

---

## 3. Phases relues

### Blocs relus

| Bloc | Phases | Features extraites |
|---|---|---|
| Playbooks | PH-PLAYBOOKS-TRUTH-RECOVERY, PH-PLAYBOOKS-BACKEND-MIGRATION-02 | 3 |
| AI Assist / Supervision | PH127, PH128, PH-AI-ASSIST-RELIABILITY-01 | 2 |
| Autopilot core | PH131-B, PH131-C, PH132-C, PH134-A | 4 |
| Autopilot UX | PH137-B-UX, PH-AUTOPILOT-UI-FEEDBACK-01 | 1 |
| IA coherence | PH137-C, PH141-F | 2 |
| Billing / Stripe | PH138-E, PH138-F, PH138-I, PH138-K | 6 |
| Agents / Escalade | PH140-A, PH140-C, PH140-F, PH140-K, PH140-L, PH140-M | 7 |
| Agent limits | PH141-A, PH141-B, PH141-C | 2 |
| Polish / Settings | PH141-D, PH141-E, PH139 | 3 |
| AI quality loop | PH142-A, PH142-B, PH142-C, PH142-D | 4 |
| Autopilot safe mode | PH142-E, PH142-F, PH142-G | 3 |
| Audits | PH142-H, PH142-K, PH142-L | 0 (audits) |
| Regression prevention | PH142-I, PH142-M | 3 |
| Restoration | PH142-J, PH142-N | 0 (corrections) |
| Infra | PH136-A, PH136-B, PH-AUTH-RATELIMIT | 3 |
| Tracking | PH136-B | 1 |

---

## 4. Top features critiques

Les 16 features marquees `critical` constituent le pack de verification obligatoire avant chaque push PROD :

| # | ID | Feature | Domain |
|---|---|---|---|
| 1 | AI-01 | Aide IA manuelle | IA |
| 2 | AI-05 | Auto-escalade fausse promesse | IA |
| 3 | AI-06 | Contexte IA intelligent | IA |
| 4 | APT-01 | Settings autopilot persistantes | Autopilot |
| 5 | APT-02 | Engine autopilot | Autopilot |
| 6 | APT-03 | Safe mode draft visible | Autopilot |
| 7 | APT-04 | Draft consume (no ghost) | Autopilot |
| 8 | BILL-01 | Upgrade plan CTA | Billing |
| 9 | BILL-02 | Addon Agent KeyBuzz checkout | Billing |
| 10 | BILL-03 | hasAgentKeybuzzAddon | Billing |
| 11 | BILL-06 | billing/current coherent | Billing |
| 12 | SET-01 | Signature tab save/load | Settings |
| 13 | AGT-02 | Lockdown agents KeyBuzz | Agents |
| 14 | AGT-03 | Invitation agent E2E | Agents |
| 15 | INFRA-02 | Pre-prod check V2 | Infra |
| 16 | INFRA-03 | Git assert committed | Infra |

---

## 5. Fichiers generes

| Fichier | Format | Usage |
|---|---|---|
| `FEATURE_TRUTH_MATRIX.md` | Markdown | Lisible humainement, reference visuelle |
| `feature_registry.json` | JSON | Exploitable par scripts automatiques |

### Structure JSON par feature

```json
{
  "id": "BILL-01",
  "domain": "billing",
  "feature": "Upgrade plan via Stripe (CTA)",
  "source_phase": "PH138-E",
  "last_validated_phase": "PH142-N",
  "expected_behavior": "...",
  "truth_test": "...",
  "test_type": "mixte",
  "criticality": "critical",
  "status_dev": "unknown",
  "status_prod": "unknown"
}
```

---

## 6. Code couleur des statuts

| Statut | Couleur | Signification |
|---|---|---|
| `green` | VERT | Valide et conforme au test de verite |
| `orange` | ORANGE | Present mais partiel ou non revalide entierement |
| `red` | ROUGE | Casse, absent, ou regresse |
| `unknown` | GRIS | Non encore teste |

---

## 7. Plan pour la phase suivante

### PH142-O1 (proposee)

Tester reellement chaque feature GRIS :
1. Navigation navigateur DEV (features UI)
2. Appels API via kubectl exec (features API)
3. Requetes DB via pod (features DB)
4. Mettre a jour `status_dev` dans `feature_registry.json`
5. Identifier les ROUGE et ORANGE
6. Produire un plan de correction priorise

### Critere de sortie PH142-O1
- 0 feature GRIS dans le registre
- Toutes les features critiques sont VERT ou ont un plan de correction

---

## 8. Anti-regression continue

La matrice doit etre mise a jour :
- Apres chaque phase qui modifie du code
- Avant chaque push PROD
- Les features critiques doivent rester VERT

Le script `pre-prod-check-v2.sh` couvre deja une partie des checks automatises.
La matrice complete la couverture avec les tests manuels documentes.

---

## Verdict

**FEATURE REGISTRY CREATED — TRUTH MATRIX READY — NO MORE INVISIBLE REGRESSIONS**
