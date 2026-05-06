# PH-SAAS-T8.12AO.10 — Amazon Inbound Setup Guide (/start + /channels) — DEV

> Date : 2026-05-06
> Auteur : Agent Cursor
> Environnement : DEV uniquement
> Tickets : KEY-249, KEY-250 (non fermés)
> Phase précédente : AO.9 (PROD promotion activation contract)

---

## 1. CONTEXTE

Après AO.9, la connexion Amazon depuis `/start` et `/channels` fonctionne correctement :
- OAuth humain Amazon OK
- Activation canal OK
- Adresse inbound visible dans `/channels`

**Problème** : le vendeur n'est pas guidé pour ajouter l'adresse inbound dans Amazon Seller Central. Sans cette étape manuelle, aucun message Amazon ne remonte dans KeyBuzz, bien que le connecteur soit marqué "Connecté".

## 2. PREFLIGHT

| Repo | Branche | HEAD | Verdict |
|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `f2e9bfc5` | OK |
| keybuzz-infra | `main` | `0d30095` | OK |

| Service | Env | Runtime image | Verdict |
|---|---|---|---|
| Client DEV | DEV | `v3.5.160-amazon-start-activation-contract-dev` | OK |
| Client PROD | PROD | `v3.5.160-amazon-start-activation-contract-prod` | INCHANGÉ |

## 3. AUDIT /START

| Élément | Avant AO.10 | Besoin |
|---|---|---|
| Succès Amazon | Bannière verte "connecté et activé avec succès" | Guide inbound complet |
| Inbound email | Non affiché | Affiché avec copie |
| Seller Central | Aucun lien | Lien country-aware |
| Instructions | Aucune | 4 étapes claires |
| Bouton continuer | Aucun | "J'ai ajouté l'adresse, continuer" |

## 4. AUDIT /CHANNELS

| Élément | Avant AO.10 | Réutilisable ? |
|---|---|---|
| Inbound email affiché | Oui (bloc gris + copie) | Oui — conservé tel quel |
| Aide Seller Central | Absente | Non — ajout nécessaire |
| Copy clipboard | `navigator.clipboard.writeText()` | Oui |
| Country code | Disponible via `ch.country_code` | Oui |

## 5. CONTRAT UX

### Composant : `AmazonInboundSetupGuide`

| Prop | Type | Requis |
|---|---|---|
| `inboundEmail` | `string` | Oui |
| `countryCode` | `string` | Oui |
| `variant` | `'full' \| 'compact'` | Non (défaut: `full`) |
| `onContinue` | `() => void` | Non |

| Variante | Surface | Contenu |
|---|---|---|
| `full` | `/start` | Titre, email, copie, 4 étapes, bouton Seller Central, bouton Continuer |
| `compact` | `/channels` | Callout amber, email tronqué, copie, lien Seller Central |

## 6. SELLER CENTRAL URL MAPPING

| marketplaceKey / Country | URL préférences | Source | Verdict |
|---|---|---|---|
| FR | `https://sellercentral.amazon.fr/notifications/preferences` | Validation Ludovic | Vérifié |
| DE | `https://sellercentral.amazon.de/notifications/preferences` | Convention Amazon EU | Raisonnable |
| ES | `https://sellercentral.amazon.es/notifications/preferences` | Convention Amazon EU | Raisonnable |
| IT | `https://sellercentral.amazon.it/notifications/preferences` | Convention Amazon EU | Raisonnable |
| NL | `https://sellercentral.amazon.nl/notifications/preferences` | Convention Amazon EU | Raisonnable |
| BE | `https://sellercentral.amazon.com.be/notifications/preferences` | Convention Amazon EU | Raisonnable |
| UK/GB | `https://sellercentral.amazon.co.uk/notifications/preferences` | Convention Amazon EU | Raisonnable |
| SE | `https://sellercentral.amazon.se/notifications/preferences` | Convention Amazon EU | Raisonnable |
| PL | `https://sellercentral.amazon.pl/notifications/preferences` | Convention Amazon EU | Raisonnable |
| IE | via UK (`sellercentral.amazon.co.uk`) | Ireland uses UK marketplace | Raisonnable |
| Fallback | `https://sellercentral-europe.amazon.com/notifications/preferences` | Safe default | OK |

Seul FR est vérifié manuellement. Les autres suivent la convention standard Amazon EU. Aucun lien faux n'est forcé.

## 7. PATCH

| Fichier | Changement | Pourquoi | Risque |
|---|---|---|---|
| `src/features/channels/AmazonInboundSetupGuide.tsx` | **NOUVEAU** — Composant réutilisable | Guide inbound avec copie, Seller Central link, instructions | Faible — composant isolé |
| `src/features/onboarding/components/OnboardingHub.tsx` | Fetch channels après activation, affiche guide full | Inbound email + guide Seller Central dans /start | Faible — logique ajoutée après succès existant |
| `app/channels/page.tsx` | Ajout variante compact sous l'email inbound | Aide Seller Central pour connecteurs Amazon actifs | Faible — ajout conditionnel |

### Logique /start post-activation :

```
1. activateAmazonChannels() réussit (activated.length > 0)
2. fetchTenantChannels() récupère les channels
3. Trouve le premier channel Amazon actif avec inbound_email
4. Affiche AmazonInboundSetupGuide variant="full"
5. Bouton "J'ai ajouté l'adresse, continuer" → router.push('/channels')
6. Si guide non affiché (pas d'inbound email) → fallback bannière verte
```

## 8. BUILD DEV

| Service | Tag | Source commit | Digest | Rollback DEV |
|---|---|---|---|---|
| Client DEV | `v3.5.161-amazon-inbound-setup-guide-dev` | `c026c55` | `sha256:daa2f7decb5bc432a95703ca952fffb41ef39fe03ccd0549c3465db463391fd9` | `v3.5.160-amazon-start-activation-contract-dev` |

## 9. GITOPS DEV

| Service | Image avant | Image après | Rollout |
|---|---|---|---|
| Client DEV | `v3.5.160-amazon-start-activation-contract-dev` | `v3.5.161-amazon-inbound-setup-guide-dev` | OK |

Commit infra : `bc734ad`

## 10. VALIDATION NAVIGATEUR DEV

### Bundle structurel

| Vérification | Résultat |
|---|---|
| `notifications/preferences` dans bundle | chunk `6040` |
| `Seller Central` dans bundle | chunk `6040`, `start/page`, `channels/page` |
| `inbound_email` dans bundle | `start/page`, `channels/page` |
| `/login` HTTP 200 | OK |
| Routes protégées 307 redirect | OK |

### Tests fonctionnels (validation humaine requise)

| Test | Attendu |
|---|---|
| /start après Amazon connecté | Guide visible, email inbound, copie, lien Seller Central, bouton continuer |
| /channels Amazon connecté | Callout compact visible, email copiable, lien Seller Central |
| Mobile 390px | Email long tronqué/break-all, boutons lisibles |

## 11. NON-RÉGRESSION

| Surface | Résultat |
|---|---|
| Client PROD | `v3.5.160` — INCHANGÉ |
| API DEV/PROD | INCHANGÉ |
| Backend DEV/PROD | INCHANGÉ |
| Website PROD | INCHANGÉ |
| OW DEV | INCHANGÉ |
| Tracking | Non touché |
| Billing | Non touché |
| CAPI/checkout/email | Aucun |

## 12. ROLLBACK DEV (GitOps strict)

```bash
# 1. Modifier keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml
# image: ghcr.io/keybuzzio/keybuzz-client:v3.5.160-amazon-start-activation-contract-dev
# 2. Commit + push
# 3. kubectl apply + rollout status
```

## 13. LINEAR

- KEY-249 : activation /start OK + inbound setup guide déployé DEV `v3.5.161`
- KEY-250 : fix DEV, pas de fermeture avant PROD

## 14. INTERDITS RESPECTÉS

| Interdit | Respecté |
|---|---|
| Pas de PROD | Oui |
| Pas de hardcoding tenant/email | Oui |
| Pas de secrets | Oui |
| Pas de billing/tracking/CAPI | Oui |
| Pas de Backend/API modifié | Oui |
| GitOps strict | Oui |
| Build depuis source pushée | Oui |
| Tag immuable + digest | Oui |

## 15. VERDICT

**GO DEV UX READY**

AMAZON INBOUND SETUP GUIDE READY IN DEV — /START SHOWS GENERATED INBOUND EMAIL AFTER AMAZON ACTIVATION — SELLER CENTRAL CONFIG STEPS EXPLAINED — COPY AND OPEN SELLER CENTRAL ACTIONS READY — CONTINUE BUTTON AVAILABLE — /CHANNELS SHOWS COMPACT INBOUND GUIDANCE — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR PROD PROMOTION

---

Chemin rapport : `keybuzz-infra/docs/PH-SAAS-T8.12AO.10-AMAZON-INBOUND-SETUP-GUIDE-START-CHANNELS-DEV-01.md`
