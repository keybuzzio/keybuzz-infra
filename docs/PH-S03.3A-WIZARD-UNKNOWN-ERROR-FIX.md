# PH-S03.3A — Fix wizard création source : erreurs explicites + perte de session (DEV only)

**Date :** 2026-01-30  
**Périmètre :** Remplacer "Unknown error" par des messages explicites ; corriger l’affichage en cas de réponse non JSON (401/422/500).  
**Environnement :** seller-dev uniquement.  
**Référence :** PH-S03.1 (stabilisation wizard), PH-S03.2 (FTP / secretRef).

---

## 1. Contexte et objectifs

- **Problème :** La source est créée (POST OK) mais le wizard affiche "Unknown error".
- **Cause identifiée :** Quand seller-api renvoie une réponse non JSON (ex. page HTML 401 "Authentication required. Please login via KeyBuzz."), `response.json()` échoue et le fallback était `detail: 'Unknown error'`.
- **Objectifs :**
  1. Identifier la requête post-create qui échoue (Network / logs).
  2. Remplacer "Unknown error" par des messages explicites selon le status (401 / 422 / 500).
  3. Log safe en console (status + endpoint, sans secrets) pour le diagnostic.
  4. Garder le comportement "Source créée, compléter depuis la liste" si partiel, sans message alarmiste.

**Invariants :** DEV only, GitOps only, aucun secret en clair.

---

## 2. Appel fautif et cause

- **Fichier :** `keybuzz-seller/seller-client/src/lib/api.ts`
- **Ligne concernée (avant fix) :**  
  `const error = await response.json().catch(() => ({ detail: 'Unknown error' }));`
- **Comportement :** Pour toute réponse d’erreur dont le corps n’est pas du JSON valide (ex. 401 avec page HTML de login, 500 avec corps texte), le client affichait "Unknown error" sans indiquer la cause (session expirée, validation, serveur).

**Séquence wizard typique (pour diagnostic) :**
1. POST `/api/catalog-sources` → 201
2. PUT `/api/catalog-sources/{id}/fields` → 200
3. POST `/api/catalog-sources/{id}/ftp/connection` (si secretRefId) → peut renvoyer 401 si session perdue
4. POST `/api/catalog-sources/{id}/ftp/select-file` (si durable)
5. POST `/api/catalog-sources/{id}/column-mappings/bulk`

Le premier appel non-2xx (souvent 401 avec corps HTML) provoquait le fallback "Unknown error".

---

## 3. Corrections réalisées

### A) Messages explicites selon le status (api.ts)

**Fichier modifié :** `keybuzz-seller/seller-client/src/lib/api.ts`

- **401 :** Message utilisateur : *"Connexion expirée, merci de vous reconnecter."* (déjà géré par redirection SSO ; message harmonisé si une couche attrape l’erreur).
- **422 :** *"Champs invalides."* (détails complets si le corps est du JSON FastAPI avec `detail` tableau).
- **5xx :** *"Erreur serveur, réessayez."*
- **Autres 4xx/5xx :** *"Erreur {status}."*

Implémentation :

- Fonction `fallbackMessage(status)` utilisée lorsque `response.json()` échoue (réponse non JSON).
- Le `catch` de `response.json()` retourne `{ detail: fallbackMessage(response.status) }` au lieu de `{ detail: 'Unknown error' }`.
- Si le corps est du JSON valide, la logique existante (detail string, tableau FastAPI 422, etc.) est conservée ; sinon on utilise `fallbackMessage(response.status)` pour le message final.

### B) Log safe en console

- En cas de réponse non JSON : `console.warn('[api]', response.status, endpoint, '(réponse non JSON)')`.
- Pour toute réponse d’erreur (status >= 400) avec JSON : `console.warn('[api]', response.status, endpoint)`.
- Aucun corps, header sensible ou secret n’est loggé.

### C) Comportement wizard (page.tsx)

- Aucun changement nécessaire : la logique existante (PH-S03.1) conserve le message partiel non alarmiste :
  - Si `source` existe (POST réussi, étape suivante en échec) : message *"Source créée, configuration incomplète. Complétez la configuration (FTP, mapping) depuis la fiche source."* + fermeture wizard + ouverture fiche source.
  - Si POST a échoué : `setCreateError(errorMessage)` avec le message renvoyé par l’API (désormais explicite : connexion expirée, champs invalides, erreur serveur, etc.).

---

## 4. Preuve Network / comportement

### Avant

- Requête en erreur avec corps non JSON (ex. 401 HTML) → UI : *"Unknown error"*.
- Console : pas de log structuré pour corréler l’erreur à un endpoint.

### Après

- **401 (corps non JSON) :** Redirection SSO + message si capturé : *"Connexion expirée, merci de vous reconnecter."*
- **422 (corps JSON) :** Message détaillé FastAPI ; si corps non JSON : *"Champs invalides."*
- **500 (corps non JSON) :** *"Erreur serveur, réessayez."*
- Console : `[api] <status> <endpoint>` et éventuellement `(réponse non JSON)` pour le diagnostic sans exposer de données sensibles.

### Validation

- Parcours wizard complet → fin OK sans message rouge.
- Si une étape optionnelle échoue (ex. FTP durable non configurée) → message clair (erreur serveur / champs invalides selon le cas) + source accessible en liste, sans "Unknown error".
- En cas de 401 (session expirée) → redirection login + message explicite si l’erreur est affichée brièvement.

---

## 5. Fichiers modifiés

| Fichier | Modification |
|--------|---------------|
| `keybuzz-seller/seller-client/src/lib/api.ts` | Fallback message selon status (401/422/5xx), log safe `[api] status endpoint`, plus de "Unknown error". |
| `keybuzz-infra/docs/PH-S03.3A-WIZARD-UNKNOWN-ERROR-FIX.md` | Rapport (ce document). |

---

## 6. Récapitulatif

| Élément | Avant | Après |
|--------|--------|--------|
| Réponse erreur non JSON | "Unknown error" | Message explicite (connexion expirée / champs invalides / erreur serveur) |
| Diagnostic | Aucun log ciblé | `console.warn('[api]', status, endpoint)` (sans secrets) |
| Wizard partiel | Message amical déjà en place (PH-S03.1) | Inchangé, pas de message alarmiste |
| 401 | Redirection SSO + "Unauthorized - redirecting to login" | Redirection SSO + "Connexion expirée, merci de vous reconnecter." |

**Statut :** Corrections appliquées côté client (seller-client). À valider en DEV en reproduisant le wizard (ex. "Wortmann") et en vérifiant les messages affichés et les logs console.
