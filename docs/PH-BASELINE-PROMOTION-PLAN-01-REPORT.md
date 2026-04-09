# PH-BASELINE-PROMOTION-PLAN-01 — RAPPORT

> Date : 1 mars 2026
> Mode : PLAN ONLY — Aucune modification executee
> Repo : keybuzz-client

---

## 1. SITUATION ACTUELLE

| Element | Valeur |
|---|---|
| Branche active bastion | `ph130-plan-gating` |
| Commit de reference | `e20ded6` |
| Image DEV deployee | `v3.5.100-ph131-fix-kbactions-dev` |
| Image PROD deployee | `v3.5.100-ph131-fix-kbactions-prod` |
| Branche par defaut GitHub | `main` |
| CI/CD automatise (GitHub Actions) | **AUCUN** — builds manuels sur bastion |
| ArgoCD pointant vers keybuzz-client | **AUCUN** |
| CronJobs referençant git pull keybuzz-client | **AUCUN** |
| ConfigMaps referençant une branche | **AUCUN** |
| Dockerfile referençant une branche | **AUCUN** |

### References a `main` trouvees

| Emplacement | Reference | Impact |
|---|---|---|
| GitHub (HEAD branch) | `main` = branche par defaut | **A CHANGER** — impact visuel + PRs par defaut |
| `.git/config` bastion | `[branch "main"]` tracking | **NEGLIGEABLE** — config locale, ne bloque rien |
| `keybuzz-infra/scripts/ph25_deploy_dev_auto.sh` | `git pull origin main` (lignes 62, 303, 415, 496) | **FAIBLE** — script ancien (PH25), pas execute par un CronJob |

**Conclusion : l'impact d'un changement de branche par defaut est MINIMAL.** Aucun pipeline automatise, aucun CronJob, aucun ArgoCD ne depend de la branche `main` pour keybuzz-client.

---

## 2. OPTIONS DE PROMOTION

### Option A — RECOMMANDEE : Promouvoir `ph130-plan-gating` comme nouveau `main`

**Principe** : force-push le contenu de `ph130-plan-gating` vers `main`, puis reprendre le travail normalement sur `main`.

**Avantages** :
- `main` redevient la source de verite (convention standard)
- Aucune reference a mettre a jour (GitHub, scripts, habitudes)
- Historique de `ph130-plan-gating` est propre, lineaire, 100% client
- Future documentation / onboarding naturels

**Operations** :
```
1. Sur le bastion :
   git checkout ph130-plan-gating
   git branch -m main main-archived    # renommer main locale
   git branch -m ph130-plan-gating main # renommer ph130 en main
   git push origin main --force         # force-push le nouveau main
   git push origin :ph130-plan-gating   # supprimer la branche distante obsolete
   git push origin main-archived        # archiver l'ancien main sur remote
```

**Risques** :
| Risque | Probabilite | Mitigation |
|---|---|---|
| Perte de l'ancien `main` | Nulle | Archivee en `main-archived` |
| Conflit pour d'autres dev | Nulle | Aucun autre contributeur actif |
| Script ph25 casse | Negligeable | Script non utilise actuellement |
| GitHub Pages/Actions | Nul | Aucun configure |

**Prerequis** :
- Confirmer qu'aucun autre contributeur ne travaille sur `main`
- Verifier que le push force est autorise sur GitHub (pas de branche protegee)

---

### Option B — Creer une branche `stable-baseline`

**Principe** : creer une nouvelle branche depuis `ph130-plan-gating` sans toucher a `main`.

**Avantages** :
- Zero risque (aucun changement sur main)
- Clair pour Cursor Executor : "toujours travailler sur `stable-baseline`"

**Inconvenients** :
- `main` reste contaminee et visible
- GitHub montre `main` par defaut (confusant)
- Risque qu'un futur prompt travaille par erreur sur `main`
- Nom non standard

**Operations** :
```
git checkout ph130-plan-gating
git checkout -b stable-baseline
git push origin stable-baseline
```

**Verdict** : Solution temporaire acceptable mais pas ideale a long terme.

---

### Option C — Archiver `main` et rester sur `ph130-plan-gating`

**Principe** : renommer `main` en `main-archived` sans la remplacer, garder `ph130-plan-gating` comme branche active.

**Avantages** :
- Main est clairement archivee
- Aucun force-push

**Inconvenients** :
- Pas de branche `main` (viole la convention Git)
- Nom `ph130-plan-gating` non intuitif pour le travail courant
- GitHub n'a plus de branche par defaut standard

**Verdict** : Deconseille. L'absence de `main` est source de confusion.

---

## 3. OPTION RECOMMANDEE : A

### Justification

| Critere | Option A | Option B | Option C |
|---|---|---|---|
| Clarte pour CE | Excellent | Bon | Moyen |
| Convention Git standard | Oui | Non | Non |
| Risque d'erreur future | Minimal | Moyen (main visible) | Moyen |
| Impact technique | Minimal | Zero | Faible |
| Perennite | Excellent | Temporaire | Mauvais |

---

## 4. IMPACTS PAR DOMAINE

### Impact CI/CD

**Aucun.** Il n'y a pas de CI/CD automatise pour keybuzz-client. Les builds sont entierement manuels sur le bastion.

### Impact Cursor Executor (CE)

| Avant | Apres |
|---|---|
| CE doit se rappeler "ne pas utiliser main" | CE travaille sur `main` normalement |
| Risque d'erreur si un prompt fait `git pull origin main` | `main` est propre et safe |
| Branche `ph130-plan-gating` = nom technique | `main` = convention standard |

### Impact futurs prompts

| Avant | Apres |
|---|---|
| Chaque prompt doit specifier "travailler sur `ph130-plan-gating`" | Comportement par defaut correct |
| Risque que CE oublie et travaille sur le mauvais `main` | Aucun risque |

### Impact keybuzz-infra scripts

| Script | Action requise |
|---|---|
| `ph25_deploy_dev_auto.sh` | **Aucune** — le `git pull origin main` tirera le bon code apres promotion |
| Tous les autres | **Aucune** — ils referencent des images Docker, pas des branches |

### Impact GitHub

| Element | Action requise |
|---|---|
| Branche par defaut | Sera automatiquement `main` (le nouveau `main`) |
| Pull Requests ouvertes | **Aucune** PR ouverte vers `main` actuellement |
| Branch protection rules | A verifier (si protegee, il faut la deproteger avant le force-push, puis la re-proteger) |

---

## 5. CHECK-LIST DE BASCULE

### Pre-requis (a verifier avant execution)

- [ ] Confirmer qu'aucun autre contributeur ne travaille sur `main`
- [ ] Verifier les branch protection rules sur GitHub (`Settings > Branches`)
- [ ] Verifier qu'aucune PR ouverte ne cible `main`
- [ ] Sauvegarder le SHA de l'ancien main : `852ef8f`

### Execution (dans cet ordre exact)

| # | Commande | Lieu | Description |
|---|---|---|---|
| 1 | `git checkout ph130-plan-gating` | Bastion | Se placer sur la base saine |
| 2 | `git branch -m main main-archived` | Bastion | Archiver l'ancien main localement |
| 3 | `git branch -m ph130-plan-gating main` | Bastion | Renommer ph130 en main |
| 4 | `git push origin main-archived` | Bastion | Sauvegarder l'archive sur remote |
| 5 | `git push origin main --force` | Bastion | Promouvoir le nouveau main |
| 6 | `git push origin :ph130-plan-gating` | Bastion | Supprimer la branche obsolete |
| 7 | `git branch -u origin/main main` | Bastion | Re-etablir le tracking |

### Verification post-bascule

- [ ] `git log --oneline -5 origin/main` montre PH131-FIX en HEAD
- [ ] `git log --oneline -5 origin/main-archived` montre PH-BILLING-FIX-B1 en HEAD
- [ ] `git status` est clean, branche `main`, up to date
- [ ] GitHub affiche `main` avec `e20ded6` comme dernier commit
- [ ] DEV runtime inchange (`v3.5.100-ph131-fix-kbactions-dev`)
- [ ] PROD runtime inchange (`v3.5.100-ph131-fix-kbactions-prod`)

### Nettoyage optionnel (plus tard)

- [ ] Supprimer la branche locale `main-archived` apres 30 jours si plus necessaire
- [ ] Supprimer la branche distante `main-archived` apres validation complete
- [ ] Supprimer les branches obsoletes : `fix/signup-redirect-v2`, `ph-s01.2d-cookie-domain`
- [ ] Evaluer `d16-settings` : garder si PH-TD-08 est pertinent, sinon archiver
- [ ] Mettre a jour la regle Cursor `keybuzz-v3-context.mdc` section "Repositories GitHub" (branche active = `main`)

---

## 6. TRAITEMENT DES BRANCHES SECONDAIRES

| Branche | Statut actuel | Recommandation | Priorite |
|---|---|---|---|
| `main` | Contaminee (56 commits, 20% toxiques) | → `main-archived` | Fait dans la bascule |
| `ph130-plan-gating` | Base saine (42 commits 100% client) | → nouveau `main` | Fait dans la bascule |
| `d16-settings` | Extension de ph130 (+1 commit PH-TD-08) | Evaluer PH-TD-08, puis archiver ou merger | Faible |
| `fix/signup-redirect-v2` | Sous-ensemble de ph130, local desynchronise | Supprimer | Faible |
| `ph-s01.2d-cookie-domain` | Ancienne, lignee differente | Supprimer | Faible |

---

## 7. TRAITEMENT DU FIX B1

Le seul commit potentiellement utile de l'ancien `main` est `852ef8f` (PH-BILLING-FIX-B1).

**Situation** :
- Le fix corrige `useCurrentPlan.tsx` pour utiliser `TenantProvider.currentTenantId` au lieu de `localStorage`
- Mais `ph130-plan-gating` contient deja `3e2e6ec PH-CHANNELS-BILLING: billing-compute BFF, useCurrentPlan channelsUsed`

**Recommandation** :
1. Apres la promotion de `main`, verifier si `useCurrentPlan.tsx` dans le nouveau `main` a deja le fix B1
2. Si non : appliquer le fix B1 comme un nouveau commit incremental (pas de cherry-pick de l'ancien)
3. Si oui : rien a faire

**Cette evaluation fait partie d'une phase future, pas de cette phase.**

---

## 8. REGLES POST-PROMOTION

Apres la bascule, les regles suivantes s'appliquent :

1. **`main` est la seule branche de travail** — plus de divergence multi-branches
2. **Tout nouveau travail part de `main`** — eventuellement sur des feature branches temporaires mergees rapidement
3. **Aucun commit non-client dans le repo client** — pas de code API, pas de SQL, pas de scripts infra
4. **Un `.dockerignore` fonctionnel est present** et doit etre maintenu
5. **Les builds se font depuis un etat Git clean uniquement** — `git status` propre avant chaque build
6. **Jamais de fichiers temporaires committes** — `.tmp_ssh_files/`, scripts de debug, etc.

---

## 9. VERDICT FINAL

### BASELINE PROMOTION PLAN READY

- Option recommandee : **A (promouvoir ph130 comme nouveau main)**
- Impact CI/CD : **AUCUN** (pas de CI/CD automatise)
- Impact CE : **POSITIF** (simplifie le workflow, elimine les erreurs)
- Impact runtime : **AUCUN** (images Docker ne dependent pas de la branche)
- Risque : **MINIMAL** (aucun autre contributeur, ancien main archive)
- Check-list : **7 commandes, 6 verifications**

---

*STOP POINT. Plan uniquement. Aucune modification executee.*
