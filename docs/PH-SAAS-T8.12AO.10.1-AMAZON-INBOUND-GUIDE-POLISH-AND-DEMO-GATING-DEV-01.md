# PH-SAAS-T8.12AO.10.1 — Amazon Inbound Guide Polish + Demo Gating — DEV

> Date : 2026-05-06
> Auteur : Agent Cursor
> Environnement : DEV uniquement
> Tickets : KEY-250, KEY-252 (non fermés)
> Phase précédente : AO.10 (inbound setup guide)

---

## 1. CONTEXTE

Deux corrections après AO.10 :

1. **Guide inbound Amazon** : le callout compact sur `/channels` dupliquait l'email inbound déjà affiché au-dessus, manquait d'espacement avec "OAuth actif", et ne contenait pas de captures visuelles Seller Central.

2. **Sample Demo** : la démo restait visible même après connexion d'un vrai canal, tant qu'aucun message réel n'existait. Un tenant connecté à Amazon mais sans messages voyait encore les données simulées.

## 2. PREFLIGHT

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `c026c55c` | Non | OK |
| keybuzz-infra | `main` | `2b25abf` | Non | OK |

| Service | Runtime | Verdict |
|---|---|---|
| Client DEV | `v3.5.161-amazon-inbound-setup-guide-dev` | OK |
| Client PROD | `v3.5.160-amazon-start-activation-contract-prod` | INCHANGÉ |
| API PROD | `v3.5.142-promo-retry-email-prod` | INCHANGÉ |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | INCHANGÉ |

## 3. SOURCES LUES

- `CE_PROMPTING_STANDARD.md` ✓
- `RULES_AND_RISKS.md` ✓
- `AMAZON_SPAPI_CONNECTOR_BASELINE.md` ✓
- `PH-SAAS-T8.12AO.10-AMAZON-INBOUND-SETUP-GUIDE-START-CHANNELS-DEV-01.md` ✓
- `PH-SAAS-T8.12AO.9-*` ✓

## 4. ASSETS

| Asset | Source | Destination | Taille | Verdict |
|---|---|---|---|---|
| Notification de retours | `C:\Users\ludov\Downloads\Notification de retours.jpg` | `public/images/amazon/notification-retours.jpg` | 58.4 KB | OK |
| Messagerie | `C:\Users\ludov\Downloads\Messagerie.jpg` | `public/images/amazon/messagerie.jpg` | 93.8 KB | OK |

## 5. PATCH GUIDE AMAZON INBOUND

### Composant `AmazonInboundSetupGuide.tsx`

Changements :
- Ajout `TutorialThumbnails` sub-component avec lightbox (clic miniature → modal plein écran)
- Images : `notification-retours.jpg` + `messagerie.jpg` (120×80px miniatures)
- Lightbox : overlay noir 70%, image max 900px, bouton fermer, clic extérieur ferme
- Import `next/image` + icône `X` de lucide-react

#### Variante `full` (`/start`)

| Changement | Détail |
|---|---|
| Miniatures ajoutées | Après les étapes 1-4, avant les boutons |
| Email inbound | Conservé (c'est la variante full) |
| Boutons | Seller Central + Continuer inchangés |

#### Variante `compact` (`/channels`)

| Changement | Détail |
|---|---|
| Email supprimé | Plus de doublon — l'email est déjà dans le bloc gris au-dessus |
| Texte reformulé | "Dernière étape : ajoutez l'adresse KeyBuzz dans Seller Central pour recevoir vos messages." |
| Miniatures ajoutées | Deux miniatures cliquables |
| Espacement | `mt-4 mb-3` (était `mt-3`) pour aération avant "OAuth actif" |

## 6. PATCH DEMO GATING

### Hook `useDemoMode.ts`

- Ajout `hasRealChannel?: boolean` dans `DemoModeOptions`
- Condition mise à jour : `isDemoAvailable = Boolean(tenantId) && conversationCount === 0 && !hasRealChannel`
- Backward compatible : si `hasRealChannel` non passé, comportement identique

### `app/inbox/page.tsx`

- Import `fetchTenantChannels` depuis `channels.service`
- Fetch channels en parallèle du convCount existant
- `hasRealChannel = channels.some(ch => ch.status === 'active' && REAL_PROVIDERS.has(ch.provider))`
- `REAL_PROVIDERS` : `amazon`, `octopia`, `cdiscount`, `shopify`, `fnac`
- Passé à `useDemoMode({ ..., hasRealChannel })`

### `app/dashboard/page.tsx`

- Même pattern que inbox
- Import `fetchTenantChannels`
- Fetch channels, calcul `hasRealChannelDash`
- Passé à `useDemoMode`

### Matrice Demo Gating

| Cas | Attendu | Implémentation |
|---|---|---|
| Tenant vide sans canal | Demo visible | `convCount=0, hasRealChannel=false` → demo ON |
| Tenant vide avec Amazon actif | Demo cachée | `convCount=0, hasRealChannel=true` → demo OFF |
| Tenant avec conversations | Données réelles | `convCount>0` → demo OFF |
| Canal pending | Pas considéré connecté | `status !== 'active'` → ignoré |
| Canal removed | Pas considéré connecté | `status !== 'active'` → ignoré |

Aucun nouvel endpoint API nécessaire — `fetchTenantChannels` existe déjà.

## 7. BUILD

| Élément | Valeur |
|---|---|
| Commit Client | `05d171d1` |
| Tag DEV | `v3.5.162-amazon-inbound-guide-demo-gating-dev` |
| Digest | `sha256:bf756b14ea698208a92048e8dc7c3d6fdc79eaeb4540747737b4d6429624af16` |
| Source build | bastion `install-v3`, git origin/ph148 |
| Rollback | `v3.5.161-amazon-inbound-setup-guide-dev` |

## 8. GITOPS

| Élément | Valeur |
|---|---|
| Commit infra | `bb80af9` |
| Image avant | `v3.5.161-amazon-inbound-setup-guide-dev` |
| Image après | `v3.5.162-amazon-inbound-guide-demo-gating-dev` |
| Pod | `keybuzz-client-5f7b99864-z6znc` |
| Restarts | 0 |
| Rollout | OK |
| Manifest = runtime | OK |

## 9. VALIDATION NAVIGATEUR

### Bundle structurel

| Check | Résultat |
|---|---|
| Images Amazon dans pod | `messagerie.jpg` (96K) + `notification-retours.jpg` (60K) |
| `notifications/preferences` dans bundle | chunk `6040` |
| `hasRealChannel` dans bundle | chunk `3514` + `dashboard/page` + `inbox/page` |
| `notification-retours` ref dans bundle | chunk `6040` |
| `/login` HTTP 200 | OK |
| Pages protégées 307 | OK |

### Tests fonctionnels (validation humaine requise)

| URL | Tenant | Viewport | Test | Attendu |
|---|---|---|---|---|
| `/channels` | ecomlg-001 (Amazon actif) | Desktop | Callout compact visible | Pas de doublon email, miniatures, SC link |
| `/channels` | ecomlg-001 | Mobile 390px | Callout compact | Miniatures lisibles, pas d'overflow |
| `/start` | Nouveau tenant | Desktop | Guide full | Email + copie + miniatures + continuer |
| `/inbox` | ecomlg-001 (Amazon actif, 124 convs) | Desktop | Données réelles | Pas de demo |
| `/inbox` | tenant vide sans canal | Desktop | Demo visible | DemoInboxExperience |
| `/dashboard` | ecomlg-001 | Desktop | Données réelles | Pas de demo |

## 10. NON-RÉGRESSION

| Surface | Résultat |
|---|---|
| Client PROD | `v3.5.160` — INCHANGÉ |
| API PROD | `v3.5.142` — INCHANGÉ |
| Backend PROD | `v1.0.47` — INCHANGÉ |
| Website PROD | `v0.6.9` — INCHANGÉ |
| OW DEV | `v3.5.165` — INCHANGÉ |
| API DEV | `v3.5.155` — INCHANGÉ |
| Tracking | Non touché |
| Billing | Non touché |
| CAPI/checkout/email | 0 |

## 11. ROLLBACK DEV (GitOps strict)

```bash
# Modifier keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml
# image: ghcr.io/keybuzzio/keybuzz-client:v3.5.161-amazon-inbound-setup-guide-dev
# Commit + push + kubectl apply + rollout status
```

## 12. LINEAR

- **KEY-250** : Guide Amazon inbound poli — miniatures ajoutées, doublon supprimé, espacement corrigé. DEV `v3.5.162`.
- **KEY-252** : Demo masquée après connexion canal réel. `hasRealChannel` dans `useDemoMode`. Pas de fermeture avant PROD.

## 13. INTERDITS RESPECTÉS

| Interdit | Respecté |
|---|---|
| Pas de PROD | Oui |
| Pas de hardcoding | Oui |
| Pas de secrets | Oui |
| Pas de billing/tracking/CAPI | Oui |
| Pas de Backend/API modifié | Oui |
| GitOps strict | Oui |
| Build depuis source pushée | Oui |
| Tag immuable + digest | Oui |
| Pas de nouvel endpoint API | Oui |

## 14. GAPS

- Validation visuelle humaine requise pour miniatures + lightbox
- Les URLs Seller Central hors FR ne sont pas vérifiées manuellement (convention Amazon EU)
- L'empty state inbox pour un tenant connecté sans messages utilise l'inbox classique (affiche une liste vide) — pas de wording custom "Vos premiers messages apparaîtront ici". Ce wording pourrait être ajouté dans une phase ultérieure.

## 15. VERDICT

**GO DEV UX READY**

AMAZON INBOUND GUIDE POLISHED IN DEV — SELLER CENTRAL MINI-TUTORIAL THUMBNAILS ADDED — COMPACT CHANNEL CALLOUT NO LONGER DUPLICATES EMAIL — START GUIDE PRESERVED — SAMPLE DEMO HIDDEN AFTER REAL CHANNEL CONNECTION — EMPTY STATE HONEST — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC VISUAL QA

---

Chemin rapport : `keybuzz-infra/docs/PH-SAAS-T8.12AO.10.1-AMAZON-INBOUND-GUIDE-POLISH-AND-DEMO-GATING-DEV-01.md`
