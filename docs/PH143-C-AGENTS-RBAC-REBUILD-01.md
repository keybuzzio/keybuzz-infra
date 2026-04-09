# PH143-C — Agents + RBAC Rebuild

> Phase : PH143-C-AGENTS-RBAC-REBUILD-01
> Date : 2026-04-05
> Branches : `rebuild/ph143-api`, `rebuild/ph143-client`
> Verdict : **GO**

---

## 1. Resume executif

Reconstruction complete du bloc Agents + RBAC sur les branches rebuild PH143.
Tous les mecanismes de securite sont en place :
- Creation agent type `client` uniquement (type `keybuzz` rejete 400)
- Limites agents par plan (STARTER=1, PRO=2, AUTOPILOT=3)
- Cookie `currentTenantRole` persistant (365j, path `/`, sameSite lax)
- Middleware RBAC bloque les agents sur les pages admin-only
- Page `/no-access` fonctionnelle
- BFF role guard et injection cookie serveur-side
- Dockerfile avec `COPY middleware.ts`

---

## 2. API Agents (avant / apres)

### Avant (PH131-B.2)
- `POST /agents` acceptait `type: 'client'` ou `type: 'keybuzz'`
- Pas de limites par plan
- Pas d'endpoint interne `/agents/internal-keybuzz`

### Apres (PH143-C)
- `POST /agents` rejette `type: 'keybuzz'` → 400 `"type must be client"`
- Limites agents par plan : STARTER/free=1, PRO=2, AUTOPILOT=3, ENTERPRISE=999
- Limites agents KeyBuzz par plan : STARTER/PRO=0, AUTOPILOT=1, ENTERPRISE=999
- `POST /agents/internal-keybuzz` protege par X-Internal-Token
- `tenantGuard.ts` : ajout `/api/v1/tracking/webhook` aux prefixes exempts

### Fichiers API modifies
| Fichier | Changement |
|---|---|
| `src/modules/agents/routes.ts` | Agent limits, keybuzz rejection, internal endpoint |
| `src/plugins/tenantGuard.ts` | Tracking webhook exempt |

---

## 3. Invitation Agent E2E

L'infrastructure d'invitation est intacte depuis PH131-B.2 :
- `app/invite/[token]/page.tsx` — page d'invitation
- `app/invite/continue/page.tsx` — continuation post-auth
- `app/api/space-invites/accept/route.ts` — BFF acceptation

Non re-teste en E2E complet (necessite un vrai email agent + OTP), mais la stack code est identique a la version validee.

---

## 4. RBAC Menu (sidebar)

### Owner/Admin
Sidebar complete : Demarrage, Tableau de bord, Messages, Commandes, Canaux, Fournisseurs, Base de reponses, Automatisation IA, Journal IA, IA Performance, Parametres, Facturation.

### Agent
Le filtrage sidebar est gere par `TenantProvider.tsx` et `ClientLayout.tsx`, qui masquent les liens admin selon le role. Le cookie `currentTenantRole` est persistant avec `expires: 365, path: '/', sameSite: 'lax'`.

---

## 5. RBAC URL (middleware)

### Mecanisme
- `middleware.ts` : lit le cookie `currentTenantRole`
- Si role = `agent` ou `viewer` et route dans `ADMIN_ONLY_ROUTES` → redirect `/inbox?rbac=restricted`
- `routeAccessGuard.ts` definit `ADMIN_ONLY_ROUTES` : `/settings`, `/billing`, `/channels`, `/dashboard`, `/knowledge`, `/onboarding`, `/start`, `/ai-journal`, `/ai-dashboard`, `/admin`

### Cookie injection
- Client-side : `TenantProvider.tsx` set le cookie apres fetch des tenants
- Server-side : `app/api/tenant-context/me/route.ts` set le cookie dans les headers de reponse (PH142-O2)

### Dockerfile
Ajout de `COPY middleware.ts ./` pour que le middleware soit inclus dans le build Next.js standalone.

### Fichiers client modifies
| Fichier | Changement |
|---|---|
| `src/features/tenant/TenantProvider.tsx` | Cookie persistence (expires: 365, path: /) |
| `Dockerfile` | COPY middleware.ts |
| `app/api/tenant-context/me/route.ts` | Server-side role cookie injection |
| `app/no-access/page.tsx` | **Nouveau** — page "Acces non autorise" |
| `src/lib/bff-role-guard.ts` | **Nouveau** — BFF permission guard |

---

## 6. Tests reels DEV

### API
| Test | Resultat |
|---|---|
| `GET /health` | 200 OK |
| `POST /agents type=keybuzz` | **400** `"type must be client"` |
| `GET /agents?tenantId=ecomlg-001` | 200 — 6 agents listes |

### UI Owner (non-regression)
| Test | Resultat |
|---|---|
| Login OTP ludo.gonthier@gmail.com | OK |
| Select tenant eComLG | OK |
| Sidebar complete (12+ liens) | OK |
| `/settings` accessible | OK |
| `/settings` onglet Agents visible + bouton Ajouter | OK |
| `/dashboard` accessible | OK |
| `/billing` accessible | OK |

### RBAC URL (cookie agent simule)
| Route | Attendu | Resultat |
|---|---|---|
| `/settings` | Redirect `/inbox?rbac=restricted` | **OK** |
| `/dashboard` | Redirect `/inbox?rbac=restricted` | **OK** |
| `/channels` | Redirect `/inbox` | **OK** |
| `/knowledge` | Redirect `/inbox` | **OK** |

### Page no-access
| Test | Resultat |
|---|---|
| `/no-access` charge | OK |
| Titre "Acces non autorise" | OK |
| Bouton "Aller a ma boite de reception" | OK |
| Bouton "Retour" | OK |

---

## 7. Commits SHA

| Repo | Branche | SHA | Message |
|---|---|---|---|
| keybuzz-api | `rebuild/ph143-api` | `9a142f7` | PH143-C rebuild agents RBAC |
| keybuzz-client | `rebuild/ph143-client` | `a5d5988` | PH143-C rebuild agents RBAC |

---

## 8. Images DEV

| Service | Image |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.196-ph143-agents-rbac-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.196-ph143-agents-rbac-dev` |

---

## 9. Limites / Points non testes

1. **Invitation agent E2E reelle** : necessite un vrai email agent + reception OTP, non teste dans cette phase (code porte integralement depuis main)
2. **Menu agent reduit** : teste via cookie simule, pas via un vrai compte agent
3. **Agent limit enforcement** : code en place, non teste par creation effective (le tenant a deja 5 agents actifs, depassant la limite PRO de 2)

---

## 10. Verdict

**GO** pour PH143-D (IA Assist).

La couche Agents + RBAC est completement reconstruite avec :
- Rejection type keybuzz : **OK**
- Limites agents par plan : **EN PLACE**
- Cookie RBAC persistant : **OK**
- Middleware URL blocking : **OK**
- Page no-access : **OK**
- Dockerfile middleware : **OK**
- Non-regression owner : **OK**
- Branches `main` intactes : **CONFIRME**
