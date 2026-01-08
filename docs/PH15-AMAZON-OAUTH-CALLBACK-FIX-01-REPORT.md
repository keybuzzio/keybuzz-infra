# PH15-AMAZON-OAUTH-CALLBACK-FIX-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Correction du callback OAuth Amazon en DEV pour :
1. Utiliser `backend-dev.keybuzz.io` comme redirect_uri
2. Rediriger vers `client-dev.keybuzz.io/onboarding` après callback

---

## 1. Problèmes Identifiés

### Problème 1 : redirect_uri mismatch

**Avant** : Le secret `amazon-spapi-creds` contenait :
```
AMAZON_SPAPI_REDIRECT_URI=https://platform-api.keybuzz.io/.../callback
```

Amazon redirigeait donc vers `platform-api.keybuzz.io` qui n'existait pas en DEV.

**Solution** : Changer vers `backend-dev.keybuzz.io` :
```bash
kubectl -n keybuzz-backend-dev delete secret amazon-spapi-creds
kubectl -n keybuzz-backend-dev create secret generic amazon-spapi-creds \
  --from-literal=AMAZON_SPAPI_REDIRECT_URI=https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback \
  ...
```

### Problème 2 : Callback retournait JSON

**Avant** : Le callback retournait :
```json
{"success":true,"tenantId":"...","sellingPartnerId":"..."}
```

L'utilisateur voyait du JSON brut au lieu d'être redirigé vers le wizard.

**Solution** : Modifier le callback pour rediriger :
```typescript
// Success
const clientUrl = process.env.CLIENT_CALLBACK_URL || "https://client-dev.keybuzz.io/onboarding";
return reply.redirect(`${clientUrl}?amazon_connected=true&tenant_id=${tenantId}`);

// Error
return reply.redirect(`${clientUrl}?amazon_error=${errorMsg}`);
```

---

## 2. Flow OAuth Corrigé

```
┌─────────────────────────────────────────────────────────────┐
│  1. Wizard: Click "Connecter Amazon"                        │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  2. backend-dev/oauth/start                                 │
│     → Génère authUrl avec:                                  │
│       redirect_uri=backend-dev.keybuzz.io/.../callback      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Amazon Seller Central                                   │
│     → User autorise l'app                                   │
│     → Redirige vers backend-dev/.../callback?code=...       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  4. backend-dev/oauth/callback                              │
│     → Échange code → refresh_token                          │
│     → Update MarketplaceConnection → CONNECTED              │
│     → Redirect client-dev/onboarding?amazon_connected=true  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Wizard affiche "Amazon Connecté ✅"                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Configuration DEV Finale

### Secret amazon-spapi-creds

```yaml
AMAZON_SPAPI_CLIENT_ID: amzn1.application-oa2-client.***
AMAZON_SPAPI_CLIENT_SECRET: amzn1.oa2-cs.v1.***
AMAZON_SPAPI_APP_ID: amzn1.sp.solution.***
AMAZON_SPAPI_REDIRECT_URI: https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback
```

### Callback Redirect

```
Success: https://client-dev.keybuzz.io/onboarding?amazon_connected=true&tenant_id=...
Error:   https://client-dev.keybuzz.io/onboarding?amazon_error=...
```

---

## 4. Preuve OAuth Start

```bash
curl -X POST backend-dev.keybuzz.io/.../oauth/start \
  -H "X-User-Email: ludo.gonthier@gmail.com" \
  -H "X-Tenant-Id: kbz-001"

# Réponse (authUrl tronquée) :
{
  "success": true,
  "authUrl": "https://sellercentral.amazon.com/apps/authorize/consent?...&redirect_uri=https%3A%2F%2Fbackend-dev.keybuzz.io%2F...%2Fcallback"
}
```

---

## 5. Versions Déployées

| Composant | Version | Image |
|-----------|---------|-------|
| keybuzz-backend | v1.0.1-dev | `sha256:4bd31f66...` |
| keybuzz-client | v0.2.41-dev | (inchangé) |

---

## 6. Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-backend | `1a4f141` | OAuth callback redirects to client-dev |
| keybuzz-infra | `ead745c` | backend-dev v1.0.1 + redirect_uri fix |

---

## 7. Comportement Attendu

| Action | Résultat |
|--------|----------|
| Click "Connecter Amazon" | Redirection Amazon Seller Central |
| Autorisation Amazon | Redirection client-dev/onboarding?amazon_connected=true |
| Refus/Erreur Amazon | Redirection client-dev/onboarding?amazon_error=... |
| Status après callback | CONNECTED dans MarketplaceConnection |

---

**Fin du rapport PH15-AMAZON-OAUTH-CALLBACK-FIX-01**
