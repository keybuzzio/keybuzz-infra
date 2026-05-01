# PH-T8.12U — Client Combined Sample Demo + Tracking Parity PROD

> Date : 2026-05-01
> Auteur : CE (Cursor Executor)
> Environnement : PROD
> Phase : PH-T8.12U-CLIENT-COMBINED-SAMPLE-DEMO-TRACKING-PARITY-PROD-01
> Statut : **GO COMBINED PROD**

---

## 1. OBJECTIF

Construire et déployer une image Client PROD unique qui réconcilie les deux lignées parallèles :

1. **Lignée SaaS** : Sample Demo platform-aware (`v3.5.146-sample-demo-platform-aware-prod`)
2. **Lignée Tracking** : GA4/sGTM/TikTok/LinkedIn/Meta (`v3.5.146-client-meta-pixel-dedup-safe-prod`)

Image cible : `v3.5.147-sample-demo-platform-aware-tracking-parity-prod`

---

## 2. PRÉREQUIS


| Prérequis                                  | Résultat                                         |
| ------------------------------------------ | ------------------------------------------------ |
| Rapport PH-T8.12T existe                   | **OK** — `keybuzz-infra/docs/PH-T8.12T-...01.md` |
| Verdict T8.12T = `GO RECONCILE BUILD NEXT` | **OK** — ligne 272                               |
| Aucun deploy Client PROD depuis freeze     | **OK** — dernier GitOps = `7be510f` (T8.12R.1)   |


---

## 3. FREEZE / PRÉFLIGHT


| Repo             | Branche attendue                     | Branche constatée                    | HEAD       | Dirty ? | Verdict |
| ---------------- | ------------------------------------ | ------------------------------------ | ---------- | ------- | ------- |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `195fe7cd` | Non     | **OK**  |
| `keybuzz-infra`  | `main`                               | `main`                               | `db77256`  | Non     | **OK**  |



| Service     | Image manifest                             | Image runtime                              | Digest runtime                                                            | Match ? |
| ----------- | ------------------------------------------ | ------------------------------------------ | ------------------------------------------------------------------------- | ------- |
| Client PROD | `v3.5.146-sample-demo-platform-aware-prod` | `v3.5.146-sample-demo-platform-aware-prod` | `sha256:c08e95ecfbdb6a63457a13e63c625f3684b18bf85b1e4787efdbb3ed0c455989` | **OK**  |


---

## 4. SOURCES EXACTES


| Lignée   | Image                                        | Digest                      | Commit source              | Branche                              | Build args connus                            |
| -------- | -------------------------------------------- | --------------------------- | -------------------------- | ------------------------------------ | -------------------------------------------- |
| SaaS     | `v3.5.146-sample-demo-platform-aware-prod`   | `sha256:c08e95ec...c455989` | `3d858a8`                  | `ph148/onboarding-activation-replay` | API_URL, API_BASE_URL, APP_ENV **seulement** |
| Tracking | `v3.5.146-client-meta-pixel-dedup-safe-prod` | `sha256:ba90a78...034c3fa`  | `5840a18` (base `3325f03`) | `ph-t812s/meta-pixel-dedup-safe`     | 8 build args complets                        |


---

## 5. RÉCONCILIATION SOURCE

### Merge

- Base : `ph148/onboarding-activation-replay` HEAD = `3d858a8`
- Merge : `origin/ph-t812p/tiktok-browser-pixel` HEAD = `3325f03`
- Résultat : **0 conflit**, merge automatique
- Commit merge : `af690d2`
- Seul fichier modifié : `src/lib/tracking.ts` (CompletePayment supprimé du browser)

### Comparaison fichiers


| Fichier                                      | Sample Demo | Tracking                 | Conflit ? | Résolution    |
| -------------------------------------------- | ----------- | ------------------------ | --------- | ------------- |
| `src/lib/tracking.ts`                        | Inchangé    | CompletePayment supprimé | **Aucun** | Merge auto OK |
| `src/components/tracking/SaaSAnalytics.tsx`  | Identique   | Identique                | **Aucun** | Aucune action |
| `Dockerfile`                                 | Identique   | Identique                | **Aucun** | Aucune action |
| `src/features/demo/DemoBanner.tsx`           | `onConnect` | Inchangé                 | **Aucun** | Préservé      |
| `src/features/demo/DemoDashboardPreview.tsx` | `onConnect` | Inchangé                 | **Aucun** | Préservé      |
| `src/features/demo/DemoInboxExperience.tsx`  | `onConnect` | Inchangé                 | **Aucun** | Préservé      |
| `src/features/demo/sampleData.ts`            | Multi-canal | Inchangé                 | **Aucun** | Préservé      |


---

## 6. PATCH META DEDUP SAFE

Commit : `7a02f5c`


| Signal                                        | Attendu    | Résultat                               |
| --------------------------------------------- | ---------- | -------------------------------------- |
| `trackMeta('Purchase', ...)` browser          | **ABSENT** | **OK** — remplacé par commentaire CAPI |
| `trackTikTok('CompletePayment', ...)` browser | **ABSENT** | **OK** — commenté depuis merge         |
| Meta Pixel activé via build arg               | Oui        | **OK**                                 |
| TikTok Pixel activé via build arg             | Oui        | **OK**                                 |
| GA4 + sGTM activés via build args             | Oui        | **OK**                                 |
| LinkedIn activé via build arg                 | Oui        | **OK**                                 |


---

## 7. SAMPLE DEMO INTACT


| Fonction SaaS            | Attendu | Résultat                                |
| ------------------------ | ------- | --------------------------------------- |
| 5 conversations demo     | 5       | **OK** (3 amazon + 1 email + 1 octopia) |
| 3 Amazon                 | 3       | **OK**                                  |
| 1 Octopia/Cdiscount      | 1       | **OK**                                  |
| 1 email/boutique directe | 1       | **OK**                                  |
| `onConnectAmazon` absent | 0       | **OK**                                  |
| `onConnect` présent      | ≥ 1     | **OK** (6)                              |
| 0 refund-first           | 0       | **OK**                                  |
| 0 API write dans demo    | 0       | **OK**                                  |
| Mobile master/detail     | Présent | **OK** (4 patterns)                     |


---

## 8. VALIDATION STATIQUE (pré-build)


| Check                       | Attendu                     | Résultat |
| --------------------------- | --------------------------- | -------- |
| 0 secret                    | 0                           | **PASS** |
| 0 `api-dev.keybuzz.io`      | 0                           | **PASS** |
| 0 `AW-18098643667`          | 0                           | **PASS** |
| 0 `trackMeta('Purchase')`   | 0                           | **PASS** |
| 0 `CompletePayment` browser | 0                           | **PASS** |
| Dockerfile GA4 ARG          | Présent                     | **PASS** |
| Dockerfile sGTM ARG         | Présent                     | **PASS** |
| Dockerfile TikTok ARG       | Présent                     | **PASS** |
| Dockerfile LinkedIn ARG     | Présent (default `9969977`) | **PASS** |
| Dockerfile Meta ARG         | Présent                     | **PASS** |
| SaaSAnalytics.tsx existe    | Oui                         | **PASS** |


11/11 PASS.

---

## 9. BUILD PROD


| Élément               | Valeur                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------- |
| Commit client combiné | `39591d9`                                                                                   |
| Tag                   | `ghcr.io/keybuzzio/keybuzz-client:v3.5.147-sample-demo-platform-aware-tracking-parity-prod` |
| Digest                | `sha256:d50740d58338129cb289640e2f69cf21164d33ccd3e754e9a737e9a44b5bbde3`                   |
| Source                | Clone temporaire propre `/tmp/build-client-combined-prod`                                   |
| Workspace clean       | Oui (0 fichiers modifiés avant build)                                                       |


### Build args (8/8)


| Arg                               | Valeur                   |
| --------------------------------- | ------------------------ |
| `NEXT_PUBLIC_API_URL`             | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL`        | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_APP_ENV`             | `production`             |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID`  | `G-R3QQDYEBFG`           |
| `NEXT_PUBLIC_SGTM_URL`            | `https://t.keybuzz.pro`  |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID`     | `D7PT12JC77U44OJIPC10`   |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977`                |
| `NEXT_PUBLIC_META_PIXEL_ID`       | `1234164602194748`       |


---

## 10. GITOPS


| Élément             | Valeur                                                     |
| ------------------- | ---------------------------------------------------------- |
| Commit infra        | `684a360`                                                  |
| Image avant         | `v3.5.146-sample-demo-platform-aware-prod`                 |
| Image après         | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` |
| Rollback annotation | `v3.5.146-sample-demo-platform-aware-prod`                 |


### Rollout


| Manifest                                                   | Image runtime                                              | Digest runtime             | Match ? |
| ---------------------------------------------------------- | ---------------------------------------------------------- | -------------------------- | ------- |
| `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | `sha256:d50740d5...5bbde3` | **OK**  |


---

## 11. VALIDATION BUNDLE (serveur)


| Signal                        | Bundle PROD | Résultat |
| ----------------------------- | ----------- | -------- |
| GA4 `G-R3QQDYEBFG`            | 1 match     | **PASS** |
| sGTM `t.keybuzz.pro`          | 2 matches   | **PASS** |
| TikTok `D7PT12JC77U44OJIPC10` | 1 match     | **PASS** |
| LinkedIn `9969977`            | 1 match     | **PASS** |
| Meta `1234164602194748`       | 1 match     | **PASS** |
| `trackMeta Purchase` browser  | 0 match     | **PASS** |
| `CompletePayment` browser     | 0 match     | **PASS** |
| `AW-18098643667`              | 0 match     | **PASS** |
| `onConnect` present           | 1 match     | **PASS** |
| `onConnectAmazon` absent      | 0 match     | **PASS** |
| Demo data `conv-001`          | 2 matches   | **PASS** |


11/11 PASS.

**Validation HAR navigateur confirmée par Ludovic (2026-05-01 20:33 UTC+2) — VISUAL QA DONE.**


| Page         | GA4 | sGTM | TikTok | LinkedIn | Meta | Purchase absent | Protected clean         |
| ------------ | --- | ---- | ------ | -------- | ---- | --------------- | ----------------------- |
| `/register`  | OK  | OK   | OK     | OK       | OK   | OK              | —                       |
| `/login`     | OK  | OK   | OK     | OK       | OK   | OK              | —                       |
| `/dashboard` | —   | —    | —      | —        | —    | —               | **OK** (0 tracking pub) |


AW direct absent. Meta Purchase browser absent. TikTok CompletePayment browser absent.

---

## 12. NON-RÉGRESSION PRODUIT


| Surface                         | Attendu                                        | Résultat |
| ------------------------------- | ---------------------------------------------- | -------- |
| 0 conversations demo en PROD DB | 0                                              | **PASS** |
| 0 messages demo en PROD DB      | 0                                              | **PASS** |
| 0 fake billing events           | 0                                              | **PASS** |
| Billing subscriptions           | 15 (inchangé)                                  | **PASS** |
| API PROD health                 | OK                                             | **PASS** |
| Client PROD health              | 200 `/login`, 307 `/` (redirect auth)          | **PASS** |
| API PROD inchangée              | `v3.5.130-platform-aware-refund-strategy-prod` | **PASS** |
| Backend PROD inchangé           | `v1.0.46-ph-recovery-01-prod`                  | **PASS** |
| Admin inchangé                  | `keybuzz-admin-v2-prod`                        | **PASS** |
| 0 fake event / fake spend       | 0                                              | **PASS** |


---

## 13. ROLLBACK GITOPS STRICT

**Image rollback** : `v3.5.146-sample-demo-platform-aware-prod`

**Procédure** :

1. Modifier `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml`
2. Remplacer l'image par `v3.5.146-sample-demo-platform-aware-prod`
3. Commit : `rollback(client-prod): v3.5.146-sample-demo-platform-aware-prod (PH-T8.12U rollback)`
4. Push + `kubectl apply -f` + `kubectl rollout status`

**Risque** : Ce rollback restaure la Sample Demo platform-aware mais **reperd l'intégralité du tracking** (GA4, sGTM, TikTok, LinkedIn, Meta). L'image `v3.5.146-sample-demo-platform-aware-prod` a été construite sans build args tracking.

**Interdit** : `kubectl set image` n'est pas une option de rollback valide.

---

## 14. COMMITS

### keybuzz-client (`ph148/onboarding-activation-replay`)


| Commit    | Message                                                                                              |
| --------- | ---------------------------------------------------------------------------------------------------- |
| `af690d2` | `merge(tracking): integrate TikTok CompletePayment removal from ph-t812p (PH-T8.12U reconciliation)` |
| `7a02f5c` | `fix(tracking): remove Meta Purchase browser — server-side only via CAPI (PH-T8.12U reconciliation)` |
| `39591d9` | `cleanup: remove parasitic keybuzz-client/ nested directory (PH-T8.12U)`                             |


### keybuzz-infra (`main`)


| Commit    | Message                                                                                     |
| --------- | ------------------------------------------------------------------------------------------- |
| `684a360` | `deploy(client-prod): v3.5.147-sample-demo-platform-aware-tracking-parity-prod (PH-T8.12U)` |


---

## 15. VERDICT

**GO COMBINED PROD**

CLIENT PROD COMBINED IMAGE LIVE — SAMPLE DEMO PLATFORM-AWARE PRESERVED — GA4 SGTM TIKTOK LINKEDIN META ACTIVE ON FUNNEL — PURCHASE/COMPLETEPAYMENT BROWSER ABSENT — PROTECTED PAGES CLEAN — NO FAKE EVENT — NO BILLING DRIFT — GITOPS STRICT

### Preuves axes obligatoires

1. **SaaS Demo platform-aware présent** :
  - 5 conversations demo (3 Amazon, 1 Octopia, 1 email) dans le bundle
  - `onConnect` présent (6 matches), `onConnectAmazon` absent (0)
  - 0 refund-first, 0 API write
  - 0 rows demo en PROD DB
2. **Tracking funnel complet restauré** :
  - GA4 `G-R3QQDYEBFG` : 1 match bundle
  - sGTM `t.keybuzz.pro` : 2 matches bundle
  - TikTok `D7PT12JC77U44OJIPC10` : 1 match bundle
  - LinkedIn `9969977` : 1 match bundle
  - Meta `1234164602194748` : 1 match bundle
  - `Purchase` browser : 0 match (server-side CAPI only)
  - `CompletePayment` browser : 0 match (server-side Events API only)