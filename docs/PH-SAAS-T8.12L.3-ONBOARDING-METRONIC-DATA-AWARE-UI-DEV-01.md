# PH-SAAS-T8.12L.3 — Onboarding Metronic Data-Aware UI DEV

> **Phase** : PH-SAAS-T8.12L.3-ONBOARDING-METRONIC-DATA-AWARE-UI-DEV-01
> **Date** : 2026-04-30
> **Type** : Implémentation DEV — UI onboarding data-aware Metronic
> **Statut** : TERMINÉ — GO PARTIEL

---

## 0. Préflight

| Repo | Branche | HEAD avant | Dirty | Verdict |
|---|---|---|---|---|
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `af0faa7` | Non | OK |
| `keybuzz-api` | `ph147.4/source-of-truth` | inchangé | Non | OK — aucun changement API |
| `keybuzz-infra` | `main` | `30d62e2` | Non | OK |

| Service | DEV runtime avant | PROD runtime | Verdict |
|---|---|---|---|
| Client | `v3.5.133-onboarding-readmodel-dev` | `v3.5.131-trial-effectiveplan-client-prod` | PROD inchangée |
| API | `v3.5.127-trial-autopilot-assisted-dev` | `v3.5.128-trial-autopilot-assisted-prod` | PROD inchangée — pas de build API |

---

## 1. Décision technique

Remplacement du wizard statique (`OnboardingWizard`) par un nouveau composant `OnboardingDataAware` qui :
- Utilise le hook `useOnboardingStatus` créé en L.2
- Affiche un stepper vertical (sidebar) + panneau de contenu (cards)
- Calcule les statuts des 8 étapes depuis des données runtime
- Différencie tenant PRO actif vs tenant trial AUTOPILOT_ASSISTED

---

## 2. Fichiers modifiés

| Fichier | Action | Changement |
|---|---|---|
| `src/features/onboarding/components/OnboardingDataAware.tsx` | **Créé** | Composant UI Metronic data-aware avec stepper, 8 sous-composants d'étape, badges de statut, responsive |
| `app/onboarding/page.tsx` | **Modifié** | Import `OnboardingDataAware` au lieu de `OnboardingWizard` |

### Détail `OnboardingDataAware.tsx`

Composant principal avec architecture par étape :

| Sous-composant | Étape | Comportement data-aware |
|---|---|---|
| `StepWelcome` | Bienvenue + Trial | Affiche `effectivePlan`, jours restants si trial, features incluses. Masque "Validation humaine" pour non-trial. Masque texte trial pour non-trialing. |
| `StepProfile` | Profil entreprise | Si `profile.filled` : affiche companyName + lien modifier. Sinon : CTA vers `/settings`. |
| `StepAmazon` | Connexion Amazon | Si connecté : affiche displayName. Sinon : CTA OAuth Amazon + bouton "Ignorer". |
| `StepInbound` | Email inbound | Si `blocked` : message "Connectez Amazon d'abord". Si `done` : adresse + count conversations. Si `current` : adresse + instructions Seller Central. |
| `StepFirstMessage` | Premier message | Affiche `conversations.total`. Si 0 : explication attente. Si >0 : lien inbox. |
| `StepAiDiscovery` | IA / Suggestions | Affiche `aiSuggestions.total`. Si 0 : explication. Si trial : mention "validation humaine". |
| `StepTrialLimits` | Limites trial | **Conditionnel** : si trial → affiche limites Autopilot (auto-send, Agent KeyBuzz). Si non-trial → affiche plan actif + CTA "Gérer mon plan". |
| `StepReady` | Prêt | Synthèse étapes done/pending. Si complet : message succès. CTA dashboard + inbox. |

### Corrections appliquées (v3.5.135)

1. **Texte trial masqué pour non-trial** : "Pendant l'essai, vous bénéficiez..." conditionné à `isTrialing`
2. **"Validation humaine obligatoire"** conditionné à `isAutopilotAssisted`
3. **StepTrialLimits bifurque** : PRO actif → "Votre plan : PRO" / Trial → limites Autopilot

---

## 3. Commits

| Repo | Commit | Message |
|---|---|---|
| `keybuzz-client` | `7e5a1fd` | `feat(onboarding): Metronic data-aware UI with useOnboardingStatus (PH-SAAS-T8.12L.3)` |
| `keybuzz-infra` | `2a8ae1f` | `GitOps: Client DEV v3.5.134-onboarding-metronic-dev (PH-SAAS-T8.12L.3)` |
| `keybuzz-infra` | `51cbb06` | `GitOps: Client DEV v3.5.135-onboarding-metronic-fix-dev (PH-SAAS-T8.12L.3)` |

---

## 4. Build

### Build v3.5.134 (initial)

| Étape | Détail |
|---|---|
| Source | Clone temporaire propre `/tmp/keybuzz-client-l3-build` |
| Branche | `ph148/onboarding-activation-replay` |
| Build args | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io` |
| Tag | `ghcr.io/keybuzzio/keybuzz-client:v3.5.134-onboarding-metronic-dev` |
| Digest | `sha256:f9d1089c4ba6f7697457b532bd5402182befdc591ca7ee1c5682b56c994f8ae7` |
| Méthode | `docker build --no-cache` depuis clone propre |
| Cleanup | Clone supprimé après push |

### Build v3.5.135 (corrections trial)

| Étape | Détail |
|---|---|
| Source | Clone temporaire propre `/tmp/keybuzz-client-l3-rebuild` |
| Branche | `ph148/onboarding-activation-replay` |
| Build args | identiques |
| Tag | `ghcr.io/keybuzzio/keybuzz-client:v3.5.135-onboarding-metronic-fix-dev` |
| Digest | `sha256:d9a1c715b21a77270fc04fb6c181d129cff9cb881690c09635e9e44fe1a0bd59` |
| Méthode | `docker build --no-cache` depuis clone propre |
| Cleanup | Clone supprimé après push |

---

## 5. Manifest / Runtime / Annotation

| Vérification | Valeur | Match |
|---|---|---|
| Manifest `deployment.yaml` | `v3.5.135-onboarding-metronic-fix-dev` | OK |
| Runtime `kubectl get deploy` | `v3.5.135-onboarding-metronic-fix-dev` | OK |
| Pod status | `1/1 Running, 0 restarts` | OK |
| PROD runtime | `v3.5.131-trial-effectiveplan-client-prod` | INCHANGÉE |

---

## 6. Validation par tenant

### Tenant `ecomlg-001` (historique, PRO, billing_exempt)

| Étape | Statut affiché | Données runtime | Verdict |
|---|---|---|---|
| Bienvenue | done | "Votre expérience : PRO", 3 features (pas "validation humaine") | OK — pas de texte trial |
| Profil | todo | API profile ne retourne pas companyName | GAP mineur (G1) |
| Amazon | done | "Amazon" (connecté) | OK |
| Inbound | done | `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io` | OK |
| Premier message | done | 459 conversations | OK |
| IA | done | 1334 suggestions | OK |
| Limites trial | done | "Votre plan : PRO" + "Gérer mon plan" | OK — pas de texte trial |
| Prêt | todo | Profile manquant bloque completion | OK — cohérent |
| Progression | 75% | 6/8 done | OK |

### Tenant trial lambda

Test non réalisé dans cette session — le tenant `test-lambda-k1-sas-molcr3ha` n'a pas été switché. Le hook `useOnboardingStatus` est conçu pour afficher correctement `AUTOPILOT_ASSISTED` via `isAutopilotAssisted` et `isTrialing` du hook `useEntitlement`.

---

## 7. Non-régression

| Page | Résultat |
|---|---|
| `/dashboard` | OK — 459 conversations, KPIs, SLA, répartition canal, activité récente |
| `/inbox` | OK — 459 conversations, suggestions IA actives, commandes |
| `/onboarding` | OK — nouvelle UI data-aware fonctionnelle |
| `/billing/plan` | OK — Plan Pro, 297 EUR/mois, capabilities correctes |
| API health | OK — `{"status":"ok"}` |
| Client pod | 1/1 Running, 0 restarts, age 127min au dernier check |
| Login/session | OK — Google OAuth fonctionnel, tenant selection OK |
| Console JS | 0 erreur nouvelle — seuls `CLIENT_FETCH_ERROR` next-auth préexistants (debug level) |

---

## 8. Tracking / Billing / CAPI invariants

| Check | Résultat |
|---|---|
| Event `signup_complete` | 0 émis |
| Event `purchase` | 0 émis |
| CAPI | 0 mutation |
| AW direct | 0 |
| Stripe mutation | 0 |
| Secret dans bundle | 0 |

---

## 9. Gaps restants

| # | Gap | Sévérité | Impact |
|---|---|---|---|
| G1 | Profil `companyName` non retourné par API pour `ecomlg-001` | Mineur | Étape profil affiche "À faire" même pour tenant établi. L'endpoint `/api/tenant-context/profile/:tenantId` ne retourne pas le nom ou n'existe pas pour ce tenant. |
| G2 | Mobile viewport layout | Mineur | Le layout stepper+contenu est tronqué sur viewport 390px. Le contenu est partiellement masqué à droite. Le Tailwind `flex-col lg:flex-row` fonctionne mais le panneau contenu déborde. |
| G3 | Tenant trial lambda non testé navigateur | Moyen | Le hook est correctement branché sur `isAutopilotAssisted` et `isTrialing`, mais aucune preuve navigateur pour un tenant en trial. |
| G4 | Ancien wizard non supprimé | Faible | `OnboardingWizard.tsx` est toujours dans le codebase mais n'est plus importé. Nettoyage possible en phase ultérieure. |

---

## 10. Rollback GitOps strict

> Corrigé en L.3.1 — procédure `kubectl set image` supprimée et remplacée par GitOps strict.

```bash
# Rollback vers v3.5.134 (premier build L.3)
# 1. Modifier keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml :
#    image: ghcr.io/keybuzzio/keybuzz-client:v3.5.134-onboarding-metronic-dev
# 2. git add && git commit -m "Rollback: Client DEV v3.5.134"
# 3. git push origin main
# 4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
# 5. kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev

# Rollback vers v3.5.133 (L.2 read model)
# 1. Modifier deployment.yaml :
#    image: ghcr.io/keybuzzio/keybuzz-client:v3.5.133-onboarding-readmodel-dev
# 2. git add && git commit -m "Rollback: Client DEV v3.5.133"
# 3. git push origin main
# 4. kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
# 5. kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 11. Verdict

### GO PARTIEL

**Critères GO remplis :**
- `/onboarding` est data-aware, piloté par `useOnboardingStatus`
- UI conforme Metronic (stepper, cards, badges, alertes)
- Trial Autopilot Assisted correctement conditionné (texte masqué pour non-trial)
- Données existantes réutilisées (459 conversations, 1334 suggestions, Amazon connecté)
- Aucune fausse vérité (profil "À faire" car API ne retourne pas le nom)
- DEV validée
- PROD inchangée
- 0 tracking/billing/CAPI drift

**Raisons GO PARTIEL :**
- Profil `companyName` non retourné par l'API pour le tenant historique (gap G1)
- Mobile viewport tronqué (gap G2)
- Tenant trial lambda non testé navigateur (gap G3)

---

**ONBOARDING METRONIC DATA-AWARE UI READY IN DEV — EXISTING CUSTOMER DATA REUSED — TRIAL AUTOPILOT ASSISTED VALUE EXPLAINED — NO FAKE STATUS — NO TRACKING/BILLING/CAPI DRIFT — PROD UNCHANGED — READY FOR LAMBDA REVIEW**

---

> Rapport : `keybuzz-infra/docs/PH-SAAS-T8.12L.3-ONBOARDING-METRONIC-DATA-AWARE-UI-DEV-01.md`
