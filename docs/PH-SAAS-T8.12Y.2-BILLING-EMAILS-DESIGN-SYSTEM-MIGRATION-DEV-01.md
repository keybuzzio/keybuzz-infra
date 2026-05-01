# PH-SAAS-T8.12Y.2 — Billing Emails Design System Migration (DEV)

> Date : 2026-05-02
> Type : Migration email billing transactionnelle contrôlée
> Environnement : DEV uniquement
> Statut : **BILLING EMAILS MIGRATED — DESIGN SYSTEM UNIFIED**

---

## 0. PREFLIGHT

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `956da28d` | Non | OK |
| `keybuzz-infra` | `main` | `main` | `9d20292` | 1 doc non lié | OK |

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | `v3.5.131-email-preview-transactional-dev` | `v3.5.131-email-preview-transactional-dev` | OK |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | `v3.5.130-platform-aware-refund-strategy-prod` | OK |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | OK |

---

## 1. AUDIT BILLING EMAILS

| Email | Trigger | Fonction | Ligne | Subject | Destinataire | Migré | Risque |
|---|---|---|---|---|---|---|---|
| Trial ending | Webhook `customer.subscription.trial_will_end` | `billingEmailHtml()` | 831 | `⏰ KeyBuzz - Votre essai gratuit se termine bientôt` | Owner | **Oui** | Faible |
| Payment failed | Webhook `invoice.payment_failed` | `billingEmailHtml()` | 870 | `ℹ️ KeyBuzz - Information sur votre abonnement` | Owner | **Oui** | Faible |
| Welcome | Checkout `session.mode === 'subscription'` | `billingEmailHtml()` | 1594 | `✨ Bienvenue sur KeyBuzz — Votre abonnement est actif !` | Owner | **Oui** | Faible |

Fonction `billingEmailHtml()` : wrapper HTML inline avec gradient header violet, logo 192px, pas de text/plain, pas de preheader, pas de responsive mobile, pas de MSO compat.

---

## 2. PATCH MINIMAL

| Email | Template cible | Champs requis | Changement source |
|---|---|---|---|
| Trial ending | `billingEmailTemplate()` | title, bodyHtml, ctaUrl, ctaLabel | Import + replace |
| Payment failed | `billingEmailTemplate()` | title, bodyHtml, ctaUrl, ctaLabel | Import + replace |
| Welcome | `billingEmailTemplate()` | title, bodyHtml, ctaUrl, ctaLabel | Import + replace |

### Détail du patch

1. Ajout `import { billingEmailTemplate } from '../../services/emailTemplates';`
2. Suppression de la fonction locale `billingEmailHtml()` (1462 chars)
3. Remplacement des 3 blocs `html: billingEmailHtml(...)` par :
   - `const xxxEmailData = billingEmailTemplate(title, body, ctaUrl, ctaLabel);`
   - `html: xxxEmailData.html, text: xxxEmailData.text`
4. Subjects, emojis, From, try/catch, logging : **inchangés**
5. Triggers Stripe webhook / checkout : **inchangés**
6. DB queries : **inchangées**
7. `emitConversionWebhook` : **inchangé**

---

## 3. FICHIERS MODIFIÉS

| Fichier | Action | Commit |
|---|---|---|
| `keybuzz-api/src/modules/billing/routes.ts` | Migration 3 emails + suppression billingEmailHtml | `1a87a1c7` |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image tag v3.5.132 | `c450142` |

---

## 4. VALIDATION STATIQUE

| Check | Attendu | Résultat |
|---|---|---|
| `tsc --noEmit` | 0 erreur | **OK** |
| Pas de secret | 0 | **OK** |
| Pas de tracking pixel | 0 | **OK** |
| Billing triggers inchangés | Oui | **OK** |
| Stripe webhook logic inchangée | Oui | **OK** |
| `billingEmailHtml()` calls restants | 0 | **OK** (1 mention commentaire) |

---

## 5. PREVIEW VALIDATION

| Template | HTML OK | Text OK | Mobile-safe | Secret-free |
|---|---|---|---|---|
| `billing-welcome` | **OK** | **OK** | **OK** (responsive) | **OK** |
| `billing-trial-ending` | **OK** | **OK** | **OK** | **OK** |
| `billing-payment-failed` | **OK** | **OK** | **OK** | **OK** |

---

## 6. BUILD DEV API

| Élément | Valeur |
|---|---|
| Tag | `v3.5.132-billing-email-design-dev` |
| Digest | `sha256:f9dc5abac983bc6c7a4940fc14f942d55cc0b5235dcfebf422a7b0cc9ff0c5f4` |
| Source commit | `1a87a1c7` |
| Clone | depth=1 clean clone |
| `tsc` build | 0 erreur |

---

## 7. GITOPS DEV

| Élément | Valeur |
|---|---|
| Image précédente | `v3.5.131-email-preview-transactional-dev` |
| Image nouvelle | `v3.5.132-billing-email-design-dev` |
| Digest | `sha256:f9dc5abac983bc6c7a4940fc14f942d55cc0b5235dcfebf422a7b0cc9ff0c5f4` |
| Commit API | `1a87a1c7` (branch `ph147.4/source-of-truth`) |
| Commit infra | `c450142` (branch `main`) |
| Apply | `kubectl apply -f` — rollout successful |
| Runtime = manifest | **Oui** |

---

## 8. RUNTIME VALIDATION

| Test | Attendu | Résultat |
|---|---|---|
| API health | OK | **OK** |
| Preview index | 12 templates | **OK** |
| Billing welcome HTML | Design system responsive | **OK** |
| Billing welcome text | Version texte | **OK** |
| Billing trial-ending HTML | Design system responsive | **OK** |
| Billing payment-failed HTML | Design system responsive | **OK** |
| Invite preview | Toujours fonctionnel | **OK** |
| Trial J0 preview | Toujours fonctionnel | **OK** |
| Secrets check | 0 | **OK** |
| Logs erreurs | 0 | **OK** |

---

## 9. NON-RÉGRESSION

| Surface | Attendu | Résultat |
|---|---|---|
| API DEV health | OK | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | **OK** — inchangé |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | **OK** — inchangé |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | **OK** — inchangé |
| Billing DB | Aucune mutation | **OK** |
| Stripe | Aucune mutation | **OK** |
| CAPI | Aucune mutation | **OK** |
| Tracking | Aucune mutation | **OK** |
| CronJobs | 3 inchangés | **OK** |

---

## 10. ROLLBACK GITOPS STRICT

1. Modifier `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` :
   remplacer l'image par `ghcr.io/keybuzzio/keybuzz-api:v3.5.131-email-preview-transactional-dev`
2. Commit infra
3. Push `main`
4. `kubectl apply -f keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`
5. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev`
6. Vérifier manifest = runtime = annotation

**Interdit** : `kubectl set image`, `kubectl patch`, `kubectl edit`.

---

## 11. GAPS

| Gap | Sévérité | Action |
|---|---|---|
| OTP Client | Faible | Phase Client séparée |
| Contact form email | Minimal | Faible valeur, interne |
| Lifecycle scheduling | Moyen | Table SQL + CronJob + endpoint |
| List-Unsubscribe | Élevé avant lifecycle | Header obligatoire |
| `email_opt_out` flag | Moyen | Colonne tenant_metadata |
| SPF/DKIM/DMARC | Moyen | Vérification DNS hors scope |
| PROD promotion | Moyen | Phase dédiée après validation DEV |

---

## 12. PROD INCHANGÉE

- API PROD : `v3.5.130-platform-aware-refund-strategy-prod` — **INTACT**
- Client PROD : `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` — **INTACT**
- Admin PROD : `v2.11.37-acquisition-baseline-truth-prod` — **INTACT**

---

## 13. BILAN EMAIL DESIGN SYSTEM (Y + Y.1 + Y.2)

| Email | Service | Migré | Phase |
|---|---|---|---|
| OTP | Client | Non | Hors scope (Client) |
| Invitation espace | API | **Oui** | Y.1 |
| Billing welcome | API | **Oui** | Y.2 |
| Billing trial ending | API | **Oui** | Y.2 |
| Billing payment failed | API | **Oui** | Y.2 |
| Contact form | API | Non | Faible valeur |
| Debug email test | API | Non | Debug tool |
| Agent replies | API | Non | Hors scope (outbound worker) |
| Trial lifecycle (7) | — | Templates prêts | Non activés |

**4/8 emails API migrés vers le design system unifié.**

---

## VERDICT

**BILLING EMAILS MIGRATED TO DESIGN SYSTEM IN DEV — STRIPE/BILLING LOGIC UNCHANGED — PREVIEW VALIDATED — NO REAL EMAIL SENT — NO TRACKING/BILLING/CAPI DRIFT — PROD UNCHANGED**
