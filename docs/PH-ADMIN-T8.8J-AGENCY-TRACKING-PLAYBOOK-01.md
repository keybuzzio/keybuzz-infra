# PH-ADMIN-T8.8J — Agency Tracking Playbook

**Phase** : PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-01
**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Type** : Documentation / Playbook agence-media buyer — tracking server-side multi-tenant
**Priorite** : P1

---

## 1. PREFLIGHT

| Element | Valeur |
|---|---|
| Branche Infra | `main` |
| HEAD Infra avant | `ef379a7` |
| Image Admin DEV avant | `v2.11.7-integration-guide-server-side-tracking-dev` |
| Image Admin PROD | `v2.11.7-integration-guide-server-side-tracking-prod` (inchangee) |
| API DEV | `v3.5.107-ad-spend-idempotence-fix-dev` (inchangee) |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` (inchangee) |
| Source Integration Guide avant | 404 lignes, 10 sections |
| Repo Infra | clean |

---

## 2. SOURCES RELUES

| Source | Statut | Contradictions |
|---|---|---|
| PH-ADMIN-T8.8I PROD Promotion report | Relu | Aucune |
| PH-ADMIN-T8.8H KBC Meta CAPI Validation report | Relu | Aucune |
| PH-T8.5 Agency Integration Doc | Relu | Mentionne une seule URL de destination — aujourd'hui on peut en creer plusieurs |
| MEDIA-BUYER-TRACKING-GUIDE.md | Relu | Section 9.6 dit "tracking server-side (Addingwell/CAPI) pas encore en place" — FAUX : Meta CAPI est live |
| MEDIA-BUYER-UTM-TRACKING.md | Relu | Confirme que seule /pricing forwarde les UTM — coherent avec notre documentation |

### Contradictions documentees

1. **MEDIA-BUYER-TRACKING-GUIDE.md section 9.6** : dit "Le tracking server-side (Addingwell/CAPI) n'est pas encore en place" — c'est obsolete. Meta CAPI natif est en PROD depuis PH-ADMIN-T8.8H, valide avec un test PageView reel.
2. **PH-T8.5** : mentionne "une seule URL de destination" — le systeme supporte desormais plusieurs destinations par tenant (Meta CAPI + webhook).

---

## 3. CHOIX D'INTEGRATION UI

| Element | Decision |
|---|---|
| Emplacement | Enrichir `/marketing/integration-guide` avec 9 nouvelles sections apres "Bonnes pratiques" |
| Nouvelle page/menu | Non — evite d'alourdir la navigation |
| Sous-titre mis a jour | "Server-Side Tracking — Ads Accounts, Destinations, Metrics, Delivery Logs — Playbook Agence" |
| Sections existantes | 10 sections conservees identiques (1-9 + Website/Landing deplacee en fin) |

---

## 4. CONTENU AJOUTE

### Nouvelles sections (10 a 18 dans l'UI)

| # | Section | Contenu |
|---|---|---|
| 10 | Playbook Agence — Qui fait quoi | 3 colonnes : KeyBuzz gere / L'agence gere / Le tenant doit fournir |
| 11 | Modele de verite des donnees | Browser events vs Business events, encart "Pixel seul ne suffit pas" |
| 12 | Plateformes — Etat reel | Tableau 5 plateformes : Meta (full native), Google/TikTok/LinkedIn/YouTube (webhook agence) |
| 13 | Matrice anti-doublon — Proprietaires | 6 lignes : PageView, Lead, StartTrial, Purchase, SubscriptionRenewed, Webhook agence |
| 14 | Addingwell — Role exact | Utile pour / Ne doit PAS — encart event_id doublon |
| 15 | Landing pages — Regle produit | Tableau 5 pages : /pricing (conforme), autres (a auditer), exemples URL |
| 16 | Checklist campagne agence | 6 points avant lancement, 5 points apres lancement |
| 17 | Procedure autonome agence | 6 etapes + nouveau tenant (agence seule vs necessite KeyBuzz) |
| 18 | Limites actuelles | 7 limites avec statut et contournement |

### Statistiques

| Metrique | Avant | Apres |
|---|---|---|
| Lignes | 404 | 860 |
| Sections | 10 | 19 (10 existantes + 9 nouvelles) |
| Boutons Copier | 4 | 6 |
| Tokens bruts | 0 | 0 |

---

## 5. VERITE PLATEFORME PAR PLATEFORME

| Plateforme | Pixel/browser | Spend inbound | Outbound business events | Mode actuel |
|---|---|---|---|---|
| Meta | Pixel actif | Ads Accounts sync (natif) | CAPI natif | Full native — operationnel |
| Google Ads | GA4 actif | Non natif | Webhook agence | Agence mappe vers Google Offline Conversions |
| TikTok | Pixel browser via sGTM | Non natif | Webhook agence | Agence mappe vers TikTok Events API |
| LinkedIn | Non installe | Non natif | Webhook agence | Agence mappe vers LinkedIn CAPI |
| YouTube | Via GA4 | Non natif | Webhook agence | Meme pipeline que Google Ads |

---

## 6. VERITE LANDING/UTM

| Page | UTM forwarding | Statut |
|---|---|---|
| keybuzz.pro/pricing | Verifie | Conforme |
| keybuzz.pro (accueil) | Non verifie | A auditer |
| keybuzz.pro/features | Non verifie | A auditer |
| keybuzz.pro/amazon | Non verifie | A auditer |
| Nouvelle landing | Inconnu | A verifier avant campagne |

**Regle** : seule `/pricing` est garantie par la documentation. Toute autre page doit etre auditee avant lancement de campagne.

---

## 7. ROLE EXACT ADDINGWELL

| Aspect | Verdict |
|---|---|
| GA4 Measurement Protocol | Utile — enrichissement server-side GA4 |
| Observabilite browser | Utile — signaux navigateur cote serveur |
| TikTok Pixel via sGTM | Utile — collecte browser |
| Envoi Purchase vers Meta CAPI | INTERDIT si KeyBuzz l'envoie deja |
| Envoi StartTrial vers Meta CAPI | INTERDIT si KeyBuzz l'envoie deja |
| Doublon conversion business | INTERDIT — un seul proprietaire par event par plateforme |

---

## 8. ANTI-DOUBLON

| Evenement | Proprietaire | Destination | Risque doublon | Garde-fou |
|---|---|---|---|---|
| PageView / ViewContent | Pixel navigateur | Meta Pixel, GA4 | Faible | Pas d'envoi server-side top funnel |
| Lead / click_signup | Pixel navigateur | Meta Pixel, GA4 | Faible | Browser-only |
| StartTrial | KeyBuzz (server) | Meta CAPI + webhook agence | Moyen | Desactiver dans sGTM si KeyBuzz l'envoie |
| Purchase | KeyBuzz (server) | Meta CAPI + webhook agence | Eleve | Un seul envoi — event_id pour dedupe |
| SubscriptionRenewed | KeyBuzz (server) | Webhook agence | Faible | Pas de Pixel equivalent |
| Webhook agence (recu) | Agence | Google Ads, TikTok, LinkedIn | Faible | L'agence controle le mapping |

---

## 9. VALIDATION NAVIGATEUR DEV

| Check | Resultat |
|---|---|
| Login DEV | OK (ludovic@keybuzz.pro) |
| Tenant selector | KeyBuzz Consulting selectionne |
| /marketing/integration-guide | Accessible, 19 sections rendues |
| Titre | "Integration Guide" + "Playbook Agence" |
| Section 10 — Qui fait quoi | 3 colonnes visibles |
| Section 11 — Modele verite | Browser vs Business events |
| Section 12 — Plateformes | Tableau 5 plateformes avec badges |
| Section 13 — Matrice anti-doublon | 6 lignes avec risque et garde-fou |
| Section 14 — Addingwell | Utile pour / Ne doit PAS |
| Section 15 — Landing pages | Tableau UTM + encart Important + exemples URL |
| Section 16 — Checklist campagne | 11 points avant/apres |
| Section 17 — Procedure autonome | 6 etapes + nouveau tenant |
| Section 18 — Limites | 7 limites avec contournement |
| NaN / undefined / mock | 0 |
| Token brut | 0 |
| Boutons Copier | 6 fonctionnels |
| Menu Marketing | Inchange (5 liens) |
| Texte tronque genant | Aucun |

---

## 10. BUILD DEV

| Element | Valeur |
|---|---|
| Commit Admin | `4bad311` |
| Push | `dfa328d..4bad311 main → main` |
| Tag | `v2.11.8-agency-tracking-playbook-dev` |
| Digest | `sha256:cadaf8fcd55af84897d5d660323d9200aad855afdcf8217ea1bf87dae44c604d` |
| Build | Build-from-git, branche main |
| GitOps DEV | `k8s/keybuzz-admin-v2-dev/deployment.yaml` mis a jour (commit `6926a4b`) |
| Deploy | `kubectl apply -f` → rollout OK |
| Pod | Running, 0 restarts |

---

## 11. ROLLBACK DEV

```bash
kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml
# avec image: v2.11.7-integration-guide-server-side-tracking-dev
```

---

## 12. ETAT PROD

| Element | Valeur |
|---|---|
| Image Admin PROD | `v2.11.7-integration-guide-server-side-tracking-prod` (INCHANGEE) |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` (INCHANGEE) |
| DB | Aucune migration |
| Webflow | Aucune modification |
| DNS | Aucune modification |

---

## 13. LIMITES RESTANTES

| Limite | Statut | Contournement |
|---|---|---|
| Google Ads spend sync | Non natif | Import manuel ou future phase |
| TikTok Ads spend sync | Non natif | Import manuel ou future phase |
| Google Ads outbound natif | Non natif | Webhook agence → Google Offline Conversions |
| TikTok outbound natif | Non natif | Webhook agence → TikTok Events API |
| Destinations self-service agence | Admin only | Configuration par Super Admin |
| Replay evenement rate | Non disponible | Contacter support KeyBuzz |
| UTM forwarding toutes landing pages | Partiel | Seule /pricing garantie |

---

## 14. TIMELINE

| Heure | Etape |
|---|---|
| T+0 | Preflight : branche main, images confirmees |
| T+1 | Sources relues : 5 docs, 2 contradictions documentees |
| T+2 | Choix UI : enrichir integration-guide (pas de nouvelle page) |
| T+3 | Redaction : 9 nouvelles sections (456 lignes ajoutees) |
| T+4 | Commit Admin : 4bad311, push main |
| T+5 | Build DEV : v2.11.8-agency-tracking-playbook-dev |
| T+6 | GitOps DEV : deployment.yaml mis a jour (commit 6926a4b) |
| T+7 | Deploy DEV : kubectl apply, rollout OK |
| T+8 | Validation navigateur : 19 sections OK, 0 token, 0 NaN |
| T+9 | Rapport final |

---

## 15. CHEMIN COMPLET DU RAPPORT

```
keybuzz-infra/docs/PH-ADMIN-T8.8J-AGENCY-TRACKING-PLAYBOOK-01.md
```

---

**VERDICT** : ADMIN AGENCY TRACKING PLAYBOOK READY IN DEV — REAL PLATFORM TRUTH DOCUMENTED — DUPLICATE PREVENTION EXPLAINED — TOKEN SAFE — PROD UNTOUCHED

**Prochaine etape** : Promotion PROD (PH-ADMIN-T8.8J-PROD si demande)
