# PH-SAAS-T8.12Y.9B - Trial Lifecycle Controlled Send PROD Allowlist

> Date : 2026-05-02
> Environnement : PROD
> Type : Envoi reel controle allowlist, sans activation generale
> Priorite : P1
> Image precedente API PROD : `ghcr.io/keybuzzio/keybuzz-api:v3.5.133-trial-lifecycle-cron-dryrun-prod`
> Image deployee API PROD : `ghcr.io/keybuzzio/keybuzz-api:v3.5.134-trial-lifecycle-controlled-send-prod`

---

## 1. OBJECTIF

Effectuer le tout premier envoi lifecycle reel en PROD, sous controle strict :
- 1 seul destinataire allowliste (`ludo.gonthier@gmail.com`)
- 1 seul tenant explicitement choisi
- 1 seul template lifecycle (`trial-welcome`)
- aucun CronJob d'envoi reel
- le CronJob existant reste en dry-run
- idempotence verifiee
- unsubscribe verifie

---

## 2. SOURCES RELUES

| Document | Chemin |
|---|---|
| CE_PROMPTING_STANDARD | `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md` |
| RULES_AND_RISKS | `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md` |
| TRIAL_WOW_STACK_BASELINE | `keybuzz-infra/docs/AI_MEMORY/TRIAL_WOW_STACK_BASELINE.md` |
| Y.4 PROD promotion | `keybuzz-infra/docs/PH-SAAS-T8.12Y.4-*.md` |
| Y.7.1 Unsubscribe hotfix | `keybuzz-infra/docs/PH-SAAS-T8.12Y.7.1-*.md` |
| Y.7.2 QA closure | `keybuzz-infra/docs/PH-SAAS-T8.12Y.7.2-*.md` |
| Y.8 PROD foundation | `keybuzz-infra/docs/PH-SAAS-T8.12Y.8-*.md` |
| Y.9A CronJob dry-run | `keybuzz-infra/docs/PH-SAAS-T8.12Y.9A-*.md` |

---

## 3. PREFLIGHT

### Repos

| Repo | Branche attendue | Branche constatee | HEAD | src/ dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api (bastion) | ph147.4/source-of-truth | ph147.4/source-of-truth | `6afa4b1a` | Non | GO |
| keybuzz-infra (local) | main | main | `e7a1c7f` | Non | GO |

### Runtimes

| Service | Manifest | Runtime | Verdict |
|---|---|---|---|
| API PROD | v3.5.133-trial-lifecycle-cron-dryrun-prod | v3.5.133-trial-lifecycle-cron-dryrun-prod | GO |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | idem | GO |
| Website PROD | v0.6.8-tiktok-browser-pixel-prod | idem | GO |

### Etat pre-phase

| Check | Valeur |
|---|---|
| CronJob trial-lifecycle-dryrun | Existe, dry-run only |
| Aucun CronJob lifecycle reel | Confirme |
| trial_lifecycle_emails_sent | 0 rows |
| Opt-out count | 0 |

---

## 4. AUDIT CANDIDATS PROD

| Metrique | Valeur |
|---|---|
| Total trial tenants | 23 |
| Exempts billing | 22 |
| Payes (billing_subscriptions active) | 3 |
| Opt-out | 0 |
| Already sent | 0 |
| **Eligibles** | **2** |

Tenant choisi : tenant interne de test (PRO, jour 3, 10j restants).
Template : `trial-welcome` (eligible car day >= 0 et trial_active).
Destinataire : `ludo.gonthier@gmail.com` via recipientOverride.

---

## 5. DESIGN CONTROLLED-SEND

### Protections implementees

| Protection | Mecanisme | Verifie |
|---|---|---|
| Auth interne | X-Lifecycle-Token (crypto.timingSafeEqual) | OUI |
| controlledSend=true requis | Body param, sinon dry-run guards classiques | OUI |
| dryRun=false requis | Verifie dans le bloc controlledSend | OUI |
| force=true requis | Verifie dans le bloc controlledSend | OUI |
| recipientOverride === allowlist | Hardcode ludo.gonthier@gmail.com, rejet sinon (403) | OUI |
| templateName explicite | Requis, pas de batch multi-template | OUI |
| tenantId explicite | Requis, pas de batch multi-tenant | OUI |
| Pas de prefix [DEV TEST] | Sujet email propre pour QA inbox | OUI |
| Idempotence | ON CONFLICT DO NOTHING existant | OUI |

---

## 6. PATCH API

### Fichiers modifies

| Fichier | Changement |
|---|---|
| trial-lifecycle.routes.ts | Ajout bloc controlledSend dans PROD (56 insertions, 7 deletions) |
| trial-lifecycle.service.ts | Ajout controlledSendOverride + targetTemplateName a TickOptions |

### Commit API

- SHA : `e8d3ff48`
- Branche : `ph147.4/source-of-truth`
- Message : `feat(lifecycle): PROD controlledSend for single allowlisted recipient (PH-SAAS-T8.12Y.9B)`

---

## 7. VALIDATION STATIQUE (10/10 PASS)

| Check | Resultat |
|---|---|
| TypeScript tsc --noEmit | PASS |
| Allowlist exacte (ludo.gonthier@gmail.com seul) | PASS |
| controlledSendOverride hardcode | PASS |
| Multi-tenant impossible | PASS |
| Multi-template impossible | PASS |
| CronJob non modifie | PASS |
| Aucun secret dans source | PASS |
| Pas d'em dash dans email content | PASS |
| Dry-run PROD preserve (3 appels true) | PASS |
| dryRun=false PROD uniquement controlledSend | PASS |

---

## 8. BUILD DEV

- Tag : `v3.5.140-lifecycle-controlled-send-dev`
- Digest : `sha256:402225591dad9b4949f323ab8192be9ff545851e350675fd4faf579cca104689`
- GitOps commit : `29a71ae`
- Health : OK

---

## 9. BUILD PROD

- Tag : `v3.5.134-trial-lifecycle-controlled-send-prod`
- Digest : `sha256:a9193b75a1172a598b1e6d4026d466672a547352273905d46cc6d078acdb6ccb`
- Source commit : `e8d3ff48`
- Branche : `ph147.4/source-of-truth`
- Rollback : `v3.5.133-trial-lifecycle-cron-dryrun-prod`

---

## 10. GITOPS API PROD

- Commit infra : `da8bf10`
- Message : `gitops(api-prod): deploy v3.5.134-trial-lifecycle-controlled-send-prod (PH-SAAS-T8.12Y.9B)`
- Rollout : success
- Health : OK
- CronJob dry-run : toujours present, inchange

---

## 11. GUARDS PROD (6/6 PASS)

| Guard | Body | Attendu | Resultat |
|---|---|---|---|
| dryRun=false sans controlledSend | `{"dryRun":false}` | 403 | **403 PASS** |
| controlledSend + mauvais email | `{"controlledSend":true,...,"recipientOverride":"hacker@evil.com"}` | 403 | **403 PASS** |
| controlledSend sans token | (pas de X-Lifecycle-Token) | 403 | **403 PASS** |
| controlledSend sans templateName | (templateName absent) | 400 | **400 PASS** |
| controlledSend sans tenantId | (tenantId absent) | 400 | **400 PASS** |
| Standard dry-run | `{"dryRun":true}` | 200 + prodSafe | **200 PASS** (47 candidats, 4 eligibles) |

---

## 12. ENVOI CONTROLE PROD

### Pre-envoi

| Check | Valeur |
|---|---|
| Idempotence rows avant | 0 |
| Tenant cible | ludovic-mojol7ds |
| Template cible | trial-welcome |
| Recipient | ludo.gonthier@gmail.com |
| CronJob dry-run toujours actif | OUI |
| Aucun CronJob reel | OUI |

### Resultat envoi

```json
{
  "controlledSend": true,
  "prodSafe": true,
  "dryRun": false,
  "timestamp": "2026-05-02T14:56:58.787Z",
  "sentCount": 1,
  "errorCount": 0,
  "sent": [{"tenantId": "ludovic-mojol7ds", "template": "trial-welcome", "to": "ludo.gonthier@gmail.com"}],
  "errors": []
}
```

### Post-envoi

| Check | Attendu | Resultat |
|---|---|---|
| Provider accepted | OUI | **PASS** |
| Email sent count | 1 | **1 PASS** |
| Row idempotence +1 | OUI | **1 row PASS** |
| template_name | trial-welcome | **PASS** |
| recipient_email | ludo.gonthier@gmail.com | **PASS** |
| status | sent | **PASS** |
| Second envoi identique | blocked (sentCount=0) | **PASS** |
| Row count apres 2nd envoi | 1 (inchange) | **PASS** |
| CronJob dry-run | inchange | **PASS** |
| Aucun autre email | OUI | **PASS** |

---

## 13. UNSUBSCRIBE VALIDATION

| Check | Resultat |
|---|---|
| Endpoint /lifecycle/unsubscribe existe | OUI (400 sans token) |
| Token invalide rejete | OUI (400 + page erreur HTML) |
| Aucun opt-out active | 0 |
| buildUnsubscribeUrl utilise dans le send | OUI |
| Lien unsubscribe integre dans l'email | OUI |

Note : pas d'activation de l'opt-out sans clic explicite de Ludovic.

---

## 14. NON-REGRESSION (13/13 PASS)

| Surface | Attendu | Resultat |
|---|---|---|
| API health | OK | PASS |
| Billing current | OK | PASS |
| Conversations | Chargees | PASS |
| Dashboard | OK | PASS |
| Outbound worker | Running | PASS |
| CronJob dry-run | 0 8 * * * inchange | PASS |
| Aucun CronJob reel | Aucun | PASS |
| Aucun CAPI/tracking | Verifie | PASS |
| Aucun Stripe event | Verifie | PASS |
| Client PROD | v3.5.147 inchange | PASS |
| Website PROD | v0.6.8 inchange | PASS |
| client.keybuzz.io | HTTP 200 | PASS |
| www.keybuzz.pro | HTTP 200 | PASS |

---

## 15. ROLLBACK GITOPS

### API PROD

```
Image precedente : v3.5.133-trial-lifecycle-cron-dryrun-prod
Fichier : keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
Action : modifier image, commit, push, kubectl apply
```

### CronJob

Aucune modification. Le CronJob `trial-lifecycle-dryrun` reste en dry-run.

### Controlled-send

L'endpoint controlledSend est inclus dans v3.5.134. Le rollback vers v3.5.133 le supprime.

---

## 16. INBOX QA LUDOVIC

**STATUT : VALIDE** (confirme en Y.9B.1, 2026-05-02)

| Check | Resultat |
|---|---|
| Inbox, pas spam | OK |
| Rendu desktop | OK |
| Rendu mobile | OK |
| Accents / apostrophes | OK |
| Tirets classiques | OK |
| Lien "Se desabonner" visible | OK |
| CTA | OK |
| Wording | OK |

---

## 17. VERDICT

**GO COMPLET**

CONTROLLED LIFECYCLE EMAIL SENT IN PROD
- ONE RECIPIENT ALLOWLISTED (ludo.gonthier@gmail.com)
- ONE TEMPLATE (trial-welcome)
- IDEMPOTENCE VERIFIED
- CRONJOB STILL DRY-RUN
- NO BULK SEND
- NO TRACKING/BILLING/CAPI DRIFT
- LUDOVIC INBOX QA VALIDATED (Y.9B.1)
