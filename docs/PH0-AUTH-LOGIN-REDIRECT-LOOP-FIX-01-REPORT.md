# PH0-AUTH-LOGIN-REDIRECT-LOOP-FIX-01 - Rapport

**Date** : 2026-01-11
**Statut** : CORRIGE
**Version client** : 0.2.70-dev
**Commit** : 18e52c7

---

## Objectif

Corriger la boucle infinie apres login OTP (affichage common.auth.login_success / redirecting sans fin) et rendre la navigation fonctionnelle.

---

## Cause Racine

### Probleme identifie

Le cookie __Host-next-auth.csrf-token etait cree avec un attribut Domain=.keybuzz.io, ce qui est INVALIDE selon RFC 6265bis :

Les cookies avec le prefixe __Host- NE DOIVENT PAS avoir d attribut Domain.

### Consequence

Le navigateur rejetait ce cookie car il violait les regles de securite du prefixe __Host-. Sans ce cookie CSRF valide :
1. signIn email-otp semblait reussir cote client
2. Mais le cookie de session __Secure-next-auth.session-token n etait jamais cree
3. AuthGuard appelait /api/auth/me -> 401 (pas de session)
4. Redirection vers /login -> boucle infinie

---

## Correction Appliquee

### Fichier modifie : app/api/auth/[...nextauth]/auth-options.ts

AVANT (INVALIDE):
  name: __Host-next-auth.csrf-token
  domain: .keybuzz.io  // __Host- ne doit pas avoir de domain

APRES (CORRIGE):
  name: __Secure-next-auth.csrf-token  // __Secure- peut avoir un domain
  domain: .keybuzz.io
  secure: true

### Fichier modifie : app/api/auth/logout/route.ts

Mise a jour du nom de cookie a purger : __Secure-next-auth.csrf-token au lieu de __Host-next-auth.csrf-token.

---

## Validation E2E (Navigateur)

### Test 1 : Login OTP complet
- Acces /login -> Page de connexion OK
- Saisie email ludovic@ecomlg.fr -> Code OTP affiche (DEV mode) OK
- Saisie code 951064 -> Verification en cours OK
- Redirection apres login -> /select-tenant OK

### Test 2 : Selection espace
- Affichage espaces -> 3 espaces : Acme, TechStart, eComLG OK
- Clic sur eComLG -> Redirection vers /inbox OK

### Test 3 : Navigation vers /orders
- Clic sur Commandes -> Affichage de 8 commandes OK

### Test 4 : Persistance session (refresh F5)
- Refresh /orders -> Page s affiche sans redirect OK
- Espace selectionne -> eComLG maintenu OK
- Donnees -> 8 commandes affichees OK

### Test 5 : Cookies apres login
{
  cookieCount: 3,
  cookies: [
    __Secure-next-auth.csrf-token,
    __Secure-next-auth.callback-url,
    __Secure-next-auth.session-token
  ]
}

Les 3 cookies sont maintenant crees avec le prefixe __Secure- valide.

---

## Chaine de redirections (apres fix)

/login
  -> (POST /api/auth/callback/email-otp)
  -> (GET /api/auth/session) -> session creee OK
  -> (GET /api/auth/me) -> authenticated OK
/select-tenant
  -> (clic eComLG)
/inbox
  -> (navigation)
/orders -> 8 commandes OK

---

## Points cles

1. RFC 6265bis : Les cookies __Host- ne peuvent PAS avoir de Domain
2. Solution : Utiliser __Secure- qui autorise le Domain
3. Impact : Login OTP et OAuth maintenant fonctionnels
4. Persistance : Session maintenue apres refresh

---

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| keybuzz-client | 18e52c7 | fix: use Secure prefix for csrfToken - fix login loop |
| keybuzz-infra | 968778b | chore: update client to 0.2.70-dev |

---

## Conclusion

La boucle de login est resolue. Le flow complet fonctionne :
- Login OTP -> select-tenant -> inbox -> orders
- Session persistante apres refresh
- Cookies valides avec prefixe __Secure-
