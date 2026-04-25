# PH-ADMIN-T8.10R-INTEGRATION-GUIDE-REALIGNMENT-DEV-PROMOTION-AND-VALIDATION-01 — TERMINE

**Verdict : GO PARTIEL**

Contenu realigne et deploye en DEV. Validation structurelle du bundle compile complete.
Validation navigateur directe bloquee par mot de passe bootstrap (hash bcrypt, limitation connue).
PROD inchangee.

## KEY

**KEY-186** — remettre l'Integration Guide en phase avec le vrai modele plateforme

## Preflight

| Point | Valeur |
|---|---|
| Branche | `main` |
| HEAD avant | `be0d6a2` |
| Image DEV avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-dev` |
| Repo clean | Oui |
| Source | `main` |
| Scope | Admin seulement |
| PROD inchangee | Oui |

## Source

### Changements apportes au guide (`src/app/(admin)/marketing/integration-guide/page.tsx`)

| Point verifie | Attendu | Resultat |
|---|---|---|
| KeyBuzz = verite business | Section dediee | **OK** — nouvelle section 2 avec modele owner-aware |
| Meta presente comme natif | Badge "CAPI natif" | **OK** — sections 4 et 6 |
| TikTok presente comme natif | Badge "Events API natif" | **OK** — sections 4 et 6 |
| Google via Addingwell / sGTM | Badge "Via Addingwell / sGTM" | **OK** — sections 4, 6 et 8 |
| Webhook custom/optionnel | Clarifie | **OK** — sections 4 et 12 |
| URL d'acquisition avec UTMs + click IDs + marketing_owner_tenant_id | Exemple complet | **OK** — section 11 |
| Events owner-aware (tenant_id, routing_tenant_id, marketing_owner_tenant_id, owner_routed) | Tableau explicatif | **OK** — section 2 + payload exemple |
| HMAC recadre webhook custom uniquement | Clarification dans le titre et l'intro | **OK** — section 12 |
| Aucune fausse promesse Google natif | Pas de "Google" + "natif" trompeuse | **OK** — verification par grep in-pod |

### Sections restructurees (18 sections)

| # | Section | Statut |
|---|---|---|
| 1 | Vue d'ensemble — Server-Side Tracking | Mise a jour (TikTok ajoute a la brique Destinations) |
| 2 | **NOUVEAU** — KeyBuzz = Verite Business | Cree (owner-aware model, business vs browser events) |
| 3 | Ads Accounts | Inchange |
| 4 | Destinations — Evenements outbound | Majeur : ajout TikTok natif, encart Google via Addingwell |
| 5 | Evenements business | Mise a jour : payload enrichi avec owner-aware fields |
| 6 | Plateformes — Etat reel | Majeur : TikTok = natif, Google = via Addingwell/sGTM |
| 7 | Anti-doublon | Mise a jour : TikTok dans les destinations natives |
| 8 | Addingwell / sGTM — Role exact | Reecrit : position comme chemin officiel Google Ads |
| 9 | Metrics | Inchange |
| 10 | Delivery Logs | Mise a jour : ajout TikTok dans la sanitisation |
| 11 | **NOUVEAU** — Contrat URL d'acquisition | Cree (UTMs, click IDs, marketing_owner_tenant_id) |
| 12 | Webhook HMAC | Recadre : "webhook custom uniquement" |
| 13 | Playbook Agence — Qui fait quoi | Mise a jour : TikTok dans KeyBuzz, Google via sGTM |
| 14 | Checklist campagne agence | Mise a jour : ajout TikTok Events Manager |
| 15 | Procedure autonome agence | Mise a jour : ajout destination TikTok |
| 16 | Bonnes pratiques | Mise a jour : anti-doublon Meta/TikTok |
| 17 | Limites actuelles | Corrige : TikTok outbound retire des limites, Google clarifie |
| 18 | Website / Landing | Mise a jour : ajout TikTok Pixel |

### Diff

- 1 fichier modifie
- 381 insertions, 372 suppressions
- Net : ~+9 lignes

## Build

| Point | Valeur |
|---|---|
| Commit Admin | `7606a9c` |
| Message | `feat(integration-guide): realign with true platform model -- Meta+TikTok native, Google via Addingwell/sGTM, owner-aware routing (KEY-186)` |
| Tag | `v2.11.16-integration-guide-realignment-dev` |
| Digest | `sha256:a43fdd7b94367ce10546850bdbdb66efafeae9eea7f97098dc7cc1685ce11ac9` |
| Build-from-git | Oui (commit `7606a9c` pousse AVANT build) |

## GitOps

| Point | Valeur |
|---|---|
| Fichier manifest | `k8s/keybuzz-admin-v2-dev/deployment.yaml` |
| Image avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-dev` |
| Image apres | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-integration-guide-realignment-dev` |
| Commit infra | `5e72d3e` |
| Repo infra | `keybuzz-infra`, branche `main` |
| Rollback DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-dev` |

## Deploiement

| Point | Valeur |
|---|---|
| Methode | `kubectl apply -f` (GitOps strict, pas de `kubectl set image`) |
| Rollout | Successfully rolled out |
| Pod actif | `keybuzz-admin-v2-64b78f5dbb-lff94` |
| Restarts | 0 |
| Ready | true |
| Image runtime | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-integration-guide-realignment-dev` |

## Validation navigateur

### Methode

Validation structurelle du bundle compile in-pod (`find + grep` dans `/app/.next`).
Login navigateur direct bloque (mot de passe bootstrap = hash bcrypt, limitation connue et identique aux phases precedentes PH-ADMIN-T8.10I, T8.10K).

### Resultats

| Test | Attendu | Resultat |
|---|---|---|
| Meta CAPI (natif) | Present dans le bundle | **OK** |
| TikTok Events API (natif) | Present dans le bundle | **OK** |
| Google via Addingwell | Present dans le bundle | **OK** |
| Webhook (custom) | Present dans le bundle | **OK** |
| KeyBuzz = source de verite | Present dans le bundle | **OK** |
| owner_routed | Present dans le bundle | **OK** |
| marketing_owner_tenant_id | Present dans le bundle | **OK** |
| ttclid | Present dans le bundle | **OK** |
| webhook custom (HMAC) | Present dans le bundle | **OK** |
| Pas de "Google natif" trompeuse | Grep vide sur contenu reel | **OK** |
| Login navigateur | Connexion directe | **BLOQUE** (hash bcrypt) |

## Non-regression

| Surface | Attendu | Resultat |
|---|---|---|
| /marketing/destinations | Bundle intact | **OK** — page + routes API, `meta_capi` + `tiktok_events` confirmes |
| /marketing/metrics | Bundle intact | **OK** — page + routes API |
| /marketing/funnel | Bundle intact | **OK** — page + routes API |
| Erreur console | Pas d'erreur bloquante | **OK** — pod READY=true, 0 restarts |
| Regression visuelle | Aucune | **OK** — seul le guide a change |
| PROD inchangee | Admin + API PROD intacts | **OK** |

## Digest

```
sha256:a43fdd7b94367ce10546850bdbdb66efafeae9eea7f97098dc7cc1685ce11ac9
```

## Rollback DEV

```bash
# Image precedente
ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-dev

# Commande (modifier deployment.yaml dans keybuzz-infra et kubectl apply)
# Ou en urgence :
kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-dev -n keybuzz-admin-v2-dev
```

## Conclusion

**GO PARTIEL** — Le guide est realigne avec la verite produit :

- Meta et TikTok presentes comme connecteurs natifs first-class
- Google presente comme officiellement supporte via Addingwell / sGTM
- Webhook documente comme integration custom optionnelle
- KeyBuzz positionne comme source de verite business
- Modele owner-aware (tenant_id, routing_tenant_id, marketing_owner_tenant_id, owner_routed) documente
- Contrat URL d'acquisition avec UTMs, click IDs (fbclid, gclid, ttclid) et marketing_owner_tenant_id documente
- Section HMAC recadree comme besoin webhook custom uniquement
- Aucune fausse promesse "Google natif dans Destinations"

Limitation :
- Validation navigateur directe bloquee par mot de passe bootstrap (hash bcrypt)
- Recommandation : verification visuelle manuelle par l'operateur via `admin-dev.keybuzz.io/marketing/integration-guide`

Prochaine phase possible :
- **Fermeture de KEY-186** apres verification visuelle par l'operateur
- **Promotion PROD** si souhaitee

## PROD inchangee

**Oui**

| Surface | Image | Inchangee |
|---|---|---|
| Admin PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-prod` | Oui |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.118-google-sgtm-owner-aware-quick-win-prod` | Oui |

---

**Chemin du rapport** : `keybuzz-infra/docs/PH-ADMIN-T8.10R-INTEGRATION-GUIDE-REALIGNMENT-DEV-PROMOTION-AND-VALIDATION-01.md`
