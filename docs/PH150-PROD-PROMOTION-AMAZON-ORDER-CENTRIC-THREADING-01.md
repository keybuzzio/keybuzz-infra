# PH150 — PROD Promotion: Amazon Order-Centric Threading

> Date : 13 avril 2026
> Environnement : PROD
> Image backend avant : `ghcr.io/keybuzzio/keybuzz-backend:v1.0.43-ph145.6-amazon-prod`
> Image backend après : `ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-ph150-thread-fix-prod`
> SHA digest : `sha256:0c2e6594a5c888ac56eda6d8f0039c970ac9948afc8c2e6ea7733cb8d6c8468e`
> Verdict : **AMAZON ORDER-CENTRIC THREADING PROMOTED TO PROD**

---

## 1. Préflight

| Check | Résultat |
|-------|---------|
| Backend DEV validé | `v1.0.41-ph150-thread-fix-dev` |
| Backend PROD avant | `v1.0.43-ph145.6-amazon-prod` |
| Fichier du diff | `src/modules/webhooks/inboxConversation.service.ts` |
| Diff minimal | Retrait `AND status = 'open'` + ajout réouverture resolved |
| 0 fichier Studio | Confirmé |
| 0 changement hors scope | Confirmé |
| Validation DEV par Ludovic | Rapport PH150 DEV (verdict RESTORED) |

---

## 2. Diff promu

**Fichier** : `src/modules/webhooks/inboxConversation.service.ts`

### 2.1 Retrait du filtre `status = 'open'`

```sql
-- AVANT
SELECT id FROM conversations
WHERE tenant_id = $1 AND channel = $2 AND thread_key = $3 AND status = 'open'

-- APRÈS (PH150)
SELECT id, status FROM conversations
WHERE tenant_id = $1 AND channel = $2 AND thread_key = $3
```

Idem pour le matching par `order_ref`.

### 2.2 Réouverture des conversations résolues

```typescript
const threadConvStatus = existingByThread.rows[0].status;
if (threadConvStatus === 'resolved') {
  await productDb.query(
    `UPDATE conversations SET status = 'pending', updated_at = NOW() WHERE id = $1`,
    [conversationId]
  );
  console.log(`[InboxConversation PH150] Reopened resolved conversation ${conversationId} to pending`);
}
```

---

## 3. Rollback

```bash
kubectl set image deployment/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.43-ph145.6-amazon-prod -n keybuzz-backend-prod
kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod
```

---

## 4. Build et déploiement

| Étape | Résultat |
|-------|---------|
| Build `--no-cache` | Succès (`8faca129f697`) |
| Push GHCR | `v1.0.44-ph150-thread-fix-prod` |
| `kubectl set image` | `deployment.apps/keybuzz-backend image updated` |
| Rollout | `successfully rolled out` |
| Pod | Running, 0 restarts |
| Health checks | 100% 200 OK |
| Connexion DB | `keybuzz_api_prod@10.0.0.10:5432/keybuzz_prod` |

---

## 5. Backfill PROD

### Scope identifié (avant backfill)

| Métrique | Valeur |
|----------|--------|
| Conversations Amazon totales | 478 |
| Commandes fragmentées | 68 |
| Conversations impliquées | 179 (68 primaires + 111 secondaires) |
| Messages dans secondaires | 204 |

### Résultat backfill

| Métrique | Valeur |
|----------|--------|
| Conversations secondaires traitées | 111 |
| Messages déplacés | 204 |
| Conversations supprimées (vides) | 111 |
| Duplicats restants | **0** |
| Transaction | COMMIT OK |

### État post-backfill

| Métrique | Valeur |
|----------|--------|
| Conversations Amazon | 367 (478 - 111 supprimées) |
| Pending | 80 |
| Open | 18 |
| Resolved | 269 |
| Orders uniques avec order_ref | 299 |

### Échantillon de vérification

Commande `407-0780180-7385966` (pire cas : 5 conversations avant) :
- **Après** : 1 seule conversation, 12 messages fusionnés, status `pending`

---

## 6. Validation produit réelle

URL : `https://client.keybuzz.io`
Compte : `ludo.gonthier@gmail.com` (owner, tenant `ecomlg-001`)

| Vérification | Résultat |
|-------------|---------|
| Connexion PROD | OK via Google OAuth |
| Inbox | 356 conversations affichées |
| Recherche `407-0780180-7385966` | 1 seule conversation (était 5) |
| Messages fusionnés | 12 messages dans le fil chronologique |
| Panneau commande | Détails (1190,25 EUR, LG UltraWideTM, UPS, tracking) |
| Suggestions IA | 2 suggestions actives avec contexte consolidé |
| Statut | Pending (réouvert par backfill) |

---

## 7. Non-régression

| Fonctionnalité | Statut | Preuve |
|----------------|--------|--------|
| Inbox | OK | 356 conversations, filtres fonctionnels |
| Amazon messages | OK | Messages reçus et affichés |
| Suggestions IA | OK | 2 suggestions actives sur conversation fusionnée |
| Orders | OK | 11 849 commandes, 44 en transit, 15 SAV actifs |
| Channels | OK | 5 canaux Amazon connectés (BE, ES, FR, IT, PL) |
| Dashboard | OK | 356 conv, Amazon 99%, SLA 78% |
| Backend pod | OK | Running, 0 restarts |
| API pod | OK | Running, 0 restarts |
| Client pod | OK | Running, 0 restarts |
| Workers | OK | items + orders + outbound + backfill running |
| CronJobs | OK | orders-sync, SLA, outbound-tick completing |
| Shopify | N/A | Non impacté (scope Amazon uniquement) |

---

## 8. Anti-contamination

- 0 fichier Studio : confirmé
- 0 changement hors scope : confirmé (seul `inboxConversation.service.ts`)
- 0 régression détectée : confirmé

---

## 9. GitOps

| Item | Valeur |
|------|--------|
| Manifest modifié | `k8s/keybuzz-backend-prod/deployment.yaml` |
| Commit | `b39fbc3` |
| Message | `PH150: promote Amazon order-centric threading to PROD - Backend v1.0.44-ph150-thread-fix-prod` |
| Push | `dbb3302..b39fbc3 main -> main` |

---

## 10. Verdict final

### AMAZON ORDER-CENTRIC THREADING PROMOTED TO PROD

Le threading conversationnel Amazon centré commande est maintenant actif en PROD :

- **1 commande = 1 conversation** quel que soit le statut
- Les conversations résolues sont rouvertes automatiquement sur nouveau message
- Les 68 commandes fragmentées (111 conversations secondaires) ont été fusionnées
- 204 messages ont été déplacés vers leur conversation principale
- 0 duplicat restant
- L'IA a accès au contexte complet consolidé
- Aucune régression détectée

### Métriques d'impact PROD

| Avant | Après |
|-------|-------|
| 68 commandes fragmentées | 0 duplicat |
| 478 conversations (dont 111 doublons) | 367 conversations (toutes uniques) |
| Messages éparpillés sur 179 conversations | Tous dans leur conversation principale |
| IA avec contexte partiel | IA avec contexte complet |
| Conversations résolues = dossier fermé | Conversations résolues = réouvrables |

### Ce qui n'a PAS été modifié (hors scope)

- Code de l'API (`keybuzz-api`) — inchangé
- Code du client (`keybuzz-client`) — inchangé
- Billing, Agents, Shopify, Amazon OAuth, Autopilot — inchangés
- Workers Amazon (items, orders) — inchangés

---

## STOP

- PROD promue avec succès
- Aucune autre correction effectuée
- Attente validation de Ludovic
