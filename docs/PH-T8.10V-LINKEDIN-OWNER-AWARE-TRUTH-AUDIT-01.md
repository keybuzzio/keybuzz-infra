# PH-T8.10V-LINKEDIN-OWNER-AWARE-TRUTH-AUDIT-01 — TERMINÉ

**Verdict : GO PARTIEL — LinkedIn peut lancer avec workaround acceptable**

> Date : 2026-04-26
> Environnement : DEV + lecture PROD
> Type : audit vérité LinkedIn owner-aware pour readiness acquisition KeyBuzz
> Priorité : P0

## KEY

**KEY-188** — audit vérité LinkedIn owner-aware pour vérifier si LinkedIn est réellement prêt pour les campagnes KeyBuzz qui doivent démarrer dans les prochains jours.

---

## Préflight

| Point | Valeur |
|---|---|
| Client bastion branche | `ph148/onboarding-activation-replay` |
| API bastion branche | `ph147.4/source-of-truth` |
| Admin branche | `main` (`aef2be2`) |
| API DEV | `v3.5.119-google-observability-dev` |
| API PROD | `v3.5.118-google-sgtm-owner-aware-quick-win-prod` |
| Client DEV | `v3.5.112-marketing-owner-mapping-foundation-dev` |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` |
| Admin PROD | `v2.11.16-google-admin-visibility-prod` |

---

## Client

### Attribution (`src/lib/attribution.ts`)

| Sujet | État |
|---|---|
| UTMs capturés (`utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`) | **OK** — `utm_source=linkedin` fonctionne |
| `gclid` (Google) | **Capturé** |
| `fbclid` / `fbc` / `fbp` (Meta) | **Capturé** |
| `ttclid` (TikTok) | **Capturé** |
| `li_fat_id` (LinkedIn) | **ABSENT** — pas dans `CLICK_ID_PARAMS`, pas dans `AttributionContext`, pas dans `captureAttribution()` |
| `marketing_owner_tenant_id` | **Capturé** depuis URL — coexiste avec tous les paramètres |
| Attribution survit OAuth/Stripe/refresh | **OK** — sessionStorage + localStorage backup 30min |

### LinkedIn Insight Tag (`src/components/tracking/SaaSAnalytics.tsx`)

| Sujet | État |
|---|---|
| Code source | **EXISTE** — Partner ID `9969977`, `snap.licdn.com/insight.min.js` (L140-154) |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` dans manifests K8s | **ABSENT** — pas dans aucun deployment.yaml |
| Insight Tag dans bundle compilé PROD | **ABSENT** — aucun match `snap.licdn.com` dans le JS compilé |
| Insight Tag actif | **NON** — le code existe mais n'est jamais rendu car le Partner ID est vide au build time |

### Conclusion Client

LinkedIn est **partiellement couvert** via les UTMs génériques. Le click ID LinkedIn (`li_fat_id`) n'est pas capturé. L'Insight Tag est du code mort : présent dans la source mais inactif faute de `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` au build time.

---

## API / Attribution

### Schema `signup_attribution` (PROD, 23 colonnes)

```
id, tenant_id, user_email,
utm_source, utm_medium, utm_campaign, utm_term, utm_content,
gclid, fbclid, fbc, fbp, gl_linker,
plan, cycle, landing_url, referrer,
attribution_id, stripe_session_id, conversion_sent_at, created_at,
ttclid, marketing_owner_tenant_id
```

**`li_fat_id` est ABSENT du schéma.**

### Persistance attribution (`tenant-context-routes.ts` L708-730)

L'INSERT dans `signup_attribution` persiste : UTMs, gclid, fbclid, fbc, fbp, gl_linker, ttclid, marketing_owner_tenant_id.
**Aucun champ LinkedIn-spécifique** — seuls les UTMs couvrent LinkedIn.

### SHA256 email hash (`billing/routes.ts` L1926-1929)

```typescript
// PH-T7.3.2: SHA256 email hash for LinkedIn CAPI via sGTM
params.sha256_email_address = crypto.createHash('sha256')
  .update(userEmail.toLowerCase().trim())
  .digest('hex');
```

**ACTIF EN PROD** — le hash SHA256 de l'email utilisateur est envoyé dans le payload GA4 MP vers sGTM. Ce champ est exploitable par un futur tag LinkedIn CAPI dans sGTM.

### Pipeline outbound conversions

| Sujet | État |
|---|---|
| `linkedin_capi` dans `DESTINATION_TYPES` | **OUI** (L15 de `routes.ts`) |
| Adapter natif LinkedIn CAPI | **ABSENT** — seuls `meta-capi.ts` et `tiktok-events.ts` existent |
| Comportement `linkedin_capi` | Tombe dans le fallback `else` → traité comme webhook générique |
| Émission dans `emitter.ts` | Dispatch : `meta_capi` → adapter Meta, `tiktok_events` → adapter TikTok, **tout le reste** → webhook |

### Owner-aware LinkedIn

Le pipeline `emitConversionWebhook` (L1861-1903) inclut depuis PH-T8.10P :
- `routing_tenant_id` — pointe vers l'owner KBC si applicable
- `marketing_owner_tenant_id` — identifie l'owner
- `owner_routed` — booléen true/false

**LinkedIn bénéficie automatiquement de ce routing owner-aware** puisque le pipeline sGTM reçoit ces champs pour TOUS les événements `purchase`, quelle que soit la source d'acquisition.

### Metrics LinkedIn (`metrics/routes.ts` L25)

`linkedin: 'EUR'` dans `CHANNEL_CURRENCIES` — l'affichage ad spend est prêt si des données existent.

### Conclusion API

Le SHA256 email est actif et prêt pour CAPI. Le type `linkedin_capi` est autorisé mais sans adapter natif. L'owner-aware couvre LinkedIn via le pipeline sGTM existant. Le champ `li_fat_id` manque dans le schéma DB et l'INSERT.

---

## Admin

| Surface Admin | LinkedIn utile aujourd'hui ? | Gap |
|---|---|---|
| Metrics / Ad Spend | Prêt visuellement (`#0A66C2`, texte "LinkedIn Ads") | Pas de données — aucun import ad spend LinkedIn actif |
| Destinations | `linkedin_capi` autorisé comme type | Pas d'adapter natif, pas de surface UI dédiée |
| Ad Accounts | N/A | Page inexistante |
| Integration Guide | Aucune mention LinkedIn | LinkedIn absent du guide |
| Funnel / Metrics owner-scoped | OK si données existent | Pas de source spécifique |

### Conclusion Admin

LinkedIn n'a pas de surface fonctionnelle dans l'Admin. Seuls des textes préparatoires (couleur canal, empty states) existent. L'absence de surface Admin n'est PAS bloquante pour un lancement — le cockpit owner-scoped affiche déjà les leads par `utm_source`.

---

## Vérité end-to-end

| Question | Réponse | Preuve |
|---|---|---|
| Un clic LinkedIn Ads peut-il être capturé proprement ? | **PARTIELLEMENT** — UTMs oui, `li_fat_id` non | `attribution.ts` : `CLICK_ID_PARAMS = ['gclid','fbclid','ttclid']` |
| Le lead remonte-t-il dans le cockpit owner KBC ? | **OUI** | `emitConversionWebhook` : `routing_tenant_id` + `owner_routed` dans payload sGTM |
| Une conversion business peut-elle être renvoyée à LinkedIn ? | **NON aujourd'hui** | CAPI token non disponible, tag sGTM non configuré (PH-T7.3.3 : WAIT) |
| Un workaround acceptable existe-t-il ? | **OUI** | Pipeline sGTM prêt architecturalement, SHA256 email déjà envoyé, plan sGTM documenté |
| Suffisant pour lancer dans quelques jours ? | **OUI pour attribution inbound, NON pour feedback conversion** | UTMs OK, cockpit OK. Optimisation campagne LinkedIn aveugle. |

### Architecture actuelle du flux LinkedIn

```
[Clic LinkedIn Ad] → /register?utm_source=linkedin&utm_medium=cpc&...
     ↓
[Client] → captureAttribution() → UTMs capturés, li_fat_id NON capturé
     ↓
[Signup] → POST /tenant-context/create-signup
     ↓
[API] → INSERT signup_attribution (utm_source='linkedin', ...)
     ↓                                                    
[API] → SET tenants.marketing_owner_tenant_id (si owner dans URL)
     ↓
[Stripe Checkout] → checkout.session.completed
     ↓
[API] → emitConversionWebhook()
  → SELECT signup_attribution (utm_source, user_email, ...)
  → SHA256(user_email) → sha256_email_address
  → routing_tenant_id = owner KBC          ✅
  → marketing_owner_tenant_id = owner KBC  ✅
  → owner_routed = true                    ✅
     ↓
[sGTM] POST https://t.keybuzz.io/mp/collect
  ├── GA4 Tag              → Google Analytics  ✅
  ├── Meta CAPI Tag        → Facebook          ✅
  ├── TikTok Events API    → TikTok            ✅
  └── LinkedIn CAPI Tag    → LinkedIn           ⏳ NON CONFIGURÉ
       → Bloqué par : token CAPI non disponible
       → SHA256 email : prêt dans le payload
       → Conversion Rule ID : 27491233 (documenté)
```

---

## Impact lancement KeyBuzz

| Scénario | Verdict | Impact |
|---|---|---|
| **A — Prêt sans changement** | **NON** | Insight Tag inactif, CAPI non configuré, `li_fat_id` absent |
| **B — Workaround raisonnable** | **OUI** | UTMs fonctionnent, cockpit owner OK, analyse manuelle CPA/ROAS possible |
| **C — Risque réel** | **Partiel** | Optimisation campagne aveugle sans CAPI. Pas bloquant pour un lancement initial, bloquant pour un scale sérieux. |

### Ce qui fonctionne déjà sans changement

1. **Attribution UTM** : un clic LinkedIn avec `utm_source=linkedin` est capturé, persisté, et visible dans le cockpit
2. **Owner-aware routing** : le tenant enfant est correctement routé vers l'owner KBC dans le pipeline sGTM
3. **SHA256 email** : déjà envoyé dans le payload sGTM, prêt pour CAPI dès que le token est disponible
4. **Architecture prête** : `linkedin_capi` est un type de destination autorisé

### Ce qui manque

1. **Insight Tag** : code mort — nécessite 1 rebuild client avec `--build-arg`
2. **`li_fat_id`** : pas capturé côté client, pas dans le schéma DB
3. **LinkedIn CAPI token** : demande d'accès en attente depuis 7 jours (soumise 19 avril 2026)
4. **Tag sGTM LinkedIn** : non configuré dans Addingwell (bloqué par token)

---

## Gap restant

| Gap | Impact | Taille | Priorité |
|---|---|---|---|
| **G1 — Activer Insight Tag** : `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977` build-arg + manifest | Tracking navigateur (view-through, audiences LinkedIn) | **XS** — 1 rebuild client | **P0 — avant lancement** |
| **G2 — Capturer `li_fat_id`** : `CLICK_ID_PARAMS` + `AttributionContext` + INSERT + ALTER TABLE | Attribution click-level pour CAPI | **S** — 3 fichiers + 1 migration | **P1 — dès que CAPI approuvé** |
| **G3 — Tag LinkedIn CAPI sGTM** : configurer dans Addingwell | Feedback conversion serveur → LinkedIn | **XS** — config Addingwell | **BLOQUÉ par token** |
| **G4 — Vérifier statut demande CAPI** : portail développeur LinkedIn | Débloquer G3 | **XS** — vérification | **P0 — immédiat** |
| **G5 — Doc media buyer LinkedIn** | Guide d'utilisation pour le media buyer | **S** — 1 page | **P2** |

### Chemin le plus court pour un lancement amélioré

1. **G4** (5 min) — Vérifier le statut de la demande CAPI sur le portail LinkedIn Developer
2. **G1** (1h) — Rebuild client avec `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977` + deploy DEV puis PROD
3. **Si CAPI approuvé** → **G3** (30 min) — Configurer tag LinkedIn CAPI dans sGTM via Addingwell
4. **En parallèle** → **G2** (2h) — Ajouter `li_fat_id` à attribution client + API + DB

---

## Conclusion

### Verdict : GO PARTIEL

LinkedIn peut lancer pour l'acquisition KeyBuzz avec le tracking partiel actuel :

- **Attribution inbound** : fonctionne via UTMs — les leads LinkedIn seront identifiés et visibles dans le cockpit owner KBC
- **Conversion outbound** : NON fonctionnelle — LinkedIn ne recevra pas de signaux de conversion automatiques
- **Optimisation campagne** : le media buyer devra analyser manuellement les CPA/ROAS en croisant les données LinkedIn Ads Manager avec les conversions visibles dans le cockpit KeyBuzz
- **Architecture** : prête pour l'activation complète — SHA256 email déjà envoyé, plan sGTM documenté, juste le token LinkedIn manque

### Action immédiate recommandée

| # | Action | Délai | Bloqueur |
|---|---|---|---|
| 1 | Vérifier statut CAPI LinkedIn | 5 min | Aucun |
| 2 | Activer Insight Tag (rebuild client) | 1h | Aucun |
| 3 | Configurer tag CAPI sGTM | 30 min | Token LinkedIn |
| 4 | Ajouter `li_fat_id` | 2h | Aucun (mais utile surtout avec CAPI) |

### Référence historique

- **PH-T7.3.2** : LinkedIn Insight Tag + SHA256 hash replay sur branches valides — DEV OK
- **PH-T7.3.3** : LinkedIn CAPI sGTM config — WAIT (approbation LinkedIn en attente)
- **App LinkedIn** : "KeyBuzz Tracking" (Client ID: `77qcrrzhz9xwro`, Conversion ID: `27491233`)

---

## Aucune modification effectuée

**Oui** — cet audit est strictement en lecture seule. Aucun fichier modifié, aucun build, aucun deploy.

## PROD inchangée

**Oui** — aucune modification en PROD.

---

## Rapport

`keybuzz-infra/docs/PH-T8.10V-LINKEDIN-OWNER-AWARE-TRUTH-AUDIT-01.md`

---

**LINKEDIN OWNER-AWARE TRUTH ESTABLISHED — KEYBUZZ ACQUISITION READINESS KNOWN — MINIMAL NEXT STEP CLEAR — PROD UNCHANGED**
