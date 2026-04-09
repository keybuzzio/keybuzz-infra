# PH-STUDIO-05 — Assets + Calendar + Editorial Workflow

> Date : 3 avril 2026
> Phase : PH-STUDIO-05
> Type : Extension produit — organisation operationnelle du contenu
> Environnements : DEV + PROD

---

## Objectif

Transformer Studio en outil reellement exploitable au quotidien pour la production marketing :
- Gerer les assets (images, medias)
- Planifier les contenus dans un calendrier editorial
- Structurer un workflow editorial complet
- Relier Ideas → Content → Assets → Calendar

---

## A. Assets (gestion medias)

### Modele de donnees

Table `content_assets` enrichie (migration 003) :

| Colonne | Type | Description |
|---|---|---|
| original_name | VARCHAR(500) | Nom original du fichier uploade |
| storage_key | VARCHAR(500) | Cle unique sur le systeme de stockage |
| storage_provider | VARCHAR(50) | Provider (local, s3, minio) |
| url | TEXT | URL de service |
| tags | TEXT[] | Tags pour categoriser |
| updated_at | TIMESTAMPTZ | Timestamp de mise a jour |

Table `content_item_assets` (join) :
- `content_item_id` → `content_items(id)`
- `asset_id` → `content_assets(id)`
- Contrainte UNIQUE sur la paire

### Stockage MVP

- **Provider** : `local` (systeme de fichiers)
- **Chemin** : `/data/assets/{workspace_id}/{uuid}-{filename}`
- **Limite** : 10MB par fichier via `@fastify/multipart`
- **Limitation** : stockage ephemere (emptyDir) — PVC ou S3/MinIO prevu pour une phase ulterieure

### Endpoints backend

| Methode | Route | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/assets/upload` | Oui | Upload multipart |
| GET | `/api/v1/assets` | Oui | Liste (filtres: mime_prefix, tag) |
| GET | `/api/v1/assets/:id` | Oui | Detail |
| PATCH | `/api/v1/assets/:id` | Oui | Update tags |
| DELETE | `/api/v1/assets/:id` | Oui | Suppression (fichier + DB) |
| GET | `/api/v1/assets/:id/file` | **Non** | Service fichier (UUID security) |
| POST | `/api/v1/content/:id/assets` | Oui | Attacher asset a content |
| GET | `/api/v1/content/:id/assets` | Oui | Liste assets d'un content |
| DELETE | `/api/v1/content/:cid/assets/:aid` | Oui | Detacher asset |

### Frontend `/assets`

- Grille responsive (2-5 colonnes)
- Preview images, icone pour les autres types
- Upload dialog avec tags
- Filtres par type (All, Images, PDF, Video)
- Recherche par nom
- Edit tags inline
- Suppression avec confirmation

---

## B. Calendar (planning editorial)

### Modele de donnees

Table `content_calendars` enrichie (migration 003) :

| Colonne ajoutee | Type | Description |
|---|---|---|
| timezone | VARCHAR(100) | Fuseau horaire (defaut Europe/Paris) |
| created_by | UUID | Createur |

### Endpoints backend

| Methode | Route | Description |
|---|---|---|
| GET | `/api/v1/calendar` | Liste (filtres: from, to, channel, status) |
| GET | `/api/v1/calendar/:id` | Detail (avec content_title joint) |
| POST | `/api/v1/calendar` | Creation |
| PATCH | `/api/v1/calendar/:id` | Mise a jour |
| DELETE | `/api/v1/calendar/:id` | Suppression |

### Frontend `/calendar`

- Vue calendrier mois (grille 7 colonnes x 6 rangees)
- Navigation mois precedent/suivant
- Aujourd'hui mis en surbrillance (cercle primary)
- Entries affichees dans les cellules (heure + titre)
- Clic sur un jour → creation nouvelle entree
- Clic sur une entree → edition
- Lien avec content items (select dans les dialogs)
- Statuts : draft, scheduled, published, cancelled

---

## C. Workflow editorial

### Etats contenu

```
draft → review → approved → scheduled → published → archived
```

### Transitions valides

| De | Vers |
|---|---|
| draft | review |
| review | approved, draft |
| approved | scheduled, draft |
| scheduled | published, approved |
| published | archived |
| archived | draft |

### Implementation backend

- Methode `transitionStatus()` dans `ContentService`
- Validation stricte des transitions (map cote serveur)
- Transition invalide → `AppError(400)` avec message explicite
- Logging dans `activity_logs` a chaque transition
- Champs `scheduled_at` et `published_at` automatiquement mis a jour

### Route

| Methode | Route | Description |
|---|---|---|
| POST | `/api/v1/content/:id/transition` | Changer statut (body: `{status: "review"}`) |

### Frontend

- Boutons de transition contextuel dans la liste content (ex: "Send to review", "Approve", "Schedule", "Publish")
- Badges couleur par statut

---

## D. Dashboard enrichi

### Nouvelles stats

| Card | Description |
|---|---|
| Scheduled | Contenus avec statut `scheduled` |
| Published | Contenus avec statut `published` |
| Assets | Total fichiers uploades |

### Activite recente

- Inclut maintenant les entries calendar en plus de knowledge, ideas, content
- Affiche le statut quand disponible
- 10 items max, tries par date

---

## Validation DEV

### Resultats (30/30 tests passes)

| Categorie | Tests | Resultat |
|---|---|---|
| Auth (OTP session) | 2 | OK |
| Dashboard (7 compteurs) | 7 | OK |
| Calendar CRUD | 4 | OK |
| Assets CRUD + file serve | 6 | OK |
| Workflow transitions (6 etapes + blocage invalide) | 7 | OK |
| Content-Asset linking | 3 | OK |
| Logout | 1 | OK |

### Pages frontend

Toutes les pages protegees redirigent correctement vers /login (HTTP 307) quand non authentifie.

---

## Deploiement PROD

### Actions

1. Migration 003 appliquee sur DB PROD (toutes colonnes/tables idempotentes)
2. API : re-tag `v0.4.0-dev` → `v0.4.0-prod` (env vars runtime)
3. Frontend : **build dedie PROD** avec `NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io`
4. K8s PROD : rollout deployment API + Frontend → success

### Verification PROD

| Test | Resultat |
|---|---|
| `/health` | HTTP 200 |
| Frontend `/login` | HTTP 200 |
| Baked URL | `https://studio-api.keybuzz.io` |
| CORS preflight | HTTP 204 |
| Login OTP (navigateur reel) | OK — ecran code OTP affiche |

### Images Docker

```
ghcr.io/keybuzzio/keybuzz-studio:v0.4.0-dev
ghcr.io/keybuzzio/keybuzz-studio:v0.4.0-prod (build dedie)
ghcr.io/keybuzzio/keybuzz-studio-api:v0.4.0-dev
ghcr.io/keybuzzio/keybuzz-studio-api:v0.4.0-prod (re-tag)
```

---

## Fichiers crees/modifies

### Nouveaux fichiers

| Fichier | Description |
|---|---|
| `keybuzz-studio-api/src/db/migrations/003-assets-calendar-workflow.sql` | Migration DB |
| `keybuzz-studio-api/src/modules/assets/assets.service.ts` | Service assets (upload, CRUD, file serve, linking) |
| `keybuzz-studio-api/src/modules/assets/assets.routes.ts` | Routes assets (protected + public file) |
| `keybuzz-studio-api/src/modules/calendar/calendar.service.ts` | Service calendar (CRUD, filtres date) |
| `keybuzz-studio-api/src/modules/calendar/calendar.routes.ts` | Routes calendar |

### Fichiers modifies

| Fichier | Modification |
|---|---|
| `keybuzz-studio-api/src/modules/content/content.service.ts` | Ajout `transitionStatus()` avec validation + activity_logs |
| `keybuzz-studio-api/src/modules/content/content.routes.ts` | Route POST `/content/:id/transition` |
| `keybuzz-studio-api/src/modules/dashboard/dashboard.service.ts` | 7 compteurs + calendar dans activite recente |
| `keybuzz-studio-api/src/routes/index.ts` | Enregistrement assets + calendar routes |
| `keybuzz-studio-api/src/config/env.ts` | Ajout `UPLOAD_DIR` |
| `keybuzz-studio-api/src/index.ts` | Enregistrement `@fastify/multipart` |
| `keybuzz-studio-api/Dockerfile` | `mkdir -p /data/assets` |
| `keybuzz-studio-api/src/db/schema.sql` | Schema complet mis a jour phase 05 |
| `keybuzz-studio/services/api.ts` | Ajout methode `upload()` + `assetFileUrl()` |
| `keybuzz-studio/app/(studio)/assets/page.tsx` | Page assets complete |
| `keybuzz-studio/app/(studio)/calendar/page.tsx` | Page calendar complete |
| `keybuzz-studio/app/(studio)/content/page.tsx` | Boutons workflow transitions |
| `keybuzz-studio/app/(studio)/dashboard/page.tsx` | 7 cards + calendar activity |

---

## Limites connues

| Limite | Impact | Mitigation prevue |
|---|---|---|
| Stockage assets local (emptyDir) | Fichiers perdus si pod restart | PVC ou S3/MinIO |
| Pas de drag-and-drop calendar | UX basique | Librairie calendar phase UX |
| Pas de preview PDF/video | Seulement images | Generateur de thumbnails |
| Pas de scheduling reel (cron) | Publication manuelle | Cron external ou n8n |
| Pas de notifications | Pas d'alerte sur transitions | WebSocket ou polling |

---

## Verdict

### PH-STUDIO-05 COMPLETE — EDITORIAL SYSTEM READY

Studio dispose maintenant de :
- Une bibliotheque d'assets avec upload/preview/tags
- Un calendrier editorial avec vue mois et liens content
- Un workflow editorial complet valide cote serveur
- Le pipeline complet : **Idea → Content → Assets → Calendar**
- Un dashboard enrichi avec 7 indicateurs
