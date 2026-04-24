# PH-T4.2-REPLAY-TRACKING-COMMITS-ON-VALIDATED-CLIENT-BRANCH-01 — TERMINÉ

> Date : 2026-04-17
> Environnement : DEV uniquement
> Type : replay propre des commits tracking client sur branche saine validée

---

## Verdict : GO — TRACKING CLIENT REPLAY SUCCESS ON VALIDATED BRANCH

---

## 1. Préflight


| Élément          | Valeur                                                                        |
| ---------------- | ----------------------------------------------------------------------------- |
| Client DEV avant | `ghcr.io/keybuzzio/keybuzz-client:v3.5.75-ph151-step4.1-filters-collapse-dev` |
| API DEV          | `ghcr.io/keybuzzio/keybuzz-api:v3.5.77-tracking-t4-api-dev` (conservée)       |
| Backend DEV      | inchangé                                                                      |
| Rollback prêt    | `v3.5.75-ph151-step4.1-filters-collapse-dev`                                  |
| Client pod       | Running 1/1                                                                   |
| API health       | OK                                                                            |


Le client DEV restauré (PH-T4.1) était cohérent : /start, dashboard, autopilot, inbox, settings/agents — tout présent et fonctionnel.

---

## 2. Branche source saine


| Propriété        | Valeur                                                       |
| ---------------- | ------------------------------------------------------------ |
| Branche          | `ph148/onboarding-activation-replay`                         |
| HEAD au checkout | `5f3f16f` (PH151.2.2: Remove .bak files and add ignore rule) |
| Repo clean       | OUI (git status --short = vide)                              |
| Contenu          | Baseline PH147→PH151 complète                                |


---

## 3. Cherry-picks exécutés


| #   | Commit source | Nouveau SHA | Description                                                         | Conflits |
| --- | ------------- | ----------- | ------------------------------------------------------------------- | -------- |
| 1   | `ec32d98`     | `05c9163`   | PH-T1: marketing attribution (UTM, click IDs, GA4 linker, Meta fbc) | ZERO     |
| 2   | `9723eef`     | `e579f1e`   | PH-T3: GA4 + Meta Pixel SaaS funnel tracking                        | ZERO     |
| 3   | `65c11ee`     | `461a6f6`   | PH-T3: fix TrackingParams type (nested objects)                     | ZERO     |
| 4   | `e5f5f54`     | `7a94f2a`   | PH-T4: checkout attribution for Stripe metadata                     | ZERO     |


Commit additionnel :


| #   | SHA       | Description                                       |
| --- | --------- | ------------------------------------------------- |
| 5   | `f165e1b` | PH-T4.2: add GA4/Meta Pixel ARG+ENV to Dockerfile |


**Aucun conflit sur les 4 cherry-picks.** Application propre.

---

## 4. Fichiers réellement touchés


| Fichier                                     | Source commit   | Scope tracking pur ?                         | OK/NOK |
| ------------------------------------------- | --------------- | -------------------------------------------- | ------ |
| `src/lib/attribution.ts`                    | PH-T1 (ec32d98) | OUI — nouveau fichier (296 lignes)           | OK     |
| `app/register/page.tsx`                     | PH-T1+T3+T4     | OUI — tracking events + attribution checkout | OK     |
| `src/lib/tracking.ts`                       | PH-T3 (9723eef) | OUI — nouveau fichier (122 lignes)           | OK     |
| `src/components/tracking/SaaSAnalytics.tsx` | PH-T3 (9723eef) | OUI — nouveau fichier (112 lignes)           | OK     |
| `app/layout.tsx`                            | PH-T3 (9723eef) | OUI — import SaaSAnalytics uniquement        | OK     |
| `app/register/success/page.tsx`             | PH-T3 (9723eef) | OUI — trackPurchase event                    | OK     |
| `app/api/billing/checkout-session/route.ts` | PH-T4 (e5f5f54) | OUI — forward attribution                    | OK     |
| `Dockerfile`                                | PH-T4.2         | OUI — ARG/ENV GA4+Meta pour build-time       | OK     |


**Total : 8 fichiers modifiés — 100% scope tracking.**

### Domaines vérifiés intacts (git diff 5f3f16f..HEAD = vide)

- `app/start/` — aucune modification
- `app/dashboard/` — aucune modification
- `app/inbox/` — aucune modification
- `app/settings/` — aucune modification
- `src/features/dashboard/` — aucune modification
- `src/features/inbox/` — aucune modification
- `src/services/agents.service.ts` — aucune modification

---

## 5. Image client DEV avant/après


| État             | Image                                                                          |
| ---------------- | ------------------------------------------------------------------------------ |
| Avant (rollback) | `ghcr.io/keybuzzio/keybuzz-client:v3.5.75-ph151-step4.1-filters-collapse-dev`  |
| Après (replay)   | `ghcr.io/keybuzzio/keybuzz-client:v3.5.78-tracking-replay-on-valid-branch-dev` |


### Provenance du build


| Propriété   | Valeur                                                                                                                                                                                               |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Branche     | `ph148/onboarding-activation-replay`                                                                                                                                                                 |
| Commit HEAD | `f165e1b`                                                                                                                                                                                            |
| Build       | `docker build --no-cache` sur bastion                                                                                                                                                                |
| Build-args  | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG`, `NEXT_PUBLIC_META_PIXEL_ID=1234164602194748` |
| Registry    | `ghcr.io/keybuzzio/keybuzz-client`                                                                                                                                                                   |
| Digest      | `sha256:cfa367f206b9278430255a1510947046566c7ea8e25d9b54e2319958da5a783b`                                                                                                                            |


---

## 6. Validation SaaS fonctionnelle


| Domaine        | État | Détail                                             |
| -------------- | ---- | -------------------------------------------------- |
| /start         | OK   | PRESENT (1625 bytes)                               |
| dashboard      | OK   | PRESENT (27888 bytes)                              |
| supervision    | OK   | SupervisionPanel compilé                           |
| autopilot      | OK   | draft, evaluate, history, settings — tous présents |
| inbox          | OK   | page + [conversationId] route                      |
| settings       | OK   | agents, ai-supervision, billing                    |
| agents         | OK   | Route PRESENT                                      |
| signature      | OK   | 1 référence dans settings                          |
| summary/résumé | OK   | 1 référence CaseSummary                            |


---

## 7. Validation tracking


| Composant                            | État | Détail                                 |
| ------------------------------------ | ---- | -------------------------------------- |
| attribution (kb_attribution_context) | OK   | 1 fichier dans bundles static          |
| SaaSAnalytics                        | OK   | 53 références dans bundles server      |
| GA4 ID (G-R3QQDYEBFG)                | OK   | 5 matches dans bundles compilés        |
| Meta Pixel (1234164602194748)        | OK   | 2 matches dans bundles compilés        |
| checkout attribution BFF             | OK   | 1 match dans checkout-session/route.js |


---

## 8. Non-régression


| Page              | État    |
| ----------------- | ------- |
| /start            | PRESENT |
| /dashboard        | PRESENT |
| /inbox            | PRESENT |
| /settings         | PRESENT |
| /channels         | PRESENT |
| /billing          | PRESENT |
| /register         | PRESENT |
| /register/success | PRESENT |


### Privacy check — zero tracking sur pages protégées


| Page      | Refs tracking | Attendu |
| --------- | ------------- | ------- |
| inbox     | 0             | 0 ✓     |
| dashboard | 0             | 0 ✓     |
| orders    | 0             | 0 ✓     |
| settings  | 0             | 0 ✓     |


---

## 9. Rollback

En cas de problème :

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.75-ph151-step4.1-filters-collapse-dev \
  -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

L'API DEV reste inchangée à `v3.5.77-tracking-t4-api-dev`.

---

## 10. Historique des commits sur la branche

```
f165e1b PH-T4.2: add GA4/Meta Pixel ARG+ENV to Dockerfile for tracking build-args
7a94f2a PH-T4: pass attribution to checkout-session for Stripe metadata enrichment
461a6f6 PH-T3: fix TrackingParams type to accept nested objects for GA4 items
e579f1e PH-T3: GA4 + Meta Pixel SaaS funnel tracking
05c9163 PH-T1: add marketing attribution capture - UTM, click IDs, GA4 linker, Meta fbc
5f3f16f PH151.2.2: Remove .bak files and add ignore rule
336f6f0 PH151.1-STEP4.1: Stats 2 lines + collapsible Filtres column
1765d03 PH151.1-STEP4: PriorityDot replaces PriorityBadge, compact stats, reorder badges
```

---

## 11. Conclusion

**TRACKING CLIENT REPLAY SUCCESS ON VALIDATED BRANCH**

- 4 cherry-picks appliqués sans conflit sur la branche saine `ph148/onboarding-activation-replay`
- 1 commit Dockerfile additionnel pour injection GA4/Meta build-args
- 8 fichiers modifiés, 100% scope tracking pur
- Aucun domaine fonctionnel SaaS altéré (vérifié par git diff + validation pod)
- GA4, Meta Pixel, attribution, funnel events, checkout attribution — tous opérationnels
- Privacy respectée : zero tracking sur pages protégées (inbox, dashboard, orders, settings)
- Non-régression complète : toutes les pages compilées et présentes
- Rollback immédiat disponible

Aucune autre action effectuée.

STOP