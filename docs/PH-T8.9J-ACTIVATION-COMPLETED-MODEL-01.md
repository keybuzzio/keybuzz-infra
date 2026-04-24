# PH-T8.9J — Activation Completed Model — DEV

> **Date** : 2026-05-01
> **Environnement** : DEV uniquement
> **Type** : Modélisation + implémentation event dérivé `activation_completed`
> **Priorité** : P0
> **Statut** : READY IN DEV

---

## Objectif

Définir et implémenter le modèle canonique de l'event interne `activation_completed`, 16e step du funnel CRO produit. Cet event dérivé marque le moment où un tenant a effectivement activé le produit : marketplace connectée + premier flux de conversation réel.

---

## Sources de vérité

| Document | Phase |
|---|---|
| `keybuzz-infra/docs/PH-T8.9G-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-01.md` | Foundation post-checkout DEV |
| `keybuzz-infra/docs/PH-T8.9I-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-PROD-PROMOTION-01.md` | Promotion PROD |
| `keybuzz-infra/docs/PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01.md` | Audit read-only |

---

## ÉTAPE 0 — Préflight

| Point | Valeur |
|---|---|
| Branche API | `ph147.4/source-of-truth` |
| HEAD API | `d004d45e` → `c0b0f195` (après commit) |
| Image API DEV (avant) | `v3.5.110-post-checkout-activation-foundation-dev` |
| Image API PROD | `v3.5.110-post-checkout-activation-foundation-prod` (inchangée) |
| Repo clean | Oui |
| PROD inchangée | Confirmé |

---

## ÉTAPE 1 — Comparaison des modèles

| Modèle | Définition | Avantages | Risques | Verdict |
|---|---|---|---|---|
| **A** | `marketplace_connected` AND `first_conversation_received` | Signal minimal de première utilisation réelle : produit branché + premier flux client | Ne garantit pas que l'agent a répondu | **RETENU** |
| **B** | A + `first_response_sent` | Signal fort : agent a effectivement répondu | Trop strict pour cette phase, délai potentiel de jours | Réservé downstream |
| **C** | `dashboard_first_viewed` ou `onboarding_started` | Signal précoce | Trop faible : n'importe quel login passe par le dashboard | Rejeté |

### Modèle retenu : A

**Justification :**
- `marketplace_connected` prouve que la marketplace est réellement connectée
- `first_conversation_received` prouve qu'un premier flux de données client existe
- Les deux events sont émis au même moment dans `inbound/routes.ts` (L132-133, L422-423), ce qui est correct : la première conversation entrante prouve à la fois la connexion et le premier flux

---

## ÉTAPE 2 — Stratégie technique

| Point | Décision |
|---|---|
| Propriétaire | API (`emitActivationEvent`) |
| Type | Event dérivé — auto-émis quand les 2 prérequis sont vrais |
| Helper | `tryEmitActivationCompleted()` appelé depuis `emitActivationEvent()` |
| Trigger | Après chaque INSERT de `marketplace_connected` ou `first_conversation_received` |
| Source funnel_id | Résolu canoniquement (earliest funnel_id du tenant, fallback tenantId) |
| Idempotence | `ON CONFLICT (funnel_id, event_name) DO NOTHING` |
| Properties | `{"model":"A","prerequisites":["marketplace_connected","first_conversation_received"]}` |
| Migration DB | Aucune nécessaire |
| Modification client | Aucune |
| Modification Admin | Aucune |

### Logique bidirectionnelle

```
emitActivationEvent('marketplace_connected')
  → INSERT marketplace_connected
  → tryEmitActivationCompleted() → CHECK if both exist → INSERT activation_completed if yes

emitActivationEvent('first_conversation_received')
  → INSERT first_conversation_received
  → tryEmitActivationCompleted() → CHECK if both exist → INSERT activation_completed if yes
```

---

## ÉTAPE 3 — Implémentation

### Fichier modifié

**`src/modules/funnel/routes.ts`** — seul fichier modifié, +32 lignes.

### Patch appliqué

1. **ALLOWED_EVENTS** : ajout de `'activation_completed'` en position 16 (après `first_response_sent`)
2. **`emitActivationEvent()`** : ajout d'un appel à `tryEmitActivationCompleted()` après l'INSERT, si l'event est `marketplace_connected` ou `first_conversation_received`
3. **`tryEmitActivationCompleted()`** : nouvelle fonction qui vérifie si les 2 prérequis existent pour le tenant, et si oui, émet `activation_completed` idempotently

### Commit

| Point | Valeur |
|---|---|
| Commit | `c0b0f195` |
| Message | `PH-T8.9J: activation_completed derived event — Model A` |
| Branche | `ph147.4/source-of-truth` |
| Push | `d004d45e..c0b0f195 ph147.4/source-of-truth` |

---

## ÉTAPE 4 — Backfill DEV

**Aucun backfill nécessaire.** La DB DEV avait 13 events mais aucun `marketplace_connected` ni `first_conversation_received` — donc 0 tenants éligibles.

---

## ÉTAPE 5 — Validation DEV

| Cas | Attendu | Résultat |
|---|---|---|
| **A** — marketplace puis conversation | `activation_completed` créé 1 fois | **PASS** |
| **B** — conversation puis marketplace | `activation_completed` créé 1 fois | **PASS** |
| **C** — Doublons (idempotence) | Re-insert SKIPPED, total = 1 | **PASS** |
| **D** — Tenant incomplet | 0 `activation_completed` | **PASS** |
| **E** — Non-régression funnel | 16 steps, `activation_completed` en position 16 | **PASS** |
| **F** — Non-régression business | 0 dans `conversion_events`, `signup_attribution` intact | **PASS** |

### 16 steps canoniques (DEV)

```
 1. register_started
 2. plan_selected
 3. email_submitted
 4. otp_verified
 5. oauth_started
 6. company_completed
 7. user_completed
 8. tenant_created
 9. checkout_started
10. success_viewed
11. dashboard_first_viewed
12. onboarding_started
13. marketplace_connected
14. first_conversation_received
15. first_response_sent
16. activation_completed        ← NEW (derived)
```

---

## ÉTAPE 6 — Preuves DB / SQL

| Preuve | Résultat |
|---|---|
| Idempotence | INSERT 1 = INSERTED, INSERT 2 = SKIPPED |
| Tenant incomplet | 1 prérequis → 0 `activation_completed` |
| `conversion_events` | 0 activation events |
| Données de test | Nettoyées après validation |

---

## ÉTAPE 7 — Build safe DEV

| Point | Valeur |
|---|---|
| Tag | `v3.5.111-activation-completed-model-dev` |
| Digest | `sha256:1d8648a623abb1d74f202cd2bb6071debc5e568e2916f9f0b85501783307621c` |
| Build-from-git | Oui (commit `c0b0f195`) |
| Repo clean | Oui |
| `--no-cache` | Oui |
| GitOps commit | `538bc62` (keybuzz-infra) |
| Rollback DEV | `v3.5.110-post-checkout-activation-foundation-dev` |

---

## ÉTAPE 8 — Non-régression

| Point | Résultat |
|---|---|
| `funnel/metrics` | 16 steps, dernier = `activation_completed` |
| `funnel/events` | 13 events (données réelles DEV) |
| 15 events existants | Tous présents |
| `activation_completed` | 16e step canonique |
| `conversion_events` | 0 (intact) |
| `signup_attribution` | 6 (intact) |
| Client DEV | `v3.5.110` (inchangé) |
| Client PROD | `v3.5.110` (inchangé) |
| Admin DEV | `v2.11.11` (inchangé) |
| Admin PROD | `v2.11.11` (inchangé) |
| API PROD | `v3.5.110` (inchangé) |

---

## ÉTAPE 9 — Gaps restants

| Gap | Description | Phase correctrice |
|---|---|---|
| `billing_events.tenant_id = NULL` | Couture billing → tenant impossible | Future phase billing |
| `OnboardingWizard` | Code mort | Nettoyage technique |
| `OnboardingHub` | Statique | Évolution produit |
| Labels Admin step 16 | `activation_completed` affiché brut | Prochaine phase Admin |
| Modèle A = signal simultané | Les 2 prérequis sont toujours émis ensemble — acceptable pour le MVP | Découplage futur si nécessaire |
| Modèle B non implémenté | `first_response_sent` pas prérequis | Future phase si signal plus profond requis |

---

## Rollback DEV

| Service | Rollback tag |
|---|---|
| API DEV | `v3.5.110-post-checkout-activation-foundation-dev` |

Procédure : modifier `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`, commit, push, pull bastion, `kubectl apply`.

---

## État PROD

**PROD inchangée dans cette phase.**

| Service | Image PROD |
|---|---|
| API | `v3.5.110-post-checkout-activation-foundation-prod` |
| Client | `v3.5.110-post-checkout-activation-foundation-prod` |
| Admin | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` |

---

## Verdict

**ACTIVATION COMPLETED MODEL READY IN DEV — DERIVED ACTIVATION EVENT CANONICALIZED — NO ADS POLLUTION — PROD UNTOUCHED**

---

## Rapport

`keybuzz-infra/docs/PH-T8.9J-ACTIVATION-COMPLETED-MODEL-01.md`
