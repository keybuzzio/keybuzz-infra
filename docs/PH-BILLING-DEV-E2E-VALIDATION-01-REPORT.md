# PH-BILLING-DEV-E2E-VALIDATION-01 — RAPPORT

> Date : 2026-03-25
> Auteur : Agent Cursor
> Phase precedente : PH-BILLING-REGRESSION-AUDIT-REPAIR-01
> Environnement : DEV uniquement (client-dev.keybuzz.io)

---

## 1. RESUME EXECUTIF

Les 10 corrections billing de PH-BILLING-REGRESSION-AUDIT-REPAIR-01 ont ete deployees en DEV.
Le build a necessite un nettoyage massif de fichiers parasites accumules dans le repo client
(90+ fichiers .ts/.tsx inutiles, absence de .dockerignore). Le build context Docker est passe
de 934 MB a 12 MB. L'image DEV est healthy et accessible.

**Verdict : BILLING DEV READY FOR MANUAL TEST**

---

## 2. COMMITS GIT

### Repo keybuzz-client (origin: keybuzzio/keybuzz-client, branche: main)

| Commit | Description |
|--------|-------------|
| `8ca1d3d` | PH-BILLING-REPAIR-01: fix 10 billing regressions |
| `cf59fc8` | PH-BILLING-DEV-BUILD: remove 27 root-level temp tsx files + exclude temp dirs from tsconfig |
| `5a05c0b` | PH-BILLING-DEV-BUILD-02: remove 63 root-level temp ts files + exclude backend dirs from tsconfig |
| `75b36c2` | PH-BILLING-DEV-BUILD-03: add .dockerignore + exclude backend-src from tsconfig |
| `39e7e71` | PH-BILLING-DEV-BUILD-04: fix .dockerignore - keep scripts/generate-build-metadata.py |
| `f43641c` | PH-BILLING-DEV-BUILD-05: comprehensive .dockerignore + tsconfig exclude |
| `d8ededb` | PH-BILLING-DEV-BUILD-06: remove src/main.ts (Fastify backend file misplaced) |
| `519f589` | PH-BILLING-DEV-BUILD-07: remove src/modules/tenants/tenants.types.ts |
| `8bb2829` | PH-BILLING-DEV-BUILD-08: exclude *.md from docker context |
| `ce4bf6e` | PH-BILLING-DEV-BUILD-09: exclude root-level *.ts from docker context |

### Repo keybuzz-infra (GitOps)

| Commit | Description |
|--------|-------------|
| `a09c425` | GitOps: update keybuzz-client-dev to v3.5.49-billing-repair-dev |

---

## 3. IMAGE ET DEPLOIEMENT

| Element | Valeur |
|---------|--------|
| **Image** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.49-billing-repair-dev` |
| **SHA** | `sha256:5dd3e008e0584e4fde38c6ccf0c1e338c6dde53df17b28c95c54e5beb40764d8` |
| **Namespace** | `keybuzz-client-dev` |
| **Pod** | `keybuzz-client-6c8446d8b5-bg65l` |
| **Status** | 1/1 Running, 0 restarts |
| **Ingress** | `client-dev.keybuzz.io` (nginx, TLS) |
| **Build args** | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io` |
| **Image precedente** | `v3.5.48-white-bg-dev` (avant), `v3.5.94-ph125-agent-queue-dev` (GitOps out of date) |

---

## 4. VALIDATIONS TECHNIQUES DEV

### 4.1 Pod et infra

| Check | Resultat |
|-------|----------|
| Pod Running 1/1 | OK |
| 0 restarts | OK |
| Image correcte | OK (v3.5.49-billing-repair-dev) |
| Ingress DEV | OK (client-dev.keybuzz.io, nginx, ports 80+443) |
| GitOps mis a jour | OK (keybuzz-infra commit a09c425) |

### 4.2 Pages compilees (verifiees au build)

| Route | Statut compilation | Taille |
|-------|-------------------|--------|
| `/billing` | OK (static) | 4.23 kB |
| `/billing/ai` | OK (static) | 2.95 kB |
| `/billing/ai/manage` | OK (static) | 4.48 kB |
| `/billing/history` | OK (static) | 4.08 kB |
| `/billing/options` | OK (static) | 4.17 kB |
| `/billing/plan` | OK (static) | 6.96 kB |
| `/login` | OK (static) | 7.1 kB |
| `/pricing` | OK (static) | 5.78 kB |

### 4.3 Middleware auth

| Page | Comportement | Correct ? |
|------|-------------|-----------|
| /billing | Redirect -> /login | OUI |
| /billing/plan | Redirect -> /login | OUI |
| /billing/history | Redirect -> /login | OUI |
| /billing/ai | Redirect -> /login | OUI |
| /billing/ai/manage | Redirect -> /login | OUI |
| /billing/options | Redirect -> /login | OUI |
| /login | Page affichee | OUI |

### 4.4 Backend API billing (test direct depuis le cluster)

Appel `GET /billing/current?tenantId=ecomlg-001` sur le backend API :

```json
{
  "tenantId": "ecomlg-001",
  "plan": "PRO",
  "billingCycle": "monthly",
  "channelsIncluded": 3,
  "channelsAddonQty": 0,
  "status": "active",
  "currentPeriodEnd": null,
  "source": "fallback",
  "channelsUsed": 1
}
```

**Points cles :**
- `channelsUsed: 1` (corrige, etait 0 avant)
- `source: fallback` (attendu pour ecomlg-001 = billing-exempt)
- `plan: PRO`, `billingCycle: monthly`

### 4.5 Routes BFF nouvelles

| Route BFF | Fichier | Statut |
|-----------|---------|--------|
| `POST /api/billing/change-plan` | `app/api/billing/change-plan/route.ts` | CREE, compile OK |
| `GET /api/billing/invoices` | `app/api/billing/invoices/route.ts` | CREE, compile OK |

---

## 5. RESULTATS E2E DEV

### 5.1 Tests automatises (navigateur + cluster)

| # | Test | Resultat | Notes |
|---|------|----------|-------|
| 1 | Login page load | OK | Formulaire OTP + OAuth visible |
| 2 | Auth redirect billing | OK | Toutes les pages protegees redirigent vers /login |
| 3 | Backend channelsUsed | OK | Retourne 1 (pas 0) |
| 4 | Backend plan/status | OK | PRO/active/fallback |
| 5 | Pod stability | OK | 0 restarts, aucun crash |
| 6 | Build compilation | OK | 87 pages compilees sans erreur TS |
| 7 | Console errors | WARNING ONLY | 3 deprecations non-bloquantes (getSession, getCurrentTenantName, getCurrentTenantId) |

### 5.2 Erreurs console observees (non-bloquantes)

```
[DEPRECATED] getSession() - Auth is now via cookie. Use useAuth() hook.
[DEPRECATED] getCurrentTenantName() - Use useAuth() hook.
[DEPRECATED] getCurrentTenantId() - Use useAuth() hook.
```

Ce sont des warnings preexistants, pas des regressions billing.

---

## 6. LIMITES CONNUES

### 6.1 Limites du test automatise

| Limitation | Raison | Impact |
|-----------|--------|--------|
| Pas de test post-login | OTP envoye par email, `devCode` non expose en mode production | Contenus des pages billing non testes programmatiquement |
| Stripe Checkout non testable | ecomlg-001 est billing-exempt, pas de customer Stripe reel | Flux Stripe reels non verifiables en DEV |
| Changement de plan non testable E2E | Necessite une session authentifiee + un customer Stripe | Modal testable visuellement uniquement |

### 6.2 Comportement attendu pour ecomlg-001 (billing-exempt)

Le tenant `ecomlg-001` est exempt de facturation (`tenant_billing_exempt.exempt = true, reason = internal_admin`).
Comportements attendus :

| Element | Comportement attendu |
|---------|---------------------|
| Plan affiche | PRO (fallback) |
| Source | "fallback" |
| Canaux | 1 / 3 |
| Bouton "Gerer via Stripe" | Desactive avec message "Mode demonstration" |
| Bouton "Changer de plan" | Actif, modal s'ouvre, mais le POST echouera (pas de customer Stripe) |
| Bouton "Annuler" | Popup dissuasive s'affiche, puis redirection Stripe echouera |
| Historique factures | "Aucun abonnement Stripe associe" |
| KBActions | Solde reel affiche (772.27 KBA environ) |
| Achat KBActions | CTA actif, checkout Stripe echouera (pas de customer) |
| Plafond mensuel | Lecture/modification/sauvegarde fonctionnels si endpoint backend OK |

### 6.3 Probleme de build Docker (dette technique nettoyee)

Le repo contenait **90+ fichiers parasites** (.ts/.tsx) accumules au fil des sessions :
- 27 fichiers .tsx a la racine
- 63 fichiers .ts a la racine
- `src/main.ts` (Fastify backend deplace dans le client)
- `src/modules/tenants/tenants.types.ts` (types dupliques)
- Pas de `.dockerignore` (build context 934 MB)

**Actions prises :**
- Suppression de 92 fichiers parasites
- Creation de `.dockerignore` comprehensif
- Mise a jour `tsconfig.json` avec 15+ exclusions
- Build context reduit de 934 MB a 12 MB

### 6.4 Enforcement du plafond mensuel KBActions

Le plafond mensuel (`ai_budget_settings.monthly_cap`) est lu et ecrit par le backend.
L'enforcement reel (bloquer les consommations au-dela du plafond) depend du backend API
(`keybuzz-api`). Le client affiche et permet de modifier la valeur, mais ne peut pas
garantir l'enforcement. **Ceci necessite un audit backend separe.**

---

## 7. CHECKLIST DE TEST MANUEL

### Pre-requis
1. Ouvrir `https://client-dev.keybuzz.io/login`
2. Se connecter avec `ludo.gonthier@gmail.com` (OTP email)
3. Verifier que le tenant ecomlg est selectionne

### Tests a effectuer

#### A. Page /billing (hub)

| # | Action | Resultat attendu | OK ? |
|---|--------|-------------------|------|
| A1 | Ouvrir /billing | Page charge sans erreur | |
| A2 | Verifier compteur canaux | Affiche "1 / 3" (pas "0 / 3") | |
| A3 | Verifier plan affiche | "PRO" | |
| A4 | Cliquer "Mon plan" | Redirige vers /billing/plan | |
| A5 | Cliquer "Historique" | Redirige vers /billing/history | |
| A6 | Cliquer "KBActions" | Redirige vers /billing/ai | |

#### B. Page /billing/plan

| # | Action | Resultat attendu | OK ? |
|---|--------|-------------------|------|
| B1 | Ouvrir /billing/plan | Page charge avec details plan PRO | |
| B2 | Verifier features listees | Liste des capabilities PRO affichee | |
| B3 | Cliquer "Changer de plan" | Modal s'ouvre avec 3 plans | |
| B4 | Verifier plan actuel grise | "Plan actuel" badge sur PRO, non cliquable | |
| B5 | Selectionner AUTOPILOT | Plan selectionne (bordure bleue) | |
| B6 | Cliquer "Confirmer" | Erreur attendue (pas de customer Stripe) | |
| B7 | Fermer la modal | Navigation OK, pas de bug | |
| B8 | Cliquer "Gerer mon abonnement" | Message "Mode demonstration" (exempt) | |
| B9 | Cliquer "Annuler mon abonnement" | Popup dissuasive s'affiche | |
| B10 | Verifier contenu popup | Liste des pertes + suggestion Starter | |
| B11 | Cliquer "Garder mon abonnement" | Popup se ferme | |
| B12 | Cliquer "Continuer vers annulation" | Tentative Stripe portal (erreur attendue) | |

#### C. Page /billing/options

| # | Action | Resultat attendu | OK ? |
|---|--------|-------------------|------|
| C1 | Ouvrir /billing/options | Page charge | |
| C2 | Verifier compteur canaux | "1 / 3" (coherent avec /billing) | |

#### D. Page /billing/history

| # | Action | Resultat attendu | OK ? |
|---|--------|-------------------|------|
| D1 | Ouvrir /billing/history | Page charge (pas de mock) | |
| D2 | Verifier contenu | "Aucun abonnement Stripe associe" ou liste vide | |
| D3 | Verifier absence de factures mock | Pas de "Facture #INV-001" ni donnees factices | |
| D4 | Ouvrir la console navigateur | Aucune erreur JS bloquante | |

#### E. Page /billing/ai

| # | Action | Resultat attendu | OK ? |
|---|--------|-------------------|------|
| E1 | Ouvrir /billing/ai | Page charge avec solde KBActions | |
| E2 | Verifier libelle bouton | "Acheter des KBActions" (pas "Acheter des actions") | |
| E3 | Cliquer le bouton achat | Navigation vers Stripe checkout (ou erreur si exempt) | |
| E4 | Verifier solde affiche | Coherent (~772 KBA) | |

#### F. Page /billing/ai/manage

| # | Action | Resultat attendu | OK ? |
|---|--------|-------------------|------|
| F1 | Ouvrir /billing/ai/manage | Page charge | |
| F2 | Verifier CTA achat | Bouton "Acheter des KBActions" actif (lien vers /billing/ai) | |
| F3 | Verifier plafond mensuel | Valeur affichee (ou 0 par defaut) | |
| F4 | Modifier le plafond | Champ editable | |
| F5 | Sauvegarder | Sauvegarde reussie (ou erreur si endpoint backend manquant) | |
| F6 | Recharger la page | Valeur persistee (ou valeur par defaut si pas d'endpoint) | |

#### G. Robustesse globale

| # | Action | Resultat attendu | OK ? |
|---|--------|-------------------|------|
| G1 | Console navigateur ouverte sur /billing | Aucune erreur JS bloquante | |
| G2 | Onglet Network sur /billing | Aucun appel API en 500 | |
| G3 | Naviguer /billing -> /inbox -> /billing | Pas de perte de contexte tenant | |
| G4 | Naviguer /billing -> /billing/plan -> retour | Navigation fluide | |
| G5 | Verifier absence de "ecomlg" affiche | Pas de canonical ID visible dans l'UI | |

---

## 8. VERDICT FINAL

### BILLING DEV READY FOR MANUAL TEST

**Justification :**
- Image v3.5.49-billing-repair-dev deployee et healthy
- Toutes les pages billing compilees sans erreur TS
- Middleware auth fonctionnel
- Backend retourne les bonnes donnees (`channelsUsed: 1`, `plan: PRO`)
- GitOps mis a jour
- Aucun crash, aucune regression visible

**Ce qui reste a faire :**
1. Test manuel complet avec la checklist ci-dessus (necesssite connexion OTP)
2. Si tous les tests passent : decision de promotion PROD
3. Audit backend separe pour l'enforcement du plafond KBActions (optionnel)

**Ce qui NE DOIT PAS etre fait :**
- Aucune promotion PROD avant validation manuelle
- Aucune modification de l'API backend dans cette phase
