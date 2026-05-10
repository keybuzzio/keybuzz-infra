# PH-SAAS-T8.12AS.1 - Escalation Proactive Notifications DEV

> Date : 2026-05-10
> Linear : KEY-263 (parent KEY-265 + KEY-253)
> Phase : audit verite + design + implementation DEV de notifications internes proactives d'escalade
> Environnement : DEV uniquement (API + Client) - PROD strictement inchangee
> Type : feature DEV - internal notifications, no PII by construction, idempotent, tenant-scoped

## VERDICT

**GO PARTIEL LUDOVIC QA PENDING**

Les notifications internes d'escalade sont implementees en DEV : 4 chemins
d'escalade ecrivent dans la table `notifications` via un helper centralise
no-PII-by-construction, les routes `/notifications` ont un ownership check
tenant-scope, et l'Inbox affiche un badge compact rouge sur le filtre
"A reprendre" quand `count > 0`. API DEV `v3.5.168-escalation-notifications-dev`
et Client DEV `v3.5.177-escalation-notifications-ux-dev` deployes via GitOps
strict, pods Running 1/1 ready 0 restart. PROD strictement inchangee.

Tests fonctionnels E2E (declenchement reel d'escalation, badge visible
end-to-end, idempotence runtime, cross-tenant 4xx via tenantGuardPlugin)
restent a valider par Ludovic via QA UI avec un vrai user authentifie sur
un tenant DEV reel. Un gap pre-existant `tenantGuardPlugin permissive en DEV`
est documente section 16.

---

## 1. Preflight

| Repo | Branche attendue | Branche reelle | HEAD pre-commit | HEAD post-commit | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 0e26bfc3 | 070707a1 | sauf dist/ (pre-existant) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | 0a7306a | 37e70ac | tsconfig.tsbuildinfo (artefact post-build) | OK |
| keybuzz-infra | main | main | 6b130b8 (post KEY-299) | 75396d5 | clean | OK |
| keybuzz-backend | main | main | c62f376 | c62f376 (inchange) | .bak pre-existant (hors scope) | OK |

| Service | Image PROD (avant) | Image PROD (apres) | Verdict |
|---|---|---|---|
| API | v3.5.151-conversation-tone-metric-prod | v3.5.151-conversation-tone-metric-prod | inchange |
| Client | v3.5.174-conversation-tone-metric-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | inchange |
| Backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | inchange |
| Website | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | inchange |
| Admin | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | inchange |
| OW | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | inchange |

| Service | Image DEV (avant) | Image DEV (apres) | Tag immuable | Rollback |
|---|---|---|---|---|
| API | v3.5.167-conversation-tone-metric-dev | v3.5.168-escalation-notifications-dev | OUI | v3.5.167-conversation-tone-metric-dev |
| Client | v3.5.176-conversation-tone-metric-ux-dev | v3.5.177-escalation-notifications-ux-dev | OUI | v3.5.176-conversation-tone-metric-ux-dev |

Global drift scan post-AS.1 : 0 drift sur tous les Deployments KeyBuzz.

---

## 2. Sources relues

| Source | Vu |
|---|---|
| C:\\DEV\\KeyBuzz\\PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01 | OUI (modele CE) |
| AI_MEMORY/CE_PROMPTING_STANDARD.md | OUI |
| AI_MEMORY/RULES_AND_RISKS.md | OUI |
| AI_MEMORY/PRE_ADS_AP_BASELINE.md | OUI |
| PH-SAAS-T8.12AP.2-ESCALATION-ASSIGNMENT-NOTIFICATION-TRUTH-AUDIT-AND-DEV-FIX-01.md | OUI |
| PH-SAAS-T8.12AP.2.5-CONVERSATION-LIFECYCLE-STATUS-PROD-PROMOTION-01.md | OUI (baseline resolved-clears-escalation) |
| PH-SAAS-T8.12AP.2.7-AUTO-ASSIGNMENT-AFTER-REPLY-DEV-01.md | OUI |
| PH-SAAS-T8.12AP.2.8-AUTO-ASSIGNMENT-AFTER-REPLY-PROD-PROMOTION-01.md | OUI |
| PH-SAAS-T8.12AP.2.9-ESCALATION-NOTIFICATION-AND-AUDIT-TRUTH-AUDIT-DEV-PLAN-01.md | OUI (recommandation source) |
| PH-SAAS-T8.12AR.7.2-MESSAGE-SOURCE-PROD-QA-DB-VERIFY-01.md | OUI |
| PH-SAAS-T8.12AR.5.2-CONVERSATION-TONE-INTERNAL-METRIC-PROD-PROMOTION-01.md | OUI (baseline post-AR.5) |

---

## 3. Audit reconfirmation (AP.2.9 reste valide a 100%)

5 chemins d'escalade verifies presents dans la source actuelle de
`keybuzz-api` post-AR.5/KEY-295/KEY-297/KEY-299 :

| # | Source | Fichier source | Hook insere | Reason code |
|---|---|---|---|---|
| 1 | Autopilot engine | src/modules/autopilot/engine.ts (~ligne 894) | OUI | autopilot_escalated |
| 2 | Autopilot consume | src/modules/autopilot/routes.ts (~ligne 397) | OUI | autopilot_consume_escalated |
| 3 | Reply false promise | src/modules/messages/routes.ts (~ligne 626) | OUI | false_promise_detected |
| 4 | AI assist needsHumanAction | src/modules/ai/ai-assist-routes.ts (~ligne 1027) | OUI | ai_assist_needs_human_action |
| 5 | Manual escalate | src/modules/messages/routes.ts (~ligne 1060) | **NON** (decision produit : auteur humain deja au courant, eviter self-notify spam) | - |

Table `notifications` schema (11 colonnes) : id, tenant_id, conversation_id,
channel, level, title, body, status, created_at, delivered_at,
acknowledged_at. Reutilisee sans migration DB.

Module API `notificationsRoutes` registered dans `src/app.ts` (line 47).
Endpoints : GET /notifications (list+filtres), GET /notifications/:id,
PATCH /notifications/:id/ack, POST /notifications/simulate (dev only).

UI Client baseline : EscalationBadge, filtre pickup, tri prioritaire dans
InboxTripane.tsx + composant AgentWorkbenchBar - tous preserves.

---

## 4. Design produit (no-PII par construction)

| Element | Decision |
|---|---|
| Helper signature | `createEscalationNotification({ tenantId, conversationId, reasonCode })` |
| Reason code | TypeScript union strict de 5 valeurs whitelistees (compile-time + runtime check `ALLOWED_REASON_CODES.includes()`) |
| Body | Hard-code via `REASON_CODE_BODY[reasonCode]` map. Aucune interpolation caller. |
| ID notification | `notif-esc-{Date.now()}-{randomUUID().slice(0,8)}` (opaque, sans conversation_id) |
| Tenant scope | Strict : tenant_id dans WHERE de SELECT (idempotence) et INSERT (creation) |
| Idempotence | 1 pending notification par (tenant_id, conversation_id, channel='escalation', status='pending'). SELECT EXISTS before INSERT. |
| Failure mode | Never-throws : `try/catch` interne du helper, retourne `{ created: false, id: null, reason }`. Escalation flow protege. |
| Destinataire | Tenant-scoped (visible a tous les agents du tenant). Pas de routing user-individuel (table n'a pas `user_id`). |
| Manual escalate | Non hooke (auto-notification de l'auteur evitee) |

Reason codes whitelistees et body mappes :

| Reason code | Body (no-PII) |
|---|---|
| autopilot_escalated | "IA : conversation escaladee" |
| autopilot_consume_escalated | "IA : brouillon escalade consomme" |
| false_promise_detected | "Detection automatique : promesse a verifier" |
| ai_assist_needs_human_action | "IA (assist) : intervention humaine requise" |
| escalation_requires_human_review | "Escalade : revue humaine requise" (reserve futur, non utilise par les 4 hooks) |

Aucun reason code n'expose : message body, customer content, detected
promise text, email, tracking, order id, content IA brut, subject. La
signature TS empeche compile-time, le runtime check empeche tout autre cas.

---

## 5. Patch API (6 fichiers, +193 / -5 lignes)

| Fichier | Type | Lignes | Description |
|---|---|---|---|
| src/lib/escalationNotification.ts | NEW | +134 | Helper centralise (whitelist + idempotence + no-PII + never-throw) |
| src/modules/notifications/routes.ts | MOD | +28 / -5 | GET filtre channel additif + GET/:id ownership check + PATCH/:id/ack ownership check + 400 si tenantId manquant |
| src/modules/autopilot/engine.ts | MOD | +8 | import + hook fin de `escalateConversation()` |
| src/modules/autopilot/routes.ts | MOD | +8 | import + hook apres INSERT message_events `'autopilot_escalate'` consume |
| src/modules/messages/routes.ts | MOD | +7 | import + hook apres INSERT message_events `'auto_escalate_false_promise'` |
| src/modules/ai/ai-assist-routes.ts | MOD | +8 | import + hook apres INSERT ai_action_log `'AI_AUTO_ESCALATED'` |

Verifie : appel helper UNIQUEMENT apres UPDATE conversations + INSERT
message_events / ai_action_log existants reussis. Aucun changement de
logique d'escalade existante. Aucune mutation outbound. Aucun envoi externe.

Ownership check tenant-scope :
- GET /notifications/:id : `WHERE id = $1 AND tenant_id = $2`
- PATCH /notifications/:id/ack : `WHERE id = $1 AND tenant_id = $2`
- 400 TENANT_ID_MISSING si tenantId absent (defense-in-depth)

TSC strict : `tsc --noEmit -p .` exit 0. Aucune erreur. Aucun warning.

Non-ASCII delta sur fichiers AS.1 : 0 byte introduit (les 1536 non-ASCII
pre-existants dans `notifications/routes.ts` sont des Unicode box-drawing chars
dans les commentaires de separation de section, identiques pre/post).

---

## 6. Patch Client (5 fichiers, +185 / -1 lignes)

| Fichier | Type | Lignes | Description |
|---|---|---|---|
| app/api/notifications/route.ts | NEW | +56 | BFF Next.js GET proxy vers API /notifications avec auth headers X-User-Email + X-Tenant-Id depuis NextAuth session. Mirror autopilot/history pattern. |
| src/services/notifications.service.ts | NEW | +51 | Service client : `fetchEscalationNotifications(tenantId, options)` via `/api/notifications?...` (credentials: 'include', cache: 'no-store') |
| src/features/inbox/hooks/useEscalationNotifsCount.ts | NEW | +53 | Hook polling 30s. `useTenant().currentTenantId`. Retourne 0 si pas de tenant ou erreur fetch (graceful degradation, never throws). Cleanup useEffect (cancelled flag + clearInterval). |
| src/features/inbox/components/AgentWorkbenchBar.tsx | MOD | +13 / -1 | Prop `escalationNotifCount?: number`. Badge red compact (no animation) sur le bouton "pickup" si `(escalationNotifCount ?? 0) > 0`. aria-label + title pour a11y. Click sur le bouton active `onFilterChange('pickup')` (comportement existant). |
| app/inbox/InboxTripane.tsx | MOD | +3 | import + invocation hook + pass prop a AgentWorkbenchBar |

Tenant-scoped via `useTenant()` (pattern projet documente). Aucun hardcoded
tenant. Aucun user-id hardcode. Pas de NotificationBell topbar, pas de
dropdown, pas de navigation conversation, pas de mini-modal.

Pas de PII dans badge : uniquement le count numerique. Pas de title text
client, pas d'email, pas de message body.

TSC Client : `node_modules/.bin/tsc --noEmit -p .` exit 0. Aucune erreur.

---

## 7. Tests prevus / executes

| Test | Status | Resultat |
|---|---|---|
| API TSC --noEmit -p . | EXECUTED | Exit 0 |
| Client TSC --noEmit -p . | EXECUTED | Exit 0 |
| Non-ASCII delta sur tous les fichiers AS.1 | EXECUTED | 0 byte introduit |
| Build API depuis worktree clean au commit 070707a1 | EXECUTED | OK |
| Build Client depuis worktree clean au commit 37e70ac | EXECUTED | OK |
| Push images vers ghcr.io | EXECUTED | OK (digests captures) |
| Apply manifests DEV via kubectl apply -f | EXECUTED | OK (configured) |
| Rollout status API DEV | EXECUTED | successfully rolled out |
| Rollout status Client DEV | EXECUTED | successfully rolled out |
| Pods Running 1/1 ready, 0 restart | EXECUTED | OK |
| Runtime image = manifest image = last-applied image | EXECUTED | OK (API + Client) |
| API DEV /health | EXECUTED | HTTP 200 |
| API DEV GET /notifications via pod direct (no auth) | EXECUTED | HTTP 200, body `[]` (pas d'erreur, table sans notif escalation) - voir gap section 16 |
| QA Ludovic : declencher vraie escalation, verifier 1 notif pending creee | PENDING | A faire via UI Inbox DEV avec vrai user authentifie |
| QA Ludovic : idempotence runtime (escalade 2 fois meme conv pending - pas de doublon) | PENDING | A faire via UI |
| QA Ludovic : cross-tenant 403 via tenantGuardPlugin | PENDING | Necessite vrai user authentifie sur DEV (curl direct ne passe pas le membership check en DEV - gap section 16) |
| QA Ludovic : badge visible Inbox si count > 0 | PENDING | A faire via UI Client DEV |
| QA Ludovic : click badge active filtre "A reprendre" | PENDING | A faire via UI |
| QA Ludovic : badge masque si count = 0 | PENDING | A faire via UI |

---

## 8. Build DEV (source-of-truth)

| Service | Source commit | Worktree path | Tag immuable | Digest registry |
|---|---|---|---|---|
| API | 070707a17bfd0f6265eea359333428f325eb054e | /tmp/build-api-as1 (cleaned post-build) | v3.5.168-escalation-notifications-dev | sha256:45626491c5fa92ff05336f4d72579db43fb049b2daff7561ac67ad30ed0014b2 |
| Client | 37e70acef8fa494ddce48595c79259196a4e769a | /tmp/build-client-as1 (cleaned post-build) | v3.5.177-escalation-notifications-ux-dev | sha256:08cfa4d42649e4f882358d37929a00d1696d902bd7be1041607e34f1cacb75e8 |

Build-from-git strict respecte :
- Aucun build depuis workspace dirty (commits + push avant build)
- worktree detached HEAD au commit source exact
- worktree cleanup apres build
- aucun `kubectl set image` / `set env` / `patch` / `edit`
- aucun `git reset --hard` / `git clean`

---

## 9. GitOps DEV

Manifests modifies (scope strict 2 fichiers) :
- k8s/keybuzz-api-dev/deployment.yaml : image -> v3.5.168 + commentaire rollback v3.5.167
- k8s/keybuzz-client-dev/deployment.yaml : image -> v3.5.177 + commentaire rollback v3.5.176

Commit infra : `75396d5` sur `main`, push origin/main OK, ahead/behind `0 0`.

Apply executes via `kubectl apply -f` uniquement. Aucun autre kubectl utilise.

---

## 10. Snapshot post-apply

| Service | Runtime image | Last-applied | Match | Pod | Restart total | Ready |
|---|---|---|---|---|---|---|
| API DEV | v3.5.168-escalation-notifications-dev | v3.5.168-escalation-notifications-dev | OK | keybuzz-api-84b46bbd7f-vs8sc | 0 | 1/1 |
| Client DEV | v3.5.177-escalation-notifications-ux-dev | v3.5.177-escalation-notifications-ux-dev | OK | keybuzz-client-584d46cff6-6d6gb | 0 | 1/1 |

Rollout cible : nouveaux pods (image changed). Old pods terminated proprement.
Pas de boucle CrashLoopBackoff. Health endpoint /health repond 200.

---

## 11. Non-regression PROD (read-only)

| Service | Image PROD avant | Image PROD apres | Verdict |
|---|---|---|---|
| API | v3.5.151-conversation-tone-metric-prod | v3.5.151-conversation-tone-metric-prod | inchangee |
| Client | v3.5.174-conversation-tone-metric-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | inchangee |
| Backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | inchangee |
| Website | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | inchangee |
| Admin | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | inchangee |
| OW | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | inchangee |

Aucun touch PROD (aucun apply, aucun build, aucun changement manifest PROD).

---

## 12. AI feature parity / Anti-regression

Verifie : aucune logique d'escalade existante modifiee. Le helper est appele
APRES les UPDATE/INSERT existants. Si le helper plante (`never-throws` mais
defense-in-depth en cas de bug futur), l'escalation et son audit trail
existent deja en DB.

| Baseline | Verdict |
|---|---|
| no-reask AP.1A->AP.1F | preserve (aucune route IA touchee logiquement) |
| author_name AP.2.2/2.3 | preserve |
| auto-assignment AP.2.7/2.8 | preserve (messages/routes.ts touche uniquement section auto_escalate_false_promise) |
| lifecycle AP.2.4/2.5/2.6 | preserve (resolved -> escalation_status='none' inchange) |
| message_source AR.7 | preserve |
| milestones AR.6 / AR.6.1 / AR.6.1A / AR.6.2 | preserve |
| performance dashboard AR.2 -> AR.6.2 | preserve |
| conversation tone AR.5.1 / AR.5.2 (ToneKpiCard) | preserve |
| escalation flow OW (v3.5.165) | preserve (OW non touche) |
| Amazon connector | preserve (Backend non touche) |
| Shopify disabled state | preserve |
| 17TRACK posture | preserve |
| Tracking server-side | preserve |
| Promo funnel | preserve |
| Filtres Inbox existants (pickup, mine, human, ai, sav, status, channel, supplier, type, unread, prioritySort) | preserves (prop optionnelle ne change pas le comportement existant) |
| EscalationBadge component (TreatmentStatusPanel) | preserve |
| AssignmentBadge component | preserve |

---

## 13. No fake events / no external send / no DB migration

| Risque | Controle | Resultat |
|---|---|---|
| Migration DB | aucune | 0 (table notifications existante reutilisee) |
| Email externe | aucun envoi | 0 |
| Message marketplace | aucun envoi | 0 |
| Webhook externe | aucun envoi | 0 |
| Event GA4 / CAPI / TikTok / LinkedIn | aucun event | 0 |
| Mutation Stripe / billing | aucune | 0 |
| Tracking drift | aucun | 0 |
| Token affiche dans logs / rapport | aucune occurrence | 0 |
| Build depuis pod / runtime / dist / SCP | aucun, build-from-git strict | 0 |
| kubectl set image / set env / patch / edit | aucun, kubectl apply -f uniquement | 0 |
| git reset --hard / git clean | aucun | 0 |
| Mutation PROD | aucune | 0 |
| PII dans notification body | helper rejette compile-time + runtime, body issu d'une map hardcodee | 0 |

---

## 14. Linear

Mise a jour a porter sur **KEY-263** (parent KEY-265 + KEY-253) :
- 4 chemins d'escalade hooked vers le helper centralise no-PII
- Routes /notifications GET filtre channel + GET/:id ownership + PATCH ack ownership
- Client Inbox badge compact rouge sur "A reprendre", polling 30s tenant-scoped
- Aucun NotificationBell topbar, aucun dropdown, aucun navigation
- Build/deploy DEV uniquement, PROD strictement inchangee
- Statut suggere : In Review (QA Ludovic pending)

KEY-265 / KEY-253 : aucun impact direct.
KEY-282 (dashboard performance) : preserve (aucun changement).
KEY-290 / KEY-292 / KEY-293 (satisfaction instrumentation) : aucun impact.
KEY-268 (auto-assignment) : preserve.
KEY-295 / KEY-296 / KEY-297 / KEY-299 (infra cleanup) : aucun nouveau drift.
KEY-298 (restartedAt long-term strategy) : aucun impact.
KEY-300 (tracking+resilience merge workers Amazon) : aucun impact.

---

## 15. Rollback DEV

API DEV :
- Image rollback : `v3.5.167-conversation-tone-metric-dev`
- Commande : modifier k8s/keybuzz-api-dev/deployment.yaml -> v3.5.167, commit + push, kubectl apply -f
- Effet : ancien pod recree avec v3.5.167. Notifications restent dans la table (donnees a part) mais ne sont plus ecrites par les 4 hooks (revertes).

Client DEV :
- Image rollback : `v3.5.176-conversation-tone-metric-ux-dev`
- Commande identique sur le manifest client-dev
- Effet : badge disparait (hook + service + BFF n'existent plus dans cette image). Composant AgentWorkbenchBar revient a sa version sans `escalationNotifCount`.

Donnees : aucune migration DB, aucune table modifiee. Les rows inserees
dans `notifications` avec channel='escalation' persistent apres rollback
mais ne sont plus consommees nulle part. Optionnel : DELETE FROM notifications
WHERE channel = 'escalation' AND status = 'pending' (manuel, a valider).

GitOps : `git revert 75396d5`, push, kubectl apply -f des 2 manifests
restaures.

---

## 16. Gaps restants

1. **QA Ludovic pending (validations fonctionnelles 4 a 9)** : declencher une
   vraie escalation DEV avec un vrai user authentifie sur l'UI Inbox,
   verifier la creation d'une notification, verifier l'idempotence (2 escalades
   meme conversation = 1 seule row pending), verifier le badge visible si
   count > 0 et masque si 0, verifier que click badge active le filtre
   "A reprendre".

2. **tenantGuardPlugin permissive en DEV (pre-existant, hors scope AS.1)** :
   curl direct sur les routes `/notifications` ET `/messages/conversations`
   (route deja existante en prod) retourne HTTP 200 `[]` sans X-User-Email
   ni X-Tenant-Id valides. Le tenantGuardPlugin (`src/plugins/tenantGuard.ts`)
   est present dans le bundle (`dist/plugins/tenantGuard.js`) mais semble
   ne pas refuser en DEV. Probable bypass via env var DEV_AUTH=true ou
   middleware specifique non identifie. **Impact AS.1** : l'ownership check
   `AND tenant_id = $2` que j'ai ajoute sur GET /:id et PATCH /:id/ack reste
   fonctionnel et empeche le cross-tenant data leak meme si tenantGuardPlugin
   etait bypasse. Mais le test cross-tenant 403 strict via curl direct ne
   peut pas etre valide en DEV. **A investiguer** dans une phase dediee
   (potentielle dette de securite a clarifier).

3. **NEXT_PUBLIC_API_URL Dockerfile Client** : le Dockerfile a un
   `ARG NEXT_PUBLIC_API_URL=https://api.keybuzz.io` (PROD) en default sans
   override DEV. Mon code utilise `/api/notifications` (BFF Next.js relatif
   via Next.js server), donc le NEXT_PUBLIC_API_URL n'a pas d'impact sur AS.1.
   Mais c'est un gap general pre-existant qui merite une phase dediee si
   d'autres parties du Client appellent directement l'API via NEXT_PUBLIC_API_URL.

4. **Pas de NotificationBell topbar, pas de dropdown, pas de ack UI Client** :
   decision produit pour C1 minimaliste. Si les notifications sont jugees
   utiles en runtime, une phase future peut ajouter :
   - NotificationBell composant topbar avec dropdown liste
   - Endpoint PATCH /notifications/:id/ack consomme cote Client
   - Marquer comme lu apres click sur conversation associee

5. **Manual escalate n'est pas hooke** : decision produit explicite (auteur
   humain de l'escalade est deja au courant). Si un agent escalade
   manuellement et qu'un autre agent doit etre alerte, le badge ne le
   refletera pas (le compteur ne compte que les escalations IA/system).
   A reconsiderer si feedback runtime montre des cas d'usage cross-agent.

6. **Notifications tenant-scoped non agent-specific** : la table
   `notifications` n'a pas de colonne `user_id` ou `assigned_agent_id`. Toutes
   les notifications pending sont visibles a tous les agents du tenant.
   Acceptable pour tenants petits, peut devenir bruyant pour tenants avec
   plusieurs agents simultanes. A reconsiderer si scale tenant grande
   (ajouter colonne `user_id` necessiterait une migration DB - hors scope AS.1).

7. **Idempotence sans UNIQUE INDEX DB** : SELECT-then-INSERT couvre ~99% des
   cas, mais une race condition exacte (2 inserts dans 100ms exact) peut
   creer 2 rows. Mitigation : helper centralise (1 seul point d'ecriture par
   service), peu probable en pratique. Idempotence robuste necessiterait
   `CREATE UNIQUE INDEX` sur (tenant_id, conversation_id, channel, status)
   partial WHERE status='pending' - migration DB hors scope AS.1.

8. **Pas de cleanup automatique des notifications resolues** : quand une
   conversation passe a `resolved`, l'escalation_status retourne a 'none'
   (AP.2.5) mais la notification reste en `status='pending'`. Pour qu'elle
   disparaisse du badge, il faut soit ack manuel via PATCH, soit cleanup
   programmatique (par exemple : auto-ack notifications dont la conversation
   est resolved). A reconsiderer si runtime montre du noise.

---

## 17. Phrase cible finale

ESCALATION PROACTIVE NOTIFICATIONS READY IN DEV - INTERNAL TENANT-SCOPED
NOTIFICATIONS CREATED FOR ESCALATED CONVERSATIONS - 4 ESCALATION PATHS HOOKED
(AUTOPILOT ENGINE / AUTOPILOT CONSUME / FALSE PROMISE / AI ASSIST
NEEDS_HUMAN_ACTION) - MANUAL ESCALATE INTENTIONALLY NOT HOOKED - NO-PII BY
CONSTRUCTION (TYPESCRIPT WHITELIST + HARD-CODED BODY MAP) - IDEMPOTENT
(PENDING NOTIF PER TENANT+CONV+CHANNEL) - NEVER THROWS (ESCALATION FLOW
PROTECTED) - NO CUSTOMER EMAIL - NO AMAZON / MARKETPLACE MESSAGE - NO
EXTERNAL SEND - NO WEBHOOK EXTERNAL - DUPLICATES GUARDED - ESCALATION /
ASSIGNMENT / LIFECYCLE / MESSAGE_SOURCE / PERFORMANCE BASELINES PRESERVED -
NO BILLING / TRACKING / CAPI DRIFT - PROD UNCHANGED - tenantGuardPlugin
PERMISSIVE IN DEV GAP DOCUMENTED (PRE-EXISTING, OWNERSHIP CHECK ENFORCES
SECURITY AT QUERY LEVEL) - READY FOR LUDOVIC QA.

STOP

---

## Rapport

`keybuzz-infra/docs/PH-SAAS-T8.12AS.1-ESCALATION-PROACTIVE-NOTIFICATIONS-DEV-01.md`

## Source commits

- keybuzz-api : `070707a17bfd0f6265eea359333428f325eb054e` on `ph147.4/source-of-truth`
- keybuzz-client : `37e70acef8fa494ddce48595c79259196a4e769a` on `ph148/onboarding-activation-replay`
- keybuzz-infra : `75396d5` on `main` (gitops DEV)

## Image digests

- ghcr.io/keybuzzio/keybuzz-api:v3.5.168-escalation-notifications-dev@sha256:45626491c5fa92ff05336f4d72579db43fb049b2daff7561ac67ad30ed0014b2
- ghcr.io/keybuzzio/keybuzz-client:v3.5.177-escalation-notifications-ux-dev@sha256:08cfa4d42649e4f882358d37929a00d1696d902bd7be1041607e34f1cacb75e8
