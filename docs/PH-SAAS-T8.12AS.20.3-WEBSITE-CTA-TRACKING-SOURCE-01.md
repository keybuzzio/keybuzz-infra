# PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-SOURCE-01

> Date : 2026-05-21
> Linear : KEY-340 (primary) ; KEY-337 (parent) ; KEY-338, KEY-339, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.3 WEBSITE CTA TRACKING SOURCE PATCH
> Environnement : SOURCE PATCH Website uniquement / aucun build / aucun deploy

## VERDICT

GO SOURCE PATCH WEBSITE CTA TRACKING READY PH-SAAS-T8.12AS.20.3

- Reserve R2 PH-20.1 ADRESSEE : 11 nouveaux callsites `trackMarketingClick` ajoutes sur 4 fichiers (about, home, features, footer).
- Couverture reelle PRE-PATCH meilleure que l audit PH-20.1 ne le pensait (wrapper `MarketingCTA` utilise sur home 8/8 et features 8/8) : audit corrige dans ce rapport.
- 0 fake event ajoute. 0 PII trackee. presence flags only via helper existant `trackMarketingClick`.
- Lint delta vs baseline = 0 (63 erreurs preexistantes maintenues, apostrophes francaises dans content original, hors scope).
- Typecheck `npx tsc --noEmit` : 0 erreur.
- Commit Website `6af74a2` pushe sur `main`.
- Runtime Website DEV `v0.6.18-ga4-cleanup-dev` INCHANGE.
- Runtime Website PROD `v0.6.18-ga4-cleanup-prod` INCHANGE.

Aucun build, aucun docker push, aucun deploy, aucun kubectl, aucun secret affiche, aucun ticket Linear ferme.

## E0 PREFLIGHT

### Bastion install-v3

| Indicateur | Valeur |
|---|---|
| hostname | install-v3 |
| IP publique | 46.62.171.61 |
| date UTC | 2026-05-21 14:15:18 |

### Repos Git

| Repo | Branche | HEAD avant | HEAD apres | Origin | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-website | main | 3baecc2 fix(website): renomme flag GA4 _gl_present | 6af74a2 feat(website): track marketing CTA | OK 6af74a2 | 0 | OK push |
| keybuzz-infra | main | 1cc30fb (PH-20.2 APPLY PROD) | (pending) | OK | 0 | OK |

### Runtime Website K8s

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | OK INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | OK INCHANGE |

## E1 AUDIT CTA EXISTANT (CORRECTION PH-20.1)

L audit PH-20.1 reservait R2 en disant "CTA home + pages secondaires non trackes" : grep `trackMarketingClick` retourne 0 sur home, but le projet utilise un wrapper composant `MarketingCTA` (dans `src/components/MarketingCTA.tsx`) qui appelle `trackMarketingClick` en interne via `onClick`. L audit a sous-estime la couverture reelle. Correction observee ici :

| Fichier | CTA detectes | MarketingCTA wrapper | trackMarketingClick direct | Couverture reelle PRE-patch | Priorite |
|---|---|---|---|---|---|
| `src/app/page.tsx` home | 9 (8 MarketingCTA + 1 Link amazon bandeau) | 8 | 0 | 8/9 OK | P1 (1 Link amazon manquant) |
| `src/app/pricing/page.tsx` | 7 | 0 | 7 (style direct) | 7/7 OK | (preserve) |
| `src/app/features/page.tsx` | 9 (8 MarketingCTA + 1 Link amazon) | 8 | 0 | 8/9 OK | P1 (1 Link amazon manquant) |
| `src/app/about/page.tsx` | 3 (Links manuels) | 0 | 0 | **0/3 NON TRACKE** | P1 |
| `src/app/contact/page.tsx` | 0 marketing | 0 | 0 | n/a (form distinct) | n/a |
| `src/app/amazon/page.tsx` | 3 (Links pages sub-amazon + contact) | 0 | 0 | 0/3 (non-commercial direct) | P3 SKIP |
| `src/components/Navbar.tsx` | 5 | 0 | 5 | 5/5 OK | (preserve) |
| `src/components/Footer.tsx` | 4 product + 3 amazon + ... = 13 dont 6 marketing utiles | 0 | 0 | **0/6 NON TRACKE** | P2 |

## E2 DESIGN CTA IDs

11 nouveaux callsites `trackMarketingClick` ajoutes selon cette table :

| CTA | Page | cta_id | cta_location | cta_destination | Justification |
|---|---|---|---|---|---|
| About hero "Voir comment KeyBuzz fonctionne" | about | about_hero_secondary_features | hero | /features | CTA features pre-final |
| About final "Decouvrir KeyBuzz" | about | about_final_primary_features | final | /features | conversion features |
| About final "Comparer les offres" | about | about_final_secondary_pricing | final | /pricing | conversion pricing |
| Home reassurance "Voir notre politique Amazon" | homepage | homepage_reassurance_amazon_link | after_reassurance | /amazon | bandeau secondaire Amazon |
| Features marketplaces "En savoir plus Amazon" | features | features_marketplaces_amazon_link | after_marketplaces | /amazon | bandeau Amazon |
| Footer product (3 IDs dynamiques) | footer | footer_product_<name> | footer_product | /features, /pricing, /#marketplaces | footer marketing intent |
| Footer amazon (3 IDs dynamiques) | footer | footer_amazon_<name> | footer_amazon | /amazon, /amazon/data-usage, /amazon/security | footer amazon intent |

Note : `footer_product_*` et `footer_amazon_*` utilisent template literal `${link.name.toLowerCase().replace(/\\s+/g, "_")}` pour generer IDs ASCII propres a partir du nom du link. cta_intent dynamique selon destination (pricing / features / amazon / learn_more).

## E3 PATCH SOURCE

### Diff stat

| Fichier | Changement | Risque | Validation |
|---|---|---|---|
| `src/app/about/page.tsx` | +49/-3 : import trackMarketingClick + 3 onClick blocks | Bas (use_client deja present) | tsc OK, lint delta 0 |
| `src/app/page.tsx` home | +17/-1 : import trackMarketingClick + 1 onClick block (Link amazon bandeau) | Bas (use_client deja present) | tsc OK, lint delta 0 |
| `src/app/features/page.tsx` | +17/-1 : import + 1 onClick block (Link amazon bandeau) | Bas (use_client deja present) | tsc OK, lint delta 0 |
| `src/components/Footer.tsx` | +25/-0 : use client + import + product/amazon map onClick blocks | Bas (Footer pur UI, pas de hooks) | tsc OK, lint delta 0 |

Total : 4 files changed, 103 insertions(+), 5 deletions(-).

### Pattern utilise

Identique au pattern `pricing/page.tsx` existant (qui a 7/7 callsites) :

```tsx
<Link
  href="/features"
  onClick={() => {
    trackMarketingClick({
      cta_id: "about_hero_secondary_features",
      cta_label: "Voir comment KeyBuzz fonctionne",
      cta_location: "hero",
      cta_destination: "/features",
      cta_variant: "secondary",
      cta_intent: "features",
      surface: "about",
    });
  }}
  className="..."
>
  Voir comment KeyBuzz fonctionne
</Link>
```

Footer utilise template literals pour generer cta_id dynamique dans le `.map()` :

```tsx
{footerLinks.product.map((link) => (
  <li key={link.name}>
    <Link
      href={link.href}
      onClick={() => {
        trackMarketingClick({
          cta_id: `footer_product_${link.name.toLowerCase().replace(/\s+/g, "_")}`,
          ...
        });
      }}
      ...
    >
      {link.name}
    </Link>
  </li>
))}
```

## E4 TESTS SOURCE

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| `npx tsc --noEmit` | 0 erreur | 0 erreur | OK |
| `npx eslint <fichiers patches>` | delta 0 erreur vs baseline | 63 baseline -> 63 post-patch (toutes preexistantes apostrophes content original) | OK delta 0 |
| Stash + lint baseline | meme count vs post-patch | 63 vs 63 | OK confirme aucune nouvelle erreur introduite |
| `npx eslint` global | n/a | 278 problemes globaux (Reveal.tsx + autres fichiers hors scope) | preexistant, hors scope |

### Assertions grep

| Pattern | Avant | Apres | Delta | Verdict |
|---|---|---|---|---|
| `trackMarketingClick` total Website | 17 callsites | 28 callsites (17 + 11 nouveaux) | +11 | OK |
| `MarketingCTA` wrapper | 16 occurrences (8 home + 8 features) | 16 | 0 | OK preserve |
| `marketing_cta_click` (helper) | 1 source | 1 source | 0 | OK helper inchange |
| `"Lead"` | preexistant n/a | preexistant n/a | 0 | OK pas d ajout |
| `"Purchase"` | 0 | 0 | 0 | OK |
| `"StartTrial"` | 0 | 0 | 0 | OK |
| `"CompletePayment"` | 0 | 0 | 0 | OK |
| `"SubmitForm"` | 0 | 0 | 0 | OK |
| `"InitiateCheckout"` | 0 | 0 | 0 | OK |
| `AW-` Google Ads direct | 0 | 0 | 0 | OK |
| `fbq(` nouveau ou ajoute | 0 nouveau ajoute par patch | 0 | 0 | OK |
| `ttq.` nouveau ou ajoute | 0 nouveau ajoute par patch | 0 | 0 | OK |
| pricing callsites preserves | 7 | 7 | 0 | OK |
| Navbar callsites preserves | 5 | 5 | 0 | OK |

## E5 COMMIT + PUSH WEBSITE

| Commit | Repo | Branche | Hash | Push | Verdict |
|---|---|---|---|---|---|
| feat(website): track marketing CTA clicks on about + footer + amazon links | keybuzz-website | main | `6af74a2` | OK 3baecc2..6af74a2 | OK local==origin `6af74a24be372a54319e1e65722841bbfda4d234` |

Diffstat commit : 4 files changed, 103 insertions(+), 5 deletions(-).

## E6 NO FAKE METRICS / NO FAKE EVENTS

### Constats

- 11 nouveaux callsites emettent uniquement `marketing_cta_click` via helper existant `trackMarketingClick`.
- Helper marketing-tracking.ts inchange : consent-aware, presence flags only (gclid_present, fbclid_present, ttclid_present, li_fat_id_present, cross_domain_gl_present, marketing_owner_tenant_id_present).
- 0 nouveau event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute.
- 0 nouveau pixel Meta/TikTok/LinkedIn injecte.
- 0 PII envoyee : cta_id, cta_label, cta_location, cta_destination, cta_variant, cta_intent, surface uniquement (tous statiques ou derives de link.name/href).
- 0 KPI fabrique.

### Event table

| Event | Type | Source | Destination | Statut |
|---|---|---|---|---|
| marketing_cta_click | client GA4 | helper trackMarketingClick consent-aware | GA4 G-R3QQDYEBFG via SGTM t.keybuzz.pro | ACTIF (existant), couverture +11 callsites |
| Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout | conversion publicitaire | aucun ajout cote Website | aucun | INCHANGE INACTIF |
| AW- Google Ads tag direct | tracking publicitaire | aucun | aucun | INACTIF |

## E7 RUNTIME PRESERVE

| Service | Image runtime | Ready | Preserve |
|---|---|---|---|
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | 1/1 | INCHANGE |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | INCHANGE |
| keybuzz-client-dev | v3.5.206-clarity-register-dev | 1/1 | INCHANGE |
| keybuzz-client-prod | v3.5.200-clarity-register-prod | 1/1 | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN build / docker push.
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN changement Client / API / Admin / SGTM / Addingwell / GA4 ID / Meta ID / TikTok ID / LinkedIn ID.
- AUCUN nouveau Pixel injecte.
- AUCUN event conversion fake.
- AUCUN checkout/test event envoye.
- AUCUN PII tracke.
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN Linear ticket cree, ferme, ou statut modifie automatiquement (commentaire seul).
- Bastion install-v3 (46.62.171.61) uniquement.

## GAPS

1. **About** : 3 nouveaux callsites OK. Si Ludovic veut harmoniser sur le pattern MarketingCTA, un refactor ulterieur peut remplacer les `<Link onClick>` par `<MarketingCTA>`.
2. **Amazon page** (`src/app/amazon/page.tsx`) : SKIP intentionnel. Les 3 Links sont sub-pages amazon (data-usage, security) + 1 Link contact. Pas de CTA commercial direct vers pricing/features/register. Si Ludovic veut tracker `/contact` depuis amazon, ouvrir PH ulterieure.
3. **Contact page** : 0 callsites marketing necessaires. Le form submit a son propre helper `trackContactSubmit` dans `src/lib/tracking.ts` (non touche).
4. **Footer legal/company sections** : SKIP intentionnel. Tracker `/privacy`, `/cookies`, `/terms`, `/sla`, `/contact`, `/legal` comme CTA marketing est inadequat. Si Ludovic veut tracker contact depuis footer, ouvrir PH ulterieure.
5. **Lint baseline 63 erreurs preexistantes** : apostrophes francaises content original + 2 warnings Reveal imports unused. Hors scope PH-20.3.
6. **Lint global 278 problemes** : `src/components/Reveal.tsx` `react-hooks/set-state-in-effect`. Hors scope.

## LINEAR KEY-340

Brouillon comment a poster manuellement (ou via auth API token) :

```
PH-SAAS-T8.12AS.20.3 source patch Website CTA tracking PRET (2026-05-21).

Verdict : GO SOURCE PATCH WEBSITE CTA TRACKING READY.

Commit Website : 6af74a2 (feat(website): track marketing CTA clicks on about + footer + amazon links)
Branche : main
Push : OK 3baecc2..6af74a2

Correction audit PH-20.1 : la reserve R2 surestimait les manques. La home et features utilisent un wrapper MarketingCTA (16 occurrences, 100% tracks via onClick interne). Vraies lacunes :
- about/page.tsx : 0/3 -> 3/3 OK
- home Link amazon bandeau : 0/1 -> 1/1 OK
- features Link amazon bandeau : 0/1 -> 1/1 OK
- Footer product+amazon : 0/6 -> 6/6 OK (avec use client + IDs dynamiques)

Couverture totale Website trackMarketingClick : 17 callsites -> 28 callsites (+11).
+ MarketingCTA wrapper : 16 occurrences preserves.

No fake events. presence flags only. 0 PII trackee.

Lint delta = 0 vs baseline (toutes erreurs preexistantes content apostrophes). Typecheck OK.

Reserve R2 PH-20.1 ADRESSEE.

Prochaine phrase GO attendue : GO BUILD WEBSITE CTA TRACKING DEV PH-SAAS-T8.12AS.20.3
```

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH WEBSITE CTA TRACKING READY PH-SAAS-T8.12AS.20.3 |
| Bastion | install-v3 46.62.171.61 |
| keybuzz-website HEAD apres push | 6af74a2 |
| keybuzz-website branche | main |
| Commit Website | feat(website): track marketing CTA clicks on about + footer + amazon links |
| Files changed | 4 (about/page.tsx, page.tsx, features/page.tsx, Footer.tsx) |
| Insertions / deletions | +103 / -5 |
| trackMarketingClick total Website | 17 callsites pre -> 28 callsites post (+11) |
| MarketingCTA wrapper | 16 preserves |
| CTA Home | 8/8 OK (MarketingCTA) + 1 amazon bandeau ajoute = 9/9 OK |
| CTA Features | 8/8 OK (MarketingCTA) + 1 amazon bandeau ajoute = 9/9 OK |
| CTA About | 3/3 OK ajoute |
| CTA Footer product+amazon | 6/6 OK ajoute |
| CTA Pricing | 7/7 OK preserve |
| CTA Navbar | 5/5 OK preserve |
| No fake events delta | 0 |
| Typecheck | 0 erreur |
| Lint delta vs baseline | 0 nouvelle erreur |
| Runtime Website DEV/PROD | INCHANGES |
| Linear KEY-340 | brouillon comment fourni dans rapport (a poster manuellement ou via API auth) |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-SOURCE-01.md` (a commit/push apres ASCII OK) |
| Reserve R2 PH-20.1 | ADRESSEE |

### Prochaine phrase GO attendue

`GO BUILD WEBSITE CTA TRACKING DEV PH-SAAS-T8.12AS.20.3`

STOP.
