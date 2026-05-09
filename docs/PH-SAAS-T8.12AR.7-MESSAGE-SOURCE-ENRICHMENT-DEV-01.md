# PH-SAAS-T8.12AR.7 — MESSAGE SOURCE ENRICHMENT DEV

**Verdict : GO DEV FIX READY**

> Date : 2026-05-09
> Linear : KEY-291
> Parent : KEY-282
> Environnement : DEV uniquement
> PROD : strictement inchangée

---

## Résumé

Enrichissement du champ `message_source` pour les futurs messages outbound en DEV.
Le Dashboard Performance SAV peut désormais distinguer les réponses humaines pures des réponses IA assistées validées par un humain, sans backfill historique et sans toucher PROD.

---

## Sources relues

- `keybuzz-infra/docs/PH-SAAS-T8.12AR.1-DASHBOARD-PERFORMANCE-SAV-TRUTH-AUDIT-AND-DESIGN-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AR.2-DASHBOARD-PERFORMANCE-SAV-API-METRICS-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AR.3-DASHBOARD-PERFORMANCE-SAV-CLIENT-UI-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AR.4-DASHBOARD-PERFORMANCE-SAV-PROD-PROMOTION-01.md`

---

## Preflight

| Repo | Branche attendue | Branche réelle | HEAD | Verdict |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | dac5b790 | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | c8e0ffe | OK |
| keybuzz-infra | main | main | 2570e45 | OK |

### Images avant/après

| Service | Image DEV avant | Image DEV après | Image PROD (inchangée) |
|---|---|---|---|
| API | v3.5.162-performance-sav-metrics-dev | **v3.5.163-message-source-enrichment-dev** | v3.5.148-performance-sav-metrics-prod |
| Client | v3.5.171-performance-sav-dashboard-dev | **v3.5.172-message-source-enrichment-ux-dev** | v3.5.171-performance-sav-dashboard-prod |
| OW | v3.5.165-escalation-flow-dev | **inchangé** | v3.5.165-escalation-flow-prod |
| Backend | -- | **inchangé** | v1.0.47-cross-env-guard-fix-prod |
| Website | -- | **inchangé** | v0.6.12-linkedin-insight-seo-prod |
| Admin | -- | **inchangé** | v2.12.2-media-buyer-lp-domain-qa-prod |

---

## Schema DB message_source

| Env | Colonne | Type | Default | Contrainte | Migration requise ? |
|---|---|---|---|---|---|
| DEV | message_source | text NOT NULL | 'HUMAN' | Aucune CHECK | **Non** (text libre) |
| PROD | message_source | text NOT NULL | 'HUMAN' | Aucune CHECK | Non |

Index existant : `idx_messages_source` (btree)

### Valeurs distinctes DEV (avant AR.7)

| Source | Count total | Count outbound | Commentaire |
|---|---|---|---|
| HUMAN | 1562 | 281 | Majoritaire, inclut les IA assistées non taguées |
| autopilot | 16 | 16 | Chemin autopilot/engine.ts existant |
| SUPPLIER_CONTACT | 8 | 8 | Contact fournisseur |
| marketplace | 5 | 0 | Import Octopia |
| SUPPLIER_INBOUND | 3 | 0 | Réponse fournisseur entrante |
| customer | 1 | 0 | Message client |

### Valeurs distinctes PROD (lecture seule)

| Source | Count total | Count outbound |
|---|---|---|
| HUMAN | 1657 | 444 |
| SUPPLIER_CONTACT | 10 | 10 |
| SUPPLIER_INBOUND | 6 | 0 |

---

## Audit chemins d'envoi

| Chemin | Fichier | Qui clique ? | Validation humaine ? | Source avant | Source après AR.7 |
|---|---|---|---|---|---|
| Composer manuel | messages/routes.ts L412 | Agent | Oui | HUMAN | HUMAN |
| Aide IA → insérer → envoyer | AISuggestionSlideOver + send | Agent | Oui | HUMAN | **AI_ASSISTED** |
| Brouillon IA → valider → envoyer | Autopilot draft panel + send | Agent | Oui | HUMAN | **AI_ASSISTED** |
| Template → insérer → envoyer | TemplatePickerSlideOver + send | Agent | Oui | HUMAN | HUMAN |
| Autopilot auto-reply | autopilot/engine.ts L823 | Système | Non | autopilot | autopilot (inchangé) |
| Supplier contact | suppliers/routes.ts | Agent | Oui | SUPPLIER_CONTACT | SUPPLIER_CONTACT (inchangé) |

---

## Contrat source

| Source | Signification | Chemin d'écriture | Implémentée AR.7 ? | Justification |
|---|---|---|---|---|
| HUMAN | Réponse humaine pure | API reply route (default) | Oui (existant) | Baseline |
| **AI_ASSISTED** | IA assistée validée par humain | API reply route + hint client | **Oui (nouveau)** | AR.7 |
| autopilot | Auto-reply sans humain | autopilot/engine.ts | Oui (existant) | Pas de changement |
| AI_AUTOPILOT | Contrat futur autopilot normalisé | -- | Non (prêt, pas de chemin) | Documenté |
| AGENT_KEYBUZZ | Agent KBZ humain | -- | Non | Pas de workflow réel |
| SUPPLIER_CONTACT | Contact fournisseur | suppliers/routes.ts | Oui (existant) | Pas de changement |
| SUPPLIER_INBOUND | Réponse fournisseur | inbound/routes.ts | Oui (existant) | Pas de changement |

---

## Patch API

### messages/routes.ts

| Changement | Détail |
|---|---|
| Body destructuring | Ajout `message_source: clientMessageSource` optionnel |
| Validation whitelist | `ALLOWED_SOURCES = ['HUMAN', 'AI_ASSISTED']` |
| Fallback | `HUMAN` si absent ou non autorisé |
| INSERT | Utilise `validatedSource` au lieu de `'HUMAN'` hardcodé |

### performance-stats.service.ts

| Changement | Détail |
|---|---|
| Limitation mise à jour | `replies_breakdown_improving: new outbound messages have explicit message_source (AR.7)` |
| Doc comment | Mis à jour pour refléter l'enrichissement |

### Baselines préservées

| Baseline | Préservée ? |
|---|---|
| author_name (Prénom.N) | Oui — aucun changement au code AP.2.2 |
| assigned_agent_id | Oui — aucun changement |
| Auto-assignment après réponse | Oui — aucun changement |
| Lifecycle status | Oui — aucun changement |
| No-reask | Oui — aucun changement |
| Human validation | Oui — aucun auto-send ajouté |

---

## Patch Client

### conversations.service.ts

| Changement | Détail |
|---|---|
| Signature sendReply | Ajout paramètre optionnel `messageSource?: string` |
| Body JSON | Inclut `message_source` si fourni |

### InboxTripane.tsx

| Changement | Détail |
|---|---|
| État `aiAssisted` | `useState(false)` — track si IA a participé à la réponse |
| AISuggestionSlideOver onInsertResponse | `setAiAssisted(true)` quand suggestion IA insérée |
| Autopilot draft onDirectSend | Passe `'AI_ASSISTED'` directement |
| handleSendReply | Passe `aiAssisted ? 'AI_ASSISTED' : undefined` |
| Reset après envoi | `setAiAssisted(false)` après succès |
| TemplatePickerSlideOver | **Non modifié** — reste HUMAN (templates humain-curated) |

---

## Patch OW

| OW touché ? | Pourquoi | Verdict |
|---|---|---|
| **Non** | L'autopilot engine écrit déjà `'autopilot'` correctement (L823). Pas de nouveau chemin à instrumenter. | Skip |

---

## Tests

### Tests DB DEV attendus

| Test | Attendu | Verdict |
|---|---|---|
| Réponse humaine pure | message_source=HUMAN, author_name=Prénom.N | **Prêt** (code validé, test fonctionnel en attente QA Ludovic) |
| Aide IA → insérer → envoyer | message_source=AI_ASSISTED, author_name=Prénom.N | **Prêt** |
| Brouillon IA → valider → envoyer | message_source=AI_ASSISTED | **Prêt** |
| Autopilot auto | message_source=autopilot (existant) | **Existant, pas de changement** |
| Legacy message | Inchangé, pas de backfill | **Confirmé** |

### Tests /stats/performance

| Cas | Attendu | Résultat |
|---|---|---|
| API retourne 200 | OK | **OK** |
| Limitation mise à jour | `replies_breakdown_improving` | **OK** |
| Satisfaction null | null | **OK** |
| Fallback legacy actif | ai_action_log correlation | **OK** |

---

## Pre-build checks

| Repo | Check | Résultat |
|---|---|---|
| API | TypeScript compile | OK |
| API | Hardcoding scan | CLEAN |
| API | Mutation scan | CLEAN |
| API | Fake metrics scan | CLEAN |
| Client | TypeScript compile | OK |
| Client | Tracking scan | CLEAN |
| Client | Fake data scan | CLEAN |

---

## Builds DEV

| Service | Commit | Tag | Digest | Rollback |
|---|---|---|---|---|
| API | 03818fea | v3.5.163-message-source-enrichment-dev | sha256:674b7dcdb7f1... | v3.5.162-performance-sav-metrics-dev |
| Client | ad0cb6b | v3.5.172-message-source-enrichment-ux-dev | sha256:37265000c098... | v3.5.171-performance-sav-dashboard-dev |

---

## GitOps DEV

| Manifest | Image avant | Image après |
|---|---|---|
| k8s/keybuzz-api-dev/deployment.yaml | v3.5.162-performance-sav-metrics-dev | v3.5.163-message-source-enrichment-dev |
| k8s/keybuzz-client-dev/deployment.yaml | v3.5.171-performance-sav-dashboard-dev | v3.5.172-message-source-enrichment-ux-dev |

Commit infra : `3640f3f` — poussé sur `main`

---

## Runtime validation DEV

| Surface | Validation | Résultat |
|---|---|---|
| API pod Running | kubectl get pods | OK (1/1 Running, 0 restarts) |
| Client pod Running | kubectl get pods | OK (1/1 Running) |
| Health API | /health | `{"status":"ok"}` |
| /stats/performance | 200, limitations updated | OK |
| Satisfaction | null | OK |

---

## Non-régression PROD

| Service PROD | Image avant | Image après | Verdict |
|---|---|---|---|
| API | v3.5.148-performance-sav-metrics-prod | v3.5.148-performance-sav-metrics-prod | **INCHANGÉ** |
| Client | v3.5.171-performance-sav-dashboard-prod | v3.5.171-performance-sav-dashboard-prod | **INCHANGÉ** |
| Backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | **INCHANGÉ** |
| Website | v0.6.12-linkedin-insight-seo-prod | v0.6.12-linkedin-insight-seo-prod | **INCHANGÉ** |
| Admin | v2.12.2-media-buyer-lp-domain-qa-prod | v2.12.2-media-buyer-lp-domain-qa-prod | **INCHANGÉ** |
| OW | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | **INCHANGÉ** |
| Manifest PROD modifié | -- | -- | **AUCUN** |
| DB PROD write | -- | -- | **AUCUN** |
| Stripe/billing/CAPI | -- | -- | **AUCUN** |

---

## Rollback DEV (non exécuté)

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.162-performance-sav-metrics-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev

# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.171-performance-sav-dashboard-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## Linear

| Ticket | Action | Statut |
|---|---|---|
| KEY-291 (AR.7) | DEV ready, tags documentés, tests prêts pour QA | **In Review** |
| KEY-282 (parent) | Commentaire AR.7 DEV ready | Non fermé |
| KEY-290 (AR.5 satisfaction) | -- | Non fermé |
| KEY-289 (AR.6 milestones) | -- | Non fermé |

---

## Gaps restants

1. **Tests fonctionnels manuels** : Ludovic doit tester en DEV sur `client-dev.keybuzz.io` :
   - Envoyer une réponse manuelle → vérifier `message_source=HUMAN` en DB
   - Utiliser Aide IA → insérer suggestion → envoyer → vérifier `message_source=AI_ASSISTED`
   - Valider un brouillon autopilot → envoyer → vérifier `message_source=AI_ASSISTED`
2. **PROD promotion** : hors scope AR.7, nécessite QA DEV validée
3. **AI_AUTOPILOT normalisé** : le chemin autopilot existant écrit `'autopilot'` (lowercase). Une normalisation future vers `AI_AUTOPILOT` est documentée mais non implémentée (pas de changement fonctionnel nécessaire).
4. **Ventilation enrichie dans /stats/performance** : la query SQL de performance-stats pourrait être enrichie pour compter explicitement `AI_ASSISTED` vs `HUMAN` dans les KPIs. Actuellement le fallback `ai_action_log` reste actif pour les messages legacy.

---

## Conclusion

MESSAGE_SOURCE ENRICHMENT READY IN DEV — FUTURE OUTBOUND REPLIES DISTINGUISH HUMAN / AI_ASSISTED WHEN AI SUGGESTION OR DRAFT IS USED — AUTOPILOT PATH ALREADY WRITES 'autopilot' CORRECTLY — LEGACY MESSAGES PRESERVED — NO DESTRUCTIVE BACKFILL — AUTHOR_NAME / AUTO_ASSIGNMENT / NO_REASK / LIFECYCLE BASELINES PRESERVED — DASHBOARD PERFORMANCE SAV SOURCE TRUTH IMPROVED — NO AUTO_SEND ADDED — NO FAKE METRICS — NO DB PROD MUTATION — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC QA THEN PROD PROMOTION
