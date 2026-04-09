# PH140-M — SLA Priority / Urgency System

**Date** : 2 avril 2026
**Status** : DEV OK — STOP (PROD apres validation explicite)
**Image DEV** : `ghcr.io/keybuzzio/keybuzz-client:v3.5.177-sla-priority-dev`

---

## Objectif

Ajouter un systeme simple de priorite/urgence pour aider les agents a savoir quoi traiter en premier, base sur le temps ecoule depuis le dernier message.

---

## Avant / Apres

| Avant | Apres |
|---|---|
| Toutes conversations = meme niveau visuel | Badges **Urgent (+24h)** rouge et **A surveiller (+4h)** ambre |
| Priorite uniquement SLA/escalade/SAV | Priorite inclut maintenant le **temps ecoule** |
| Tri par date par defaut | **Tri prioritaire actif par defaut** |
| Supervision sans urgence | Supervision avec compteurs **Urgentes** et **A surveiller** |

---

## Logique de priorite (PH140-M)

Enrichissement du systeme PH126 existant avec 2 nouveaux niveaux temporels :

| Condition | Niveau | Score | Label | Couleur |
|---|---|---|---|---|
| `status = resolved` | low | 0 | Resolu | gris |
| `sla_state = breached` | **high** | 100 | SLA depasse | rouge |
| `escalation_status = escalated` | **high** | 95 | Escalade | rouge |
| `sav_status = to_process` | **high** | 90 | SAV a traiter | rouge |
| **`last_message > 24h`** | **high** | **85** | **Urgent (+24h)** | **rouge** |
| `sla_state = at_risk` | **high** | 80 | SLA a risque | rouge |
| `assigned_to_me + pending` | **high** | 70 | A reprendre | rouge |
| `escalation = recommended` | medium | 55 | Escalade suggeree | ambre |
| **`last_message > 4h`** | **medium** | **52** | **A surveiller (+4h)** | **ambre** |
| `assigned_to_me + open` | medium | 50 | En cours | ambre |
| ... (autres regles PH126 inchangees) | ... | ... | ... | ... |

---

## Fichiers modifies

| Fichier | Action |
|---|---|
| `src/features/inbox/utils/conversationPriority.ts` | Ajoute `getAgeHours()` + 2 regles temporelles |
| `src/features/dashboard/components/SupervisionPanel.tsx` | Ajoute compteurs Urgentes + A surveiller (6 KPIs) |
| `app/inbox/InboxTripane.tsx` | `prioritySort` default = `true` |

---

## Composants existants reutilises (aucune creation)

- `PriorityBadge.tsx` (PH126) — affiche les badges rouge/ambre/gris
- `conversationPriority.ts` (PH126) — enrichi avec logique temporelle
- `SupervisionPanel.tsx` (PH140-L) — enrichi avec 2 KPIs supplementaires

---

## Tests DEV (verifies navigateur reel)

### Inbox
| Test | Resultat |
|---|---|
| Badge "Urgent (+24h)" rouge sur conversations anciennes | OK |
| Badge "SAV a traiter" rouge preservee | OK |
| Compteur "243 urgentes, 6 moyennes" | OK |
| Toggle "Prioritaires d'abord" actif par defaut | OK |
| Tri par priorite (SAV + urgent en haut) | OK |
| Labels PH140-K preserves (Non assignees, Mes conversations) | OK |

### Dashboard / Supervision
| Test | Resultat |
|---|---|
| 6 KPIs : En file, Assignees, Escaladees, Urgentes, A surveiller, Resolues | OK |
| **Urgentes : 243** (rouge) | OK |
| **A surveiller : 6** (ambre) | OK |
| Badge "Attention requise" | OK |
| Alerte "243 conversations sans reponse depuis +24h" | OK |

### Non-regression
| Test | Resultat |
|---|---|
| Inbox fonctionnelle | OK |
| Dashboard KPIs existants | OK |
| Supervision PH140-L | OK (enrichie) |
| Assignment PH140-K | OK |
| Agent lockdown PH140-J | Non touche |
| Billing | Non touche |

---

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.176-agent-supervision-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## PROD

**Deploye le 3 avril 2026.**

| Etape | Resultat |
|---|---|
| Build PROD (`--no-cache`, `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `APP_ENV=production`) | OK |
| Push GHCR | OK — `sha256:87473f43...` |
| Deploy `keybuzz-client-prod` | OK — rollout reussi |
| Health check `client.keybuzz.io` | OK — HTTP 200, 0.91s |
| Pod | `1/1 Running`, 0 restarts |
| GitOps YAML DEV + PROD | Mis a jour |

**Image PROD** : `ghcr.io/keybuzzio/keybuzz-client:v3.5.177-sla-priority-prod`

### Rollback PROD

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.176-agent-supervision-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```
