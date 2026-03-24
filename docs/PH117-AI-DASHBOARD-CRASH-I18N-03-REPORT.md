# PH117-AI-DASHBOARD-CRASH-I18N-03 — Rapport

> Date : 24 mars 2026
> Phase : PH117-AI-DASHBOARD-CRASH-I18N-03
> Type : Correction crash client + francisation

---

## Erreur console exacte

```
Application error: a client-side exception has occurred
TypeError: Cannot read properties of undefined (reading 'safeAutomatic')
```

Le crash se produisait lors de l'accès à `data.automation.safeAutomatic` — l'objet `automation` n'existait pas dans la réponse BFF.

---

## Root cause exacte

**Incompatibilité totale entre l'interface frontend et la structure BFF.**

Le frontend (`app/ai-dashboard/page.tsx`) définissait une interface `DashboardData` attendant :
```
data.autonomy.level
data.execution.totalExecutions
data.automation.safeAutomatic
data.workflows.top
data.financialImpact.estimatedSavings
data.risk.fraudAlerts
data.systemHealth.status
data.connectors[].name
data.recommendations[]
```

Le BFF (`app/api/ai/dashboard/route.ts`) retournait en réalité :
```
data.health.systemHealthScore
data.metrics.totals.executions
data.monitoring.volume.total
data.incidents.activeCount
data.connectors.connectors{}
data.fallback.globalRecommendation
```

**Le BFF n'a jamais été modifié** — il agrège 6 endpoints backend réels (health-monitoring, performance-metrics, real-execution-monitoring, real-execution-incidents, real-execution-connectors, real-execution-fallback). C'est la page frontend qui a été écrite pour une structure de données qui n'a jamais existé.

---

## Fichier modifié

**1 seul fichier** : `app/ai-dashboard/page.tsx`

### Changements effectués

| Aspect | Avant | Après |
|---|---|---|
| Interface | `DashboardData` (fictive) | `BFFResponse` (réelle, typée) |
| Accès données | Direct sans garde (`data.automation.safeAutomatic`) | Via `safe()` wrapper + optional chaining |
| Labels | Partiellement anglais | **100% français** |
| Dark mode | Non supporté | **50 classes `dark:`** |
| États vides | Crash si donnée absente | Fallback propre pour chaque section |
| Structure UI | 7 sections sur données fictives | 6 sections sur données réelles |

### Sections de la page corrigée

1. **En-tête** — titre "IA Performance", bouton Actualiser
2. **Bandeau santé** — score système, risque, exécutions, taux automatisation
3. **Répartition exécutions + Workflows** — barres de progression, liste triée
4. **Alertes actives** — badges severité, seuils
5. **Monitoring 24h + Connecteurs** — volume, latences, états connecteurs
6. **Recommandation système** — affichée si non `NONE`

### Gardes défensifs ajoutés

- Fonction `safe(val, fallback)` : convertit null/undefined/NaN en valeur par défaut
- Optional chaining partout : `data.metrics?.totals || {}`
- Fallback BFF : chaque section gère l'absence de données
- Pas de crash possible même si le payload est vide

---

## BFF/API

**Non modifié.** Le BFF (`app/api/ai/dashboard/route.ts`) était déjà correct. Seul le frontend ne consommait pas sa structure réelle.

---

## Éléments francisés

- Titre : "IA Performance"
- Sous-titre : "Vue d'ensemble du moteur d'intelligence artificielle"
- "Santé du système" / "Opérationnel" / "Attention requise" / "Dégradé" / "Indisponible"
- "Exécutions totales" / "Automatiques" / "Bloquées" / "Taux automatisation"
- "Répartition des exécutions" / "Automatique" / "Assisté" / "Bloqué"
- "Workflows principaux" / labels CONVERSATION → "Conversation", ESCALATED_CASE → "Cas escaladé", etc.
- "Alertes actives" / severité "Élevée" / "Moyenne" / "Faible"
- "Monitoring 24h" / "Volume total" / "Exécutions réelles" / "Simulations (dry run)" / "Latence moyenne" / "Latence p95"
- "Connecteurs" / "actifs"
- "Recommandation système"
- "Risque" / "Faible" / "Modéré" / "Élevé"
- États vides : "Aucun workflow exécuté", "Aucun connecteur actif"
- Erreur : "Impossible de charger le tableau de bord", "Données indisponibles", "Réessayer"

---

## Validations DEV

| Test | Résultat |
|---|---|
| /ai-dashboard HTTP status | 200 |
| Console JS | Aucune erreur bloquante |
| BFF /api/ai/dashboard | Payload correct (6 sections) |
| /login | 200 |
| /register | 200 |
| /dashboard | 200 |
| /inbox | 200 |
| /orders | 200 |
| /billing | 200 |
| /settings | 200 |
| /channels | 200 |
| /suppliers | 200 |
| /knowledge | 200 |
| /playbooks | 200 |
| /ai-journal | 200 |
| API health | ok |
| **13/13 pages** | **200** |

### Verdicts DEV

- **AI DASHBOARD DEV CRASH = OK**
- **AI DASHBOARD DEV I18N = OK**
- **AI DASHBOARD DEV UX = OK**

---

## Validations PROD

| Test | Résultat |
|---|---|
| /ai-dashboard HTTP status | 200 |
| BFF PROD | Données réelles (score 0.36, status CRITICAL, 10 exec, alertes HIGH) |
| /login | 200 |
| /register | 200 |
| /dashboard | 200 |
| /inbox | 200 |
| /orders | 200 |
| /billing | 200 |
| /settings | 200 |
| /channels | 200 |
| /suppliers | 200 |
| /knowledge | 200 |
| /playbooks | 200 |
| /ai-journal | 200 |
| API health | ok |
| **13/13 pages** | **200** |

### Verdicts PROD

- **AI DASHBOARD PROD CRASH = OK**
- **AI DASHBOARD PROD I18N = OK**
- **AI DASHBOARD PROD UX = OK**

---

## Non-régressions

| Module | Statut |
|---|---|
| Menu / sidebar | Inchangé |
| Focus mode | Inchangé |
| Theme light | Inchangé |
| Auth / login | OK |
| Onboarding | Non touché |
| Billing | Non touché |
| Amazon | Non touché |
| Orders / Messages | Non touché |

---

## Images déployées

| Env | Image | Digest |
|---|---|---|
| **DEV** | `v3.5.84-ph117-ai-dashboard-crash-i18n-dev` | `sha256:e7a210783edc09a6a43485d0466d98cecb9168044e331c624abb14bd9828e112` |
| **PROD** | `v3.5.84-ph117-ai-dashboard-crash-i18n-prod` | `sha256:8a2d1710490d7f73c6dc7b2943c780ae919b4e82f4987dfe367f7f30ab225ebb` |

Git commit client : `7381147` sur branche `fix/signup-redirect-v2`
Git commits infra : `0e6131c` (DEV) + `263b415` (PROD) sur branche `main`

---

## Rollback

| Env | Image rollback |
|---|---|
| DEV | `v3.5.83-ph120-minimal-fix-dev` |
| PROD | `v3.5.83-ph120-minimal-fix-prod` |

API/BFF non modifié → pas de rollback API nécessaire.

---

## Verdict final

# AI DASHBOARD CRASH FIXED AND FRENCHIFIED
