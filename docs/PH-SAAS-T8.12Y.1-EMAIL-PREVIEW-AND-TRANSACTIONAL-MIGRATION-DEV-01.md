# PH-SAAS-T8.12Y.1 — Email Preview & Transactional Migration (DEV)

> Date : 2026-05-02
> Type : Source lock + preview DEV + migration transactionnelle
> Environnement : DEV uniquement
> Statut : **EMAIL PREVIEW LIVE IN DEV — INVITE MIGRATED — DESIGN SYSTEM RUNTIME VALIDATED**

---

## 0. SOURCES RELUES

- `keybuzz-infra/docs/AI_MEMORY/TRIAL_WOW_STACK_BASELINE.md`
- `keybuzz-infra/docs/AI_MEMORY/SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12Y-EMAIL-DESIGN-SYSTEM-AND-TRIAL-LIFECYCLE-CONVERSION-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12X-TRIAL-WOW-STACK-CLOSURE-AND-NEXT-ROADMAP-01.md`

---

## 1. PRÉFLIGHT

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `16106d23` | Oui (dist/ + Y files) | OK |
| `keybuzz-infra` | `main` | `main` | `a9dd8ee` | Oui (docs untracked) | OK |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `39591d9` | Non | OK (lecture seule) |

| Service | ENV | Image runtime | Manifest = runtime | Verdict |
|---|---|---|---|---|
| API DEV | DEV | `v3.5.130-platform-aware-refund-strategy-dev` | Oui | OK |
| API PROD | PROD | `v3.5.130-platform-aware-refund-strategy-prod` | — | OK (baseline) |
| Client PROD | PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | — | OK (baseline) |

---

## 2. SOURCE LOCK PH-SAAS-T8.12Y

| Fichier | Existe | Commité | Export valide | Risque |
|---|---|---|---|---|
| `src/services/emailTemplates.ts` | Oui (25555 bytes) | `b9b03122` | 14 exports | Aucun |
| `src/modules/debug/email-preview.ts` | Oui (4527 bytes) | `b9b03122` | 1 route | Aucun |

---

## 3. PREVIEW ENDPOINT

Import ajouté dans `app.ts` lignes 15 + 141 :

```typescript
import { emailPreviewRoutes } from './modules/debug/email-preview';
app.register(emailPreviewRoutes, { prefix: '/debug' });
```

Garde DEV-only : `if (process.env.NODE_ENV === 'production') return;`

| Route | Attendu | Résultat |
|---|---|---|
| `GET /debug/email/preview` | Index HTML avec 12 templates | **OK** |
| `GET /debug/email/preview?template=otp&format=html` | HTML OTP responsive | **OK** |
| `GET /debug/email/preview?template=trial-j0&format=html` | HTML trial welcome | **OK** |
| `GET /debug/email/preview?template=trial-j13&format=text` | Texte trial J13 | **OK** |
| `GET /debug/email/preview?template=trial-grace&format=json` | JSON {subject, html, text} | **OK** |
| `GET /debug/email/preview?template=invite&format=html` | HTML invitation design system | **OK** |
| `GET /debug/email/preview?template=billing-welcome&format=html` | HTML billing welcome | **OK** |
| `GET /debug/email/preview?template=nonexistent` | 404 propre | **OK** |
| Secrets check | 0 secret exposé | **OK** |

---

## 4. MIGRATION TRANSACTIONNELLE

| Email | Fichier actuel | Migré | Raison | Risque |
|---|---|---|---|---|
| **Invitation espace** | `space-invites-routes.ts` | **Oui** | 1 call site, inline simple, faible trafic | Faible |
| Billing welcome | `billing/routes.ts:1594` | Reporter | Fichier critique 89KB, webhooks Stripe | Moyen |
| Billing trial ending | `billing/routes.ts:831` | Reporter | Même fichier | Moyen |
| Billing payment failed | `billing/routes.ts:870` | Reporter | Même fichier | Moyen |
| Contact form | `public/contact.ts` | Non | Interne seulement | — |
| Debug email test | `debug/email-test.ts` | Non | Debug tool | — |
| OTP | Client `otp-email.ts` | Non | Vit dans Client, pas API | Hors scope |

### Migration invite : détail

Remplacement du HTML inline par `inviteEmailTemplate(tenantName, role, inviteUrl)` :
- Ajout import `inviteEmailTemplate` depuis `emailTemplates`
- Remplacement du HTML inline par appel template
- Ajout `text: emailData.text` (version plain text)
- Subject, From, destinataire, try/catch inchangés
- `tsc --noEmit` : 0 erreur

---

## 5. LIVRABILITÉ

| Check | Attendu | Résultat |
|---|---|---|
| Pas de JS email | Oui | **OK** |
| Pas de tracking pixel | Oui | **OK** |
| Pas d'image lourde | Oui | **OK** (logo 40px) |
| Preheader présent | Oui | **OK** |
| Version text/plain | Oui | **OK** |
| CTA fallback URL visible | Oui | **OK** |
| From inchangé | Oui | **OK** (`noreply@keybuzz.io`) |
| Reply-to inchangé | Oui | **OK** |
| Pas de mots spammy | Oui | **OK** |

---

## 6. BUILD DEV API

| Élément | Valeur |
|---|---|
| Tag | `v3.5.131-email-preview-transactional-dev` |
| Digest | `sha256:4c88535bf67a5e80dc420f1b0e31ffc030241b6a85086f9ad5e6dcd75d506ed8` |
| Source commit | `956da28d` |
| Clone | depth=1 clean clone, supprimé après build |
| `tsc` build | 0 erreur |
| `npm ci` | 380 packages |

---

## 7. GITOPS DEV

| Élément | Valeur |
|---|---|
| Image précédente | `v3.5.130-platform-aware-refund-strategy-dev` |
| Image nouvelle | `v3.5.131-email-preview-transactional-dev` |
| Digest | `sha256:4c88535bf67a5e80dc420f1b0e31ffc030241b6a85086f9ad5e6dcd75d506ed8` |
| Rollback | `v3.5.130-platform-aware-refund-strategy-dev` |
| Commit API | `956da28d` (branch `ph147.4/source-of-truth`) |
| Commit infra | `490ad20` (branch `main`) |
| Manifest | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` |
| Apply | `kubectl apply -f` — rollout successful |
| Runtime = manifest | **Oui** |

---

## 8. VALIDATION RUNTIME

| Test | Attendu | Résultat |
|---|---|---|
| API health | `{"status":"ok"}` | **OK** |
| Preview index | 12 templates listés | **OK** |
| OTP HTML | Responsive, preheader, OTP code | **OK** |
| Trial J0 HTML | Copilote, seller-first | **OK** |
| Trial J13 text | Version texte complète | **OK** |
| Trial grace JSON | {subject, html, text} | **OK** |
| Invite HTML | Design system unifié | **OK** |
| Billing welcome HTML | Design system unifié | **OK** |
| Template 404 | Erreur propre | **OK** |
| Secrets check | 0 secret | **OK** |

---

## 9. EMAIL RÉEL

Email réel non envoyé volontairement. Aucune adresse de test contrôlée documentée. Le preview runtime valide la structure complète.

---

## 10. NON-RÉGRESSION

| Surface | Attendu | Résultat |
|---|---|---|
| API health DEV | `{"status":"ok"}` | **OK** |
| API PROD | `v3.5.130-platform-aware-refund-strategy-prod` | **OK** — inchangé |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | **OK** — inchangé |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | **OK** — inchangé |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | **OK** — inchangé |
| Billing | Aucun event | **OK** |
| CAPI | Aucun event | **OK** |
| Tracking | Aucun event | **OK** |
| DB | Aucune mutation | **OK** |
| CronJobs | 3 inchangés | **OK** |

---

## 11. GAPS

| Gap | Sévérité | Action |
|---|---|---|
| OTP Client à migrer | Faible | Phase Client séparée |
| Billing emails (3 appels) | Moyen | Phase Y.2 |
| Lifecycle scheduling | Moyen | Table SQL + CronJob |
| List-Unsubscribe | Élevé avant lifecycle | Header à ajouter |
| `email_opt_out` flag | Moyen | Colonne tenant_metadata |
| SPF/DKIM/DMARC | Moyen | Vérification DNS hors scope |
| PROD promotion | Basse | Après validation DEV complète |

---

## 12. ROLLBACK GITOPS

En cas de problème :

```bash
# API DEV rollback
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.130-platform-aware-refund-strategy-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

Puis mettre à jour `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` avec le tag précédent.

---

## 13. FICHIERS MODIFIÉS

| Fichier | Action | Commit |
|---|---|---|
| `keybuzz-api/src/services/emailTemplates.ts` | Nouveau (Y) | `b9b03122` |
| `keybuzz-api/src/modules/debug/email-preview.ts` | Nouveau (Y) | `b9b03122` |
| `keybuzz-api/src/app.ts` | Modifié (+2 lignes) | `956da28d` |
| `keybuzz-api/src/modules/auth/space-invites-routes.ts` | Modifié (migration invite) | `956da28d` |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Modifié (image tag) | `490ad20` |

---

## 14. PROD INCHANGÉE

- Client PROD : `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` — **INTACT**
- API PROD : `v3.5.130-platform-aware-refund-strategy-prod` — **INTACT**
- Admin PROD : `v2.11.37-acquisition-baseline-truth-prod` — **INTACT**
- Website PROD : `v0.6.8-tiktok-browser-pixel-prod` — **INTACT**

---

## VERDICT

**EMAIL PREVIEW LIVE IN DEV — TRANSACTIONAL EMAIL MIGRATION SAFE — DESIGN SYSTEM RUNTIME VALIDATED — LIFECYCLE EMAILS STILL NOT AUTOMATED — DELIVERABILITY CONSTRAINTS PRESERVED — NO TRACKING/BILLING/CAPI DRIFT — PROD UNCHANGED**

### Résumé

- Source Y verrouillée et commitée (`b9b03122`)
- Preview endpoint enregistré dans `app.ts`, opérationnel en DEV
- 12 templates prévisualisables (HTML, text, JSON)
- Invitation espace migrée vers le design system
- Build `v3.5.131-email-preview-transactional-dev` depuis clone propre
- Déployé via GitOps strict (commit infra `490ad20`)
- 10/10 runtime checks OK
- 10/10 non-régression OK
- 0 email envoyé
- PROD intacte
- Billing migration reportée (phase Y.2)
- Lifecycle scheduling non activé
