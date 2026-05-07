# PH-SAAS-T8.12AP.2.3.1 — Outbound Author Name PROD QA DB Verify

> **Phase** : PH-SAAS-T8.12AP.2.3.1-OUTBOUND-AUTHOR-NAME-PROD-QA-DB-VERIFY-01
> **Type** : vérification read-only DB + rapport, sans build/deploy/mutation
> **Priorité** : P0
> **Date** : 2026-05-07
> **Ticket** : KEY-266
> **Standard** : CE_PROMPTING_STANDARD appliqué

---

## 1. OBJECTIF

Confirmer côté DB PROD que les nouveaux messages outbound envoyés par Ludovic stockent le vrai nom agent au format `Prénom.N`, et non plus le fallback legacy `KeyBuzz Agent`.

---

## 2. PREFLIGHT READ-ONLY

### Runtime PROD

| Service | Image PROD | Touché par cette phase | Verdict |
|---|---|---|---|
| API | `v3.5.145-outbound-author-name-prod` | Non (read-only) | OK |
| Client | `v3.5.168-outbound-author-name-ux-prod` | Non (read-only) | OK |
| OW | `v3.5.165-escalation-flow-prod` | Non | OK |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | Non | OK |
| Website | `v0.6.9-promo-forwarding-prod` | Non | OK |

Tous les pods Running 1/1, 0 restart.

### Repo

| Repo | Branche | Commit HEAD | Dirty | Action prévue |
|---|---|---|---|---|
| keybuzz-infra | `main` | `847f04a` | Non | Création rapport uniquement |

---

## 3. MESSAGES QA LOCALISÉS

### Contexte
- Tenant : **SWITAA SASU** (`switaa-sasu-mnc1ouqu`)
- Utilisateur : `contact@switaa.com` / **Ludovic GONTHIER** (role: owner dans `switaa-sasu-mn9c3eza`)
- Conversation : `cmmo8oyg4o922ff27e99dc9bf` (subject: "test", channel: amazon, status: open)
- Timestamps capture : `2026-05-07 12:37:18` et `12:38:12` (heure Paris, UTC+2)
- Timestamps UTC : `10:37:18.369Z` et `10:38:12.809Z`

### Messages identifiés

| Message | created_at (UTC) | tenant_id | conversation_id | direction | author_name | source | Verdict |
|---|---|---|---|---|---|---|---|
| `msg-1778150238367-lhg03n4ty` | `2026-05-07T10:37:18.369Z` | `switaa-sasu-mnc1ouqu` | `cmmo8oyg4o922ff27e99dc9bf` | outbound | **`Ludovic.G`** | HUMAN | **PASS** |
| `msg-1778150292807-z0hvs54s5` | `2026-05-07T10:38:12.809Z` | `switaa-sasu-mnc1ouqu` | `cmmo8oyg4o922ff27e99dc9bf` | outbound | **`Ludovic.G`** | HUMAN | **PASS** |

Les deux messages correspondent exactement aux timestamps de la capture Ludovic. Les deux stockent `author_name = Ludovic.G` — le vrai nom de l'agent au format `Prénom.N`.

---

## 4. VÉRIFICATION AUTHOR_NAME

| Critère | Attendu | Observé | Verdict |
|---|---|---|---|
| author_name msg 1 | Prénom.N du vrai agent | `Ludovic.G` | **PASS** |
| author_name msg 2 | Prénom.N du vrai agent | `Ludovic.G` | **PASS** |
| message_source | HUMAN | HUMAN | OK |
| direction | outbound | outbound | OK |
| visibility | public | public | OK |
| UI affiche "Vous" | Oui (capture) | Correspond à author DB | OK |
| UI affiche "Assignée — Ludovic.G" | Oui (capture) | Correspond à author_name DB | OK |

**L'UI et la DB sont alignées.** Le format `Ludovic.G` affiché dans l'assignation correspond au `author_name` stocké en DB.

---

## 5. LEGACY CHECK

| author_name | count | Delta vs AP.2.3 | Mutation | Verdict |
|---|---|---|---|---|
| `KeyBuzz Agent` | **442** | Inchangé (442 en AP.2.3) | 0 | OK |
| `Equipe SAV` | 5 | Inchangé | 0 | OK |
| `Equipe SAV eComLG` | 4 | Inchangé | 0 | OK |
| **`Ludovic.G`** | **2** | **+2 (nouveau)** | 0 UPDATE, 2 nouveaux INSERT | **OK — ce sont les messages QA** |
| `Equipe SAV Test` | 1 | Inchangé | 0 | OK |

Les 442 messages legacy `KeyBuzz Agent` sont strictement inchangés. Les 2 nouveaux messages `Ludovic.G` sont les messages QA de Ludovic — confirmant que le fix fonctionne.

---

## 6. BASELINES PROD INCHANGÉES

| Surface | Avant AP.2.3.1 | Après AP.2.3.1 | Mutation | Verdict |
|---|---|---|---|---|
| API PROD image | `v3.5.145-outbound-author-name-prod` | `v3.5.145-outbound-author-name-prod` | 0 | OK |
| Client PROD image | `v3.5.168-outbound-author-name-ux-prod` | `v3.5.168-outbound-author-name-ux-prod` | 0 | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | 0 | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | 0 | OK |
| Website PROD | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | 0 | OK |
| Manifests | Aucun modifié | Aucun modifié | 0 | OK |
| DB mutation | - | 0 UPDATE, 0 DELETE, 0 migration | 0 | OK |
| Stripe/billing | - | 0 mutation | 0 | OK |
| CAPI/tracking | - | 0 event | 0 | OK |
| Pod restart | - | 0 restart induit | 0 | OK |

---

## 7. INTERPRÉTATION NO-REASK

| Conversation | order_ref connu | Demande commande présente | Verdict no-reask |
|---|---|---|---|
| `cmmo8oyg4o922ff27e99dc9bf` | **NULL** | Non observé dans les body extraits | **OK — pas de régression** |

La conversation "test" n'a pas d'`order_ref` lié. KeyBuzz ne connaît pas de commande pour cette conversation. Si un message demandait un numéro de commande, ce serait légitime dans ce contexte (pas une régression no-reask KEY-256).

Les body extraits montrent des réponses manuelles de Ludovic — pas de demande de numéro de commande observée.

---

## 8. LINEAR

| Ticket | Mise à jour |
|---|---|
| **KEY-266** | **QA PROD VALIDÉE.** Les 2 messages outbound QA de Ludovic stockent `author_name = Ludovic.G` en DB PROD. UI et DB alignées. Legacy inchangé. Recommandation : **fermer KEY-266**. |
| KEY-265 | Lifecycle identity confirmée en PROD. `Assignée — Ludovic.G` dans UI = `Ludovic.G` en DB. |
| KEY-253 | AP.2.3.1 QA validée. Cycle author_name terminé. |
| KEY-267 | Toujours ouvert (assigned_agent_name non retourné par API). |
| KEY-268 | Toujours ouvert (auto-assignment post-reply). |
| KEY-269 | Toujours ouvert (first_name/last_name split). |

---

## 9. PREUVE READ-ONLY

- 0 code modifié
- 0 build
- 0 deploy
- 0 manifest modifié
- 0 kubectl set/patch/edit
- 0 UPDATE/DELETE/INSERT DB exécuté par cette phase
- 0 mutation Stripe/billing/CAPI/tracking
- 0 auto-send IA
- 0 notification externe
- 0 hardcoding tenant/user/seller/email/order/tracking/marketplace/pays
- Seules requêtes DB : SELECT read-only
- Seule action repo : création de ce rapport

---

## 10. VERDICT

### **GO QA DB VERIFIED**

OUTBOUND AUTHOR NAME PROD QA VERIFIED — NEW HUMAN REPLIES STORE REAL AGENT NAME (`Ludovic.G`) — UI ASSIGNMENT `Ludovic.G` MATCHES DB AUTHOR TRUTH — LEGACY 442 × `KeyBuzz Agent` MESSAGES UNCHANGED — NO CODE — NO BUILD — NO DEPLOY — NO MUTATION — READY TO CLOSE KEY-266

STOP
