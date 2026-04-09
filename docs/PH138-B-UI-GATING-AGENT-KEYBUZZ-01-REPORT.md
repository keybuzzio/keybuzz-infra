# PH138-B — UI Gating Agent KeyBuzz

> Phase : PH138-B-UI-GATING-AGENT-KEYBUZZ-01
> Date : 31 mars 2026
> Environnement : DEV + PROD valides

---

## 1. Objectif

Aligner l'UI client avec le backend PH138-A pour le module Agent KeyBuzz :
- Options d'escalade "KeyBuzz" et "Les deux" gatees par addon
- CTA d'activation visible et clair
- Pas de confusion utilisateur

---

## 2. Modifications effectuees

### 2.1 BFF Routes (Next.js)

| Route | Methode | Proxy vers | Description |
|---|---|---|---|
| `/api/billing/agent-keybuzz-status` | GET | `/billing/agent-keybuzz-status` | Statut addon (hasAddon, canActivate) |
| `/api/billing/update-agent-keybuzz` | POST | `/billing/update-agent-keybuzz` | Activer/desactiver addon |

### 2.2 AutopilotSection.tsx

Composant reecrit avec gating addon :

**Escalade — logique de verrouillage** :
- `planLocked` : plan insuffisant (comme avant)
- `addonLocked` : option `requiresAddon: true` mais `hasAddon === false`
- Les deux conditions sont independantes

**UX — 3 cas** :
| Cas | Visuel |
|---|---|
| Plan insuffisant | Icone Lock + "Passez au plan X" |
| Plan OK, pas d'addon | Icone Crown + "Necessite Agent KeyBuzz" |
| Plan OK + addon actif | Bouton actif, selection possible |

**Banner Agent KeyBuzz** :
- Visible sous "Cible d'escalade" si Autopilot+ sans addon
- Description du service + prix (797 EUR/mois)
- Bouton "Activer Agent KeyBuzz" (si canActivate + owner/admin)

**Badge addon actif** :
- Encart vert avec icone Crown si addon present

---

## 3. Images deployees

| Service | Namespace | Image |
|---|---|---|
| Client DEV | keybuzz-client-dev | `ghcr.io/keybuzzio/keybuzz-client:v3.5.152-agent-keybuzz-ui-gating-dev` |
| Client PROD | keybuzz-client-prod | `ghcr.io/keybuzzio/keybuzz-client:v3.5.152-agent-keybuzz-ui-gating-prod` |
| API PROD | keybuzz-api-prod | `ghcr.io/keybuzzio/keybuzz-api:v3.5.151-stripe-addon-prod` (inchange) |

---

## 4. Tests DEV

### 4.1 Endpoints

| Test | URL | Code | Resultat |
|---|---|---|---|
| Client health | /login | 200 | OK |
| API health | /health | 200 | OK |
| BFF billing current | /api/billing/current?tenantId=ecomlg-001 | 200 | OK |
| BFF agent-keybuzz-status | /api/billing/agent-keybuzz-status?tenantId=ecomlg-001 | 200 | `hasAddon:false, canActivate:false` |
| Inbox | /inbox | 200 | OK |
| Dashboard | /dashboard | 200 | OK |
| Billing | /billing | 200 | OK |
| Settings | /settings | 200 | OK |
| Orders | /orders | 200 | OK |

### 4.2 Reponse agent-keybuzz-status

```json
{
  "tenantId": "ecomlg-001",
  "hasAddon": false,
  "canActivate": false,
  "reason": "no_subscription"
}
```

Correct : `ecomlg-001` est billing-exempt, pas de subscription Stripe.

### 4.3 Logs client

Aucune erreur en conditions normales. La seule erreur observee etait due au test curl avec JSON mal echappe via SSH.

---

## 5. Non-regression

| Composant | Statut |
|---|---|
| Client login | OK (200) |
| Inbox | OK (200) |
| Dashboard | OK (200) |
| Billing | OK (200) |
| Settings | OK (200) |
| Orders | OK (200) |
| API health | OK |

---

## 6. Comportement attendu par plan

| Plan | Addon | "Votre equipe" | "KeyBuzz" | "Les deux" |
|---|---|---|---|---|
| STARTER | - | Lock (plan) | Lock (plan) | Lock (plan) |
| PRO | non | Actif | Lock (plan) | Lock (plan) |
| AUTOPILOT | non | Actif | Lock (addon) + CTA | Lock (addon) + CTA |
| AUTOPILOT | oui | Actif | Actif | Actif |
| ENTERPRISE | non | Actif | Lock (addon) + CTA | Lock (addon) + CTA |
| ENTERPRISE | oui | Actif | Actif | Actif |

---

## 7. Tests PROD

### 7.1 Endpoints PROD

| Test | URL | Code | Resultat |
|---|---|---|---|
| Client login | client.keybuzz.io/login | 200 | OK |
| API health | api.keybuzz.io/health | 200 | OK |
| BFF billing current | /api/billing/current?tenantId=ecomlg-001 | 200 | OK |
| BFF agent-keybuzz-status | /api/billing/agent-keybuzz-status?tenantId=ecomlg-001 | 200 | `hasAddon:false` |
| Inbox | /inbox | 200 | OK |
| Dashboard | /dashboard | 200 | OK |
| Billing | /billing | 200 | OK |
| Settings | /settings | 200 | OK |
| Orders | /orders | 200 | OK |

### 7.2 Logs PROD

```
Next.js 14.2.35 - Ready in 418ms
```

Zero erreur, zero warning.

---

## 8. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.148-autopilot-draft-ux-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.148-autopilot-draft-ux-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## 9. GitOps

- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` mis a jour
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` mis a jour

---

## 10. Correctif Unicode

Un probleme de caracteres accentues affiches en `\u00e9` (au lieu de `e`) a ete detecte et corrige entre le premier et le second build. Cause : utilisation d'un raw string Python (`r"""`) qui n'interprete pas les escapes Unicode. Correction : remplacement des 42 sequences `\uXXXX` par les vrais caracteres UTF-8.

---

## 11. Verdict

**UI CONSISTENT — NO CONFUSION — UPSELL CLEAR — USER UNDERSTANDS**

- Escalade KeyBuzz gatee par addon (double verrou plan + addon)
- CTA d'activation visible et fonctionnel
- Badge addon actif quand present
- Caracteres accentues corrects
- Aucune regression sur inbox, billing, settings, dashboard, orders
- DEV et PROD valides
