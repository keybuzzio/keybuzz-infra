# PH-ADMIN-T8.10S-GOOGLE-ADMIN-VISIBILITY-AND-MONETIZATION-FOUNDATION-01 — TERMINE

**Verdict : GO**

Google a maintenant une surface produit honnete et visible dans l'Admin DEV.
Le modele Addingwell/sGTM est rendu comprehensible pour les agences et clients.
Aucune fausse promesse de connecteur natif Google.
Validation navigateur complete en DEV.
PROD inchangee.

## KEY

**KEY-185** — rendre Google visible et monetisable dans l'Admin sans faux connecteur natif

## Preflight

| Point | Valeur |
|---|---|
| Branche | `main` |
| HEAD avant | `7606a9c` |
| Image DEV avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-integration-guide-realignment-dev` |
| Repo clean | Oui |
| Source | `main` |
| Scope | Admin seulement |
| PROD inchangee | Oui |

## Audit des surfaces

| Surface | Etat actuel | Google y a-t-il sa place ? | Risque de confusion |
|---|---|---|---|
| `/marketing/ad-accounts` | Meta Ads uniquement | **Non** — Google Ads spend sync n'existe pas | Eleve |
| `/marketing/destinations` | meta_capi, tiktok_events, webhook | **Non** — pas d'adapter natif Google | Tres eleve |
| `/marketing/delivery-logs` | Logs pipeline outbound | **Indirect** — events Google via sGTM invisibles ici | Moyen |
| `/marketing/integration-guide` | Deja realigne (PH-T8.10R) | **Fait** — documentation, pas surface produit | Faible |
| **Nouvelle page dediee** | N'existait pas | **Oui** — separation nette avec les natifs | Faible |

**Decision** : nouvelle page `/marketing/google-tracking` — la plus petite surface produit utile.

## Design retenu

| Sujet | Decision | Pourquoi |
|---|---|---|
| Surface | Page `/marketing/google-tracking` | Separation nette, pas de pollution des natifs |
| Sidebar | Apres Destinations, avant Delivery Logs | Proximite logique |
| Icone | Chrome (lucide-react) | Identifie Google immediatement |
| Status | Badge "Support actif" | Signal clair, pas de faux statut temps reel |
| Architecture | Diagramme visuel 3 blocs | Comprehension immediate du flux |
| Comparaison | Tableau Meta/TikTok/Google | Pas de confusion possible |
| Faux connecteur | Interdit | Le backend n'existe pas |
| Faux statut | Interdit | Events Google via sGTM, pas via delivery logs |

## Patch Admin

### Fichiers modifies

| Fichier | Changement | Lignes |
|---|---|---|
| `src/app/(admin)/marketing/google-tracking/page.tsx` | Nouvelle page dediee Google | +293 (creation) |
| `src/config/navigation.ts` | Ajout sidebar "Google Tracking" | +1 |
| `src/components/layout/Sidebar.tsx` | Ajout icone Chrome a l'import et iconMap | +1 (net) |

### Contenu de la page

| Section | Contenu |
|---|---|
| 1. Status Banner | "Google Ads — Support actif" + badges Transport/Owner-aware/Verite business |
| 2. Architecture | Diagramme KeyBuzz API → Addingwell/sGTM → Google Ads |
| 3. Ce qui fonctionne | 5 actifs (conversions, gclid, GA4 MP, owner-aware, GA4 browser) + 4 non natifs |
| 4. Pourquoi pas natif | Encart explicatif — choix produit delibere, pas manque technique |
| 5. Comparaison | Tableau Meta Natif / TikTok Natif / Google Via sGTM (7 criteres) |
| 6. Prerequisites agence | Checklist 5 etapes d'activation |
| 7. Qui fait quoi | KeyBuzz vs Agence/Addingwell |
| 8. Ressources | Liens Integration Guide + Destinations |

## Validation DEV

| Test | Attendu | Resultat |
|---|---|---|
| Google supporte | Badge "Support actif" | **OK** |
| Chemin = Addingwell/sGTM | Explicite | **OK** |
| KeyBuzz = verite business | Badge visible | **OK** |
| Pas de faux connecteur | Aucun formulaire/bouton | **OK** |
| Pas de faux statut | Aucune donnee fictive | **OK** |
| Surface vendable | Architecture + checklist | **OK** |
| Orienter une agence | Prerequisites clairs | **OK** |
| Pas de confusion Meta/TikTok | Tableau comparatif | **OK** |

## Non-regression

| Surface | Attendu | Resultat |
|---|---|---|
| `/marketing/destinations` | Intact | **OK** — bundle compile, meta_capi + tiktok_events confirmes |
| `/marketing/metrics` | Intact | **OK** — bundle compile |
| `/marketing/funnel` | Intact | **OK** — bundle compile |
| `/marketing/integration-guide` | Intact | **OK** — bundle compile |
| Erreur console | Aucune | **OK** — pod READY=true, 0 restarts |
| Build Next.js | Zero erreur | **OK** |
| PROD inchangee | Admin + API | **OK** |

## Build

| Point | Valeur |
|---|---|
| Commit Admin | `8a12901` |
| Message | `feat(google-tracking): add dedicated Google Tracking page + sidebar entry -- visible, honest, monetizable (KEY-185)` |
| Tag | `v2.11.17-google-admin-visibility-dev` |
| Digest | `sha256:a75252f775b940d713e512ab1e9c6543cf14e3d9f55cd18d99dc8dfd5f51ea19` |
| Build-from-git | Oui (commit pousse AVANT build) |

## GitOps

| Point | Valeur |
|---|---|
| Fichier | `k8s/keybuzz-admin-v2-dev/deployment.yaml` |
| Image avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-integration-guide-realignment-dev` |
| Image apres | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.17-google-admin-visibility-dev` |
| Commit infra | `ea8d18a` |
| Rollback DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-integration-guide-realignment-dev` |

## Deploiement

| Point | Valeur |
|---|---|
| Methode | `kubectl apply -f` (GitOps strict) |
| Rollout | Successfully rolled out |
| Pod actif | `keybuzz-admin-v2-55579c6585-qcx4g` |
| Restarts | 0 |
| Ready | true |
| Image runtime | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.17-google-admin-visibility-dev` |

## Validation navigateur DEV

**Validation directe reussie** via `admin-dev.keybuzz.io/marketing/google-tracking`.

| Test navigateur | Attendu | Resultat |
|---|---|---|
| Page accessible | Charge correctement | **OK** |
| Sidebar visible | "Google Tracking" dans Marketing | **OK** — position correcte |
| Bandeau status | "Google Ads — Support actif" | **OK** — avec 3 badges |
| Architecture | Diagramme 3 blocs | **OK** — KeyBuzz → sGTM → Google |
| Ce qui fonctionne | 5 actifs + 4 non natifs | **OK** — colonnes claires |
| Honnetete | Encart "Pourquoi pas natif" | **OK** |
| Tableau comparatif | Meta Natif / TikTok Natif / Google Via sGTM | **OK** — badges differencies |
| Prerequisites | Checklist 5 etapes | **OK** |
| Qui fait quoi | KeyBuzz vs Agence | **OK** |
| Ressources | Liens Integration Guide + Destinations | **OK** |
| Pas de faux connecteur | Aucun | **OK** |
| PROD inchangee | Confirmee | **OK** |

## Digest

```
sha256:a75252f775b940d713e512ab1e9c6543cf14e3d9f55cd18d99dc8dfd5f51ea19
```

## Rollback DEV

```bash
# Image precedente
ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-integration-guide-realignment-dev

# Commande (modifier deployment.yaml dans keybuzz-infra et kubectl apply)
# Ou en urgence :
kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-integration-guide-realignment-dev -n keybuzz-admin-v2-dev
```

## Conclusion

**GO** — Google a maintenant une surface produit honnete dans l'Admin DEV :

- **Page dediee** `/marketing/google-tracking` avec entree sidebar
- **Bandeau status** "Google Ads — Support actif" clairement differencie des natifs
- **Architecture** KeyBuzz → Addingwell/sGTM → Google Ads expliquee visuellement
- **Tableau comparatif** Meta Natif / TikTok Natif / Google Via sGTM — zero ambiguite
- **Checklist agence** actionnable (5 etapes d'activation)
- **Aucune fausse promesse** : pas de faux connecteur, pas de faux statut, pas de faux bouton
- **Validation navigateur** complete sur `admin-dev.keybuzz.io` — page rendue correctement

Prochaine phase possible :
- **Promotion PROD** pour rendre Google visible en production
- **KEY-187** ou evolutions fonctionnelles

## PROD inchangee

**Oui**

| Surface | Image | Inchangee |
|---|---|---|
| Admin PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-prod` | Oui |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.118-google-sgtm-owner-aware-quick-win-prod` | Oui |

---

**Chemin du rapport** : `keybuzz-infra/docs/PH-ADMIN-T8.10S-GOOGLE-ADMIN-VISIBILITY-AND-MONETIZATION-FOUNDATION-01.md`
