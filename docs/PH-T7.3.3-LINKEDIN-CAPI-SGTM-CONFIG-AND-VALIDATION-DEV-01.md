# PH-T7.3.3-LINKEDIN-CAPI-SGTM-CONFIG-AND-VALIDATION-DEV-01 — EN ATTENTE LINKEDIN

> Date : 2026-04-19
> Type : Configuration LinkedIn CAPI via sGTM + validation end-to-end
> Environnement : DEV uniquement
> Verdict : **WAIT — EN ATTENTE APPROBATION LINKEDIN CONVERSIONS API**

---

## Preflight


| Element                | Valeur                                                |
| ---------------------- | ----------------------------------------------------- |
| Client image DEV       | `v3.5.83-linkedin-replay-dev` (Insight Tag actif)     |
| API image DEV          | `v3.5.81-linkedin-api-replay-dev` (SHA256 hash actif) |
| LinkedIn Partner ID    | `9969977`                                             |
| LinkedIn Conversion ID | `27491233`                                            |
| LinkedIn App           | `KeyBuzz Tracking` (Client ID: `77qcrrzhz9xwro`)      |
| Conversions API Access | **Demande soumise** — en attente approbation LinkedIn |
| LinkedIn Access Token  | **NON disponible** — bloque par CAPI approval         |
| PROD touchee           | **NON**                                               |
| Builds effectues       | **AUCUN** (contrainte PH-T7.3.3)                      |
| Code modifie           | **AUCUN** (contrainte PH-T7.3.3)                      |


---

## 1. App LinkedIn creee

### KeyBuzz Tracking


| Champ              | Valeur                              |
| ------------------ | ----------------------------------- |
| App name           | `KeyBuzz Tracking`                  |
| Client ID          | `77qcrrzhz9xwro`                    |
| App ID LinkedIn    | `244510130`                         |
| App type           | Standalone app                      |
| Date creation      | 19 avril 2026                       |
| LinkedIn Page      | KeyBuzz Consulting                  |
| Privacy policy URL | `https://www.keybuzz.pro/legal`     |
| App logo           | Logo KeyBuzz (uploade manuellement) |
| Token TTL          | 2 mois (1 146 000 secondes)         |


### Credentials

- **Client ID** : `77qcrrzhz9xwro`
- **Primary Client Secret** : `WPL_AP1.5qOC0NIWpXWMz56I`

> **SECURITE** : Ces credentials sont documentes ici pour reference.
> En production, ils doivent etre stockes dans Vault ou K8s Secrets.

---

## 2. Etat des produits LinkedIn API


| Produit                                    | Tier        | Etat                                             |
| ------------------------------------------ | ----------- | ------------------------------------------------ |
| **Conversions API**                        | Standard    | **Demande soumise** — Access Request Form envoye |
| Share on LinkedIn                          | Default     | Disponible (non active — non necessaire)         |
| Advertising API                            | Development | Disponible (non active — non necessaire)         |
| Lead Sync API                              | Standard    | Disponible (non active — non necessaire)         |
| Live Events                                | Development | En attente                                       |
| Sign In with LinkedIn using OpenID Connect | Standard    | Disponible (non active — non necessaire)         |
| Events Management API                      | Standard    | Disponible (non active — non necessaire)         |
| Community Management API                   | Development | Disponible (non active — non necessaire)         |


### Conversions API — Detail demande

- Formulaire soumis sur : `linkedincustomerops.qualtrics.com` (Qualtrics)
- Type : LinkedIn Conversions API Access Request Form
- Soumission : LinkedIn Marketing Developer Team
- Delai estime : quelques heures a quelques jours ouvrables
- Scope requis : `rw_conversions`

---

## 3. Verification Page LinkedIn


| Element                 | Etat                                                   |
| ----------------------- | ------------------------------------------------------ |
| Page LinkedIn           | `KeyBuzz Consulting`                                   |
| Verification de la page | **URL generee** (valide 30 jours, expire 19 mai 2026)  |
| Approbation Page Admin  | En attente — le Page Admin doit visiter l'URL          |
| Impact                  | Mineur — la verification n'est PAS bloquante pour CAPI |


> La verification de la page est un bonus (credibilite). Le bloqueur principal
> est l'approbation du produit Conversions API par LinkedIn.

---

## 4. OAuth 2.0 — Etat scopes


| Element       | Etat                                             |
| ------------- | ------------------------------------------------ |
| Scopes actifs | **Aucun** ("No permissions added")               |
| Redirect URLs | **Aucune** (sera ajoutee par le Token Generator) |
| Token genere  | **NON** — bloque par absence de scopes           |


### Processus de generation du token (a executer apres approbation CAPI)

1. Naviguer vers `https://www.linkedin.com/developers/tools/oauth/token-generator`
2. Selectionner l'app **KeyBuzz Tracking**
3. Flow : **Member authorization code (3-legged)**
4. Cocher le scope `**rw_conversions`**
5. Cocher "I understand this tool will update my app's redirect URL settings"
6. Cliquer "Request access token"
7. Autoriser sur la page OAuth
8. Copier le token genere

> **IMPORTANT** : Le token expire apres **2 mois**. Un mecanisme de refresh
> sera necessaire pour la production.

---

## 5. Plan de configuration sGTM (pret a executer)

### Prerequis


| Element                | Etat    | Detail                                           |
| ---------------------- | ------- | ------------------------------------------------ |
| Container sGTM         | **OK**  | `t.keybuzz.io` (Addingwell)                      |
| Webhook conversion     | **OK**  | `emitConversionWebhook()` dans billing/routes.ts |
| `sha256_email_address` | **OK**  | Hash SHA256 de user_email envoye dans le payload |
| Conversion ID          | **OK**  | `27491233`                                       |
| Access Token           | **NON** | Bloque par CAPI approval                         |


### Configuration prevue

**Tag LinkedIn CAPI** (a creer dans sGTM) :


| Parametre          | Valeur                                |
| ------------------ | ------------------------------------- |
| Tag Type           | LinkedIn Conversions API              |
| Conversion Rule ID | `27491233`                            |
| Access Token       | `{A FOURNIR}`                         |
| Event Type         | CONVERSION                            |
| User Data          | SHA256 Email (`sha256_email_address`) |


**Trigger** :


| Parametre  | Valeur                                |
| ---------- | ------------------------------------- |
| Type       | Custom Event                          |
| Event Name | `purchase`                            |
| Condition  | Fired on event_name equals "purchase" |


**Variables sGTM a mapper** :


| Variable sGTM          | Source dans le payload webhook      |
| ---------------------- | ----------------------------------- |
| `sha256_email_address` | Event Data > `sha256_email_address` |
| `value`                | Event Data > `value`                |
| `currency`             | Event Data > `currency`             |
| `transaction_id`       | Event Data > `transaction_id`       |


---

## 6. Flux de donnees end-to-end (architecture)

```
[Utilisateur] → /signup → signup_attribution (DB)
     ↓
[Utilisateur] → /billing → Stripe Checkout
     ↓
checkout.session.completed (Stripe webhook)
     ↓
emitConversionWebhook() [keybuzz-api]
  → SELECT user_email FROM signup_attribution
  → SHA256(user_email.toLowerCase().trim())
  → params.sha256_email_address = hash
     ↓
POST https://t.keybuzz.io (sGTM)
  → GA4 event "purchase" + all params
     ↓
[sGTM Container]
  ├── GA4 Tag → Google Analytics 4 ✅
  ├── Meta CAPI Tag → Facebook ✅
  ├── TikTok Events API Tag → TikTok ✅
  └── LinkedIn CAPI Tag → LinkedIn ⏳ (a configurer)
       → POST /conversions (LinkedIn REST API)
       → Conversion Rule ID: 27491233
       → User Data: sha256_email_address
```

---

## 7. Matrice de tracking actuelle (pre-LinkedIn CAPI)


| Plateforme | Client-side (pixel) | Server-side (CAPI/sGTM) | Etat           |
| ---------- | ------------------- | ----------------------- | -------------- |
| GA4        | ✅ `G-JJ4KBW1BFE`    | ✅ via sGTM              | **ACTIF**      |
| Meta       | ✅ Pixel Facebook    | ✅ Meta CAPI via sGTM    | **ACTIF**      |
| TikTok     | ✅ TikTok Pixel      | ✅ TikTok Events API     | **ACTIF**      |
| Google Ads | ✅ via GA4           | ✅ via GA4/sGTM          | **ACTIF**      |
| LinkedIn   | ✅ Insight Tag       | ⏳ CAPI via sGTM         | **EN ATTENTE** |


---

## 8. Actions effectuees dans cette phase


| #   | Action                                      | Resultat                        |
| --- | ------------------------------------------- | ------------------------------- |
| 1   | Creation app LinkedIn "KeyBuzz Tracking"    | OK — Client ID `77qcrrzhz9xwro` |
| 2   | Configuration app (logo, privacy URL, page) | OK                              |
| 3   | Demande produit Conversions API             | OK — formulaire soumis          |
| 4   | Generation URL verification page            | OK — valide 30 jours            |
| 5   | Tentative generation token                  | BLOQUE — aucun scope sans CAPI  |
| 6   | Audit complet etat Products/Auth/Settings   | OK — documente dans ce rapport  |


---

## 9. Bloqueur et prochaines etapes

### Bloqueur actuel

**L'approbation du produit Conversions API par LinkedIn est requise.**

LinkedIn Marketing Developer Team doit examiner la demande soumise via le
Access Request Form (Qualtrics). Ce processus prend generalement quelques
heures a quelques jours ouvrables.

### Etapes a executer apres approbation

1. **Verifier** : onglet Products → Conversions API passe de "Access request form" a "Added"
2. **Verifier** : onglet Auth → OAuth 2.0 scopes inclut `rw_conversions`
3. **Generer** le Access Token via Token Generator (voir section 4)
4. **Configurer** le tag LinkedIn CAPI dans sGTM (voir section 5)
5. **Tester** : effectuer un signup + checkout sur DEV
6. **Valider** : verifier que la conversion remonte dans LinkedIn Campaign Manager
7. **Publier** : version sGTM avec le tag LinkedIn CAPI actif

### Notifications

LinkedIn envoie un email a l'adresse associee au compte developpeur
lorsque la demande est approuvee. Surveiller egalement :

- L'onglet Products de l'app (le Conversions API passera en section "Added products")
- L'onglet Auth (les scopes apparaitront)

---

## 10. Rollback

Aucune modification de code ou d'infrastructure n'a ete effectuee dans
cette phase. **Aucun rollback necessaire.**


| Service     | Image actuelle                        | Modifiee ? |
| ----------- | ------------------------------------- | ---------- |
| Client DEV  | `v3.5.83-linkedin-replay-dev`         | **NON**    |
| API DEV     | `v3.5.81-linkedin-api-replay-dev`     | **NON**    |
| Client PROD | `v3.5.81-tiktok-attribution-fix-prod` | **NON**    |
| API PROD    | `v3.5.79-tiktok-api-replay-prod`      | **NON**    |
| sGTM        | Container actuel (inchange)           | **NON**    |


---

## Conclusion

### Resume

L'app LinkedIn **KeyBuzz Tracking** est creee et configuree. La demande d'acces
au produit **Conversions API** a ete soumise a LinkedIn via le formulaire
officiel. Aucune modification de code, aucun build, aucune action PROD.

### Verdict

**WAIT — EN ATTENTE APPROBATION LINKEDIN CONVERSIONS API**

- App LinkedIn : creee et configuree ✅
- Conversions API : demande soumise ✅
- Access Token : non disponible (bloque par CAPI approval) ⏳
- sGTM config plan : pret a executer ✅
- Code/Builds : intacts (aucune modification) ✅
- PROD : intacte ✅

### Reprise prevue

Des que LinkedIn approuve le Conversions API :

1. Generer le token OAuth
2. Configurer le tag LinkedIn CAPI dans sGTM
3. Tester et valider end-to-end
4. Mettre a jour ce rapport avec le verdict final

