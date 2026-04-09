# PH142-L — Feature Truth Recovery

> Date : 1 mars 2026
> Type : Audit verite par phases (aucune implementation)
> Methode : relecture 48 docs de phase + audit code bastion + git log

---

## 1. Resume executif

**Cause racine des regressions identifiee** : les phases PH138-* (billing/addon) et PH141-E (deep-links) ont ete deployees via scripts Python directs sur le bastion SANS etre commitees dans Git. Lors des rebuilds ulteri eurs (PH142-E a PH142-J), le code a ete reconstruit depuis le repo Git qui ne contenait pas ces modifications. Les features ont ete **integralement perdues cote client**.

**Le backend API est INTACT** — toutes les features PH138 et PH141 existent cote serveur.

**Impact** : 5 features client majeures perdues, toutes livrables par restauration.

---

## 2. Source de verite reconstruite par phases

### PH138 — Billing / Agent KeyBuzz (13 phases)

| Phase | Feature livree | Fichier client principal | Statut actuel |
|---|---|---|---|
| PH138-A | Backend addon Agent KeyBuzz (DB + endpoints) | — (backend) | **OK** (backend intact) |
| PH138-B | UI gating addon dans AutopilotSection | `AutopilotSection.tsx` | **KO** (perdu) |
| PH138-C | Checkout Stripe obligatoire pour addon | `AutopilotSection.tsx` | **KO** (perdu) |
| PH138-D | CTAs upgrade plan cliquables (`upgradePlan()`) | `AutopilotSection.tsx` | **KO** (perdu) |
| PH138-E | Fallback checkout si pas de subscription | `AutopilotSection.tsx` | **KO** (perdu) |
| PH138-F | Sync URL post-checkout + auto-mode | `AutopilotSection.tsx` | **KO** (perdu) |
| PH138-G | Fix double subscription + redirect | `AutopilotSection.tsx` + backend | **Backend OK, client KO** |
| PH138-H | `hasAgentKeybuzzAddon` dans useCurrentPlan | `useCurrentPlan.tsx` | **KO** (perdu) |
| PH138-I | div role="button" pour CTAs dans cartes verouillees | `AutopilotSection.tsx` | **KO** (perdu) |
| PH138-J | Audit lecture seule | — | N/A |
| PH138-K | Checkout obligatoire final (backend + UI) | `AutopilotSection.tsx` + backend | **Backend OK, client KO** |
| PH138-L | Visual premium (badges, couleurs) | `AutopilotSection.tsx` | **KO** (perdu) |
| PH138-M | Produit/prix Stripe LIVE en PROD | env/deployment | **OK** (infra intacte) |

### PH139 — Signature (3 phases)

| Phase | Feature livree | Statut actuel |
|---|---|---|
| PH139 | SignatureTab + backend resolver | **OK** (backend intact, tab restaure PH142-J) |
| PH139-B | Agent par defaut + lockdown type=keybuzz | **OK** (backend intact) |
| PH139-C | UX signature (preview, fix skeleton) | **PARTIEL** (tab OK, mais preview non verifie) |

### PH141 — Agents / Limites (6 phases)

| Phase | Feature livree | Fichier client | Statut actuel |
|---|---|---|---|
| PH141-A | Limites agents par plan (UI + backend) | `AgentsTab.tsx`, `planCapabilities.ts` | **Backend OK, client KO** |
| PH141-B | Limites corrigees (Pro 2, Autopilot 3) + KeyBuzz separees | `AgentsTab.tsx`, `planCapabilities.ts` | **Backend OK, client KO** |
| PH141-C | Lockdown creation KeyBuzz publique + route interne | backend only | **OK** (backend intact) |
| PH141-D | Audit polish (lecture seule) | — | N/A |
| PH141-E | Deep-links `?tab=xxx` dans settings | `settings/page.tsx` | **KO** (perdu) |
| PH141-F | Contexte IA (ne pas redemander infos) | backend/prompts | **OK** |

### PH142 — IA / Autopilot / Audit (11 phases)

| Phase | Feature livree | Statut actuel |
|---|---|---|
| PH142-A | AI quality loop (flag erreur) | **OK** |
| PH142-B | AI error clustering | **OK** |
| PH142-C | AI action consistency (false promises) | **OK** |
| PH142-D | Auto-escalade | **OK** |
| PH142-E | Autopilot safe mode draft recovery | **OK** |
| PH142-F | Unified AI drawer | **OK** |
| PH142-G | Draft lifecycle + KBActions truth | **OK** |
| PH142-H | Full regression audit | N/A (audit) |
| PH142-I | Pre-prod check script | **OK** |
| PH142-J | Signature tab restore | **OK** |
| PH142-K | Critical feature truth audit | N/A (audit) |

---

## 3. Matrice attendu vs actuel

### A. Billing / Upsell / Agent KeyBuzz

| Feature | Source | Attendu | Actuel | Statut |
|---|---|---|---|---|
| CTA "Passez au plan Autopilot" cliquable | PH138-D | `upgradePlan()` → change-plan/checkout | `<p>` texte mort | **KO** |
| CTA "Activer Agent KeyBuzz" cliquable | PH138-B/C/K | `activateAddon()` → checkout Stripe | Inexistant | **KO** |
| Badge/couronne addon premium | PH138-L | Style purple + Crown icon | Inexistant | **KO** |
| `hasAgentKeybuzzAddon` dans useCurrentPlan | PH138-H | Prop exposee depuis /billing/current | Absente | **KO** |
| Gating addon dans AutopilotSection | PH138-B | Lock/Crown selon plan+addon | Lock simple par plan | **KO** |
| Fallback checkout si pas de sub | PH138-E | Toast + redirect Checkout | Inexistant | **KO** |
| Sync URL post-checkout (?tab=ai) | PH138-F/G | Auto-refetch + toast + mode auto | Inexistant | **KO** |
| div role="button" au lieu de button disabled | PH138-I | CTAs enfants cliquables | button disabled | **KO** |
| Backend addon endpoints | PH138-A/C/K | checkout-agent-keybuzz, status, update | **Presents** | **OK** |
| Produit Stripe LIVE PROD | PH138-M | IDs LIVE dans env | **Present** | **OK** |
| /billing/current expose hasAgentKeybuzzAddon | PH138-A | `hasAgentKeybuzzAddon: bool` | **Present** | **OK** |

### B. Settings

| Feature | Source | Attendu | Actuel | Statut |
|---|---|---|---|---|
| Deep-links `?tab=xxx` | PH141-E | useSearchParams + validTabs | Absent | **KO** |
| Signature tab | PH139/PH142-J | Onglet visible | **Present** | **OK** |
| Tous onglets (10) | PH131-A/PH142-J | 10 onglets | **Present** | **OK** |

### C. Agents / Limites

| Feature | Source | Attendu | Actuel | Statut |
|---|---|---|---|---|
| maxAgents dans planCapabilities | PH141-A/B | Starter 1, Pro 2, Autopilot 3 | Absent | **KO** |
| Compteur + limite dans AgentsTab UI | PH141-A/B | Badge X/Y + banniere upsell | Absent | **KO** |
| Backend AGENT_LIMIT_REACHED | PH141-A | 403 si limite | **Present** | **OK** |
| Backend KEYBUZZ_AGENT_LIMITS | PH141-B | Limites separees | **Present** | **OK** |
| Route /agents/internal-keybuzz | PH141-C | Endpoint interne protege | **Present** | **OK** |

---

## 4. Contradictions majeures resolues

### Contradiction 1 : "Agent KeyBuzz jamais implemente" (PH142-K) vs "livre en PH138-*"

**Resolution** : L'Agent KeyBuzz a ete **pleinement implemente** dans PH138-A a PH138-M (backend + UI). Le backend est **intact**. Seul le code client (`AutopilotSection.tsx`) a ete perdu car les modifications etaient faites par scripts Python sur le bastion sans commit Git. Lors du rebuild PH142-E, le fichier a ete reconstruit depuis le repo Git (version PH131-B.2) sans les ajouts PH138.

**Preuve** : git log montre le dernier commit sur `AutopilotSection.tsx` = `PH131-B.2` (avant PH138).

### Contradiction 2 : "Deep-links jamais implementes" (PH142-K) vs "livres en PH141-E"

**Resolution** : Les deep-links ont ete implementes dans PH141-E (`useSearchParams` + `validTabs`). Le code a ete perdu lors du rebuild PH142-J/E car `settings/page.tsx` a ete modifie a partir du repo Git (dernier commit PH131-A).

**Preuve** : git log montre le dernier commit sur `settings/page.tsx` = `PH131-A` (avant PH141-E).

### Contradiction 3 : "Limites agents jamais implementees" (PH142-K) vs "livrees en PH141-A/B"

**Resolution** : Les limites agents ont ete implementees cote client (compteur, banniere upsell dans `AgentsTab.tsx`) et cote `planCapabilities.ts`. Le code client a ete perdu par le meme mecanisme. Le backend (`agents/routes.ts`) est intact avec `AGENT_LIMITS` et `KEYBUZZ_AGENT_LIMITS`.

**Preuve** : git log montre le dernier commit sur `planCapabilities.ts` = `PH129` (avant PH141-A).

### Mecanisme de regression systemique

```
1. Phases PH138/PH141-E deployees via scripts Python sur bastion
2. Modifications appliquees directement aux fichiers source
3. Builds Docker faits depuis les fichiers modifies → deploiement OK
4. MAIS : modifications JAMAIS commitees dans Git
5. Lors d'un rebuild ulterieur (PH142-*), le repo Git est pull
6. Le pull ecrase les fichiers modifies avec la version Git (sans PH138/PH141-E)
7. Le build Docker est fait depuis la version Git → features perdues
```

---

## 5. Focus billing / upsell / Agent KeyBuzz

### Etat reel

| Couche | Statut |
|---|---|
| Stripe PROD (produit + prix LIVE) | **OK** |
| Backend API (checkout, status, webhook) | **OK** |
| Base de donnees (has_agent_keybuzz_addon) | **OK** |
| BFF client (routes proxy) | **A VERIFIER** |
| UI AutopilotSection (gating, CTAs, badges) | **KO — entierement perdu** |
| UI useCurrentPlan (hasAgentKeybuzzAddon) | **KO — prop absente** |

### Ce qu'il faut restaurer (client uniquement)

1. `AutopilotSection.tsx` : ajouter `upgradePlan()`, `activateAddon()`, gating addon, badges premium, div role="button", fallback checkout, sync URL
2. `useCurrentPlan.tsx` : ajouter `hasAgentKeybuzzAddon` depuis `/billing/current`
3. BFF : verifier `app/api/billing/checkout-agent-keybuzz/route.ts` et `agent-keybuzz-status/route.ts`

---

## 6. Focus settings / signature / deep-links

### Deep-links `?tab=xxx`

| Element | Source PH141-E | Actuel | Action |
|---|---|---|---|
| `useSearchParams()` | Ajoute | Absent | Restaurer |
| `validTabs` array | Ajoute | Absent | Restaurer |
| `useEffect` init tab | Ajoute | Absent | Restaurer |

### Signature

| Element | Source | Actuel |
|---|---|---|
| SignatureTab composant | PH139 | **OK** |
| Import dans settings/page.tsx | PH142-J | **OK** |
| Backend resolver | PH139 | **OK** |
| Preview resolu (resolvedPreview) | PH139-C | A verifier |

---

## 7. Plan de recuperation priorise

### P0 — Regressions critiques (a corriger en priorite)

| # | Feature | Fichier | Effort | Phase source |
|---|---|---|---|---|
| P0.1 | CTAs upgrade plan cliquables | `AutopilotSection.tsx` | 30 min | PH138-D/E/I |
| P0.2 | Deep-links settings `?tab=xxx` | `settings/page.tsx` | 15 min | PH141-E |

### P1 — Agent KeyBuzz addon (a corriger)

| # | Feature | Fichier | Effort | Phase source |
|---|---|---|---|---|
| P1.1 | `hasAgentKeybuzzAddon` dans useCurrentPlan | `useCurrentPlan.tsx` | 10 min | PH138-H |
| P1.2 | Gating addon dans AutopilotSection | `AutopilotSection.tsx` | 45 min | PH138-B/C/K |
| P1.3 | Badge premium + CTA addon | `AutopilotSection.tsx` | 20 min | PH138-L |
| P1.4 | Sync URL post-checkout | `AutopilotSection.tsx` | 15 min | PH138-F/G |
| P1.5 | BFF routes addon | `app/api/billing/` | 15 min | PH138-B/C |

### P2 — Limites agents UI (a corriger)

| # | Feature | Fichier | Effort | Phase source |
|---|---|---|---|---|
| P2.1 | maxAgents dans planCapabilities | `planCapabilities.ts` | 5 min | PH141-A/B |
| P2.2 | Compteur + limite dans AgentsTab | `AgentsTab.tsx` | 20 min | PH141-A/B |

### Effort total estime : ~3h

---

## 8. Proposition pre-prod-check V2

### Principe anti-regression

Le probleme fondamental est que les modifications faites par script Python ne sont pas commitees. La V2 du check doit detecter les incoherences entre le code deploye et les features attendues.

### Checks supplementaires proposes

| # | Check | Methode | Detecte |
|---|---|---|---|
| 11 | AutopilotSection contient `upgradePlan` | `grep` dans le pod | PH138-D perdu |
| 12 | AutopilotSection contient `activateAddon` | `grep` dans le pod | PH138-B perdu |
| 13 | useCurrentPlan contient `hasAgentKeybuzz` | `grep` dans le pod | PH138-H perdu |
| 14 | settings/page contient `useSearchParams` | `grep` dans le pod | PH141-E perdu |
| 15 | planCapabilities contient `maxAgents` | `grep` dans le pod | PH141-A perdu |
| 16 | BFF checkout-agent-keybuzz existe | `ls` dans le pod | PH138-C perdu |
| 17 | Settings 10+ onglets (grep `tabs`) | `grep` dans le pod | Onglet supprime |
| 18 | API agent-keybuzz-status 200 | HTTP GET interne | Backend OK |

### Recommandation critique

**Apres chaque phase, commiter les modifications dans Git avant le build Docker.**
Le script Python peut etre suivi d'un `git add && git commit` automatique.
Sans cela, toute modification sera perdue au prochain rebuild depuis le repo.
