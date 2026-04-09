# PH-STUDIO-04B — Owner Bootstrap + Knowledge / Ideas / Content MVP

> Phase : PH-STUDIO-04B
> Date : 2026-04-03
> Statut : **COMPLETE — OWNER READY + CORE PRODUCT MVP**

---

## 1. Objectif

Rendre Studio reellement utilisable en :
- Creant le premier owner (ludovic@keybuzz.pro)
- Corrigeant le layout auth
- Remplacant les placeholders par les 3 modules metier : Knowledge, Ideas, Content
- Construisant un dashboard utile

## 2. Compte Owner

### Methode
Le compte a ete cree via l'endpoint `POST /api/v1/auth/setup` (bootstrap one-shot de PH-STUDIO-04A), en utilisant le `BOOTSTRAP_SECRET` stocke dans Vault.

### DEV
- Email : ludovic@keybuzz.pro
- Display name : Ludovic GONTHIER
- Workspace : KeyBuzz (slug: keybuzz)
- Role : owner
- Verification : `GET /auth/setup/status` retourne `{"needed":false}`

### PROD
- Meme configuration
- Bootstrap effectue apres promotion PROD
- Verification identique

### Securite
- Aucune donnee owner hardcodee dans le code
- Bootstrap via donnees runtime + secret Vault
- Bootstrap desactive apres premier owner cree (needed:false → 409 Conflict)

## 3. Validation Auth DEV

| Test | Resultat |
|------|----------|
| setup/status = false | OK |
| request-otp pour ludovic@keybuzz.pro | OK (email envoye + devCode) |
| verify-otp | HTTP 200, session creee |
| /auth/me | User correct, workspace KeyBuzz, role owner |
| logout | Session invalidee, /auth/me = 401 |
| pages protegees sans cookie | HTTP 307 redirect /login |

## 4. Fix UX Auth

### Probleme
Le body root a `class="flex h-full"`. Le layout auth etait `<>{children}</>`, ce qui ne donnait pas la pleine largeur au contenu auth.

### Solution
Layout auth modifie en `<div className="grow w-full">{children}</div>`. Les pages /login et /setup sont maintenant correctement centrees verticalement et horizontalement.

## 5. Modele de Donnees

### knowledge_documents (colonnes ajoutees)
| Colonne | Type | Defaut |
|---------|------|--------|
| status | VARCHAR(50) | 'draft' |
| summary | TEXT | NULL |
| content_structured | JSONB | '{}' |
| tags | TEXT[] | '{}' |
| source | VARCHAR(255) | NULL |
| created_by | UUID FK users | NULL |

### ideas (nouvelle table)
| Colonne | Type | Defaut |
|---------|------|--------|
| id | UUID PK | uuid_generate_v4() |
| workspace_id | UUID FK workspaces | NOT NULL |
| title | VARCHAR(500) | NOT NULL |
| description | TEXT | NULL |
| status | VARCHAR(50) | 'inbox' |
| score | INT | 0 |
| target_channel | VARCHAR(100) | NULL |
| source_type | VARCHAR(100) | NULL |
| source_reference | TEXT | NULL |
| tags | TEXT[] | '{}' |
| created_by | UUID FK users | NULL |
| created_at / updated_at | TIMESTAMPTZ | NOW() |

Status possibles : inbox, review, approved, rejected, converted
Canaux cibles : linkedin, reddit, seo, x, other

### content_items (colonne ajoutee)
| Colonne | Type |
|---------|------|
| current_version_id | UUID |

## 6. Routes Backend

### Knowledge
| Methode | Route | Action |
|---------|-------|--------|
| GET | /api/v1/knowledge | Liste (filtres: status, doc_type) |
| GET | /api/v1/knowledge/:id | Detail |
| POST | /api/v1/knowledge | Creation |
| PATCH | /api/v1/knowledge/:id | Mise a jour |
| DELETE | /api/v1/knowledge/:id | Suppression |

### Ideas
| Methode | Route | Action |
|---------|-------|--------|
| GET | /api/v1/ideas | Liste (filtres: status, target_channel) |
| GET | /api/v1/ideas/:id | Detail |
| POST | /api/v1/ideas | Creation |
| PATCH | /api/v1/ideas/:id | Mise a jour |
| DELETE | /api/v1/ideas/:id | Suppression |

### Content
| Methode | Route | Action |
|---------|-------|--------|
| GET | /api/v1/content | Liste (filtres: status, channel, content_type) |
| GET | /api/v1/content/:id | Detail |
| POST | /api/v1/content | Creation (+ version 1 auto) |
| PATCH | /api/v1/content/:id | Mise a jour |
| DELETE | /api/v1/content/:id | Suppression |
| POST | /api/v1/content/:id/versions | Nouvelle version |
| GET | /api/v1/content/:id/versions | Historique versions |

### Dashboard
| Methode | Route | Action |
|---------|-------|--------|
| GET | /api/v1/dashboard/stats | Compteurs + activite recente |

Toutes les routes sont auth-required et workspace-aware.

## 7. Ecrans Frontend

### Dashboard (/dashboard)
- Compteurs reels : Knowledge, Ideas, Content, Drafts
- Activite recente (8 derniers items tous types confondus)
- Liens vers chaque section
- Nom utilisateur + workspace affiches

### Knowledge (/knowledge)
- Liste en table avec titre, type, status, date, tags
- Filtres par type de document
- Recherche texte
- Dialog creation/edition (titre, type, status, summary, contenu, tags, source)
- Suppression avec confirmation
- Empty state

### Ideas (/ideas)
- Liste en table avec titre, score, canal, status, tags
- Filtres par status
- Recherche texte
- Score colore (vert >= 70, ambre >= 40, gris < 40)
- Action "Convert to content" pour les idees approuvees
- Dialog creation/edition
- Empty state

### Content (/content)
- Liste en table avec titre, type, canal, status, tags
- Filtres par status
- Recherche texte
- Dialog de creation (titre, type, canal, body, tags)
- Dialog d'edition (avec tous les champs + status)
- Bouton "Save as version" pour creer un snapshot
- Dialog historique des versions
- Empty state

## 8. Validations DEV

| Test | Resultat |
|------|----------|
| Knowledge create | OK (201) |
| Knowledge get/list/update | OK |
| Ideas create (score 75, channel linkedin) | OK |
| Ideas get/list/update | OK |
| Content create (version 1 auto) | OK |
| Content version 2 | OK |
| Content versions list (v2, v1) | OK |
| Dashboard stats (1/1/1/0, 3 recent) | OK |
| Logout → auth/me = 401 | OK |
| Frontend pages protegees → 307 redirect | OK |
| Frontend login → 200 | OK |

## 9. Validations PROD

| Test | Resultat |
|------|----------|
| Migration appliquee | OK |
| Images v0.3.0-prod (meme SHA que DEV) | OK |
| Pods Running, 0 restarts | OK |
| /health | OK |
| setup/status = false (owner cree) | OK |
| Frontend login = HTTP 200 | OK |
| API logs propres (JSON, zero erreur) | OK |

## 10. Points Ouverts

| Point | Priorite | Mitigation |
|-------|----------|------------|
| Donnees test DEV a nettoyer avant usage reel | Basse | Delete via API |
| Pas de pagination backend | Moyenne | Ajouter LIMIT/OFFSET sur les listes |
| Pas de confirm delete propre (window.confirm) | Basse | Remplacer par AlertDialog UI |
| Content "Create from idea" redirige sans feedback | Basse | Ajouter toast notification |

## 11. Verdict

### PH-STUDIO-04B COMPLETE — OWNER READY + CORE PRODUCT MVP

- Owner ludovic@keybuzz.pro cree en DEV et PROD
- Login OTP fonctionnel
- Knowledge, Ideas, Content — CRUD complet backend + frontend
- Dashboard avec donnees reelles
- DEV et PROD alignes (meme SHA image)
- Aucun hardcode utilisateur
- Aucun secret expose
- Multi-user / multi-workspace ready
