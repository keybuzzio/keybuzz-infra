# PH-T7.2.2.4 — TikTok Query Param Capture Fix (DEV)

> **Date** : 19 avril 2026
> **Auteur** : Agent Cursor
> **Environnement** : DEV uniquement
> **Type** : Correction capture attribution query params
> **Prerequis** : PH-T7.2.2.3 (validation E2E identifiant le bug)

---

## 1. OBJECTIF

Corriger la capture des query params (`ttclid`, UTM, `gclid`, `fbclid`, etc.) pour qu'ils soient persistes immediatement et ne soient plus perdus avant les redirections / transitions internes sur `/register`.

---

## 2. PREFLIGHT


| Element                 | Valeur                                          | Statut   |
| ----------------------- | ----------------------------------------------- | -------- |
| Client branche          | `ph148/onboarding-activation-replay`            | OK       |
| Client HEAD (avant fix) | `f2a8523` PH-T7.2.2.2 TikTok replay             | OK       |
| Client status           | 1 untracked (`scripts/ph-t722-patch-client.js`) | OK       |
| API branche             | `ph147.4/source-of-truth`                       | OK       |
| API HEAD                | `12e1f407` PH-T7.2.2.2 TikTok ttclid            | OK       |
| API status              | Clean                                           | OK       |
| Build prevu             | **Client seul** — aucun build API               | Confirme |


---

## 3. AUDIT ROOT CAUSE

### Constatation (PH-T7.2.2.3)

- URL navigee : `https://client-dev.keybuzz.io/register?ttclid=test_ttclid_e2e_001`
- `ttclid` en DB : **null**
- `landing_url` en DB : `https://client-dev.keybuzz.io/register` (sans query params)
- `fbp` (cookie Meta) : capture correctement

### Analyse du code

**Point 1 — Source des params dans le `useEffect`**

`app/register/page.tsx` :

```javascript
useEffect(() => {
    const params = new URLSearchParams(window.location.search); // <-- BUG ICI
    const ctx = initAttribution(params, effectivePlan, effectiveCycle);
    setAttribution(ctx);
}, []);
```

Le `useEffect([])` s'execute APRES le premier rendu du composant. A ce moment, `window.location.search` peut etre **vide** car Next.js App Router avec Suspense/hydration peut avoir modifie l'URL avant que l'effet ne fire.

En revanche, `useSearchParams()` (hook Next.js) capture les params au moment du rendu du composant (apres resolution Suspense) et les conserve correctement.

**Point 2 — `landing_url` sans params**

`src/lib/attribution.ts` :

```javascript
landing_url: window.location.href,
```

Utilise `window.location.href` qui, si l'URL a ete strippee, ne contient plus les query params.

### Tableau d'audit


| Point                   | Fichier               | Etat avant fix                                                    | Impact                           |
| ----------------------- | --------------------- | ----------------------------------------------------------------- | -------------------------------- |
| Params source useEffect | `register/page.tsx`   | `window.location.search` (vide apres hydration)                   | ttclid/UTMs perdus               |
| searchParams hook       | `register/page.tsx`   | Correct via `useSearchParams()` mais non utilise pour attribution | Params disponibles non exploites |
| landing_url             | `attribution.ts`      | `window.location.href` (sans params)                              | landing_url incomplet            |
| Middleware `/register`  | `routeAccessGuard.ts` | PUBLIC_ROUTES — aucune redirect                                   | OK, pas de redirect              |
| First-touch strategy    | `attribution.ts`      | `loadAttribution()` verifie en premier                            | OK, pas de conflit               |


---

## 4. CORRECTION

### Fichiers modifies


| Fichier                  | Modifie                 | Scope attribution pur ? | OK  |
| ------------------------ | ----------------------- | ----------------------- | --- |
| `app/register/page.tsx`  | 1 ligne (params source) | Oui                     | OK  |
| `src/lib/attribution.ts` | 1 bloc (landing_url)    | Oui                     | OK  |


### Patch 1 : `app/register/page.tsx`

**Avant :**

```javascript
const params = new URLSearchParams(window.location.search);
```

**Apres :**

```javascript
const params = new URLSearchParams(searchParams.toString());
```

Utilise les `searchParams` du hook `useSearchParams()` de Next.js, qui sont garantis d'avoir les params URL correctes au moment du rendu du composant.

### Patch 2 : `src/lib/attribution.ts`

**Avant :**

```javascript
landing_url: window.location.href,
```

**Apres :**

```javascript
landing_url: (() => {
    const qs = searchParams.toString();
    if (qs && !window.location.search) {
        return window.location.origin + window.location.pathname + '?' + qs;
    }
    return window.location.href;
})(),
```

Reconstruit le `landing_url` avec les searchParams quand `window.location.search` est vide — assure que le landing_url complet est toujours stocke.

### Commit

- Hash : `7b82c8a`
- Message : `PH-T7.2.2.4: fix attribution query param capture — use searchParams hook instead of window.location.search`
- Branche : `ph148/onboarding-activation-replay`

---

## 5. BUILD CLIENT


| Element      | Valeur                                                                                                                       |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| Commit       | `7b82c8a`                                                                                                                    |
| Tag          | `ghcr.io/keybuzzio/keybuzz-client:v3.5.81-tiktok-attribution-fix-dev`                                                        |
| Digest       | `sha256:7a2a2dd7d818910de421f2387335fb70d9af9c5958f22571c7f991c68d0d8c95`                                                    |
| Build args   | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `GA4=G-R3QQDYEBFG`, `META=1234164602194748`, `TIKTOK=CTGBP3JC77UBTJHGMMGG` |
| Build option | `--no-cache`                                                                                                                 |


---

## 6. DEPLOY


| Element       | Valeur                                    | Statut |
| ------------- | ----------------------------------------- | ------ |
| Namespace     | `keybuzz-client-dev`                      | OK     |
| Image deploye | `v3.5.81-tiktok-attribution-fix-dev`      | OK     |
| Pod           | `keybuzz-client-5cdcb4bd89-8svq8` Running | OK     |
| Rollout       | Successfully rolled out                   | OK     |


---

## 7. VALIDATION

### 7.1 Browser — Attribution Capture

URL testee :

```
https://client-dev.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=tiktok&utm_medium=cpc&utm_campaign=test_tiktok_fix&ttclid=test_ttclid_fix_001
```


| Verification                              | Resultat                             | Statut                  |
| ----------------------------------------- | ------------------------------------ | ----------------------- |
| Page charge avec params                   | URL complete preservee               | OK                      |
| `[TRACKING] attribution context captured` | Log console emis                     | **OK — FIX FONCTIONNE** |
| Bundle JS                                 | `7085-eaf96e83ceac5ea9.js` (nouveau) | OK (build v3.5.81)      |
| TikTok Pixel                              | Script charge                        | OK                      |
| GA4                                       | Script charge (`G-R3QQDYEBFG`)       | OK                      |
| Meta Pixel                                | Script charge (`1234164602194748`)   | OK                      |


**Le log `[TRACKING] attribution context captured` confirme que `captureAttribution` retourne un contexte AVEC signals (sinon le log dirait "minimal"). Le fix est operationnel.**

### 7.2 Persistance DB — VALIDE

Test E2E complet realise le 19 avril 2026 :

- Email test : `ludo.gonthier+ph-t7224@gmail.com`
- Tenant cree : `tiktok-fix-test-sas-mo5hkwww` / "TikTok Fix Test SAS"
- Plan : PRO (trial 14j via Stripe test card 4242)

**Comparaison AVANT/APRES fix :**


| Champ                | AVANT (PH-T7.2.2.3 — `mo4y4fde`)         | APRES fix (PH-T7.2.2.4 — `mo5hkwww`)                                                                                                                     |
| -------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ttclid`             | **null**                                 | `**test_ttclid_fix_001`**                                                                                                                                |
| `utm_source`         | **null**                                 | `**tiktok`**                                                                                                                                             |
| `utm_medium`         | **null**                                 | `**cpc`**                                                                                                                                                |
| `utm_campaign`       | **null**                                 | `**test_tiktok_fix`**                                                                                                                                    |
| `landing_url`        | `https://client-dev.keybuzz.io/register` | `https://client-dev.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=tiktok&utm_medium=cpc&utm_campaign=test_tiktok_fix&ttclid=test_ttclid_fix_001` |
| `conversion_sent_at` | `2026-04-18T23:07:56.969Z`               | `2026-04-19T08:11:55.610Z`                                                                                                                               |
| `fbp`                | present                                  | present                                                                                                                                                  |


**Tous les signaux d'attribution sont correctement persistes en DB.**
Le `conversion_sent_at` non-null confirme que le pipeline server-side (TikTok Events API via sGTM) a egalement fonctionne.

### 7.3 Non-regression


| Page                      | Statut                                     |
| ------------------------- | ------------------------------------------ |
| `/register` (avec params) | OK — attribution capturee                  |
| `/dashboard`              | OK — KPIs, supervision                     |
| `/inbox`                  | OK — TripaneLayout, filtres, conversations |
| `/start`                  | OK (accessible via sidebar)                |
| `/settings`               | OK (accessible via sidebar)                |
| Auth (AuthGuard)          | OK — sessions actives                      |
| GA4                       | OK — pas de regression                     |
| Meta                      | OK — pas de regression                     |
| TikTok Pixel              | OK — script charge                         |


---

## 8. ROLLBACK

### Client DEV (si necessaire)

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.79-tracking-t5.3-replay-dev -n keybuzz-client-dev
```

### API DEV (non modifiee, pas de rollback necessaire)

Image actuelle inchangee : `ghcr.io/keybuzzio/keybuzz-api:v3.5.79-tiktok-api-replay-dev`

---

## 9. VERDICT

### TIKTOK ATTRIBUTION CAPTURE FIXED — VALIDATED — READY FOR PROD

Le fix corrige la root cause identifiee dans PH-T7.2.2.3 :

- `captureAttribution` utilise desormais les `searchParams` du hook `useSearchParams()` au lieu de `window.location.search`
- Le `landing_url` est reconstruit avec les searchParams quand l'URL du navigateur a ete strippee
- Le log console confirme la capture avec signals sur la page `/register?...ttclid=...`
- **DB validation E2E : `ttclid`, `utm_source`, `utm_medium`, `utm_campaign`, `landing_url` tous non-null et corrects**
- **Pipeline server-side TikTok confirme via `conversion_sent_at` non-null**
- Non-regression validee sur 5+ pages
- Scope minimal : 2 fichiers, attribution pur, 0 impact sur GA4/Meta/Stripe/sGTM

### Aucune autre action effectuee

- API non modifiee, non rebuildee
- sGTM non modifie
- Stripe non modifie
- Google Ads / Meta / GA4 non modifies
- PROD non touchee

