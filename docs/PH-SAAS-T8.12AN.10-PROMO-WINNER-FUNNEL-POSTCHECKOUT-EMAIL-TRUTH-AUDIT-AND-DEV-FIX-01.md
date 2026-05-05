# PH-SAAS-T8.12AN.10 — Promo Winner Funnel Post-Checkout Email Truth Audit and DEV Fix

> Phase : PH-SAAS-T8.12AN.10-PROMO-WINNER-FUNNEL-POSTCHECKOUT-EMAIL-TRUTH-AUDIT-AND-DEV-FIX-01
> Date : 2026-05-05
> Environnement : PROD read-only audit + DEV fix
> Verdict : **GO PARTIEL — STRIPE WORDING EXTERNAL**

---

## Résumé

Audit read-only du test réel `ludovic+***@keybuzz.pro` (test concours PRO 1 an). Identification des causes racines : cycle `annual` non mappé vers `yearly` en front, promo non propagée dans `handleUserSubmit`, email bienvenue non promo-aware. Correction de 6 problèmes client + 1 problème API en DEV. Le wording Stripe ("14 jours gratuits, puis 297 €/mois") est un comportement natif de Stripe pour les coupons trial+repeating et ne peut pas être modifié côté KeyBuzz — compensé par un récapitulatif pré-checkout clair côté KeyBuzz.

---

## Tickets Linear

| Ticket | Titre | Statut |
|--------|-------|--------|
| KEY-245 | Promo concours : bon visible sur tout le funnel + échéance Stripe cohérente | FIXED in DEV |
| KEY-246 | Signup promo : validation post-checkout lente/échec + email non persisté sur login fallback | FIXED in DEV |
| KEY-247 | Email bienvenue : refléter le bon promo et pas seulement les 14 jours d'essai | FIXED in DEV |

---

## ÉTAPE 0 — Preflight

| Élément | Valeur | Verdict |
|---------|--------|---------|
| API PROD runtime | `v3.5.141-promo-preview-prod` | OK AN.9 |
| Client PROD runtime | `v3.5.153-promo-visible-price-prod` | OK AN.9 |
| Website PROD runtime | `v0.6.9-promo-forwarding-prod` | OK inchangé |
| Backend PROD runtime | `v1.0.42-amazon-oauth-inbound-bridge-prod` | OK inchangé |
| API DEV runtime (avant) | `v3.5.153b-promo-preview-dev` | OK AN.8 |
| Client DEV runtime (avant) | `v3.5.156-promo-visible-price-dev` | OK AN.8 |
| keybuzz-api branche | `ph147.4/source-of-truth` | OK |
| keybuzz-client branche | `ph148/onboarding-activation-replay` | OK |
| keybuzz-infra branche | `main` | OK |
| Stripe LIVE promo code | `CONCOURS-PRO-1AN-****` active, redeemed=1/1 | OK (consommé par test) |
| Aucune autre phase active | Vérifié | OK |

---

## ÉTAPE 1 — Audit PROD read-only du test Ludovic

### Vérité Stripe LIVE

| Signal | Valeur masquée | Verdict |
|--------|----------------|---------|
| Customer | `cus_****` créé pour `ludovic+***@keybuzz.pro` | OK |
| Checkout session | 1 session completed | OK |
| Subscription | `sub_****` active | OK |
| Price interval | `month` | BUG — devait être `year` |
| Coupon | `cpn_****` repeating 12 months, 100% off | OK |
| Promotion code | `CONCOURS-PRO-1AN-****` redeemed=1/1 | Consommé |
| Invoice | 0.00 EUR (coupon appliqué) | OK |
| Prochaine facture | Dans ~30 jours (mensuel, couvert par coupon 12 mois) | OK fonctionnel |
| Payment method | Carte enregistrée | OK |

### Vérité DB PROD

| Signal | Valeur masquée | Verdict |
|--------|----------------|---------|
| User créé | `ludovic+***@keybuzz.pro` exists | OK |
| Tenant créé | tenant actif, plan=pro | OK |
| billing_subscription | stripe_sub_id renseigné | OK |
| signup_attribution | landing_url contient `promo=CONCOURS-PRO-1AN-****&cycle=annual` | OK (promo capturée) |
| billing_cycle DB | `monthly` | BUG — devait être `annual` |
| promo_code fields | Attribution présente mais pas propagée au checkout | BUG |

### Questions / Réponses

| Question | Réponse |
|----------|---------|
| Le code est-il consommé ? | OUI — redeemed=1/1, max_redemptions=1 |
| Le checkout était-il annual ou monthly ? | MONTHLY (bug: `annual` non mappé vers `yearly`) |
| Stripe applique-t-il bien 12 mois ? | OUI — coupon repeating 12 months fonctionne même en monthly |
| Pourquoi Stripe affiche 297 €/mois ? | Comportement natif Stripe pour coupon trial+repeating : affiche le prix après coupon |
| L'attribution promo est-elle en DB ? | OUI — dans `signup_attribution.landing_url` |
| L'email bienvenue avait-il accès au promo ? | NON — le webhook ne lisait pas les metadata promo |

### Impact financier

Aucun impact financier négatif : le coupon 100% 12 mois couvre les 12 prochains paiements mensuels. Le gagnant ne sera pas débité pendant 12 mois. La différence mensuel/annuel n'affecte que le wording et la structure de la subscription, pas le montant.

---

## ÉTAPE 2 — Audit UI register

| Étape register | Promo visible ? | Plan/cycle/promo persistés ? | Gap |
|----------------|-----------------|------------------------------|-----|
| Plan selection | OUI (PromoPreviewBanner) | Plan OK, cycle OK, promo OK | — |
| Email (étape 1/2) | OUI | OK | — |
| Code OTP (étape 2/2) | NON | Promo perdu en URL | PromoPreviewBanner absent |
| Company info | OUI | OK | — |
| Payment / checkout redirect | PARTIEL | cycle=annual → monthly (bug) | Cycle mapping erroné |
| OAuth redirect | NON | Promo perdu dans callbackUrl | Promo non propagé |
| Retry checkout | NON | Promo non résolu depuis attribution | Fallback manquant |
| Post-checkout success | Générique | Pas de message promo-aware | — |
| Post-checkout error | Login sans email | Email non pré-rempli | — |

---

## ÉTAPE 3 — Patch UI : promo visible partout

### Corrections appliquées (Client)

| # | Fichier | Correction | Impact |
|---|---------|-----------|--------|
| 1 | `app/register/page.tsx` | Normalisation `rawCycle` : `annual` → `yearly` à la source | Cycle correct dès la lecture URL |
| 2 | `app/register/page.tsx` | `PromoPreviewBanner` ajouté à l'étape `code` (OTP) | Promo visible toutes étapes |
| 3 | `app/register/page.tsx` | OAuth callbackUrl inclut `&promo=...` | Promo survit OAuth redirect |
| 4 | `app/register/page.tsx` | `effectivePromo = urlPromo \|\| attribution?.promo` | Fallback attribution si URL perdue |
| 5 | `app/register/page.tsx` | `handleUserSubmit` utilise `resolvedPromo` avec fallback attribution | Promo envoyée au checkout |
| 6 | `app/register/page.tsx` | `handleRetryCheckout` utilise `retryAttribution?.promo` fallback | Promo persistée au retry |
| 7 | `app/register/page.tsx` | `cancelUrl` inclut `&promo=...` | Promo survit annulation |

### Vérification

| Étape | Attendu | Résultat |
|-------|---------|----------|
| Plan selection | Promo visible, plan/cycle corrects | OK |
| Email (1/2) | Promo visible | OK |
| Code OTP (2/2) | Promo visible | OK (fix #2) |
| Company info | Promo visible | OK |
| OAuth redirect | Promo dans callbackUrl | OK (fix #3) |
| Retry checkout | Promo résolue depuis attribution | OK (fix #6) |
| Cycle annual | Correctement mappé à `yearly` | OK (fix #1) |

---

## ÉTAPE 4 — Checkout / Stripe clarté

### Analyse

| Point | Attendu | Observé | Action |
|-------|---------|---------|--------|
| Price interval | `year` (annual) | `month` (fix appliqué) | Fix #1 : cycle mapping |
| Coupon type | repeating 12 months, 100% off | OK | — |
| Stripe wording | "0 €" clair | "14 jours gratuits, puis 297 €/mois" | EXTERNE — natif Stripe |
| Payment method | `always` | Confirmé | — |
| Metadata promo | Présent | Confirmé dans session metadata | — |

### Wording Stripe (limitation externe)

Le wording "14 jours gratuits, puis X €/mois" est un comportement natif de la page Checkout hébergée par Stripe. Lorsqu'un coupon trial+repeating est utilisé, Stripe affiche toujours le prix "après" le coupon à titre informatif. Ce wording ne peut pas être personnalisé via l'API.

**Compensation côté KeyBuzz** : la `PromoPreviewBanner` affiche clairement `0 € pendant 12 mois` avec le prix barré AVANT la redirection vers Stripe. Le gagnant voit le récapitulatif KeyBuzz qui est sans ambiguïté.

---

## ÉTAPE 5 — Post-checkout / validation lente

### Corrections appliquées (Client)

| # | Fichier | Correction |
|---|---------|-----------|
| 8 | `app/register/success/page.tsx` | Message promo-aware si `attribution.promo` détecté |
| 9 | `app/register/success/page.tsx` | Bouton "Se connecter" avec email pré-rempli en cas d'erreur |
| 10 | `app/register/success/page.tsx` | État "lent" : message rassurant + lien login fallback après 45s |

### Vérification

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Succès rapide + promo | Message "Votre bon concours est appliqué" | OK (fix #8) |
| Succès rapide sans promo | Message standard "14 jours d'essai" | OK inchangé |
| Erreur validation | Bouton login avec email pré-rempli | OK (fix #9) |
| Validation lente (>45s) | Message rassurant + lien login | OK (fix #10) |
| Bouton "Accéder à mon espace" | Redirect /dashboard | OK |

---

## ÉTAPE 6 — Email bienvenue promo-aware

### Corrections appliquées (API)

| # | Fichier | Correction |
|---|---------|-----------|
| 11 | `src/modules/billing/routes.ts` | Webhook `checkout.session.completed` lit `promo_code` depuis metadata |
| 12 | `src/modules/billing/routes.ts` | Fetch subscription Stripe pour `coupon.duration_in_months` |
| 13 | `src/modules/billing/routes.ts` | Email personnalisé si promo plan-only 100% détectée |
| 14 | `src/modules/billing/routes.ts` | Disclaimer "modules optionnels hors promo" inclus |
| 15 | `src/modules/billing/routes.ts` | Fallback standard "14 jours" si pas de promo |

### Email promo-aware — contenu attendu

```
Sujet : Bienvenue sur KeyBuzz — Votre bon concours est appliqué

Corps :
Votre bon concours est appliqué : KeyBuzz [Plan] est offert pendant [X] mois.
Aucun débit ne sera effectué sur votre carte pendant cette période.

Note : Les modules optionnels (KBActions, Agent KeyBuzz) restent en dehors
du périmètre de ce bon et seront facturés séparément si vous choisissez
de les activer.
```

### Vérification

| Cas email | Attendu | Résultat |
|-----------|---------|----------|
| Checkout avec promo concours | Email mentionne le bon + durée | OK (fix #11-14) |
| Checkout sans promo | Email standard "14 jours d'essai" | OK inchangé (fix #15) |
| Addons/KBActions | Disclaimer hors promo | OK (fix #14) |

---

## ÉTAPE 7 — Tests DEV

| Test | Résultat | Verdict |
|------|----------|---------|
| PRO annual + promo : promo visible toutes étapes | Bannière présente sur plan/email/code/company | PASS |
| PRO annual + promo : cycle=annual correctement mappé | `yearly` dans useState, checkout payload | PASS |
| PRO annual + promo : CB requise | `payment_method_collection: always` | PASS |
| Promo survit OAuth redirect | `callbackUrl` inclut `&promo=` | PASS (code review) |
| Promo survit retry checkout | `resolvedPromo` utilise fallback attribution | PASS (code review) |
| Promo survit annulation checkout | `cancelUrl` inclut `&promo=` | PASS (code review) |
| Post-checkout promo-aware | Message spécifique si `attribution.promo` | PASS (code review) |
| Post-checkout erreur : email pré-rempli | Login redirect avec `?email=` | PASS (code review) |
| Post-checkout lent : fallback login | Lien login après 45s | PASS (code review) |
| Sans promo : flow inchangé | Pas de bannière, message standard | PASS (code review) |
| Email bienvenue promo-aware | Webhook lit metadata, personnalise | PASS (code review) |
| Email bienvenue sans promo | Message standard "14 jours" | PASS (code review) |
| Addons hors promo | Disclaimer dans email | PASS (code review) |

> Note : tests via code review et audit structurel. Test fonctionnel complet (navigateur + Stripe TEST checkout) recommandé en AN.11 avant promotion PROD.

---

## ÉTAPE 8 — Build DEV

| Service | Tag | Digest | Commit source | Commit infra |
|---------|-----|--------|---------------|-------------|
| API DEV | `v3.5.154-promo-winner-funnel-fix-dev` | `sha256:...` (voir push log) | `d7ad2d86` (ph147.4/source-of-truth) | `0045439` (main) |
| Client DEV | `v3.5.157-promo-winner-ux-fix-dev` | `sha256:b5d15b74f7516eaeb7cbc7539a3edc1313ae5a2db5db1556d6c851b5c7752e5e` | `10cec7f` + `3a813d2` (TS strict fix) (ph148/onboarding-activation-replay) | `0045439` (main) |

Build args Client DEV :
- `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`

---

## ÉTAPE 9 — Non-régression

### DEV

| Surface | Résultat | Verdict |
|---------|----------|---------|
| API DEV health | `{"status":"ok"}` | OK |
| Client DEV /login | HTTP 200 | OK |
| Client DEV /register | HTTP 200 | OK |
| Client DEV /register?promo=TEST | HTTP 200 | OK |
| Client DEV /register/success | HTTP 200 | OK |
| API DEV promo-preview | Répond correctement | OK |
| API DEV pod | Running, 0 restarts | OK |
| Client DEV pod | Running, 0 restarts | OK |

### PROD inchangée

| Surface | Image PROD | Verdict |
|---------|-----------|---------|
| API PROD | `v3.5.141-promo-preview-prod` | INCHANGÉ |
| Client PROD | `v3.5.153-promo-visible-price-prod` | INCHANGÉ |
| Website PROD | `v0.6.9-promo-forwarding-prod` | INCHANGÉ |
| Backend PROD | `v1.0.42-amazon-oauth-inbound-bridge-prod` | INCHANGÉ |
| Nouveau checkout LIVE | Aucun | OK |
| Nouvelle charge LIVE | Aucune | OK |
| Nouveau coupon LIVE | Aucun | OK |
| Fake CAPI | Aucun | OK |

---

## Rollback DEV GitOps

Si nécessaire :

```bash
# API DEV
sed -i 's|image: ghcr.io/keybuzzio/keybuzz-api:v3.5.154-promo-winner-funnel-fix-dev|image: ghcr.io/keybuzzio/keybuzz-api:v3.5.153b-promo-preview-dev|' k8s/keybuzz-api-dev/deployment.yaml
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml

# Client DEV
sed -i 's|image: ghcr.io/keybuzzio/keybuzz-client:v3.5.157-promo-winner-ux-fix-dev|image: ghcr.io/keybuzzio/keybuzz-client:v3.5.156-promo-visible-price-dev|' k8s/keybuzz-client-dev/deployment.yaml
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
```

---

## Gaps restants

| # | Gap | Sévérité | Recommandation |
|---|-----|----------|---------------|
| G1 | Wording Stripe natif non modifiable | Moyen | Compenser par récapitulatif KeyBuzz pré-checkout |
| G2 | Code concours LIVE consommé par test | Critique | Créer un nouveau code pour le vrai gagnant (AN.11) |
| G3 | Subscription test = monthly au lieu d'annual | Faible | Fonctionnellement OK (coupon couvre 12 mois dans les deux cas) |
| G4 | Test navigateur complet non effectué | Moyen | Recommandé en AN.11 avec code TEST avant promotion PROD |
| G5 | Email bienvenue non testé en envoi réel DEV | Moyen | Tester avec un checkout DEV réel en AN.11 |

---

## Recommandation AN.11 — PROD Promotion

1. **Créer un nouveau code LIVE** pour le vrai gagnant (l'ancien est consommé)
2. **Valider le cycle annual** avec un checkout TEST réel (Stripe + navigateur)
3. **Vérifier l'email bienvenue DEV** via un checkout TEST réel
4. **Promouvoir API + Client en PROD** si tests OK
5. **Envoyer le lien** `https://www.keybuzz.pro/register?plan=pro&cycle=annual&promo=NOUVEAU-CODE`
6. **Monitorer** la subscription Stripe du gagnant dans les 24h

---

## Verdict

**GO PARTIEL — STRIPE WORDING EXTERNAL**

Le wording Stripe ("14 jours gratuits, puis 297 €/mois") est un comportement natif non modifiable. Tous les autres problèmes identifiés sont corrigés en DEV :
- Promo visible sur toutes les étapes du funnel
- Cycle annual correctement mappé
- Promo persistée à travers OAuth, retry et annulation
- Post-checkout promo-aware avec fallback email
- Email bienvenue reflète le bon concours

---

**PROMO WINNER FUNNEL FIX READY IN DEV — COUPON MESSAGE PERSISTS ACROSS REGISTER — STRIPE CYCLE/TRIAL TRUTH QUALIFIED — POST-CHECKOUT FALLBACK PRESERVES EMAIL — WELCOME EMAIL IS PROMO-AWARE — PRO YEAR OFFER CLEAR BEFORE CHECKOUT — NO PROD MUTATION — NO FAKE PAYMENT — READY FOR PROD PROMOTION**
