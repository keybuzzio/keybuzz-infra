# PH15-AMAZON-INBOUND-VALIDATION-UX-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Amélioration de l'UX pour l'adresse inbound Amazon avec :
- Affichage de l'adresse réelle (pas "pending")
- Badge de statut (PENDING/VALIDATED)
- Bouton "Envoyer email de validation"
- Correction des caractères échappés (`\u00e9` -> `é`)

---

## 1. Endpoints Backend

### GET /api/v1/marketplaces/amazon/inbound-address

**Existant** - Retourne l'adresse inbound et son statut.

Réponse :
```json
{
  "address": "amazon.ecomlg-001.fr.abc123@inbound.keybuzz.io",
  "country": "FR",
  "status": "PENDING"
}
```

### POST /api/v1/marketplaces/amazon/inbound-address/send-validation

**Nouveau** - Envoie un email de validation vers l'adresse inbound.

Headers :
- `X-User-Email`
- `X-Tenant-Id`

Body :
```json
{ "country": "FR" }
```

Réponse :
```json
{
  "ok": true,
  "message": "Validation email sent",
  "note": "The validation becomes effective upon receiving a message."
}
```

---

## 2. Routes Client (Next.js API)

| Route | Backend |
|-------|---------|
| `GET /api/amazon/inbound-address` | → `GET /api/v1/marketplaces/amazon/inbound-address` |
| `POST /api/amazon/inbound-address/send-validation` | → `POST /api/v1/marketplaces/amazon/inbound-address/send-validation` |

---

## 3. UI Wizard "Messages Amazon"

Améliorations :
- Affichage de l'adresse réelle (pas "en cours de génération")
- Badge statut : "En attente" (jaune) ou "Validé" (vert)
- Bouton "Envoyer email de validation" si statut PENDING
- Message de confirmation après envoi

---

## 4. UI Page /channels

Améliorations :
- Section inbound avec adresse + badge statut
- Bouton "Envoyer email de validation" si PENDING
- Bouton copier simplifié
- Instructions Seller Central

---

## 5. Fix Double-Escaping

Caractères corrigés :
- `Copi\u00e9` → `Copié`
- `\u2192` → `→`
- `connect\u00e9` → `connecté`
- `D\u00e9connecter` → `Déconnecter`

---

## 6. Versions Déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| keybuzz-backend | **v1.0.3-dev** | `5c2b9f26ebfb...` |
| keybuzz-client | **v0.2.44-dev** | `87dac62c3610...` |

---

## 7. Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-backend | `1c2e53f` | feat: add send-validation endpoint for Amazon inbound |
| keybuzz-client | `0660205` | feat: inbound validation UX + status badge + fix escaping |

---

## 8. Tests E2E

### Test inbound-address (tenant non connecté)
```json
{"error":"Amazon not connected","message":"Connect Amazon first to get inbound address"}
```
✅ Comportement attendu

### Test send-validation endpoint
```
POST /api/v1/marketplaces/amazon/inbound-address/send-validation
→ {"error":"Unauthorized"} (sans JWT/headers valides)
```
✅ Endpoint existe et répond

### Test version client
```
curl https://client-dev.keybuzz.io/debug/version
→ {"version":"0.2.44"}
```
✅ Version correcte

---

## 9. Fichiers Modifiés

### Backend
- `src/modules/marketplaces/amazon/amazon.routes.ts` : ajout endpoint send-validation

### Client
- `app/api/amazon/inbound-address/send-validation/route.ts` : nouveau proxy
- `src/features/onboarding/components/OnboardingWizard.tsx` : StepAmazonMessages avec validation
- `app/channels/page.tsx` : section inbound avec validation + fix escaping

---

**Fin du rapport PH15-AMAZON-INBOUND-VALIDATION-UX-01**
