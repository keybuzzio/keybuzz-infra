# PH-WEBSITE-T8.12AS.17.0-PUBLIC-CTA-TRACKING-PASS-DEV-01

> Date : 2026-05-15
> Linear : KEY-322 related (suit AS.16.1-PROD Clarity activation)
> Phase : T8.12AS.17.0 (Website public CTA + marketing click tracking, source code patch DEV-first)
> Environnement : Source code commit pushed. STOP avant build DEV.

---

## 0. VERDICT

GO PUBLIC CTA TRACKING SOURCE READY.

Passe CTA marketing source code livree sur keybuzz-website. 2 nouveaux fichiers (helper consent-aware + composant MarketingCTA reusable) + 2 fichiers patches (homepage page.tsx + Navbar.tsx). Total : 4 fichiers, +363 / -8 lignes, commit `a0d0cb5` pushed sur origin main.

Taxonomie event stable definie : `marketing_cta_click` avec parametres standardises (cta_id, cta_label, cta_location, cta_destination, cta_variant, cta_intent, surface, page_path). Tous les CTAs instrumentes posent egalement des attributs HTML `data-track`, `data-cta-id`, `data-cta-location`, etc. pour Clarity heatmaps + QA + analyse media buyer.

Consent-aware strict : aucun event GA4 declenche tant que `keybuzz_cookie_consent.status !== "accepted"`. No-op en SSR, no-op si gtag absent, no-op silencieux jamais throw, jamais retarder la navigation.

Hors scope cette phase (decision pragmatique) :
- /pricing : deja partiellement instrumente via `tracking.ts` existant (trackSelectPlan + trackClickSignup) - alignement taxonomie marketing_cta_click reporte a AS.17.x dedie pour eviter touche fichier 700+ lignes
- /features : idem, instrumentation Hero + Final CTAs propose en AS.17.x dedie
- Footer : 16 links non instrumentes (juste les principaux Tarifs / Contact pourraient etre ajoutes en AS.17.x)
- /about, /amazon, /contact (deja trackContactSubmit), pages legales : pas de patch necessaire dans cette phase

Aucun build, aucun docker push, aucun deploy. STOP avant build DEV (GO Ludovic requis).

KEY-322 reste Open. Aucun ticket Linear cree. Aucun faux event. Aucune PII. Aucun changement Clarity Project ID.

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.17.0 source code DEV-first) :
- 4 fichiers commit `a0d0cb5` sur keybuzz-website main
- 0 patch Client / API / Admin / Backend
- 0 build / docker push / kubectl apply / manifest edit
- 0 modification runtime DEV ou PROD
- 0 modification CookieConsent / ClarityProvider / tracking.ts existant
- 0 modification Clarity Project ID `wrff07upjx`
- 0 changement Linear statut
- 0 faux event / fake review / fake metric

Actions effectuees :
- SSH read-only install-v3 (46.62.171.61 confirme)
- Agent Explore cartographie CTAs website public (13 routes)
- Creation helper `marketing-tracking.ts` consent-aware
- Creation component `MarketingCTA.tsx` reusable
- Patch `src/app/page.tsx` homepage (hero CTAs + nouveau bloc CTA mid-page + final CTAs)
- Patch `src/components/Navbar.tsx` (4 CTAs primaires desktop + mobile)
- git add + commit + push origin main

---

## 2. PREFLIGHT

### 2.1 SSH + bastion

| Champ | Valeur |
|---|---|
| Alias | install-v3 |
| IP serveur | 46.62.171.61 (conforme) |
| IP interdites | 51.159.99.247 (NON CONTACTE) |

### 2.2 Repos

| Repo | Branche | HEAD avant | HEAD apres |
|---|---|---|---|
| keybuzz-website | main | 2f684f9 (Dockerfile patch AS.16.1) | **a0d0cb5** (AS.17.0 CTA tracking pass) |
| keybuzz-infra | main | 8843b22 (AS.16.1-PROD rapport) | a inchange (sera mis a jour avec ce rapport) |

### 2.3 Runtime

| Service | DEV | PROD |
|---|---|---|
| keybuzz-website | v0.6.13-clarity-website-dev (UNCHANGED) | v0.6.13-clarity-website-prod (UNCHANGED) |

Aucun build, aucun deploy. Runtime preserve.

---

## 3. AUDIT CTA WEBSITE PUBLIC (cartographie cote source)

### 3.1 Routes publiques inventories (13)

| Route | Fichier source | Nature | CTAs presents avant AS.17.0 | Tracking avant |
|---|---|---|---|---|
| / (Homepage) | src/app/page.tsx | Hero sales landing | 4 (hero x2 + final x2) | AUCUN |
| /pricing | src/app/pricing/page.tsx | Plans + conversion | ~8 (3 plans + Enterprise + Final + FAQ) | Partiel (trackSelectPlan/trackClickSignup) |
| /features | src/app/features/page.tsx | Use cases + demo | 4 (hero x2 + final x2) | AUCUN |
| /about | src/app/about/page.tsx | Founder story | 1 | AUCUN |
| /contact | src/app/contact/page.tsx | Form contact | 1 submit | trackContactSubmit (existant) |
| /amazon | src/app/amazon/page.tsx | Integration SP-API | 0 CTA outbound | n/a |
| /amazon/security, /amazon/data-usage | StaticPage | Docs Amazon | 0 | n/a |
| /privacy, /terms, /legal, /cookies, /sla | StaticPage | Legal pages | 0 CTA marketing | n/a |

### 3.2 Components reusables

| Component | Path | Role | CTAs |
|---|---|---|---|
| Navbar | src/components/Navbar.tsx | Nav header | 4 (desktop: Creer un compte + Connexion ; mobile: idem) |
| Footer | src/components/Footer.tsx | Footer | 16 links (Products, Amazon, Legal, Social) - 0 instrumente |

### 3.3 Tracking helper existant

`src/lib/tracking.ts` (90 lignes) - SANS consent check :
- `trackEvent({ action, category, label, ... })`
- `trackViewPricing()`
- `trackSelectPlan(plan, cycle)` -> InitiateCheckout
- `trackClickSignup(plan)` -> Lead
- `trackContactSubmit()` -> Contact

NOTE : tracking.ts envoie aux pixels GA4 + Meta + TikTok sans verifier le consent banner CookieConsent. Risque pre-existant non resolu dans cette phase (out of scope AS.17.0). Ces fonctions restent utilisees par /pricing + /contact.

Pour la **nouvelle instrumentation marketing AS.17.0**, on cree un helper SEPARE consent-aware (cf section 4).

---

## 4. NOUVEAU helper `src/lib/marketing-tracking.ts`

### 4.1 Design

Helper central consent-aware pour les micro-conversions marketing CTA. SEPARE de `tracking.ts` pour ne pas casser l existant (qui utilise des events de conversion comme Lead / InitiateCheckout).

Logique :
- Read `localStorage.getItem("keybuzz_cookie_consent")` (meme key que CookieConsent + ClarityProvider)
- Parse JSON, check `data.status === "accepted"`
- Si OK : appelle `window.gtag("event", "marketing_cta_click", {...params})`
- Si KO ou erreur : silent fail-safe, ne jamais throw

### 4.2 API publique

```typescript
export function trackMarketingClick(params: MarketingClickParams): void
```

Avec types :
- `CtaVariant` : "primary" | "secondary" | "outline" | "link"
- `CtaIntent` : "signup" | "pricing" | "demo" | "contact" | "features" | "learn_more" | "login" | "amazon" | "social"
- `CtaSurface` : "homepage" | "pricing" | "features" | "about" | "contact" | "amazon" | "navbar" | "footer"

### 4.3 Anti-regression

- `if (typeof window === "undefined") return` -> no-op SSR
- `if (!hasAnalyticsConsent()) return` -> no-op si consent != accepted
- `if (typeof gtag !== "function") return` -> no-op si GA4 absent
- `try { gtag(...) } catch { /* silent */ }` -> ne jamais throw
- Synchrone non-blocking (gtag SDK gere fire-and-forget)
- Ne jamais retarder la navigation : Next.js Link navigue immediatement, onClick s execute en parallel

---

## 5. NOUVEAU component `src/components/MarketingCTA.tsx`

### 5.1 Design

Component reusable qui wrap Link/anchor avec :
- data-* attributes stables (data-track, data-cta-id, data-cta-location, data-cta-destination, data-cta-variant, data-cta-intent) pour Clarity heatmaps + QA + media buyer analysis
- onClick handler qui appelle `trackMarketingClick`
- Variants Tailwind alignes sur styles existants : `primary` (btn-primary kb-btn-polish), `secondary` (btn-outline-visible kb-btn-polish), `outline` (btn-outline), `link` (inline-flex text-cyan)

### 5.2 API publique

```tsx
<MarketingCTA
  href="/pricing"
  ctaId="homepage_hero_primary_pricing"
  ctaLocation="hero"
  ctaIntent="pricing"
  surface="homepage"
  variant="primary"
>
  Essayer 14 jours gratuitement
</MarketingCTA>
```

### 5.3 Routing intelligent

- `external={true}` -> `<a target="_blank" rel="noopener noreferrer">`
- `href` commencant par `#` -> `<a>` (anchor scroll)
- Sinon -> `<Link>` Next.js

---

## 6. TAXONOMIE EVENTS (stable, doc reference)

### 6.1 Event name unique

```
marketing_cta_click
```

### 6.2 Parametres standardises

| Param | Type | Exemple |
|---|---|---|
| cta_id | string stable | "homepage_hero_primary_pricing" |
| cta_label | string visible | "Essayer 14 jours gratuitement" |
| cta_location | section name | "hero" / "after_steps" / "final" / "navbar_desktop" |
| cta_destination | URL cible | "/pricing" / "https://client.keybuzz.io" |
| cta_variant | "primary"\|"secondary"\|"outline"\|"link" | "primary" |
| cta_intent | "signup"\|"pricing"\|"demo"\|"contact"\|"features"\|"learn_more"\|"login"\|"amazon"\|"social" | "pricing" |
| surface | "homepage"\|"pricing"\|"features"\|"about"\|"contact"\|"amazon"\|"navbar"\|"footer" | "homepage" |
| page_path | window.location.pathname auto-injecte | "/" / "/pricing" |

### 6.3 cta_id stable convention

Format : `{surface}_{location}_{variant}_{intent}` ou `{surface}_{location}_{purpose}`.

Exemples instrumentes dans AS.17.0 :

| cta_id | Page | Section | Label | Destination | Intent |
|---|---|---|---|---|---|
| `homepage_hero_primary_pricing` | / | hero | Essayer 14 jours gratuitement | /pricing | pricing |
| `homepage_hero_secondary_learn_more` | / | hero | Voir comment ca marche | #comment | learn_more |
| `homepage_midpage_primary_pricing` | / | after_steps (nouveau bloc) | Demarrer l'essai gratuit | /pricing | pricing |
| `homepage_midpage_secondary_features` | / | after_steps (nouveau bloc) | Voir les fonctionnalites | /features | features |
| `homepage_final_primary_pricing` | / | final | Demarrer l'essai gratuit | /pricing | pricing |
| `homepage_final_secondary_features` | / | final | Decouvrir les fonctionnalites | /features | features |
| `navbar_primary_signup` | (all) | navbar_desktop | Creer un compte | https://client.keybuzz.io/signup | signup |
| `navbar_primary_login` | (all) | navbar_desktop | Connexion | https://client.keybuzz.io | login |
| `navbar_mobile_signup` | (all) | navbar_mobile | Creer un compte | https://client.keybuzz.io/signup | signup |
| `navbar_mobile_login` | (all) | navbar_mobile | Connexion | https://client.keybuzz.io | login |

### 6.4 Parametres INTERDITS (jamais transmis)

email, phone, company typed, name, message, tenant_id, user_id, cookie raw, gclid/fbclid/ttclid/li_fat_id raw, token, session_id.

---

## 7. HOMEPAGE CTA AJOUTS (4 CTAs instrumentes + 1 nouveau bloc)

### 7.1 CTAs hero (existants migres -> MarketingCTA)

Avant : `<Link href="/pricing" className="btn btn-primary kb-btn-polish ...">Essayer...</Link>` (0 tracking)

Apres : `<MarketingCTA href="/pricing" ctaId="homepage_hero_primary_pricing" ...>Essayer...</MarketingCTA>` (tracking auto + data-*)

### 7.2 NOUVEAU bloc CTA mid-page

Section ajoutee entre "Comment ca marche" (section 3) et "Benefices cles" (section 4). Backgrounded `bg-gradient-to-r from-[#26a9e0]/5 to-[#224282]/5`, padding compact (pt-12 pb-12).

Texte :
- Titre : "Pret a essayer KeyBuzz sur vos messages reels ?"
- Sous-texte : "14 jours d essai gratuit. Aucun engagement. L IA prepare vos premieres reponses des la connexion Amazon."
- 2 boutons :
  - "Demarrer l essai gratuit" (primary, -> /pricing, cta_id=homepage_midpage_primary_pricing)
  - "Voir les fonctionnalites" (secondary, -> /features, cta_id=homepage_midpage_secondary_features)

### 7.3 CTAs final (existants migres)

Avant : 2 `<Link>` sans tracking. Apres : 2 `<MarketingCTA>` avec tracking + data-*.

---

## 8. NAVBAR CTAs INSTRUMENTES (4 CTAs)

Pattern : ajout inline `onClick={() => trackMarketingClick({...})}` + `data-*` attributes sur les 4 CTAs primaires (desktop x2 + mobile x2). Aucun changement design, aucun nouveau component.

Resultat :
- "Creer un compte" desktop : cta_id=navbar_primary_signup
- "Connexion" desktop : cta_id=navbar_primary_login
- "Creer un compte" mobile : cta_id=navbar_mobile_signup
- "Connexion" mobile : cta_id=navbar_mobile_login

Les liens navigation interne ("Accueil", "Services", "Tarifs", "Amazon", "Contact") ne sont PAS instrumentes dans cette phase (faible volume de clics analytics, scope evite).

---

## 9. PRICING + FEATURES + FOOTER (hors scope cette phase)

### 9.1 Pricing /pricing

Deja instrumente avec `tracking.ts` (trackSelectPlan + trackClickSignup) sur les 3 plans + final CTA. Alignement sur taxonomie marketing_cta_click reporte a AS.17.x dedie (necessite edit fichier 700+ lignes, scope evite).

CTAs non instrumentes a noter (potentiel AS.17.x) :
- Enterprise "Parler a un expert" -> /contact
- FAQ "Consultez nos offres" -> /pricing (lien inline)

### 9.2 Features /features

4 CTAs presents sans tracking. Hors scope AS.17.0 pour eviter scope explosion (fichier 655+ lignes). Propose en AS.17.x dedie : instrumenter Hero CTAs + Final CTAs.

### 9.3 Footer

16 links non instrumentes. Hors scope AS.17.0. Propose en AS.17.x dedie pour instrumenter au moins les 4 principaux (Tarifs, Contact, Services, Demo).

### 9.4 Autres pages publiques

- /about : 1 CTA "Voir comment ca marche" -> /features. Faible volume, faible priorite, hors scope.
- /contact : deja trackContactSubmit (existant).
- /amazon, /amazon/* : pages techniques sans CTA marketing critique.
- Pages legales : pas de CTAs marketing.

---

## 10. CONSENT PROOF

| Verification | Resultat |
|---|---|
| `marketing-tracking.ts` read localStorage CONSENT_KEY | OUI ("keybuzz_cookie_consent") |
| Check status === "accepted" avant emit | OUI (no-op sinon) |
| Compatible avec ClarityProvider existant (meme key) | OUI |
| Compatible avec CookieConsent v2 existant | OUI |
| No-op SSR | OUI (typeof window check) |
| No-op gtag absent | OUI (typeof gtag check) |
| No-op silent error | OUI (try/catch) |
| Ne retarde JAMAIS la navigation | OUI (Next.js Link navigation synchrone, onClick fire-and-forget) |

---

## 11. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 event Lead / InitiateCheckout / Purchase / Signup / Conversion declenche par le nouveau helper
- 0 fake review / fake logo client / fake chiffres ajoute sur la homepage
- 0 simulation de signup / paiement
- 0 PII transmise dans les params (email, phone, company typed, tenant_id, user_id, tokens, click_ids raw)
- 0 modification des SDK existants (GA4, Meta, TikTok, LinkedIn, Clarity)
- 0 modification CookieConsent ou ClarityProvider
- 0 modification Clarity Project ID `wrff07upjx`

Les events autorises et utilises uniquement :
- `marketing_cta_click` avec params stable (cta_id, cta_label, cta_location, cta_destination, cta_variant, cta_intent, surface, page_path)

---

## 12. CLARITY COMPATIBILITY

| Aspect | Compatibility |
|---|---|
| ClarityProvider existant non touche | OK (jamais modifie) |
| Same CookieConsent key | OK (`keybuzz_cookie_consent` partage) |
| Clarity heatmaps sur nouveau bloc mid-page | OK (Clarity capture le DOM globalement, aucun setup specifique necessaire) |
| Clarity click tracking sur data-* | OK (Clarity peut filtrer par data-cta-id pour reports cibles) |
| Project ID wrff07upjx PROD inchange | OK (aucune modification) |

Le nouveau bloc CTA mid-page + les 4 hero/final CTAs avec data-* permettront a Antoine et l agence de creer dans Clarity dashboard :
- Heatmaps des nouveaux blocs (scroll + clic + rage clicks)
- Filtres click par `data-cta-id` ou `data-cta-intent`
- Comparaison de variantes A/B (si Ludovic ajoute des variantes plus tard)

---

## 13. GA4 / sGTM COMPATIBILITY

Le helper `marketing-tracking.ts` envoie via `window.gtag("event", "marketing_cta_click", params)`.

Cote GA4 :
- L event `marketing_cta_click` apparaitra dans GA4 Realtime + Events report
- Tous les params (cta_id, cta_label, etc.) doivent etre crees comme custom dimensions dans GA4 Admin -> Events -> Modify event (a faire par Ludovic ou agence)
- Filtres GA4 possibles : `cta_intent=pricing` pour voir les clics convertissants

Cote sGTM (`t.keybuzz.pro`) :
- Si sGTM est configure comme transport pour GA4, les events `marketing_cta_click` passeront par sGTM avant GA4
- Server container peut enrichir les params (ajouter session_id, etc.) sans toucher au code Client

---

## 14. ANTI-REGRESSION (verification source)

Verifications avant commit :
- 0 modification SaaS Client (`keybuzz-client` non touche)
- 0 modification Admin v2 (`keybuzz-admin-v2` non touche)
- 0 modification API (`keybuzz-api` non touche)
- 0 modification Backend (`keybuzz-backend` non touche)
- 0 modification tracking.ts existant
- 0 modification Analytics.tsx
- 0 modification ClarityProvider.tsx
- 0 modification CookieConsent.tsx
- 0 modification /cookies, /privacy, /terms, /legal, /sla pages
- 0 fake review/logo/chiffre ajoute
- 0 modification design/layout existant (sauf nouveau bloc CTA mid-page)
- 0 changement Linear status
- 0 secret / token / PII dans le code

Inbox / Brouillon IA / tenant switcher / escalation / playbooks / channels / SaaS authenticated : tous preserves (Client repo non touche).

---

## 15. RISQUES / GAPS

| Risque | Severity | Mitigation |
|---|---|---|
| Tracking helper non utilise sur /pricing /features /footer | Medium | Acceptable cette phase, propose AS.17.x dedie |
| `tracking.ts` existant n a pas de consent check | Medium (pre-existant) | Hors scope AS.17.0. AS.17.x ulterieur peut aligner |
| Nouveau bloc CTA mid-page : impact UX/conversion non mesure | Low | A mesurer via Clarity + GA4 apres deploy DEV + QA |
| Surcharge CTAs homepage (5 CTAs total : hero x2 + midpage x2 + final x2) | Low | Espacement section par section evite la fatigue |
| Mobile responsive du nouveau bloc | Low | Pattern `flex-col sm:flex-row gap-3 justify-center` aligne sur hero/final existants |

---

## 16. PLAN PROCHAINES PHASES

### 16.1 AS.17.0 build DEV (apres GO Ludovic)

- Build website DEV from-git commit a0d0cb5
- Tag propose : `v0.6.14-cta-tracking-pass-dev`
- KEY-308 OCI labels obligatoires
- KEY-302 bundle check DEV : api-dev.keybuzz.io present, api.keybuzz.io absent
- STOP avant docker push

### 16.2 AS.17.0 DEV deploy + QA (apres GO build)

- docker push v0.6.14-cta-tracking-pass-dev
- Manifest edit k8s/website-dev/deployment.yaml v0.6.13 -> v0.6.14
- kubectl apply + rollout
- QA Ludovic preview.keybuzz.io : 
  - Nouveau bloc CTA mid-page visible apres "Comment ca marche"
  - Hero CTAs cliquables
  - Final CTAs cliquables
  - Navbar CTAs (desktop + mobile)
  - Accepter consent -> verifier dans Network DevTools : appel `gtag('event', 'marketing_cta_click', {cta_id: "...", ...})` apres clic CTA

### 16.3 AS.17.0 PROD (apres AS.17.0 DEV QA OK)

- Build PROD v0.6.14-cta-tracking-pass-prod
- KEY-302 bundle PROD : api.keybuzz.io present, api-dev absent, wrff07upjx present (Clarity preserve)
- docker push + GitOps PROD apply
- QA Ludovic www.keybuzz.pro + Clarity dashboard + GA4 events

### 16.4 AS.17.x dedies (futurs)

- AS.17.1 /pricing taxonomie alignment marketing_cta_click (preserve tracking.ts existant)
- AS.17.2 /features Hero + Final CTAs instrumentation
- AS.17.3 Footer principal CTAs (Tarifs, Contact, Services, Demo)
- AS.17.4 tracking.ts consent-aware refactor (resoudre risque pre-existant)
- AS.17.5 GA4 custom dimensions setup (cta_id, cta_intent, cta_variant) cote Ludovic
- AS.17.6 A/B test variantes CTA homepage (futur reviews/avis section)

---

## 17. LINEAR (commentaire propose KEY-322)

```
PH-WEBSITE-T8.12AS.17.0 source code pushed (commit a0d0cb5).

Public CTA + marketing click tracking pass source livree :

NOUVEAU :
- src/lib/marketing-tracking.ts (helper trackMarketingClick consent-aware, no-op si CookieConsent != accepted)
- src/components/MarketingCTA.tsx (component reusable avec data-* attributes + variants Tailwind alignes)

PATCHES :
- src/app/page.tsx (homepage) : 4 CTAs existants migres vers MarketingCTA (hero x2 + final x2) + 1 NOUVEAU bloc CTA mid-page apres "Comment ca marche" avec 2 boutons (Demarrer l essai / Voir les fonctionnalites)
- src/components/Navbar.tsx : 4 CTAs primaires (desktop + mobile : Creer un compte + Connexion) avec onClick + data-* attributes

Taxonomie event stable :
- event_name : marketing_cta_click
- params : cta_id, cta_label, cta_location, cta_destination, cta_variant, cta_intent, surface, page_path

10 cta_id stables documentes (homepage_hero_*, homepage_midpage_*, homepage_final_*, navbar_*).

Consent-aware :
- Aucun event GA4 sans consentement explicite via CookieConsent banner v2 (status === "accepted")
- Same key key `keybuzz_cookie_consent` partage avec ClarityProvider
- No-op SSR, no-op gtag absent, no-op silent error, ne jamais retarder la navigation
- Anti-regression : aucun changement tracking.ts existant, Analytics.tsx, ClarityProvider, CookieConsent

Hors scope cette phase (propose en AS.17.x ulterieur) :
- /pricing taxonomie alignment (deja instrumente partiellement via tracking.ts trackSelectPlan + trackClickSignup)
- /features Hero + Final CTAs
- Footer 16 links
- tracking.ts consent-aware refactor

No fake metrics :
- 0 fake review / logo / chiffre ajoute homepage
- 0 event Lead / InitiateCheckout / Purchase
- 0 PII / token / click_id raw
- 0 modification Clarity Project ID wrff07upjx

Anti-regression PROD :
- 0 modification Client / API / Admin / Backend
- 0 build / docker push / kubectl apply
- 0 changement runtime DEV ou PROD
- 0 modification CookieConsent ou ClarityProvider

Diff stat : 4 fichiers, +363 / -8 lignes, commit a0d0cb5 push origin main.

Prochaines etapes proposees (apres GO Ludovic) :
1. Build website DEV v0.6.14-cta-tracking-pass-dev from-git commit a0d0cb5
2. docker push + GitOps DEV apply
3. QA Ludovic preview.keybuzz.io (CTAs visibles + Clarity heatmaps + GA4 events apres consent)
4. PROMOTION PROD apres DEV QA OK
5. AS.17.x dedies pour pricing/features/footer

KEY-322 reste Open. KEY-301/KEY-313 Done. KEY-314 Open + pause.

Rapport : keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.0-PUBLIC-CTA-TRACKING-PASS-DEV-01.md
```

Aucun changement Linear statut.

---

## 18. COMMIT SUMMARY

| Repo | Branche | Commit | Changes |
|---|---|---|---|
| keybuzz-website | main | a0d0cb5 | +363 / -8 lignes, 4 fichiers (2 new + 2 patches) |
| keybuzz-infra | main | (ce rapport docs-only, en cours) | rapport AS.17.0 |

Fichiers touches keybuzz-website :
- NEW src/lib/marketing-tracking.ts (95 lignes)
- NEW src/components/MarketingCTA.tsx (131 lignes)
- M src/app/page.tsx (+76 / -8 lignes : homepage 4 CTAs + nouveau bloc)
- M src/components/Navbar.tsx (+61 lignes : 4 CTAs Navbar)

---

## 19. PHRASE CIBLE FINALE

Passe CTA marketing source code livree sur keybuzz-website. Helper trackMarketingClick consent-aware + composant MarketingCTA reusable + homepage instrumentee (4 CTAs migres + 1 nouveau bloc mid-page) + Navbar instrumente (4 CTAs primaires). Taxonomie event `marketing_cta_click` stable avec 10 cta_id documentes. Consent-aware respecte CookieConsent v2. Anti-regression : Client/API/Admin/Backend/tracking.ts/Analytics/ClarityProvider/CookieConsent tous preserves. Aucun fake review/metric. Commit a0d0cb5 pushed. KEY-322 reste Open. Aucun enchainement vers build DEV sans GO Ludovic explicite.

STOP
