# PH-T8.11V — Google Ads Conversion Measurement — Config Only

> **Date** : 28 avril 2026
> **KEY** : KEY-210
> **Objectif** : Finaliser la mesure des conversions Google Ads / YouTube sans installer le snippet `AW-18098643667`
> **Prérequis** : PH-T8.11U (diagnostic tag Google Ads)

---

## 1. Préflight

| Élément | Valeur |
|---|---|
| API PROD | `v3.5.123-linkedin-capi-native-prod` |
| Admin PROD | `v2.11.21-marketing-surfaces-truth-alignment-prod` |
| Client PROD | `v3.5.121-linkedin-tracking-hardened-prod` |
| Website PROD | `v0.6.6-tiktok-ttclid-prod` |
| Rapport PH-T8.11U | Disponible |
| Code PROD modifié | **Non** |

---

## 2. Diagnostic Google Ads

### Compte Google Ads
- Customer ID : `5947963982`
- Conversion ID : `AW-18098643667`
- Accès console : Ludovic (vérification manuelle requise)

### Destinations de conversion existantes en PROD

| Type | Nom | Actif | Dernier test |
|---|---|---|---|
| `meta_capi` | KeyBuzz Consulting — Meta CAPI | ✅ | success (23 avr) |
| `tiktok_events` | KeyBuzz Consulting — TikTok | ✅ | success (25 avr) |
| `linkedin_capi` | KeyBuzz Consulting — LinkedIn CAPI | ✅ | success (27 avr) |
| `google_ads` | — | **AUCUNE** | — |

### Delivery logs résumé

| Platform | Event | Status | Count |
|---|---|---|---|
| LinkedIn CAPI | StartTrial | success | 1 |
| Meta CAPI | StartTrial | delivered | 2 |
| Meta CAPI | PageView | success/failed | 1/3 |
| TikTok Events | StartTrial | delivered | 2 |
| TikTok Events | ViewContent | success/failed | 1/1 |
| **Google Ads** | **—** | **—** | **0** |

---

## 3. Diagnostic sGTM / Addingwell

### sGTM `t.keybuzz.pro`
- Health : `200 ok` ✅
- GA4 ID routé : `G-R3QQDYEBFG`
- Google Ads Conversion tag existant : **NON** (aucun tag `AW-` dans le website ni le sGTM)

### GA4 sur le website (`www.keybuzz.pro`)
- Script chargé : `https://t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG` ✅
- Configuration : `server_container_url: 'https://t.keybuzz.pro'` ✅
- Cross-domain : `linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }` ✅
- Événements envoyés : **pageview uniquement** (pas de conversion events)
- Pixels présents : Meta `1234164602194748`, TikTok `D7HQO0JC77U2ODPGMDI0`
- Google Ads `AW-` : **absent** (volontaire, confirmé PH-T8.11U)

### GA4 sur le client (`client.keybuzz.io`)
- **GA4 NON CHARGÉ** — aucun script `gtag/js`, aucun `G-R3QQDYEBFG` dans le code
- Module tracking **prêt mais inactif** (module 69064)
- Guard : `if(!window.gtag) return` → tous les events GA4 sont silencieusement ignorés

### Module tracking client (module 69064) — code existant, inactif

| Fonction exportée | GA4 Event | Meta Event | TikTok Event |
|---|---|---|---|
| `i(plan, cycle)` | `signup_start` | `Lead` | `SubmitForm` |
| `u(step, plan)` | `signup_step` | — | — |
| `s(plan, cycle, tenantId)` | `signup_complete` | `CompleteRegistration` | — |
| `c(plan, cycle, value)` | `begin_checkout` | `InitiateCheckout` | `InitiateCheckout` |
| `l(e)` | `purchase` | `Purchase` | `CompletePayment` |

> **Observation** : Les fonctions Meta (`window.fbq`) et TikTok (`window.ttq`) sont dans la même situation — silencieusement ignorées si les pixels ne sont pas chargés côté client. Seul le pipeline server-side (CAPI) fonctionne pour Meta, TikTok, et LinkedIn.

---

## 4. Attribution gclid — ce qui fonctionne

```sql
SELECT COUNT(*) as total, COUNT(gclid) as with_gclid FROM signup_attribution;
-- total: 9, with_gclid: 3, utm_source=google: 3
```

| tenant_id | utm_source | utm_medium | gclid | owner_tenant_id | date |
|---|---|---|---|---|---|
| test-codex-checkout-* | google | cpc | test-gclid-manual-pr... | keybuzz-consulting-* | 25 avr |
| codex-google-legacy-* | google | cpc | test-gclid-codex-pro... | null | 25 avr |
| codex-google-owner-* | google | cpc | test-gclid-codex-pro... | keybuzz-consulting-* | 25 avr |

→ Le `gclid` est capturé, l'attribution Google est fonctionnelle dans KeyBuzz, le routing owner-aware est actif (2/3 avec `marketing_owner_tenant_id`).

---

## 5. Analyse des options

### Option A — sGTM Google Ads Conversion tag

| Critère | Évaluation |
|---|---|
| Faisabilité | **NON** sans code change |
| Raison | Le sGTM ne reçoit que des pageviews du website. Les conversions (signup, purchase) se produisent sur `client.keybuzz.io` qui n'a pas GA4 chargé. Le sGTM ne voit jamais ces événements. |
| Prérequis | Charger GA4 (`G-R3QQDYEBFG` via `t.keybuzz.pro`) dans le layout du client → **modification client interdite** |
| Risque doublon | Aucun (pas de GA4 client) |

### Option B — Import GA4 conversions → Google Ads

| Critère | Évaluation |
|---|---|
| Faisabilité | **NON** sans code change |
| Raison | GA4 ne contient que des pageviews. Les événements de conversion (`signup_complete`, `purchase`) ne sont jamais envoyés car GA4 n'est pas chargé sur le client. Rien à importer. |
| Prérequis | Charger GA4 sur le client → **modification client interdite** |
| Risque doublon | Aucun (rien à importer) |

### Option C — No change volontaire ✅

| Critère | Évaluation |
|---|---|
| Faisabilité | **OUI** — aucune modification requise |
| Impact | Google Ads affiche 0 conversions (correct et honnête) |
| YouTube | Diffusion non impactée (confirmé PH-T8.11U) |
| Attribution | `gclid` capturé → visible dans KeyBuzz Admin |
| Pipeline existant | Meta CAPI, TikTok Events API, LinkedIn CAPI fonctionnent correctement |
| Cohérence | Google Tracking Admin (`/marketing/google-tracking`) déjà documenté comme "via sGTM" |

---

## 6. Décision

### **OPTION C RETENUE — No change volontaire**

Le diagnostic révèle un prérequis manquant commun aux options A et B : **GA4 n'est pas chargé sur le client app**. Le module tracking existe (5 fonctions prêtes) mais est silencieusement inactif. Charger GA4 sur le client constitue une modification du client, explicitement interdite dans cette phase.

---

## 7. Plan d'action futur (hors scope PH-T8.11V)

### Phase future recommandée : PH-GA4-CLIENT-ACTIVATION

**Étape 1 — Activer GA4 sur le client** (code change `keybuzz-client`)
- Charger `https://t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG` dans `app/layout.tsx`
- Configurer `server_container_url: 'https://t.keybuzz.pro'`
- Le module tracking (module 69064) s'activera automatiquement
- GA4 recevra : `signup_start`, `signup_step`, `signup_complete`, `begin_checkout`, `purchase`
- Cross-domain déjà configuré côté website → liaison automatique

**Étape 2 — Importer GA4 → Google Ads** (config externe)
- Lier GA4 `G-R3QQDYEBFG` au compte Google Ads `5947963982` (dans GA4 Admin → Google Ads Linking)
- Créer les conversion actions dans Google Ads si absentes
- Importer `signup_complete` comme `StartTrial` et `purchase` comme `Purchase`
- Délai données : ~24h (standard pour import GA4)

**Alternative future — Google Ads Offline Conversions API**
- Créer un destination type `google_ads_offline` dans `outbound_conversion_destinations`
- Utiliser le `gclid` capturé dans `signup_attribution` pour envoyer les conversions via l'API Google Ads Customer Match / Offline Conversions
- Avantage : temps réel, cohérent avec Meta CAPI / TikTok Events / LinkedIn CAPI
- Complexité : plus élevée (OAuth Google Ads API, refresh tokens)

---

## 8. Validation anti-doublon

| Vérification | Résultat |
|---|---|
| Destinations Google Ads dans DB | 0 — aucune destination |
| Delivery logs Google Ads | 0 — aucun event envoyé |
| Tag `AW-` sur le website | 0 fichiers — absent |
| Tag `AW-` sur le client | 0 fichiers — absent |
| GA4 events de conversion dans GA4 | 0 — GA4 non chargé sur le client |
| `/marketing/google-tracking` cohérent | ✅ — documente "via sGTM" sans faux signal |
| `/metrics` faux signal | ✅ — pas de faux signal Google Ads |

**Risque de double conversion : ZÉRO** — il n'existe aucune conversion Google Ads à dupliquer.

---

## 9. Code PROD inchangé

| Service | Avant | Après | Modifié |
|---|---|---|---|
| API PROD | `v3.5.123-linkedin-capi-native-prod` | `v3.5.123-linkedin-capi-native-prod` | **Non** |
| Admin PROD | `v2.11.21-marketing-surfaces-truth-alignment-prod` | `v2.11.21-marketing-surfaces-truth-alignment-prod` | **Non** |
| Client PROD | `v3.5.121-linkedin-tracking-hardened-prod` | `v3.5.121-linkedin-tracking-hardened-prod` | **Non** |
| Website PROD | `v0.6.6-tiktok-ttclid-prod` | `v0.6.6-tiktok-ttclid-prod` | **Non** |

---

## 10. KEY-210 — Mise à jour

| Champ | Valeur |
|---|---|
| Chemin choisi | **Option C — No change volontaire** |
| Conversion actions trouvées | Aucune vérifiable (accès console requis) |
| Labels sGTM utilisés | Aucun (option non retenue) |
| Import GA4 | Non applicable (GA4 non chargé sur le client) |
| Validation anti-doublon | ✅ Zéro risque (aucune conversion existante) |
| Code PROD inchangé | ✅ Confirmé |
| Blocage technique | GA4 non chargé sur `client.keybuzz.io` — prérequis pour toute option |
| Phase future | PH-GA4-CLIENT-ACTIVATION (activer GA4 client + import conversions) |

---

## 11. Verdict final

```
OPTION C — NO CHANGE VOLONTAIRE — GO
```

| Critère | Statut |
|---|---|
| Google Ads conversion measurement | ⏳ Reporté (prérequis : GA4 client) |
| YouTube diffusion | ✅ Non impactée |
| gclid capture | ✅ Fonctionnel (3 attributions) |
| Owner-aware routing | ✅ Intact |
| Anti-doublon | ✅ Zéro risque |
| Code PROD | ✅ Inchangé |
| Surfaces Admin | ✅ Cohérentes |
| Pipeline Meta/TikTok/LinkedIn | ✅ Opérationnels |

**Diagnostic additionnel révélé** : Le module tracking client (module 69064) est prêt mais 100% inactif. L'activation de GA4 sur le client dans une future phase débloquera simultanément :
- Les événements GA4 de conversion (import → Google Ads)
- Les événements GA4 de funnel (analytics enrichi)
- Le cross-domain tracking (déjà configuré côté website)

Aucune modification de code n'a été effectuée. Aucune configuration externe n'a été appliquée.
