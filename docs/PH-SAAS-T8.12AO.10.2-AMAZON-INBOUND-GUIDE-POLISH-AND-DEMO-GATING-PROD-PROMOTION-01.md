# PH-SAAS-T8.12AO.10.2 — Amazon Inbound Guide Polish + Demo Gating PROD Promotion

> **Date** : 6 mai 2026
> **Environnement** : PROD
> **Type** : Promotion Client PROD uniquement
> **Priorité** : P0
> **Linear** : KEY-250, KEY-252

---

## Résumé

Promotion en PROD du patch Client validé en DEV dans PH-SAAS-T8.12AO.10.1 :

1. **Guide Amazon inbound poli** :
   - Miniatures Seller Central cliquables (notification-retours.jpg, messagerie.jpg)
   - Lightbox au clic sur miniature
   - Variante compact `/channels` sans doublon d'adresse email
   - Espacement corrigé avant "OAuth actif"
   - Variante full `/start` préservée avec miniatures

2. **Correction Sample Demo** :
   - Sample Demo cachée dès qu'un canal réel actif est connecté
   - État vide honnête en attendant les premiers messages
   - Sample Demo conservée pour tenants vides sans canal réel

---

## Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `05d171d1` | Non | OK |
| keybuzz-infra | `main` | `ec402d4` | Non | OK |

| Service | Runtime avant | Manifest | Verdict |
|---|---|---|---|
| Client DEV | `v3.5.162-amazon-inbound-guide-demo-gating-dev` | Aligné | OK |
| Client PROD | `v3.5.160-amazon-start-activation-contract-prod` | Baseline | OK |
| API PROD | `v3.5.142-promo-retry-email-prod` | INCHANGÉ | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | INCHANGÉ | OK |
| Website PROD | `v0.6.9-promo-forwarding-prod` | INCHANGÉ | OK |
| Admin PROD | `keybuzz-admin-v2-prod` | INCHANGÉ | OK |

- DEV validée par Ludovic
- PROD promotion explicitement demandée
- Client uniquement — API/Backend/Admin/Website hors scope

---

## Source DEV validée

| Brique | Point vérifié | Résultat |
|---|---|---|
| Guide Amazon | `AmazonInboundSetupGuide.tsx` | Présent |
| Miniatures SC | `TutorialThumbnails` + 2 images | OK |
| Lightbox | `lightbox` state + modal overlay | OK |
| Compact sans doublon | Pas d'`inboundEmail` dans compact render | OK |
| Full `/start` | `TutorialThumbnails` dans variante full | OK |
| Assets | `notification-retours.jpg` + `messagerie.jpg` | OK |
| `useDemoMode` | `hasRealChannel` param + condition | OK |
| Inbox gating | `REAL_PROVIDERS` + `fetchTenantChannels` | OK |
| Dashboard gating | `REAL_PROVIDERS_DASH` + même logique | OK |
| Backward compat | `hasRealChannel?:` optionnel | OK |

Commit source : `05d171d1`

---

## Build PROD

| Élément | Valeur |
|---|---|
| Commit Client | `05d171d1` |
| Tag PROD | `v3.5.162-amazon-inbound-guide-demo-gating-prod` |
| Digest | `sha256:f76e21f0ebe9f18b182a6307f1ad0d40592aa1d7b9640c2f03a7247b652bc056` |
| Rollback | `v3.5.160-amazon-start-activation-contract-prod` |

### Build args tracking PROD

| Arg | Valeur |
|---|---|
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_APP_ENV` | `production` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | `D7PT12JC77U44OJIPC10` |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977` |
| `NEXT_PUBLIC_META_PIXEL_ID` | `1234164602194748` |

---

## Audit bundle tracking

| Signal | Attendu | Résultat |
|---|---|---|
| GA4 `G-R3QQDYEBFG` | Présent | OK (1 match) |
| sGTM `t.keybuzz.pro` | Présent | OK (1 match) |
| TikTok `D7PT12JC77U44OJIPC10` | Présent | OK (1 match) |
| LinkedIn `9969977` | Présent | OK (1 match) |
| Meta `1234164602194748` | Présent | OK (1 match) |
| Meta Purchase browser `fbq` | Absent | OK — `onPurchase` prop React ≠ `fbq` |
| TikTok CompletePayment browser | Absent | OK (0 match) |
| Assets Amazon miniatures | Présent | OK (2 fichiers) |
| `hasRealChannel` gating | Présent | OK (1 match) |
| `notifications/preferences` (SC URL) | Présent | OK (1 match) |

---

## GitOps

| Élément | Valeur |
|---|---|
| Manifest modifié | `k8s/keybuzz-client-prod/deployment.yaml` |
| Image avant | `v3.5.160-amazon-start-activation-contract-prod` |
| Image après | `v3.5.162-amazon-inbound-guide-demo-gating-prod` |
| Commit infra | `4cd8399` |
| Rollback | `v3.5.160-amazon-start-activation-contract-prod` |

---

## Rollout

| Check | Résultat |
|---|---|
| Rollout | `successfully rolled out` |
| Pod | 1/1 Running, 0 restart |
| Image runtime | `v3.5.162-amazon-inbound-guide-demo-gating-prod` |
| Digest runtime | `sha256:f76e21f0ebe9f18b182a6307f1ad0d40592aa1d7b9640c2f03a7247b652bc056` |
| Digest = build | OK |
| Manifest = runtime | OK |

---

## Validation structurelle

| Surface | Attendu | Résultat |
|---|---|---|
| `/channels` | HTTP 307→200 | OK |
| `/start` | HTTP 307→200 | OK |
| `/inbox` | HTTP 307→200 | OK |
| `/dashboard` | HTTP 307→200 | OK |
| `/login` | HTTP 200 direct | OK |
| Assets Amazon | 2 fichiers (96KB + 59KB) | OK |
| `hasRealChannel` bundle | 3 chunks | OK |
| `setLightbox` bundle | 1 chunk | OK |

---

## Validation visuelle PROD

| Surface | Attendu | Résultat |
|---|---|---|
| `/channels` desktop | Guide compact, miniatures, copier, SC link, pas de doublon email | OK |
| Miniature click | Lightbox s'ouvre (image agrandie) | OK |
| Close lightbox | Fermeture au clic X | OK |
| Espacement callout / OAuth actif | Correct | OK |
| `/start` desktop | Page fonctionnelle, pas de crash | OK |
| `/inbox` | Données réelles (514 conv), pas de Sample Demo | OK |
| `/dashboard` | Données réelles, KPI, SLA 100%, pas de Sample Demo | OK |
| Sample Demo cachée tenant connecté | Confirmé (ecomlg-001, 5 canaux Amazon) | OK |

---

## Non-régression

| Domaine | Résultat |
|---|---|
| API PROD | `v3.5.142-promo-retry-email-prod` — INCHANGÉ |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` — INCHANGÉ |
| Website PROD | `v0.6.9-promo-forwarding-prod` — INCHANGÉ |
| OW PROD | `v3.5.165-escalation-flow-prod` — INCHANGÉ |
| CronJobs | INCHANGÉS |
| billing | 0 mutation |
| Stripe | 0 checkout créé |
| CAPI | 0 fake event |
| tracking | GA4+sGTM+TikTok+LinkedIn+Meta préservés |
| lifecycle emails | 0 email |
| Amazon OAuth | INCHANGÉ |

---

## Services inchangés

- API PROD : `v3.5.142-promo-retry-email-prod`
- Backend PROD : `v1.0.47-cross-env-guard-fix-prod`
- Website PROD : `v0.6.9-promo-forwarding-prod`
- OW PROD : `v3.5.165-escalation-flow-prod`
- Admin PROD : `keybuzz-admin-v2-prod`
- CronJobs : tous inchangés
- DB : 0 mutation

---

## Rollback GitOps

En cas de régression :
1. Modifier `k8s/keybuzz-client-prod/deployment.yaml` → image `v3.5.160-amazon-start-activation-contract-prod`
2. Commit + push infra
3. `kubectl apply -f` sur le bastion
4. Vérifier rollout

---

## Linear

**KEY-250** : Promotion PROD faite — miniatures Seller Central live, compact sans doublon email, guide `/start` préservé. Ne pas fermer sans validation Ludovic.

**KEY-252** : Demo gating promu PROD — tenant connecté ne voit plus de Sample Demo, état vide honnête. Ne pas fermer sans validation Ludovic.

---

## Verdict

### GO PROD

- Client PROD live : `v3.5.162-amazon-inbound-guide-demo-gating-prod`
- Digest : `sha256:f76e21f0ebe9f18b182a6307f1ad0d40592aa1d7b9640c2f03a7247b652bc056`
- Tracking préservé (GA4+sGTM+TikTok+LinkedIn+Meta)
- Guide Amazon OK (miniatures, lightbox, compact sans doublon, full préservé)
- Demo gating OK (caché après canal réel, honnête en vide)
- Validation structurelle OK
- Validation visuelle OK
- Aucune régression

**AMAZON INBOUND GUIDE POLISHED LIVE IN PROD — SELLER CENTRAL MINI-TUTORIAL THUMBNAILS ADDED — COMPACT CHANNEL CALLOUT NO LONGER DUPLICATES EMAIL — START GUIDE PRESERVED — SAMPLE DEMO HIDDEN AFTER REAL CHANNEL CONNECTION — EMPTY STATE HONEST — CLIENT TRACKING PRESERVED — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT**
