# PH-T8.11E.1-GOOGLE-ADS-CREDENTIALS-RECOVERY-01 — TERMINÉ

**Verdict : GO PARTIEL — 3/5 credentials identifiés, 2 actions manuelles requises**

---

## 1. Surfaces Google testées

| Surface | URL | Accessible ? | Résultat |
|---|---|---|---|
| Google Cloud Console | `console.cloud.google.com` | Oui | Session active `keybuzz.pro@gmail.com` |
| Projet GCP `KeyBuzz-Intelligence` | `project=keybuzz-intelligence` | Oui | Projet actif, 21 APIs activées |
| APIs & Services - Identifiants | `/apis/credentials` | Oui | 3 clés API + 1 OAuth2 Client ID |
| Google Ads API (Bibliothèque) | `/apis/library/googleads.googleapis.com` | Oui | API disponible, **pas encore activée** |
| Google Ads - Compte KeyBuzz | `ads.google.com` (authuser=4) | Oui | Compte existant, ID `817-386-1138` |
| Google Ads - API Center | `/aw/apicenter` | Non | "Seuls les comptes administrateur ont accès" |
| Écran consentement OAuth | Visible dans la sidebar | Oui | Configuré |

---

## 2. Statut de la connexion

- **Session Google** : active pour `keybuzz.pro@gmail.com` (KeyBuzz Consulting)
- **Projet GCP** : `KeyBuzz-Intelligence` (ID: `keybuzz-intelligence`, numéro: `74873063393`)
- **Compte Google Ads** : **EXISTANT** — `KeyBuzz` (Customer ID: `8173861138`)
- **Type de compte Google Ads** : compte standard (pas MCC)
- **Campagnes actives** : 0 (aucune campagne activée)

---

## 3. Éléments trouvés vs absents

### Credentials disponibles (3/5)

| Élément | Statut | Localisation | Note |
|---|---|---|---|
| OAuth2 `client_id` | **TROUVÉ** | Env vars pods client DEV+PROD | Même client utilisé pour Google Login |
| OAuth2 `client_secret` | **TROUVÉ** | Env vars pods client DEV+PROD | Secret actif (créé 6 jan 2026) |
| Google Ads `customer_id` | **TROUVÉ** | Google Ads UI | `8173861138` (format: `817-386-1138`) |

**Important** : les secrets ne sont pas exposés dans ce rapport (conformément aux règles).

### Credentials manquants (2/5)

| Élément | Statut | Pourquoi | Action requise |
|---|---|---|---|
| `developer_token` | **ABSENT** | Le compte KeyBuzz Google Ads est un **compte standard**, pas un MCC. L'API Center n'est accessible qu'aux comptes administrateur (MCC). | Créer un compte MCC Google Ads + demander un developer token |
| OAuth2 `refresh_token` | **ABSENT** | Aucun refresh token n'a été généré pour les scopes Google Ads API. | Générer via OAuth Playground ou script après activation de l'API |

### Prérequis techniques manquants

| Élément | Statut | Action |
|---|---|---|
| Google Ads API activée dans GCP | **NON activée** | 1 clic sur "Activer" dans la bibliothèque APIs |
| Google Ads API scopes dans OAuth consent screen | **Non vérifié** | Ajouter le scope `https://www.googleapis.com/auth/adwords` |

---

## 4. Action utilisateur requise

**Ludovic doit prendre la main pour les étapes suivantes :**

### Étape A — Activer l'API Google Ads dans GCP (1 min)
1. Aller sur : `https://console.cloud.google.com/apis/library/googleads.googleapis.com?project=keybuzz-intelligence`
2. Cliquer sur "**Activer**"

### Étape B — Créer un compte MCC Google Ads (5 min)
1. Aller sur : `https://ads.google.com/home/tools/manager-accounts/`
2. Créer un compte administrateur (MCC) avec `keybuzz.pro@gmail.com`
3. Lier le compte KeyBuzz existant (`817-386-1138`) au MCC

### Étape C — Obtenir le developer token (5 min + délai approbation)
1. Dans le MCC créé, aller à **Admin** > **Centre API** (`/aw/apicenter`)
2. Accepter les conditions d'utilisation de l'API Google Ads
3. Le developer token est affiché immédiatement (mode **test**)
4. Pour accéder aux données réelles du compte `817-386-1138` :
   - Remplir le formulaire de demande d'accès **Basic**
   - Délai d'approbation : typiquement 24-72h

### Étape D — Générer un refresh_token (5 min)

Option 1 — OAuth Playground :
1. Aller sur `https://developers.google.com/oauthplayground/`
2. Settings (engrenage) : cocher "Use your own OAuth credentials"
3. Entrer le `client_id` et `client_secret` (disponibles dans les pods client)
4. Scope : `https://www.googleapis.com/auth/adwords`
5. "Authorize APIs" → se connecter avec `keybuzz.pro@gmail.com`
6. "Exchange authorization code for tokens"
7. Copier le `refresh_token` affiché

Option 2 — Script Node.js avec googleapis :
```bash
npm install googleapis
node -e "
const {google} = require('googleapis');
const oauth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, 'urn:ietf:wg:oauth:2.0:oob');
const url = oauth2Client.generateAuthUrl({access_type: 'offline', scope: 'https://www.googleapis.com/auth/adwords'});
console.log('Open:', url);
"
```

### Étape E — Confirmer et relancer
Une fois les 5 credentials disponibles, fournir au CE :
1. `developer_token` (du MCC)
2. `refresh_token` (de l'étape D)
3. Confirmer que l'API Google Ads est activée dans GCP
4. **Le CE peut alors relancer PH-T8.11E immédiatement**

---

## 5. Aucun secret exposé

Aucun secret, token, ou credential n'est affiché en clair dans ce rapport. Les valeurs identifiées sont référencées par leur localisation uniquement.

---

## 6. Aucun code modifié

- Aucune modification de code dans `keybuzz-api`
- Aucune modification de code dans `keybuzz-admin-v2`
- Aucune modification d'infrastructure
- Aucun déploiement
- PROD inchangée

---

## 7. Conclusion actionnable

### Verdict : **GO PARTIEL**

La connexion Google a réussi et a révélé une situation bien meilleure qu'attendu :

**Ce qui existe déjà :**
- Projet GCP `KeyBuzz-Intelligence` avec OAuth2 client configuré
- Secrets OAuth2 déjà déployés dans les pods client (DEV + PROD)
- Compte Google Ads `KeyBuzz` existant avec customer_id `817-386-1138`
- API Google Ads disponible à l'activation (1 clic)

**Ce qui manque (2 éléments) :**
1. **developer_token** — nécessite la création d'un MCC (~5 min) + demande d'accès Basic (~24-72h)
2. **refresh_token** — générable en 5 min via OAuth Playground après activation de l'API

### Estimation pour débloquer
- **Temps Ludovic** : ~15-20 min d'actions manuelles
- **Délai d'attente** : 24-72h pour l'approbation du developer token Basic Access
- **Alternative rapide** : le developer token en mode Test est immédiat, mais ne donne accès qu'aux comptes test (pas aux données réelles de `817-386-1138`)

### Prochaine phase
Une fois les credentials fournis → relancer **PH-T8.11E** pour l'implémentation complète.

---

## Récapitulatif credentials

| # | Élément | Statut | Source |
|---|---|---|---|
| 1 | OAuth2 `client_id` | ✅ Disponible | Pods client DEV+PROD |
| 2 | OAuth2 `client_secret` | ✅ Disponible | Pods client DEV+PROD |
| 3 | Google Ads `customer_id` | ✅ Identifié | Google Ads UI (`817-386-1138`) |
| 4 | Google Ads `developer_token` | ❌ Manquant | Nécessite MCC + demande accès |
| 5 | OAuth2 `refresh_token` (scope ads) | ❌ Manquant | Générable via OAuth Playground |

---

## PROD inchangée

Oui — aucune modification PROD.

---

## Rapport

`keybuzz-infra/docs/PH-T8.11E.1-GOOGLE-ADS-CREDENTIALS-RECOVERY-01.md`
