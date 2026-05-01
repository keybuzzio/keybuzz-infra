# PH-SAAS-T8.12Y.3 — Email Inbox Deliverability & Visual QA DEV

> **Phase** : PH-SAAS-T8.12Y.3-EMAIL-INBOX-DELIVERABILITY-AND-VISUAL-QA-DEV-01
> **Date** : 2026-05-02
> **Environnement** : DEV uniquement
> **Type** : Validation inbox réelle + QA visuelle email
> **Priorité** : P1
> **Code/Build/Deploy** : Aucun

---

## 1. Objectif

Valider que le nouveau design system email, déployé en DEV depuis les phases Y — Y.2, fonctionne en conditions réelles d'envoi email :

1. Envoi réel contrôlé depuis DEV vers une adresse test autorisée
2. Réception inbox/spam vérifiable
3. Rendu réel dans Gmail
4. Subjects + preheaders + CTA + text/plain
5. Absence de fuite secret
6. Aucun impact billing/tracking/CAPI
7. Aucune modification PROD

---

## 2. Preflight

### Repos

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `1a87a1c7` | Non | **OK** |
| `keybuzz-infra` | `main` | `main` | `99527c0` | Non | **OK** |

### Runtimes

| Service | Attendu | Runtime | Manifest = runtime | Verdict |
|---|---|---|---|---|
| API DEV | `v3.5.132-billing-email-design-dev` | `v3.5.132-billing-email-design-dev` | Oui | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | `v3.5.130-platform-aware-refund-strategy-prod` | — | **OK** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | — | **OK** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | Identique | — | **OK** |

---

## 3. Méthode d'envoi DEV

### Audit capacités existantes

| Méthode | Fichier/endpoint | Peut envoyer template design system ? | Risque | Verdict |
|---|---|---|---|---|
| `POST /debug/email/send-test` | `debug/email-test.ts` | **Partiellement** — accepte `to`, `subject`, `body` mais pas `html` | Faible (DEV-only) | Insuffisant pour design system |
| `emailService.sendEmail()` direct | `emailService.ts` | **Oui** via `kubectl exec` dans le pod API | Faible (exécution isolée) | **Utilisé** |
| `GET /debug/email/preview` | `debug/email-preview.ts` | **Non** — preview only | Aucun | Preview uniquement |

### Méthode retenue

Exécution de scripts Node.js via `kubectl exec` dans le pod API DEV (`keybuzz-api-57f5985f86-8mdnb`).
Cette approche :
- Charge directement les modules compilés (`/app/dist/services/emailTemplates.js` + `emailService.js`)
- Utilise le runtime existant sans aucune modification de code
- Envoie via le même pipeline SMTP que les emails réels
- Ne nécessite **aucun build, aucun deploy, aucun code nouveau**

---

## 4. Adresse test

| Champ | Valeur |
|---|---|
| Adresse test | `ludo.gonthier@gmail.com` |
| Source autorisation | Compte owner DEV `ecomlg-001`, propriétaire du produit |
| Type mailbox | Gmail (Google) |
| Risque client réel | **Aucun** — seul utilisateur humain actif du système |
| Verdict | **Autorisé** |

---

## 5. Previews avant envoi

Tous les templates cibles ont été prévisualisés via `GET /debug/email/preview` en DEV.

| Template | HTML preview | Text preview | Secret-free | Verdict |
|---|---|---|---|---|
| `invite` | 3.8KB | 538B | Oui (0 match) | **OK** |
| `billing-welcome` | 3.3KB | 599B | Oui (0 match) | **OK** |
| `billing-trial-ending` | 3.2KB | 538B | Oui (0 match) | **OK** |
| `billing-payment-failed` | 3.3KB | 566B | Oui (0 match) | **OK** |
| `trial-j0` | 4.3KB | 764B | Oui (0 match) | **OK** |
| `trial-j13` | 4.0KB | 701B | Oui (0 match) | **OK** |

Scan effectué : `grep -ciE 'sk_live|sk_test|password|secret|token|apikey|api_key|Bearer'` sur HTML et text de chaque template → **0 match total**.

---

## 6. Envois réels contrôlés DEV

4 emails envoyés via `kubectl exec` + `sendEmail()` dans le pod API DEV.

| Email | Envoyé ? | Message ID | Provider | Statut SMTP | Verdict |
|---|---|---|---|---|---|
| Invitation espace | **Oui** | `<2c36e20c-99f2-dafa-94c1-60357fa84049@keybuzz.io>` | SMTP DEV (`49.13.35.167:25`) | Accepté | **OK** |
| Billing welcome | **Oui** | `<1baddf45-b2e7-73a9-0e24-db3d5e87dd7f@keybuzz.io>` | SMTP DEV (`49.13.35.167:25`) | Accepté | **OK** |
| Billing payment failed | **Oui** | `<c29df5a1-74ac-e7fa-f009-deb89c815941@keybuzz.io>` | SMTP DEV (`49.13.35.167:25`) | Accepté | **OK** |
| Trial J0 | **Oui** | `<cedcba7c-1c61-f2d2-a0f6-c5fe46b399ee@keybuzz.io>` | SMTP DEV (`49.13.35.167:25`) | Accepté | **OK** |

### Conditions respectées

- Destinataire = adresse test autorisée uniquement
- Subjects préfixés avec `[DEV TEST]`
- Aucun trigger Stripe réel
- Aucune mutation DB billing (vérifié : 0 events, 0 subscriptions)
- Aucune lifecycle automation
- Logs SMTP sans secret (uniquement message IDs et metadata d'envoi)
- From : `noreply@keybuzz.io`

---

## 7. QA Inbox / Spam / Rendu

### Statut

**En attente de validation visuelle par Ludovic.**

L'agent n'a pas accès à la boîte Gmail `ludo.gonthier@gmail.com`.

| Email | Inbox/Spam | Subject OK | Preheader OK | Mobile OK | CTA OK | Verdict |
|---|---|---|---|---|---|---|
| Invite | En attente | `[DEV TEST] Invitation...` | — | — | — | **En attente** |
| Billing welcome | En attente | `[DEV TEST] Bienvenue...` | — | — | — | **En attente** |
| Billing payment failed | En attente | `[DEV TEST] Problème...` | — | — | — | **En attente** |
| Trial J0 | En attente | `[DEV TEST] Bienvenue...` | — | — | — | **En attente** |

### Action requise

Ludovic doit vérifier dans sa boîte Gmail :
1. Les 4 emails sont-ils en inbox ou spam ?
2. Les subjects sont-ils corrects et lisibles ?
3. Le preheader (texte sous le subject dans Gmail) est-il visible et pertinent ?
4. Le rendu desktop est-il correct (logo, couleurs, CTA, footer) ?
5. Le rendu mobile est-il correct (responsive, CTA cliquable) ?
6. Les liens CTA pointent-ils vers `client-dev.keybuzz.io` ?
7. La version text/plain est-elle lisible (visible dans les clients qui n'affichent pas le HTML) ?

---

## 8. Livrabilité code-side

| Check | Attendu | Résultat | Verdict |
|---|---|---|---|
| SPF/DKIM/DMARC auditable code-side | Non / hors scope | Hors scope (configuration DNS serveur mail) | **N/A** |
| From stable | Oui | `"KeyBuzz" <noreply@keybuzz.io>` — hardcodé dans emailService.ts | **OK** |
| Reply-To stable | Oui / documenté | Pas de Reply-To custom (sauf threading inbound via In-Reply-To) | **OK** |
| HTML size raisonnable | Oui (< 100KB) | 3.2KB — 4.5KB par template (tous < 5KB) | **OK** |
| No JS | Oui | 0 balise `<script>` dans emailTemplates.ts | **OK** |
| No tracking pixel | Oui | 0 tracking pixel / beacon / analytics | **OK** |
| text/plain présent | Oui | 13 appels `buildEmailText` (12 templates + index) | **OK** |
| List-Unsubscribe lifecycle | Pas encore requis | 0 header (lifecycle non automatisé) | **OK** |

### Tailles HTML complètes (12 templates)

| Template | Taille HTML |
|---|---|
| `otp` | 3.4KB |
| `invite` | 3.8KB |
| `billing-welcome` | 3.3KB |
| `billing-trial-ending` | 3.2KB |
| `billing-payment-failed` | 3.3KB |
| `trial-j0` | 4.3KB |
| `trial-j2` | 4.5KB |
| `trial-j5` | 4.2KB |
| `trial-j10` | 4.1KB |
| `trial-j13` | 4.0KB |
| `trial-j14` | 4.0KB |
| `trial-grace` | 3.9KB |

Tous les templates sont bien en dessous du seuil de 100KB recommandé pour la livrabilité. Les tailles compactes (3-5KB) minimisent le risque de clipping Gmail (seuil ~102KB).

---

## 9. Non-régression

| Surface | Attendu | Résultat | Verdict |
|---|---|---|---|
| API DEV health | OK | `{"status":"ok","service":"keybuzz-api"}` | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | Inchangée | **OK** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Inchangée | **OK** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | Inchangée | **OK** |
| DB billing | Aucune mutation | 0 billing_events, 0 billing_subscriptions (30 min) | **OK** |
| Stripe | Aucune mutation | Aucune interaction (envois via SMTP, pas Stripe) | **OK** |
| CAPI | Aucun event | Aucun | **OK** |
| Tracking | Aucun event | Aucun pixel/tracker dans templates | **OK** |
| CronJobs DEV | Inchangés | 3 jobs (outbound-tick, sla-evaluator, sla-escalation) | **OK** |
| CronJobs PROD | Inchangés | 2 jobs (outbound-tick, sla-evaluator) | **OK** |

---

## 10. Gaps identifiés

| # | Gap | Impact | Action requise |
|---|---|---|---|
| G1 | QA inbox/spam/rendu en attente de Ludovic | Verdict conditionnel | Ludovic doit vérifier sa boîte Gmail |
| G2 | `POST /debug/email/send-test` ne supporte pas `html` | Nécessite `kubectl exec` pour tests design system | Optionnel : ajouter champ `html` à l'endpoint dans une phase future |
| G3 | SPF/DKIM/DMARC non vérifiés code-side | Livrabilité infra dépend de la config DNS | Hors scope — à vérifier séparément |
| G4 | OTP et outbound agent replies non encore migrés | Templates anciens toujours actifs | Phase future |
| G5 | List-Unsubscribe absent | Requis avant activation lifecycle auto | Phase future (avant activation CronJob lifecycle) |

---

## 11. Décision

### Verdict conditionnel

**GO PARTIEL — EMAILS ENVOYÉS AVEC SUCCÈS — PREVIEWS VALIDÉS — LIVRABILITÉ CODE-SIDE OK — QA INBOX EN ATTENTE VALIDATION LUDOVIC — NO BUILD — NO DEPLOY — NO CODE CHANGE — PROD UNCHANGED**

Les 4 emails ont été envoyés avec succès via SMTP DEV. Les 6 previews cibles + les 12 templates complets sont validés. La livrabilité code-side est conforme. Aucune régression détectée.

Le verdict final dépend de la validation inbox/spam/rendu par Ludovic dans sa boîte Gmail.

Si Ludovic confirme bonne réception inbox + rendu correct :

> **EMAIL INBOX QA PASSED IN DEV — DESIGN SYSTEM EMAILS RENDER CORRECTLY — CONTROLLED TEST EMAILS DELIVERED — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR PROD PROMOTION OF TRANSACTIONAL EMAILS**

Si emails en spam ou rendu cassé :

> **NO GO — EMAIL DELIVERY OR RENDERING ISSUE FOUND — PROD UNCHANGED — FIX REQUIRED BEFORE PROMOTION**

---

## 12. Prochaine phase recommandée

Selon le résultat de la QA Ludovic :

- **Si GO** : `PH-SAAS-T8.12Y.4` — Promotion PROD des emails transactionnels migrés (invite + billing)
- **Si NO GO** : corriger le problème identifié (spam filtering, rendu, etc.) avant promotion

### Roadmap restante

1. Migration OTP vers design system
2. Migration outbound agent replies
3. Activation lifecycle trial CronJob (après List-Unsubscribe)
4. Promotion PROD

---

## 13. PROD inchangée

Confirmé : aucune modification PROD effectuée pendant cette phase.

| Service PROD | Image avant | Image après | Changement |
|---|---|---|---|
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | `v3.5.130-platform-aware-refund-strategy-prod` | **Aucun** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | **Aucun** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | Identique | **Aucun** |

---

## 14. Artefacts

### Fichiers créés
- Aucun fichier code créé ou modifié

### Scripts temporaires (bastion, à supprimer)
- `/tmp/preview_check.sh` — vérification previews
- `/tmp/check_container.sh` — inspection container
- `/tmp/send_test_emails.sh` — envoi emails test
- `/tmp/deliverability_check.sh` — checks livrabilité
- `/tmp/nonreg.sh` — non-régression

### Commits
- Aucun commit code (phase sans code)
- Ce rapport : unique commit de cette phase
