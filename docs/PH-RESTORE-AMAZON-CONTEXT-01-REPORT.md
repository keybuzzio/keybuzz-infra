# PH-RESTORE-AMAZON-CONTEXT-01 — Rapport de contexte Amazon + Inbound Email

**Date** : 7 janvier 2026  
**Objectif** : Retrouver le flow Amazon + inbound email existant sans modification

---

## 📧 FORMAT EMAIL INBOUND RÉEL

### Format canonique
```
<marketplace>.<tenantId>.<country>.<token>@inbound.keybuzz.io
```

### Exemples réels (depuis la DB/docs)
- `amazon.tenant_test_dev.de.97lo14@inbound.keybuzz.io`
- `amazon.tenant_test_dev.uk.2hpmad@inbound.keybuzz.io`
- `amazon.tenant_test_dev.fr.6v8gqm@inbound.keybuzz.io`

### Domaine
- **Domain** : `inbound.keybuzz.io`
- **Token** : 6 caractères alphanumériques générés côté backend

### Code de génération (keybuzz-backend)
**Fichier** : `src/modules/inboundEmail/inboundEmailAddress.service.ts`

```typescript
export function buildInboundAddress(params: {
  marketplace: string;
  tenantId: string;
  country: string;
  token: string;
}): string {
  const { marketplace, tenantId, country, token } = params;
  return `${marketplace.toLowerCase()}.${tenantId}.${country.toLowerCase()}.${token}@inbound.keybuzz.io`;
}

export function generateToken(length: number = 6): string {
  const charset = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let token = '';
  for (let i = 0; i < length; i++) {
    token += charset.charAt(Math.floor(Math.random() * charset.length));
  }
  return token;
}
```

---

## 🔐 FLOW AMAZON SP-API OAuth

### Diagramme texte

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AMAZON SP-API OAUTH FLOW                     │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐     POST /oauth/start        ┌────────────────────┐
│   Admin UI   │ ─────────────────────────────▶│  keybuzz-backend   │
│ (keybuzz-    │                               │                    │
│  admin)      │                               │ 1. Create OAuthState│
│              │                               │    (state, tenantId,│
│              │                               │     connectionId)   │
│              │◀───────────── authUrl ────────│                    │
└──────────────┘                               │ 2. Generate authUrl │
       │                                       │    with app_id      │
       │ redirect                              └────────────────────┘
       ▼
┌──────────────────────────┐
│   Amazon Seller Central  │
│   (LWA Consent Page)     │
│                          │
│   User authorizes app    │
└──────────────────────────┘
       │
       │ redirect with code, state, selling_partner_id
       ▼
┌────────────────────────────────────────────────────────────────────┐
│  GET /api/v1/marketplaces/amazon/oauth/callback                     │
│                                                                      │
│  1. Validate state (anti-CSRF)                                       │
│  2. Exchange code for tokens (refresh_token, access_token)           │
│  3. Store refresh_token in Vault: secret/keybuzz/tenants/{tenantId}/amazon_spapi │
│  4. Update MarketplaceConnection in DB (status=CONNECTED)            │
│  5. Mark OAuthState as used                                          │
│  6. Redirect to Admin UI with success                                │
└────────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────┐
│   Admin UI               │
│   /inbound-email/{id}    │
│   → Amazon Connected ✓   │
└──────────────────────────┘
```

### Endpoints Backend

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/v1/marketplaces/amazon/oauth/start` | Initier OAuth, retourne authUrl |
| GET | `/api/v1/marketplaces/amazon/oauth/callback` | Callback Amazon (public, pas de JWT) |
| GET | `/api/v1/marketplaces/amazon/status` | Statut connexion tenant |
| POST | `/api/v1/marketplaces/amazon/mock/connect` | Dev only - simuler connexion |

### Endpoints Inbound Email

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/v1/inbound-email/connections` | Liste connexions tenant |
| GET | `/api/v1/inbound-email/connections/:id` | Détail connexion |
| POST | `/api/v1/inbound-email/connections` | Créer connexion (+ adresses) |
| POST | `/api/v1/inbound-email/connections/:id/validate` | Valider adresse |
| POST | `/api/v1/inbound-email/addresses/:id/regenerate` | Régénérer token |
| GET | `/api/v1/inbound-email/health` | Health global |
| GET | `/api/v1/inbound-email/health/:connectionId` | Health connexion |
| POST | `/api/v1/inbound-email/dev/seed` | Dev only - seed données |

---

## 🖥️ ÉCRANS ADMIN EXISTANTS

### Fichiers Admin (keybuzz-admin)

```
app/inbound-email/
├── page.tsx                    # Overview des connexions
├── layout.tsx                  # Layout inbound-email
├── amazon/                     # Callback OAuth
│   └── callback/
└── [connectionId]/
    └── page.tsx                # Détail connexion

src/features/inbound-email/
├── types.ts                    # Types TypeScript
├── mocks.ts                    # Données mockées
├── index.ts                    # Exports
├── utils/
│   └── emailAddress.ts         # Utilitaires email
└── components/
    ├── OverviewCards.tsx        # Cards métriques
    ├── ConnectionsTable.tsx     # Table connexions
    ├── ConnectionHeader.tsx     # Header détail
    ├── InboundAddressesList.tsx # Liste adresses + actions
    ├── HealthIndicators.tsx     # Indicateurs santé
    ├── RecentMessages.tsx       # Timeline messages
    ├── ValidationSteps.tsx      # Étapes validation
    └── AmazonConnectionCard.tsx # Card OAuth + Polling
```

### URL Admin DEV

- **Overview** : `https://admin-dev.keybuzz.io/inbound-email`
- **Détail connexion** : `https://admin-dev.keybuzz.io/inbound-email/cmj9z9qwu0003p0ekp7a2wl8p`

### Composant AmazonConnectionCard

**Fichier** : `src/features/inbound-email/components/AmazonConnectionCard.tsx`

Affiche :
- Statut OAuth (Connected / Not Connected)
- Bouton "Connect Amazon" / "Reconnect Amazon"
- Statut Polling (OK / WARNING / ERROR)
- Dernière exécution polling
- Jobs dernières 24h

### Composant InboundAddressesList

**Fichier** : `src/features/inbound-email/components/InboundAddressesList.tsx`

Affiche par pays :
- Adresse email complète + bouton Copy
- Pipeline status (Validated/Pending)
- Amazon Forward status
- Configured status
- Dernière réception
- Actions (I added email, Test guide)

---

## 🔒 VAULT — STRUCTURE SECRETS

### Paths Vault confirmés

```
secret/keybuzz/
├── amazon_spapi/
│   └── app                      # Credentials app Amazon (client_id, client_secret, application_id)
├── tenants/
│   ├── tenant_test_dev/
│   │   └── amazon_spapi         # refresh_token, seller_id, marketplace_id, region
│   └── kbz_test/
│       └── amazon_spapi
├── smtp/                        # Credentials SMTP
├── ses/                         # Credentials AWS SES
└── auth/                        # NextAuth secrets
```

### Structure secret/keybuzz/amazon_spapi/app
- `application_id`
- `client_id`
- `client_secret`
- `login_uri`
- `redirect_uri`
- `region`

### Structure secret/keybuzz/tenants/{tenantId}/amazon_spapi
- `refresh_token`
- `seller_id`
- `marketplace_id`
- `region`
- `created_at`

---

## ⚠️ CE QUI EST PRÉSENT vs CE QUI A DISPARU

### ✅ PRÉSENT ET FONCTIONNEL

| Élément | Localisation | Statut |
|---------|--------------|--------|
| Code OAuth backend | `amazon.oauth.ts`, `amazon.routes.ts` | ✅ Complet |
| Code génération adresse | `inboundEmailAddress.service.ts` | ✅ Complet |
| Admin UI composants | `src/features/inbound-email/` | ✅ Complet |
| Vault credentials app | `secret/keybuzz/amazon_spapi/app` | ✅ Présent |
| Vault tenant credentials | `secret/keybuzz/tenants/*/amazon_spapi` | ✅ Présent |
| Types Prisma | `schema.prisma` | ✅ Définis |

### ❌ PROBLÈME : TABLES DB MANQUANTES

Les tables suivantes sont **définies dans Prisma** mais **n'existent PAS** dans la DB de production :

| Table Prisma | Map DB | Statut DB |
|--------------|--------|-----------|
| `InboundConnection` | `inbound_connections` | ❌ N'existe pas |
| `InboundAddress` | `inbound_addresses` | ❌ N'existe pas |
| `MarketplaceConnection` | `marketplace_connections` | ❌ N'existe pas |
| `OAuthState` | `oauth_states` | ❌ N'existe pas |

**Cause probable** : Les migrations Prisma n'ont jamais été appliquées sur la DB de production.

### 🔧 MIGRATIONS NON APPLIQUÉES

Migrations présentes dans `prisma/migrations/` :
- `20251218162802_add_pipeline_marketplace_status`
- `20251220235148_add_oauth_state_table`

Ces migrations **modifient** des tables mais ne les **créent** pas.

**⚠️ La migration de création initiale des tables est ABSENTE du dossier migrations.**

---

## 📊 ÉTAT CONNEXIONS ADMIN (DONNÉES MOCK)

Les données affichées dans l'admin sont des **mocks** car les tables DB n'existent pas :

| Tenant | Marketplace | Countries | Status |
|--------|-------------|-----------|--------|
| tenant_test_dev | AMAZON | DE, UK, FR | DRAFT |

### Adresses mock affichées
| Country | Email | Pipeline | Amazon Forward |
|---------|-------|----------|----------------|
| DE | `amazon.tenant_test_dev.de.97lo14@inbound.keybuzz.io` | Validated | Validated |
| UK | `amazon.tenant_test_dev.uk.2hpmad@inbound.keybuzz.io` | Validated | Pending |
| FR | `amazon.tenant_test_dev.fr.6v8gqm@inbound.keybuzz.io` | Validated | Validated |

---

## 📋 CHECKLIST ACTIONS REQUISES

Pour restaurer le flow Amazon complet :

1. **[ ] Créer migration pour tables manquantes**
   - `inbound_connections`
   - `inbound_addresses`
   - `marketplace_connections`
   - `oauth_states`

2. **[ ] Appliquer migrations sur DB**
   ```bash
   npx prisma migrate deploy
   ```

3. **[ ] Vérifier callback URL Amazon**
   - Configurée dans Amazon Developer Console
   - Doit pointer vers `/api/v1/marketplaces/amazon/oauth/callback`

4. **[ ] Tester flow OAuth complet**
   - Admin → Connect Amazon → Seller Central → Callback → DB updated

5. **[ ] Seed données initiales**
   - Créer tenant_test_dev dans DB si absent
   - Créer InboundConnection + InboundAddress

---

## 🔗 RÉFÉRENCES DOCUMENTATION

| Fichier | Contenu |
|---------|---------|
| `22-AMAZON-SP-API-AWS-SES.md` | Config Amazon SP-API + SES |
| `KeyBuzz v3-2.txt` | Historique développement inbound email |
| `Résumé KeyBuzz v3-2.txt` | Résumé phases PH10/PH11 |

---

## 📝 CONCLUSION

Le code Amazon + Inbound Email est **complet et présent** dans les repos :
- **Backend** : OAuth, génération adresse, routes API
- **Admin** : Composants UI, gestion connexions

**Problème bloquant** : Les tables PostgreSQL n'ont jamais été créées.

**Solution** : Appliquer `prisma migrate deploy` ou créer manuellement les tables manquantes.
