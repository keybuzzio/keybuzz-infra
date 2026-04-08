# PH143-AGENTS-R2 — Full Module Truth Recovery

> Date : 2026-04-08
> Auteur : Agent Cursor (CE)
> Phase : PH143-AGENTS-R2-FULL-MODULE-TRUTH-RECOVERY-01
> Env : DEV uniquement

---

## 1. Phases sources retrouvées

| Phase | Feature | Couche | Présent dans release/client-v3.5.220 ? |
|-------|---------|--------|----------------------------------------|
| PH139-B | Agent par défaut, type `client` forcé à la création | Both | Oui (type 'client' hardcodé) |
| PH140-B | Agent Workspace (barre 4 vues, actions 1 clic) | Client | Oui (AgentWorkbenchBar, ConversationActionBar) |
| PH140-C | Auth Role Scoping, bandeau Mode Agent, nav réduite | Both | Oui (ClientLayout, middleware, routeAccessGuard) |
| PH140-D | Invite auto après création agent | Both | **NON** — `sendAgentInvite` absent |
| PH140-H | Linkage `agents.user_id` à l'accept | API | Corrigé en PH143-AGENTS-R1 |
| PH140-I | Invite UX polish (email prérempli, resolve) | Both | Oui (invite pages) |
| PH140-J | Hard Access Lockdown (admin-only routes, /no-access) | Client | Oui (middleware + routeAccessGuard) |
| PH141-A | Agent limits par plan, compteur x/y, bannière ambre | Both | **NON** — compteur et bannière absents du composant |
| PH141-B | Limits alignment (Pro=2, Autopilot=3), exclusion keybuzz du compteur | Both | `planCapabilities.ts` OK, **AgentsTab.tsx** manquant |
| PH141-C | KeyBuzz agent lockdown (POST public interdit) | API | Oui (API deployed) |
| PH143-R1 | Billing-exempt bypass + linkage user_id | API | Oui (`v3.5.48-ph143-agents-fix-dev`) |

---

## 2. Vérité historique du module Agents complet

Le module Agents complet validé historiquement inclut :

### Client
1. ✅ Création agent avec type `client` uniquement (KeyBuzz exclu)
2. ❌ **Envoi automatique d'invitation après création** (sendAgentInvite)
3. ❌ **Compteur quota x/y** (agents clients / max plan)
4. ❌ **Bannière ambre quand limite atteinte** + CTA upgrade
5. ❌ **Bouton Ajouter désactivé quand limite atteinte**
6. ❌ **Bouton renvoi invitation** pour agents en attente
7. ❌ **Statut agent détaillé** (Actif / En attente / Inactif)
8. ✅ Mode focus agent (nav réduite)
9. ✅ Bandeau "Mode Agent" vert
10. ✅ Restrictions RBAC middleware
11. ✅ Agent Workspace (barre 4 vues)

### API
12. ✅ Création agent avec limites par plan
13. ✅ Billing-exempt bypass
14. ✅ Linkage agents.user_id à l'accept
15. ✅ KeyBuzz lockdown (POST public interdit)
16. ✅ Envoi email invitation (space-invites)

---

## 3. Cartographie manque actuel vs attendu

| # | Feature | État avant R2 | État après R2 |
|---|---------|--------------|---------------|
| 1 | Compteur quota x/y | ❌ Seulement `agents.length` | ✅ `clientCount/maxAgents` |
| 2 | Bannière limite atteinte | ❌ Absente | ✅ Ambre + texte plan + CTA |
| 3 | Upsell CTA "Voir les plans" | ❌ Absent | ✅ Lien /billing/plan |
| 4 | Bouton Ajouter désactivé | ❌ Toujours actif | ✅ Grisé quand limite |
| 5 | sendAgentInvite auto | ❌ Fonction absente | ✅ Invocation après createAgent |
| 6 | Bouton renvoi invitation | ❌ Absent | ✅ Pour agents sans user_id |
| 7 | Statut détaillé | ❌ Simple Actif/Inactif | ✅ Actif/En attente/Inactif |
| 8 | getAgentStatus helper | ❌ Absent | ✅ Ajouté au service |
| 9 | Badge invite success | ❌ Absent | ✅ Message vert temporaire |
| 10 | Type forcé 'client' | ✅ (déjà) | ✅ (conservé) |
| 11 | RBAC / nav réduite | ✅ (déjà) | ✅ (conservé) |
| 12 | Bandeau Mode Agent | ✅ (déjà) | ✅ (conservé) |

---

## 4. Stratégie de reconstruction

**Stratégie retenue : implémentation directe** sur `release/client-v3.5.220`

Raison : les changements manquants ne pouvaient pas être cherry-pickés depuis `origin/main` (contaminée par Studio). Les modifications étant bien délimitées (2 fichiers, ~150 lignes), une implémentation directe alignée sur la vérité historique PH141-A/B était la plus sûre.

### Fichiers modifiés

| Fichier | Changement | Lignes |
|---------|-----------|--------|
| `app/settings/components/AgentsTab.tsx` | Réécriture complète avec toutes les features | +149 -45 |
| `src/services/agents.service.ts` | Ajout `sendAgentInvite` + `getAgentStatus` | +26 |
| `src/features/billing/planCapabilities.ts` | Déjà présent (maxAgents) | 0 |

---

## 5. Commits et fichiers repris

### Client (release/client-v3.5.220)
- **SHA** : `a51dc7e`
- **Message** : `PH143-AGENTS-R2: full agents module recovery`
- **Fichiers** :
  - `app/settings/components/AgentsTab.tsx`
  - `src/services/agents.service.ts`

### API (inchangée)
- **Image déployée** : `v3.5.48-ph143-agents-fix-dev`
- **Fixes PH143-R1** : billing-exempt bypass + linkage user_id (déjà en place)

### planCapabilities.ts (déjà présent)
- `maxAgents` : STARTER=1, PRO=2, AUTOPILOT=3, ENTERPRISE=Infinity
- `maxKeybuzzAgents` : 0/0/1/3

---

## 6. Image DEV

| Service | Image |
|---------|-------|
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.221-ph143-agents-full-recovery-dev` |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph143-agents-fix-dev` |

---

## 7. Tests E2E réels

| Test | Résultat | Détail |
|------|---------|--------|
| Création agent API | ✅ HTTP 201 | Billing-exempt bypass actif |
| Envoi invitation API | ✅ HTTP 200 | "Invitation sent" |
| Invite créée en DB | ✅ | Token généré, accepted_at=null |
| Billing exempt | ✅ | ecomlg-001 = true |
| Pages client (curl) | ✅ | Toutes retournent 307 (redirect login attendu) |
| Cleanup test | ✅ | Agent + invite de test supprimés |

---

## 8. Détail des modifications AgentsTab.tsx

### Nouveau compteur quota
```tsx
<span className={`... ${isAtLimit ? 'bg-amber-100 text-amber-700' : 'bg-gray-100 text-gray-600'}`}>
  {clientAgentCount}/{maxAgents}
</span>
```

### Bannière limite atteinte
Affichée automatiquement quand `clientAgentCount >= maxAgents` :
- Icône AlertTriangle
- Message "Limite d'agents atteinte (x/y)"
- Texte explicatif avec nom du plan
- Lien "Voir les plans" → /billing/plan

### Bouton Ajouter
Désactivé (grisé) quand la limite est atteinte, avec `cursor-not-allowed`.

### Envoi invitation automatique
Après `createAgent()`, appel automatique à `sendAgentInvite()` :
- Email d'invitation envoyé immédiatement
- Échec silencieux si l'utilisateur est déjà membre

### Bouton renvoi invitation
Pour chaque agent sans `user_id` (invitation non acceptée), bouton "Inviter" avec icône Send.

### Statut détaillé
Via `getAgentStatus()` :
- **Actif** (vert) : `is_active` + `user_id` non null
- **En attente** (jaune + icône Clock) : `is_active` + `user_id` null
- **Inactif** (gris) : `!is_active`

---

## 9. Fonctionnalités déjà présentes (non modifiées)

| Feature | Source | Fichier |
|---------|--------|---------|
| Nav réduite agent | PH140-C | `ClientLayout.tsx` (agentAllowed) |
| Bandeau "Mode Agent" | PH140-C | `ClientLayout.tsx` |
| RBAC middleware | PH140-J | `middleware.ts` + `routeAccessGuard.ts` |
| Admin-only routes | PH140-J | `/settings, /billing, /channels, /dashboard, /knowledge, /ai-journal, /admin` |
| Matrice permissions | PH140-C | `roles.ts` |
| Invite accept flow | PH140-D/H | `invite/[token]`, `invite/continue` |
| Agent Workspace | PH140-B | `AgentWorkbenchBar.tsx` |

---

## 10. Rollback

```bash
# Client DEV
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh client dev v3.5.220-ph143-clean-release-dev
```

---

## 11. Validation UI par Ludovic (à faire)

1. Ouvrir Settings > Agents
2. Vérifier compteur `x/y` visible (ex: 5/2 si billing-exempt)
3. Vérifier bannière ambre si limite atteinte
4. Vérifier bouton "Ajouter" grisé si limite (non-exempt)
5. Créer un agent → vérifier invitation envoyée par email
6. Vérifier statut "En attente" pour agent non accepté
7. Vérifier bouton "Inviter" pour renvoi
8. Se connecter en tant qu'agent → nav réduite + bandeau Mode Agent
9. Tenter /settings en tant qu'agent → redirection /inbox

---

## Verdict

**FULL AGENTS MODULE RESTORED**

Le module Agents complet est reconstruit avec :
- ✅ Compteur quota x/y plan-aware
- ✅ Bannière limite + upsell CTA
- ✅ Invitation automatique à la création
- ✅ Renvoi d'invitation
- ✅ Statuts détaillés (Actif / En attente / Inactif)
- ✅ KeyBuzz exclu de la création publique
- ✅ Mode focus agent (nav réduite + bandeau)
- ✅ RBAC middleware + restrictions URL
- ✅ API : billing-exempt bypass + linkage user_id
- ✅ API : limites agents par plan
