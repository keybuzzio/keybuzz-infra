# PH-T8.7A — Audit Tenant Flow Marketing

> Date : 22 avril 2026
> Branche : `ph147.4/source-of-truth`
> Commit audité : `db14cb03`

---

## A. Attribution Signup (`signup_attribution`)


| Critère                    | Résultat                                                                                                                                           |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tenant_id` présent ?      | **OUI** — colonne TEXT, NOT NULL implicite                                                                                                         |
| Source de création         | `tenant-context-routes.ts` → `CreateSignup` (transaction)                                                                                          |
| Relation                   | `tenant_id` est le canonical ID du tenant créé dans la même transaction                                                                            |
| Explicite ou reconstruit ? | **Explicite** — injecté directement lors de l'INSERT                                                                                               |
| Colonnes clés              | `tenant_id`, `user_email`, UTMs, click IDs (gclid, fbclid, fbc, fbp, ttclid), `landing_url`, `referrer`, `stripe_session_id`, `conversion_sent_at` |
| Ambiguïté                  | **Aucune**                                                                                                                                         |
| Correctif                  | **Aucun**                                                                                                                                          |


### Flux complet

1. Client envoie `POST /auth/create-signup` avec `attribution` dans le body
2. Backend crée user + tenant + user_tenants dans une transaction
3. `signup_attribution` reçoit le `tenant_id` du tenant fraîchement créé
4. Ultérieurement, `stripe_session_id` est linkée via `UPDATE` dans `billing/routes.ts`
5. L'emitter lit l'attribution via `SELECT FROM signup_attribution WHERE tenant_id = $1`

---

## B. Events Outbound (StartTrial / Purchase)

### StartTrial


| Critère            | Résultat                                                           |
| ------------------ | ------------------------------------------------------------------ |
| Origine            | `handleCheckoutCompleted()` dans `billing/routes.ts`               |
| `tenant_id` source | `session.metadata?.tenant_id` (Stripe checkout metadata)           |
| Fiable ?           | **OUI** — défini à la création de la session Stripe par le backend |
| Payload externe    | `customer.tenant_id` = valeur explicite                            |
| Idempotence key    | `conv_${tenantId}_StartTrial_${subId}` — inclut tenant             |


### Purchase


| Critère            | Résultat                                                                                |
| ------------------ | --------------------------------------------------------------------------------------- |
| Origine            | `handleSubscriptionChange()` dans `billing/routes.ts`                                   |
| `tenant_id` source | `subscription.metadata?.tenant_id` OU résolu via `billing_customers.stripe_customer_id` |
| Fiable ?           | **OUI** — double source avec fallback DB                                                |
| Payload externe    | `customer.tenant_id` = valeur explicite                                                 |
| Idempotence key    | `conv_${tenantId}_Purchase_${subId}` — inclut tenant                                    |


### Emitter (`emitter.ts`)


| Critère              | Résultat                                                           |
| -------------------- | ------------------------------------------------------------------ |
| `tenantId` paramètre | **Explicite** — passé comme argument de `emitOutboundConversion()` |
| Test exclusion       | Via `tenant_billing_exempt WHERE tenant_id = $1`                   |
| Destinations         | Via `getActiveDestinations(pool, tenantId)` — requête par tenant   |
| Attribution          | Via `signup_attribution WHERE tenant_id = $1`                      |
| Payload final        | `customer.tenant_id` toujours présent                              |


**Conclusion B** : Les events sont déjà tenant-native de bout en bout. Le `tenant_id` est explicite, fiable, et présent dans chaque couche.

---

## C. Metrics (`/metrics/overview`)


| Critère               | Résultat AVANT patch                                       |
| --------------------- | ---------------------------------------------------------- |
| Accepte `tenant_id` ? | **NON** — endpoint global uniquement                       |
| Customers             | Requête globale sur `tenants` — aucun filtre tenant        |
| Conversion rate       | Requête globale sur `billing_subscriptions` — aucun filtre |
| Revenue (MRR)         | Requête globale — aucun filtre                             |
| Ad spend              | Table `ad_spend` — **pas de colonne tenant_id**            |
| CAC / ROAS            | Calculés à partir de spend global / customers globaux      |



| Critère               | Résultat APRÈS patch (PH-T8.7A)                   |
| --------------------- | ------------------------------------------------- |
| Accepte `tenant_id` ? | **OUI** — query param optionnel                   |
| Mode global           | `scope: 'global'` quand pas de `tenant_id`        |
| Mode tenant           | `scope: 'tenant'` avec filtre SQL conditionnel    |
| Ad spend              | Reste global (pas de `tenant_id` dans `ad_spend`) |
| Backward compatible   | **OUI** — comportement identique sans `tenant_id` |


**Limitation connue** : `ad_spend` est global par nature (dépense publicitaire totale, pas par tenant). Le CAC/ROAS restent globaux même en mode tenant-scoped. Pour un CAC par tenant, il faudrait une attribution tenant-level de la dépense (phase future).

---

## D. Destinations Outbound (`outbound_conversion_destinations`)


| Critère                          | Résultat                                                     |
| -------------------------------- | ------------------------------------------------------------ |
| `tenant_id` sur la table         | **OUI** — colonne TEXT                                       |
| Sélection par tenant             | `WHERE tenant_id = $1 AND is_active = true`                  |
| Events envoyés portent le tenant | **OUI** — `customer.tenant_id` dans le payload               |
| RBAC                             | Via `user_tenants` — vérifie que l'user appartient au tenant |
| Cross-tenant leakage             | **Impossible** — chaque requête est scopée par tenant_id     |
| Logs cohérents                   | Via `destination_id` → destination → `tenant_id`             |
| Idempotence                      | Clé inclut `tenantId` — pas de collision inter-tenant        |


---

## Tableau Récapitulatif


| Composant              | `tenant_id` présent ? | Source de vérité                                                 | Ambiguïté ?      | Correctif nécessaire ? |
| ---------------------- | --------------------- | ---------------------------------------------------------------- | ---------------- | ---------------------- |
| `signup_attribution`   | OUI                   | Canonical tenant ID (création)                                   | NON              | NON                    |
| StartTrial event       | OUI                   | `session.metadata.tenant_id` (Stripe)                            | NON              | NON                    |
| Purchase event         | OUI                   | `subscription.metadata.tenant_id` + fallback `billing_customers` | NON              | NON                    |
| Emitter payload        | OUI                   | Paramètre explicite `tenantId`                                   | NON              | NON                    |
| Emitter destinations   | OUI                   | `outbound_conversion_destinations.tenant_id`                     | NON              | NON                    |
| Emitter test exclusion | OUI                   | `tenant_billing_exempt.tenant_id`                                | NON              | NON                    |
| `/metrics/overview`    | **NON → OUI**         | N/A → query param `tenant_id`                                    | **OUI → NON**    | **OUI — FAIT**         |
| `ad_spend`             | NON                   | Table globale (pas de tenant)                                    | OUI (par design) | Phase future           |
| Destinations RBAC      | OUI                   | `user_tenants`                                                   | NON              | NON                    |
| Delivery logs          | OUI (indirect)        | Via `destination_id`                                             | NON              | NON                    |
| `conversion_events`    | OUI                   | `event_id` inclut tenant                                         | NON              | NON                    |


---

## Source de Vérité Officielle

**La source de vérité tenant marketing officielle est le `tenant_id` canonical (ex: `ecomlg-001`), utilisé dans :**

1. `signup_attribution.tenant_id` — attribution à la création
2. `session.metadata.tenant_id` — checkout Stripe
3. `emitOutboundConversion(eventName, tenantId, ...)` — paramètre explicite
4. `outbound_conversion_destinations.tenant_id` — destinations scopées
5. `conversion_events.tenant_id` — idempotence
6. `/metrics/overview?tenant_id=X` — métriques filtrées

**Règle unique** : tout événement marketing est rattaché au `tenant_id` canonical via la chaîne signup → Stripe metadata → emitter → destination → logs.