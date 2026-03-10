# PH-S03.5E — Validation par navigateur headless (Playwright)

**Date :** 2026-02-02  
**Périmètre :** Prouver via Playwright (exécution JS) : Catalog Sources sans bandeau « Unknown error », wizard FTP 5 étapes max, pas d’étape « Mapping des colonnes ».  
**Environnement :** seller-dev uniquement.  
**Règles :** CE exécute tout, DEV only, GitOps only, cookies/tokens masqués, bastion install-v3 / CI uniquement.

---

## 1. Objectifs (critères de sortie)

| Id | Critère |
|----|--------|
| A | Playwright ouvre seller-dev avec une session valide et prouve : Catalog Sources sans bandeau « Unknown error », wizard FTP CSV 5 étapes max (pas d’étape mapping), mapping uniquement dans onglet « Colonnes (CSV) ». |
| B | Si le test échoue, CE corrige (build/deploy) jusqu’à réussite. |
| C | Fournir screenshots et traces réseau/console masquées. |

---

## 2. Livrables (exécution par CE)

### 2.1 Projet Playwright (keybuzz-infra)

| Fichier | Rôle |
|---------|------|
| `e2e/package.json` | Dépendance `@playwright/test`. |
| `e2e/playwright.config.ts` | Config baseURL seller-dev, trace/screenshot/video. |
| `e2e/seller-dev-catalog-sources.spec.ts` | 3 tests : (1) Catalog Sources pas « Unknown error » (avec session), (2) Wizard 5 étapes + pas « Mapping des colonnes » (avec session), (3) Sans session : pas « Unknown error » dans le HTML initial. |
| `e2e/global-setup.ts` | Helper masquage (optionnel). |

### 2.2 Workflow CI

**Fichier :** `.github/workflows/ph-s035e-playwright-proof.yml`

- **Déclenchement :** `workflow_dispatch` ou push sur `e2e/**` ou ce workflow.
- **Steps :** checkout → Setup Node → Install e2e deps + Playwright Chromium → Run Playwright (env `SELLER_DEV_COOKIES` depuis secret, jamais affiché).
- **Artifacts :** `ph-s035e-playwright-proof` contenant :
  - `catalog-sources-page.png` (screenshot page Catalog Sources si test avec session),
  - `wizard-stepper.png` (screenshot stepper wizard),
  - `playwright-log-masked.txt` (sortie Playwright avec tokens/cookies masqués),
  - `playwright-report/` (rapport HTML),
  - `version.txt` (RUN_ID, RUN_URL, BUILD_SHA_PROVEN).

### 2.3 Session authentifiée (sans action Ludovic)

- **Secret `SELLER_DEV_COOKIES` :** tableau JSON de cookies pour `.keybuzz.io` (ex. session NextAuth).  
  Exemple de format (à ne jamais committer) :  
  `[{"name":"next-auth.session-token","value":"***","domain":".keybuzz.io","path":"/"}]`  
  La valeur n’est jamais loguée ; le workflow utilise uniquement le secret.
- **Sans secret :** les tests « avec session » sont skippés (redirect login) ; le test « Without session » s’exécute et vérifie l’absence de « Unknown error » dans le HTML initial.

---

## 3. Lien workflow run

Après exécution du workflow :

- **Run URL :**  
  `https://github.com/keybuzzio/keybuzz-infra/actions/runs/<RUN_ID>`
- **Artifacts :** télécharger `ph-s035e-playwright-proof` depuis la page du run.

*(Remplacer `<RUN_ID>` par l’ID réel du run ; il est aussi dans `proof-artifacts/version.txt`.)*

---

## 4. Artifacts : screenshots + logs (masqués)

| Artifact | Contenu |
|----------|--------|
| `catalog-sources-page.png` | Capture de la page Catalog Sources (si session valide). |
| `wizard-stepper.png` | Capture du stepper du wizard (étape X sur 5). |
| `playwright-log-masked.txt` | Sortie console Playwright ; chaînes type token/cookie/session/Bearer remplacées par `***MASKED***`. |
| `playwright-report/` | Rapport HTML Playwright (traces, screenshots sur échec). |
| `version.txt` | RUN_ID, RUN_URL, BUILD_SHA_PROVEN (référence image déployée). |

---

## 5. Version seller-client (BUILD_SHA) prouvée

- **Source :** image déployée dans `k8s/keybuzz-seller-dev/deployment-client.yaml` (tag ou digest).
- **Preuve :** après déploiement PH-S03.5D / PH-S03.5C, l’image contient `BUILD_SHA` (footer « build xxxxxxx »). Le rapport Playwright atteste le comportement de la version servie au moment du run.
- **Dans l’artifact :** `version.txt` indique « BUILD_SHA_PROVEN=see deployment-client.yaml image tag » ; pour une preuve explicite, vérifier le footer sur une capture ou le tag d’image dans le manifest.

---

## 6. Résultat PASS / FAIL

- **PASS :** les 3 tests passent (ou 2 skippés + 1 passé si pas de cookie) : pas de « Unknown error » dans le DOM/HTML, wizard à 5 étapes, pas de « Mapping des colonnes » dans le wizard.
- **FAIL :** au moins un test échoue. Voir section 7 (corrections).

---

## 7. Corrections appliquées si FAIL

Si Playwright prouve que le bug est encore présent :

1. **« Unknown error » encore affiché :**
   - Identifier la requête JS en erreur (network dans le rapport Playwright ou trace).
   - Vérifier que seller-client déployé contient les correctifs PH-S03.5B (dégradation 400/404, `getDisplayErrorMessage`). Si l’image n’est pas à jour : rebuild + push image (tag/digest) + mise à jour GitOps + resync ArgoCD.

2. **Wizard à 6 étapes ou « Mapping des colonnes » présent :**
   - Vérifier que le bundle déployé contient PH-S03.4 (totalSteps = 5, getStepTitle étape 5 = « Finalisation »). Si l’image est ancienne : rebuild + push + mise à jour `deployment-client.yaml` + déploiement GitOps.

3. **Rejouer Playwright** après déploiement jusqu’à PASS.

---

## 8. Exécution locale (optionnel)

Sur une machine avec Node et accès à seller-dev :

```bash
cd keybuzz-infra/e2e
npm install
npx playwright install chromium
export SELLER_DEV_COOKIES='[{"name":"...","value":"...","domain":".keybuzz.io","path":"/"}]'  # optionnel
npx playwright test
```

---

## 9. Stop conditions / alternative

- **Si Playwright ne peut pas s’exécuter en CI (ex. Chromium install échoue, timeout réseau) :** documenter le diagnostic (étape en échec, message d’erreur) dans ce rapport et proposer une alternative automatisée équivalente (ex. script sur install-v3 avec Playwright, ou renforcement des preuves curl/HTML + vérification du bundle déployé). Aucune demande du type « Ludovic doit tester ».
- **Si l’auth SSO est impossible en CI sans secret :** les tests avec session sont skippés ; le test « Without session » reste exécuté. Pour une preuve complète avec session, configurer une fois le secret `SELLER_DEV_COOKIES` (génération du cookie en dehors de la CI, sans exposer la valeur).
