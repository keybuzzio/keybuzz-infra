# PH15-AMAZON-DISCONNECT-UX-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Ajout de l'UX complète pour la gestion de connexion Amazon dans le wizard :
- Boutons Connecter / Reconnecter / Déconnecter
- Modal de confirmation avant déconnexion
- Affichage conditionnel de l'adresse inbound selon le statut

---

## 1. Fonctionnalités Implémentées

### Wizard - Étape "Vos canaux" (StepChannels)

| État | Affichage |
|------|-----------|
| **DISCONNECTED** | Bouton "Connecter Amazon" |
| **CONNECTED** | Badge "Connecté" + boutons "Reconnecter" et "Déconnecter" |
| **Loading** | "Chargement..." |

### Modal de Confirmation

Avant la déconnexion, une modal s'affiche :
- Titre : "Déconnecter Amazon ?"
- Message explicatif
- Boutons "Annuler" / "Déconnecter"

### Wizard - Étape "Messages Amazon" (StepAmazonMessages)

| État | Affichage |
|------|-----------|
| **DISCONNECTED** | Message "Connectez Amazon pour générer votre adresse email KeyBuzz" |
| **CONNECTED** | Adresse inbound réelle (sans "pending") + bouton Copier |
| **CONNECTED + pending** | Message "Adresse en cours de génération..." |

---

## 2. Fichiers Modifiés

```
keybuzz-client/
├── src/features/onboarding/components/OnboardingWizard.tsx
│   ├── StepChannels: +showDisconnectConfirm state
│   ├── StepChannels: +modal confirmation
│   ├── StepChannels: +boutons Reconnecter/Déconnecter
│   └── StepAmazonMessages: affichage conditionnel adresse
└── package.json: 0.2.38 → 0.2.39
```

---

## 3. Endpoints Utilisés

| Endpoint | Méthode | Usage |
|----------|---------|-------|
| `/api/amazon/status` | GET | Récupérer status réel depuis DB |
| `/api/amazon/disconnect` | POST | Déconnecter le compte Amazon |
| `/api/amazon/oauth/start` | GET | Lancer le flow OAuth |
| `/api/amazon/inbound-address` | GET | Récupérer l'adresse email inbound |

---

## 4. Preuves de Fonctionnement

### Status Backend
```bash
curl -H 'X-User-Email: demo@keybuzz.io' -H 'X-Tenant-Id: kbz-001' \
  https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/status
# {"connected":false,"status":"DISCONNECTED",...}
```

### Version Client
```bash
curl https://client-dev.keybuzz.io/debug/version
# {"app":"app","version":"0.2.39","buildDate":"2026-01-08T07:47:47Z"}
```

---

## 5. UX Flow

```
┌─────────────────────────────────────────────────────────────┐
│  État DISCONNECTED                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☑ Amazon                    [Connecter Amazon]      │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Click "Connecter"
                         ▼
                   Amazon OAuth
                         │
                         │ Callback success
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  État CONNECTED                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☑ Amazon  ✓ Connecté   [Reconnecter] [Déconnecter] │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Click "Déconnecter"
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Modal Confirmation                                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Déconnecter Amazon ?                               │   │
│  │  Vous devrez reconnecter votre compte...            │   │
│  │       [Annuler]     [Déconnecter]                   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-client | `a4d62b1` | feat(PH15): Amazon disconnect UX - connect/reconnect/disconnect buttons |
| keybuzz-infra | `acfe1e6` | feat(PH15): update client to v0.2.39-dev with Amazon disconnect UX |

---

## 7. Limitations

- **Page Canaux (Settings)** : Pas de modal "Configurer Amazon" existante. La gestion Amazon est concentrée dans le wizard.
- **Adresse Inbound** : Dépend de l'endpoint `/api/amazon/inbound-address` qui peut retourner "pending" si l'adresse n'a pas encore été générée.

---

## 8. Version Déployée

```
ghcr.io/keybuzzio/keybuzz-client:v0.2.39-dev
digest: sha256:a539bf1b31aab4a31251fa039d453403da2ec45d2929874bf5f904095291e19e
```

---

**Fin du rapport PH15-AMAZON-DISCONNECT-UX-01**
