# PH-SAAS-T8.12AP.1B — AI No-Reask Client PROD Promotion

> Phase : PH-SAAS-T8.12AP.1B-AI-NO-REASK-CLIENT-PROD-PROMOTION-01
> Date : 2026-05-07
> Type : promotion Client PROD + validation no-reask
> Priorité : P0
> Verdict : **GO PARTIEL — LUDOVIC QA PENDING**

---

## 1. FREEZE CLIENT PROD

| Élément | Valeur |
|---|---|
| Runtime Client PROD avant | `v3.5.162-amazon-inbound-guide-demo-gating-prod` |
| Digest PROD avant | `sha256:f76e21f0ebe9f18b182a6307f1ad0d40592aa1d7b9640c2f03a7247b652bc056` |
| Dernier commit manifest avant | Ligne 74 deployment.yaml |
| Rollout avant | 1/1 Ready, Running, 0 restarts |
| Freeze confirmé | Oui — seul Client PROD touché |

Services non touchés :
- API PROD : `v3.5.142-promo-retry-email-prod` — INCHANGÉE
- Backend PROD : `v1.0.47-cross-env-guard-fix-prod` — INCHANGÉ
- Website PROD : `v0.6.9-promo-forwarding-prod` — INCHANGÉ

---

## 2. PREFLIGHT

| Repo | Branche | Commit HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `d254b611` | 10 fichiers (hors scope) | **OK** |
| keybuzz-infra | `main` | `7afa8fb` | Scripts + docs (hors scope) | **OK** |

### Runtimes avant promotion

| Service | Env | Image |
|---|---|---|
| Client | PROD | `v3.5.162-amazon-inbound-guide-demo-gating-prod` |
| Client | DEV | `v3.5.163-ai-no-reask-fix-dev` |
| API | PROD | `v3.5.142-promo-retry-email-prod` |
| API | DEV | `v3.5.155-promo-retry-metadata-email-dev` |
| Backend | PROD | `v1.0.47-cross-env-guard-fix-prod` |
| Backend | DEV | `v1.0.47-cross-env-guard-fix-dev` |

---

## 3. SOURCE PARITY CHECK

| Feature baseline | Présente source | Preuve | Verdict |
|---|---|---|---|
| Fix no-reask orderRef | ✅ | `AISuggestionSlideOver.tsx:319-326` | OK |
| Fix no-reask instruction | ✅ | `AISuggestionSlideOver.tsx:324-326` | OK |
| Retry/régénération | ✅ | fullContext recalculé chaque appel | OK |
| AmazonInboundSetupGuide | ✅ | `src/features/channels/AmazonInboundSetupGuide.tsx` | OK |
| Seller Central miniatures | ✅ | Dans AmazonInboundSetupGuide.tsx | OK |
| Demo gating hasRealChannel | ✅ | `src/features/demo/useDemoMode.ts` | OK |
| Shopify PNG officiel | ✅ | `app/channels/page.tsx`, `app/billing/options/page.tsx` | OK |
| PromoPreviewBanner | ✅ | `app/register/page.tsx` | OK |
| GA4 ARG | ✅ | `Dockerfile:13,23` | OK |
| sGTM ARG | ✅ | `Dockerfile:15,25` | OK |
| TikTok ARG | ✅ | `Dockerfile:16,26` | OK |
| LinkedIn ARG | ✅ | `Dockerfile:17,27` (default=9969977) | OK |
| Meta ARG | ✅ | `Dockerfile:14,24` | OK |
| Meta Purchase browser | ❌ (absent) | 0 matches code source | OK |
| TikTok CompletePayment browser | ❌ (absent) | 0 matches code source | OK |

**Toutes les features baseline sont présentes. Pas de STOP BASELINE RISK.**

---

## 4. BUILD CLIENT PROD

| Paramètre | Valeur |
|---|---|
| Commit source | `d254b611` |
| Tag | `ghcr.io/keybuzzio/keybuzz-client:v3.5.163-ai-no-reask-fix-prod` |
| Digest | `sha256:988fb4b22de347fb1088b7905cc782ca8d1bea029e12647781b960e11bf9ae6e` |
| Rollback | `v3.5.162-amazon-inbound-guide-demo-gating-prod` |

### Build args

```
NEXT_PUBLIC_API_URL=https://api.keybuzz.io
NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io
NEXT_PUBLIC_APP_ENV=production
NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG
NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro
NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10
NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977
NEXT_PUBLIC_META_PIXEL_ID=1234164602194748
```

### Commande exacte

```bash
cd /opt/keybuzz/keybuzz-client
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  --build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG \
  --build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro \
  --build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10 \
  --build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977 \
  --build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748 \
  -t ghcr.io/keybuzzio/keybuzz-client:v3.5.163-ai-no-reask-fix-prod .
```

---

## 5. GITOPS PROD

- Manifest modifié : `k8s/keybuzz-client-prod/deployment.yaml`
- Commit GitOps : `0306885`
- Push : `main → main`
- `kubectl apply -f` : OK
- `kubectl rollout status` : `deployment "keybuzz-client" successfully rolled out`
- Runtime confirmé : `v3.5.163-ai-no-reask-fix-prod`, pod 1/1 Running, 0 restarts
- Digest runtime : `sha256:988fb4b22de347fb1088b7905cc782ca8d1bea029e12647781b960e11bf9ae6e` (correspond au push)

Manifests non touchés : API PROD, Backend PROD, Website PROD, Admin PROD, CronJobs, secrets, DB.

---

## 6. VALIDATION STRUCTURELLE PROD (bundle)

| Signal | Présent runtime PROD | Attendu | Verdict |
|---|---|---|---|
| `[COMMANDE CONNUE]` | ✅ chunks/1024 + server/1990 | Oui | **OK** |
| `[INSTRUCTION OBLIGATOIRE]` | ✅ chunks/1024 + server/1990 | Oui | **OK** |
| GA4 `G-R3QQDYEBFG` | ✅ chunks/1918 + register | Oui | **OK** |
| sGTM `t.keybuzz.pro` | ✅ chunks/1918 + register | Oui | **OK** |
| TikTok `D7PT12JC77U44OJIPC10` | ✅ layout + chunks/1918 | Oui | **OK** |
| LinkedIn `9969977` | ✅ layout + chunks/1918 | Oui | **OK** |
| Meta `1234164602194748` | ✅ layout + chunks/1918 | Oui | **OK** |
| API `api.keybuzz.io` | ✅ chunks/1990 | Oui | **OK** |
| Meta Purchase browser | ❌ (absent) | Absent | **OK** |
| TikTok CompletePayment browser | ❌ (absent) | Absent | **OK** |

---

## 7. VALIDATION FONCTIONNELLE PROD (read-only)

| Cas | Donnée connue | Comportement attendu | Résultat | Preuve |
|---|---|---|---|---|
| A. orderRef connu | orderRef passé par InboxTripane | IA ne demande pas numéro commande | **OK structurel** | `[COMMANDE CONNUE]` + `[INSTRUCTION OBLIGATOIRE]` dans bundle |
| B. orderRef + tracking | orderRef + backend T8.12AF | IA ne demande ni commande ni tracking | **OK structurel** | Client + serveur couverts |
| C. Sans orderRef | null | IA peut demander honnêtement | **OK structurel** | Pas de bloc anti-reask quand null |
| D. Retry/régénération | Même conversation | Même fullContext recalculé | **OK structurel** | useCallback recalcule à chaque appel |

**Limite** : pas de test navigateur réel effectué pour éviter tout envoi accidentel. QA Ludovic recommandée.

---

## 8. PLAN GATES PROD

| Plan | Aide IA | KBActions/mois | Auto-send | Verdict |
|---|---|---|---|---|
| STARTER | Oui (teaser, 0 KBA) | 0 | Non | **OK** |
| PRO | Oui (illimité) | 1000 | Non | **OK** |
| AUTOPILOT_ASSISTED | Oui (illimité) | 1000 | Non | **OK** |
| AUTOPILOT | Oui (illimité) | 2000 | Oui (guardrails) | **OK** |

Aucun bypass. Le fix AP.1B ne modifie que `fullContext` dans `AISuggestionSlideOver.tsx`. `planCapabilities.ts` inchangé.

---

## 9. NON-RÉGRESSION PROD

| Point | Résultat |
|---|---|
| Client PROD | `v3.5.163-ai-no-reask-fix-prod`, 1/1 Running, 0 restarts |
| API PROD | `v3.5.142-promo-retry-email-prod` — **INCHANGÉE** |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` — **INCHANGÉ** |
| Website PROD | `v0.6.9-promo-forwarding-prod` — **INCHANGÉ** |
| /login PROD | HTTP 200 |
| /register PROD | HTTP 200 |
| /pricing PROD | HTTP 200 |
| Tracking public | GA4 + sGTM + TikTok + LinkedIn + Meta dans bundle |
| Meta Purchase browser | Absent |
| TikTok CompletePayment browser | Absent |
| Outbound | 0 |
| Billing drift | 0 |
| Stripe mutation | 0 |
| CAPI | 0 |
| Auto-send IA | 0 |

---

## 10. LINEAR

### KEY-256 — AI no-reask order/tracking
- **Statut** : Promotion PROD effectuée. Tag `v3.5.163-ai-no-reask-fix-prod`.
- **QA Ludovic pending** : validation navigateur réelle recommandée sur une conversation avec orderRef.
- **Recommandation** : passer en **In Review** → fermer après QA Ludovic.

### KEY-253 — Synthèse parent AI messaging
- **Statut** : no-reask déployé DEV + PROD. Plan gates vérifiés. Escalade (KEY-255/KEY-263) reste hors scope.

### KEY-255 / KEY-263
- **Non traités** dans cette phase (hors scope).

---

## 11. ROLLBACK

Procédure GitOps stricte :

```yaml
# Dans k8s/keybuzz-client-prod/deployment.yaml, remplacer :
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.163-ai-no-reask-fix-prod
# Par :
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.162-amazon-inbound-guide-demo-gating-prod
```

```bash
cd /opt/keybuzz/keybuzz-infra
git pull
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## 12. VERDICT

### GO PARTIEL — LUDOVIC QA PENDING

Tout est structurellement validé :
- Build PROD OK
- Déploiement GitOps OK
- Bundle contient le fix no-reask + toutes les baselines
- Tracking préservé
- Plan gates préservés
- Non-régression OK

**QA Ludovic recommandée** : ouvrir l'inbox PROD, sélectionner une conversation avec un orderRef visible, cliquer "Aide IA", vérifier que la suggestion ne demande pas le numéro de commande.

### Commits

| Repo | Branche | Commit | Description |
|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `d254b611` | fix(ai): always inject orderRef + anti-reask instruction (KEY-256) |
| keybuzz-infra | `main` | `0306885` | gitops(prod): Client PROD v3.5.163-ai-no-reask-fix-prod (KEY-256) |

### Phrase cible

AI NO-REASK FIX LIVE IN PROD — ORDERREF ALWAYS INJECTED IN IA DRAWER CONTEXT — KNOWN ORDER/TRACKING DATA NO LONGER REQUESTED FROM CUSTOMER — PLAN GATES PRESERVED — STARTER IA REMAINS KBACTIONS-GATED — CLIENT TRACKING/PROMO/AMAZON INBOUND/DEMO GATING BASELINES PRESERVED — NO AUTO-SEND — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT — LUDOVIC QA PENDING
