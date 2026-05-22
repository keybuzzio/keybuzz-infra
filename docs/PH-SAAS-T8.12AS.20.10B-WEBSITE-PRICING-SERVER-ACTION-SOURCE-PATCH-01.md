# PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-SOURCE-PATCH-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-346 (primary pricing/conversion) ; KEY-343 (related Laurent context)
> Phase : PH-SAAS-T8.12AS.20.10B source patch Website error boundary defensif
> Environnement : source patch only (aucun build, aucun deploy, aucun docker push)

## VERDICT

GO SOURCE PATCH WEBSITE PRICING SERVER ACTION READY PH-SAAS-T8.12AS.20.10B

- Patch source Website applique : `src/app/error.tsx` + `src/app/global-error.tsx` ameliores avec auto-reload single-shot defensif sur erreur "Failed to find Server Action" (guard sessionStorage anti-boucle `kb_pricing_server_action_reload_v1`).
- Diff scope strict : +44 lignes / 2 fichiers seulement. Pas de modification copy/design/tracking/CMP/pricing/contact.
- tsc 0 erreurs.
- Tracking IDs preserve (GA/SGTM/LinkedIn in src/components/Analytics.tsx + env, non touche par diff).
- Repo clean post-commit, push origin/main OK (commit `907689b`).
- Runtime Website DEV+PROD INCHANGES (image v0.6.20-cmp-mobile-polish-* preserve).
- Aucun build. Aucun deploy. Aucun docker push. Aucun event tracking ajoute. Aucun fake lead/register/checkout.

STOP avant build DEV PH-20.10B.

## CONTEXTE PH-20.10 AUDIT (rappel)

Logs Website PROD montrent pattern continu :
```
Error: Failed to find Server Action "x". This request might be from an older or newer deployment.
```
- ~2 erreurs/heure par pod depuis deploy PH-20.8 (2026-05-22T09:30 UTC).
- ~4 erreurs/heure cumule 2 pods = ~96 utilisateurs/jour potentiellement affectes.
- Audit source confirme : ZERO "use server" et ZERO async function exportee dans le repo Website. ZERO `action=` form attribute.
- Pricing/Contact/CookieConsent = client components purs.

Hypothese : utilisateurs avec un bundle JS client ancien (onglet ouvert avant deploy ou cache navigateur) tentent une Server Action dont l ID a change apres deploy. Note : l action ID "x" tres court suggere aussi du trafic bot/scanner probing l API Next.js. Dans les 2 cas, l effet utilisateur reel est l affichage de l error boundary Next.js.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T14:50:45Z |
| keybuzz-website HEAD avant | bb49798 |
| keybuzz-website HEAD apres | **907689b** |
| Dirty avant | 0 |
| Dirty apres | 0 (clean post-commit + push) |
| keybuzz-infra HEAD | 9408cbd |

### Runtime non-touche

| Service | Env | Runtime | Verdict |
|---|---|---|---|
| keybuzz-website | DEV | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-website | PROD | v0.6.20-cmp-mobile-polish-prod | INCHANGE |
| keybuzz-client | DEV+PROD | v3.5.210 / v3.5.201 | INCHANGES |
| keybuzz-api | DEV+PROD | v3.5.253 / v3.5.252-meta-capi-emq-prod | INCHANGES |

## E1 LOCALISATION SERVER ACTIONS / FORMS

| Pattern | Count repo Website | Verdict |
|---|---|---|
| `"use server"` directive | 0 | aucun Server Action explicite |
| `action=` form attribute (tsx) | 0 | aucun form server action |
| `formAction` | 0 | aucun |
| async function exportee dans `app/` | 0 | aucune fonction Server Action implicite |
| Forms HTML | 1 (`contact/page.tsx` ligne 181 : `<form onSubmit={handleSubmit}>` client-side fetch) | OK pas de Server Action |

### Components key

| File | Type | Server Action ? | Verdict |
|---|---|---|---|
| `src/app/pricing/page.tsx` | client (`"use client"`) | NON | pas de Server Action |
| `src/app/contact/page.tsx` | client (`"use client"` fetch via CONTACT_API_URL) | NON | OK |
| `src/components/CookieConsent.tsx` | client (`"use client"`) | NON | OK PH-20.8 |
| `src/app/error.tsx` | error boundary client | NON | maintenant ameliore PH-20.10B |
| `src/app/global-error.tsx` | global error boundary client | NON | maintenant ameliore PH-20.10B |

**Conclusion** : le repo Website n a aucune Server Action exposee. Les errors logs proviennent soit de probes externes (bots), soit d utilisateurs avec bundle stale qui essaient d invoquer une Server Action obsolete.

## E2 PATCH SOURCE DURABLE

### Decision design

Approche choisie : **error boundary defensif avec auto-reload single-shot**.

Justification :
- Ne masque pas l erreur (transparence preserve).
- Ne supprime pas les logs serveur (debug preserve).
- Coupe court a l UX dysfonctionnelle quand l erreur survient : auto-recover automatique en rechargeant le bundle frais.
- Guard anti-boucle via `sessionStorage` clef `kb_pricing_server_action_reload_v1` : si l erreur persiste apres reload, l utilisateur voit la page d erreur classique avec les boutons "Reessayer" + "Recharger la page" (UX existante non touchee).
- Aucun tracking event ajoute (regle no fake events).
- Aucune dependance ajoutee.
- Diff minimaliste : 24+20=44 lignes inserees, 0 ligne supprimee.

### Fichiers modifies

| Fichier | +Lines | -Lines | Risque | Verdict |
|---|---|---|---|---|
| `src/app/error.tsx` | +24 | 0 | nul (effet local au boundary, guard sessionStorage) | OK |
| `src/app/global-error.tsx` | +20 | 0 | nul (idem pour RootLayout) | OK |

### Diff resume

```
import { useEffect } from "react";
const SERVER_ACTION_RELOAD_KEY = "kb_pricing_server_action_reload_v1";
...
useEffect(() => {
  if (typeof window === "undefined") return;
  const msg = String(error?.message || "");
  if (msg.indexOf("Failed to find Server Action") !== -1) {
    const flag = window.sessionStorage.getItem(SERVER_ACTION_RELOAD_KEY);
    if (!flag) {
      window.sessionStorage.setItem(SERVER_ACTION_RELOAD_KEY, String(Date.now()));
      window.location.reload();
    }
  }
}, [error]);
```

## E3 TESTS SOURCE

| Test | Resultat | Verdict |
|---|---|---|
| `npx tsc --noEmit` (timeout 120s) | 0 erreurs (sortie vide = OK) | OK |
| git diff scope | 2 fichiers seulement : error.tsx + global-error.tsx | OK strict |
| git diff fake events | 0 lignes ajoutees avec gtag/fbq/lintrk/track (verifie grep) | OK |
| Tracking IDs (GA G-R3QQDYEBFG / SGTM t.keybuzz.pro / LinkedIn 9969977) | non touches (Analytics.tsx pas modifie, env preservee) | preserve |
| `src/components/CookieConsent.tsx` | non touche | preserve PH-20.8 |
| `src/app/pricing/page.tsx` | non touche | preserve PH-20.6A + tracking marketing |
| `src/app/contact/page.tsx` | non touche | preserve PH-17.0.1 |
| `src/lib/marketing-tracking.ts` | non touche | preserve |

## E4 BUILD-LIGHT LOCAL

Skip : pas de build local execute. Le patch sera teste via la phase BUILD DEV suivante.

## E5 COMMIT SOURCE

| Item | Valeur |
|---|---|
| Branche | main |
| Commit | `907689b` |
| Message | `fix(website): harden pricing against stale server action errors` |
| Push | OK bb49798..907689b origin/main |
| Repo dirty post-commit | 0 |

## TRACKING / CMP PRESERVATION

| Indicateur | Verdict |
|---|---|
| GA G-R3QQDYEBFG | preserve (Analytics.tsx non touche) |
| SGTM t.keybuzz.pro | preserve |
| LinkedIn 9969977 | preserve |
| marketing_cta_click / trackMarketingClick | preserve (marketing-tracking.ts non touche) |
| CookieConsent PH-20.8 (CONSENT_KEY v2 Microsoft Clarity opt-in strict) | preserve |
| Hero/CTA pricing PH-20.6A | preserve |
| Contact form PH-17.0.1 (CONTACT_API_URL env-driven sans fallback) | preserve |

## NO FAKE METRICS / NO FAKE EVENTS

| Controle | Resultat | Verdict |
|---|---|---|
| Fake event ajoute dans diff | 0 | OK |
| Tracking gtag/fbq/lintrk ajoute | 0 | OK |
| Pixel ID hardcode ajoute | 0 | OK |
| Stripe call ajoute | 0 | OK |
| API call ajoute (vers Meta Graph / GA Measurement Protocol) | 0 | OK |
| DB mutation | 0 (patch source uniquement) | OK |

## CONFIRMATIONS SECURITE

- AUCUN docker build. AUCUN docker push.
- AUCUN deploy DEV/PROD.
- AUCUN kubectl apply/set/patch/edit.
- AUCUN restart pod.
- AUCUN changement API/Client/Admin.
- AUCUN changement tracking IDs / CMP / copy / design.
- AUCUN faux event / register / checkout / lead.
- AUCUN secret/token affiche.
- AUCUN PII brut.
- AUCUN Linear ticket statut modifie.
- AUCUNE migration DB.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK SOURCE

Si necessaire :
```
cd /opt/keybuzz/keybuzz-website
git revert 907689b
git push origin main
```
Ou patch alternative (retirer juste le useEffect dans les 2 fichiers).

L image runtime PROD actuelle v0.6.20-cmp-mobile-polish-prod ne contient PAS encore le patch (deploy non fait). Si rollback avant build : aucun impact runtime.

## GAPS

1. Le patch resout l effet utilisateur (auto-recover via reload single-shot) MAIS ne touche pas a la source des erreurs (bots probing + utilisateurs avec bundle stale post-deploy). C est intentionnel : on ne peut pas eliminer la cause (Next.js Server Action ID hash change a chaque deploy), seulement adoucir l UX.
2. Le pattern logs `Failed to find Server Action "x"` continuera d apparaitre (les bots/utilisateurs avec bundle stale envoient toujours leurs requetes). Le patch fait disparaitre l UX dysfonctionnelle, pas le log noise.
3. Si Ludovic veut aussi couper le log noise serveur : phase optionnelle PH-20.10C ajouter un middleware Next.js qui retourne 404 sur header `Next-Action` quand `req.method==="POST"` (le site n a aucune Server Action legitime, donc safe). Pas prioritaire.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO SOURCE PATCH WEBSITE PRICING SERVER ACTION READY PH-SAAS-T8.12AS.20.10B |
| Bastion | install-v3 46.62.171.61 |
| Patch | error.tsx + global-error.tsx auto-reload single-shot defensif |
| Commit Website | `907689b` push origin/main |
| Fichiers modifies | 2 (+44 / -0 lignes) |
| tsc | 0 erreurs |
| Tracking + CMP | preserves |
| Runtime DEV/PROD | INCHANGES |
| Build/Deploy | NONE |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.10B-WEBSITE-PRICING-SERVER-ACTION-SOURCE-PATCH-01.md` |

### Prochaine phrase GO attendue

`GO BUILD WEBSITE PRICING SERVER ACTION DEV PH-SAAS-T8.12AS.20.10B`

Sequencing futur :
1. BUILD Website DEV depuis commit `907689b` avec tag KEY-309 (`v0.6.21-server-action-recover-dev`).
2. PUSH IMAGE GHCR DEV.
3. APPLY DEV GitOps strict.
4. QA DEV : verifier que /pricing rend OK, que les errors logs persistent (normal) mais que l UX est silencieuse pour utilisateurs reels (auto-reload).
5. Eventuel cycle PROD si OK DEV.

STOP. Aucun build, aucun deploy, aucun event Meta, aucun changement Linear statut.
