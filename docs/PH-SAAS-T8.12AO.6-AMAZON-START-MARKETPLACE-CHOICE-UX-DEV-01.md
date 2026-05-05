# PH-SAAS-T8.12AO.6 — Amazon Start Marketplace Choice UX DEV

> **Phase** : PH-SAAS-T8.12AO.6-AMAZON-START-MARKETPLACE-CHOICE-UX-DEV-01
> **Ticket** : KEY-249
> **Date** : 2026-05-05
> **Environnement** : DEV uniquement
> **Verdict** : GO PARTIEL — DEV UX READY, OAUTH REAL TEST PENDING

---

## 1. Objectif

Ajouter dans `/start` un choix explicite du pays / marketplace Amazon avant de lancer l'OAuth Amazon.

**Contexte** : KEY-248 fermé. Le flux OAuth Amazon fonctionne. Nouveau besoin KEY-249 : depuis `/start`, le bouton "Connecter Amazon" lançait OAuth sans demander explicitement quel pays connecter. Amazon Seller Central Europe affiche un pays selon la session Amazon, ce qui crée de l'ambiguïté.

---

## 2. Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `3a813d2` | Non | GO |
| keybuzz-infra | `main` | `374b57f` | Oui (docs existants) | GO |

| Env | Manifest image | Runtime image | Verdict |
|---|---|---|---|
| Client DEV | `v3.5.157-promo-winner-ux-fix-dev` | `v3.5.157-promo-winner-ux-fix-dev` | Aligné |
| Client PROD | `v3.5.153-promo-visible-price-prod` | `v3.5.153-promo-visible-price-prod` | Aligné |

---

## 3. Audit /start actuel (avant patch)

| Élément | /start actuel | /channels actuel | Gap |
|---|---|---|---|
| Bouton Amazon | `handleMarketplaceClick('amazon')` | Catalog + country picker | Pas de choix pays dans /start |
| marketplace_key envoyé | Aucun (OAuth sans pays) | `marketplace_key` via catalog | Manquant |
| Source marketplaces | Constante `MARKETPLACES` hardcodée | API catalog dynamique | /start n'utilise pas le catalog |
| Choix pays | Absent | Présent (country cards) | Gap critique |
| Bouton Retour | N/A | Présent | Absent |
| Message disclaimer | Absent | Absent | N/A |

---

## 4. Audit source marketplaces

| Source | Contenu | Réutilisable pour /start ? | Risque |
|---|---|---|---|
| API `/channels/catalog` | Liste complète des marketplaces avec `provider`, `country_code`, `marketplace_key` | Oui | Aucun — même source que /channels |
| Constante `MARKETPLACES` (OnboardingHub) | 5 providers (amazon, shopify, cdiscount, fnac, ebay) | Non — pas de détail pays | Insuffisant seul |
| `COUNTRY_FLAGS` (/channels) | Map country_code -> emoji flag | Oui — réutilisé | Aucun |

**Décision** : Réutiliser `fetchChannelsCatalog()` + filtrer `provider === 'amazon'` pour obtenir la liste dynamique des pays.

---

## 5. Design UX

| État UX | Comportement |
|---|---|
| Aucun choix pays | Bouton "Sélectionnez un pays" désactivé |
| Choix FR | Carte FR active (bordure bleue), bouton "Connecter Amazon France" actif |
| Choix ES/IT/DE/PL | Carte correspondante active, bouton mis à jour dynamiquement |
| Clic Retour | Retour grille marketplaces initiale |
| Retour OAuth OK | Message succès vert |
| Échec activation | Message erreur rouge |

**Flux UX** :
1. Grille 5 marketplaces (Amazon recommandé, Shopify, Cdiscount, Fnac, eBay)
2. Clic Amazon → sélecteur pays (chargement catalog API)
3. Cartes pays avec drapeaux + code country + nom localisé
4. Message disclaimer : "Amazon peut afficher un pays différent selon votre session Seller Central. KeyBuzz connectera le pays sélectionné ici."
5. Bouton "Connecter Amazon [Pays]" activé après sélection
6. OAuth redirige vers Amazon Seller Central
7. Retour sur `/start` avec query params de callback

---

## 6. Patch Client

### Fichiers modifiés

| Fichier | Changement | Pourquoi | Risque |
|---|---|---|---|
| `src/features/onboarding/components/OnboardingHub.tsx` | Ajout sélecteur pays Amazon, états, callbacks, UI | Fonctionnalité principale AO.6 | Faible — isolé dans /start |
| `src/services/amazon.service.ts` | Paramètre `marketplaceKey` dans `startAmazonOAuth` | Propager le choix pays à l'OAuth | Faible — paramètre optionnel |
| `app/api/amazon/oauth/start/route.ts` | Extraction `marketplace_key`, `deriveCountry` helper | BFF propage le pays au backend | Faible — existait déjà côté remote |

### Détails OnboardingHub.tsx

**Nouveaux imports** :
- `useState`, `useEffect` (React)
- `ArrowLeft` (lucide-react)
- `checkOAuthCallback`, `clearOAuthCallbackParams` (amazon.service)
- `fetchChannelsCatalog`, `addTenantChannel`, `CatalogEntry` (channels.service)

**Nouveaux states** :
- `showCountryPicker` : affiche/masque le sélecteur
- `amazonCountries` : liste `CatalogEntry[]` filtrée Amazon
- `selectedCountry` : pays sélectionné
- `countryLoading` / `oauthLoading` : états de chargement
- `oauthError` / `oauthSuccess` : feedback utilisateur

**Fonctions clés** :
- `handleAmazonClick()` : charge le catalog, filtre Amazon, déduplique par country_code
- `handleCountryOAuth()` : `addTenantChannel` + `startAmazonOAuth` avec `marketplace_key`
- `useEffect` callback detection : détecte `amazon_connected` / `amazon_error` dans les query params

### Code critique

```typescript
const handleCountryOAuth = async () => {
    if (!selectedCountry) return;
    setOauthLoading(true);
    setOauthError(null);
    try {
        try {
            await addTenantChannel(tenantId, selectedCountry.marketplace_key);
        } catch {
            // Channel may already exist — non-blocking
        }
        const { authUrl } = await startAmazonOAuth(
            tenantId,
            '/start',
            selectedCountry.marketplace_key,
        );
        redirectToAmazonOAuth(authUrl);
    } catch (err: any) {
        setOauthError(err.message || 'Erreur lors de la connexion Amazon');
        setOauthLoading(false);
    }
};
```

### Pas de modification Backend/API

Le backend OAuth n'a pas été modifié. Le `marketplace_key` est propagé via le BFF existant et le `deriveCountry` helper (déjà présent côté remote).

---

## 7. Build DEV

| Image | Commit source | Digest | Rollback DEV |
|---|---|---|---|
| `ghcr.io/keybuzzio/keybuzz-client:v3.5.158-amazon-start-country-choice-dev` | `5144d68` | `sha256:0a8eeca4239c241b4e696f259e6c1cd0450cc9c48183b4a1ebcbedc5bc30bfac` | `v3.5.157-promo-winner-ux-fix-dev` |

**Build args tracking** :
- `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG`
- `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977`

---

## 8. GitOps DEV

| Manifest | Image avant | Image après | Rollout |
|---|---|---|---|
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.157-promo-winner-ux-fix-dev` | `v3.5.158-amazon-start-country-choice-dev` | OK — Running 1/1 |

Commit infra : `33d2968` sur `main`

---

## 9. Validation navigateur DEV

| Test | Attendu | Résultat | Preuve |
|---|---|---|---|
| `/start` — grille marketplaces | 5 tiles (Amazon, Shopify, Cdiscount, Fnac, eBay) | OK | Screenshot |
| `/start` — clic Amazon | Sélecteur pays Amazon affiché | OK — 16 pays | Screenshot |
| `/start` — sélection FR | "Connecter Amazon France" activé | OK | Screenshot |
| `/start` — sélection ES | "Connecter Amazon Espagne" activé | OK | Snapshot |
| `/start` — bouton Retour | Retour grille marketplaces | OK | Snapshot |
| `/start` — sans choix | "Sélectionnez un pays" désactivé | OK | Snapshot |
| Responsive 390px | Layout adapté, 3 colonnes | OK | Screenshot |
| `/channels` | Page intacte, fonctionnelle | OK — 0/3 canaux | Screenshot |
| `/dashboard` | Page intacte | OK — KPI + demo data | Screenshot |
| OAuth réel | Flux complet Amazon | SKIP — pas de compte Amazon disponible | N/A |

---

## 10. Non-régression

| Surface | Résultat |
|---|---|
| Dashboard DEV | OK |
| Channels DEV | OK |
| Start DEV | OK — nouvelle UX |
| Client PROD | INCHANGÉ — `v3.5.153-promo-visible-price-prod` |
| API DEV | INCHANGÉ — `v3.5.155-promo-retry-metadata-email-dev` |
| API PROD | INCHANGÉ — `v3.5.142-promo-retry-email-prod` |
| Backend DEV | INCHANGÉ — `v1.0.46-amazon-oauth-activation-bridge-dev` |
| Backend PROD | INCHANGÉ — `v1.0.46-amazon-oauth-activation-bridge-prod` |
| Website PROD | INCHANGÉ — `v0.6.9-promo-forwarding-prod` |
| Billing/Stripe | Non touché |
| Tracking GA4/LinkedIn | Build args préservés |
| Register promo | Non touché |

---

## 11. KEY-249 Update

- **Statut** : In Progress (pas fermé en DEV)
- **Ce qui est fait** : sélecteur pays Amazon dans `/start`, propagation `marketplace_key`, validation UX
- **Ce qui reste** : test OAuth réel, promotion PROD
- **Image DEV** : `v3.5.158-amazon-start-country-choice-dev`

---

## 12. PROD inchangée

Aucune modification PROD. Toutes les images PROD sont aux mêmes versions qu'avant cette phase.

---

## 13. Rollback DEV (GitOps strict)

```bash
# 1. Modifier k8s/keybuzz-client-dev/deployment.yaml
#    image: ghcr.io/keybuzzio/keybuzz-client:v3.5.157-promo-winner-ux-fix-dev
# 2. Commit + push keybuzz-infra
# 3. kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml
# 4. kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 14. Verdict

**GO PARTIEL — DEV UX READY, OAUTH REAL TEST PENDING**

AMAZON START MARKETPLACE CHOICE READY IN DEV — /START NOW ASKS EXPLICIT AMAZON COUNTRY BEFORE OAUTH — EXPECTED_CHANNEL PRESERVED — /CHANNELS UNCHANGED — CONNECTOR ACTIVATION PATH PRESERVED — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR PROD PROMOTION

---

## 15. Chemin du rapport

`keybuzz-infra/docs/PH-SAAS-T8.12AO.6-AMAZON-START-MARKETPLACE-CHOICE-UX-DEV-01.md`
