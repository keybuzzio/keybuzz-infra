# Trial Wow Stack Baseline

> Dernière mise à jour : 2026-05-01
> Phase de clôture : PH-SAAS-T8.12X
> Statut : **LAUNCH-READY**

---

## 1. CE QUI EST LAUNCH-READY

### Trial AUTOPILOT_ASSISTED
- Tout nouveau trial (Starter ou Pro) reçoit `effectivePlan: AUTOPILOT_ASSISTED` pendant 14 jours
- Le `selectedPlan` (plan choisi par l'utilisateur) est préservé comme vérité commerciale
- `trialEntitlementPlan: AUTOPILOT_ASSISTED` est calculé runtime par l'API, pas stocké en DB
- Après le trial : retour au `selectedPlan` réel
- Preuves : PH-SAAS-T8.12C.1, T8.12I, T8.12K.1, T8.12W

### TrialBanner + FeatureGate
- `TrialBanner` affiche les jours restants et le CTA Autopilot
- `FeatureGate` utilise `effectivePlan` (pas `selectedPlan`) pour les vérifications de capabilities
- Label onboarding : `isTrialing ? 'Limites trial' : 'Plan & limites'`
- Preuves : PH-SAAS-T8.12H, T8.12H.1, T8.12H.2

### Onboarding Metronic Data-Aware
- 8 étapes : Welcome, Profil, Amazon, Inbound, Premier message, IA, Limites, Prêt
- Chaque étape fetch les données réelles (Amazon status, conversations count, profil, IA)
- Skip tenant-scoped via `kb_onboarding_skipped:v1:<tenantId>`
- Preuves : PH-SAAS-T8.12L → T8.12L.4, T8.12M, T8.12M.1

### Sample Demo Wow
- 5 conversations : 3 Amazon + 1 Octopia/Cdiscount + 1 email/boutique directe
- Visible uniquement pour tenants avec 0 conversations
- Dismiss tenant-scoped via `kb_demo_dismissed:v1:<tenantId>`
- Client-side only : 0 API call, 0 DB write, 0 tracking event
- No refund-first : aucune promesse de remboursement prématurée
- `onConnect` (pas `onConnectAmazon`) : textes généralisés multi-canal
- Preuves : PH-SAAS-T8.12N → T8.12N.4, T8.12O, T8.12R, T8.12R.1

### Tracking Funnel Public
- GA4 : `G-R3QQDYEBFG`
- sGTM : `https://t.keybuzz.pro`
- TikTok Pixel : `D7PT12JC77U44OJIPC10` (browser PageView/SubmitForm/InitiateCheckout)
- LinkedIn Insight Tag : `9969977`
- Meta Pixel : `1234164602194748` (browser PageView/Lead/CompleteRegistration/InitiateCheckout)
- **Meta Purchase browser ABSENT** — server-side CAPI only
- **TikTok CompletePayment browser ABSENT** — server-side Events API only
- **AW direct ABSENT** — pas de Google Ads tag direct
- Pages protégées (dashboard/inbox/billing) : 0 tracking publicitaire
- Preuves : PH-T8.12P → T8.12U

### IA Seller-First / Platform-Aware
- `policyPosture` : `marketplace_strict` (Amazon/Octopia) vs `direct_seller_controlled` (email/Shopify)
- `channelContext` injecté dans les layers de décision IA
- Refund protection : l'IA ne recommande jamais de remboursement proactif sur marketplace
- Response strategy adaptée au canal
- 20 patterns platform-aware dans API PROD
- Preuves : PH-API-T8.12P, T8.12Q, T8.12Q.1, T8.12Q.2

---

## 2. BASELINES RUNTIME (2026-05-01)

| Service | Image | Digest | Contenu clé |
|---|---|---|---|
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | `sha256:d50740d58338129cb289640e2f69cf21164d33ccd3e754e9a737e9a44b5bbde3` | Demo + tracking complet |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | `sha256:1c1ccb19c5f56e1262a0d6b681f4ab5fdfa3c2251a991820f371671a7e4df2c7` | IA platform-aware + trial entitlement |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | `sha256:f434eed82abf01bdd6d5b5e4d082f569bac2357fe35dcd43e5778bffd6439c0a` | Acquisition baseline truth |
| Backend PROD | `v1.0.46-ph-recovery-01-prod` | — | Recovery stable |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | — | TikTok browser pixel |

### Règle absolue

**Ne JAMAIS écraser Client PROD sans preuve que le nouveau build inclut :**
1. Sample Demo platform-aware (5 conv, multi-canal, no refund-first)
2. Tracking complet (8 build args : API_URL, API_BASE_URL, APP_ENV, GA4, sGTM, TikTok, LinkedIn, Meta)
3. Meta Purchase browser absent
4. TikTok CompletePayment browser absent

---

## 3. TRACKING INVARIANTS

### Build args obligatoires pour tout rebuild Client

```
--build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io
--build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io
--build-arg NEXT_PUBLIC_APP_ENV=production
--build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG
--build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro
--build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10
--build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
--build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748
```

### Signaux honnêtes uniquement
- `signup_complete` : uniquement après `POST /api/auth/create-signup` réel
- `trackPurchase` (GA4 `purchase`) : uniquement après Stripe `checkout.session.completed`
- Meta `Purchase` : server-side CAPI uniquement (pas de browser event)
- TikTok `CompletePayment` : server-side Events API uniquement (pas de browser event)
- Aucun fake signup, fake purchase, fake CAPI autorisé

### Acquisition reporting baseline
- Date : `2026-05-01 00:00 Europe/Paris`
- Avant cette date : données potentiellement polluées par tenants test
- Après cette date : données propres (tenants test marqués `billing_exempt: test_account`)

---

## 4. SELLER-FIRST INVARIANTS

- L'IA est un **copilote, jamais un exécuteur**
- Aucune promesse de remboursement proactive sur marketplace
- Canal détecté → `policyPosture` → stratégie adaptée
- Sample Demo reflète cette doctrine (no refund-first, multi-canal)
- Tout nouveau script qui envoie un message marketplace doit vérifier `policyPosture`

---

## 5. DETTES RESTANTES (non bloquantes)

| Dette | Sévérité | Phase recommandée |
|---|---|---|
| TikTok Business API approval (server-side Events API) | Moyenne | Attente approbation TikTok |
| LinkedIn spend attribution fine | Faible | Monitoring ads post-launch |
| Cdiscount/FNAC distinction derrière Octopia | Faible | Future amélioration UX |
| 20+ tenants test DEV accumulés | Moyenne | Phase cleanup dédiée |
| Client DEV en retard sur PROD (`v3.5.146` vs `v3.5.147`) | Faible | Aligner prochain cycle DEV |
| `ecomlg-001` `is_trial: true` avec `trial_ends_at: null` | Info | Nettoyage data |
| Trial lifecycle emails (nudges avant fin essai) | Moyenne | Phase email lifecycle |
| Usage/value dashboard (valeur économisée) | Moyenne | Phase persuasion trial |

---

## 6. PHASES RECOMMANDÉES

| Phase | Objectif | Priorité | Dépendance |
|---|---|---|---|
| Trial lifecycle emails | Nudges automatiques J-3, J-1, J0 avant fin trial | P1 | SMTP OK |
| Usage/value dashboard | Montrer la valeur économisée pendant le trial | P2 | Données conversation suffisantes |
| Cleanup tenants test DEV | Purger les 20+ tenants test accumulés | P2 | Aucune |
| TikTok Events API activation | Activer server-side quand BM approval obtenu | P2 | TikTok Business API approval |
| LinkedIn conversion import | Importer les conversions LinkedIn via CAPI | P3 | LinkedIn approval |
| Octopia enrichissement canal | Distinguer Cdiscount/FNAC derrière Octopia | P3 | Metadata Octopia API |
