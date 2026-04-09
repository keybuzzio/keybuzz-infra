# PH139-C — Signature UX Finalization

> Date : 1er avril 2026
> Auteur : Agent Cursor
> Environnement : DEV

---

## Objectif

Rendre la signature visible, modifiable, prioritaire et coherente dans toute l'application.

---

## Audit UX (Etape 1)

### Etat avant PH139-C

| Onglet | Contenu | Observation |
|--------|---------|-------------|
| Entreprise | Nom, email, tel, adresse | OK |
| Horaires | Horaires ouverture | OK |
| Conges | Periodes de fermeture | OK |
| Messages auto | Accuse reception, hors horaires, templates retard/retour | Distinct de Knowledge/Templates |
| Notifications | Preferences notification | OK |
| Intelligence Artificielle | Modes IA, escalade, Agent KeyBuzz | OK |
| Espaces | Gestion multi-espaces | OK |
| Agents | Gestion agents (owner/admin) | OK |
| Avance | Mode focus | OK |
| **Signature** | **ABSENT** | A ajouter |

### Decision

- "Messages auto" = configure les reponses automatiques systeme (accuse reception, hors horaires). **Distinct** de Knowledge/Templates qui gere les templates de reponse manuelle.
- **Signature = nouvel onglet dedie** insere apres "Messages auto" et avant "Notifications".
- Pas de doublon supprime car chaque onglet a un role distinct.

---

## Emplacement retenu (Etape 2)

Onglet **Signature** entre "Messages auto" et "Notifications" :

```
Entreprise > Horaires > Conges > Messages auto > [Signature] > Notifications > IA > Espaces > Agents > Avance
```

- Icone : PenLine (lucide-react)
- Le bouton "Enregistrer" global est masque sur cet onglet (sauvegarde autonome integrée)

---

## Priorite de resolution signature (Etape 3)

Ordre de priorite dans `signatureResolver.ts` :

| Priorite | Source | Champ |
|----------|--------|-------|
| 1 | `tenant_settings` | `signature_company_name`, `signature_sender_name`, `signature_sender_title` |
| 2 | `agents` (admin actif) | `first_name + last_name` (fallback senderName) |
| 3 | `tenants` | `name` (fallback companyName) |
| 4 | Hardcode | `"Service client"` |

La signature configuree manuellement dans les Parametres est **toujours prioritaire**.

---

## Fichiers modifies

### Client (keybuzz-client)

| Fichier | Action |
|---------|--------|
| `app/settings/page.tsx` | Ajout import SignatureTab, tab "Signature", exclusion bouton global |
| `app/settings/components/SignatureTab.tsx` | **NOUVEAU** - Composant complet avec 3 champs, preview live, resolvedPreview, save/reset, feedback |
| `app/api/tenant-context/signature/route.ts` | **NOUVEAU** - Route BFF GET/PUT proxy vers API backend |

### API (keybuzz-api)

| Fichier | Action |
|---------|--------|
| `src/modules/auth/tenant-context-routes.ts` | Import `getSignatureConfig` + `formatSignature`, ajout `resolvedPreview` dans GET response |

---

## SignatureTab - Fonctionnalites

- **3 champs** : Nom entreprise, Nom expediteur (optionnel), Fonction (optionnel)
- **Apercu live** : mise a jour en temps reel a chaque frappe
- **Resolved preview** : affiche la signature reelle (avec fallback agent) quand elle differe
- **Save/Reset** : bouton enregistrer desactive si pas de changement, bouton annuler conditionnel
- **Feedback** : etats idle / saving / saved / error avec icones
- **Note priorite** : encart informatif sur la priorite settings > agent
- **Loading skeleton** : animation pendant le chargement

---

## API - resolvedPreview

Le GET `/tenant-context/signature/:tenantId` retourne desormais :

```json
{
  "signature": {
    "companyName": "eComLG",
    "senderName": "",
    "senderTitle": ""
  },
  "preview": "Cordialement,\neComLG",
  "resolvedPreview": "Cordialement,\nLudovic Gonthier\neComLG"
}
```

- `signature` : valeurs brutes editables
- `preview` : apercu base sur les champs du formulaire
- `resolvedPreview` : signature reelle utilisee (avec fallback agent)

---

## Tests DEV

| Test | Resultat |
|------|----------|
| API health | OK (`{"status":"ok"}`) |
| GET /signature/ecomlg-001 | OK (resolvedPreview present) |
| Client DEV login page | HTTP 200 |
| Worker startup | OK (SMTP OK, SES OK) |
| API logs erreurs | Zero erreur |

---

## Non-regressions

| Module | Statut |
|--------|--------|
| Settings (autres onglets) | OK - aucun changement |
| Agents | OK - non touche |
| Inbox | OK - non touche |
| Outbound worker | OK - demarre normalement |
| AI assist | OK - non touche |
| Autopilot | OK - non touche |
| Billing | OK - non touche |

---

## Images deployees DEV

| Service | Image |
|---------|-------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.164-signature-ux-final-dev` |
| Worker | `ghcr.io/keybuzzio/keybuzz-api:v3.5.164-signature-ux-final-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.164-signature-ux-final-dev` |

---

## Bug fix : Skeleton de chargement infini

**Symptome** : L'onglet Signature affichait un skeleton anime indefiniment, le contenu ne se chargeait jamais.

**Cause racine** : Deux problemes combines :
1. Le composant `SignatureTab` appelait le BFF `/api/tenant-context/signature` sans header `X-User-Email`. Le BFF relayait un header vide vers l'API backend, qui retournait 401 ("Not authenticated"). Le composant swallowait l'erreur silencieusement.
2. Si `useTenantId()` retournait `undefined` avant que le tenant context soit disponible, le `useEffect` retournait immediatement sans jamais appeler `setLoading(false)`.

**Fix** :
- Ajout d'un fetch `/api/auth/me` prealable (meme pattern que `ProfileTab`) pour recuperer l'email de session
- Passage de `X-User-Email` en header dans les appels GET et PUT
- `setLoading(false)` explicite quand `tenantId` est absent

---

## Deploiement PROD

**Date** : 1er avril 2026

### Images PROD

| Service | Image |
|---------|-------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.164-signature-ux-final-prod` |
| Worker | `ghcr.io/keybuzzio/keybuzz-api:v3.5.164-signature-ux-final-prod` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.164-signature-ux-final-prod` |

### Verifications PROD

| Test | Resultat |
|------|----------|
| API health | `{"status":"ok"}` |
| GET /signature/ecomlg-001 | `resolvedPreview: "Cordialement,\nLudovic Gonthier\neComLG"` |
| Client login | HTTP 200 |
| Worker startup | SMTP OK, SES OK |
| Logs erreurs | Zero erreur |

---

## Rollback DEV

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.163-agent-default-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.163-agent-default-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.163-agent-default-dev -n keybuzz-client-dev
```

## Rollback PROD

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.163-agent-default-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.163-agent-default-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.163-agent-default-prod -n keybuzz-client-prod
```

---

## Verdict

**SIGNATURE UX CLEAR — SETTINGS PRIORITY ENFORCED — NO DUPLICATE MENU — BUG FIXED — PROD DEPLOYED**
