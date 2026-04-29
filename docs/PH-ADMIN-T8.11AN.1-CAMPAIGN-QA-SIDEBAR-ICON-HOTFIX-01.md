# PH-ADMIN-T8.11AN.1 — Campaign QA Sidebar Icon Hotfix

> Date : 2026-04-29
> Auteur : Agent Cursor
> Phase precedente : PH-ADMIN-T8.11AN (Campaign QA / URL Builder)
> Ticket : KEY-221

---

## 1. RESUME EXECUTIF

PH-ADMIN-T8.11AN a livre la page `/marketing/campaign-qa` en DEV et PROD.
La page etait fonctionnelle mais l'entree sidebar affichait le label "Campaign QA" **sans icone** a gauche.

**Verdict : CAMPAIGN QA SIDEBAR ICON FIXED — VISUAL NAVIGATION VALIDATED DEV AND PROD — NO FUNCTIONAL DRIFT — NO TRACKING DRIFT**

---

## 2. PREFLIGHT

| Check | Resultat |
|---|---|
| Admin `main` | clean, HEAD `fd77350` |
| Infra `main` | clean, HEAD `c83c6e1` |
| DEV image | `v2.11.32-campaign-qa-url-builder-dev` |
| PROD image | `v2.11.32-campaign-qa-url-builder-prod` |
| API PROD | `v3.5.123-linkedin-capi-native-prod` (inchange) |
| Client PROD | `v3.5.125-register-console-cleanup-prod` (inchange) |
| Website PROD | `v0.6.7-pricing-attribution-forwarding-prod` (inchange) |

---

## 3. CAUSE RACINE

`navigation.ts` declarait `icon: 'Link2'` pour l'entree Campaign QA, mais :
- `Link2` n'etait **pas importe** de `lucide-react` dans `Sidebar.tsx`
- `Link2` n'etait **pas present** dans `iconMap` de `Sidebar.tsx`

Le composant `Sidebar.tsx` utilise un `iconMap: Record<string, LucideIcon>` pour resoudre les noms d'icones declares dans la navigation. Si la cle n'existe pas dans le map, `Icon` est `undefined` et le `{Icon && ...}` ne rend rien.

---

## 4. FICHIER MODIFIE

**`src/components/layout/Sidebar.tsx`** — 2 lignes modifiees :

1. **Ligne 9** : ajout de `Link2` dans l'import `lucide-react`
2. **Ligne 19** : ajout de `Link2` dans `iconMap`

Aucun autre fichier modifie. Route, label, position dans le menu : inchanges.

---

## 5. COMMITS GIT

### Repo keybuzz-admin-v2

| Commit | Message |
|---|---|
| `785a93f` | `fix(sidebar): add Link2 icon to iconMap for Campaign QA entry (KEY-221)` |

### Repo keybuzz-infra

| Commit | Message | Manifest |
|---|---|---|
| `f30deec` | `PH-ADMIN-T8.11AN.1: GitOps Admin DEV v2.11.33-campaign-qa-icon-hotfix-dev (KEY-221)` | `k8s/keybuzz-admin-v2-dev/deployment.yaml` |
| `8413423` | `PH-ADMIN-T8.11AN.1: GitOps Admin PROD v2.11.33-campaign-qa-icon-hotfix-prod (KEY-221)` | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |

---

## 6. IMAGES DOCKER

| Env | Tag | Digest |
|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.33-campaign-qa-icon-hotfix-dev` | `sha256:617f5d07a9fa4ebcb389c6da2265d3ee86ee457331569cfb73f37c05925210f0` |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.33-campaign-qa-icon-hotfix-prod` | `sha256:870d033e97c212930eeccd647ea2db3cae0b5151e5521e0e8a414ab4b7c57cfe` |

Source commune : commit `785a93f` (clone temporaire propre, `docker build --no-cache`).

---

## 7. VALIDATION NAVIGATEUR DEV

URL : `https://admin-dev.keybuzz.io/marketing/campaign-qa`

| Check | Resultat |
|---|---|
| Icone visible a gauche de "Campaign QA" | OK — icone Link2 (chaine/lien) |
| Alignement avec les autres entrees Marketing | OK — identique a Delivery Logs, Acquisition Playbook, Integration Guide |
| Etat actif correct | OK — fond bleu clair, texte bleu |
| Pas d'overlap texte | OK |
| Page Campaign QA fonctionnelle | OK — formulaire complet, URLs generees |
| Boutons Copier URL / Copier /register | OK — presents |
| Aucun codex visible | OK |
| Aucun AW-18098643667 | OK |
| Erreurs console bloquantes | Aucune (debug NextAuth pre-existant uniquement) |

---

## 8. VALIDATION NAVIGATEUR PROD

URL : `https://admin.keybuzz.io/marketing/campaign-qa`

| Check | Resultat |
|---|---|
| Icone visible a gauche de "Campaign QA" | OK — icone Link2 identique a DEV |
| Alignement sidebar | OK |
| Etat actif | OK |
| Page fonctionnelle | OK — formulaire complet, URLs generees |
| Aucun codex | OK |
| Aucun AW direct | OK |
| Aucun secret expose | OK |

---

## 9. NON-REGRESSION

| Service | Image PROD | Statut |
|---|---|---|
| API | `v3.5.123-linkedin-capi-native-prod` | Inchange |
| Client | `v3.5.125-register-console-cleanup-prod` | Inchange |
| Website | `v0.6.7-pricing-attribution-forwarding-prod` | Inchange |
| Admin | `v2.11.33-campaign-qa-icon-hotfix-prod` | 1/1 Running, 0 restart |

### Pages Admin PROD (in-pod wget)

| Page | Status |
|---|---|
| `/metrics` | 200 |
| `/marketing/paid-channels` | 200 |
| `/marketing/google-tracking` | 200 |
| `/marketing/acquisition-playbook` | 200 |
| `/marketing/campaign-qa` | 200 |

---

## 10. ROLLBACK GITOPS

En cas de regression :

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` :
   - Remplacer `v2.11.33-campaign-qa-icon-hotfix-prod` par `v2.11.32-campaign-qa-url-builder-prod`
2. Commit + push `keybuzz-infra`
3. `kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod`

**Interdit** : `kubectl set image`, `kubectl edit`, `kubectl patch`.

---

## 11. LINEAR

Ticket : KEY-221
Commentaire a ajouter manuellement (token Linear non disponible dans les pods K8s) :

> PH-ADMIN-T8.11AN.1 — Hotfix icone sidebar Campaign QA
> - Cause : Link2 absent de iconMap dans Sidebar.tsx
> - Fix : ajout Link2 a l'import et au map (commit 785a93f)
> - Validation navigateur DEV/PROD OK
> - Aucune regression

---

## 12. CONFIRMATIONS

- Aucun secret expose dans les commits, builds ou navigateur
- Aucun tag AW direct ou destination Google ajoute
- Aucun faux event ou faux spend cree
- Aucune modification de la logique Campaign QA (uniquement icone sidebar)
- API, Client et Website PROD strictement inchanges
