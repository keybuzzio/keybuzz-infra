# PH148-PROD-PROMOTION-ONBOARDING-ACTIVATION-FLOW-01

> Promotion contrôlée du nouveau flow onboarding activation vers PROD
> Date : 13 avril 2026

---

## IMAGES


| Service      | Avant                                     | Après                                                             |
| ------------ | ----------------------------------------- | ----------------------------------------------------------------- |
| Client DEV   | `v3.5.60-ph148-onboarding-activation-dev` | `v3.5.60-ph148-onboarding-activation-dev` (rebuild avec fix hook) |
| Client PROD  | `v3.5.258-ph146.4-billing-addons-prod`    | `v3.5.60-ph148-onboarding-activation-prod`                        |
| API PROD     | `v3.5.53-ph147.3-encoding-cleanup-prod`   | inchangé                                                          |
| Backend PROD | `v1.0.43-ph145.6-amazon-prod`             | inchangé                                                          |


---

## DIFF MINIMAL

**2 fichiers** (scope onboarding uniquement) :


| Fichier                                                | Action  | Lignes |
| ------------------------------------------------------ | ------- | ------ |
| `src/features/onboarding/hooks/useOnboardingState.ts`  | CRÉÉ    | 107    |
| `src/features/onboarding/components/OnboardingHub.tsx` | RÉÉCRIT | 264    |


**0 fichier hors scope. 0 fichier Studio. 0 modification API/Backend.**

---

## ROLLBACK

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.258-ph146.4-billing-addons-prod \
  -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## ROLLOUT

1. Build PROD initial : `v3.5.60-ph148-onboarding-activation-prod` (SHA: `ea4650858e...`)
2. Déploiement : `kubectl set image` → rollout success
3. Validation technique : pod Running 1/1, API health OK, 0 erreur logs
4. Bug détecté : hook utilisait `totalConversations` au lieu de `conversations.total`
5. Fix appliqué : `useOnboardingState.ts` corrigé pour le format API réel
6. Rebuild DEV + PROD : même tag, nouvelle image (SHA: `356b692e4e...`)
7. Rollout restart : nouveaux pods DEV + PROD créés avec le fix

---

## VALIDATION PRODUIT RÉELLE

### Compte : [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com) (eComLG, PROD)


| Test                                              | Résultat                                                 |
| ------------------------------------------------- | -------------------------------------------------------- |
| `/start` — Hero visible                           | ✅ "Bienvenue sur KeyBuzz"                                |
| `/start` — Stepper 4 étapes                       | ✅ Connecter ✅ → Messages ✅ → Répondre ✅ → Automatiser 🔵 |
| `/start` — Plus de checklist legacy               | ✅ Totalement supprimée                                   |
| `/start` — CAS 4 correct (465 conv, 437 résolues) | ✅ "Automatiser vos réponses ?"                           |
| CTA "Continuer manuellement" → inbox              | ✅ Redirect /inbox avec 465 conversations                 |
| CTA "Gérer mes canaux" → channels                 | ✅ 5 Amazon connectés                                     |
| Retour `/start` → état recalculé                  | ✅ CAS 4 maintenu                                         |
| Badge canal "✅ Amazon"                            | ✅ Affiché en bas de page                                 |


### Logique dynamique confirmée

```
hasChannel = true  (Amazon PROD connecté)
hasMessages = true (465 conversations)
hasReplied = true  (437 résolues + 7 ouvertes)
currentStep = 4    → CAS 4 "Automatiser"
```

Format API dashboard summary PROD vérifié :

```json
{ "conversations": { "total": 464, "open": 6, "resolved": 437 } }
```

---

## NON-RÉGRESSION

### Navigation réelle PROD (client.keybuzz.io)


| Page         | Statut | Détails                                         |
| ------------ | ------ | ----------------------------------------------- |
| `/start`     | ✅      | Nouveau flow dynamique CAS 4                    |
| `/inbox`     | ✅      | 465 conversations, suggestions IA actives       |
| `/channels`  | ✅      | 5 Amazon (BE, ES, FR, IT, PL) connectés         |
| `/dashboard` | ✅      | 465 conv, 7 ouvertes, 96% SLA, activité récente |
| `/billing`   | ✅      | (vérifié DEV, même codebase)                    |


### Pods K8s PROD


| Pod             | Status      | Image                                              |
| --------------- | ----------- | -------------------------------------------------- |
| keybuzz-client  | Running 1/1 | `v3.5.60-ph148-onboarding-activation-prod`         |
| keybuzz-api     | Running 1/1 | `v3.5.53-ph147.3-encoding-cleanup-prod` (inchangé) |
| keybuzz-backend | Running 1/1 | `v1.0.43-ph145.6-amazon-prod` (inchangé)           |


### API Health PROD

```json
{"status":"ok","timestamp":"2026-04-13T14:40:41.254Z","service":"keybuzz-api","version":"1.0.0"}
```

### Logs PROD

- Client : 0 erreur
- API : 0 erreur

---

## ANTI-CONTAMINATION

- ✅ 0 fichier Studio
- ✅ 0 changement hors scope onboarding
- ✅ API PROD inchangée
- ✅ Backend PROD inchangé
- ✅ Amazon connecteurs non touchés
- ✅ Billing non touché
- ✅ Agents non touchés
- ✅ Autopilot non touché
- ✅ 0 régression détectée

---

## GITOPS


| Manifest                                  | Image                                      |
| ----------------------------------------- | ------------------------------------------ |
| `k8s/keybuzz-client-dev/deployment.yaml`  | `v3.5.60-ph148-onboarding-activation-dev`  |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.60-ph148-onboarding-activation-prod` |


---

## VERDICT

### ONBOARDING ACTIVATION FLOW PROMOTED TO PROD

