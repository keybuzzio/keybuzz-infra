# PH-T8.10N-TIKTOK-NATIVE-OWNER-AWARE-PROD-PROMOTION-01 — TERMINÉ

**Verdict : GO STRUCTUREL — CREDENTIALS OFFICIELS PENDING**

> TIKTOK NATIVE OWNER-AWARE LIVE IN PROD — STAGING DESTINATION CONFIGURED — ADMIN VISIBILITY CONFIRMED — DEV SETUP PRESERVED — CLIENT PROD UNCHANGED

---

## Préflight

| Point | Résultat |
|---|---|
| API branche | `ph147.4/source-of-truth` — HEAD `acf5536d` — clean |
| Admin branche | `main` — HEAD `be0d6a2` — clean |
| API DEV | `v3.5.117-tiktok-native-owner-aware-dev` |
| API PROD avant | `v3.5.116-marketing-owner-stack-prod` |
| Admin DEV | `v2.11.15-tiktok-native-owner-aware-dev` |
| Admin PROD avant | `v2.11.14-owner-cockpit-browser-truth-fix-prod` |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` — inchangé |

---

## Source à promouvoir

| Brique | Point vérifié | Résultat |
|---|---|---|
| API | Adapter `tiktok-events.ts` | OK — 3351 bytes |
| API | Dispatch tri-voie `meta_capi / tiktok_events / webhook` | OK |
| API | `sendToTikTokDest` avec retries | OK |
| API | Delivery logs TikTok distincts | OK |
| API | Owner-aware `resolveOutboundRoutingTenantId` | OK |
| Admin | Type `tiktok_events` dans DestinationType | OK |
| Admin | Formulaire : Pixel Code + Access Token + Advertiser ID | OK |
| Admin | Icône + badge TikTok | OK |
| Admin | Test route natif TikTok | OK |

---

## Build PROD

| Service | Tag | Commit source | Digest |
|---|---|---|---|
| API | `v3.5.117-tiktok-native-owner-aware-prod` | `acf5536d` | `sha256:896b5550bb696ec2ea2dc336154c7c8f487ade66bf550510da1b5e623ec748ac` |
| Admin | `v2.11.15-tiktok-native-owner-aware-prod` | `be0d6a2` | `sha256:663b1dcbaaace1369cc429756bea3bea5cb41507ceecc509f5d0a31dc7ece6ac` |

Build-from-git : repos clean, `--no-cache`, tags immuables.

---

## GitOps PROD

| Manifest | Image avant | Image après |
|---|---|---|
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.116-marketing-owner-stack-prod` | `v3.5.117-tiktok-native-owner-aware-prod` |
| `k8s/keybuzz-admin-v2-prod/deployment.yaml` | `v2.11.14-owner-cockpit-browser-truth-fix-prod` | `v2.11.15-tiktok-native-owner-aware-prod` |

Commit infra : `9ebb879` — pushé sur `main`.

### Rollback PROD

```
API  → v3.5.116-marketing-owner-stack-prod
Admin → v2.11.14-owner-cockpit-browser-truth-fix-prod
```

---

## Déploiement PROD

| Service | Pod | Status | Image runtime | Health |
|---|---|---|---|---|
| API PROD | `keybuzz-api-7744b75cb7-hqbs6` | Running, 0 restarts | `v3.5.117-tiktok-native-owner-aware-prod` | HTTP 200 OK |
| Admin PROD | `keybuzz-admin-v2-7598bb4588-m8rtd` | Running, 0 restarts | `v2.11.15-tiktok-native-owner-aware-prod` | Running |

Méthode : `kubectl apply -f` sur manifests SCP depuis infra locale. Pas de `kubectl set image`.

---

## Configuration officielle KBC PROD

### Diagnostic credentials

| Source | Résultat |
|---|---|
| K8s secrets TikTok | Aucun |
| Vault | DOWN depuis jan 2026 |
| `ad_account_credentials` table | N'existe pas en PROD |
| Variables d'env TikTok | Aucune |

**Aucune source automatisée de credentials TikTok n'est disponible.**

### Destination créée (staging)

| Champ | Valeur |
|---|---|
| ID | `d5832725-060e-4e10-8969-3043fa3f4745` |
| Tenant | `keybuzz-consulting-mo9zndlk` |
| Type | `tiktok_events` |
| Nom | `TikTok PROD Staging — Credentials Pending` |
| Endpoint | `https://business-api.tiktok.com/open_api/v1.3/event/track/` (auto-résolu) |
| Active | **false** (désactivée en attendant credentials officiels) |
| Pixel Code | Placeholder (non exposé) |
| Access Token | Placeholder — masqué dans l'API |
| Advertiser ID | Placeholder |

### Action requise opérateur

L'opérateur doit :
1. Accéder à TikTok Events Manager
2. Récupérer le Pixel Code (Event Source ID) et l'Access Token
3. Mettre à jour la destination via l'Admin UI `https://admin.keybuzz.io` → Marketing → Destinations
4. Activer la destination

---

## Validation test route

| Point vérifié | Attendu | Résultat |
|---|---|---|
| Handler natif TikTok utilisé | `destination_type: tiktok_events` | **OK** |
| Endpoint TikTok API contacté | HTTP vers TikTok | **OK** — HTTP 401, `tiktok_code: 40105` |
| Delivery log PROD créé | event_id présent | **OK** — `test_keybuzz-consulting-mo9zndlk_1777107263650` |
| Erreur attendue | Token placeholder | **OK** — `Access token is incorrect or has been revoked` |
| Event_id format | préfixe `test_` | **OK** |

La test route prouve que le handler TikTok natif est déployé et fonctionnel en PROD, que la requête atteint l'API TikTok Events, et qu'un delivery log est créé.

---

## Validation owner-aware PROD

| Cas | Attendu | Résultat |
|---|---|---|
| Metrics owner scope | HTTP 200, scope=owner | **OK** |
| Funnel metrics owner | HTTP 200 | **OK** |
| Funnel events owner | HTTP 200 | **OK** |
| Owner-mapped children PROD | ≥1 enfant | **OK** — `test-owner-runtime-p-modeeozl` |
| Destinations KBC PROD | Meta + TikTok | **OK** |
| TikTok éligible au lookup owner | Présente dans la liste | **OK** (quand activée) |
| Business event PROD | Non déclenché | **Note** — destination inactive |

---

## Validation navigateur PROD

| Test | Attendu | Résultat |
|---|---|---|
| Destinations KBC visibles (API) | Meta CAPI + TikTok | **OK** — 2 destinations |
| TikTok secret masqué | Token redacté | **OK** — `PE...EN` |
| TikTok test status | failed (placeholder) | **OK** |
| Meta CAPI active | active=true, test=success | **OK** |
| Delivery logs TikTok | 1 log test | **OK** |
| Tenant guard forgé | 403 | **OK** |
| Login visuel Admin PROD | Nécessite mot de passe opérateur | **Pending** — à vérifier par l'opérateur |

---

## Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| Health API PROD | HTTP 200 | **OK** |
| Meta CAPI PROD | active, test=success | **OK** |
| All dest types PROD | meta_capi + tiktok_events | **OK** |
| `/marketing/metrics` owner PROD | HTTP 200 | **OK** |
| `/marketing/funnel` owner PROD | HTTP 200 | **OK** |
| Tenant guard PROD | 403 forgé | **OK** |
| Client PROD inchangé | `v3.5.116-marketing-owner-stack-prod` | **OK** |
| API DEV inchangé | `v3.5.117-tiktok-native-owner-aware-dev` | **OK** |
| Admin DEV inchangé | `v2.11.15-tiktok-native-owner-aware-dev` | **OK** |
| DEV TikTok destination non supprimée | `2e8803be` active | **OK** |

---

## Digests

| Service | Tag | Digest |
|---|---|---|
| API PROD | `v3.5.117-tiktok-native-owner-aware-prod` | `sha256:896b5550bb696ec2ea2dc336154c7c8f487ade66bf550510da1b5e623ec748ac` |
| Admin PROD | `v2.11.15-tiktok-native-owner-aware-prod` | `sha256:663b1dcbaaace1369cc429756bea3bea5cb41507ceecc509f5d0a31dc7ece6ac` |

---

## Gaps restants

| Gap | Description | Action requise |
|---|---|---|
| Credentials TikTok officiels | Aucune source automatisée. Destination inactive avec placeholders | Opérateur : mettre à jour via Admin UI avec valeurs TikTok Events Manager |
| TikTok Pixel browser PROD | `NEXT_PUBLIC_TIKTOK_PIXEL_ID` non configuré dans le build Client | Phase client séparée si nécessaire |
| Business event PROD TikTok | Aucun StartTrial/Purchase déclenché (destination inactive) | Automatique dès activation credentials |
| Sync spend TikTok Ads | Non traité | Phase dédiée |
| Google/LinkedIn | Non traités | Hors scope |
| Validation visuelle Admin PROD | Mot de passe opérateur non accessible au CE | Opérateur : vérifier `/marketing/destinations` |

---

## Conclusion

### Verdict : GO STRUCTUREL — CREDENTIALS OFFICIELS PENDING

Le pipeline TikTok natif owner-aware est **live en PROD** :

1. **API déployée** — handler `tiktok_events` natif, dispatch tri-voie, retries, logs delivery distincts
2. **Admin déployée** — formulaire TikTok, badge, icône, test route, listing
3. **Test route prouvée** — requête atteint l'API TikTok Events, delivery log PROD créé
4. **Owner-aware intact** — metrics, funnel, destinations, tenant guard, tout fonctionnel
5. **Meta CAPI intact** — active, last_test=success
6. **Destination staging créée** — type `tiktok_events`, désactivée, credentials placeholder
7. **Non-régression totale** — Meta, webhooks, owner cockpit, tenant guard, DEV préservé

**Le seul élément manquant** est la mise à jour des credentials officiels TikTok par l'opérateur. Dès que les credentials sont configurés et la destination activée, le pipeline sera immédiatement opérationnel pour les business events owner-aware.

### Actions opérateur requises

1. Se connecter à `https://admin.keybuzz.io`
2. Aller dans Marketing → Destinations
3. Éditer la destination `TikTok PROD Staging — Credentials Pending`
4. Renseigner le Pixel Code et l'Access Token depuis TikTok Events Manager
5. Activer la destination
6. Relancer un test pour confirmer le succès

---

## Client PROD inchangé

Oui — `v3.5.116-marketing-owner-stack-prod`

## DEV non supprimé

Oui — destination DEV `2e8803be` active, API/Admin DEV inchangés

## Chemin rapport

`keybuzz-infra/docs/PH-T8.10N-TIKTOK-NATIVE-OWNER-AWARE-PROD-PROMOTION-01.md`
