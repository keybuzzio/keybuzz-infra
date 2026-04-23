# PH-ADMIN-T8.8J — Agency Tracking Playbook PROD Promotion

**Phase** : PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-PROD-PROMOTION-01
**Date** : 2026-04-23
**Environnement** : PROD
**Type** : Promotion PROD — Playbook agence / media buyer dans Integration Guide
**Priorite** : P1

---

## 1. PREFLIGHT

| Element | Valeur |
|---|---|
| Branche Infra | `main` |
| HEAD Infra avant | `891d299` |
| Admin PROD avant | `v2.11.7-integration-guide-server-side-tracking-prod` |
| Admin DEV | `v2.11.8-agency-tracking-playbook-dev` |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` (inchangee) |
| HEAD Admin | `4bad311` (playbook agence, 860 lignes) |
| Rapport DEV | `PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-01.md` (commit `891d299`) |
| Repo Admin | clean |
| Repo Infra | clean (fichiers untracked non-impactants) |

---

## 2. SOURCE VERIFIEE

| Point | Resultat |
|---|---|
| Page enrichie | OK (860 lignes, commit `4bad311`) |
| 9 nouvelles sections playbook | OK (sections 10-18) |
| Verite browser vs server | OK (section 11 — Modele verite) |
| Tableau plateformes | OK (section 12 — Meta natif, reste webhook) |
| Matrice anti-doublon | OK (section 13 — 6 events, proprietaire + garde-fou) |
| Role exact Addingwell | OK (section 14 — complement, pas remplacant) |
| Regle produit landing pages | OK (section 15 — seule /pricing garantie) |
| Checklist campagne agence | OK (section 16 — 11 points avant/apres) |
| Procedure autonome agence | OK (section 17 — 6 etapes + nouveau tenant) |
| Limites actuelles | OK (section 18 — 7 limites documentees) |
| Token safety | OK (0 token brut, 12 mentions generiques/doc) |
| Menu Marketing | Inchange (Metrics, Ads Accounts, Destinations, Delivery Logs, Integration Guide) |

---

## 3. IMAGE PROD

| Element | Valeur |
|---|---|
| Image PROD avant | `v2.11.7-integration-guide-server-side-tracking-prod` |
| Image PROD apres | `v2.11.8-agency-tracking-playbook-prod` |
| Tag | `v2.11.8-agency-tracking-playbook-prod` |
| Digest | `sha256:cadaf8fcd55af84897d5d660323d9200aad855afdcf8217ea1bf87dae44c604d` |
| Build | Build-from-git, branche main, commit `4bad311` |
| Push | OK vers `ghcr.io/keybuzzio/keybuzz-admin` |

---

## 4. GITOPS PROD

| Element | Valeur |
|---|---|
| Fichier | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.8-agency-tracking-playbook-prod` |
| ROLLBACK comment | `v2.11.7-integration-guide-server-side-tracking-prod` |
| Commit | `526dab2` |
| Message | `PH-ADMIN-T8.8J-PROD: Admin v2.11.8-agency-tracking-playbook-prod -- rollback: v2.11.7-integration-guide-server-side-tracking-prod -- API PROD unchanged v3.5.107` |

---

## 5. DEPLOY PROD

| Element | Valeur |
|---|---|
| Methode | `kubectl apply -f` (GitOps) |
| Rollout | Complete |
| Pod | Running, 0 restarts |
| DEV image | Inchangee (`v2.11.8-agency-tracking-playbook-dev`) |
| API PROD image | Inchangee (`v3.5.107-ad-spend-idempotence-fix-prod`) |

---

## 6. VALIDATION NAVIGATEUR PROD

### 6.1 Integration Guide (`/marketing/integration-guide`)

| Test | Attendu | Resultat |
|---|---|---|
| Page accessible | OK | OK |
| Titre | "Integration Guide" + "Playbook Agence" | OK |
| 19 sections rendues | 19 | 19 (240 refs dans snapshot) |
| Sections 1-9 (SST existantes) | Presentes | OK |
| Section 10 — Qui fait quoi | 3 colonnes | OK |
| Section 11 — Modele verite | Browser vs Business | OK |
| Section 12 — Plateformes | Tableau 5 plateformes | OK (Meta natif, reste webhook) |
| Section 13 — Anti-doublon | Matrice 6 events | OK |
| Section 14 — Addingwell | Complement, pas remplacant | OK |
| Section 15 — Landing pages | Seule /pricing garantie | OK |
| Section 16 — Checklist | 11 points | OK |
| Section 17 — Procedure autonome | 6 etapes + nouveau tenant | OK |
| Section 18 — Limites | 7 limites | OK |
| Section 19 — Website/Landing | En fin de page | OK |
| NaN / undefined / mock | 0 | 0 |
| Token brut | 0 | 0 |
| Boutons Copier | 6 | 6 fonctionnels |

### 6.2 Contenu critique verifie en PROD

| Affirmation | Presente en PROD |
|---|---|
| Pixel/browser != business events | OUI (section 11) |
| Meta = plus natif | OUI (section 12 — "Full native — operationnel") |
| TikTok/Google/YouTube = webhook agence (non full-native) | OUI (section 12) |
| Webhook agence = voie valide | OUI (sections 10, 12, 17) |
| Addingwell = complement, pas remplacant | OUI (section 14) |
| Seule /pricing garantie pour UTM forwarding | OUI (section 15) |

### 6.3 Non-regression Marketing

| Page | Statut |
|---|---|
| /marketing/metrics | OK (445 GBP) |
| /marketing/ad-accounts | OK (menu visible) |
| /marketing/destinations | OK (KBC Meta CAPI actif) |
| /marketing/delivery-logs | OK (menu visible) |
| Menu Marketing | OK (5 liens, ordre correct) |
| Tenant selector | OK (KeyBuzz Consulting) |

### 6.4 Verification KBC

| Element | Attendu | Resultat |
|---|---|---|
| Spend total (GBP) | ~445 GBP | 445 GBP |
| Destination Meta CAPI | Active | Active |
| Token | Masque | `EA*****...` |
| Test: success | Visible | Visible (dans snapshot precedent) |

---

## 7. NON-REGRESSION

| Composant | Impact |
|---|---|
| API SaaS PROD | Aucun (image inchangee `v3.5.107`) |
| Base de donnees | Aucune migration |
| Admin DEV | Aucun (image inchangee `v2.11.8-...-dev`) |
| Webflow / DNS | Aucune modification |
| Metrics spend KBC | Stable (445 GBP) |
| Destinations Meta CAPI | Fonctionnelle (Active, token masque) |
| Token safety | OK partout |
| eComLG tenant isolation | Verifie (KBC scope uniquement) |

---

## 8. CAPTURES PROD

Les captures ont ete realisees via le navigateur integre durant la validation :
- Integration Guide haut : titre + "Playbook Agence" + Architecture 4 briques
- Section playbook agence : "Qui fait quoi" 3 colonnes
- Section anti-doublon : Matrice 6 events avec proprietaire
- Section landing/UTM : Tableau UTM + encart Important + exemples URL
- Section Addingwell : Utile pour / Ne doit PAS
- Metrics : 445 GBP, bouton CAC visible
- Destinations : Meta CAPI actif, token masque

Aucune capture ne contient de token brut, access token, secret webhook ou payload sensible.

---

## 9. ROLLBACK PROD

En cas de regression :

```bash
# 1. Appliquer le manifest avec l'image precedente
# k8s/keybuzz-admin-v2-prod/deployment.yaml → v2.11.7-integration-guide-server-side-tracking-prod
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml

# 2. Verifier
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
kubectl get pods -n keybuzz-admin-v2-prod
```

---

## 10. DOCS OBSOLETES (rappel du rapport DEV)

| Document | Contradiction | Impact |
|---|---|---|
| `MEDIA-BUYER-TRACKING-GUIDE.md` section 9.6 | Dit "tracking server-side pas encore en place" — FAUX : Meta CAPI est live depuis PH-ADMIN-T8.8H | Document non modifie dans cette phase |
| `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md` | Mentionne "une seule URL de destination" — le systeme supporte desormais plusieurs destinations | Document non modifie dans cette phase |

Ces documents sont obsoletes mais non corriges dans cette phase (hors perimetre UI Admin).

---

## 11. RESUME

| Element | Avant | Apres |
|---|---|---|
| Image Admin PROD | `v2.11.7-integration-guide-server-side-tracking-prod` | `v2.11.8-agency-tracking-playbook-prod` |
| Integration Guide | 10 sections SST (404 lignes) | 19 sections SST + Playbook Agence (860 lignes) |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` | Inchangee |
| Metrics spend | ~445 GBP | Stable |
| Destinations Meta CAPI | Active, Test: success | Inchange |
| Rollback | `v2.11.6-metrics-currency-cac-controls-prod` | `v2.11.7-integration-guide-server-side-tracking-prod` |

---

## 12. CHEMIN COMPLET DU RAPPORT

```
keybuzz-infra/docs/PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-PROD-PROMOTION-01.md
```

---

**VERDICT** : ADMIN AGENCY TRACKING PLAYBOOK LIVE IN PROD — REAL PLATFORM TRUTH DOCUMENTED — DUPLICATE PREVENTION EXPLAINED — TOKEN SAFE — API UNCHANGED — NON REGRESSION OK

**Prochaine etape** : a definir
