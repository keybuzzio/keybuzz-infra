# PH-ADMIN-T8.11AO — Campaign QA Event Lab Safe Mode

**Date** : 29 avril 2026
**Ticket** : KEY-221 (sous-phase)
**Verdict** : CAMPAIGN QA EVENT LAB SAFE MODE LIVE

---

## 1. Préflight

| Check | Résultat |
|---|---|
| Admin `main` | clean, HEAD `785a93f` |
| Infra `main` | docs untracked uniquement |
| Admin DEV runtime | `v2.11.33-campaign-qa-icon-hotfix-dev` |
| Admin PROD runtime | `v2.11.33-campaign-qa-icon-hotfix-prod` |
| API/Client/Website | Inchangés |
| `/marketing/campaign-qa` | Existant, fonctionnel |

## 2. Rapports lus

- PH-ADMIN-T8.11AN-CAMPAIGN-QA-URL-BUILDER-FOUNDATION-01.md
- PH-ADMIN-T8.11AN.1-CAMPAIGN-QA-SIDEBAR-ICON-HOTFIX-01.md
- PH-WEBSITE-T8.11AK-PRICING-ATTRIBUTION-FORWARDING-CLOSURE-01.md (context du summary)
- PH-T8.11AL-GOOGLE-ADS-SIGNUP-COMPLETE-ACTIVATION-01.md (context du summary)

## 3. Design UI

- Onglets en haut de page : **URL Builder** | **Event Lab**
- URL Builder = fonctionnalité existante (inchangée)
- Event Lab = nouveau, purement client-side, read-only

## 4. Fichier modifié

| Fichier | Changement |
|---|---|
| `keybuzz-admin-v2/src/app/(admin)/marketing/campaign-qa/page.tsx` | Ajout onglets + Event Lab complet |

## 5. Fonctionnalités Event Lab

### Champ URL
- Textarea pour coller une URL complète
- Bouton "Analyser URL" (désactivé si vide)

### Parsing
- Domaine, path, query params
- Détection plateforme via `utm_source`
- Détection acteur via préfixe `utm_campaign` (mb-, ag-, kb-)
- Détection `marketing_owner_tenant_id`
- Détection click IDs (fbclid, gclid, ttclid, li_fat_id)
- Détection `_gl` (Google Linker)

### Règles de validation

| Règle | Niveau |
|---|---|
| `utm_source` ∈ meta/google/tiktok/linkedin | OK |
| `utm_source=facebook` | BLOQUANT |
| `utm_medium` présent | OK |
| `utm_campaign` présent | BLOQUANT si absent |
| `utm_campaign` préfixe mb-/ag-/kb- | OK / WARNING |
| `marketing_owner_tenant_id` présent et correct | OK / BLOQUANT |
| Landing `/pricing` | OK / WARNING |
| URL raccourcie (bit.ly, etc.) | BLOQUANT |
| Domaine non KeyBuzz | BLOQUANT |
| Tag AW- détecté | BLOQUANT |
| Click ID manuel dans l'URL | WARNING |
| `_gl` absent | WARNING |
| Campagne contient "test" / "internal-validation" | WARNING |

### Sortie "Où vérifier"

Affichée selon plateforme détectée :
- **Meta** : Ads Manager, Events Manager, Admin Delivery Logs, Admin Metrics
- **Google** : Google Ads, GA4 Realtime, Google Ads Conversions, Admin Google Tracking
- **TikTok** : TikTok Ads Manager, Events Manager, Admin Delivery Logs
- **LinkedIn** : Campaign Manager, LinkedIn CAPI, Admin Delivery Logs

### Actions

| Action | Statut |
|---|---|
| Analyser URL | Autorisé |
| Copier rapport QA | Autorisé |
| Ouvrir landing | Autorisé (désactivé si bloquants) |
| Réinitialiser | Autorisé |
| Envoyer event/conversion | INTERDIT — non implémenté |

### Banner sécurité
> Ce lab ne déclenche aucun événement business. Il valide uniquement l'URL, les paramètres d'attribution et les points de contrôle. Aucune conversion CAPI n'est envoyée.

## 6. URLs testées

| URL | Résultat attendu | Résultat obtenu |
|---|---|---|
| Meta valide (utm_source=meta, owner, /pricing) | OK | OK — tous checks verts, warnings _gl/fbclid normaux |
| `utm_source=facebook` | BLOQUANT | BLOQUANT — "interdit, utiliser meta" |
| Sans `marketing_owner_tenant_id` | BLOQUANT | BLOQUANT — "attribution impossible" |
| Campaign sans préfixe acteur | WARNING | WARNING — "ne commence pas par mb-, ag-, kb-" |
| Campaign contenant "test" | WARNING | WARNING — "exclue du reporting" |

## 7. Build tags + digests

| Env | Tag | Digest |
|---|---|---|
| DEV | `v2.11.34-campaign-qa-event-lab-dev` | `sha256:49d2b5282d0021f3006e637a0a028b2b1bfa4277b338d02e06816342c4718769` |
| PROD | `v2.11.34-campaign-qa-event-lab-prod` | `sha256:a8805a018937730d04cd8a9faef64a360fa6692558d66ab08944374ebadb089a` |

Source commit : `97d1775` (keybuzz-admin-v2 main)

## 8. GitOps commits

| Repo | Commit | Description |
|---|---|---|
| keybuzz-admin-v2 | `97d1775` | feat(marketing): Campaign QA Event Lab safe mode |
| keybuzz-infra | `5dd9dd9` | GitOps Admin DEV v2.11.34 |
| keybuzz-infra | `01709e1` | GitOps Admin PROD v2.11.34 |

## 9. Validation navigateur DEV

| Check | Résultat |
|---|---|
| Sidebar icône Campaign QA | Visible, Link2 icon |
| Onglet URL Builder | Fonctionnel |
| Onglet Event Lab | Fonctionnel |
| Banner "Mode safe" | Visible |
| Analyse URL Meta valide | OK — checks verts |
| Boutons Analyser/Copier/Ouvrir/Réinitialiser | Fonctionnels |
| Aucun secret visible | Confirmé |
| Aucun AW- direct | Confirmé |

## 10. Validation navigateur PROD

| Check | Résultat |
|---|---|
| Login PROD | OK (ludovic@keybuzz.pro) |
| Sidebar icône Campaign QA | Visible |
| Onglet URL Builder | Fonctionnel |
| Onglet Event Lab | Fonctionnel |
| Analyse `utm_source=facebook` | BLOQUANT détecté |
| Analyse sans owner | BLOQUANT détecté |
| "Ouvrir landing" disabled sur bloquant | Confirmé |
| Aucun secret/AW/fake event | Confirmé |

## 11. Preuve aucun fake event / aucun appel CAPI / aucun secret

- L'Event Lab est 100% client-side (parsing `new URL()` + validation JS)
- Aucun `fetch()`, `XMLHttpRequest`, ou appel réseau dans le code
- Aucun endpoint API appelé
- Aucune conversion business émise
- Aucun tag `AW-` dans le code
- Aucun secret dans le bundle

## 12. Non-régression

| Service | Statut | Image |
|---|---|---|
| Admin PROD | 1/1 Running, 0 restarts | v2.11.34-campaign-qa-event-lab-prod |
| API PROD | Inchangé | v3.5.123-linkedin-capi-native-prod |
| Client PROD | Inchangé | v3.5.125-register-console-cleanup-prod |
| Website PROD | Inchangé | v0.6.7-pricing-attribution-forwarding-prod |

## 13. Linear

- Ticket KEY-221 : mise à jour manuelle requise (token Linear non disponible)
- Sous-phase "Campaign QA Event Lab safe mode" — Done

## 14. Rollback GitOps

```bash
# DEV
vim keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml
# image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.33-campaign-qa-icon-hotfix-dev
git add . && git commit -m "rollback Admin DEV to v2.11.33"
git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev

# PROD
vim keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml
# image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.33-campaign-qa-icon-hotfix-prod
git add . && git commit -m "rollback Admin PROD to v2.11.33"
git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

---

## VERDICT FINAL

**CAMPAIGN QA EVENT LAB SAFE MODE LIVE — URL ATTRIBUTION TESTING ENABLED — NO BUSINESS EVENT EMITTED — NO FAKE CONVERSIONS — NO TRACKING DRIFT**
