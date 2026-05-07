# PH-SAAS-T8.12AP.2.6 — Resolved+Escalated Historical Cleanup PROD

> Date : 2026-05-07
> Auteur : Cursor Executor
> Phase : AP.2.6
> Ticket : KEY-265
> Tickets liés : KEY-253, KEY-263, KEY-268
> Environnement : PROD
> Type : Audit + backup + cleanup DB contrôlé

---

## Objectif

Nettoyer les 18 conversations historiques PROD incohérentes `resolved + escalated`.

La phase AP.2.5 a promu le fix futur empêchant la création de nouvelles incohérences. Cette phase nettoie les données historiques pré-existantes.

---

## Sources relues

| Source | Statut |
|---|---|
| `CE_PROMPTING_STANDARD.md` | Relue (contexte conversation) |
| `RULES_AND_RISKS.md` | Relue (contexte conversation) |
| `DATA_HYGIENE_BASELINE.md` | Relue (contexte conversation) |
| `AI_MESSAGING_FEATURE_PARITY_BASELINE.md` | Relue (contexte conversation) |
| `PH-SAAS-T8.12AP.2.4-...-TRUTH-AUDIT-AND-DEV-FIX-01.md` | Relue |
| `PH-SAAS-T8.12AP.2.5-...-PROD-PROMOTION-01.md` | Relue |

---

## Baselines PROD (inchangées, aucun build/deploy)

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API PROD | `v3.5.146-conversation-lifecycle-status-prod` | `v3.5.146-conversation-lifecycle-status-prod` | MATCH |
| Client PROD | `v3.5.168-outbound-author-name-ux-prod` | `v3.5.168-outbound-author-name-ux-prod` | MATCH |
| OW PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | MATCH |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | MATCH |
| Website PROD | `v0.6.9-promo-forwarding-prod` | `v0.6.9-promo-forwarding-prod` | MATCH |

Pod API : 1/1 Running, 0 restarts, health OK. Aucun rollout en cours.

---

## Infra preflight

| Champ | Valeur |
|---|---|
| Repo | keybuzz-infra |
| Branche | main |
| HEAD | `8067e68` |
| Git status | Clean |

---

## ÉTAPE 1 — Audit read-only des 18 conversations

### Count cible

`resolved + escalated` : **18** (exact match attendu)

### Détail complet

| ID | Tenant | Channel | Status | Esc. | SAV | Agent | Order | Created | Updated |
|---|---|---|---|---|---|---|---|---|---|
| cmmopuprrxb283a3e20b8899e | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-05-03 | 2026-05-06 |
| cmmoshgw3j9841e37954823ed | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-05-05 | 2026-05-06 |
| cmmor2ij44f04b48f32926e80 | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-05-04 | 2026-05-05 |
| cmmohk01kf27e59d2776aa42d | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-27 | 2026-04-30 |
| cmmoaq3tb148cef7b6d7f5414 | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-23 | 2026-04-30 |
| cmmod29pbab126513035027c2 | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-24 | 2026-04-29 |
| cmmodyhqo0cd57b0b1ea606ea | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-25 | 2026-04-28 |
| cmmoh1nawvaac6df28ef5ca45 | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-27 | 2026-04-28 |
| cmmob7xos2d8a189a7fc56746 | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-23 | 2026-04-24 |
| cmmnzpvtj4b6345e0e8f164a8 | switaa-s.. | amazon | resolved | escalated | null | no | yes | 2026-04-15 | 2026-04-23 |
| cmml43wxbc7a9bd6e17aa15a2 | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-02-01 | 2026-04-22 |
| cmmml1zhuld8d96514f80c48c | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-03-10 | 2026-04-22 |
| cmmnpr02ql54c20dc6624b2d9 | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-08 | 2026-04-21 |
| cmmntdju8nda9124c4964693b | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-10 | 2026-04-21 |
| cmmnz73ngt0a7e8162e15c62d | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-14 | 2026-04-21 |
| cmmnrj3eu1165cafb6e29337c | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-09 | 2026-04-21 |
| cmmnzrymyt39a8305629ef9bb | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-15 | 2026-04-16 |
| cmmnjy5r2790c0e877b652afd | ecomlg-0.. | amazon | resolved | escalated | closed | no | yes | 2026-04-04 | 2026-04-14 |

### Profil des 18 lignes

- **Toutes resolved** : 18/18
- **Toutes escalated** : 18/18
- **Toutes amazon** : 18/18
- **Toutes avec order_ref** : 18/18
- **Toutes sans agent assigné** : 18/18
- **SAV** : 17/18 closed, 1/18 null (tenant switaa)
- **Inbound après résolution** : 0/18 — aucune conversation encore active
- **Billing events (dernière heure)** : 0

Verdict : **18 conversations bien incohérentes, toutes résolues et inactives, aucun risque**.

---

## ÉTAPE 2 — Décision de cleanup

| Champ | Décision |
|---|---|
| Valeur actuelle | `'escalated'` |
| Valeur cible | `'none'` |
| Justification | `'none'` est la valeur standard (527 conversations), utilisée par le fix AP.2.4, et cohérente avec le schéma |
| `updated_at` | Non modifié (cleanup technique, pas une action utilisateur) |
| `status` | Non touché |
| `sav_status` | Non touché |
| `assigned_agent_id` | Non touché |

---

## ÉTAPE 3 — Backup ciblé

| Champ | Valeur |
|---|---|
| Path pod | `/opt/keybuzz/backups/PH-SAAS-T8.12AP.2.6/resolved-escalated-conversations-20260507143139.sql` |
| Path bastion | `/opt/keybuzz/backups/PH-SAAS-T8.12AP.2.6/resolved-escalated-conversations-20260507143139.sql` |
| Size | 3634 bytes |
| SHA256 | `65f9efc29925637b9e3f90f04fcafbf0467387f605c1a68cc5a63005e135c915` |
| Rows | 18 |
| Contient secrets | Non |
| Commité Git | **Non** (jamais) |

Le backup contient :
- SQL de rollback restaurable
- Détail complet de chaque ligne (id, status, escalation_status, sav_status, agent, updated_at)

---

## ÉTAPE 4 — Dry-run

| Étape | Résultat |
|---|---|
| BEGIN | OK |
| SELECT count avant | 18 resolved+escalated |
| UPDATE | 18 rows affected |
| SELECT count après | 0 resolved+escalated |
| ROLLBACK | OK |

Verdict : **PASS — exactement 18 rows**

---

## ÉTAPE 5 — Mutation contrôlée

```sql
UPDATE conversations
SET escalation_status = 'none'
WHERE id IN (
  'cmml43wxbc7a9bd6e17aa15a2', 'cmmml1zhuld8d96514f80c48c',
  'cmmnjy5r2790c0e877b652afd', 'cmmnpr02ql54c20dc6624b2d9',
  'cmmnrj3eu1165cafb6e29337c', 'cmmntdju8nda9124c4964693b',
  'cmmnz73ngt0a7e8162e15c62d', 'cmmnzpvtj4b6345e0e8f164a8',
  'cmmnzrymyt39a8305629ef9bb', 'cmmoaq3tb148cef7b6d7f5414',
  'cmmob7xos2d8a189a7fc56746', 'cmmod29pbab126513035027c2',
  'cmmodyhqo0cd57b0b1ea606ea', 'cmmoh1nawvaac6df28ef5ca45',
  'cmmohk01kf27e59d2776aa42d', 'cmmopuprrxb283a3e20b8899e',
  'cmmor2ij44f04b48f32926e80', 'cmmoshgw3j9841e37954823ed'
)
AND status = 'resolved'
AND escalation_status = 'escalated';
```

Résultat : **18 rows — COMMIT**

---

## ÉTAPE 6 — Validation post-mutation

| Signal | Avant | Après | Verdict |
|---|---|---|---|
| `resolved + escalated` | 18 | **0** | CLEAN |
| `escalation_status = none` | 527 | **545** (+18) | MATCH |
| `escalation_status = escalated` | 34 | **16** (-18, tous `open`) | MATCH |
| conversations total | 561 | 561 | INCHANGÉ |
| messages total | 1661 | 1661 | INCHANGÉ |
| tenants | 14 | 14 | INCHANGÉ |
| billing_events | 160 | 160 | INCHANGÉ |
| billing_subscriptions | 8 | 8 | INCHANGÉ |
| 18 IDs maintenant `none` | N/A | **YES** | CONFIRMÉ |
| API health | OK | OK | OK |
| Pod restarts | 0 | 0 | OK |

### Matrice status/escalation après cleanup

| Status | Escalation | Count |
|---|---|---|
| resolved | none | 511 |
| open | none | 32 |
| open | escalated | 16 |
| pending | none | 2 |

Les 16 `open + escalated` sont un état valide (conversations en cours d'escalade, pas un bug).

---

## ÉTAPE 7 — Rollback plan

Si rollback nécessaire :

```sql
-- Depuis le backup sur le bastion
-- /opt/keybuzz/backups/PH-SAAS-T8.12AP.2.6/resolved-escalated-conversations-20260507143139.sql

UPDATE conversations SET escalation_status = 'escalated' WHERE id IN (
  'cmml43wxbc7a9bd6e17aa15a2',
  'cmmml1zhuld8d96514f80c48c',
  'cmmnjy5r2790c0e877b652afd',
  'cmmnpr02ql54c20dc6624b2d9',
  'cmmnrj3eu1165cafb6e29337c',
  'cmmntdju8nda9124c4964693b',
  'cmmnz73ngt0a7e8162e15c62d',
  'cmmnzpvtj4b6345e0e8f164a8',
  'cmmnzrymyt39a8305629ef9bb',
  'cmmoaq3tb148cef7b6d7f5414',
  'cmmob7xos2d8a189a7fc56746',
  'cmmod29pbab126513035027c2',
  'cmmodyhqo0cd57b0b1ea606ea',
  'cmmoh1nawvaac6df28ef5ca45',
  'cmmohk01kf27e59d2776aa42d',
  'cmmopuprrxb283a3e20b8899e',
  'cmmor2ij44f04b48f32926e80',
  'cmmoshgw3j9841e37954823ed'
);
```

Préconditions : exécuter depuis le pod API PROD ou depuis `db-postgres-01` via psql.

---

## Linear

| Ticket | Mise à jour |
|---|---|
| KEY-265 | AP.2.6 cleanup historique fait. 18 conversations nettoyées. 0 `resolved+escalated` restant. Fix futur actif (AP.2.5). Backup SHA256: `65f9efc2...`. Non fermé — auto-assignation/notification restent hors scope. |
| KEY-253 | Progression avant Ads : no-reask, author_name, escalation lifecycle, data hygiene — tous en PROD. |
| KEY-263 | Auto-assignation post-escalade reste hors scope. |
| KEY-268 | Notification agent on-escalade reste hors scope. |

---

## Interdits respectés

- Aucun build Docker
- Aucun deploy / rollout
- Aucun manifest modifié
- Aucune conversation supprimée
- Aucun message modifié
- Aucun status modifié
- Aucun sav_status modifié
- Aucun assigned_agent_id modifié
- Aucun billing/Stripe/CAPI modifié
- Aucun tracking modifié
- Backup créé avant mutation
- Dry-run validé avant commit
- Backup non commité Git

---

## Images PROD (inchangées)

| Service | Image |
|---|---|
| API | `v3.5.146-conversation-lifecycle-status-prod` |
| Client | `v3.5.168-outbound-author-name-ux-prod` |
| OW | `v3.5.165-escalation-flow-prod` |
| Backend | `v1.0.47-cross-env-guard-fix-prod` |
| Website | `v0.6.9-promo-forwarding-prod` |

---

## Gaps restants

1. **Auto-assignation post-escalade** (KEY-263) — phase dédiée
2. **Notification agent on-escalade** (KEY-268) — phase dédiée
3. **16 conversations `open + escalated`** — état valide, pas un bug

---

## Verdict

**GO CLEANUP COMPLETE**

RESOLVED ESCALATED HISTORICAL CLEANUP COMPLETE — 18 LEGACY CONVERSATIONS NORMALIZED — FUTURE FIX ALREADY LIVE — BACKUP VERIFIED — NO CONVERSATION/MESSAGE DELETED — STATUS/SAV/ASSIGNMENT PRESERVED — API/CLIENT/BACKEND/WEBSITE/OW UNCHANGED — NO BILLING/TRACKING/CAPI DRIFT — PROD DATA HYGIENE IMPROVED
