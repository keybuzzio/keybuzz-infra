# PH143-ROLLBACK-URGENT-01

> Date : 2026-04-07
> Type : Rollback d'urgence DEV
> Environnement : DEV uniquement — PROD non touchee

---

## 1. Image avant rollback

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.219-ph143-playbooks-real-fix-dev
```

Deployee dans `keybuzz-client-dev`, pod `keybuzz-client-65564fb74-bt4qh` (Running).

## 2. Image apres rollback

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.218-ph143-fr-real-fix-dev
```

Pod `keybuzz-client-65fc47847f-xng2p` (Running), rollout complete.

## 3. PROD intacte

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.216-ph143-francisation-prod
```

Aucune modification PROD. Pod stable, 3h+ d'uptime au moment du rollback.

## 4. Methode utilisee

**Script officiel GitOps** : `rollback-service.sh`

```bash
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh client dev v3.5.218-ph143-fr-real-fix-dev
```

Le script a :
1. Mis a jour le manifest `k8s/keybuzz-client-dev/deployment.yaml` via `sed`
2. Applique le manifest via `kubectl apply -f`
3. Attendu le rollout complet (`kubectl rollout status`)
4. Verifie l'image deployee dans le cluster

Suivi du commit + push GitOps :

```
Commit: 0fca432 "PH143-ROLLBACK-URGENT-01: DEV client rollback v3.5.219 -> v3.5.218"
Push: origin/main (d0d9df5 -> 0fca432)
```

## 5. Commandes reellement executees

```bash
# 1. Sync git bastion
cd /opt/keybuzz/keybuzz-infra
git pull origin main --ff-only  # 235c405 -> d0d9df5

# 2. Rollback
bash scripts/rollback-service.sh client dev v3.5.218-ph143-fr-real-fix-dev

# 3. Commit GitOps
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "PH143-ROLLBACK-URGENT-01: DEV client rollback v3.5.219 -> v3.5.218"
git push origin main
```

## 6. Resultat rollout

| Verification | Resultat |
|---|---|
| Rollout status | `successfully rolled out` |
| Pod | `keybuzz-client-65fc47847f-xng2p` — 1/1 Running |
| Image cluster | `v3.5.218-ph143-fr-real-fix-dev` |
| Manifest git | `v3.5.218-ph143-fr-real-fix-dev` |

## 7. URLs testees

| URL | HTTP |
|---|---|
| `https://client-dev.keybuzz.io/` | 200 |
| `https://client-dev.keybuzz.io/dashboard` | 200 |
| `https://client-dev.keybuzz.io/inbox` | 200 |
| `https://client-dev.keybuzz.io/settings` | 200 |
| `https://client-dev.keybuzz.io/playbooks` | 200 |
| `https://client-dev.keybuzz.io/billing` | 200 |

## 8. Cause de la derive PH143-FR.4

### Merge non controle

Le commit `7801ad1` (Merge `origin/main` into `rebuild/ph143-client`) a introduit :

- **211 fichiers modifies**
- **+39 392 lignes ajoutees**
- **-1 447 lignes supprimees**

### Contenu du merge non lie a PH143

Le merge a inclus entre autres :
- **Le module `keybuzz-studio/` complet** (~180+ fichiers, ~12 000+ lignes de `package-lock.json` seul)
- Des composants `AutopilotConversationFeedback`, `AutopilotDraftBanner`, `ConversationActionBar`
- Des modifications sur `AgentWorkbenchBar`, `AutopilotSection`, `SupervisionPanel`
- Le hook `usePlaybooks.ts` (338 lignes) — la cible initiale du fix

### Impact

L'introduction massive de code non teste et non lie au scope PH143 a cree des regressions visibles dans l'UI, rendant le build `v3.5.219` instable.

## 9. Regles non respectees par PH143-FR.4

| # | Regle | Violation |
|---|---|---|
| 1 | **Scope minimal** | Merge de `origin/main` = 211 fichiers au lieu de cherry-pick cible du seul `usePlaybooks.ts` |
| 2 | **Pas de merge large dans une branche de fix** | `origin/main` contenait des semaines de travail non lie (keybuzz-studio, autopilot, etc.) |
| 3 | **Test visuel obligatoire avant validation** | Le build a ete declare pret sans validation visuelle reelle (browser-use subagent indisponible) |
| 4 | **Principe de moindre changement** | +39 392 lignes dans un rollout cense corriger uniquement l'affichage Playbooks |
| 5 | **Isolation des branches de fix** | La branche `rebuild/ph143-client` a ete polluee par du code hors scope |
| 6 | **GitOps coherent** | Le manifest bastion etait desynchronise (v3.5.216 vs cluster v3.5.219), indiquant un deploiement potentiellement hors GitOps |

## 10. SHA infra avant/apres

| Moment | SHA | Message |
|---|---|---|
| Avant rollback (bastion) | `235c405` | PH143-FR: GitOps v3.5.216 francisation + report |
| Avant rollback (remote) | `d0d9df5` | PH143-FR.4 GitOps: client DEV v3.5.219 playbooks API-based fix |
| Apres rollback | `0fca432` | PH143-ROLLBACK-URGENT-01: DEV client rollback v3.5.219 -> v3.5.218 |

## 11. Etat gele

- **PH143-FR.4 est annule**
- **La ligne PH143 est gelee**
- Aucune nouvelle correction, aucun rebuild, aucun merge
- Attente validation humaine de Ludovic avant toute nouvelle tentative

---

## Verdict

```
ROLLBACK DEV EFFECTIF — PH143-FR.4 ANNULE
```

- DEV : `v3.5.218-ph143-fr-real-fix-dev` (stable, pre-merge)
- PROD : `v3.5.216-ph143-francisation-prod` (intacte)
- Ligne PH143 : **GELEE**
