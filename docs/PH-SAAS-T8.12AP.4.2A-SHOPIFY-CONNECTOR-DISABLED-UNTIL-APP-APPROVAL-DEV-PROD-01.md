# PH-SAAS-T8.12AP.4.2A — Shopify Connector Disabled Until App Approval DEV+PROD

> Phase : PH-SAAS-T8.12AP.4.2A-SHOPIFY-CONNECTOR-DISABLED-UNTIL-APP-APPROVAL-DEV-PROD-01
> Date : 7 mai 2026
> Ticket principal : KEY-276
> Tickets liés : KEY-273, KEY-271, KEY-253
> Priorité : P1 avant lancement Ads
> Type : patch Client UX + GitOps strict
> Verdict : **GO PROD**

---

## Contexte

AP.4 a classé Shopify comme `PARTIAL` : code backend restauré mais secrets `SHOPIFY_API_KEY`/`SHOPIFY_API_SECRET` UNSET en DEV et PROD. L'application Shopify KeyBuzz n'est pas encore validée côté Shopify Partner / App Store.

Décision Ludovic : Shopify doit être mis de côté pour l'instant. Le connecteur reste visible mais **non connectable** dans le SaaS, grisé comme les connecteurs "Bientôt" existants (Fnac, eBay). Le code backend Shopify restauré est conservé pour activation future.

---

## Sources relues

| Document | Lu |
|---|:---:|
| `CE_PROMPTING_STANDARD.md` | OUI |
| `RULES_AND_RISKS.md` | OUI |
| `TRIAL_WOW_STACK_BASELINE.md` | OUI |
| `PH-SAAS-T8.12AP.4` (audit connecteurs) | OUI |
| `PH-SAAS-T8.12AP.4.1` (claims website) | OUI |

---

## Preflight

### Branches

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `abef1bc` | propre | OK |
| keybuzz-infra | `main` | `9a33d24` | propre | OK |

### Baselines PROD

| Service | Image attendue | Image runtime | Match |
|---|---|---|---|
| Client | `v3.5.168-outbound-author-name-ux-prod` | idem | ✓ |
| API | `v3.5.147-auto-assignment-after-reply-prod` | idem | ✓ |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | idem | ✓ |
| Website | `v0.6.10-connector-claims-truth-prod` | idem | ✓ |
| OW | `v3.5.165-escalation-flow-prod` | idem | ✓ |

---

## ÉTAPE 0 — Audit UI Shopify

| Surface | Fichier | État avant | Risque | Action |
|---|---|---|---|---|
| `/channels` catalogue | `app/channels/page.tsx` | `coming_soon: false`, bouton "Connecter Shopify" actif | **P0** | `coming_soon: true` + badge "En préparation" |
| `/channels` modal ajout | `app/channels/page.tsx` | Clic ouvre modal Shopify OAuth | P0 | Retour anticipé (no-op) |
| `/channels` modal connect | `app/channels/page.tsx` | Modal avec domaine input + bouton Connect | P1 | Modal inatteignable |
| `/start` (OnboardingHub) | `src/features/onboarding/components/OnboardingHub.tsx` | Shopify cliquable, `action: 'redirect'` | P1 | `comingSoon: true` (grisé + "Bientôt") |
| Onboarding state hook | `src/features/onboarding/hooks/useOnboardingState.ts` | Fetch `/api/shopify/status` | P3 — safe | Conservé (retourne false) |
| Service Shopify | `src/services/shopify.service.ts` | Fonctions connect/disconnect/status | Aucun | Conservé |
| BFF routes | `app/api/shopify/*/route.ts` | 3 routes proxy | Aucun | Conservé |

---

## ÉTAPE 1 — Patch Client

### Fichiers modifiés (2 fichiers, 8+/14-)

#### `src/features/onboarding/components/OnboardingHub.tsx`

Shopify marqué `comingSoon: true` dans le tableau des marketplaces, aligné avec Fnac et eBay. Le composant existant gère automatiquement :
- Bouton grisé (`opacity-50 cursor-not-allowed bg-gray-50`)
- Click désactivé (`if ('comingSoon' in mp && mp.comingSoon) return;`)
- Badge "Bientôt" affiché

#### `app/channels/page.tsx`

4 modifications :
1. Import `Clock` ajouté depuis `lucide-react`
2. `shopifyEntry.coming_soon` changé de `false` à `true`
3. Bouton "Connecter Shopify" remplacé par badge `<span>` "En préparation" (amber, non cliquable)
4. Clic "Ajouter" dans le modal catalogue retourne `return` au lieu d'ouvrir le modal Shopify

---

## Validation statique

| Check | Résultat |
|---|---|
| "Connecter Shopify" button | **0 occurrence** ✓ |
| Shopify `coming_soon: true` | ✓ channels |
| Shopify `comingSoon: true` | ✓ OnboardingHub |
| Clock import | ✓ |
| Amazon `startAmazonOAuth` | Présent ✓ |
| Promo funnel code | 37 références ✓ |
| Amazon inbound guide | 5 références ✓ |

---

## Builds et déploiements

### Client commit

```
SHA: 258060a
Branche: ph148/onboarding-activation-replay
Message: fix(channels): disable Shopify connector until app approval (AP.4.2A KEY-276)
```

### Images Docker

| Env | Tag | Digest |
|---|---|---|
| DEV | `v3.5.169-shopify-disabled-until-approval-dev` | `sha256:863c4c77813c06e864dc9ea2776eddfc03a3b9b47dbde2745f05b5ac92f11d6a` |
| PROD | `v3.5.169-shopify-disabled-until-approval-prod` | `sha256:5a95af2d15559084ee5019483d4554d97dd0a1cfd22c6cf429290d2582848494` |

### Tracking vérifié dans bundle PROD

| Tracking | Présent | Status |
|---|---|---|
| GA4 `G-R3QQDYEBFG` | 1 ref | ✓ |
| sGTM `t.keybuzz.pro` | 2 refs | ✓ |
| TikTok `D7PT12JC77U44OJIPC10` | 1 ref | ✓ |
| LinkedIn `9969977` | 1 ref | ✓ |
| Meta `1234164602194748` | 1 ref | ✓ |
| Browser CompletePayment | 0 | ✓ |

### GitOps infra

```
SHA: 4272eab (rebased from 10b0aee)
Message: deploy(client): v3.5.169-shopify-disabled-until-approval DEV+PROD (AP.4.2A KEY-276)
Fichiers: k8s/keybuzz-client-dev/deployment.yaml, k8s/keybuzz-client-prod/deployment.yaml
```

---

## Validation PROD

| Check | Résultat |
|---|---|
| Client PROD runtime | `v3.5.169-shopify-disabled-until-approval-prod` ✓ |
| `/start` | 307 (redirect auth, normal) ✓ |
| `/channels` | 307 (redirect auth, normal) ✓ |
| API health | 200 OK ✓ |

### Services inchangés

| Service | Image PROD après | Identique avant | Status |
|---|---|---|---|
| API | `v3.5.147-auto-assignment-after-reply-prod` | ✓ | Inchangé |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | ✓ | Inchangé |
| Website | `v0.6.10-connector-claims-truth-prod` | ✓ | Inchangé |
| OW | `v3.5.165-escalation-flow-prod` | ✓ | Inchangé |

### 0 mutations

- 0 DB mutation
- 0 API/Backend build
- 0 Website build
- 0 Stripe mutation
- 0 billing mutation
- 0 CAPI event

---

## Contrat UX Shopify post-AP.4.2A

```
SHOPIFY CONNECTOR — CONTRAT UX

État : VISIBLE MAIS DÉSACTIVÉ
Raison : Application Shopify pas encore validée (Shopify Partner / App Store)

/start (OnboardingHub) :
  - Logo Shopify affiché
  - Bouton grisé (opacity-50, cursor-not-allowed)
  - Badge "Bientôt"
  - Click → no-op

/channels :
  - Shopify dans le catalogue avec coming_soon: true
  - Si status "pending" : badge amber "En préparation" (pas de bouton Connect)
  - Modal ajout marketplace : click sur Shopify → return (pas de modal)
  - Modal Shopify Connect : inaccessible (aucun chemin UI ne l'ouvre)

Code backend : CONSERVÉ (shopify.service.ts, BFF routes, API routes)
Secrets : UNSET (à configurer lors de KEY-273 activation)
DB tables : shopify_connections, shopify_webhook_events — CONSERVÉES

Réactivation : KEY-273 (configurer secrets + changer coming_soon/comingSoon à false)
```

---

## Linear

| Ticket | Action |
|---|---|
| **KEY-276** | Shopify grisé DEV+PROD, tags/digests documentés — **à fermer** |
| KEY-273 | Shopify reste ouvert pour activation finale (app review + secrets). UX volontairement disabled. |
| KEY-271 | AP.4 Shopify risk mitigé côté UX |
| KEY-253 | Pre-Ads safe, Shopify non connectable dans le SaaS |

---

## Rollback

```bash
PREV_TAG="ghcr.io/keybuzzio/keybuzz-client:v3.5.168-outbound-author-name-ux-prod"

cd /opt/keybuzz/keybuzz-infra
sed -i "s|image: ghcr.io/keybuzzio/keybuzz-client:.*|image: $PREV_TAG|g" k8s/keybuzz-client-prod/deployment.yaml
git add k8s/keybuzz-client-prod/deployment.yaml
git commit -m "rollback(client): revert to v3.5.168-outbound-author-name-ux-prod"
git push origin main
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod --timeout=120s
```

---

## Verdict

**GO PROD**

SHOPIFY CONNECTOR DISABLED UNTIL APP APPROVAL LIVE IN PROD — SHOPIFY VISIBLE BUT NOT CONNECTABLE — AMAZON/EMAIL CONNECTORS PRESERVED — SHOPIFY BACKEND CODE PRESERVED FOR FUTURE ACTIVATION — CLIENT TRACKING/PROMO/AMAZON GUIDE/DEMO GATING PRESERVED — API/BACKEND/WEBSITE/DB UNCHANGED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT
