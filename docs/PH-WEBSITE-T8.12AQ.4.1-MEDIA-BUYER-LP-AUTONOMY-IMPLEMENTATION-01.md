# PH-WEBSITE-T8.12AQ.4.1 - Media Buyer LP Autonomy Implementation

> Phase : PH-WEBSITE-T8.12AQ.4.1-MEDIA-BUYER-LP-AUTONOMY-IMPLEMENTATION-01
> Date : 2026-05-09
> Ticket : KEY-285
> Parent : KEY-284 / KEY-253
> Verdict : **GO PROD**

---

## Résumé exécutif

Les deux gaps identifiés dans AQ.4 sont fermés :

1. **Campaign QA accepte désormais tous les sous-domaines `*.keybuzz.io` et `*.keybuzz.pro`** sans intervention code pour chaque nouvelle LP.
2. **Documentation media buyer officielle créée** dans `keybuzz-infra/docs/AI_MEMORY/MEDIA_BUYER_LP_TRACKING_CONTRACT.md`.

L'autonomie media buyer est désormais opérationnelle. Antoine peut créer des LP Webflow sur `try.keybuzz.io` ou tout autre sous-domaine KeyBuzz sans intervention Ludovic.

---

## 0. Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-admin-v2 | main | `22a268e` | Non | OK |
| keybuzz-infra | main | `c082950` (AQ.4 report) | Non | OK |

| Service | Image PROD avant | Runtime | Match |
|---|---|---|---|
| Website PROD | `v0.6.12-linkedin-insight-seo-prod` | match | OK |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | match | OK |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | match | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | match | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | match | OK |
| Admin PROD | `v2.12.1-promo-codes-foundation-prod` | match | OK |

---

## 1. Audit Campaign QA

| Élément | Fichier | État avant | Gap |
|---|---|---|---|
| `VALID_DOMAINS` | page.tsx:25 | `['www.keybuzz.pro', 'keybuzz.pro', 'client.keybuzz.io']` | `try.keybuzz.io` absent |
| Domain check `analyzeUrl()` | page.tsx:183 | Bloquant si hostname hors liste | Rejette toute LP externe |
| Landing check `analyzeUrl()` | page.tsx:232 | Warning si != `/pricing` | Ne distingue pas LP vs CTA |
| URL Builder | page.tsx:87-100 | Génère `keybuzz.pro/pricing` | OK, pas de changement |

### Réponses aux questions d'audit

- `try.keybuzz.io` est-il rejeté ? **OUI** (avant patch) — domaine bloquant dans Event Lab
- `*.keybuzz.io` accepté ? **NON** (avant patch) — uniquement les 3 domaines exacts
- Faut-il domaine exact ou wildcard ? **Wildcard contrôlé** — KeyBuzz contrôle le DNS
- Risque d'accepter trop large ? **Nul** — seuls `*.keybuzz.io` et `*.keybuzz.pro` (DNS contrôlé)
- Campaign QA détecte-t-il les params obligatoires ? **OUI** — utm_source, utm_campaign, marketing_owner
- Campaign QA alerte-t-il si CTA incomplet ? **OUI** — checks bloquants pour les params manquants

---

## 2. Décision domaine

| Option | Avantage | Risque | Décision |
|---|---|---|---|
| A — `try.keybuzz.io` seul | Plus restrictif | Intervention code par nouveau domaine | Non retenue |
| **B — `*.keybuzz.io` + `*.keybuzz.pro`** | **Autonomie totale** | **Nul (DNS contrôlé)** | **Retenue** |
| C — Config admin dynamique | Maximum flexibilité | Complexité, hors scope | Future feature optionnelle |

**Justification Option B** : KeyBuzz contrôle le DNS de `keybuzz.io` et `keybuzz.pro`. Aucun tiers ne peut créer un sous-domaine. Les domaines externes (`evil.com`, `keybuzz.io.evil.com`) sont rejetés par la validation suffix.

---

## 3. Patch Campaign QA

### Changements (3 modifications ciblées, +16/-4 lignes)

**1. Constantes + fonction validation domaine** (remplace `VALID_DOMAINS`)

```typescript
const CORE_DOMAINS = ['www.keybuzz.pro', 'keybuzz.pro', 'client.keybuzz.io', 'keybuzz.io'];
const CONTROLLED_SUFFIXES = ['.keybuzz.io', '.keybuzz.pro'];

function isControlledDomain(hostname: string): 'core' | 'lp' | false {
  if (CORE_DOMAINS.includes(hostname)) return 'core';
  if (CONTROLLED_SUFFIXES.some(s => hostname.endsWith(s))) return 'lp';
  return false;
}
```

**2. Domain check LP-aware** (remplace le blocking check)

```typescript
const domainType = isControlledDomain(parsed.hostname);
if (!domainType) {
  // BLOQUANT : domaine externe non reconnu
} else if (domainType === 'lp') {
  // OK : sous-domaine LP contrôlé, info CTA
}
```

**3. Landing check LP-aware** (remplace le warning /pricing)

```typescript
if (domainType === 'lp') {
  // OK : LP externe, rappel CTA
} else if (parsed.pathname === '/pricing' || parsed.pathname === '/pricing/') {
  // OK : landing recommandée
} else {
  // WARNING : landing non recommandée
}
```

### Tests de validation

| URL | Attendu | Résultat |
|---|---|---|
| `https://try.keybuzz.io/landing?utm_source=meta` | Accepté (LP) | ✅ `domainType === 'lp'` |
| `https://www.keybuzz.pro/pricing?utm_source=meta` | Accepté (core) | ✅ `domainType === 'core'` |
| `https://client.keybuzz.io/register?plan=pro` | Accepté (core) | ✅ `domainType === 'core'` |
| `https://ads.keybuzz.io/v1?utm_source=google` | Accepté (LP) | ✅ `domainType === 'lp'` |
| `https://preview.keybuzz.pro/page?utm_source=tiktok` | Accepté (LP) | ✅ `domainType === 'lp'` |
| `https://evil.com/keybuzz?utm_source=meta` | Rejeté | ✅ `domainType === false` |
| `https://keybuzz.io.evil.com/page` | Rejeté | ✅ `domainType === false` (ne se termine pas par `.keybuzz.io`) |
| `javascript:alert(1)` | Rejeté | ✅ URL parse fail |
| `http://try.keybuzz.io/` | Accepté (LP) | ✅ Protocol ne change pas la validation domaine |

---

## 4. Documentation media buyer officielle

Créée dans `keybuzz-infra/docs/AI_MEMORY/MEDIA_BUYER_LP_TRACKING_CONTRACT.md`.

Contenu :
- Règle fondamentale (Meta Pixel seul insuffisant)
- Template CTA register direct + via pricing
- Paramètres obligatoires, optionnels, automatiques
- Script Webflow forwarding click IDs
- Pixels autorisés / Events interdits
- Checklist avant mise en ligne
- Convention nommage campagnes
- Domaines LP autorisés
- Autonomie media buyer (tableau)
- **Directives Antoine prêtes à copier-coller**

---

## 5. Builds et déploiements

### Admin DEV

| Élément | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-dev` |
| Digest | `sha256:c747ee93d25a81e43f44e04d2c845b51a3eab0ede51f050df1375e6009abaa09` |
| GitOps commit | `9f86d65` |
| Rollback | `v2.12.0-promo-codes-foundation-dev` |
| Runtime vérifié | ✅ |

### Admin PROD

| Élément | Valeur |
|---|---|
| Tag | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod` |
| Digest | `sha256:ecc2080ff7fe5031eab812b1c32d330e4f7eea902d2a98e4d7bd7b409e0d5037` |
| GitOps commit | `2225f0b` |
| Rollback | `v2.12.1-promo-codes-foundation-prod` |
| Runtime vérifié | ✅ |

---

## 6. Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| Website PROD | `v0.6.12-linkedin-insight-seo-prod` | ✅ Inchangé |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | ✅ Inchangé |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | ✅ Inchangé |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | ✅ Inchangé |
| OW PROD | `v3.5.165-escalation-flow-prod` | ✅ Inchangé |
| Admin DEV | `v2.12.2-media-buyer-lp-domain-qa-dev` | ✅ Mis à jour |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | ✅ Mis à jour |
| Stripe | Aucune mutation | ✅ |
| DB | Aucune mutation | ✅ |
| Tracking providers | Aucune mutation | ✅ |
| Fake events | 0 | ✅ |

---

## 7. Commits

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-admin-v2 | main | (latest) | `feat(campaign-qa): accept controlled LP subdomains` |
| keybuzz-infra | main | `9f86d65` | `gitops(dev): admin campaign-qa LP domain v2.12.2` |
| keybuzz-infra | main | `2225f0b` | `gitops(prod): admin campaign-qa LP domain v2.12.2` |

---

## 8. Rollback

| Env | Image rollback | Commande |
|---|---|---|
| Admin DEV | `v2.12.0-promo-codes-foundation-dev` | `kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.12.0-promo-codes-foundation-dev -n keybuzz-admin-v2-dev` |
| Admin PROD | `v2.12.1-promo-codes-foundation-prod` | `kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.12.1-promo-codes-foundation-prod -n keybuzz-admin-v2-prod` |

---

## 9. Linear

### KEY-285
- ✅ Campaign QA patché : `isControlledDomain()` accepte `*.keybuzz.io` et `*.keybuzz.pro`
- ✅ Documentation media buyer officielle créée
- ✅ Directives Antoine prêtes à copier-coller
- ✅ Script Webflow forwarding click IDs documenté
- ✅ Admin DEV déployé `v2.12.2-media-buyer-lp-domain-qa-dev`
- ✅ Admin PROD déployé `v2.12.2-media-buyer-lp-domain-qa-prod`
- Statut : **Done**

### KEY-284
- AQ.4 (audit) + AQ.4.1 (implémentation) terminés
- Autonomie media buyer opérationnelle
- Meta Pixel seul clarifié comme insuffisant
- Contrat URL CTA documenté
- Statut : **Done**

### KEY-253
- LP externe / media buyer tracking contract fermé
- Ads restent GO

### KEY-282 / KEY-283
- Hors scope, non modifiés

---

## 10. Confirmations finales

- 0 fake event
- 0 checkout
- 0 payment
- 0 DB mutation
- 0 Stripe mutation
- 0 CAPI mutation
- 0 DNS change
- 0 secret exposé
- 0 PII dans rapport

---

## Verdict

**PH-WEBSITE-T8.12AQ.4.1 - TERMINÉ**

**Verdict : GO PROD**

**MEDIA BUYER LP AUTONOMY READY - TRY.KEYBUZZ.IO ACCEPTED BY CAMPAIGN QA - OFFICIAL MEDIA BUYER TRACKING CONTRACT CREATED - CTA URL CONTRACT / UTM CLICK ID FORWARDING / MARKETING OWNER / PROMO RULES DOCUMENTED - META PIXEL ALONE CLARIFIED AS INSUFFICIENT - NO FAKE EVENTS - NO CHECKOUT - NO PAYMENT - NO DB / STRIPE / CAPI MUTATION - GITOPS STRICT**
