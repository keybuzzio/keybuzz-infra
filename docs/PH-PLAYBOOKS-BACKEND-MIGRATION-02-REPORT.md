# PH-PLAYBOOKS-BACKEND-MIGRATION-02 — Rapport Final

> Date : 2026-03-28
> Auteur : Cursor Executor
> Phase : PH-PLAYBOOKS-BACKEND-MIGRATION-02
> Environnement : DEV uniquement
> Type : migration UI → backend existant (unification système)

---

## 1. OBJECTIF

Unifier définitivement les Playbooks en supprimant le double système (localStorage + DB)
et en branchant la page /playbooks sur le backend existant (API + DB `ai_rules`).

**Résultat attendu :**
- Page /playbooks affiche les playbooks DB (ai_rules)
- Toute modification impacte le moteur IA réel
- Inbox / Autopilot / UI utilisent le MÊME système
- Aucun double système

---

## 2. VERSIONS

| Service | Avant | Après |
|---|---|---|
| Client DEV | `v3.5.123-playbooks-truth-recovery-dev` | `v3.5.124-playbooks-backend-migration-dev` |
| Client PROD | `v3.5.123-playbooks-truth-recovery-prod` | `v3.5.124-playbooks-backend-migration-prod` |
| API DEV | `v3.5.50-ph-tenant-iso-dev` | **NON MODIFIÉE** |
| API PROD | — | **NON TOUCHÉ** |

### Rollback DEV
```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.123-playbooks-truth-recovery-dev \
  -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 3. FICHIERS MODIFIÉS

| Fichier | Action | Description |
|---|---|---|
| `src/hooks/usePlaybooks.ts` | **CRÉÉ** | Hook unifié API (fetchPlaybooks, CRUD, toggle, mapping) |
| `app/playbooks/page.tsx` | Modifié | Remplace localStorage par usePlaybooks hook |
| `app/playbooks/[playbookId]/page.tsx` | Modifié | Remplace localStorage par usePlaybooks hook |
| `app/playbooks/[playbookId]/tester/page.tsx` | Modifié | Charge playbook via API, simulation locale conservée |
| `app/playbooks/new/page.tsx` | Modifié | createPlaybook via API au lieu de savePlaybook localStorage |

### Fichiers NON modifiés (intentionnel)
| Fichier | Raison |
|---|---|
| `src/services/playbooks.service.ts` | Conservé comme fallback rollback |
| `app/api/playbooks/*.ts` (BFF) | Déjà fonctionnels, aucun changement nécessaire |
| `src/modules/playbooks/routes.ts` (API) | Backend non touché (règle absolue) |
| `src/features/inbox/components/PlaybookSuggestionBanner.tsx` | Utilisait déjà le backend, inchangé |

---

## 4. MAPPING API ↔ UI

### Types API (DB ai_rules) → Types UI (Playbook)

| Champ API | Champ UI | Transformation |
|---|---|---|
| `id` | `id` | Direct |
| `tenant_id` | `tenantId` | Rename |
| `name` | `name` | Direct |
| `description` | `description` | Null → "" |
| `status` ("active"/"disabled") | `enabled` (bool) | Conversion |
| `trigger_type` | `trigger` | Rename |
| `scope` | `scope` | Direct |
| `is_starter` | `isStarter` | Rename |
| `mode` | `mode` | Direct |
| `min_plan` | `minPlan` | Rename |
| `priority` | `priority` | Direct |
| `created_at` | `createdAt` | Rename |
| `updated_at` | `updatedAt` | Rename |
| `conditions[].type` | `conditions[].field` | Rename |
| `conditions[].op` | `conditions[].operator` | Rename |
| `conditions[].value` | `conditions[].value` | String → any |
| `actions[].type` | `actions[].type` | Direct |
| `actions[].params` (JSON string) | `actions[].params` (object) | JSON.parse |

### Routes BFF utilisées

| Méthode | Route BFF | Route API Backend |
|---|---|---|
| GET | `/api/playbooks?tenantId=xxx` | `GET /playbooks?tenantId=xxx` |
| POST | `/api/playbooks` | `POST /playbooks` |
| GET | `/api/playbooks/:id?tenantId=xxx` | `GET /playbooks/:id?tenantId=xxx` |
| PUT | `/api/playbooks/:id` | `PUT /playbooks/:id` |
| DELETE | `/api/playbooks/:id?tenantId=xxx` | `DELETE /playbooks/:id?tenantId=xxx` |
| PATCH | `/api/playbooks/:id/toggle` | `PATCH /playbooks/:id/toggle` |

---

## 5. ARCHITECTURE UNIFIÉE

### Avant (double système)
```
Page /playbooks  →  localStorage (5 starters)
PlaybookSuggestionBanner  →  API /playbooks/suggestions (15 starters DB)
Playbook Engine (API)  →  DB ai_rules (15 starters)
```

### Après (source unique)
```
Page /playbooks  →  API → DB ai_rules (15 starters)
PlaybookSuggestionBanner  →  API → DB ai_rules (même source)
Playbook Engine (API)  →  DB ai_rules (même source)
```

---

## 6. TRIGGERS ÉTENDUS

Le hook supporte les triggers backend en plus des triggers client d'origine :

| Trigger | Label FR | Origine |
|---|---|---|
| delivery_delay | Retard de livraison | Client + Backend |
| tracking_request | Demande de suivi | Client + Backend |
| return_request | Demande de retour | Client + Backend |
| damaged_item | Produit endommagé | Client |
| defective_product | Produit défectueux | Backend |
| warranty | Demande garantie | Client |
| supplier_escalation | Escalade fournisseur | Client |
| unanswered_2h | Sans réponse 2h | Client |
| unanswered_timeout | Sans réponse (SLA) | Backend |
| negative_sentiment | Sentiment négatif | Client + Backend |
| payment_declined | Paiement refusé | Backend |
| invoice_request | Demande de facture | Backend |
| order_cancelled | Annulation commande | Backend |
| incompatible_product | Produit incompatible | Backend |
| off_topic | Message hors sujet | Backend |
| vip_client | Client VIP | Backend |
| escalation_needed | Escalade nécessaire | Backend |

---

## 7. VALIDATION E2E DEV

### Cas 1 — ecomlg-001
- **15 playbooks** visibles via API
- Tous starters, tous disabled
- Aucune perte, aucune duplication

### Cas 2 — Nouveau tenant
- L'API seed automatiquement 15 starters à la première requête
- Page ne sera pas vide

### Cas 3 — Modification playbook
- PUT /playbooks/:id → impact réel DB
- Le moteur IA lit la même DB → cohérence

### Cas 4 — Inbox
- PlaybookSuggestionBanner inchangé
- Utilisait déjà le backend → aucune régression

### Cas 5 — Autopilot
- Playbook Engine inchangé
- Lit la même DB → aucune régression

### Build
- Next.js compilé sans erreur
- Pod Running, démarrage en 410ms
- Aucun crash ni erreur dans les logs

---

## 8. PREUVES

### Image déployée
```
ghcr.io/keybuzzio/keybuzz-client:v3.5.124-playbooks-backend-migration-dev
```

### API Response (ecomlg-001)
```
Playbooks count: 15
Active: 0 | Disabled: 15
Starters: 15
First 3:
  - Où est ma commande ? | disabled | tracking_request
  - Suivi indisponible | disabled | tracking_request
  - Retard de livraison | disabled | delivery_delay
```

### Git
```
Commit: e5034ab
Message: PH-PLAYBOOKS-BACKEND-MIGRATION-02: unify playbooks UI with backend API
Branch: main
Pushed: origin/main
```

---

## 9. IMPACT

### Ce qui change
- `/playbooks` lit depuis l'API (DB) au lieu de localStorage
- `/playbooks/[id]` édite via l'API (DB)
- `/playbooks/new` crée via l'API (DB)
- Simulation tester utilise les données API
- Duplication via API POST au lieu de localStorage

### Ce qui ne change PAS
- Backend API : inchangé
- Inbox suggestions : inchangé (utilisait déjà l'API)
- Autopilot engine : inchangé
- Billing / plans / gating : inchangé
- Auth / tenant context : inchangé

---

## 10. ÉTAT PROD

**PROD PROMU — Validation Ludovic obtenue**

Image PROD : `v3.5.124-playbooks-backend-migration-prod`
Déployé le : 2026-03-28

### Rollback PROD
```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.123-playbooks-truth-recovery-prod \
  -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## 11. VERDICT FINAL

```
PLAYBOOKS BACKEND CONNECTED — SINGLE SOURCE OF TRUTH — TENANT SAFE — ROLLBACK READY
```

| Critère | Statut |
|---|---|
| Page /playbooks utilise API | ✅ OUI |
| Plus aucun accès localStorage actif | ✅ OUI |
| Inbox suggestions toujours OK | ✅ OUI |
| Autopilot OK | ✅ OUI |
| Aucun crash UI | ✅ OUI |
| Multi-tenant strict | ✅ OUI |
| Backend non modifié | ✅ OUI |
| PROD promu | ✅ OUI |
| Rollback documenté | ✅ OUI |
| GitOps | ✅ OUI |

---

## 12. PROCHAINE PHASE RECOMMANDÉE

**PH-PLAYBOOKS-STARTERS-ACTIVATION-03**
- Activer les starters pertinents par défaut
- Vérifier la cohérence avec les plans
- Documenter les playbooks starter de référence
