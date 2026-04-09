# PH142-B — AI Error Clustering

> Date : 2026-04-03
> Statut : DEV + PROD deployes

---

## Objectif

Regrouper automatiquement les erreurs IA (flags `HUMAN_FLAGGED_INCORRECT`) en categories pour identifier rapidement les patterns d'erreur recurrents.

## Changements

### API (`keybuzz-api`)

**`src/modules/ai/suggestion-tracking-routes.ts`** :
- Ajout fonction `classifyError(text)` — classification par mots-cles deterministes :
  - `facture` : facture, invoice, facturation, tva, siret
  - `tracking` : colis, tracking, livraison, suivi, transporteur, expedition
  - `retour` : retour, remboursement, renvoi, echange
  - `commande` : commande, order, annulation, achat
  - `produit` : produit, article, defectueux, casse, garantie
  - `compte` : compte, connexion, mot de passe, email, profil
  - `autre` : fallback
- Ajout endpoint `GET /ai/errors/clusters?tenantId=xxx&period=7d|30d` :
  - Requete les flags `HUMAN_FLAGGED_INCORRECT` + jointure laterale sur la derniere suggestion
  - Classification de chaque flag via `classifyError()`
  - Retourne : `{ totalFlags, clusters: [{ type, count, examples }], period }`
  - Trie par count decroissant (top erreurs en premier)
  - Inclut jusqu'a 3 exemples par categorie

### Client (`keybuzz-client`)

**`app/api/ai/errors/clusters/route.ts`** (nouveau) :
- Route BFF proxy vers `GET /ai/errors/clusters`

**`app/ai-journal/page.tsx`** :
- Import icones `ThumbsDown`, `BarChart3`
- Types `ErrorCluster` + constantes `CLUSTER_LABELS` / `CLUSTER_COLORS`
- State `clusters` + `totalFlags`
- Fetch clusters dans `fetchJournal()` (apres le fetch principal)
- Section UI "Erreurs IA signalees" entre les filtres et la table d'evenements :
  - Affichee uniquement si `totalFlags > 0`
  - Grille responsive (2/3/4 colonnes selon ecran)
  - Chaque categorie avec badge colore + compteur + extrait du 1er exemple

## Tests DEV

```
Health check:                    OK (status: ok)
GET /ai/errors/clusters (vide):  OK (1 flag reel)
Insert 8 test flags:             OK
GET /ai/errors/clusters (data):  OK — 9 flags, 5 categories
  - tracking: 3
  - retour: 2
  - facture: 2
  - compte: 1
  - produit: 1
Period filter (7d):              OK
Non-regression journal:          OK (1306 events)
Cleanup test data:               OK
```

## Images deployees

| Service | DEV | PROD |
|---------|-----|------|
| API     | `v3.5.184-ai-error-clustering-dev` | `v3.5.184-ai-error-clustering-prod` |
| Client  | `v3.5.184-ai-error-clustering-dev` | `v3.5.184-ai-error-clustering-prod` |

## Non-regression

- PH142-A (quality loop, flag, log) : intact
- Journal IA : fonctionnel
- Suggestions IA : intactes
- Billing : non touche
- Autopilot : non touche
- Multi-tenant : strict (filtre `tenant_id` sur tous les endpoints)

## Health checks PROD

```
API  : https://api.keybuzz.io/health     → 200 OK
Client : https://client.keybuzz.io        → 200 OK
Pods : keybuzz-api 1/1 Running, keybuzz-client 1/1 Running
```

## Rollback DEV

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.183-ai-quality-loop-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.183-ai-quality-loop-dev -n keybuzz-client-dev
```

## Rollback PROD

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.183-ai-quality-loop-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.183-ai-quality-loop-prod -n keybuzz-client-prod
```
