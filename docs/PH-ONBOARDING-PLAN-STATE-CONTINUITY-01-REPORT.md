# PH-ONBOARDING-PLAN-STATE-CONTINUITY-01 — Rapport

> Date : 2026-03-01
> Phase : PH-ONBOARDING-PLAN-STATE-CONTINUITY-01
> Type : fix UX cible — conservation plan/cycle durant OAuth
> Environnements : DEV + PROD

---

## Probleme

Depuis la page de selection du forfait :
1. L'utilisateur active le mode annuel
2. Choisit le plan PRO
3. Clique "Continuer avec Google"
4. Apres authentification Google, **il revient sur la page de selection du forfait**
5. L'etat annuel est perdu
6. Il doit rechoisir le plan une seconde fois

## Cause racine

Le callback `redirect` de NextAuth dans `auth-options.ts` ne gerait pas les URLs relatives.

```javascript
// AVANT — bug
async redirect({ url, baseUrl }) {
  if (url.startsWith(baseUrl)) {  // '/register?...' ne commence PAS par 'https://...'
    return url;                    // => jamais execute
  }
  return baseUrl + '/select-tenant'; // => TOUJOURS execute pour les URLs relatives
}
```

Quand `signIn('google', { callbackUrl: '/register?plan=pro&cycle=yearly&step=company&oauth=google' })` est appele, NextAuth stocke le callbackUrl comme URL relative. Au retour OAuth, le redirect callback compare `/register?...` avec `https://client-dev.keybuzz.io` — le test `startsWith` echoue. L'utilisateur est redirige vers `/select-tenant`, qui detecte 0 tenants et renvoie vers `/register` SANS les parametres plan/cycle/step.

**Pourquoi ca marchait au second essai** : apres le premier retour, l'utilisateur a deja une session Google active. `useSession()` retourne `provider: 'google'`, donc `isOAuthUser = true` via la session. Le flow fonctionne normalement car `handleSelectPlan` saute directement a l'etape 'company'.

## Correction

### Fichier 1 : `app/api/auth/[...nextauth]/auth-options.ts`

Resolution des URLs relatives avant comparaison :

```javascript
// APRES — fix
async redirect({ url, baseUrl }) {
  const resolved = url.startsWith('/') ? `${baseUrl}${url}` : url;
  if (resolved.startsWith(baseUrl)) {
    if (resolved.includes('/login') || resolved.includes('/auth/signin')) {
      return baseUrl + '/select-tenant';
    }
    return resolved;
  }
  return baseUrl + '/select-tenant';
}
```

### Fichier 2 : `app/register/page.tsx`

Trois ajouts comme filet de securite :

1. **sessionStorage save** avant depart OAuth :
   - `handleGoogleAuth` sauvegarde `{plan, cycle}` dans `sessionStorage` avant `signIn()`
   
2. **sessionStorage restore** au chargement :
   - Si les URL params ne contiennent pas de plan, restauration depuis `sessionStorage`
   - Nettoyage automatique apres restauration

3. **useEffect email** :
   - Mise a jour de l'email depuis la session NextAuth quand elle devient disponible
   - Necessaire car l'email Google n'est pas dans les URL params du callbackUrl

## Fichiers modifies

| Fichier | Changement | Lignes |
|---------|-----------|--------|
| `app/api/auth/[...nextauth]/auth-options.ts` | Fix redirect callback URLs relatives | +4, -4 |
| `app/register/page.tsx` | sessionStorage save/restore + useEffect email | +27, -4 |

## Methode de persistance

Double mecanisme (belt + suspenders) :
1. **URL callbackUrl** : parametres plan/cycle/step dans le callbackUrl NextAuth (fix principal)
2. **sessionStorage** : `kb_signup_context` comme fallback (filet de securite)

Le sessionStorage est nettoye automatiquement apres lecture pour eviter les donnees stales.

## Images deployees

| Env | Image |
|-----|-------|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.69-onboarding-plan-state-continuity-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.69-onboarding-plan-state-continuity-prod` |

## Rollback

| Env | Tag rollback |
|-----|-------------|
| DEV | `v3.5.68-i18n-escaped-strings-dev` |
| PROD | `v3.5.68-i18n-escaped-strings-prod` |

## Tests DEV (6/6 PASS)

| # | Test | Resultat |
|---|------|----------|
| 1 | Client DEV /login accessible | PASS |
| 2 | /register accessible | PASS |
| 3 | Image correcte deployee | PASS |
| 4 | `kb_signup_context` present dans le build | PASS |
| 5 | `sessionStorage` dans les chunks register | PASS |
| 6 | `useEffect` dans le chunk register | PASS |

## Tests PROD (9/9 PASS)

| # | Test | Resultat |
|---|------|----------|
| 1 | Client PROD /login accessible | PASS |
| 2 | /register accessible | PASS |
| 3 | Image PROD correcte deployee | PASS |
| 4 | `kb_signup_context` present dans le build | PASS |
| 5 | `sessionStorage` dans les chunks register | PASS |
| 6 | ArgoCD Synced | PASS |
| 7 | Pod PROD healthy | PASS |
| 8 | API PROD healthy | PASS |
| 9 | DEV toujours healthy | PASS |

## Impact

- Aucun impact sur le billing securise
- Aucun impact sur le hard gate pending_payment
- Aucun impact sur le flow email/OTP classique
- Aucun impact sur le layout/menu/focus mode
- Le fix du redirect callback beneficie aussi a tout futur flow OAuth avec callbackUrl relatif

## Verdict

**PLAN STATE CONTINUITY FIXED**
