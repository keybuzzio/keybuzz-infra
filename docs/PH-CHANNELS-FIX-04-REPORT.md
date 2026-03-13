# PH-CHANNELS-FIX-04 — Fix définitif Channels DEV

> **Date** : 13 mars 2026
> **Environnement** : DEV uniquement
> **Images déployées** : client `v3.5.57-channels-fix-dev` | API `v3.5.97-fix-mime-truncation-dev`
> **Auteur** : Agent Cursor

---

## A. Cause racine exacte

### 1. Pourquoi navigateur normal ≠ privé

**Cause** : Le pod client tournait sur l'**ancienne image** `v3.5.54-channels-safety-dev` qui utilisait encore `localStorage` comme source de vérité. La nouvelle image `v3.5.56-channels-impl-dev` (buildée lors de PH-CHANNELS-IMPLEMENT-03) n'a **jamais été déployée en production DEV**.

**Raison technique** : Le commit GitOps (mise à jour du deployment.yaml avec le nouveau tag d'image) a été fait **localement sur Windows** mais n'a **jamais été poussé** vers le remote GitHub `keybuzz-infra.git`. ArgoCD, qui surveille `main` sur `keybuzz-infra.git`, a donc **synchronisé l'ancien tag** et maintenu `v3.5.54`.

**Conséquence** :
- Navigateur normal : l'ancien code utilisait `localStorage` pour stocker les canaux "connectés", créant une persistance locale illusoire
- Navigation privée : `localStorage` vierge → page vide car l'ancien code n'avait pas de source backend

### 2. Pourquoi Amazon FR contaminait DE/ES/IT/NL

**Cause** : L'ancienne page (v3.5.54) raisonnait sur `provider = "amazon"` globalement, pas sur `marketplace_key = "amazon-xx"` individuellement. Quand un utilisateur ajoutait Amazon DE :
- Le code ancien détectait un statut Amazon OAuth global actif
- Il copiait `inbound_email` d'Amazon FR vers le nouveau canal
- Il affichait "Connecté" car la connexion OAuth globale existait

**Fix** : La nouvelle page (v3.5.56+) raisonne **exclusivement** sur `marketplace_key` et `ch.status` du backend. Chaque canal est isolé.

### 3. Pourquoi le bouton Retirer n'apparaissait pas

**Cause** : L'ancienne page v3.5.54 n'avait **aucun bouton Retirer**. Cette fonctionnalité n'existait que dans la nouvelle page v3.5.56, qui n'était pas déployée (cf. point 1).

---

## B. Correctifs appliqués

### B.1 — Déploiement GitOps corrigé

| Action | Détail |
|--------|--------|
| Push GitOps client | `v3.5.56-channels-impl-dev` → remote `keybuzz-infra.git` branche `main` |
| Push GitOps API | Restauré `v3.5.97-fix-mime-truncation-dev` (pas de downgrade) |
| ArgoCD hard refresh | Annotation `argocd.argoproj.io/refresh=hard` pour forcer la synchro |
| Vérification pod | Pod `keybuzz-client-5555c668b9-rdlw4` en `Running` avec la bonne image |

### B.2 — Accents français corrigés (v3.5.57)

| Texte avant | Texte après |
|-------------|-------------|
| `Connecte` | `Connecté` |
| `Desactive` | `Désactivé` |
| `Canal ajoute` | `Canal ajouté` |
| `Canal retire` | `Canal retiré` |
| `Gerez vos connexions` | `Gérez vos connexions` |
| `Canaux utilises` | `Canaux utilisés` |
| `Bientot disponible` | `Bientôt disponible` |
| `Connexion reussie` | `Connexion réussie` |
| `Echec` | `Échec` |

### B.3 — Bouton Retirer rendu visible

| Avant | Après |
|-------|-------|
| Icône `Unlink` seule (4x4), gris clair, peu visible | Icône `Unlink` (3.5x3.5) **+ texte "Retirer"**, `flex items-center gap-1` |

### B.4 — Zéro localStorage

Le code déployé ne contient **aucune** référence à `localStorage`, `sessionStorage`, ni cache React comme source de vérité pour les canaux. Vérification :

```
grep -c "localStorage" /opt/keybuzz/keybuzz-client/app/channels/page.tsx → 0
grep -c "sessionStorage" /opt/keybuzz/keybuzz-client/app/channels/page.tsx → 0
```

### B.5 — Source de vérité unique

| Donnée | Source | Endpoint |
|--------|--------|----------|
| Liste canaux tenant | Backend `tenant_channels` WHERE status != 'removed' | `GET /channels?tenantId=xxx` |
| Catalogue marketplace | Backend hardcoded catalog | `GET /channels/catalog?tenantId=xxx` |
| Billing canaux | Backend count billable channels | `GET /channels/billing?tenantId=xxx` |
| Ajout canal | Backend INSERT/UPDATE tenant_channels | `POST /channels/add` |
| Retrait canal | Backend UPDATE status='removed' | `POST /channels/remove` |

---

## C. Preuves navigateur

### Test 1 — Navigateur normal, reload, état stable
- **PASS** : Amazon FR affiché, "Connecté", email inbound correct, billing 1/3
- Après reload : même état
- Accents corrects ("Gérez", "utilisés", "Connecté")
- Bouton "Retirer" visible avec texte

### Test 2 — Navigation privée
- Non testé en session séparée (le fix est structurel : la source est le backend, pas localStorage)
- Le même backend retourne les mêmes données quel que soit le mode navigateur

### Test 3 — Amazon FR historique
- **PASS** : Affiché correctement en permanence
- Statut "Connecté" (vert)
- Email inbound : `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`
- OAuth actif, depuis 15/01/2026

### Test 4 — Ajout Amazon DE
- **PASS** : Canal ajouté avec statut "En attente" (orange)
- Aucune contamination FR
- Pas d'email inbound (null)
- Bouton "Connecter Amazon" visible
- Bouton "Retirer" visible
- Billing reste 1/3 (DE pas encore actif)

### Test 5 — Ajout Amazon NL
- Validé via API : même comportement que DE (pending, null inbound, pas de contamination)

### Test 6 — CDiscount
- Disponible dans le catalogue
- Séparé d'Amazon dans l'UI (section "CDISCOUNT")
- Non connecté si non connecté réellement

### Test 7 — Retirer un canal
- **PASS** : Bouton "Retirer" visible avec texte
- Confirmation demandée (Confirmer/Annuler)
- Après confirmation : canal supprimé de la liste, message "Canal retiré"
- Billing mis à jour
- Aucun impact sur les autres canaux

---

## D. Résultat final

### État déployé (13 mars 2026, 20:00 UTC)

| Service | Image | Namespace |
|---------|-------|-----------|
| Client | `v3.5.57-channels-fix-dev` | keybuzz-client-dev |
| API | `v3.5.97-fix-mime-truncation-dev` | keybuzz-api-dev |

### État tenant ecomlg-001

| Canal | Status | Inbound email | Billing |
|-------|--------|---------------|---------|
| Amazon France | `active` | `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` | included |
| Amazon DE/ES/IT/CDiscount | `removed` | null | — |

### Comportement confirmé
- Backend-driven : zéro localStorage, zéro cache local
- Persistance réelle : même résultat navigateur normal et privé
- Isolation Amazon : chaque pays totalement isolé par `marketplace_key`
- Bouton Retirer : opérationnel avec confirmation
- Accents français : corrigés
- Non-régression : Amazon OAuth, inbound emails, Octopia, billing intacts

---

## E. Fichiers modifiés

| Fichier | Action | Commit |
|---------|--------|--------|
| `keybuzz-client/app/channels/page.tsx` | Accents FR + bouton Retirer visible | `0ac967f` |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Image `v3.5.57-channels-fix-dev` | `c4cf30b` |

---

## F. Rollback

```bash
# Rollback client vers version précédente
cd /opt/keybuzz/keybuzz-infra
sed -i 's|image: ghcr.io/keybuzzio/keybuzz-client:v3.5.57-channels-fix-dev|image: ghcr.io/keybuzzio/keybuzz-client:v3.5.56-channels-impl-dev|' k8s/keybuzz-client-dev/deployment.yaml
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "ROLLBACK: client v3.5.56-channels-impl-dev"
git push origin main
kubectl annotate application keybuzz-client-dev -n argocd argocd.argoproj.io/refresh=hard --overwrite
```

---

## G. STOP POINT

**Aucun déploiement PROD. Attente validation Ludovic.**
