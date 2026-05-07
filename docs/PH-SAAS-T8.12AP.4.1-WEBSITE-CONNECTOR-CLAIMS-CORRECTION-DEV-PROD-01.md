# PH-SAAS-T8.12AP.4.1 — Website Connector Claims Correction DEV+PROD

> Phase : PH-SAAS-T8.12AP.4.1-WEBSITE-CONNECTOR-CLAIMS-CORRECTION-DEV-PROD-01
> Date : 7 mai 2026
> Ticket principal : KEY-272
> Tickets liés : KEY-271, KEY-253, KEY-273, KEY-274
> Priorité : P0 avant lancement Ads
> Verdict : **GO PROD**

---

## Contexte

AP.4 (audit connecteurs et features critiques) a identifié des claims marketing trompeurs sur le website `keybuzz.pro`. Avant le lancement Ads, ces claims devaient être corrigés pour éviter qu'un prospect (notamment eBay) ne s'inscrive et ne trouve aucune fonctionnalité correspondante.

### Vérité AP.4 par connecteur

| Connecteur | Statut AP.4 | Claim website avant | Risque |
|---|---|---|---|
| Amazon | FULL | Disponible ✓ | Aucun |
| Email | FULL | Disponible | Aucun |
| eBay | **ABSENT** (0 code/runtime) | ✓ checkmark disponible | **P0** |
| Fnac | MARKETING_RISK (coming_soon:true) | ✓ checkmark disponible | P1 |
| Cdiscount/Octopia | PARTIAL (code mais 0 connexion) | ✓ checkmark disponible | P2 |
| Shopify | PARTIAL (secrets UNSET) | ✓ checkmark disponible | P1 |
| WooCommerce | ABSENT | ✓ checkmark disponible | P1 |
| 17TRACK | PARTIAL (webhook secret UNSET) | Non mentionné directement | P3 |

---

## Sources relues

- `CE_PROMPTING_STANDARD.md` ✓
- `RULES_AND_RISKS.md` ✓
- `PH-SAAS-T8.12AP.4-CONNECTORS-AND-CRITICAL-FEATURES-REGRESSION-TRUTH-AUDIT-01.md` ✓
- `PH-SAAS-T8.12AP-MEDIA-BUYER-BRIEF-PRODUCT-PARITY-TRUTH-AUDIT-01.md` ✓
- `TRIAL_WOW_STACK_BASELINE.md` ✓
- `SERVER_SIDE_TRACKING_CONTEXT.md` ✓

---

## Preflight

### Website (`keybuzz-website`)

- Branche : `main`
- Commit avant : `7fc942b` (PH-SAAS-T8.12AN.3: forward promo param)
- Dirty state : propre
- Décision : **CONTINUER**

### Infra (`keybuzz-infra`)

- Branche : `main`
- Commit avant : `4dfa7df`
- Dirty state : propre
- Décision : **CONTINUER**

### Baselines PROD confirmées

| Service | Image PROD | Attendu | Match |
|---|---|---|---|
| Website | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | ✓ |
| API | `v3.5.147-auto-assignment-after-reply-prod` | `v3.5.147-auto-assignment-after-reply-prod` | ✓ |
| Client | `v3.5.168-outbound-author-name-ux-prod` | `v3.5.168-outbound-author-name-ux-prod` | ✓ |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | ✓ |
| OW | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | ✓ |

---

## Audit Claims (18 occurrences identifiées)

| Fichier | Claim actuel | Connecteur | Statut AP.4 | Action |
|---|---|---|---|---|
| `MarketplaceMarquee.tsx:26` | Logo eBay dans carrousel | eBay | ABSENT | **Retiré** |
| `layout.tsx:31` | Keyword SEO "ebay" | eBay | ABSENT | **Retiré** |
| `page.tsx:350` | "Amazon, Fnac/Darty, Cdiscount, eBay" | eBay | ABSENT | eBay retiré |
| `page.tsx:699` | "Amazon, Fnac/Darty, Cdiscount, eBay" | eBay | ABSENT | eBay retiré |
| `pricing/page.tsx:145` | "Amazon, Fnac/Darty, Cdiscount, eBay" ✓all | Fnac+eBay | RISK+ABSENT | → "Amazon, Cdiscount (Octopia)" |
| `pricing/page.tsx:186` | FAQ APIs avec eBay | eBay | ABSENT | eBay retiré, Fnac/Shopify "en préparation" |
| `pricing/page.tsx:562` | Context avec eBay | eBay | ABSENT | eBay retiré |
| `pricing/page.tsx:622` | Conformité avec eBay | eBay | ABSENT | eBay retiré |
| `features/page.tsx:116` | FAQ: eBay+Shopify "disponibles" | Multi | ABSENT+PARTIAL | Réécrit honnêtement |
| `features/page.tsx:188` | Inbox "Amazon, Fnac, Cdiscount, eBay" | eBay | ABSENT | → "Amazon, Cdiscount et e-mail" |
| `features/page.tsx:470` | ✓ bleu Fnac / Darty | Fnac | MARKETING_RISK | → Clock amber "Bientôt" |
| `features/page.tsx:473` | ✓ bleu Cdiscount | Cdiscount | PARTIAL | → ✓ bleu + "(Octopia)" |
| `features/page.tsx:476` | ✓ bleu eBay | eBay | ABSENT | → Clock gris "Prévu" |
| `features/page.tsx:487` | ✓ bleu Shopify | Shopify | PARTIAL | → Clock amber "En préparation" |
| `features/page.tsx:490` | ✓ bleu WooCommerce | WooCommerce | ABSENT | → Clock amber "Bientôt" |
| `privacy/page.tsx:71` | "Amazon, Fnac, Cdiscount, eBay, etc." | eBay | ABSENT | → "Amazon, Cdiscount, etc." |
| `sla/page.tsx:225` | "Amazon, Fnac, Cdiscount, eBay, etc." | eBay | ABSENT | → "Amazon, Cdiscount, etc." |
| `terms/page.tsx:54,70` | "Amazon, Fnac, Cdiscount, eBay, etc." (x2) | eBay | ABSENT | → "Amazon, Cdiscount, etc." |

---

## Fichiers modifiés (8 fichiers)

| Fichier | Insertions | Suppressions |
|---|---|---|
| `src/components/MarketplaceMarquee.tsx` | 0 | 1 |
| `src/app/layout.tsx` | 0 | 1 |
| `src/app/page.tsx` | 2 | 2 |
| `src/app/pricing/page.tsx` | 4 | 4 |
| `src/app/features/page.tsx` | 7 | 7 |
| `src/app/privacy/page.tsx` | 1 | 1 |
| `src/app/sla/page.tsx` | 1 | 1 |
| `src/app/terms/page.tsx` | 2 | 2 |
| **Total** | **17** | **19** |

---

## Builds et déploiements

### Website commit

```
SHA: f155bfa27759d8074983e6c98af1c285e40206b9
Message: fix(claims): correct misleading marketplace connector claims (AP.4.1 KEY-272)
Branche: main
```

### Images Docker

| Env | Tag | Digest |
|---|---|---|
| DEV | `v0.6.10-connector-claims-truth-dev` | `sha256:dbcd3c1a71b624736449201e838dc7c1ad58c9cad347e1fc28f45d971c1d27ec` |
| PROD | `v0.6.10-connector-claims-truth-prod` | `sha256:3151944b85ac873e928d672254bd40aebb17eb9a6ba35d84d47db39c2d67d4fe` |

### GitOps infra

```
SHA: f39b887 (rebased from e80f296)
Message: deploy(website): v0.6.10-connector-claims-truth DEV+PROD (AP.4.1 KEY-272)
Fichiers: k8s/website-dev/deployment.yaml, k8s/website-prod/deployment.yaml
```

---

## Validation PROD

### HTTP Status

| Page | Code | Status |
|---|---|---|
| Homepage (`/`) | 200 | ✓ |
| Pricing (`/pricing`) | 200 | ✓ |
| Features (`/features`) | 200 | ✓ |
| SLA (`/sla`) | 200 | ✓ |
| Privacy (`/privacy`) | 200 | ✓ |
| Terms (`/terms`) | 200 | ✓ |

### Claims corrigés

| Vérification | Résultat |
|---|---|
| eBay sur homepage | **0 occurrence** ✓ |
| eBay sur pricing | **0 occurrence** ✓ |
| eBay sur features | **1 occurrence** = badge "Prévu" gris (correct) ✓ |
| Fnac sur features | Clock amber + "Bientôt" ✓ |
| Shopify sur features | Clock amber + "En préparation" ✓ |
| Amazon sur homepage | 37 occurrences (connecteur principal) ✓ |
| Amazon sur pricing | 18 occurrences ✓ |

### Non-régression tracking

| Tracking | PROD | Status |
|---|---|---|
| TikTok Pixel | 4 références HTML | ✓ préservé |
| UTM/promo forwarding | Code intact (0 fichier modifié) | ✓ préservé |
| Register page | HTTP 200 | ✓ |

### Services inchangés

| Service | Image PROD après | Identique avant | Status |
|---|---|---|---|
| API | `v3.5.147-auto-assignment-after-reply-prod` | ✓ | Inchangé |
| Client | `v3.5.168-outbound-author-name-ux-prod` | ✓ | Inchangé |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | ✓ | Inchangé |
| OW | `v3.5.165-escalation-flow-prod` | ✓ | Inchangé |

### 0 mutations

- 0 DB mutation
- 0 Stripe mutation
- 0 billing mutation
- 0 CAPI event
- 0 tracking fake
- 0 purchase fake

---

## Rollback

```bash
# Image précédente
PREV_TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.9-promo-forwarding-prod"

# Modifier manifest
cd /opt/keybuzz/keybuzz-infra
sed -i "s|image: ghcr.io/keybuzzio/keybuzz-website:.*|image: $PREV_TAG|g" k8s/website-prod/deployment.yaml
git add k8s/website-prod/deployment.yaml
git commit -m "rollback(website): revert to v0.6.9-promo-forwarding-prod"
git push origin main
kubectl apply -f k8s/website-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod --timeout=120s
```

---

## Linear

| Ticket | Action |
|---|---|
| KEY-272 | Claims corrigés, tags/digests documentés, pages validées — **à fermer** |
| KEY-271 | AP.4.1 terminé, P0 eBay résolu |
| KEY-253 | Risque marketing connecteurs levé pour Ads |
| KEY-273 | Shopify reste activation config, claim website corrigé — **ne pas fermer** |
| KEY-274 | 17TRACK webhook secret non traité ici — **ne pas fermer** |

---

## Verdict

**GO PROD**

WEBSITE CONNECTOR CLAIMS CORRECTED IN PROD — EBAY NO LONGER CLAIMED AS AVAILABLE — FNAC/SHOPIFY STATUS HONEST — AMAZON REMAINS CLEAR PRIMARY CONNECTOR — WEBSITE TRACKING AND PROMO FORWARDING PRESERVED — API/CLIENT/BACKEND/ADMIN/DB UNCHANGED — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT
