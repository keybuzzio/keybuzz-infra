# PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01 — TERMINÉ

**Verdict : GO STRUCTUREL — VALIDATION RUNTIME PENDING CONTROLLED SIGNUP**

| Champ | Valeur |
|---|---|
| Phase | PH-T8.10J |
| Environnement | PROD |
| Date | 2026-04-24 |
| Type | Promotion PROD du marketing owner stack |
| Priorité | P0 |
| API PROD | `v3.5.116-marketing-owner-stack-prod` |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` (inchangée) |
| Tenant owner | `keybuzz-consulting-mo9zndlk` |

---

## 1. Préflight

| Point | Résultat |
|---|---|
| API branche | `ph147.4/source-of-truth` |
| API HEAD | `ac29fd55` |
| API DEV image | `v3.5.116-owner-cockpit-browser-truth-fix-dev` |
| API PROD image (avant) | `v3.5.111-activation-completed-model-prod` |
| Client branche | `ph148/onboarding-activation-replay` |
| Client HEAD | `6d5a796` |
| Client DEV image | `v3.5.112-marketing-owner-mapping-foundation-dev` |
| Client PROD image (avant) | `v3.5.110-post-checkout-activation-foundation-prod` |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` (inchangée) |
| Repos clean | Oui (API + Client) |

---

## 2. Vérification source owner stack

| Brique | Point vérifié | Résultat |
|---|---|---|
| API | `marketing_owner_tenant_id` sur create-signup (tenant-context-routes) | 6 occurrences — OK |
| API | Outbound owner-aware (`resolveOutboundRoutingTenantId` dans emitter.ts) | 3 occurrences — OK |
| API | `/metrics/overview?scope=owner` (`resolveOwnerAggregateTenantIds` dans metrics/routes.ts) | 2 occurrences — OK |
| API | `/funnel/metrics+events?scope=owner` (`resolveOwnerFunnelCohort` dans funnel/routes.ts) | 3 occurrences — OK |
| API | Fix borne haute funnel (`interval '1 day'` exclusif) | 2 points (lines 244, 297) — OK |
| Client | Capture `marketing_owner_tenant_id` (attribution.ts) | 3 occurrences — OK |
| Client | Propagation register → create-signup (register/page.tsx) | 1 occurrence — OK |

Source complète : **GO**

---

## 3. Migration additive PROD

| Table | Colonne | État avant | Action | État après |
|---|---|---|---|---|
| `tenants` | `marketing_owner_tenant_id` | Absente | `ALTER TABLE ADD COLUMN IF NOT EXISTS ... TEXT DEFAULT NULL` | TEXT, nullable — OK |
| `signup_attribution` | `marketing_owner_tenant_id` | Absente | `ALTER TABLE ADD COLUMN IF NOT EXISTS ... TEXT DEFAULT NULL` | TEXT, nullable — OK |
| `funnel_events` | — | Présente | Aucune | Inchangée |
| `conversion_events` | — | Présente | Aucune | Inchangée |

Migration strictement additive, aucun DDL destructif.

---

## 4. Build PROD API + Client

| Service | Commit | Tag | Digest |
|---|---|---|---|
| API | `ac29fd55` (ph147.4/source-of-truth) | `v3.5.116-marketing-owner-stack-prod` | `sha256:baa9e5085c40e08c60ef38c8834007347dc3a34a3738b83a99f97fc41f17507a` |
| Client | `6d5a796` (ph148/onboarding-activation-replay) | `v3.5.116-marketing-owner-stack-prod` | `sha256:f4b8dba6384a3da302e216ad556b90d180aa4273de0acab7772221ee09df164e` |

Build-from-git : repos clean, `--no-cache`, tags immuables, digests documentés.

Client build-args PROD :
- `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_APP_ENV=production`

---

## 5. GitOps PROD

| Fichier | Image avant | Image après |
|---|---|---|
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.111-activation-completed-model-prod` | `v3.5.116-marketing-owner-stack-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.110-post-checkout-activation-foundation-prod` | `v3.5.116-marketing-owner-stack-prod` |

Commit infra : `ae9c64e` sur `main` (keybuzz-infra)
Admin PROD : inchangée.

Rollback documenté dans les commentaires des manifests :
- API : `# rollback: v3.5.111-activation-completed-model-prod`
- Client : `# rollback: v3.5.110-post-checkout-activation-foundation-prod`

---

## 6. Deploy PROD

| Point | Résultat |
|---|---|
| API rollout | `deployment "keybuzz-api" successfully rolled out` |
| Client rollout | `deployment "keybuzz-client" successfully rolled out` |
| API pod | `keybuzz-api-6f7d9fcf8b-qwkxz` — Running, 0 restarts |
| Client pod | `keybuzz-client-694bd98f98-gjldt` — Running, 0 restarts |
| Health | 200 — `{"status":"ok","service":"keybuzz-api"}` |
| API image runtime | `v3.5.116-marketing-owner-stack-prod` |
| Client image runtime | `v3.5.116-marketing-owner-stack-prod` |

---

## 7. Validation PROD structurelle

| Endpoint | Attendu | Résultat |
|---|---|---|
| `/metrics/overview?tenant_id=keybuzz-consulting-mo9zndlk&scope=owner` | 200, scope=owner, owner_cohort | **200, scope=owner, cohort {owner, children:[], total:1}, spend=512.89 EUR** |
| `/funnel/metrics?tenant_id=keybuzz-consulting-mo9zndlk&scope=owner` | 200, 16 steps, activation_completed #16 | **200, 16 steps, last_step=activation_completed, cohort_size=0** |
| `/funnel/events?tenant_id=keybuzz-consulting-mo9zndlk&scope=owner` | 200, owner_cohort | **200, count=0 (fresh PROD), owner_cohort OK** |
| Legacy `/metrics/overview` (no scope) | 200, scope=tenant, pas d'owner_cohort | **200, scope=tenant, owner_cohort=false** |
| Legacy `/funnel/metrics` (no scope) | 200, pas de scope owner | **200, scope=NONE, 16 steps, owner_cohort=false** |

Tous les endpoints owner-scoped répondent correctement. Legacy inchangé.

---

## 8. Validation runtime contrôlée

**Stack live structurally, runtime truth pending controlled signup.**

Aucun signup PROD avec `marketing_owner_tenant_id` n'a été effectué dans cette phase. Le tenant KBC n'a pas encore d'enfants en PROD. La validation runtime sera effectuée au premier signup réel acquis via les publicités.

| Cas | Attendu | Résultat |
|---|---|---|
| Signup avec `marketing_owner_tenant_id` | Tenant enfant mappé | Non testé — aucun signup PROD approuvé |
| `signup_attribution.marketing_owner_tenant_id` | Renseigné | Pending — premier signup réel |
| `tenants.marketing_owner_tenant_id` | Renseigné | Pending — premier signup réel |
| Outbound routing StartTrial | Vers destinations owner | Pending — premier trial réel |

---

## 9. Preuves DB / outbound

| Preuve | Résultat |
|---|---|
| Colonnes `marketing_owner_tenant_id` présentes | `tenants` + `signup_attribution` — TEXT, nullable — OK |
| Tenant KBC PROD | `keybuzz-consulting-mo9zndlk` existe, owner_mapping=NULL (pas d'auto-ref) — OK |
| Tenants avec owner mapping | 0 rows (aucun signup réel yet) — Normal |
| Tenants legacy (NULL owner) | 5 existants (ecomlg-001, switaa, etc.) — OK |
| `signup_attribution` avec owner | 0 rows — Normal (pending premier signup) |
| `conversion_events` | 0 rows — Normal |
| Outbound destinations KBC | 1 active (Meta CAPI `87f8dc49`), 2 soft-deleted — OK |

---

## 10. Non-régression

| Point | Résultat |
|---|---|
| `/funnel/metrics` legacy (ecomlg-001) | 200, 16 steps, scope=NONE — OK |
| `/metrics/overview` legacy (ecomlg-001) | 200, scope=tenant, owner_cohort=false — OK |
| Health endpoint | 200 — OK |
| API restarts | 0 — OK |
| Client restarts | 0 — OK |
| `signup_attribution` intacte | 4 rows — OK |
| `billing_subscriptions` intacte | 11 rows — OK |
| `funnel_events` intactes | 6 rows — OK |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` — Inchangée |
| Legacy flows sans owner | Fonctionnels (aucun crash, scope=tenant) — OK |

---

## 11. Digests

| Image | Digest |
|---|---|
| API `v3.5.116-marketing-owner-stack-prod` | `sha256:baa9e5085c40e08c60ef38c8834007347dc3a34a3738b83a99f97fc41f17507a` |
| Client `v3.5.116-marketing-owner-stack-prod` | `sha256:f4b8dba6384a3da302e216ad556b90d180aa4273de0acab7772221ee09df164e` |

---

## 12. Rollback PROD

| Service | Rollback vers | Commande |
|---|---|---|
| API | `v3.5.111-activation-completed-model-prod` | `kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.111-activation-completed-model-prod -n keybuzz-api-prod` |
| Client | `v3.5.110-post-checkout-activation-foundation-prod` | `kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.110-post-checkout-activation-foundation-prod -n keybuzz-client-prod` |

Les colonnes `marketing_owner_tenant_id` sont nullables et rétrocompatibles — aucun rollback DB nécessaire.

---

## 13. Gaps restants

| Gap | Description | Impact |
|---|---|---|
| Admin PROD ne fait pas encore `scope=owner` | L'Admin PROD (`v2.11.11`) n'envoie pas `scope=owner` | Le cockpit owner n'est pas visible en PROD Admin |
| Owner cockpit PROD UI pas promu | L'UI owner cockpit existe en Admin DEV mais n'a pas été promue | Dashboard owner non accessible en PROD Admin |
| Contrat LP/funnels externes owner-scoped | Les LP Webflow/externes ne passent pas encore `marketing_owner_tenant_id` automatiquement | Signups depuis LP doivent être configurés pour passer le param |
| Absence de backfill historique | Les tenants existants n'ont pas été rétromappés avec un `marketing_owner_tenant_id` | Seuls les nouveaux signups seront owner-mappés |
| Existing-user path | Si un utilisateur existant refait un signup, la capture du `marketing_owner_tenant_id` peut ne pas s'appliquer | Limitation connue, à valider si rencontrée |

---

## 14. Admin PROD inchangée

**Oui** — `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` — confirmé avant et après déploiement.

---

## 15. Conclusion

**MARKETING OWNER STACK LIVE IN PROD — OWNER MAPPING AND OWNER-SCOPED API READY — OUTBOUND OWNER-AWARE PRESERVED — ADMIN PROD UNCHANGED**

La PROD est prête pour le mode owner marketing :
- Les colonnes `marketing_owner_tenant_id` sont en place sur `tenants` et `signup_attribution`
- Le flow `/register` capture et propage `marketing_owner_tenant_id`
- Les endpoints `scope=owner` fonctionnent (`/metrics/overview`, `/funnel/metrics`, `/funnel/events`)
- Le routing outbound est owner-aware
- Le fix borne haute funnel est actif
- Les flows legacy sans owner sont préservés
- Admin PROD reste inchangée

Le premier signup réel acquis via les publicités avec `marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk` confirmera la vérité runtime complète.

---

**Rapport** : `keybuzz-infra/docs/PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01.md`
