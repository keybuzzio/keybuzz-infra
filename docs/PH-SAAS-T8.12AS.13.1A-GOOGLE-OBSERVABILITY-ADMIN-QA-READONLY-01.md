# PH-SAAS-T8.12AS.13.1A-GOOGLE-OBSERVABILITY-ADMIN-QA-READONLY-01

> Date : 2026-05-14
> Linear : KEY-313 (R1 outbound+compat surfaces tenantGuard extension)
> Phase : PH-SAAS-T8.12AS.13.1A QA read-only Admin v2 consumer apres patch AS.13.1 API DEV
> Environnement : DEV (Admin v2 + API). PROD strictement non touchee.

---

## VERDICT

GO GOOGLE OBSERVABILITY ADMIN QA READY

Le patch AS.13.1 (KEY-313) applique au runtime API DEV v3.5.187-google-observability-tenantguard-dev n introduit aucune regression du consumer legitime Admin v2 marketing google-tracking. Les trois roles d injection prevus (super_admin / account_manager / media_buyer) bypassent correctement la verification user_tenants ; les autres roles globaux (ops_admin) sont refuses comme attendu ; un role membre legitime (owner / admin) avec tenantId concordant passe le checkAccess. Le scope filter signup_attribution applique : un tenantId fictif renvoie counts a zero et last_gclid / last_conversion null (preuve absence de leak aggregate). PROD inchangee.

---

## 1. Preflight runtime

| Surface | Image runtime | Etat | Note |
|---|---|---|---|
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-dev | A jour | Post patch AS.13.1 KEY-313. Digest sha256:9cfd946c593b464936e81cbc9876ea7acdff5206178408588e1674a9ccb96104. OCI revision 1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c. |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.186-ai-rules-mut-tenantguard-prod | Inchangee | Aucun apply / set / patch / edit. Verifie via kubectl get deploy. |
| Admin v2 DEV | ghcr.io/keybuzzio/keybuzz-admin-v2:v2.12.2-media-buyer-lp-domain-qa-dev | Inchangee | Pod ready=true restartCount=0. |
| Admin v2 PROD | ghcr.io/keybuzzio/keybuzz-admin-v2:v2.12.2-media-buyer-lp-domain-qa-prod | Inchangee | Aucune mutation. |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.196-ai-rules-bff-dev | Inchangee | Hors scope direct (consumer Admin v2 uniquement). |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.196-ai-rules-bff-prod | Inchangee | Hors scope. |
| Ingress Admin v2 DEV | admin-dev.keybuzz.io | OK | Confirme via kubectl get ingress. |

Aucun docker push, aucun kubectl apply, aucun build, aucun patch source effectue dans cette phase.

---

## 2. Audit source : chain Admin v2 -> API alignee

### 2.1 Page Admin v2 (consumer)

Fichier : keybuzz-admin-v2/src/app/(admin)/marketing/google-tracking/page.tsx

- Hook tenant : useCurrentTenant() (selecteur Admin v2 marketing).
- Appel reseau : fetch('/api/admin/marketing/google-observability?tenantId=<id>&scope=owner').
- Aucune injection client-side de role ; tous les headers sensibles passent par la BFF.

### 2.2 BFF Admin v2 (proxy authentifie)

Fichier : keybuzz-admin-v2/src/app/api/admin/marketing/google-observability/route.ts

Sequence : NextAuth getServerSession -> requireMarketing(session) -> assertTenantAccess(session, tenantId) -> buildHeaders -> fetch API DEV.

Headers sortants vers API : x-user-email, x-tenant-id, x-admin-role.

Fichier : keybuzz-admin-v2/src/app/api/admin/marketing/proxy.ts

- MARKETING_ROLES = ['super_admin', 'account_manager', 'media_buyer']
- GLOBAL_ROLES (bypass user_tenants) = ['super_admin', 'ops_admin']
- requireMarketing renvoie 403 si role hors MARKETING_ROLES.
- assertTenantAccess autorise GLOBAL_ROLES sans verifier user_tenants, sinon JOIN user_tenants.

### 2.3 API checkAccess (cible du patch AS.13.1)

Fichier : keybuzz-api/src/modules/outbound-conversions/google-observability.ts

- ALLOWED_ROLES = ['owner', 'admin']
- ADMIN_BYPASS_ROLES = ['super_admin', 'account_manager', 'media_buyer']
- Sequence handler : x-user-email + tenantId requis (400 sinon) -> checkAccess (403 sinon) -> SELECT scope tenantId.

### 2.4 Alignement chain

ADMIN_BYPASS_ROLES API = MARKETING_ROLES Admin v2 (exact match).
=> Tout role legitime Admin v2 marketing passe sans toucher user_tenants. Le consumer prevu reste fonctionnel a 100 pour cent.

---

## 3. Probes runtime read-only DEV (aucune mutation)

Toutes les requetes envoyees a https://api-dev.keybuzz.io/api/v3/outbound-conversions/google-observability avec headers x-user-email (ludo.gonthier@gmail.com), x-tenant-id (fictif pour preuve absence de leak), x-admin-role variable, query scope=owner.

| Cas | x-admin-role | Resultat HTTP | Verdict |
|---|---|---|---|
| Admin marketing 1 | super_admin | 200 | Bypass attendu OK |
| Admin marketing 2 | account_manager | 200 | Bypass attendu OK |
| Admin marketing 3 | media_buyer | 200 | Bypass attendu OK |
| Role hors marketing | ops_admin | 403 Insufficient permissions | Refus attendu OK |
| Headers absents (sanity) | - | 400 Missing x-user-email or x-tenant-id | Refus attendu OK |

### 3.1 Sample response body (tenantId fictif, scope=owner)

```
{
  "google_observability": {
    "gclid_count": 0,
    "google_utm_count": 0,
    "conversions_sent": 0,
    "total_signups": 0,
    "last_gclid": null,
    "last_conversion_sent": null,
    "transport": "addingwell_sgtm",
    "data_source": "signup_attribution"
  }
}
```

Lecture : avec tenantId fictif, le filter SQL WHERE (marketing_owner_tenant_id = $1 OR tenant_id = $1) renvoie zero ligne. Counts a zero, last_gclid et last_conversion_sent a null. Aucun leak aggregate cross-tenant.

Comparaison qualitative avec l etat pre-patch (consultee dans le rapport AS.13.0) : sans tenantId, le filter etait absent et le handler renvoyait des counts agreges sur signup_attribution toutes lignes confondues plus la derniere ligne reelle (gclid_prefix, tenant_id, owner_tenant_id) en clair. Cette surface est desormais fermee : sans header ou sans tenantId la requete retourne 400, avec tenantId non concordant et role non bypass elle retourne 403, avec tenantId fictif et role bypass elle retourne un payload vide.

---

## 4. QA Admin v2 navigateur (validation Ludovic)

URL : https://admin-dev.keybuzz.io/marketing/google-tracking

Confirmation Ludovic dans la conversation courante : "OK : QA Admin v2 DEV validee sur https://admin-dev.keybuzz.io. Page marketing google-tracking charge avec role autorise. Aucune erreur visible, pas de 403/500. Stats visibles ou vides selon donnees DEV, mais page fonctionnelle. Aucune action mutationnelle effectuee."

Lecture : la chain end-to-end Admin v2 -> BFF -> API DEV v3.5.187 fonctionne pour les roles d injection prevus. Aucun spike 403 / 500 / TypeError cote navigateur.

---

## 5. Logs runtime 5 minutes

### 5.1 API DEV

Plage : derniere fenetre de 5 minutes apres les probes.
Filtre : statusCode >= 500 ou url contient google-observability.
Resultat : 0 ligne 5xx. Les hits 200 / 403 / 400 attendus apparaissent avec leur HTTP code correct, sans stack trace.

### 5.2 Admin v2 DEV

Pod : ready=true, restartCount=0 sur la derniere fenetre. Aucun crash, aucune erreur critique dans stdout/stderr. Logs filtres sur "google-observability" : 0 erreur, traffic conforme aux probes.

---

## 6. PROD non touchee

| Surface | Image runtime PROD | Etat | Action effectuee |
|---|---|---|---|
| API PROD | v3.5.186-ai-rules-mut-tenantguard-prod | Inchangee | Aucune |
| Admin v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod | Inchangee | Aucune |
| Client PROD | v3.5.196-ai-rules-bff-prod | Inchangee | Aucune |

Aucun docker push, aucun kubectl apply, aucun set / edit / patch, aucune mutation namespace *-prod. PROD est strictement read-only pour cette sous-phase AS.13.1A.

---

## 7. Disclosure-controlled : pas de PoC, pas de payload reproducible

Conformement aux regles de cette phase aucun extrait suivant n est inclus dans ce rapport ni ne sera publie en commentaire Linear :
- Aucun payload curl complet avec tenantId reel.
- Aucun gclid reel, aucun gclid_prefix de production.
- Aucun email client reel.
- Aucun token interne ni secret.
- Aucun draftText IA, aucun corps de message client.
- Aucun snippet exploit reutilisable.

Le rapport documente uniquement la presence et l alignement du controle d acces ; les exemples curl sont volontairement reduits a la forme generique (headers attendus, codes HTTP, schema de reponse vide).

---

## 8. Linear KEY-313 (texte propose, disclosure-controlled)

A coller en commentaire si Ludovic donne le GO Linear separe (aucun changement de statut sans GO).

```
PH-SAAS-T8.12AS.13.1A QA read-only Admin v2 consumer apres AS.13.1 DEV.

Resultat : aucune regression du consumer Admin v2 marketing google-tracking apres le patch tenantGuard applique au runtime API DEV (v3.5.187-google-observability-tenantguard-dev).

Probes runtime DEV (read-only, aucune mutation, aucun PoC publie) :
- super_admin : 200
- account_manager : 200
- media_buyer : 200
- ops_admin : 403 (attendu)
- Headers absents : 400 (attendu)
- tenantId fictif + role bypass : payload vide (counts 0, last_gclid null, last_conversion null)

QA navigateur https://admin-dev.keybuzz.io/marketing/google-tracking confirme par owner : page charge, aucune erreur, aucune mutation declenchee.

PROD strictement inchangee. Aucun apply, aucun push, aucun build dans cette phase. KEY-313 reste Open. Promotion AS.13.1-PROD requiert un GO Ludovic explicite.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.1A-GOOGLE-OBSERVABILITY-ADMIN-QA-READONLY-01.md
```

---

## 9. Gaps restants

- AS.13.1-PROD (promotion API PROD du patch google-observability) : en attente GO Ludovic explicite. Pre-requis : KEY-308 OCI labels OK, KEY-309 tag immuable OK, KEY-302 sentinel absent (hors scope client), rollback prepare vers v3.5.186-ai-rules-mut-tenantguard-prod.
- AS.13.2 outbound/deliveries (5 endpoints read + 3 mutations) : design audit a faire avant patch.
- AS.13.3 compat module (6 endpoints, proxy legacy) : design audit pendant.
- AS.13.4 destinations confirmatif : probable 0 patch (pattern checkAccess deja en place), audit a documenter quand meme.

---

## 10. Verdicts autorises

- GO GOOGLE OBSERVABILITY ADMIN QA READY (verdict retenu)
- NO GO ADMIN CONSUMER REGRESSION FOUND

---

## 11. Phrase cible finale

GO GOOGLE OBSERVABILITY ADMIN QA READY. KEY-313 reste Open. Promotion API PROD requiert un GO Ludovic explicite et separe.

STOP. Aucun enchainement vers PROD sans GO Ludovic.
