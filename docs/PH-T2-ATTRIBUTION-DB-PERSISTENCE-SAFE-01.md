# PH-T2-ATTRIBUTION-DB-PERSISTENCE-SAFE-01 — Rapport

> Date : 2026-04-16
> Environnement : DEV uniquement
> Image deployee : `ghcr.io/keybuzzio/keybuzz-api:v3.5.48-tracking-t2-dev`
> Commit API : `383fa824` sur `ph147.4/source-of-truth`

---

## Objectif

Persister les donnees d'attribution marketing en base de donnees
au moment de la creation du tenant (signup), pour relier
attribution → utilisateur → paiement.

---

## Table creee : `signup_attribution`

```sql
CREATE TABLE signup_attribution (
  id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id           TEXT NOT NULL,
  user_email          TEXT NOT NULL,
  utm_source          TEXT,
  utm_medium          TEXT,
  utm_campaign        TEXT,
  utm_term            TEXT,
  utm_content         TEXT,
  gclid               TEXT,
  fbclid              TEXT,
  fbc                 TEXT,
  fbp                 TEXT,
  gl_linker           TEXT,
  plan                TEXT,
  cycle               TEXT,
  landing_url         TEXT,
  referrer            TEXT,
  attribution_id      TEXT,
  stripe_session_id   TEXT,          -- PH-T3 : rempli lors du checkout Stripe
  conversion_sent_at  TIMESTAMPTZ,   -- PH-T5 : timestamp webhook CAPI
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_signup_attribution_tenant ON signup_attribution(tenant_id);
CREATE INDEX idx_signup_attribution_created ON signup_attribution(created_at);
```

### Colonnes reservees (futures phases)


| Colonne              | Phase | Usage                                   |
| -------------------- | ----- | --------------------------------------- |
| `stripe_session_id`  | PH-T3 | Lie l'attribution au checkout Stripe    |
| `conversion_sent_at` | PH-T5 | Timestamp envoi webhook CAPI/Addingwell |


---

## Modifications

### 1. Client (`app/register/page.tsx`) — DEJA FAIT (PH-T1)

Le client envoie deja `attribution` dans le payload `create-signup` (ligne 208).
Aucune modification necessaire.

### 2. BFF (`app/api/auth/create-signup/route.ts`) — AUCUNE MODIFICATION

Le BFF fait un `JSON.stringify(body)` transparent (ligne 26).
L'attribution est forwardee telle quelle au backend.

### 3. API (`src/modules/auth/tenant-context-routes.ts`)

Ajout d'un bloc SAVEPOINT `sp_attribution` apres `sp_wallet`, avant le `COMMIT`.

```typescript
// PH-T2: Persist marketing attribution (non-blocking)
const attribution = body.attribution;
if (attribution && typeof attribution === 'object') {
  await client.query('SAVEPOINT sp_attribution');
  try {
    await client.query(
      `INSERT INTO signup_attribution (
        tenant_id, user_email,
        utm_source, utm_medium, utm_campaign, utm_term, utm_content,
        gclid, fbclid, fbc, fbp, gl_linker,
        plan, cycle, landing_url, referrer,
        attribution_id
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)`,
      [
        tenantId, emailLower,
        attribution.utm_source || null,
        attribution.utm_medium || null,
        attribution.utm_campaign || null,
        attribution.utm_term || null,
        attribution.utm_content || null,
        attribution.gclid || null,
        attribution.fbclid || null,
        attribution.fbc || null,
        attribution.fbp || null,
        attribution._gl || null,
        attribution.plan || null,
        attribution.cycle || null,
        attribution.landing_url || null,
        attribution.referrer || null,
        attribution.id || null,
      ]
    );
    console.log(`[CreateSignup] Attribution persisted for tenant ${tenantId}`);
  } catch (attrErr: any) {
    await client.query('ROLLBACK TO SAVEPOINT sp_attribution');
    console.warn('[CreateSignup] signup_attribution insert skipped:', attrErr.message?.substring(0, 80));
  }
}
```

### Garanties de securite


| Garantie                              | Implementation                                        |
| ------------------------------------- | ----------------------------------------------------- |
| Non-bloquant                          | SAVEPOINT + ROLLBACK TO SAVEPOINT si erreur           |
| Pas de crash sans attribution         | `if (attribution && typeof attribution === 'object')` |
| Pas de modification tables existantes | Nouvelle table dediee uniquement                      |
| Multi-tenant strict                   | `tenant_id` obligatoire dans l'INSERT                 |
| Pas de dependance forte               | Le signup reussit meme si l'INSERT attribution echoue |


---

## Tests de validation

### Test 1 : Signup AVEC attribution

```
POST /tenant-context/create-signup
X-User-Email: test-tracking-t2@keybuzz-test.io
Body: { name, plan, attribution: { utm_source: "google", gclid: "test-gclid-abc123", ... } }

Resultat : HTTP 201
Log API : "[CreateSignup] Attribution persisted for tenant test-ph-t2-attributi-mo20y99z"
DB : 1 row dans signup_attribution avec toutes les colonnes remplies
```

### Test 2 : Signup SANS attribution

```
POST /tenant-context/create-signup
X-User-Email: test-tracking-t2-noattr@keybuzz-test.io
Body: { name, plan }  (pas de cle attribution)

Resultat : HTTP 201
Log API : "[CreateSignup] Created tenant test-ph-t2-no-attrib-mo20y9m0"
DB : 0 row dans signup_attribution pour ce tenant (attendu)
```

### Test 3 : Verification DB

```sql
SELECT tenant_id, user_email, utm_source, utm_medium, utm_campaign,
       gclid, fbp, gl_linker, attribution_id, plan, cycle, landing_url
FROM signup_attribution;

-- 1 row avec toutes les valeurs attendues
-- utm_source=google, utm_medium=cpc, utm_campaign=launch-2026
-- gclid=test-gclid-abc123, fbp=fb.1.1234567890.987654321
-- gl_linker=1*abc123*_ga*MTIzNDU2, attribution_id=test-uuid-ph-t2-001
```

Donnees de test nettoyees apres validation.

---

## Deploiement


| Element      | Valeur                                                  |
| ------------ | ------------------------------------------------------- |
| Image API    | `ghcr.io/keybuzzio/keybuzz-api:v3.5.48-tracking-t2-dev` |
| Namespace    | `keybuzz-api-dev`                                       |
| Commit       | `383fa824`                                              |
| Pod status   | `Running 1/1`                                           |
| Health check | `{"status":"ok"}`                                       |


---

## Rollback

```bash
# Image precedente
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.47-vault-tls-fix-dev -n keybuzz-api-dev

# Table (optionnel, non destructif de la garder)
DROP TABLE IF EXISTS signup_attribution;
```

---

## Flux complet (PH-T1 + PH-T2)

```
1. User arrive sur /register?utm_source=google&utm_medium=cpc&gclid=xxx
2. Client: initAttribution() capture UTMs + click IDs + GA4 linker + Meta fbc
3. Client: stocke dans sessionStorage + localStorage backup (30 min TTL)
4. Client: handleUserSubmit() → POST /api/auth/create-signup { ..., attribution }
5. BFF: forward transparent → POST /tenant-context/create-signup
6. API: cree user + tenant + metadata + wallet
7. API: INSERT signup_attribution (tenant_id, utm_source, gclid, fbp, ...)
8. DB: row persistee avec attribution_id unique → prete pour lien Stripe
```

---

## Prochaine phase

**PH-T3** : Lier `stripe_session_id` a `signup_attribution`
lors de la creation de la Checkout Session Stripe.
Cela completera le lien attribution → paiement.

---

## Verdict

**ATTRIBUTION PERSISTED IN DB — READY FOR STRIPE LINK**