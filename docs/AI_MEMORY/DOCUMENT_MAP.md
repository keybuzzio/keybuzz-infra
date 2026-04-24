# Carte documentaire KeyBuzz

> Derniere mise a jour : 2026-04-21
> Scope : inventaire local hors `node_modules`, `.next`, `.venv`, `site-packages`, `.git`, archives et builds.

## Volume documentaire

Documents utiles identifies : 2 119.

| Type | Nombre | Commentaire |
|---|---:|---|
| Markdown `.md` | 1 384 | Rapports de phase, runbooks, sources de verite. |
| YAML/YML | 306 | Manifests K8s, ArgoCD, inventories, configs. |
| PDF | 206 | Principalement corpus marketing Asphalte/Smoozii. |
| JSON | 87 | Feature registry, configs, donnees diverses. |
| DOCX | 69 | Briefs, brand books, prompts marketing, cahiers des charges. |
| TXT | 64 | Conversations, transcriptions, exports. |
| TOML | 3 | Configs diverses. |

## Repartition par grandes familles

| Famille | Volume approx. | Role |
|---|---:|---|
| `keybuzz-infra/docs` | 1 008 | Source principale de verite projet/phase. |
| Infra/K8s/Ansible | 568 | Manifests, install, runbooks, scripts, modules historiques. |
| Marketing | 313 | Corpus copywriting, branding, media buying, funnels. |
| App/root/other | 202 | Client SaaS, docs racine, configs, divers. |
| Seller | 10 | Seller API et docs associees. |
| Studio | 7 | Docs/artefacts Studio. |
| Automation | 6 | n8n/workflows. |
| Admin | 5 | Admin v2 local hors rapports PH-ADMIN. |

## Sources de verite prioritaires

Lecture en premiere intention :

1. `AI_MEMORY/CURRENT_STATE.md`
2. `AI_MEMORY/PROJECT_OVERVIEW.md`
3. `AI_MEMORY/RULES_AND_RISKS.md`
4. `RECAPITULATIF PHASES.md`
5. `PROMPT-NOUVEL-AGENT.md` avec prudence, car date du 2026-03-27
6. `DB-ARCHITECTURE-CONTRACT.md`
7. `FEATURE_TRUTH_MATRIX_V2.md`
8. `PH152-GIT-SOURCE-OF-TRUTH-LOCK-01.md`
9. `PH147.RULES-CURSOR-PROCESS-LOCK-01.md`
10. Le dernier rapport de phase du domaine concerne

## Rapports recents critiques par domaine

### Autopilot

- `PH-AUTOPILOT-E2E-TRUTH-AUDIT-01.md`
- `PH-AUTOPILOT-ESCALATION-CONSUME-DIAGNOSTIC-01.md`
- `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-01.md`
- `PH-AUTOPILOT-ESCALATION-HANDOFF-FIX-PROD-PROMOTION-01.md`
- `PH-AUTOPILOT-ORDER-ID-CONTEXT-AUDIT-01.md`
- `PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-01.md`
- `PH-AUTOPILOT-INBOUND-TRIGGER-RECOVERY-01.md`
- `PH152.2-AUTOPILOT-TRUTH-RECOVERY-01.md`

### Inbox / Client reconstruction

- `PH152.1-DEV-TRUTH-RECONSTRUCTION-FROM-PROD-AND-REPORTS-01.md`
- `PH152-GIT-SOURCE-OF-TRUTH-LOCK-01.md`
- `PH153.9-DEPENDENCY-CLOSURE-PLAN-01.md`
- `PH153.10.3-ROLLBACK-AND-FINAL-MISSING-FEATURES-PROOF-01.md`
- `PH154-INBOX-CONTEXT-CLEAN-REBUILD-01.md`
- `PH154.1.2-INBOX-PIXEL-TARGET-REBUILD-01.md`
- `PH154.1.3-INBOX-VISUAL-PARITY-FIX-STRICT-01.md`

### DB / source-of-truth

- `DB-ARCHITECTURE-CONTRACT.md`
- `DB-TABLE-MATRIX.md`
- `DB-ACCESS-MAP.md`
- `PH-TD-01B-DB-ACCESS-MAPPING.md`
- `PH-TD-05-EXTERNALMESSAGE-UNIFICATION.md`
- `PH26.4-SINGLE-SOURCE-OF-TRUTH-MAPPING.md`

### Plans / billing / feature truth

- `FEATURE_TRUTH_MATRIX.md`
- `FEATURE_TRUTH_MATRIX_V2.md`
- `feature_registry.json`
- `PH129-PLAN-AUDIT-01-REPORT.md`
- `PH129-PLAN-NORMALIZATION-BUSINESS-02-REPORT.md`
- `PH130-PLAN-GATING-ACTIVATION-01-REPORT.md`
- `PH-BILLING-PLAN-TRUTH-RECOVERY-02-REPORT.md`
- `PH146.5-PROD-PROMOTION-BILLING-SUBSCRIPTION-WEBHOOK-SYNC-01.md`

### Playbooks

- `PH-PLAYBOOKS-TRUTH-RECOVERY-01-REPORT.md`
- `PH-PLAYBOOKS-BACKEND-TRUTH-AUDIT-01-REPORT.md`
- `PH-PLAYBOOKS-BACKEND-MIGRATION-02-REPORT.md`
- `PH-PLAYBOOKS-ENGINE-ALIGNMENT-02B-REPORT.md`
- `PH-PLAYBOOKS-STARTERS-ACTIVATION-03-REPORT.md`
- `PH-PLAYBOOKS-SUGGESTIONS-LIVE-04-REPORT.md`

### Admin

- `PH-ADMIN-SOURCE-OF-TRUTH-01-REPORT.md`
- `PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md`
- `PH-ADMIN-87.7A-FULL-E2E-FUNCTIONAL-AUDIT-REPORT.md`
- `PH-ADMIN-87.8B-DEPLOYMENT-TRUTH-AUDIT.md`
- `PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md`

### Tracking / acquisition

- `PH-TRACKING-SAAS-ARCHITECTURE-AND-PLAN-01.md`
- `PH-WEBSITE-TRACKING-FOUNDATION-01.md`
- `PH-T5.0-ADDINGWELL-ARCHITECTURE-DECISION-01.md`
- `PH-T7.0-MULTI-CHANNEL-TRACKING-ARCHITECTURE-DECISION-01.md`
- `PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md`
- `PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md`
- `PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md`

### Studio

- `STUDIO-ARCHITECTURE.md`
- `STUDIO-RULES.md`
- `STUDIO-WORKFLOW.md`
- `STUDIO-MASTER-REPORT.md`
- `PH-STUDIO-*`

### Shopify

- `PH-SHOPIFY-01-ARCHITECTURE-AUDIT-AND-INSERTION-PLAN.md`
- `PH-SHOPIFY-02-OAUTH-CONNECTION.md`
- `PH-SHOPIFY-04-PROD-PROMOTION.md`
- `PH-SHOPIFY-PROD-APP-SETUP-01.md`
- `PH-SHOPIFY-PROD-CLIENT-ALIGN-01.md`

### Amazon

- `AMAZON-OUTBOUND-SOURCE-OF-TRUTH.md`
- `PH150-AMAZON-CONVERSATION-THREADING-TRUTH-AND-ORDER-CENTRIC-RECOVERY-01.md`
- `PH15-AMAZON-*`
- `PH-AMZ-*`
- `PH145.3-AMAZON-CONNECTOR-TRUTH-RECOVERY-01.md`
- `PH145.5-AMAZON-OAUTH-CALLBACK-ATOMICS-RECOVERY-01.md`

## Marketing / contenu

Le dossier `V3\marketing` contient surtout :

- 101 PDFs emails Asphalte dans `Branding\Asphalte\Emails`;
- 101 PDFs similaires/dupliques dans `Smoozii vs Asphalte\Email Asphalte`;
- brand books et documents Smoozii;
- briefs/cahiers des charges;
- landing pages, ads, lead magnets, formulaires;
- prompts n8n/audit funnel.

Ces documents servent au copywriting, a la strategie marketing et aux assets. Ils ne tranchent pas l'etat technique.

## Methode de lecture recommandee pour un nouvel agent

1. Lire `AI_MEMORY`.
2. Identifier le domaine exact de la demande.
3. Lire le dernier rapport de phase du domaine.
4. Lire les rapports precedents seulement si la phase actuelle y fait reference.
5. Inspecter le code local et le Git status.
6. Refuser les conclusions basees uniquement sur un vieux prompt de conversation.
7. Mettre a jour `AI_MEMORY` apres toute nouvelle phase.

