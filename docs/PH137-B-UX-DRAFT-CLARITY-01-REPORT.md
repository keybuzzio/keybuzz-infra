# PH137-B-UX-DRAFT-CLARITY-01 — Rapport

> Date : 1 mars 2026
> Auteur : Agent Cursor (CE)
> Version DEV : `v3.5.148-autopilot-draft-ux-dev`
> Version PROD : `v3.5.148-autopilot-draft-ux-prod`
> Environnement : DEV + PROD deploye

---

## 1. Objectif

Rendre les drafts IA immediatement visibles, comprehensibles et actionnables en 1 clic.

---

## 2. Problemes identifies (Audit)

### AutopilotDraftBanner (avant)

| Probleme | Impact |
|---|---|
| Titre "Brouillon IA" trop vague | Utilisateur ne comprend pas que c'est une suggestion prete |
| Bouton "Utiliser" copie seulement dans le champ | 2 clics minimum pour envoyer (Utiliser puis Envoyer) |
| Pas de bouton "Modifier" explicite | Confusion entre utiliser et modifier |
| Confiance affichee en % technique | Non intuitif pour un agent non-technique |
| Panneau collapsible | Masque le draft quand le plus important est de le montrer |
| Pas de feedback apres action | Agent ne sait pas si son action a ete prise en compte |
| Pas d'auto-scroll | Le banner peut etre invisible si conversation longue |

---

## 3. Changements implementes

### 3.1 AutopilotDraftBanner.tsx — Refonte complete

**Titre clair** : "Reponse suggeree par l'IA" (au lieu de "Brouillon IA")

**Sous-titre** : "Verifiez le contenu puis envoyez en 1 clic ou modifiez avant envoi"

**Badge confiance** :
- Confiance elevee (>= 85%) — vert avec icone bouclier
- Confiance moyenne (>= 65%) — ambre avec icone bouclier
- Confiance faible (< 65%) — rouge avec icone alerte

**3 boutons d'action clairs** :
| Bouton | Icone | Action |
|---|---|---|
| **Envoyer** | Send | Envoie directement au client en 1 clic |
| **Modifier** | Pencil | Copie dans le champ reponse pour modification |
| **Ignorer** | X | Dismiss le draft |

**Feedback toast** : Message de confirmation apres chaque action
- "Message envoye"
- "Brouillon copie dans le champ de reponse"
- "Brouillon ignore"

**Auto-scroll** : `scrollIntoView({ behavior: "smooth" })` quand un draft apparait

**Design ameliore** :
- Bordure bleue visible (2px)
- Fond degrade blue-50 -> white
- Icone Bot dans un cadre arrondi
- Pas de collapse — toujours visible
- Shadow legere pour mise en evidence

### 3.2 InboxTripane.tsx — Envoi direct

Ajout de `onDirectSend` callback qui appelle `sendReply()` directement depuis le banner, avec :
- Gestion d'erreur (toast)
- Reset du champ reponse apres envoi
- Scroll vers le bas

---

## 4. Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/features/inbox/components/AutopilotDraftBanner.tsx` | Refonte complete |
| `app/inbox/InboxTripane.tsx` | Ajout prop `onDirectSend` |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Image `v3.5.148-autopilot-draft-ux-dev` |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | Image `v3.5.148-autopilot-draft-ux-prod` |

---

## 5. Avant / Apres

### Avant

```
+------------------------------------------+
| [v] Brouillon IA          72% confiance  |
|   [Sparkles] Brouillon genere...         |
|   +----------------------------------+   |
|   | texte du draft                   |   |
|   +----------------------------------+   |
|   [Utiliser]  [Ignorer]                  |
+------------------------------------------+
```
- Titre vague
- Confiance en % brut
- Collapse possible (masque le draft)
- "Utiliser" = copier seulement
- Pas de feedback

### Apres

```
+================================================+
| [Bot]  Reponse suggeree par l'IA               |
|        Verifiez puis envoyez en 1 clic         |
|        [Confiance elevee]           14:32      |
|                                                |
| +--------------------------------------------+ |
| | [Sparkles] BROUILLON GENERE A PARTIR DU    | |
| |            CONTEXTE                         | |
| |                                             | |
| | Bonjour M. Dupont,                          | |
| | Merci pour votre message...                 | |
| +--------------------------------------------+ |
|                                                |
| [Envoyer]  [Modifier]              [Ignorer]  |
+================================================+
```
- Titre explicite
- Sous-titre actionnable
- Badge confiance lisible (texte + couleur)
- 3 actions claires
- Envoyer = 1 clic direct
- Feedback toast apres action
- Auto-scroll
- Toujours visible (pas de collapse)

---

## 6. Non-regressions

### DEV

| Endpoint | Status |
|---|---|
| Client /login | 200 |
| API /health | 200 |
| Client /dashboard | 200 |
| Client /inbox | 200 |
| Client /billing | 200 |
| Client /orders | 200 |

### PROD

| Endpoint | Status |
|---|---|
| Client /login | 200 |
| API /health | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /billing | 200 |
| Client /orders | 200 |

---

## 7. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.131-autopilot-contextual-draft-dev -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.131-autopilot-contextual-draft-prod -n keybuzz-client-prod
```

Sources sauvegardees :
- `AutopilotDraftBanner.tsx.bak-pre-ph137b-ux`
- `InboxTripane.tsx.bak-pre-ph137b-ux`

---

## 8. Verdict

**DRAFT UX CLEAR — ONE CLICK SEND — USER UNDERSTANDS IMMEDIATELY — NO CONFUSION**

- Image DEV : `v3.5.148-autopilot-draft-ux-dev` — Pod 1/1 Running
- Image PROD : `v3.5.148-autopilot-draft-ux-prod` — Pod 1/1 Running
- Non-regressions DEV + PROD : OK (tous endpoints 200)
- GitOps : deployment.yaml DEV + PROD mis a jour
- PROD deploye le 1 mars 2026 apres validation Ludovic
