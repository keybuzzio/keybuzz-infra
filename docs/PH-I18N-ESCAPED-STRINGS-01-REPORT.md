# PH-I18N-ESCAPED-STRINGS-01 — Fix caracteres echappes

> Date : 22 mars 2026
> Auteur : Cursor Executor
> Verdict : **ESCAPED STRINGS FIXED**

---

## Probleme

Plusieurs pages du client affichaient les accents francais sous forme de sequences echappees visibles :

```
Votre compte a \u00e9t\u00e9 activ\u00e9
Acc\u00e9der \u00e0 mon espace
Aucun impact sur vos donn\u00e9es
```

Au lieu de :

```
Votre compte a ete active
Acceder a mon espace
Aucun impact sur vos donnees
```

## Cause racine exacte

Les fichiers source contenaient des sequences Unicode echappees (`\u00e9`, `\u00e0`, etc.) au lieu de caracteres UTF-8 directs. Ces sequences fonctionnent dans les string literals JavaScript (`'...\u00e9...'`) mais s'affichent litteralement dans le JSX text content (texte entre balises HTML sans `{}`).

**Exemple problematique** (JSX text - affiche `\u00e9` litteralement) :
```jsx
<p>La validation prend un peu plus de temps que pr\u00e9vu.</p>
```

**Equivalent correct** :
```jsx
<p>La validation prend un peu plus de temps que prevu.</p>
```

**Pourquoi `/locked` etait corrige mais pas les autres** : la page `/locked` avait ete corrigee dans PH-BILLING-HARD-UI-GATE-01, mais les 7 autres fichiers n'avaient pas ete audites.

## Pages touchees

| Page | Fichier | Replacements |
|---|---|---|
| Succes apres paiement | `app/register/success/page.tsx` | 16 |
| Gestion plan billing | `app/billing/plan/page.tsx` | 18 |
| Canaux marketplace | `app/channels/page.tsx` | 7 |
| Nouveau playbook | `app/playbooks/new/page.tsx` | 1 |
| Liste playbooks | `app/playbooks/page.tsx` | 2 |
| Suggestion playbook | `src/features/inbox/components/PlaybookSuggestionBanner.tsx` | 4 |
| Layout principal | `src/components/layout/ClientLayout.tsx` | 1 |
| Email OTP | `src/lib/otp-email.ts` | 3 |
| **Total** | **8 fichiers** | **52 replacements** |

## Fichier exclu (intentionnel)

`src/features/ai-ui/AISuggestionSlideOver.tsx` contient des sequences Unicode dans des patterns de regex/nettoyage de texte IA. Ces escapes sont intentionnels et n'affichent pas de texte visible a l'utilisateur.

## Exemples avant/apres

### `app/register/success/page.tsx`

**Avant** :
```
Votre compte a \u00e9t\u00e9 activ\u00e9 et votre essai gratuit de 14 jours commence maintenant.
Acc\u00e9der \u00e0 mon espace
```

**Apres** :
```
Votre compte a ete active et votre essai gratuit de 14 jours commence maintenant.
Acceder a mon espace
```

### `app/billing/plan/page.tsx`

**Avant** :
```
Aucun impact sur vos donn\u00e9es
Changement imm\u00e9diat (p\u00e9riode d\u2019essai)
```

**Apres** :
```
Aucun impact sur vos donnees
Changement immediat (periode d'essai)
```

## Correction appliquee

Remplacement systematique de 21 sequences Unicode echappees par leurs caracteres UTF-8 natifs dans les 8 fichiers source. Aucune modification de logique metier.

## Scan global post-correction

Un scan complet de `app/` et `src/` confirme : **zero occurrence `u00e` restante** (hors AI regex intentionnels).

## Versions deployees

| Env | Image | Git SHA |
|---|---|---|
| DEV | `v3.5.68-i18n-escaped-strings-dev` | `61a3116` |
| PROD | `v3.5.68-i18n-escaped-strings-prod` | `61a3116` |

## Tests DEV (7/7 PASS)

| Test | Resultat |
|---|---|
| Image DEV correcte | PASS |
| Pod Running | PASS |
| `/locked` HTTP 200 | PASS |
| register/success : 0 `u00e` escapes dans chunk | PASS |
| register/success : "Bienvenue" UTF-8 present | PASS |
| billing/plan : 0 `u00e` escapes dans chunk | PASS |
| Pages critiques accessibles (locked, register, login, billing/plan) | PASS |

## Tests PROD (9/9 PASS)

| Test | Resultat |
|---|---|
| Image PROD correcte | PASS |
| `/locked` HTTP 200 | PASS |
| `/register` HTTP 200 | PASS |
| `/login` HTTP 200 | PASS |
| `/billing/plan` HTTP 200 | PASS |
| register/success : 0 `u00e` escapes | PASS |
| register/success : "Bienvenue" UTF-8 | PASS |
| locked : "Finalisez" UTF-8 | PASS |
| billing/plan : 0 `u00e` escapes | PASS |

## Rollback

```bash
# DEV
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.67-billing-server-gate-dev -n keybuzz-client-dev

# PROD
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.67-billing-server-gate-prod -n keybuzz-client-prod
```

## GitOps commits

| Repo | Commit | Description |
|---|---|---|
| `keybuzz-client` | `61a3116` | fix: replace escaped Unicode sequences with UTF-8 in 8 files |
| `keybuzz-infra` | `2c6a0fe` | gitops: client DEV v3.5.68-i18n-escaped-strings-dev |
| `keybuzz-infra` | `ec1e363` | gitops: client PROD v3.5.68-i18n-escaped-strings-prod |

## Verdict final

**ESCAPED STRINGS FIXED** — 52 sequences Unicode echappees remplacees par du vrai UTF-8 dans 8 fichiers. Aucun caractere echappe visible restant dans le client.
