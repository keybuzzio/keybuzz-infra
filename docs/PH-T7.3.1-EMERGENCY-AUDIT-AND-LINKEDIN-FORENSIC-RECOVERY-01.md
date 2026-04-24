# PH-T7.3.1-EMERGENCY-AUDIT-AND-LINKEDIN-FORENSIC-RECOVERY-01 — TERMINE

> Date : 2026-03-01
> Type : Audit forensique (lecture seule)
> Environnement : DEV uniquement
> Verdict : **LINKEDIN WORK PARTIALLY RECOVERABLE**

---

## PREFLIGHT


| Element                    | Valeur                                                                 |
| -------------------------- | ---------------------------------------------------------------------- |
| Client image DEV actuelle  | `ghcr.io/keybuzzio/keybuzz-client:v3.5.82-linkedin-dev`                |
| API image DEV actuelle     | `ghcr.io/keybuzzio/keybuzz-api:v3.5.80-linkedin-dev`                   |
| Client image PROD actuelle | `ghcr.io/keybuzzio/keybuzz-client:v3.5.81-tiktok-attribution-fix-prod` |
| API image PROD actuelle    | `ghcr.io/keybuzzio/keybuzz-api:v3.5.79-tiktok-api-replay-prod`         |
| Branche client bastion     | `ph148/onboarding-activation-replay`                                   |
| Branche API bastion        | `ph147.4/source-of-truth`                                              |
| Repo clean (client)        | **NON** — 2 fichiers modifies, 1 untracked                             |
| Repo clean (API)           | **NON** — 1 fichier modifie                                            |
| PROD touchee ?             | **NON** — images PROD = TikTok, aucun LinkedIn                         |


### Client — git log (5 derniers commits)

```
7b82c8a PH-T7.2.2.4: fix attribution query param capture
f2a8523 PH-T7.2.2.2: TikTok tracking replay
9e13d88 PH-T5.3.2: add sGTM server_container_url for Addingwell
f165e1b PH-T4.2: add GA4/Meta Pixel ARG+ENV to Dockerfile
7a94f2a PH-T4: pass attribution to checkout-session for Stripe metadata enrichment
```

### API — git log (5 derniers commits)

```
12e1f407 PH-T7.2.2.2: TikTok ttclid in signup_attribution INSERT/SELECT, Stripe metadata, conversion webhook
fc6e5c85 PH-T5.6: adapt emitConversionWebhook to GA4 Measurement Protocol format
3a10e731 PH-T4: fix emitConversionWebhook scope
a314ffec PH-T4: Stripe metadata enrichment + stripe_session_id linkage + conversion webhook + HMAC
383fa824 PH-T2: persist marketing attribution in signup_attribution table
```

**Observation** : ZERO commit LinkedIn dans l'historique des deux repos.

---

## 1. INVENTAIRE COMPLET

### CLIENT


| Fichier                                     | Modif                                                                       | Commite ? | Scope LinkedIn pur ?                        |
| ------------------------------------------- | --------------------------------------------------------------------------- | --------- | ------------------------------------------- |
| `src/components/tracking/SaaSAnalytics.tsx` | LinkedIn Insight Tag (22 lignes ajoutees) + refactoring commentaires/TikTok | **NON**   | **NON** — melange LinkedIn + TikTok cleanup |
| `Dockerfile`                                | +1 ARG `NEXT_PUBLIC_LINKEDIN_PARTNER_ID`, +1 ENV                            | **NON**   | **OUI**                                     |
| `scripts/ph-t722-patch-client.js`           | Untracked, script TikTok residuel                                           | **NON**   | NON (hors scope)                            |


#### Detail `SaaSAnalytics.tsx` — contenu LinkedIn isole

Le diff contient 3 types de modifications :

1. **LinkedIn pur** : ajout `LINKEDIN_PARTNER_ID` const, condition `shouldLoad`, bloc JSX Insight Tag (lignes 30, 54, 150-166)
2. **Refactoring commentaires** : en-tete du fichier mis a jour (TikTok + LinkedIn)
3. **TikTok cleanup** : reformatage du script TikTok Pixel (indentation, variables)

### API


| Fichier                         | Modif                          | Commite ? | Correct ?        |
| ------------------------------- | ------------------------------ | --------- | ---------------- |
| `src/modules/billing/routes.ts` | +6 lignes sha256_email_address | **NON**   | **BUG CRITIQUE** |


#### Bug API : code mort

Le bloc ajoute reference `attribution.user_email` :

```typescript
if (attribution.user_email) {
  const crypto = require('crypto');
  params.sha256_email_address = crypto.createHash('sha256')
    .update(String(attribution.user_email).toLowerCase().trim()).digest('hex');
}
```

Mais le SELECT qui alimente `attribution` ne contient PAS `user_email` :

```sql
SELECT utm_source, utm_medium, utm_campaign, utm_term, utm_content,
       gclid, fbclid, fbc, fbp, gl_linker, landing_url, referrer,
       attribution_id, plan, cycle, ttclid
FROM signup_attribution WHERE tenant_id = $1 LIMIT 1
```

`**attribution.user_email` est toujours `undefined` → le hash ne s'execute JAMAIS.**

#### Cause racine

1. Le patch v1 (`ph-t73-patch-email-hash.js`) devait ajouter `user_email` au SELECT (PATCH 1) + le hash dans un objet `attribution: {` (PATCH 2). PATCH 1 a reussi, PATCH 2 a echoue ("attribution object not found").
2. Le patch v2 (`ph-t73-patch-email-hash-v2.js`) dit "PATCH 1 already applied by v1" et verifie `billing.includes('user_email')`. Mais `user_email` existe deja dans le fichier a la ligne 1295 (`cancel_reasons`). La verification est un **faux positif**.
3. Le fichier source a ete remis a zero (git checkout ou re-pull) entre v1 et v2.
4. v2 a applique uniquement le hash (PATCH 2 correct) SANS le SELECT (PATCH 1 perdu).
5. **Le bundle deploye confirme** : le SELECT compile ne contient pas `user_email`.

### DB


| Verification                                   | Resultat                    |
| ---------------------------------------------- | --------------------------- |
| Colonne `user_email` dans `signup_attribution` | **EXISTE** (depuis PH-T2)   |
| Migration LinkedIn                             | **AUCUNE** (pas necessaire) |
| Table modifiee                                 | **AUCUNE**                  |


La colonne `user_email` est deja presente — seul le SELECT doit etre corrige.

### sGTM


| Element               | Etat                  |
| --------------------- | --------------------- |
| Tag LinkedIn CAPI     | **NON configure**     |
| Trigger LinkedIn      | **NON configure**     |
| Access Token LinkedIn | **NON genere**        |
| Impact actuel         | AUCUN — sGTM inchange |


---

## 2. VERIFICATION DE PROVENANCE


| Element                     | Valeur                                              |
| --------------------------- | --------------------------------------------------- |
| Branche client utilisee     | `ph148/onboarding-activation-replay` — **CORRECTE** |
| Branche API utilisee        | `ph147.4/source-of-truth` — **CORRECTE**            |
| Commit reel client LinkedIn | **AUCUN** — modifications non commitees             |
| Commit reel API LinkedIn    | **AUCUN** — modifications non commitees             |
| Build-from-git respecte ?   | **NON** — builds faits depuis du code uncommitte    |
| Patch bastion utilise ?     | **OUI** — 2 scripts Node.js executes sur le bastion |
| Reproductibilite            | **NON** — impossible de reproduire l'image exacte   |


### Conclusion provenance

Les branches sont correctes, mais aucun commit LinkedIn n'existe.
Les images DEV `v3.5.82-linkedin-dev` et `v3.5.80-linkedin-dev` ont ete construites
depuis du code modifie en working directory, non commite, non reproductible.

---

## 3. CLASSIFICATION


| Element                                                        | Classe  | Justification                                                                                                                                         |
| -------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **LinkedIn Insight Tag** (SaaSAnalytics.tsx, bloc JSX)         | **A**   | Code fonctionnel, verifie en production DEV (pixel charge, requetes LinkedIn confirmees). Bloc isole (lignes 150-166).                                |
| **LINKEDIN_PARTNER_ID const + shouldLoad** (SaaSAnalytics.tsx) | **A**   | 2 lignes triviales, correctes.                                                                                                                        |
| **Dockerfile ARG/ENV**                                         | **A**   | 2 lignes ajoutees, propres, isolees, pattern identique aux autres tracking vars.                                                                      |
| **SaaSAnalytics commentaires/TikTok refactoring**              | **B**   | Refactoring non-LinkedIn melange dans le meme diff. Separable mais demande tri.                                                                       |
| **SHA256 email hash** (API routes.ts)                          | **B**   | Logique de hash correcte en soi, mais necessite fix du SELECT (ajouter `user_email`). 6 lignes recuperables avec 1 correction.                        |
| **Patch scripts bastion** (v1, v2)                             | **C**   | Scripts jetables, v1 echoue, v2 faux positif. Approche non reproductible.                                                                             |
| **Images DEV linkedin** (`v3.5.82`, `v3.5.80`)                 | **C**   | Non reproductibles (code non commite). A remplacer.                                                                                                   |
| **Rapport PH-T7.3** (`docs/PH-T7.3-...`)                       | **C**   | Mauvais emplacement (`docs/` au lieu de `keybuzz-infra/docs/`). Affirme "code fonctionnel" alors que le hash est du code mort. Conclusions invalides. |
| **sGTM config LinkedIn**                                       | **N/A** | Jamais faite. A faire lors du replay.                                                                                                                 |
| **LinkedIn credentials** (Partner ID, Conversion ID)           | **A**   | Partner ID `9969977`, Conversion ID `27491233`, Ad Account `514471703`. Valides, recuperables directement.                                            |


### Resume classification


| Classe                              | Count | Elements                                                    |
| ----------------------------------- | ----- | ----------------------------------------------------------- |
| **A — recuperable tel quel**        | 4     | Insight Tag JSX, const+shouldLoad, Dockerfile, credentials  |
| **B — recuperable avec adaptation** | 2     | Commentaires SaaSAnalytics, SHA256 hash (fix SELECT requis) |
| **C — a jeter**                     | 3     | Patch scripts, images DEV, rapport PH-T7.3                  |
| **N/A**                             | 1     | sGTM (jamais fait)                                          |


---

## 4. PLAN DE REPLAY (proposition — NON execute)

### Ordre

```
1. Client (Insight Tag + Dockerfile)
2. API (SELECT fix + SHA256 hash)
3. Build + Deploy DEV
4. Test (signup → checkout → verifier hash dans webhook)
5. sGTM (config tag LinkedIn CAPI)
```

### 4.1 Client

- **Base** : `ph148/onboarding-activation-replay`
- **Actions** :
  1. Ajouter `LINKEDIN_PARTNER_ID` const dans `SaaSAnalytics.tsx`
  2. Ajouter `LINKEDIN_PARTNER_ID` dans condition `shouldLoad`
  3. Ajouter bloc JSX LinkedIn Insight Tag
  4. Ajouter `ARG NEXT_PUBLIC_LINKEDIN_PARTNER_ID=` dans Dockerfile
  5. Ajouter `ENV NEXT_PUBLIC_LINKEDIN_PARTNER_ID=${NEXT_PUBLIC_LINKEDIN_PARTNER_ID}` dans Dockerfile
  6. Commit : `PH-T7.3: LinkedIn Insight Tag + Dockerfile env`
- **Ne PAS inclure** : refactoring commentaires/TikTok (hors scope LinkedIn)

### 4.2 API

- **Base** : `ph147.4/source-of-truth`
- **Actions** :
  1. Ajouter `, user_email` au SELECT de `emitConversionWebhook` (apres `ttclid`)
  2. Ajouter le bloc SHA256 hash apres `referrer`
  3. Commit : `PH-T7.3: SHA256 email hash for LinkedIn CAPI via sGTM`
- **Correction critique** : le SELECT DOIT inclure `user_email` sinon le hash est du code mort

### 4.3 sGTM

- **Prerequis** : generer LinkedIn Access Token (Developer Portal)
- **Actions** :
  1. Creer tag LinkedIn CAPI dans le container sGTM
  2. Conversion Rule ID : `27491233`
  3. Mapper `sha256_email_address` → User Data → SHA256 Email
  4. Trigger : evenement `purchase`

### 4.4 Test

- Client : verifier pixel LinkedIn charge sur `/login`
- API : verifier `user_email` dans le SELECT (bundle compile)
- API : verifier `sha256_email_address` dans le webhook POST
- E2E : signup → checkout → conversion LinkedIn visible

---

## 5. CONCLUSION

### Verdict : LINKEDIN WORK PARTIALLY RECOVERABLE

**Ce qui fonctionne** :

- L'Insight Tag client est fonctionnel et verifie (pixel charge, requetes LinkedIn confirmees)
- Les branches sont correctes (`ph148` client, `ph147.4` API)
- Les credentials LinkedIn sont valides (Partner ID, Conversion ID)
- La colonne `user_email` existe deja en DB

**Ce qui est casse** :

- Le hash SHA256 API est du **code mort** (SELECT incomplet)
- Aucun commit LinkedIn dans aucun des deux repos
- Les images DEV ne sont pas reproductibles
- Le rapport PH-T7.3 est inexact et mal place
- sGTM n'a jamais ete configure

**Impact reel** :

- PROD : **ZERO impact** (images PROD non touchees)
- DEV : images LinkedIn deployees mais hash API non fonctionnel
- Risque : **FAIBLE** — tout est reversible, pas de donnees corrompues

**Action recommandee** :
Un replay propre (PH-T7.3.2) est necessaire avec :

1. Commits propres sur les bonnes branches
2. Fix du SELECT pour inclure `user_email`
3. Build reproductible depuis git
4. Verification end-to-end du hash dans le webhook
5. Configuration sGTM

Aucune autre action effectuee.