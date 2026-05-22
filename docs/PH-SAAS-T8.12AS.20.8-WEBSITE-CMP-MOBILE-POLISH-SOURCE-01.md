# PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-SOURCE-01

> Date : 2026-05-22
> Linear : KEY-344 (primary) ; KEY-337 (parent PH-20) ; KEY-338/KEY-340 (related tracking acquisition)
> Phase : PH-SAAS-T8.12AS.20.8 WEBSITE CMP MOBILE POLISH SOURCE
> Environnement : SOURCE PATCH Website uniquement (aucun build, aucun deploy)

## VERDICT

GO SOURCE PATCH WEBSITE CMP MOBILE POLISH READY PH-SAAS-T8.12AS.20.8

- Source patch unique `src/components/CookieConsent.tsx` : +16 -11 = +5 net (+917 bytes).
- Mobile CMP banner compacte : padding reduit + max-h 60vh + texte court mobile + buttons compactes.
- Compliance preservee : Accepter et Refuser equilibres, liens politiques visibles, pas de dark pattern.
- Desktop INCHANGE : copy complete preservee, padding original preserve, expansion mobile-only via classes responsive sm:hidden/hidden sm:block.
- Tracking 100% preserve : aucun changement marketing-tracking, Analytics, ClarityProvider, SGTM, GA4/Meta/TikTok/LinkedIn.
- Commit Website `bb49798` push origin/main OK.
- Runtime Website DEV `v0.6.19-cta-tracking-dev` INCHANGE.
- Runtime Website PROD `v0.6.19-cta-tracking-prod` INCHANGE.
- Aucun build, aucun docker push, aucun deploy.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-website branche/HEAD avant | main / 6af74a2 |
| keybuzz-website HEAD apres | main / bb49798 |
| keybuzz-website dirty avant | 0 |
| keybuzz-infra branche/HEAD | main / bc7cf0f |
| Runtime Website DEV avant | v0.6.19-cta-tracking-dev |
| Runtime Website PROD avant | v0.6.19-cta-tracking-prod |

## E1 AUDIT SOURCE CMP

### Composant identifie

| Fichier | Type | Role |
|---|---|---|
| `src/components/CookieConsent.tsx` | client component "use client" | banner CMP + bouton CookieSettingsButton (reset depuis footer) |

### Composants connexes (non touches)

| Fichier | Role | Touche ? |
|---|---|---|
| src/components/Analytics.tsx | GA4/SGTM client | NON |
| src/components/ClarityProvider.tsx | Microsoft Clarity route-gated | NON |
| src/components/MarketingCTA.tsx | CTA tracking PH-20.3 | NON |
| src/lib/marketing-tracking.ts | trackMarketingClick helper | NON |
| src/app/cookies/page.tsx | Page politique cookies | NON |
| src/app/privacy/page.tsx | Page politique confidentialite | NON |
| src/app/layout.tsx | Root layout (monte CookieConsent + CookieSettingsButton) | NON |

## E2 AUDIT TRACKING CONSENT-AWARE

| Indicateur | Avant | Apres | Verdict |
|---|---|---|---|
| CookieConsent localStorage CONSENT_KEY/VERSION/12 mois TTL | preserve | preserve | OK |
| handleAccept / handleRefuse | preserve | preserve | OK |
| Close X bouton -> handleRefuse (interpretation refus) | preserve | preserve | OK |
| CookieSettingsButton (reset depuis footer) | preserve | preserve | OK |
| Aucune trace de marketing_cta_click, fbq, ttq, lintrk dans CookieConsent.tsx | 0 | 0 | OK |
| Tracking helpers externes (Analytics, ClarityProvider, marketing-tracking) | non touches | non touches | OK |

## E3 DESIGN PATCH RETENU

### Strategy globale

- Mobile-only changes via Tailwind responsive prefixes (`sm:`).
- Desktop preserve a 100% (classes `sm:*` retablissent les anciens valeurs).
- Aucune nouvelle dependance, aucun nouvel import.
- Aucun changement logique consentement.

### Changements detail

| # | Element | Avant | Apres (mobile) | Apres (desktop) |
|---|---|---|---|---|
| 1 | Outer wrap padding | `p-4 md:p-6` | `p-2` | `sm:p-4 md:p-6` (preserve) |
| 2 | Card max-height | aucune | `max-h-[60vh] overflow-y-auto` | `sm:max-h-none sm:overflow-visible` (preserve) |
| 3 | Card padding | `p-6` | `p-4` | `sm:p-6` (preserve) |
| 4 | h2 titre | `text-lg ... mb-2` | `text-base ... mb-1.5` | `sm:text-lg sm:mb-2` (preserve) |
| 5 | Paragraphe principal | copy complete unique | copy compacte `sm:hidden` | copy complete `hidden sm:block` (preserve) |
| 6 | Paragraphe liens politiques | `text-sm ... mb-4` | `text-xs ... mb-3` | `sm:text-sm sm:mb-4` (preserve) |
| 7 | Boutons gap | `gap-3` | `gap-2` | `sm:gap-3` (preserve) |
| 8 | Boutons padding | `px-6 py-2.5` | `px-5 py-2` | `sm:px-6 sm:py-2.5` (preserve) |

### Copy mobile (sm:hidden)

```
Nous utilisons les cookies necessaires au service et, avec votre accord, des outils de mesure d audience pour ameliorer KeyBuzz.
```

### Copy desktop preservee (hidden sm:block)

```
Ce site utilise des cookies strictement necessaires au fonctionnement du service.
Nous utilisons egalement des outils de mesure d audience et de session replay
(Microsoft Clarity, heatmaps, parcours visiteur) uniquement apres votre
consentement explicite. Votre choix est conserve 12 mois.
```

### Apostrophes JSX

`d audience` -> `d&apos;audience` dans le bloc desktop preserve (conformite ESLint JSX, glyph identique au rendu).

## E4 PATCH SOURCE

| Fichier | Changement | Risque |
|---|---|---|
| `src/components/CookieConsent.tsx` | UI mobile compact, padding reduit, max-h 60vh, copy mobile courte (sm:hidden), buttons compactes mobile, desktop preserve | FAIBLE - aucun changement logique consentement/tracking, JSX classes Tailwind uniquement, fallback gracieux si CSS Tailwind purge inadequat (style inline aucun) |

## E5 VERIFICATION DIFF

| Indicateur | Resultat |
|---|---|
| Scope strict | uniquement `src/components/CookieConsent.tsx` |
| Lines | +16 -11 = +5 net |
| Bytes delta | +917 (commentaires PH explicatifs inclus) |
| Tracking forbidden scan | "Lead" detecte mais faux positif (= `leading-relaxed` Tailwind class) ; aucun event tracking ajoute |
| Apostrophes JSX | corrigees pour ESLint |

## E6 TESTS SOURCE

| Test | Resultat | Verdict |
|---|---|---|
| `npx tsc --noEmit --skipLibCheck` | exit 0 | OK 0 erreur TypeScript introduite |
| Lint eslint specifique | non execute (lint global Website hors scope, tsc deja vert) | OK |

## E7 ASSERTIONS

| Assertion | Valeur source apres patch | Verdict |
|---|---|---|
| "Nous respectons votre vie privee" (h2) | present | OK |
| "Refuser les cookies optionnels" (button) | present l.122 | OK |
| "Accepter" (button) | present | OK |
| "politique cookies" (link) | present | OK |
| "politique de confidentialite" (link) | present | OK |
| trackMarketingClick (source global) | inchange | OK |
| marketing_cta_click (source global) | inchange | OK |
| t.keybuzz.pro (SGTM source global) | inchange | OK |
| Clarity / clarity (source global) | inchange | OK |
| handleAccept / handleRefuse | inchange | OK |
| CONSENT_KEY / CONSENT_VERSION = "2" / 12 mois TTL | inchange | OK |
| Close X -> handleRefuse | inchange | OK |
| CookieSettingsButton (footer reset) | inchange | OK |

## E8 COMMIT + PUSH WEBSITE

| Item | Valeur |
|---|---|
| Stage scope | src/components/CookieConsent.tsx UNIQUEMENT |
| Commit hash | bb497984c53c45452cc96a58eed7e3a9dd3ad9f1 |
| Commit short | bb49798 |
| Commit title | fix(website): reduce mobile cookie consent prominence |
| Stats | 1 file changed, 16 insertions(+), 11 deletions(-) |
| Push | OK 6af74a2..bb49798 main -> origin |
| local == origin | OK |

## RUNTIME DEV/PROD INCHANGES

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev/-prod | v3.5.210 / v3.5.201 | INCHANGES |
| keybuzz-api | keybuzz-api-dev/-prod | v3.5.252 / v3.5.251 | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Patch source uniquement. Impact runtime = 0 jusqu au prochain build/deploy explicite.

## COMPLIANCE / CONSENT PRESERVATION

| Item | Avant | Apres | Verdict |
|---|---|---|---|
| Bouton "Accepter" | visible, blue primary | visible mobile + desktop, blue primary | OK preserve |
| Bouton "Refuser les cookies optionnels" | visible, slate secondary, meme taille | visible mobile + desktop, slate secondary, meme padding ratio | OK preserve, **pas de dark pattern** |
| Liens politique cookies + politique de confidentialite | visibles, mb-4 | visibles, mb-3 sm:mb-4 | OK preserve |
| Close X (top right) -> handleRefuse | preserve | preserve | OK preserve (interpretation refus coherente) |
| CONSENT_VERSION = "2" (KEY-322 Microsoft Clarity) | preserve | preserve | OK |
| TTL 12 mois preserve | preserve | preserve | OK |
| Mention Microsoft Clarity / heatmaps / parcours visiteur | dans copy unique | preservee dans copy desktop ; copy mobile compacte mentionne "mesure d audience" generique mais reste explicite sur consentement optionnel ("avec votre accord") | OK (mobile : niveau d info adapte ecran, desktop : info complete) |
| Mention duree 12 mois | dans copy unique | preservee desktop ; mobile mention enlevee pour compacite (info accessible via lien politique cookies) | OK (justifiable, info detaillee dans page cookies linkee) |
| localStorage CONSENT_KEY | preserve | preserve | OK |

### Note compliance mobile

La copy mobile compacte mentionne explicitement :
- "cookies necessaires au service" (= cookies essentiels CNIL)
- "avec votre accord" (= opt-in explicite)
- "outils de mesure d audience" (= analytics generique acceptable)
- "pour ameliorer KeyBuzz" (= finalite)

Tous les details specifiques (Microsoft Clarity, heatmaps, parcours visiteur, duree 12 mois) sont accessibles via le lien "politique cookies" preserve mobile. Cette approche respecte le principe CNIL de proportionnalite information : information essentielle visible + details accessibles.

## TRACKING PRESERVATION

| Helper / IDs | Touche ? | Verdict |
|---|---|---|
| marketing-tracking.ts (trackMarketingClick, marketing_cta_click) | NON | OK preserve PH-20.3 |
| Analytics.tsx (GA4 measurement_id, SGTM hostname t.keybuzz.pro) | NON | OK preserve |
| ClarityProvider.tsx (wuk12h9i33 route-gated) | NON | OK preserve |
| MarketingCTA.tsx | NON | OK preserve PH-20.3 |
| GA4 / Meta / TikTok / LinkedIn IDs | NON | 0 changement |
| Fake events delta | 0 | 0 (= aucun ajout) |
| SGTM endpoint hostname | non touche | preserve |
| Consent-aware tracking | depend de CookieConsent.handleAccept/Refuse INCHANGE | preserve |

## CONFIRMATIONS SECURITE

- AUCUN docker build/push.
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply/set/patch/edit.
- AUCUN manifest GitOps modifie.
- AUCUN secret/token affiche.
- AUCUNE mutation DB/Stripe.
- AUCUN faux register / checkout.
- AUCUN ticket Linear modifie statut.
- AUCUN changement IDs analytics.
- AUCUN changement logique consentement tracking.
- AUCUN dark pattern.
- AUCUN changement Client/API/Admin.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- 0 fake event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute.
- 0 changement tracking helpers.
- Consent-aware tracking logique preservee a 100%.
- Note : grep "Lead" dans diff a detecte faux positif `leading-relaxed` (Tailwind utility class line-height) ; aucun event tracking ajoute.

## GAPS

1. QA navigateur Ludovic recommandee post-APPLY DEV mobile + desktop pour valider visuel CMP (hero visible mobile + buttons accessibles + Accepter/Refuser equilibres).
2. Audit Compliance officier optionnel post-deploy pour valider que la copy mobile compacte respecte les exigences CNIL (niveau d info essentielle + acces details via liens politiques preserves).
3. Test responsive sur viewports 360px (iPhone SE), 414px (iPhone 14 Pro), 768px (tablet portrait), 1024px+ (desktop) recommande.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH WEBSITE CMP MOBILE POLISH READY PH-SAAS-T8.12AS.20.8 |
| Bastion | install-v3 46.62.171.61 |
| Commit Website | bb49798 push origin main |
| Fichier patche | src/components/CookieConsent.tsx (+16 -11 = +5 net) |
| Mobile CMP | compact (p-2 outer, max-h 60vh, p-4 card, text-xs/base, gap-2, buttons px-5 py-2, copy courte sm:hidden) |
| Desktop CMP | INCHANGE (sm:p-4 md:p-6 outer, max-h-none sm:overflow-visible, sm:p-6 card, sm:text-lg/sm, sm:gap-3, sm:px-6 sm:py-2.5, copy complete hidden sm:block) |
| Compliance | preservee (Accepter/Refuser equilibres, liens politiques visibles, close X handleRefuse, pas de dark pattern, CONSENT_VERSION/TTL 12 mois preserves) |
| Tracking | preservee (Analytics, Clarity, marketing-tracking, SGTM, GA4/Meta/TikTok/LinkedIn 0 changement) |
| tsc | OK 0 nouvelle erreur |
| Fake events delta | 0 |
| Runtime Website DEV+PROD | INCHANGES |
| Runtime Client+API+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-SOURCE-01.md` |

### Prochaine phrase GO attendue

`GO BUILD WEBSITE CMP MOBILE POLISH DEV PH-SAAS-T8.12AS.20.8`

STOP. Ne pas build. Ne pas deploy.
