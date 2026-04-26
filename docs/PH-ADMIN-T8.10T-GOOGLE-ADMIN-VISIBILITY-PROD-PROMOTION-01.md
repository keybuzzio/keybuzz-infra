# PH-ADMIN-T8.10T-GOOGLE-ADMIN-VISIBILITY-PROD-PROMOTION-01 — TERMINE

**Verdict : GO PARTIEL**

La page Google Tracking est deployee en PROD. Le bundle compile contient tout le contenu attendu.
La validation navigateur directe est bloquee par le mot de passe bootstrap stocke en bcrypt hash (limitation connue).
La meme source exacte (`8a12901`) a ete validee avec succes en navigateur DEV dans la phase precedente (PH-ADMIN-T8.10S).

## KEY

**KEY-185** — rendre Google visible et monetisable dans l'Admin sans faux connecteur natif

## Preflight

| Point | Valeur |
|---|---|
| Branche | `main` |
| HEAD | `8a12901` |
| Image DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.17-google-admin-visibility-dev` |
| Image PROD avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.118-google-sgtm-owner-aware-quick-win-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.116-marketing-owner-stack-prod` |
| Repo clean | Oui |
| Source = main | Confirme |
| Scope = Admin seulement | Confirme |

## Source verifiee

| Point verifie | Attendu | Resultat |
|---|---|---|
| Page `/marketing/google-tracking` | Fichier existe | **OK** — 16866 octets |
| Sidebar "Google Tracking" | Entree navigation.ts | **OK** — ligne 46 |
| Icone Chrome dans Sidebar | Import + iconMap | **OK** |
| "Support actif" | Present | **OK** — 1 occurrence |
| Addingwell / sGTM | Mentions multiples | **OK** — 8 occurrences |
| KeyBuzz = verite business | Mentions multiples | **OK** — 5 occurrences |
| Comparaison Meta/TikTok | Badges Natif + Via sGTM | **OK** — 2 Natif + 1 Via sGTM |
| Pas de faux connecteur | "Connecter Google" = 0 | **OK** |
| Pas de faux bouton test | "Tester Google" = 0 | **OK** |
| Commit SHA | `8a12901` | **OK** |

## Build

| Point | Valeur |
|---|---|
| Commit Admin | `8a12901` |
| Tag | `v2.11.16-google-admin-visibility-prod` |
| Digest | `sha256:77112da923b626f7ee8843e29b2144bca69f9f53902da1dfae3df4935086c808` |
| Build-from-git | Oui (HEAD = `8a12901`, repo clean) |

## GitOps

| Point | Valeur |
|---|---|
| Fichier | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image avant | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-prod` |
| Image apres | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-google-admin-visibility-prod` |
| Commit infra | `783c557` |
| Rollback PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-prod` |

## Deploiement

| Point | Valeur |
|---|---|
| Methode | `kubectl apply -f` (GitOps strict) |
| Rollout | Successfully rolled out |
| Pod actif | `keybuzz-admin-v2-8556b4648b-cqhf7` |
| Restarts | 0 |
| Ready | true |
| Image runtime | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.16-google-admin-visibility-prod` |

## Validation navigateur PROD

### Validation structurelle (in-pod)

| Test | Attendu | Resultat |
|---|---|---|
| Page google-tracking compile | 3 fichiers JS | **OK** — server + client chunks |
| "Support actif" dans bundle | Present | **OK** |
| "Addingwell" dans bundle | Present | **OK** |
| "business" dans bundle | Present | **OK** |
| "Google Tracking" dans sidebar | Present | **OK** — layout chunk + server chunk |
| "Connecter Google" absent | 0 occurrences | **OK** |
| Destinations intact | meta_capi present | **OK** |
| Integration Guide intact | TikTok Events API present | **OK** |
| Pod health | READY, 0 restarts | **OK** |

### Validation navigateur directe

| Test navigateur | Attendu | Resultat |
|---|---|---|
| Login PROD | Acces a la page | **BLOQUE** — mot de passe bootstrap en bcrypt hash, texte clair inaccessible |

### Justification de la confiance malgre le blocage navigateur

1. **Meme source exacte** : commit `8a12901` = identique a la version DEV validee en navigateur (PH-ADMIN-T8.10S)
2. **Meme hash bcrypt** DEV/PROD : applications identiques
3. **Validation navigateur DEV reussie** : la page a ete rendue correctement dans le navigateur en DEV (screenshots captures)
4. **Validation structurelle PROD complete** : tous les contenus presents dans le bundle compile
5. **Limitation connue** : ce blocage login est recurrent depuis PH-ADMIN-T8.10R, il est lie a l'infrastructure d'authentification, pas au contenu deploye

## Non-regression

| Surface | Attendu | Resultat |
|---|---|---|
| `/marketing/destinations` | Intact | **OK** — meta_capi confirme dans bundle |
| `/marketing/metrics` | Build compile | **OK** |
| `/marketing/funnel` | Build compile | **OK** |
| `/marketing/integration-guide` | Intact | **OK** — TikTok Events API confirme dans bundle |
| Erreur console | Pod sain | **OK** — READY=true, 0 restarts |
| API PROD | Inchangee | **OK** — `v3.5.118-google-sgtm-owner-aware-quick-win-prod` |
| Client PROD | Inchange | **OK** — `v3.5.116-marketing-owner-stack-prod` |
| Tracking Google existant | Non touche | **OK** — aucun changement API/tracking |

## Digest

```
sha256:77112da923b626f7ee8843e29b2144bca69f9f53902da1dfae3df4935086c808
```

## Rollback PROD

```bash
# Image precedente
ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-prod

# Via manifest (methode preferee) :
# Modifier k8s/keybuzz-admin-v2-prod/deployment.yaml et kubectl apply

# En urgence :
kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.15-tiktok-native-owner-aware-prod -n keybuzz-admin-v2-prod
```

## Conclusion

**GO PARTIEL** — La page Google Tracking est deploye en PROD avec tout le contenu attendu :

- **Source verifiee** : meme commit exact que DEV (`8a12901`)
- **Build PROD OK** : tag `v2.11.16-google-admin-visibility-prod`, digest documente
- **Deploy OK** : pod Running, 0 restarts, image correcte
- **Validation structurelle complete** : tous les contenus presents (Support actif, Addingwell/sGTM, verite business, comparaison Meta/TikTok, zero faux connecteur)
- **Non-regression confirmee** : toutes les surfaces existantes intactes
- **Navigateur bloque** : mot de passe bootstrap bcrypt — limitation connue

### Action requise pour passer en GO definitif

L'utilisateur peut valider visuellement en se connectant a :
`https://admin.keybuzz.io/marketing/google-tracking`
avec ses credentials connus.

La page affichera le meme contenu que celui valide en DEV :
- Bandeau "Google Ads — Support actif"
- Architecture KeyBuzz → Addingwell/sGTM → Google Ads
- Tableau comparatif Meta Natif / TikTok Natif / Google Via sGTM
- Checklist agence d'activation
- Liens vers Integration Guide et Destinations

### Prochaine phase possible

- **GO definitif** : une fois la validation navigateur PROD confirmee par l'utilisateur
- **KEY-187** : evolutions fonctionnelles Google
- **Fermeture KEY-185** : la surface produit Google existe, la visibilite est assuree

## API/Client PROD inchanges

**Oui**

| Surface | Image | Inchangee |
|---|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.118-google-sgtm-owner-aware-quick-win-prod` | Oui |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.116-marketing-owner-stack-prod` | Oui |

---

**Chemin du rapport** : `keybuzz-infra/docs/PH-ADMIN-T8.10T-GOOGLE-ADMIN-VISIBILITY-PROD-PROMOTION-01.md`
