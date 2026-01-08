# PH15-AMAZON-OAUTH-REDIRECT-FIX-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Correction de la redirection OAuth Amazon. Le bouton "Connecter Amazon" redirige maintenant correctement vers Amazon Seller Central.

---

## 1. Problème Identifié

### Cause Racine

La route client `/api/amazon/oauth/start` envoyait un `connectionId` fictif au backend :

```typescript
// AVANT (cassé)
body: JSON.stringify({
  tenantId,
  connectionId: connectionId || `${tenantId}-amazon-wizard`, // Fake ID!
}),
```

Ce `connectionId` (ex: `kbz-001-amazon-wizard`) n'existait pas dans la base de données, provoquant une erreur 404 du backend :

```json
{"error":"MarketplaceConnection not found or does not belong to tenant"}
```

### Solution

Le backend crée automatiquement une `MarketplaceConnection` si `connectionId` n'est pas fourni. La correction consiste à n'envoyer `connectionId` que s'il provient réellement de la DB :

```typescript
// APRÈS (corrigé)
body: JSON.stringify({
  tenantId,
  // Only include connectionId if we have a real one from DB
  ...(connectionId ? { connectionId } : {}),
}),
```

---

## 2. Fichier Modifié

```
keybuzz-client/app/api/amazon/oauth/start/route.ts
```

**Changement** : Suppression du fallback `${tenantId}-amazon-wizard` pour `connectionId`

---

## 3. Flow OAuth Corrigé

```
┌─────────────────────────────────────────────────────────────┐
│  1. Utilisateur clique "Connecter Amazon"                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Client GET /api/amazon/oauth/start                      │
│     → Appelle backend POST /oauth/start (sans connectionId) │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Backend crée MarketplaceConnection (status: PENDING)    │
│     → Génère authUrl Amazon Seller Central                  │
│     → Retourne { authUrl, state }                           │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Client redirige vers authUrl                            │
│     → Utilisateur sur Amazon Seller Central                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Preuves

### Backend OAuth Start (test direct)

```bash
# Sans connectionId → backend crée automatiquement
curl -X POST backend-dev/api/v1/marketplaces/amazon/oauth/start \
  -H "X-User-Email: demo@keybuzz.io" \
  -H "X-Tenant-Id: kbz-001" \
  -d '{"tenantId":"kbz-001"}'
# → { "authUrl": "https://sellercentral.amazon.com/apps/authorize/consent?...", ... }
```

### Version Client

```bash
curl https://client-dev.keybuzz.io/debug/version
# {"version":"0.2.40","buildDate":"2026-01-08T08:26:05Z"}
```

---

## 5. Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-client | `489c3e9` | fix(PH15): OAuth redirect - remove fake connectionId |
| keybuzz-infra | `2ac02b9` | feat(PH15): update client to v0.2.40-dev - OAuth fix |

---

## 6. Version Déployée

```
ghcr.io/keybuzzio/keybuzz-client:v0.2.40-dev
digest: sha256:bdd2d23b55b58eab98af5788862c5e16e2e04239c17d69ae59b8f0e743123fc1
```

---

## 7. Comportement Attendu

| Action | Résultat |
|--------|----------|
| Clic "Connecter Amazon" | Redirection vers Amazon Seller Central |
| Annulation OAuth | Retour wizard, status DISCONNECTED |
| Relance OAuth | Nouvelle redirection vers Amazon |

---

**Fin du rapport PH15-AMAZON-OAUTH-REDIRECT-FIX-01**
