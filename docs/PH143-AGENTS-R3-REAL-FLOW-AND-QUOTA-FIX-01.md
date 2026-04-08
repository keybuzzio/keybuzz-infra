# PH143-AGENTS-R3-REAL-FLOW-AND-QUOTA-FIX-01

> Date : 2026-04-08
> Env : DEV uniquement
> Image : `v3.5.222-ph143-agents-real-flow-fix-dev`
> Client SHA : `fb66ba0`

---

## 1. Reproduction des 3 bugs

### Bug A — Compteur quota faux (`7/3`)

**Cause racine** : le compteur utilisait `agents.filter(a => a.type !== 'keybuzz').length` qui :
- Incluait le **owner** (admin) dans le compte
- Incluait les agents **inactifs** s'il y en avait
- Comptait tous les types d'agents sans distinction owner/invite

**Donnees DB** (6 agents, ecomlg-001, plan PRO) :

| ID | Email | Type | Role | Actif | Lie user | Comptait ? |
|----|-------|------|------|-------|----------|-----------|
| #33 | ludo.gonthier@gmail.com | client | admin | oui | oui | NON (owner) |
| #34 | test-agent@keybuzz.io | client | agent | oui | non | OUI |
| #35 | support@keybuzz.io | keybuzz | agent | oui | non | NON (keybuzz) |
| #107 | ludo.gonthier+test@gmail.com | client | agent | oui | non | OUI |
| #112 | ludo.gonthier+oly@gmail.com | client | agent | oui | oui | OUI |
| #113 | ludo.gonthier+ecomlg@gmail.com | client | agent | oui | oui | OUI |

Ancien compteur : `5/2` (tous les client) — incohérent car l'owner comptait.
Remarque : Ludovic voyait `7/3` car il a pu tester avec un plan AUTOPILOT ou 7 agents a un moment.

### Bug B — Flow invitation/login bascule vers "Créer un compte"

**Cause racine** :
1. `/invite/[token]` redirige vers `/auth/signin` (page OAuth pure)
2. L'utilisateur invite n'a pas de record dans `users` (seulement dans `agents`)
3. S'il va sur `/login`, `check-email` retourne `{ exists: false }` → page "Créer un compte"
4. Le flow OTP est bloque car pas de user record

**Page responsable** : `app/invite/[token]/page.tsx` ligne 54 (`router.push('/auth/signin')`)
**Decision fausse** : `app/login/page.tsx` ligne 83-96 → step `not_found`

### Bug C — Message AUTOPILOT trompeur

**Cause** : le texte disait "Passez au plan supérieur" quel que soit le plan.
Pour AUTOPILOT, aucun plan self-service supérieur n'existe → message trompeur.

---

## 2. Regle metier quota retenue

| Question | Reponse |
|----------|---------|
| Qui compte dans la limite ? | Agents `type=client`, `is_active=true`, `role=agent` (invités uniquement) |
| L'owner/admin compte ? | **NON** — l'owner est le porteur du plan, il ne consomme pas de slot |
| Agents pending (user_id=null) ? | **OUI** — un invite en attente consomme un slot |
| Agents inactifs ? | **NON** — seuls les actifs comptent |
| Agents KeyBuzz ? | **NON** — agents système |

**Formule** :
```
invitedAgentCount = agents.filter(a => a.type !== 'keybuzz' && a.is_active && a.role !== 'admin').length
inviteSlots = maxAgents - 1    (1 slot réservé pour l'owner)
isOverQuota = invitedAgentCount > inviteSlots
```

**Affichage** : `4/1 agents invités` (PRO, maxAgents=2, -1 pour owner = 1 slot)

---

## 3. Cause racine du flow "Créer un compte"

**Problème** : l'invite redigeait l'utilisateur vers `/auth/signin` (page NextAuth OAuth), pas `/login`.
Quand l'utilisateur tentait le login par email (OTP) :
- `check-email` → `exists: false` (pas de record users)
- Login page → state `not_found` → bouton "Créer un compte"

**Fix** : double correction :
1. `/invite/[token]` redirige maintenant vers `/login?invite_token=xxx` (pas `/auth/signin`)
2. `/login` détecte `invite_token` et montre un écran dédié avec Google/Microsoft + "Créer un compte"
   au lieu de l'écran générique "Aucun compte trouvé"

---

## 4. Corrections appliquees

### Fichiers modifies (3 fichiers)

| Fichier | Changement |
|---------|-----------|
| `app/settings/components/AgentsTab.tsx` | Nouveau calcul quota, bouton toujours actif, message AUTOPILOT |
| `app/invite/[token]/page.tsx` | Redirect `/login?invite_token=xxx` au lieu de `/auth/signin` |
| `app/login/page.tsx` | Detection `invite_token`, écran invite dédié avec OAuth |

### AgentsTab — avant/apres

| Aspect | Avant R3 | Apres R3 |
|--------|---------|---------|
| Compteur | `agents.filter(a => a.type !== 'keybuzz').length / maxAgents` | `filter(active + agent role) / (maxAgents - 1)` |
| Label | `x/y` | `x/y agents invités` |
| Bouton Ajouter | Désactivé si `isAtLimit` | **Toujours actif** (API enforce) |
| Banniere PRO | "passez au plan supérieur" | "passez au plan supérieur" |
| Banniere AUTOPILOT | "passez au plan supérieur" (faux) | "contactez-nous pour un plan Entreprise" |
| CTA AUTOPILOT | lien /billing/plan | mailto:contact@keybuzz.io |

### Invite flow — avant/apres

| Aspect | Avant R3 | Apres R3 |
|--------|---------|---------|
| Redirect invite | `/auth/signin` (OAuth) | `/login?invite_token=xxx` |
| Email inconnu + invite | "Créer un compte" | Écran dédié: "Vous avez été invité(e)" + OAuth + Créer un compte |
| Email inconnu sans invite | "Créer un compte" | "Créer un compte" (inchangé) |

---

## 5. Tests E2E

| Test | Résultat |
|------|---------|
| Agent data coherente | OK — 4 invited, 1 owner, 1 keybuzz |
| Login page | 200 OK |
| Login + invite_token | 200 OK |
| Invite/token page | 200 OK |
| API agent creation | 201 Created |
| API invite send | 200 `{"success":true}` |
| Dashboard | 307 (redirect auth) OK |
| Inbox | 307 (redirect auth) OK |
| Billing | 307 (redirect auth) OK |
| AgentsTab quota logic | `invitedAgentCount=4, inviteSlots=1, isOverQuota=true` |
| Invite redirect | `/login?invite_token=xxx&callbackUrl=...` |
| Login invite detection | `inviteToken` extracte de searchParams |

---

## 6. Image DEV

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.222-ph143-agents-real-flow-fix-dev
```

Deployment : `keybuzz-client-dev` → pod Running, Health OK.

---

## 7. Commits

| SHA | Message |
|-----|---------|
| `fb66ba0` | PH143-AGENTS-R3: fix quota counter, invite flow, AUTOPILOT message |

---

## 8. Verdict

### REAL AGENT FLOW RESTORED

Les 3 bugs identifies par Ludovic sont corriges :
1. **Compteur** : affiche uniquement les agents invites actifs, exclut l'owner
2. **Flow invite** : redirige vers `/login` avec detection invite, ecran dedie OAuth + signup
3. **Message AUTOPILOT** : CTA "Contactez-nous" au lieu de "plan superieur"

Le bouton "Ajouter" reste actif en permanence — l'API est le garant reel des limites
(y compris billing-exempt pour ecomlg-001).

---

## 9. Validation manuelle Ludovic

Checklist pour validation navigateur :

- [ ] Aller sur Settings > Agents
- [ ] Verifier le compteur : `4/1 agents invités` (pas `7/3`)
- [ ] Verifier le bouton Ajouter est cliquable
- [ ] Verifier la banniere ambre avec le bon message
- [ ] Creer un agent test avec un email +alias
- [ ] Recevoir le mail d'invitation
- [ ] Cliquer le lien : verifier qu'on arrive sur `/login?invite_token=...`
- [ ] Entrer l'email : verifier qu'on voit l'ecran "Vous avez été invité(e)" avec Google/Microsoft
- [ ] Se connecter via Google : verifier redirection vers `/invite/continue`
- [ ] Verifier l'agent lie (user_id non NULL)
- [ ] Se connecter en tant qu'agent : verifier nav réduite
- [ ] Verifier `/settings` bloque pour l'agent

---

## 10. Rollback

```bash
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh client dev v3.5.221-ph143-agents-full-recovery-dev
```
