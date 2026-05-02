# PH-SAAS-T8.12Y.7 — Trial Lifecycle Controlled Send DEV

> **Date** : 2 mai 2026
> **Auteur** : Agent Cursor
> **Verdict** : GO PARTIEL — CONTROLLED LIFECYCLE EMAIL SENT — WAITING LUDOVIC INBOX QA — NO AUTOMATIC EMAILS — PROD UNCHANGED

---

## 1. Preflight

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | `76cd7d9c` (Y.6) | Clean | OK |
| keybuzz-infra | main | main | `6b0eba8` (Y.6 rapport) | Clean | OK |

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | v3.5.136-trial-lifecycle-unsubscribe-dev | Identique | OK |
| API PROD | v3.5.131-transactional-email-design-prod | Identique | OK |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Identique | OK |

---

## 2. Candidats

| Tenant | Owner email | Templates éligibles | Test tenant | Sub status | Retenu |
|---|---|---|---|---|---|
| tenant-1772234265142 | ludovic@ecomlg.fr | trial-welcome, trial-day-2 | Non | trialing | Non |
| **test-lambda-k1-sas-molcr3ha** | switaa26+trialk1@gmail.com | trial-welcome, trial-day-2 | **Oui** | trialing | **Oui** |

Justification : `test-lambda-k1-sas-molcr3ha` est clairement un tenant de test, non exempt, sans billing active, éligible pour `trial-welcome` et `trial-day-2`.

---

## 3. recipientOverride Design

Le owner email du tenant retenu n'étant pas `ludo.gonthier@gmail.com`, un `recipientOverride` a été ajouté.

| Guard | Attendu | Résultat |
|---|---|---|
| DEV-only | Oui | Tick route n'existe pas en PROD (NODE_ENV guard) |
| production rejected | Oui | `validateRecipientOverride()` retourne null si PROD |
| allowlist exact email | Oui | `['ludo.gonthier@gmail.com']` — seule valeur acceptée |
| force required | Oui | 400 si dryRun=false sans force |
| dryRun false required | Oui | Override ignoré en dry-run |
| no tenant mutation | Oui | Owner email inchangé en DB |

Le `targetTenantId` filtre optionnel a aussi été ajouté pour cibler un seul tenant lors de l'envoi contrôlé.

---

## 4. Patch

### Fichiers modifiés (2)

- `src/modules/lifecycle/trial-lifecycle.service.ts` — ajout `recipientOverride`, `targetTenantId`, `validateRecipientOverride()`, `RECIPIENT_OVERRIDE_ALLOWLIST`, `TickOptions`
- `src/modules/lifecycle/trial-lifecycle.routes.ts` — ajout paramètres body `recipientOverride` + `targetTenantId`, validation 400 si override invalide

### Fichiers non modifiés

- `src/app.ts` — inchangé (routes déjà enregistrées en Y.6)
- `src/modules/lifecycle/trial-lifecycle-unsubscribe.ts` — inchangé
- `src/services/emailService.ts` — inchangé
- `src/services/emailTemplates.ts` — inchangé

---

## 5. Validation Statique

| Check | Attendu | Résultat |
|---|---|---|
| tsc --noEmit | 0 erreur | 0 |
| No secrets | 0 | 0 |
| recipientOverride PROD rejected | Oui | 1 (NODE_ENV guard) |
| recipientOverride allowlist | Exact | `['ludo.gonthier@gmail.com']` |
| dryRun default | true | 1 |
| force required | Oui | 4 refs |
| No auto-send | Oui | 0 scheduler |
| No CronJob | Oui | 0 (commentaire = faux positif) |

---

## 6. Build DEV

| Élément | Valeur |
|---|---|
| Source commit | `8a58cf75` feat(lifecycle): recipientOverride DEV-only + targetTenantId for controlled send (PH-SAAS-T8.12Y.7) |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.137-trial-lifecycle-controlled-send-dev` |
| Digest | `sha256:2cd26f95c7ae43629fdfd28f49d3a630b301140d8ec7e0e5a8dfa40c303e1e11` |
| Rollback | `v3.5.136-trial-lifecycle-unsubscribe-dev` |
| Build method | `docker build --no-cache` depuis source propre sur bastion |

---

## 7. GitOps DEV

| Étape | Résultat |
|---|---|
| Manifest mis à jour | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Commit infra | `8c99754` gitops(api-dev): deploy v3.5.137-trial-lifecycle-controlled-send-dev |
| Push | `main → main` |
| kubectl apply | deployment.apps/keybuzz-api configured |
| Rollout status | successfully rolled out |
| Manifest = runtime | ghcr.io/keybuzzio/keybuzz-api:v3.5.137-trial-lifecycle-controlled-send-dev |
| Health | OK |

### Rollback GitOps strict

```bash
# Modifier deployment.yaml : image -> v3.5.136-trial-lifecycle-unsubscribe-dev
# git add + commit + push
# kubectl apply -f keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
# kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 8. Email Contrôlé

**2 emails envoyés à `ludo.gonthier@gmail.com`** via `recipientOverride` sur tenant test `test-lambda-k1-sas-molcr3ha`.

| Tenant | Template | Destinataire final | Message ID | Idempotence row | Verdict |
|---|---|---|---|---|---|
| test-lambda-k1-sas-molcr3ha | trial-welcome | ludo.gonthier@gmail.com | `<ef839581-802c-062b-b85f-09f912ef0f63@keybuzz.io>` | Oui | OK |
| test-lambda-k1-sas-molcr3ha | trial-day-2 | ludo.gonthier@gmail.com | `<2a17af5c-b62c-2fb7-0ad1-0b54bd7ea86d@keybuzz.io>` | Oui | OK |

- `recipientOverride` rejeté pour email non-allowlisté (400 vérifié)
- 0 erreurs
- List-Unsubscribe header présent (buildUnsubscribeUrl)

---

## 9. Idempotence

| Test | Attendu | Résultat |
|---|---|---|
| Duplicate send (second tick) | Bloqué | 0 sent (excluded: already_sent) |
| Rows count | 2 (inchangé) | 2 |
| Provider second call | None | Aucun email envoyé |

---

## 10. Unsubscribe E2E

| Test | Attendu | Résultat |
|---|---|---|
| Unsubscribe first call | opt-out true | "Désinscription confirmée" + optout: true |
| Unsubscribe second call | Idempotent | "Déjà désinscrit" |
| Dry-run after opt-out | Tenant exclu | lifecycle_optout (welcome + day-2) |
| Transactionnels | Non affectés | Health OK |

Opt-out remis à false après test (état clean).

---

## 11. QA Inbox

| Check | Attendu | Résultat |
|---|---|---|
| inbox | Oui | **Waiting Ludovic inbox QA** |
| spam | Non | Waiting |
| subject | Propre | Waiting |
| mobile | OK | Waiting |
| unsubscribe link | Présent | Waiting |

---

## 12. Non-Régression

| Surface | Attendu | Résultat |
|---|---|---|
| API DEV health | OK | OK |
| API PROD | v3.5.131 inchangée | OK |
| Client PROD | v3.5.147 inchangée | OK |
| Website PROD | v0.6.8 inchangée | OK |
| Billing DB | Aucune mutation métier | 0 subs modifiées |
| PROD internal endpoint | 404 | 404 |
| CronJobs lifecycle | Absent | NONE |
| Lifecycle automatic send | Absent | NONE |

---

## 13. Confirmations Explicites

- **Nombre exact d'emails envoyés** : 2 (trial-welcome + trial-day-2)
- **Destinataire final** : `ludo.gonthier@gmail.com` (via recipientOverride)
- **Idempotence confirmée** : Second envoi bloqué (already_sent), 2 rows stables
- **Unsubscribe confirmé** : E2E fonctionnel, opt-out + idempotent + dry-run exclusion
- **Aucun CronJob lifecycle** : Confirmé (0)
- **Aucun email PROD** : Confirmé
- **PROD inchangée** : Confirmé (v3.5.131)
- **dryRun par défaut** : true
- **recipientOverride** : DEV-only, allowlist exacte `['ludo.gonthier@gmail.com']`, PROD rejected
- **Aucune mutation billing/Stripe/CAPI/tracking** : Confirmé

---

## 14. Gaps

1. **QA inbox** : Les 2 emails sont envoyés mais la validation visuelle (inbox/spam/mobile/subject/unsubscribe link) attend Ludovic
2. **PROD unsubscribe** : L'endpoint `/lifecycle/unsubscribe` existe dans le code mais la PROD n'a pas cette image. À promouvoir quand ready.

---

## 15. Phase Suivante Recommandée

**PH-SAAS-T8.12Y.8** — Lifecycle PROD readiness :
1. QA inbox validation par Ludovic
2. Promotion endpoint unsubscribe en PROD
3. Subject prefix cleanup (retirer [DEV TEST])
4. Activation contrôlée du CronJob lifecycle (dry-run PROD d'abord)

---

## 16. Artefacts

| Type | Valeur |
|---|---|
| Rapport | `keybuzz-infra/docs/PH-SAAS-T8.12Y.7-TRIAL-LIFECYCLE-CONTROLLED-SEND-DEV-01.md` |
| Tag DEV | `v3.5.137-trial-lifecycle-controlled-send-dev` |
| Digest | `sha256:2cd26f95c7ae43629fdfd28f49d3a630b301140d8ec7e0e5a8dfa40c303e1e11` |
| Commit API | `8a58cf75` |
| Commit infra GitOps | `8c99754` |
