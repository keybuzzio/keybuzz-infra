# PH-ADMIN-T8.8H — KBC Meta CAPI Outbound Real Config Validation

**Phase** : PH-ADMIN-T8.8H-KBC-META-CAPI-OUTBOUND-REAL-CONFIG-VALIDATION-01
**Date** : 2026-04-23
**Environnement** : PROD
**Type** : Configuration + Validation reelle Meta CAPI pour KeyBuzz Consulting
**Priorite** : P0

---

## 1. OBJECTIF

Configurer et valider la destination Meta CAPI reelle pour le tenant KeyBuzz Consulting en PROD.
Envoyer un test `PageView` (pas `StartTrial` ni `Purchase`).
Verifier token safety, delivery logs, non-regression metrics.

---

## 2. PREFLIGHT

| Element | Valeur |
|---|---|
| Admin PROD | `v2.11.6-metrics-currency-cac-controls-prod` |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` |
| Tenant KBC | `keybuzz-consulting-mo9zndlk` |
| KBC Spend baseline | `445 GBP` |
| Destinations KBC avant | **0** (aucune) |
| Delivery Logs KBC avant | **0** (aucun) |
| URL Admin | `https://admin.keybuzz.io` |

---

## 3. CREDENTIALS META CAPI

| Parametre | Valeur | Source |
|---|---|---|
| Pixel ID | `1234164602194748` | Meta Events Manager |
| Access Token | `EAAe...18gt` (masque) | Meta Business Manager |
| Test Event Code | `TEST66800` | Events Manager |
| Account ID | `1485150039295668` | Meta Ads Account KBC |

> Source credentials : phase PH-T8.7B.1 (validation reelle DEV).

---

## 4. CREATION DESTINATION

| Etape | Resultat |
|---|---|
| Navigation | `/marketing/destinations` — KBC selectionne |
| Etat initial | "Aucune destination" |
| Type selectionne | **Meta CAPI** |
| Nom | `KeyBuzz Consulting — Meta CAPI` |
| Pixel ID | `1234164602194748` |
| Token | Saisi (champ password) |
| Account ID | `1485150039295668` |
| Bouton "Creer" | Clic → "Creation..." → Succes |

### Destination creee

| Champ | Valeur |
|---|---|
| Nom | KeyBuzz Consulting — Meta CAPI |
| Type | `meta_capi` |
| Badges | **Meta CAPI** / **Actif** |
| Pixel | `1234164602194748` |
| Token affiche | `EA*****...` (masque — defense-in-depth) |
| Endpoint auto-genere | `https://graph.facebook.com/v21.0/1234164602194748/events` |
| Date creation | 23/04/2026 17:12:33 |

---

## 5. TEST PAGEVIEW META CAPI

| Etape | Resultat |
|---|---|
| Bouton "Test PageView Meta" | Clique |
| test_event_code | `TEST66800` |
| Bouton "Envoyer" | Clique |
| Reponse | **Test reussi (HTTP 200)** |
| Meta response | **events_received: 1** |
| Badge apres test | `Test: success` |
| Dernier test | 23/04/2026 17:13:03 |

### Event envoye

- **event_name** : `PageView` (pas StartTrial, pas Purchase)
- **action_source** : `website`
- **test_event_code** : `TEST66800` (event visible dans Meta Events Manager mais non comptabilise comme reel)

---

## 6. DELIVERY LOGS

| Filtre | Resultat |
|---|---|
| Tous les evenements | **1 log** : PageView / KBC Meta CAPI / Livre / HTTP 200 / 23/04 17:13:03 |
| StartTrial | **0 log** — "Aucun log" |
| Purchase | **0 log** — "Aucun log" |
| SubscriptionRenewed | **0 log** |
| SubscriptionCancelled | **0 log** |

**VERDICT** : Seul le PageView de test est present. Aucun business event n'a ete envoye.

---

## 7. NON-REGRESSION METRICS

| Metrique | Valeur | Baseline |
|---|---|---|
| Spend total (GBP) | **445 GBP** | 445 GBP |
| New customers | 0 | 0 |
| MRR (GBP) | 0 GBP | 0 GBP |
| CAC paid | — | — |
| ROAS | — | — |
| Bouton "Inclus dans le CAC" | Visible (Super Admin) | OK |

**VERDICT** : Aucune alteration des metriques. Spend KBC stable a 445 GBP.

---

## 8. TOKEN SAFETY

### Console browser

| Check | Resultat |
|---|---|
| Token `EAA...` dans console | **0 occurrence** |
| `access_token` dans console | **0 occurrence** |
| `platform_token_ref` dans console | **0 occurrence** |
| Messages console | Uniquement `[next-auth]` (pre-existant) et `[CursorBrowser]` |

### Network requests

| Check | Resultat |
|---|---|
| Token dans URLs | **0** |
| Requete directe `graph.facebook.com` | **0** (test passe par proxy serveur) |
| Appel destinations | `GET /api/admin/marketing/destinations?tenantId=keybuzz-consulting-mo9zndlk` (HTTP 200, sans token) |

### DOM / UI

| Check | Resultat |
|---|---|
| Token affiche | `EA*****...` (masque) |
| Champ token en clair | Non (type password a la creation, masque apres) |
| Pixel ID visible | Oui (ID public Meta, pas sensible) |

**VERDICT** : Token safety OK. Aucune fuite dans console, network, ou DOM.

---

## 9. ETAT FINAL DESTINATION

| Champ | Valeur |
|---|---|
| Nom | KeyBuzz Consulting — Meta CAPI |
| Statut | **Actif** |
| Type | `meta_capi` |
| Pixel | `1234164602194748` |
| Token | Masque (`EA*****...`) |
| Endpoint | `https://graph.facebook.com/v21.0/1234164602194748/events` |
| Account ID | `1485150039295668` |
| Dernier test | 23/04/2026 17:13:03 |
| Resultat test | **success** (HTTP 200, events_received: 1) |
| Date creation | 23/04/2026 17:12:33 |
| Business events envoyes | **0** (seul PageView de test) |

---

## 10. INTERDICTIONS RESPECTEES

| Interdiction | Respectee |
|---|---|
| Pas de code modifie | OUI |
| Pas de build | OUI |
| Pas de deploy | OUI |
| Pas de kubectl set image/env/edit/patch | OUI |
| Configuration via Admin UI uniquement | OUI |
| Pas de StartTrial/Purchase envoye | OUI |
| Pas de token brut dans UI/logs/rapport | OUI |
| Pas de modification Webflow/DNS | OUI |
| GitOps strict | OUI (aucune modification infra) |

---

## 11. VERDICT FINAL

**KBC META CAPI OUTBOUND DESTINATION CONFIGURED AND VALIDATED IN PROD**

- Destination `meta_capi` creee pour KeyBuzz Consulting
- Test `PageView` reussi (HTTP 200, events_received: 1)
- Token masque partout (UI, console, network, rapport)
- 0 business events envoyes (StartTrial, Purchase)
- Metrics KBC inchangees (445 GBP)
- Delivery logs propres (1x PageView seul)

---

## 12. PROCHAINES ETAPES

1. **Activer les business events reels** : quand le premier vrai `StartTrial` ou `Purchase` sera declenche par le SaaS, il sera automatiquement route vers cette destination Meta CAPI
2. **Verifier dans Meta Events Manager** : le PageView de test avec `TEST66800` doit etre visible dans l'onglet "Test events"
3. **Optionnel** : creer une destination pour eComLG si necessaire
4. **Monitoring** : surveiller les delivery logs pour les premiers events reels
