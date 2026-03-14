# PH-ADMIN-87.0A — Global Search & Command Palette — Rapport

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.16.0-ph87.0a-global-search`
**Statut** : DEV + PROD deploye

---

## 1. Tables interrogees

| Table | Champs recherches | Type resultat |
|---|---|---|
| `tenants` | id, name, domain | tenant |
| `admin_users` | email, id | user |
| `ai_human_approval_queue` | id, tenant_id, queue_type, queue_status | case |
| `tenant_channels` | provider, tenant_id + JOIN tenants.name | connector |
| `billing_events` | event_type, tenant_id + JOIN tenants.name | billing_event |

---

## 2. API Search

**Route** : `GET /api/admin/search?q=<query>`

**RBAC** : `super_admin`, `ops_admin`, `account_manager`

**Comportement** :
- Minimum 2 caracteres requis
- Maximum 20 resultats (4 par source max, priorise par pertinence)
- Recherche ILIKE sur toutes les sources en parallele
- `safeQuery()` pour resilience si table manquante

**Reponse** :
```json
{
  "data": [
    {
      "type": "tenant",
      "id": "ecomlg-001",
      "label": "EcomLG",
      "description": "PRO · active",
      "url": "/tenants/ecomlg-001"
    }
  ]
}
```

---

## 3. Command Palette UI

### Activation
- **Clavier** : `Ctrl+K` (Windows/Linux) ou `Cmd+K` (Mac)
- **Bouton** : SearchTrigger dans la Topbar avec icone + raccourci affiche
- **Evenement** : `open-command-palette` (custom DOM event)

### Fonctionnalites
- Modal centree avec backdrop blur
- Champ recherche avec debounce 250ms
- Navigation clavier : fleches haut/bas, Enter pour ouvrir, Escape pour fermer
- Navigation souris : hover pour selectionner, clic pour ouvrir
- Highlight de l'element actif
- Icones et couleurs par type de resultat :
  - Tenant : bleu, Building2
  - User : violet, User
  - Case : ambre, FileText
  - Connector : emeraude, Plug
  - Billing : rose, Receipt
- Badge type a droite de chaque resultat
- Footer avec raccourcis clavier
- Compteur de resultats

### Etats UI
- **Loading** : spinner pendant la recherche
- **Minimum 2 caracteres** : message indicatif
- **Aucun resultat** : message avec la requete citee
- **Resultats** : liste navigable

---

## 4. Integration

### Fichiers crees
| Fichier | Role |
|---|---|
| `src/features/search/search.service.ts` | Service recherche multi-sources (5 methodes SQL) |
| `src/app/api/admin/search/route.ts` | Route API GET avec RBAC |
| `src/components/layout/CommandPalette.tsx` | Composant palette + SearchTrigger |

### Fichiers modifies
| Fichier | Modification |
|---|---|
| `src/components/layout/Topbar.tsx` | Ajout SearchTrigger dans la topbar |
| `src/app/(admin)/layout.tsx` | Ajout CommandPalette (toujours monte) |

---

## 5. RBAC

| Role | Acces |
|---|---|
| `super_admin` | Recherche complete |
| `ops_admin` | Recherche complete |
| `account_manager` | Recherche complete |
| Autres roles | Bloque (403) |

---

## 6. Performance

- Debounce 250ms sur la saisie
- 5 requetes SQL en parallele (Promise.all)
- Limite 4 resultats par source, 20 total
- ILIKE simple (pas de full-text search)
- Pas d'index supplementaire necessaire

---

## 7. Non-regression

| Verification | Resultat |
|---|---|
| `client-dev.keybuzz.io` | 307 OK |
| `client.keybuzz.io` | 307 OK |
| Aucune modification backend API | Confirme |
| Pages existantes non impactees | Confirme |

---

## 8. Deploiement

| Env | Image | Statut |
|---|---|---|
| DEV | `v0.16.0-ph87.0a-global-search` | 1/1 Running |
| PROD | `v0.16.0-ph87.0a-global-search` | 1/1 Running |

---

## 9. Limitations

- Pas de recherche full-text (ILIKE suffisant pour le volume actuel)
- Pas de filtrage par type dans la palette (a ajouter si necessaire)
- Pas d'historique de recherches recentes
- Pas de suggestions pre-remplies (quick actions)
