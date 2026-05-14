# PH-SAAS-T8.12AS.13.4A-KEY-313-LINEAR-CLOSEOUT-01

> Date : 2026-05-14
> Linear : KEY-313 (closeout) ; suivi KEY-319 KEY-320 KEY-321
> Phase : T8.12AS.13.4A
> Environnement : docs-only (aucun changement code/build/deploy/DB/manifests/runtime)

---

## 0. VERDICT

GO KEY-313 CLOSED WITH FOLLOW-UP BACKLOG READY.

KEY-313 (R1 outbound + compat surfaces tenantGuard extension) ferme. Tous les sous-tickets R1 livres et confirmes : 18 endpoints proteges sur 4 sous-phases (AS.13.1 / AS.13.2A / AS.13.3A / AS.13.4). Trois tickets de suivi disclosure-controlled crees et lies a KEY-313 pour suite. KEY-301 reste Done sans modification. KEY-312 reste separe comme ticket produit hors perimetre security.

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Phase docs-only de cloture administrative KEY-313. Aucune modification de code, image, manifest, runtime, base de donnees, secrets ou configuration. Aucun appel build, push, GitOps ou kubectl. Seules actions :

- Creation 3 tickets Linear de suivi (R2.2, R3, U2) lies a KEY-313.
- Commentaire closeout KEY-313 (recap R1 + lien rapports + recommandation backlog).
- Transition KEY-313 vers Done.
- Redaction et publication de ce rapport docs-only.

Toutes les operations Linear ont ete executees directement via outils Linear cote operateur, token jamais affiche dans la conversation, conformement a la regle reference_linear_token.

---

## 2. RECAP R1 SURFACES FERMEES (18 ENDPOINTS PROTEGES)

| Sous-phase | Surface | Endpoints | Pattern applique | Statut |
|---|---|---|---|---|
| AS.13.1 | google-observability | 1 | checkAccess local owner/admin + admin-bypass | Done DEV + PROD (v3.5.186 / v3.5.187) |
| AS.13.2A | outbound/deliveries | 5 (2 reads + 3 mutations) | tenantGuard matchers dynamiques | Done DEV + PROD (v3.5.188) |
| AS.13.3A | compat Amazon legacy proxy | 6 (status / disconnect / oauth-start GET+POST / inbound-address GET+POST) | tenantGuard PROTECTED_ROUTES static | Done DEV + PROD (v3.5.189) |
| AS.13.4 | outbound-conversions/destinations | 6 (list / create / patch / test / delete / logs) | checkAccess local deja en place | Audit only, 0 patch |
| Total R1 | 4 surfaces | 18 endpoints | 2 patterns complementaires | 100 pourcent ferme |

Toutes les protections operationnelles AS.12 (AI, autopilot, notifications, tenants) restent preservees a l identique. Aucune regression detectee sur les probes negatifs DEV + PROD.

Rapports de reference (tous deja commit + push sur keybuzz-infra main) :

- AS.13.1 PROD : docs/PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-PROD-01.md
- AS.13.2 audit : docs/PH-SAAS-T8.12AS.13.2-R1-OUTBOUND-DELIVERIES-TENANTGUARD-DESIGN-AUDIT-01.md
- AS.13.2A DEV : docs/PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-DEV-01.md
- AS.13.2A PROD : docs/PH-SAAS-T8.12AS.13.2A-R1-OUTBOUND-DELIVERIES-TENANTGUARD-HARDENING-PROD-01.md
- AS.13.3 audit : docs/PH-SAAS-T8.12AS.13.3-R1-COMPAT-AMAZON-TENANTGUARD-DESIGN-AUDIT-01.md
- AS.13.3A DEV : docs/PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-DEV-01.md
- AS.13.3A PROD : docs/PH-SAAS-T8.12AS.13.3A-R1-COMPAT-AMAZON-TENANTGUARD-HARDENING-PROD-01.md
- AS.13.4 confirmation : docs/PH-SAAS-T8.12AS.13.4-R1-DESTINATIONS-CHECKACCESS-CONFIRMATION-AUDIT-01.md
- Ce rapport : docs/PH-SAAS-T8.12AS.13.4A-KEY-313-LINEAR-CLOSEOUT-01.md

---

## 3. TICKETS DE SUIVI CREES (DISCLOSURE-CONTROLLED)

Les trois tickets ont ete crees sous l organisation keybuzz, lies a KEY-313 comme suivi, sans PoC, sans payload reproductible, sans PII, sans secret, sans recette d exploit. Chacun decrit la surface, la justification et la classe d action recommandee uniquement.

| Code | Identifier | Priorite | Titre | Lien KEY-313 |
|---|---|---|---|---|
| R2.2 | KEY-319 | High | tenantGuard defense-in-depth outbound deliveries UPDATE tenant scope | Linked to KEY-313 |
| R3 | KEY-320 | High | tenantGuard backend defense-in-depth compat Amazon (segmentation + token rotation) | Linked to KEY-313 |
| U2 | KEY-321 | Medium | tenantGuard surveiller les 401/403 compat Amazon post-hardening | Linked to KEY-313 |

URLs :

- KEY-319 : https://linear.app/keybuzz/issue/KEY-319/tenantguard-defense-in-depth-outbound-deliveries-update-tenant-scope
- KEY-320 : https://linear.app/keybuzz/issue/KEY-320/tenantguard-backend-defense-in-depth-compat-amazon
- KEY-321 : https://linear.app/keybuzz/issue/KEY-321/tenantguard-surveiller-les-401403-compat-amazon-post-hardening

### 3.1 R2.2 (KEY-319) defense-in-depth outbound UPDATEs

Surface : outbound_deliveries UPDATE (simulate-deliver / fail / retry).

Justification : actuellement la protection 403 d acces multi-tenant est garantie par tenantGuard a l entree (matcher dynamique AS.13.2A). En defense-in-depth, ajouter une clause AND tenant_id = $X dans les requetes SQL UPDATE limiterait toute mutation a la ligne du tenant courant meme en cas de bug ou bypass amont. Pattern deja deploye sur les SELECT/INSERT du module.

Action proposee : extension WHERE clause sur 3 endpoints UPDATE existants + tests negatifs cross-tenant. Pas de migration DB. Pas de patch routes. Estimation : 1 sous-phase courte (DEV + PROD).

### 3.2 R3 (KEY-320) backend defense-in-depth compat Amazon

Surface : keybuzz-backend Node legacy (cible de proxy compat Amazon).

Justification : tenantGuard cote keybuzz-api ferme l acces sur les 6 endpoints AS.13.3A, mais le backend lui-meme accepte des requetes signees par X-Internal-Token sans separation reseau forte. En defense-in-depth :

- Segmenter le NetworkPolicy backend pour n autoriser que keybuzz-api comme client.
- Rotation periodique de KEYBUZZ_INTERNAL_PROXY_TOKEN (procedure et secret K8s versionne).
- Audit des routes legacy backend pour exposition tenant.

Action proposee : 1 phase infra GitOps + 1 phase audit source backend. Sans impact runtime utilisateur si NetworkPolicy applique apres validation des selectors.

### 3.3 U2 (KEY-321) surveillance logs PROD compat Amazon

Surface : observabilite production post AS.13.3A.

Justification : les 6 endpoints compat Amazon sont desormais proteges par tenantGuard. Mettre en place une surveillance des 401 / 403 PROD pendant les 7 jours suivant la promotion (2026-05-14 ouverture fenetre) permet de detecter :

- Un consumer legitime mal aligne (BFF non observe a ce jour, mais a confirmer en runtime).
- Une integration tierce inconnue qui frapperait /api/v1/marketplaces/amazon/* sans header propre.
- Un pic anormal indiquant probing ou scan.

Action proposee : 1 dashboard kibana ou loki + 1 alerte simple. Estimation : 1 sous-phase tres courte.

---

## 4. COMMENTAIRE CLOSEOUT KEY-313

Le commentaire de cloture a ete poste sur KEY-313 a partir de la section 9 du rapport AS.13.4 (verbatim, ASCII strict, disclosure-controlled). Lien permanent :

https://linear.app/keybuzz/issue/KEY-313/tenantguard-securiser-outbound-compat-proxy#comment-ddeff1a7

Contenu (resume) : recap des 4 sous-phases, total 18 endpoints proteges, pattern checkAccess identique a AS.13.1 sur destinations sans patch necessaire, probes negatifs DEV + PROD confirmes 400/403, DB inchangee, 0 provider call externe, preservations AS.12 + AS.13.1/2A/3A intactes, recommandation closeout sous GO Ludovic, mention des trois tickets de suivi proposes.

Aucune information sensible (PoC, payload, draftText, customer body, secret) dans le commentaire.

---

## 5. TRANSITION KEY-313 ET STATUT KEY-301

| Ticket | Statut precedent | Statut nouveau | Date transition | Acteur |
|---|---|---|---|---|
| KEY-313 | In Progress | Done | 2026-05-14 | Operateur via Linear API (token hors-chat) |
| KEY-301 | Done | Done (inchange) | n/a | Aucune action requise |
| KEY-312 | Open (ticket produit separe) | Open (inchange) | n/a | Hors perimetre security R1, non bloquant pour KEY-313 |
| KEY-319 | New | Open / Backlog | 2026-05-14 | Cree dans cette phase |
| KEY-320 | New | Open / Backlog | 2026-05-14 | Cree dans cette phase |
| KEY-321 | New | Open / Backlog | 2026-05-14 | Cree dans cette phase |

Transition KEY-313 effectuee uniquement apres validation de la creation des 3 tickets de suivi et apres redaction du commentaire closeout, conformement aux consignes Option C.

---

## 6. PROOF OF NO RUNTIME CHANGE

Aucune des operations suivantes n a ete declenchee dans cette phase :

| Operation | Statut |
|---|---|
| docker build | Non |
| docker push | Non |
| kubectl apply / set / patch / edit | Non |
| Modification manifest deployment / service / ingress | Non |
| Modification secret / configmap | Non |
| Migration ou ecriture DB applicative | Non |
| Trigger pipeline CI / cron / job | Non |
| Modification code source keybuzz-api / client / admin / backend / website | Non |

Seul artefact ecrit cote infrastructure : ce rapport markdown sous keybuzz-infra/docs/, commit + push sur main.

Images PROD live au moment du closeout : keybuzz-api v3.5.189-compat-amazon-tenantguard-prod (digest sha256:3d466c8ad3f3b3c9041f7155d17200a108f82e72d008769b12eceb997818854e). Inchange par cette phase.

---

## 7. LINEAR ETAT FINAL

| Champ | Valeur |
|---|---|
| KEY-313 etat | Done |
| KEY-313 commentaire closeout | https://linear.app/keybuzz/issue/KEY-313/tenantguard-securiser-outbound-compat-proxy#comment-ddeff1a7 |
| Tickets suivi crees | KEY-319, KEY-320, KEY-321 |
| Tickets suivi lies a KEY-313 | Oui (3 / 3) |
| KEY-301 | Done (inchange) |
| KEY-312 | Inchange, hors perimetre |
| Token | Jamais affiche dans la conversation |

---

## 8. GAPS RESTANTS APRES KEY-313

Trois axes de defense-in-depth sont desormais formalises dans le backlog (KEY-319, KEY-320, KEY-321). Aucun n est bloquant pour la promotion deja effectuee de R1 ; ils relevent du durcissement supplementaire et de l observabilite continue. Aucun gap critique ni de regression connue.

Le perimetre R2 (autres surfaces non explicitement listees dans R1) reste a inventorier dans une phase dediee si pertinent. Cette decision est differee et non bloquante.

---

## 9. PHRASE CIBLE FINALE

KEY-313 ferme proprement avec backlog de suivi disclosure-controlled (KEY-319 + KEY-320 + KEY-321) lie et commentaire de cloture publie. KEY-301 inchange. Aucun changement runtime. Rapport docs-only commit + push direct sur keybuzz-infra main. R1 outbound + compat surfaces tenantGuard extension entierement livre.

STOP
