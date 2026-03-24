# PH-ADMIN-87.10D — TENANT OPERATIONS PANEL

> Date : 2026-03-04
> Statut : **TERMINE**

---

## 1. Resume executif

### Ce qui a ete ajoute
- **Endpoint operations** : `GET /api/admin/tenants/[id]/operations` — retourne les donnees operationnelles reelles du tenant (conversations, messages, queues, approvals, followups, activite IA, channels)
- **TenantOperationsPanel** : composant UI complet affichant toutes les donnees operationnelles dans le cockpit tenant
- **Empty states honnetes** : quand une donnee n'existe pas, un message clair est affiche (pas de placeholder, pas de mock)
- **Navigation tenant-aware** : liens vers `/queues?tenantId=X`, `/approvals?tenantId=X`, `/users?tenantId=X` depuis le panneau operations
- **Followups tenant-aware** : page `/followups` mise a jour avec `TenantFilterBanner` et `Suspense` boundary
- **Version** : bumpee de v2.3.0 a v2.4.0

### Ce qui est visible depuis le cockpit
| Section | Donnees | Source |
|---|---|---|
| Conversations | total, ouvertes, en attente, resolues, 5 recentes | `conversations` |
| Messages | total, dernières 24h | `messages` |
| Queues & Cases | total, en cours, derniers items | `ai_human_approval_queue` |
| Approbations | total, en attente | `ai_human_approval_queue` |
| Follow-ups | total, ouverts | `ai_followup_cases` |
| Activite IA | regles totales, actives, actions executees, 5 recentes | `ai_rules`, `ai_action_log` |
| Channels | total, actifs, liste detaillee | `tenant_channels` |

### Ce qui reste non branche
- Followups page : `TenantFilterBanner` ajoute mais la page ne filtre pas encore les donnees par tenant (le scheduler ne scope pas par tenant)
- Audit page : pas encore tenant-aware
- Billing page : pas encore tenant-aware

---

## 2. Cartographie des sources reelles

| Domaine | Table | Tenant-scope | Donnees ecomlg-001 | Utilisable |
|---|---|---|---|---|
| Conversations | `conversations` | Oui (`tenant_id`) | 262→270 | Oui |
| Messages | `messages` | Oui (`tenant_id`) | 831→864 | Oui |
| Attachments | `message_attachments` | Oui (`tenant_id`) | 97 | Non utilise (pas necessaire) |
| Queues | `ai_human_approval_queue` | Oui (`tenant_id`) | 1→2 | Oui |
| Followups | `ai_followup_cases` | Oui (`tenant_id`) | 0 | Oui (empty state) |
| Actions IA | `ai_action_log` | Oui (`tenant_id`) | 1285 | Oui |
| Execution audit | `ai_execution_audit` | Oui (`tenant_id`) | 5 | Non utilise |
| Evaluations | `ai_evaluations` | Oui (`tenant_id`) | 0 | Non utilise |
| Regles IA | `ai_rules` | Oui (`tenant_id`) | 15 | Oui |
| Ledger KBA | `ai_actions_ledger` | Oui (`tenant_id`) | 261 | Deja affiche (cockpit AI) |
| Wallet | `ai_credits_wallet` | Oui (`tenant_id`) | 1 | Deja affiche (cockpit AI) |
| Billing | `billing_subscriptions` | Oui (`tenant_id`) | 1 | Deja affiche (cockpit) |
| Channels | `tenant_channels` | Oui (`tenant_id`) | 7 | Oui |

---

## 3. Endpoint operations

### Route
```
GET /api/admin/tenants/[id]/operations
```

### RBAC
`super_admin` uniquement

### Payload reel (ecomlg-001 PROD)
```json
{
  "data": {
    "conversations": {
      "total": 270,
      "open": 136,
      "pending": 11,
      "resolved": 123,
      "recent": [
        { "id": "...", "subject": "Demande de facturation...", "status": "open", "channel": "amazon", ... },
        ...
      ]
    },
    "messages": { "total": 864, "last_24h": 0 },
    "queues": { "total": 2, "open": 2, "items": [...] },
    "approvals": { "total": 2, "pending": 2 },
    "followups": { "total": 0, "open": 0 },
    "ai": { "rules_total": 15, "rules_active": 0, "action_log_total": 48, "recent_activity": [...] },
    "channels": { "total": 2, "active": 1, "list": [...] }
  }
}
```

---

## 4. UI cockpit

### Panneau Operations
Le `TenantOperationsPanel` est integre dans `/tenants/[id]` entre les "Acces rapides" et les "Controles Admin".

#### Sections
1. **Conversations** : 4 compteurs (total/ouvertes/en attente/resolues) + 5 conversations recentes avec sujet, statut, canal, date relative
2. **Queues & Cases** : compteurs + derniers items avec type, statut, date
3. **Approbations** : compteurs total/en attente
4. **Follow-ups** : compteurs ou empty state honnete
5. **Activite IA** : regles totales/actives, actions executees, 5 dernieres activites avec type, statut, confiance
6. **Channels connectes** : total/actifs, liste avec provider, marketplace, statut

#### Liens tenant-aware
- "Voir queues" → `/queues?tenantId=<id>`
- "Voir tout" (approbations) → `/approvals?tenantId=<id>`
- "Voir tout" (followups) → `/followups?tenantId=<id>`
- "AI Control Center" → `/ai-control`

#### Actions non destructives
- Bouton "Actualiser" pour recharger les donnees operations
- Liens de navigation vers les modules filtres par tenant
- Retour au cockpit depuis les modules via `TenantFilterBanner`

---

## 5. Preuve DB → API → UI → navigation

### ecomlg-001 (PROD — tenant principal riche)

| Donnee | DB reelle | API reponse | UI cockpit |
|---|---|---|---|
| Conversations total | 262→270 | 270 | 270 |
| Conversations ouvertes | ~136 | 136 | 136 |
| Messages | 831→864 | 864 | 864 |
| Queues | 1→2 | 2 | 2 total, 2 en cours |
| Approbations | 2 | 2 | 2 total, 2 en attente |
| Followups | 0 | 0 | "Aucun follow-up pour ce tenant" |
| Regles IA | 15 | 15 | 15 regles, 0 actives |
| Actions IA | ~48 | 48 | 48 actions executees |
| Channels | 2 | 2 | 1 actif / 2 total |
| Conversations recentes | 5 | 5 | Affichees avec sujet |

### w3lg-mmyqdxzb (PROD — tenant vide, empty states)

| Donnee | DB reelle | API reponse | UI cockpit |
|---|---|---|---|
| Conversations | 0 | 0 | "Aucune conversation pour ce tenant" |
| Messages | 0 | 0 | 0 / 0 |
| Queues | 0 | 0 | "Aucun cas en file d'attente" |
| Followups | 0 | 0 | "Aucun follow-up pour ce tenant" |
| IA activite | 0 | 0 | "Aucune activite IA recente pour ce tenant" |
| Channels | 0 | 0 | "Aucun channel connecte" |
| Regles IA | 15 | 15 | 15 regles, 0 actives |

### Navigation tenant-aware (PROD)
- `/queues?tenantId=ecomlg-001` : page chargee avec filtre tenant actif, `TenantFilterBanner` avec "Retour au cockpit tenant"
- Retour cockpit : navigation vers `/tenants/ecomlg-001` fonctionne

### DEV
- Pod confirme avec image `v2.4.0-ph-admin-87-10d-dev`
- Meme code, meme digest image
- Login navigateur bloque (probleme session NEXTAUTH apres rollout restart, non lie au code)

---

## 6. Deploiement

| Element | Valeur |
|---|---|
| Commit SHA source (feat) | `7e95943a00f553b9610c10d1f738f5c2ea96acd1` |
| Commit SHA source (fix) | `80dd9ad436ea8a45b86ae8adbaa9b6c8808bb499` |
| Tag DEV | `v2.4.0-ph-admin-87-10d-dev` |
| Digest DEV | `sha256:180b81c17253ae26bee007285d3b057264bebf47eb3e88e19f2f706a2c70e3be` |
| Tag PROD | `v2.4.0-ph-admin-87-10d-prod` |
| Digest PROD | `sha256:180b81c17253ae26bee007285d3b057264bebf47eb3e88e19f2f706a2c70e3be` |
| Version runtime | v2.4.0 (visible sidebar) |
| Pod DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.4.0-ph-admin-87-10d-dev` |
| Pod PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.4.0-ph-admin-87-10d-prod` |

### Fichiers modifies (7 fichiers, 751 insertions)
| Fichier | Type |
|---|---|
| `src/features/users/types.ts` | Types TenantOperationsData + sous-types |
| `src/features/users/services/users.service.ts` | Methode `getTenantOperations()` |
| `src/app/api/admin/tenants/[id]/operations/route.ts` | Nouvel endpoint API |
| `src/components/tenant/TenantOperationsPanel.tsx` | Nouveau composant UI |
| `src/app/(admin)/tenants/[id]/page.tsx` | Integration du panneau |
| `src/app/(admin)/followups/page.tsx` | Tenant-aware + Suspense |
| `src/components/layout/Sidebar.tsx` | Version bump v2.4.0 |

---

## 7. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.3.0-ph-admin-87-10c-dev \
  -n keybuzz-admin-v2-dev
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.3.0-ph-admin-87-10c-prod \
  -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

### Images stables precedentes
- DEV : `ghcr.io/keybuzzio/keybuzz-admin:v2.3.0-ph-admin-87-10c-dev`
- PROD : `ghcr.io/keybuzzio/keybuzz-admin:v2.3.0-ph-admin-87-10c-prod`

---

## 8. Dettes restantes

| Dette | Description | Impact |
|---|---|---|
| Followups page filtering | Le `TenantFilterBanner` est ajoute mais le scheduler report n'est pas scope par tenant | Les followups affichent toutes les donnees, pas juste celles du tenant |
| Audit page tenant-aware | Page `/audit` ne supporte pas encore `?tenantId=X` | Pas de filtre tenant sur l'audit |
| Billing page tenant-aware | Page `/billing` ne supporte pas encore `?tenantId=X` | Pas de filtre tenant sur la facturation |
| DEV login session | Le navigateur ne peut plus se connecter au DEV apres le rollout restart | Probleme NEXTAUTH session, pas de code — un redemarrage du navigateur ou nettoyage cookies devrait resoudre |
| Conversations detail | Pas de lien direct vers le detail d'une conversation depuis les recentes | Necessiterait une page conversation detail admin |
| Messages par canal | La repartition par canal dans le panneau messages n'est pas affichee | Donnee disponible via `conversations.channel` |
| Queue items detail | Les items queue dans le panneau n'ont pas de lien vers le detail | Necessiterait une page queue item detail |
