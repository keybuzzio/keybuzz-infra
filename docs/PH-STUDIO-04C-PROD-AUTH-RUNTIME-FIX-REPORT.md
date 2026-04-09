# PH-STUDIO-04C — PROD Auth Runtime Fix

> Date : 3 avril 2026
> Phase : PH-STUDIO-04C
> Type : Debug ciblé + correctif minimal
> Environnement : PROD

---

## Symptôme

Sur https://studio.keybuzz.io/login, après saisie d'un email et clic sur "Send verification code", le frontend affichait :

```
Cannot connect to the server
```

Contexte :
- La page frontend PROD chargeait normalement
- L'API PROD `/health` répondait HTTP 200
- L'API PROD acceptait les requêtes `curl` directes (non-browser)

---

## Diagnostic

### Étape 1 — Vérification config K8s

| Élément | Valeur | Verdict |
|---|---|---|
| `NEXT_PUBLIC_STUDIO_API_URL` (env K8s) | `https://studio-api.keybuzz.io` | OK |
| `CORS_ORIGIN` (API PROD) | `https://studio.keybuzz.io` | OK |
| `COOKIE_DOMAIN` | `.keybuzz.io` | OK |
| Preflight CORS PROD API | HTTP 204, ACAO correct | OK |
| POST direct API PROD | HTTP 200 | OK |

La configuration K8s était correcte, mais `NEXT_PUBLIC_*` est résolu au **build time** par Next.js, pas au runtime.

### Étape 2 — Vérification URL baked dans le JS PROD

Commande exécutée dans le pod PROD :
```
kubectl exec -n keybuzz-studio-prod $POD -- grep -r "studio-api" /app/.next/static/
```

**Résultat : `https://studio-api-dev.keybuzz.io`**

### Étape 3 — Vérification CORS cross-origin DEV API

Preflight `OPTIONS` vers `studio-api-dev.keybuzz.io` avec `Origin: https://studio.keybuzz.io` :

```
access-control-allow-origin: https://studio-dev.keybuzz.io
```

L'API DEV autorise uniquement `studio-dev.keybuzz.io`, pas `studio.keybuzz.io`.

---

## Cause racine

| # | Fait |
|---|---|
| 1 | L'image PROD `keybuzz-studio:v0.3.0-prod` était un **re-tag** de l'image DEV `v0.3.0-dev` |
| 2 | L'image DEV avait été buildée avec `--build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io` |
| 3 | Next.js inline `NEXT_PUBLIC_*` dans le JavaScript **au build time** — les env vars K8s runtime sont ignorés |
| 4 | Le frontend PROD envoyait ses requêtes à l'API **DEV** |
| 5 | L'API DEV rejette le CORS pour l'origin `https://studio.keybuzz.io` |
| 6 | Le `fetch` côté navigateur échouait → catch → "Cannot connect to the server" |

**Résumé : URL API baked incorrecte dans l'image PROD (pointait vers DEV au lieu de PROD).**

---

## Correctif

### Action

Rebuild dédié de l'image frontend PROD avec l'URL correcte :

```bash
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  -t ghcr.io/keybuzzio/keybuzz-studio:v0.3.1-prod .
```

### Déploiement

```bash
docker push ghcr.io/keybuzzio/keybuzz-studio:v0.3.1-prod
kubectl set image deployment/keybuzz-studio \
  keybuzz-studio=ghcr.io/keybuzzio/keybuzz-studio:v0.3.1-prod \
  -n keybuzz-studio-prod
```

Rollout confirmé : `deployment "keybuzz-studio" successfully rolled out`

### Fichiers modifiés

Aucune modification de code source. Le correctif est purement un rebuild d'image Docker avec le bon `--build-arg`.

---

## Validation PROD

### API Backend

| Test | Résultat |
|---|---|
| `/health` | HTTP 200, `{"status":"ok"}` |
| `setup/status` | `{"needed":false}` |
| `POST /api/v1/auth/request-otp` | HTTP 200 |
| CORS preflight (OPTIONS) | HTTP 204, `ACAO: https://studio.keybuzz.io` |
| CORS sur POST | `access-control-allow-origin: https://studio.keybuzz.io` |

### Frontend Pages

| Page | HTTP | Comportement |
|---|---|---|
| `/login` | 200 | Affichage correct |
| `/` | 307 | Redirect login (non-auth) |
| `/dashboard` | 307 | Redirect login (non-auth) |
| `/knowledge` | 307 | Redirect login (non-auth) |
| `/ideas` | 307 | Redirect login (non-auth) |
| `/content` | 307 | Redirect login (non-auth) |

### URL baked vérifiée

```
kubectl exec -n keybuzz-studio-prod $POD -- grep -r "studio-api" /app/.next/static/
→ https://studio-api.keybuzz.io
```

### Test navigateur réel

1. Ouverture de `https://studio.keybuzz.io/login` → page chargée
2. Saisie de `ludovic@keybuzz.pro` → bouton activé
3. Clic "Send verification code" → bouton "Sending..." puis transition vers l'écran OTP
4. Message affiché : "Enter the 6-digit code sent to ludovic@keybuzz.pro"
5. **Aucune erreur "Cannot connect to the server"**

### Logs API PROD

Tous les requêtes complétées avec statusCode 200/204, aucune erreur.

---

## Leçon retenue

> **Next.js `NEXT_PUBLIC_*` est résolu au build time.**
> Il est impossible de promouvoir une image frontend DEV vers PROD par simple re-tag Docker si les URLs API diffèrent entre environnements.
> Chaque environnement nécessite son propre build frontend.

---

## Impact

- **Aucune modification de code source**
- **Aucune modification de configuration K8s** (la config était déjà correcte)
- **Seule l'image Docker frontend a été reconstruite** avec le bon build-arg
- Tag PROD : `v0.3.1-prod` (remplace `v0.3.0-prod`)

---

## Verdict

### PH-STUDIO-04C COMPLETE — PROD LOGIN FIXED

Le frontend PROD appelle maintenant la bonne API PROD. Le login OTP fonctionne de bout en bout dans un vrai navigateur. Aucune erreur réseau, CORS, TLS ou DNS.
