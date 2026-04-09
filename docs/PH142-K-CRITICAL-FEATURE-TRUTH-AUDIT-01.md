# PH142-K — Critical Feature Truth Audit

> Date : 1 mars 2026
> Type : Audit verite (aucune implementation)
> Methode : audit code bastion + tests navigateur reels DEV

---

## 1. Resume executif

Audit complet des features critiques visibles cote client (billing, upsell, IA, settings, agents).

**3 regressions identifiees, 1 lacune produit, 1 comportement attendu :**

| # | Probleme | Gravite | Type |
|---|---|---|---|
| R1 | CTA upgrade non cliquables dans Settings > IA | **CRITIQUE** | Regression UX |
| R2 | Deep-links settings `?tab=xxx` non supportes | **MAJEUR** | Jamais implemente |
| R3 | Add-on "Agent KeyBuzz" inexistant dans le code | **MAJEUR** | Jamais implemente |
| OK | Boutons Stripe disabled sur billing_exempt tenant | Info | Comportement attendu |

---

## 2. Matrice des features critiques testees

### A. Billing / Upsell / Plans

| Feature | Statut | Detail |
|---|---|---|
| Page /billing | **OK** | Plan PRO affiche, KBActions 959.35, canaux 4/3 |
| Page /billing/plan | **OK** | Plan Pro details, inclusions listees |
| Bouton "Changer de plan" | **PARTIEL** | Disabled car `isFallback=true` (tenant billing_exempt) — attendu |
| Bouton "Gerer via Stripe" | **PARTIEL** | Disabled car `isFallback=true` — attendu |
| Lien "Comparer les offres" | **OK** | Cliquable, redirige vers /pricing |
| Page /pricing | **OK** | 4 plans affiches, CTAs "Demarrer", "Passer en Pro", "Activer Autopilot" |
| Page /billing/ai | **OK** | Solde 959.35, dotation 1000, packs achetes 50, bouton "Acheter" |
| Locked/paywall | **OK** | (non testable sans tenant verrouille, mais code OK) |

### B. IA / Autopilot (Settings > Intelligence Artificielle)

| Feature | Statut | Detail |
|---|---|---|
| Section IA (AISettingsSection) | **OK** | Limites securite visibles (20/h, 3/conv, 2 consecutives) |
| Lien Journal IA | **OK** | Cliquable, redirige vers /ai-journal |
| Section Pilotage IA (AutopilotSection) | **OK** | Mode, escalade, actions autorisees visibles |
| Toggle Pilotage IA ON/OFF | **OK** | Cliquable, sauvegarde immediate |
| Mode "Suggestions" (STARTER+) | **OK** | Selectionnable |
| Mode "Supervise" (PRO+) | **OK** | Selectionnable |
| Mode "Autonome" (AUTOPILOT+) | **KO** | Lock visible + texte "Passez au plan Autopilot" MAIS **pas de lien** |
| Escalade "Votre equipe" | **OK** | Selectionnable |
| Escalade "KeyBuzz" (AUTOPILOT+) | **KO** | Lock + texte mort — **pas de lien upgrade** |
| Escalade "Les deux" (AUTOPILOT+) | **KO** | Lock + texte mort — **pas de lien upgrade** |
| Reponse automatique (AUTOPILOT+) | **KO** | Lock + texte mort — **pas de lien upgrade** |
| Assignation auto (PRO+) | **OK** | Toggle fonctionnel |
| Escalade auto (PRO+) | **OK** | Toggle fonctionnel |
| Mode securise | **OK** | Toggle fonctionnel |
| Learning Control | **OK** | 3 modes (Standard, Adaptatif, Expert) + toggle |

### C. Settings

| Feature | Statut | Detail |
|---|---|---|
| Page /settings | **OK** | 10 onglets visibles |
| Onglet Entreprise | **OK** | Formulaire avec donnees pre-remplies |
| Onglet Horaires | **OK** | (visible) |
| Onglet Conges | **OK** | (visible) |
| Onglet Messages auto | **OK** | (visible) |
| Onglet Notifications | **OK** | (visible) |
| Onglet Intelligence Artificielle | **OK** | Voir section B ci-dessus |
| Onglet Signature | **OK** | Restaure PH142-J, 3 champs + bouton save |
| Onglet Espaces | **OK** | (visible) |
| Onglet Agents | **OK** | Liste agents, creation, toggle actif/inactif |
| Onglet Avance | **OK** | (visible) |
| Deep-link `?tab=xxx` | **KO** | Non implemente — toujours onglet "Entreprise" |

### D. Agents / Gating

| Feature | Statut | Detail |
|---|---|---|
| Liste agents | **OK** | Table avec nom, email, type, role, statut |
| Creation agent (modale) | **OK** | Formulaire prenom/nom/email/type/role |
| Toggle actif/inactif | **OK** | Bouton fonctionnel |
| RBAC (non admin) | **OK** | "Acces reserve aux administrateurs" |
| Add-on "Agent KeyBuzz" | **KO** | N'existe pas dans le code — jamais implemente |

### E. Autres

| Feature | Statut | Detail |
|---|---|---|
| Dashboard | **OK** | Donnees reelles (328 conv, 245 ouvertes, 12 en attente) |
| Inbox | **OK** | (non re-teste, PH142-H confirme OK) |
| Orders | **OK** | (non re-teste, 11922 commandes confirme) |
| Channels | **OK** | (non re-teste) |
| AI Journal | **OK** | (endpoint confirme) |

---

## 3. Top regressions critiques

### R1 — CTA upgrade non cliquables (CRITIQUE)

**Symptome** : Dans Settings > IA, les blocs verouilles (Autonome, KeyBuzz, Les deux, Reponse automatique) affichent "Passez au plan Autopilot" avec une icone fleche, mais c'est un **`<p>` texte, pas un lien ni un bouton**. L'utilisateur ne peut pas cliquer pour upgrader.

**Fichier** : `src/features/ai-ui/AutopilotSection.tsx`

**Code fautif** :
```tsx
{locked && !isStarter && (
  <p className="text-xs text-amber-600 ...">
    <ArrowUpRight className="w-3 h-3" />
    Passez au plan {planLabel(opt.minPlan)}
  </p>
)}
```

**Fix** : Remplacer le `<p>` par un `<Link href="/billing/plan">` ou `<a href="/pricing">`.

**Phase probable** : PH131-B (Autopilot Configuration, fevrier 2026) — CTA jamais transforme en lien.

**Effort** : 15 min

### R2 — Deep-links settings `?tab=xxx` (MAJEUR)

**Symptome** : `/settings?tab=signature` ne fonctionne pas — la page charge toujours sur l'onglet "Entreprise".

**Fichier** : `app/settings/page.tsx`

**Cause** : `useState("profile")` en dur, aucun `useSearchParams()` pour lire le query param.

**Phase probable** : Sprint D16 (decomposition settings) — jamais implemente lors du refactoring.

**Effort** : 10 min (ajouter `useSearchParams` + `useEffect` pour initialiser `activeTab`)

### R3 — Add-on Agent KeyBuzz (MAJEUR)

**Symptome** : Le concept "Agent KeyBuzz" (agent IA dedie facturable en add-on) n'existe nulle part dans le code client.

**Recherche** : `grep -rn 'add.on\|addon\|agent.keybuzz\|Agent KeyBuzz'` dans app/billing, app/settings, src/features/billing = aucun resultat pertinent.

**Cause** : Feature produit jamais implementee — pas une regression.

**Effort** : Sprint dedie (plusieurs jours — conception + implementation + Stripe)

### OK — Boutons Stripe disabled (ATTENDU)

**Symptome** : Sur /billing/plan, les boutons "Changer de plan" et "Gerer via Stripe" sont disabled.

**Cause** : Le tenant `ecomlg-001` est `billing_exempt` (table `tenant_billing_exempt`), donc `source='fallback'` et `isFallback=true`. Les boutons Stripe sont correctement desactives pour un tenant sans subscription Stripe reelle.

**Fix** : Aucun — comportement correct pour un tenant interne.

---

## 4. Focus billing/upsell/settings

### Flux upgrade depuis Settings > IA

L'utilisateur PRO qui voit un bloc verouille avec "Passez au plan Autopilot" ne peut PAS cliquer pour upgrader. Le flux est **casse** :

```
ACTUEL (casse):
  Settings > IA > Bloc Autonome > "Passez au plan Autopilot" = TEXTE MORT

ATTENDU:
  Settings > IA > Bloc Autonome > Clic "Passez au plan Autopilot" → /billing/plan ou /pricing
```

### Flux upgrade depuis /billing

Le flux upgrade depuis /billing fonctionne partiellement :
- "Comparer les offres" → /pricing : **OK**
- "Changer de plan" : disabled pour billing_exempt, fonctionnel pour un vrai subscriber

### Deep-links

Aucun deep-link settings ne fonctionne. Les pages de billing envoient vers `/settings` sans query param.

---

## 5. Phases probables d'introduction

| Regression | Phase probable | Fichier | Certitude |
|---|---|---|---|
| R1 CTA non cliquable | PH131-B Autopilot Config | `AutopilotSection.tsx` | Haute — le composant a ete cree avec `<p>` des l'origine |
| R2 Deep-links settings | Sprint D16 settings | `settings/page.tsx` | Haute — jamais implemente lors du refactoring |
| R3 Add-on Agent KeyBuzz | N/A | N/A | Certaine — n'a jamais existe dans le code |

---

## 6. Pack anti-regression V2

### Checks existants (PH142-I, 10 checks)

1. API health
2. Client health
3. Inbox API
4. Dashboard API
5. AI Settings
6. AI Journal
7. Autopilot draft
8. Signature DB
9. Orders > 0
10. Channels > 0

### Checks proposes V2 (+8 checks feature-level)

| # | Check | Methode |
|---|---|---|
| 11 | Settings 10 onglets presents | Navigateur : compter les boutons d'onglet |
| 12 | Settings Signature tab visible | Navigateur : bouton "Signature" present |
| 13 | IA Pilotage active/desactive toggle | Navigateur : toggle cliquable |
| 14 | CTA upgrade cliquable dans IA blocs | Navigateur : lien/bouton dans blocs verouilles |
| 15 | Billing /current retourne plan | API : GET /billing/current retourne plan != null |
| 16 | Pricing page 4 plans visibles | Navigateur : 4 headings plan |
| 17 | Draft safe mode visible si disponible | API : GET /autopilot/draft retourne 200 |
| 18 | KBActions solde visible | Navigateur : /billing/ai affiche solde |

**Note** : Les checks 11-18 necessitent un navigateur automatise (Playwright/browser-use). Les checks 1-10 sont CLI-only (bastion).

---

## 7. Plan de correction priorise

| Priorite | Correction | Fichier | Effort | Phase proposee |
|---|---|---|---|---|
| **P0** | R1 — CTA upgrade cliquable dans AutopilotSection | `AutopilotSection.tsx` | 15 min | PH142-L |
| **P1** | R2 — Deep-links settings `?tab=xxx` | `settings/page.tsx` | 10 min | PH142-L |
| **P2** | R3 — Add-on Agent KeyBuzz | Nouveau composant + API + Stripe | Jours | Sprint dedie |

### Detail P0 — Fix CTA upgrade

```tsx
// AVANT (texte mort)
<p className="text-xs text-amber-600 ...">
  <ArrowUpRight className="w-3 h-3" /> Passez au plan {planLabel(opt.minPlan)}
</p>

// APRES (lien cliquable)
<Link href="/billing/plan" className="text-xs text-amber-600 hover:underline ...">
  <ArrowUpRight className="w-3 h-3" /> Passez au plan {planLabel(opt.minPlan)}
</Link>
```

5 occurrences a corriger dans `AutopilotSection.tsx` :
1. Mode Autonome
2. Escalade KeyBuzz
3. Escalade Les deux
4. Reponse automatique
5. (Starter encart — deja un `<a href="/billing/plan">`, OK)

### Detail P1 — Fix deep-links settings

```tsx
// AJOUTER dans settings/page.tsx
import { useSearchParams } from 'next/navigation';

// Dans le composant
const searchParams = useSearchParams();
const tabParam = searchParams.get('tab');

useEffect(() => {
  if (tabParam && VALID_TABS.includes(tabParam)) {
    setActiveTab(tabParam);
  }
}, [tabParam]);
```
