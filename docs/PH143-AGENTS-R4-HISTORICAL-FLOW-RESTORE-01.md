# PH143-AGENTS-R4-HISTORICAL-FLOW-RESTORE-01

> Date : 2026-04-08
> Env : DEV uniquement
> Image : `v3.5.223-ph143-agents-historical-flow-dev`
> Client SHA : `28669ad`

---

## 1. Verite historique retrouvee

### Comptage agents

La regle historique validee par Ludovic :
- **L'admin/owner COMPTE** dans le total
- Le compteur affiche `activeClientCount / maxAgents`
- Pas de soustraction, pas de logique "agents invites"
- En AUTOPILOT avec 3 agents actifs → `3/3`
- En PRO avec 5 agents actifs (billing-exempt) → `5/2`

### Flow OTP pour agents invites

Le flow historique valide :
1. Admin cree un agent + invitation envoyee par email
2. Agent invite clique le lien → `/invite/[token]`
3. Token stocke en cookie, redirection vers `/login?invite_token=xxx`
4. Page login : email entre, check-email **BYPASSE** (invite_token present)
5. OTP envoye directement via `magic/start` (fonctionne pour tout email)
6. Code OTP verifie via NextAuth `email-otp` (ne verifie pas l'existence user en DB)
7. Session JWT creee avec `id = email`
8. Redirection vers `/invite/continue?token=xxx`
9. Endpoint accept : cree le user si necessaire, lie au tenant, lie a l'agent
10. Redirection vers `/dashboard`

### Pourquoi ca marche techniquement

- `magic/start` (BFF) : genere OTP + envoie email — **aucun check user en DB**
- `authorize` (NextAuth) : appelle `verifyOTP(email, code)` — **retourne `{ id: email }` sans toucher la DB**
- Le SEUL blocage etait le `check-email` dans la page `/login` qui retournait `exists: false`
- Solution : **skip `check-email` quand `invite_token` est present**

---

## 2. Ce que R3 avait reinvente a tort

| Element R3 | Probleme | Correction R4 |
|-----------|---------|--------------|
| Ecran "Vous avez ete invite(e)" | Flow invente, pas historique | **Supprime** |
| Boutons Google/Microsoft/Creer sur ecran invite | UX inventee | **Supprime** |
| `invitedAgentCount` (exclut admin) | Regle fausse | `activeClientCount` (admin inclus) |
| `inviteSlots = maxAgents - 1` | Soustraction inventee | `maxAgents` direct |
| Label "x/y agents invites" | Wording invente | `x/y` simple |

---

## 3. Regle quota restauree

| Question | Reponse |
|----------|---------|
| Qui compte ? | Tous les agents `type=client` ET `is_active=true` |
| Admin/owner compte ? | **OUI** |
| Agents pending (user_id=null) comptent ? | OUI s'ils sont actifs |
| Agents keybuzz comptent ? | NON |
| Agents inactifs comptent ? | NON |

**Formule** :
```typescript
const activeClientCount = agents.filter(a => a.type !== 'keybuzz' && a.is_active).length;
const isOverQuota = activeClientCount > maxAgents;
```

**Affichage** : `{activeClientCount}/{maxAgents}`

### Exemples :
| Plan | maxAgents | Donnees actuelles | Affichage |
|------|-----------|-------------------|-----------|
| STARTER | 1 | 5 actifs | `5/1` |
| PRO | 2 | 5 actifs | `5/2` |
| AUTOPILOT | 3 | 3 actifs | `3/3` |
| ENTERPRISE | Infinity | 5 actifs | `5/∞` |

### Bouton Ajouter
Toujours actif — l'API est le garant reel des limites (y compris billing-exempt).
Si l'API retourne 403, l'erreur est affichee dans le modal.

### Banniere AUTOPILOT
- PRO/STARTER : "Passez au plan superieur" + lien `/billing/plan`
- AUTOPILOT/ENTERPRISE : "Contactez-nous pour un plan Entreprise" + `mailto:contact@keybuzz.io`

---

## 4. Flow OTP restaure

### Fichiers modifies (2 fichiers)

| Fichier | Changement |
|---------|-----------|
| `app/settings/components/AgentsTab.tsx` | Quota: admin compte, `activeClientCount/maxAgents` |
| `app/login/page.tsx` | Skip check-email si invite_token, redirect callbackUrl, suppression ecran R3 |

### Avant/apres login page

| Aspect | R3 (faux) | R4 (historique) |
|--------|----------|----------------|
| Invite + email inconnu | Ecran custom "Vous avez ete invite(e)" | Login normal, OTP direct |
| check-email avec invite | Bypasse → ecran custom | Bypasse → OTP directement |
| Apres OTP success + invite | `onLoginSuccess()` | `router.push(callbackUrl)` → `/invite/continue` |
| Ecran not_found + invite | 3061 chars de JSX custom | Meme ecran standard que sans invite |

### Avant/apres AgentsTab

| Aspect | R3 (faux) | R4 (historique) |
|--------|----------|----------------|
| Compteur | `invitedAgentCount/inviteSlots` | `activeClientCount/maxAgents` |
| Admin dans le total | Non (exclu via `role !== 'admin'`) | Oui (inclus) |
| Label | "x/y agents invites" | "x/y" |
| Soustraction | `inviteSlots = maxAgents - 1` | Pas de soustraction |

---

## 5. Tests E2E

| Test | Resultat |
|------|---------|
| Agent data coherente (5 client actifs + 1 keybuzz) | OK |
| Compteur attendu `5/2` (PRO, admin compte) | OK |
| API creation agent | 201 Created |
| API envoi invite | 200 Success |
| Login page | 200 |
| Login + invite_token | 200 |
| Invite/[token] page | 200 |
| Pas d'ecran "Vous avez ete invite(e)" | OK (0 occurrences) |
| check-email bypasse avec invite_token | OK (ligne 89) |
| callbackUrl redirect apres OTP | OK (lignes 73-74) |
| Pages auth (inbox, billing, settings, dashboard) | 307 (redirect auth) OK |

---

## 6. Image DEV

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.223-ph143-agents-historical-flow-dev
```

Pod Running, Health OK.

---

## 7. Commits

| SHA | Message |
|-----|---------|
| `28669ad` | PH143-AGENTS-R4: restore historical agent flow |

---

## 8. Verdict

### HISTORICAL AGENT FLOW RESTORED

Les 3 corrections de R3 qui etaient fausses ont ete rectifiees :
1. **Quota** : admin compte dans le total → `activeClientCount/maxAgents`
2. **Login invite** : pas d'ecran custom, OTP direct avec bypass check-email
3. **Redirect** : apres OTP success, callbackUrl → `/invite/continue` → accept → dashboard

---

## 9. Validation manuelle Ludovic

Checklist pour tester le flow reel en navigateur :

- [ ] Aller sur Settings > Agents → verifier compteur `5/2` (pas `7/3` ni `4/1`)
- [ ] Bouton Ajouter cliquable
- [ ] Creer un agent test avec email `+alias`
- [ ] Recevoir le mail d'invitation
- [ ] Cliquer le lien : verifier redirection vers `/login?invite_token=...`
- [ ] Page login NORMALE (pas d'ecran "Vous avez ete invite(e)")
- [ ] Entrer l'email invite → OTP envoye directement (pas de "Creer un compte")
- [ ] Entrer le code OTP → connexion reussie
- [ ] Redirection vers `/invite/continue` → acceptation → dashboard
- [ ] Verifier agent lie (user_id non NULL)
- [ ] Se connecter en tant qu'agent : nav reduite, /settings bloque

---

## 10. Rollback

```bash
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh client dev v3.5.222-ph143-agents-real-flow-fix-dev
```
