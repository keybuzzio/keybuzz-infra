# PH15-ONBOARDING-WIZARD-AMAZON-01 — Intégration Amazon dans le Wizard Onboarding

**Date**: 2026-01-07  
**Environnement**: DEV (`keybuzz-client-dev`)  
**Version**: `v0.2.34-dev`  
**Status**: ✅ **IMPLÉMENTÉ**

---

## 📋 Résumé

| Élément | Status |
|---------|--------|
| Génération adresse inbound retrouvée | ✅ |
| Étape "Vos canaux" + Connect Amazon | ✅ |
| Nouvelle étape "Messages Amazon" | ✅ |
| Wizard reprenable | ✅ |
| Déploiement DEV | ✅ v0.2.34-dev |

---

## 1. Génération Adresse Inbound — Source Retrouvée

### Fichiers source

| Fichier | Description |
|---------|-------------|
| `keybuzz-admin/src/features/inbound-email/utils/emailAddress.ts` | Utilitaires frontend |
| `keybuzz-backend/src/modules/inboundEmail/inboundEmailAddress.service.ts` | Service backend |

### Format canonique

```
<marketplace>.<tenantId>.<country>.<token>@inbound.keybuzz.io
```

### Exemples

```
amazon.kbz-001.fr.x7p4@inbound.keybuzz.io
amazon.kbz-002.de.p9k2@inbound.keybuzz.io
```

### Fonction utilisée

```typescript
// keybuzz-admin/src/features/inbound-email/utils/emailAddress.ts
export function buildInboundEmailAddress(
  marketplace: string,
  tenantId: string,
  country: string,
  token: string
): string {
  return `${marketplace.toLowerCase()}.${tenantId}.${country.toLowerCase()}.${token}@inbound.keybuzz.io`;
}
```

---

## 2. Modifications du Wizard

### 2.1 Types (`types.ts`)

Ajout de l'interface `OnboardingAmazon` :

```typescript
export interface OnboardingAmazon {
  connected: boolean;
  connectedAt: string | null;
  sellerId: string | null;
  marketplace: string | null;
  inboundEmailConfigured: boolean;
}
```

### 2.2 Étapes du wizard

| # | Titre | Description | Condition |
|---|-------|-------------|-----------|
| 1 | Bienvenue | Découvrez KeyBuzz | - |
| 2 | Votre entreprise | Informations de base | - |
| 3 | Vos canaux | Marketplaces et contacts | - |
| **4** | **Messages Amazon** | **Configuration email inbound** | **Si Amazon coché** |
| 5 | Fournisseurs | Dropshipping (optionnel) | - |
| 6 | Base IA KeyBuzz | Vos connaissances | - |
| 7 | Terminé | Prêt à démarrer | - |

### 2.3 Étape "Vos canaux" (Step 3)

- Affichage du statut Amazon (Connecté / Non connecté)
- Bouton "Connecter Amazon" → OAuth SP-API
- Warning si Amazon coché mais non connecté

### 2.4 Étape "Messages Amazon" (Step 4)

- Affichage de l'adresse inbound générée
- Bouton "Copier" l'adresse
- Mini-tuto Seller Central en 4 étapes :
  1. Connectez-vous à Seller Central
  2. Allez dans Settings → Notification Preferences
  3. Section Buyer Messages, cliquez sur Edit
  4. Ajoutez l'adresse email et cliquez Save
- Bouton "J'ai terminé" pour valider

---

## 3. Persistance de l'état

Le wizard est **reprenable** grâce à :

- Stockage dans `localStorage` (`kb_client_onboarding:v1`)
- État sauvegardé à chaque changement d'étape
- Récupération du callback OAuth Amazon (`amazon_connected=true`)

### Structure de l'état

```typescript
interface OnboardingState {
  completed: boolean;
  currentStep: number;
  completedSteps: number[];
  data: OnboardingData;
  startedAt: string | null;
  completedAt: string | null;
}
```

---

## 4. Flow OAuth Amazon

```
1. Utilisateur coche "Amazon" dans "Vos canaux"
2. Clic sur "Connecter Amazon"
3. Redirect vers /api/amazon/oauth/start?return_url=...
4. OAuth Amazon Seller Central
5. Callback avec ?amazon_connected=true&seller_id=...
6. Wizard met à jour l'état amazonState.connected = true
```

---

## 5. Captures d'écran (Description)

### Étape 3 — Vos canaux

```
┌─────────────────────────────────────┐
│ ☐ Amazon           [Connecter Amazon] │
│ ☐ Fnac                               │
│ ☑ Email direct                       │
│                                       │
│ ⚠️ Connectez votre compte Amazon...   │
│                                       │
│ [Retour]           [Continuer]        │
└─────────────────────────────────────┘
```

### Étape 4 — Messages Amazon

```
┌─────────────────────────────────────┐
│ 📧 Messages Amazon                   │
│ Configuration des notifications      │
│                                       │
│ ✓ Amazon connecté                    │
│                                       │
│ Votre adresse email KeyBuzz:         │
│ ┌─────────────────────────────┬───┐ │
│ │ amazon.kbz-001.fr.auto@...  │ 📋│ │
│ └─────────────────────────────┴───┘ │
│                                       │
│ Comment configurer Seller Central:   │
│ 1. Connectez-vous...                 │
│ 2. Allez dans Settings...            │
│ 3. Section Buyer Messages...         │
│ 4. Ajoutez l'adresse...              │
│                                       │
│ [Retour]           [J'ai terminé]     │
└─────────────────────────────────────┘
```

---

## 6. Fichiers Modifiés

| Fichier | Modification |
|---------|--------------|
| `src/features/onboarding/types.ts` | Ajout OnboardingAmazon, nouvelle étape |
| `src/features/onboarding/components/OnboardingWizard.tsx` | Intégration Amazon complète |

---

## 7. Commits

| Repository | Commit | Message |
|------------|--------|---------|
| keybuzz-client | `7835ac6` | `feat(PH15): onboarding wizard Amazon integration v0.2.34-dev` |

---

## 8. Tests

| Test | Résultat |
|------|----------|
| Wizard démarre | ✅ |
| Cocher Amazon affiche le bouton Connect | ✅ |
| Étape "Messages Amazon" affiche l'adresse | ✅ |
| Copier l'adresse fonctionne | ✅ |
| Refresh conserve l'état | ✅ |
| Skip étape si Amazon non coché | ✅ |

---

## 9. Limitations

| Limitation | Note |
|------------|------|
| Token "auto" | Le vrai token est généré côté backend, le wizard affiche un placeholder |
| OAuth Amazon | Nécessite que l'endpoint `/api/amazon/oauth/start` soit configuré |
| Validation email | Pas de vérification E2E que l'email a bien été configuré dans Seller Central |

---

## 10. Prochaines étapes

1. **Endpoint health inbound** : Vérifier qu'un email test a été reçu
2. **Token réel** : Appeler le backend pour générer le vrai token
3. **Multi-marketplace** : Supporter plusieurs pays (FR, DE, ES, IT, UK)

---

**Implémentation terminée** ✅  
**Version déployée** : `v0.2.34-dev`  
**URL** : https://platform-dev.keybuzz.io/onboarding
