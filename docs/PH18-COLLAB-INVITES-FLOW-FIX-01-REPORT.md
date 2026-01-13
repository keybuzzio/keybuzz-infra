# PH18-COLLAB-INVITES-FLOW-FIX-01 — Consommation correcte des invitations après auth

**Date**: 2026-01-13  
**Statut**: ✅ COMPLÉTÉ

---

## 🎯 Objectif

Corriger le flow d'invitation pour qu'une invitation soit TOUJOURS consommée après authentification, quel que soit le mode de login (Email OTP ou Google OAuth).

---

## 📋 Problème Identifié

Le flow d'invitation était **cassé** : les utilisateurs invités pouvaient se connecter, mais n'étaient jamais rattachés au tenant invité. La page `/invite/[token]` existait sous forme de fichier temporaire mais n'était pas intégrée dans la structure Next.js de l'application déployée.

---

## ✅ Solution Implémentée

### Architecture du Flow Corrigé

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           FLOW D'INVITATION                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. Utilisateur clique sur le lien d'invitation                          │
│     https://client-dev.keybuzz.io/invite/{token}                         │
│                                │                                         │
│                                ▼                                         │
│  ┌─────────────────────────────────────────────────────────┐            │
│  │ /invite/[token]/page.tsx                                 │            │
│  │ - Stocke le token dans un cookie `kb_invite_token`       │            │
│  │ - Vérifie l'état de la session                           │            │
│  └─────────────────────────────────────────────────────────┘            │
│                                │                                         │
│                ┌───────────────┼───────────────┐                        │
│                │               │               │                        │
│         Non authentifié   Authentifié   Session loading                 │
│                │               │               │                        │
│                ▼               ▼               ▼                        │
│       /auth/signin?    /invite/continue    Attente                      │
│       callbackUrl=                                                      │
│       /invite/continue                                                  │
│                │               │                                         │
│                └───────────────┤                                         │
│                                ▼                                         │
│  ┌─────────────────────────────────────────────────────────┐            │
│  │ /invite/continue/page.tsx                                │            │
│  │ - Lit le cookie `kb_invite_token`                        │            │
│  │ - Appelle POST /api/space-invites/accept                 │            │
│  │ - Supprime le cookie                                     │            │
│  │ - Définit le tenant courant                              │            │
│  │ - Redirige vers /dashboard                               │            │
│  └─────────────────────────────────────────────────────────┘            │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### Fichiers Créés/Modifiés

| Fichier | Description |
|---------|-------------|
| `app/invite/[token]/page.tsx` | Page d'entrée qui stocke le token en cookie et redirige |
| `app/invite/continue/page.tsx` | Page post-auth qui consomme l'invitation |
| `app/api/space-invites/accept/route.ts` | Proxy API vers le backend |
| `middleware.ts` | Ajout de `/invite` aux routes publiques |

### Stockage du Token

Le token d'invitation est stocké dans un **cookie navigateur** :
- Nom: `kb_invite_token`
- Durée: 1 jour
- Path: `/`
- SameSite: `Lax`
- Secure: `true` (en HTTPS)

Ce stockage permet au token de **survivre aux redirections OAuth** (Google, Microsoft).

---

## 🧪 Tests E2E

### Test 1: Utilisateur déjà authentifié

| Étape | Résultat |
|-------|----------|
| Accès à `/invite/test-token-xyz` | ✅ Token stocké en cookie |
| Redirection vers `/invite/continue` | ✅ Automatique |
| Appel API | ✅ Effectué |
| Message erreur (token invalide) | ✅ "Cette invitation a expiré" |

### Test 2: Flow complet avec token valide

| Étape | Résultat |
|-------|----------|
| Création invitation via API | ✅ `POST /space-invites/ecomlg-002/invite` |
| Email envoyé | ✅ Postfix `status=sent` |
| Token hash stocké en DB | ✅ SHA256 |

### Test 3: Gestion des erreurs

| Cas | Message affiché |
|-----|-----------------|
| Token invalide | "Cette invitation a expiré. Demandez une nouvelle invitation." |
| Token expiré | "Cette invitation a expiré. Demandez une nouvelle invitation." |
| Utilisateur déjà membre | Redirection vers `/dashboard` |
| Pas de token en cookie | "Aucune invitation en attente" |

---

## 🔒 Sécurité

- **Token hash**: Seul le hash SHA256 est stocké en DB (le token clair n'est jamais persisté)
- **Cookie sécurisé**: Attributs `Secure` et `SameSite=Lax`
- **Validation serveur**: Le token est validé côté API avant toute action
- **Expiration**: 7 jours par défaut

---

## 📦 Déploiement

| Service | Version | Image |
|---------|---------|-------|
| keybuzz-client | 0.2.82 | `ghcr.io/keybuzzio/keybuzz-client:0.2.82-dev` |

### Commits

```
keybuzz-client:
- 7c9bd56 fix: escape apostrophe
- 2b87954 chore: bump version to 0.2.82
- ff8634a feat(invite): fix invitation flow with cookie storage post-auth - PH18
```

---

## 🔄 Compatibilité Auth

Le flow est compatible avec:
- ✅ **Google OAuth**: Le cookie survit au redirect vers Google et retour
- ✅ **Microsoft OAuth**: Même comportement
- ✅ **Email OTP**: Le cookie survit à la redirection post-OTP

---

## ⚠️ Limitations Connues

1. **Token non récupérable**: Le token original n'est pas loggé en production (sécurité). En DEV, seuls les 8 premiers caractères sont loggés.
2. **Cookie client-side**: Le cookie `kb_invite_token` est accessible par JavaScript. Pour une sécurité maximale, un cookie HTTP-only géré côté serveur serait préférable.

---

## 📝 Notes

- L'API backend `/space-invites/accept` était déjà fonctionnelle
- Seul le client Next.js devait être corrigé pour le flow post-auth
- Les invitations existantes restent valides
