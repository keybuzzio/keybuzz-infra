# PH140-D — Agent Invite / Activate / Login Unification

**Phase** : PH140-D-AGENT-INVITE-ACTIVATE-LOGIN-UNIFICATION-01
**Environnements** : DEV + PROD
**Tags** : `v3.5.168-agent-invite-login-unified-dev` / `v3.5.168-agent-invite-login-unified-prod`

---

## Objectif

Unifier les deux systemes concurrents (Espaces/invitation et Agents) en un seul flow
coherent pour qu'un agent puisse etre cree, invite, active et connecte.

---

## Audit des 2 systemes

### Systeme 1 — Space Invites (PH18)

| Etape | Action | Tables |
|---|---|---|
| Admin invite | `POST /space-invites/{tenantId}/invite` | `space_invites` |
| Email envoye | Lien `/invite/{token}` (expiration 7j) | - |
| Invitee clique | Cookie `kb_invite_token` + auth | - |
| Invitee accepte | `POST /space-invites/accept` | `user_tenants` + `users` |

**Resultat** : l'invitee a un compte et un acces tenant, MAIS pas de fiche `agents`.

### Systeme 2 — Agents (PH131/PH139-B)

| Etape | Action | Tables |
|---|---|---|
| Admin cree agent | `POST /agents` | `agents` |
| Resultat | Fiche DB creee | - |

**Resultat** : une fiche agent existe, MAIS aucun email, aucun login, aucun acces.

### Cause racine

Les deux systemes ne se parlent pas :
- Creer un agent ne declenche pas d'invitation
- Accepter une invitation ne cree pas de fiche agent
- Un agent cree via l'UI ne peut pas se connecter

---

## Solution retenue

**Bridge** : la creation d'agent declenche automatiquement une invitation via space-invites.

### Flow unifie final

```
1. Admin ouvre Parametres > Agents > "Ajouter"
2. Saisie prenom, nom, email, role (agent/admin)
3. POST /api/agents → cree la fiche agents en DB
4. POST /api/space-invites/{tenantId}/invite → envoie l'email d'invitation
5. Agent recoit l'email avec lien /invite/{token}
6. Agent clique → auth (OTP ou OAuth)
7. POST /space-invites/accept → cree user + user_tenants
8. Agent redirige vers /inbox (pas /dashboard car admin-only)
9. Restrictions PH140-C appliquees (nav reduite, bandeau agent)
```

---

## Modifications

### `src/services/agents.service.ts`

- **`sendAgentInvite(tenantId, email, role)`** : nouvelle fonction qui appelle le BFF space-invites pour envoyer une invitation. Gere gracieusement le cas "deja membre".
- **`getAgentStatus(agent)`** : retourne le statut visuel selon `user_id` :
  - `user_id` present + actif → "Actif" (vert)
  - `user_id` present + inactif → "Inactif" (gris)
  - `user_id` absent → "Invitation envoyée" (ambre)

### `app/settings/components/AgentsTab.tsx`

- **Creation** : apres `createAgent()`, appel automatique `sendAgentInvite()` pour envoyer l'email.
- **Colonne Statut** : affiche "Actif" / "Inactif" / "Invitation envoyée" avec icone horloge.
- **Bouton "Inviter"** : visible pour les agents sans `user_id`, permet de (re)envoyer l'invitation.
- **Toast succes** : "Invitation envoyée à {email}" apres renvoi.

### `app/invite/continue/page.tsx`

- **Redirection role-aware** : apres acceptation, les agents et viewers sont rediriges vers `/inbox` (pas `/dashboard` qui est admin-only via PH140-C).

---

## Fichiers modifies

| Fichier | Action |
|---|---|
| `src/services/agents.service.ts` | `sendAgentInvite()` + `getAgentStatus()` |
| `app/settings/components/AgentsTab.tsx` | Invitation auto + statut + bouton renvoyer |
| `app/invite/continue/page.tsx` | Redirection agents → `/inbox` |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Tag v3.5.168 |

---

## Tests

| Cas | Attendu | Resultat |
|---|---|---|
| Creation agent via UI | Fiche creee + invitation envoyee | OK |
| Agent sans user_id | Statut "Invitation envoyée" + bouton Inviter | OK |
| Agent avec user_id actif | Statut "Actif" | OK |
| Agent inactif | Statut "Inactif" | OK |
| Renvoi invitation | Toast succes | OK |
| Acceptation invite role agent | Redirect vers /inbox | OK |
| Acceptation invite role admin | Redirect vers /dashboard | OK |
| PH140-C restrictions | Bandeau agent + nav reduite | OK |

---

## Non-regressions

| Composant | DEV | PROD |
|---|---|---|
| Owner/admin login | OK | OK |
| Onboarding tenant | OK | OK |
| Escalade (PH140-A) | OK | OK |
| Workspace agent (PH140-B) | OK | OK |
| Role scoping (PH140-C) | OK | OK |
| Signature (PH139) | OK | OK |
| Billing | OK | OK |

---

## Deploiement

| Env | Service | Image |
|---|---|---|
| DEV | keybuzz-client | `v3.5.168-agent-invite-login-unified-dev` |
| PROD | keybuzz-client | `v3.5.168-agent-invite-login-unified-prod` |

---

## Rollback

### DEV

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.167-agent-auth-scope-dev -n keybuzz-client-dev
```

### PROD

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.167-agent-auth-scope-prod -n keybuzz-client-prod
```

---

## Verdict

**AGENT FLOW UNIFIED — INVITE WORKS — ACTIVATION WORKS — LOGIN WORKS — NO DUPLICATE SYSTEM — DEPLOYE DEV + PROD**
