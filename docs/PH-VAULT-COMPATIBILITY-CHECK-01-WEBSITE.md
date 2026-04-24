# PH-VAULT-COMPATIBILITY-CHECK-01-WEBSITE — Verification compatibilite Vault rotation

> Date : 10 avril 2026
> Service : keybuzz-website (site vitrine www.keybuzz.pro)
> Type : audit compatibilite Vault HA rotation
> Reference : PH-VAULT-TOKEN-AUTO-ROTATION-01

---

## Verdict

**AUCUN USAGE VAULT — SERVICE 100% COMPATIBLE — AUCUNE CORRECTION NECESSAIRE**

---

## Usage Vault

| Element | Resultat |
|---|---|
| `VAULT_TOKEN` dans env vars K8s | Non |
| `VAULT_ADDR` dans env vars K8s | Non |
| Secret K8s `vault-*` dans namespace | Non |
| envFrom secretRef vers Vault | Non |
| volumeMounts secrets Vault | Non |
| Import/require Vault dans le code | Non |
| Appel HTTP vers Vault API | Non |
| Dependance npm `node-vault` ou similaire | Non |
| Reference Vault dans Dockerfile | Non |
| Reference Vault dans next.config.ts | Non |
| Reference Vault dans .env | Non |

### Detail des secrets K8s presents

**keybuzz-website-dev** :
- `ghcr-secret` (dockerconfigjson) — pull image GHCR
- `preview-basic-auth` (Opaque) — basic auth ingress preview

**keybuzz-website-prod** :
- `ghcr-secret` (dockerconfigjson) — pull image GHCR
- `keybuzz-website-prod-tls` (tls) — certificat TLS ingress

Aucun de ces secrets n'est lie a Vault.

### Detail des env vars

**DEV** : `NEXT_PUBLIC_SITE_MODE`, `NEXT_PUBLIC_CLIENT_APP_URL`, `NODE_ENV` — toutes statiques.
**PROD** : `NEXT_PUBLIC_SITE_MODE`, `NODE_ENV` — toutes statiques.

Aucune variable Vault.

---

## Occurrences du mot "vault" dans le code

Deux occurrences trouvees, toutes deux du **contenu textuel marketing** (pas du code) :

| Fichier | Contexte |
|---|---|
| `src/app/privacy/page.tsx:299` | `"Gestion securisee des secrets (vault dedie, aucun secret dans le code)"` |
| `src/app/page.tsx:160` | `"Gestion des secrets - Vault securise, aucun secret dans le code"` |

Ce sont des textes affiches sur les pages privacy et homepage pour decrire les pratiques de securite de KeyBuzz. Aucun appel API, aucune logique liee a Vault.

---

## Compatibilite rotation

| Question | Reponse |
|---|---|
| Le service utilise-t-il Vault ? | **Non** |
| Le service necessite-t-il un token Vault ? | **Non** |
| Le service lit-il des secrets Vault au runtime ? | **Non** |
| Le service cache-t-il un token en memoire ? | **Non** (pas de token) |
| Le service necessite-t-il un restart apres rotation ? | **Non applicable** |
| Le service est-il reference dans le RBAC du CronJob ? | **Non** (seuls keybuzz-api, keybuzz-backend, workers Amazon sont listes) |

---

## Risques identifies

| Risque | Statut |
|---|---|
| Token hardcode | **Aucun** |
| Token stocke localement | **Aucun** |
| Token non renouvelable | **Non applicable** |
| Dependance a ancien Vault | **Aucune** |
| Secret expose dans le code | **Aucun** |

---

## Seule dependance externe

Le formulaire de contact (`src/app/contact/page.tsx`) fait un appel `fetch` vers :

```
NEXT_PUBLIC_CONTACT_API_URL || "https://api.keybuzz.io/api/public/contact"
```

C'est un endpoint **public** de l'API KeyBuzz (pas de token, pas d'auth). Si l'API est indisponible suite a une rotation Vault mal geree, le formulaire de contact echouera, mais c'est un risque API — pas un risque website.

---

## Corrections necessaires

**Aucune.** Le service website n'a aucune interaction avec Vault.

---

## Conclusion

Le site vitrine `keybuzz-website` est un site Next.js statique purement frontend. Il ne consomme aucun secret Vault, n'a aucun token injecte, et n'a aucune dependance directe ou indirecte au systeme Vault.

La rotation automatique des tokens Vault (PH-VAULT-TOKEN-AUTO-ROTATION-01) n'a **aucun impact** sur ce service. Aucune modification, aucune adaptation, aucun restart necessaire.

**VAULT COMPATIBILITY: N/A — NO VAULT DEPENDENCY — NO ACTION REQUIRED**
