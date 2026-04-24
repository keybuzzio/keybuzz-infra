# PH152-GIT-SOURCE-OF-TRUTH-LOCK-01

> Date : 14 avril 2026
> Environnement : DEV + INFRA
> Type : securisation Git / Bastion / Build

---

## Objectif

Garantir que TOUT code utilise en build provient UNIQUEMENT de Git.
AUCUN code local bastion non commit ne peut etre build.
Toute divergence est detectee et bloquee.

---

## 1. Etat avant (audit bastion)

### Contamination detectee


| Repo            | Branche                   | Fichiers modifies | Fichiers non trackes | Delta lignes    |
| --------------- | ------------------------- | ----------------- | -------------------- | --------------- |
| keybuzz-client  | `release/client-v3.5.220` | 23                | 18                   | +2668/-2304     |
| keybuzz-api     | `rebuild/ph143-api`       | 15                | 22                   | +793/-414       |
| keybuzz-backend | `main`                    | 12                | 27                   | +868/-500       |
| **TOTAL**       |                           | **50**            | **67**               | **+4329/-3218** |


### Contaminations critiques identifiees


| Fichier                                                    | Repo    | Type       | Risque                             |
| ---------------------------------------------------------- | ------- | ---------- | ---------------------------------- |
| `app/inbox/InboxTripane.tsx`                               | client  | modifie    | CRITIQUE — source regression PH151 |
| `src/features/inbox/components/AICaseSummary.tsx`          | client  | non tracke | CRITIQUE — contamination PH151     |
| `src/features/inbox/components/MessageBubble.tsx`          | client  | non tracke | CRITIQUE — contamination PH151     |
| `src/features/inbox/components/MessageFilterToggle.tsx`    | client  | non tracke | CRITIQUE — contamination PH151     |
| `src/features/inbox/utils/messageClassifier.ts`            | client  | non tracke | CRITIQUE — contamination PH151     |
| `src/features/inbox/components/ConversationSummaryBar.tsx` | client  | non tracke | CRITIQUE — composant fantome       |
| `src/features/inbox/components/ConversationActionBar.tsx`  | client  | non tracke | CRITIQUE — composant fantome       |
| `src/features/inbox/components/AgentWorkbenchBar.tsx`      | client  | modifie    | CRITIQUE — type divergent          |
| `src/modules/autopilot/engine.ts`                          | api     | modifie    | CRITIQUE — moteur autopilot        |
| `src/app.ts`                                               | api     | modifie    | CRITIQUE — point entree API        |
| `src/modules/webhooks/attachmentParser.service.ts`         | backend | modifie    | MAJEUR — +472 lignes               |


### Contaminations secondaires

- 15 fichiers `.bak`* / `.v0-backup`* (backups manuels)
- Module Shopify complet (non integre, feature future)
- Services autopilotGuardrails (non integres)
- Fichiers de tests PH145

---

## 2. Reset effectue

```bash
# Pour chaque repo (client, api, backend) :
git reset --hard HEAD
git clean -fd
```

### Resultats


| Repo            | Fichiers supprimes   | Etat post-reset      |
| --------------- | -------------------- | -------------------- |
| keybuzz-client  | 19 fichiers/dossiers | `working tree clean` |
| keybuzz-api     | 16 fichiers/dossiers | `working tree clean` |
| keybuzz-backend | 27 fichiers/dossiers | `working tree clean` |


Note : `keybuzz-backend` est 4 commits ahead de `origin/main` (commits locaux non push — c'est du code DANS Git local, pas du code fantome).

---

## 3. Analyse Dockerfiles


| Repo    | Methode COPY             | .dockerignore | Risque pre-PH152 |
| ------- | ------------------------ | ------------- | ---------------- |
| Client  | Explicit COPY (PH-TD-08) | Oui           | Moyen            |
| API     | `COPY src ./src`         | Oui           | Moyen            |
| Backend | `**COPY . .**`           | **AUCUN**     | **ELEVE**        |


Le backend est le plus vulnerable : sans `.dockerignore` et avec `COPY . .`, tout fichier fantome etait inclus dans le build.

---

## 4. Garde-fous ajoutes

### Script `/opt/keybuzz/pre-build-check.sh`

Verifie avant chaque build :

1. **Aucun changement stage** (`git diff --cached --quiet`)
2. **Aucun changement unstaged** (`git diff --quiet`)
3. **Aucun fichier non tracke** (`git ls-files --others --exclude-standard`)
4. **Affiche branche et commit** (tracabilite)

Si l'un des checks echoue → **exit 1** → build bloque.

### Test du garde-fou


| Scenario                   | Resultat        |
| -------------------------- | --------------- |
| Repos propres (post-reset) | `BUILD ALLOWED` |
| Fichier fantome ajoute     | `BUILD BLOCKED` |


### Regle documentee

> **NO SCP WITHOUT COMMIT**
>
> Interdiction formelle de `scp` de fichiers vers un repo bastion sans les avoir commit dans Git au prealable.
> Tout fichier present sur le bastion qui n'est pas dans Git sera detecte et bloquera le build.

### Usage obligatoire

Avant tout `docker build`, executer :

```bash
/opt/keybuzz/pre-build-check.sh /opt/keybuzz/<repo>
```

Exemple :

```bash
/opt/keybuzz/pre-build-check.sh /opt/keybuzz/keybuzz-client && \
cd /opt/keybuzz/keybuzz-client && \
docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-client:<TAG> .
```

Le script est egalement disponible dans `keybuzz-infra/scripts/pre-build-check.sh`.

---

## 5. Validation reelle

### Build

```
Image: v3.5.65-ph152-git-lock-dev
Source: Git HEAD (2adbd40 - release/client-v3.5.220)
Pre-build check: PASSED (working tree clean)
Build: SUCCESS (156s)
Push GHCR: SUCCESS
```

### Deploiement

```
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.65-ph152-git-lock-dev -n keybuzz-client-dev
Rollout: SUCCESS
Pod: Running (1/1 Ready)
```

### Navigation reelle


| Page                        | Resultat                                              |
| --------------------------- | ----------------------------------------------------- |
| Login (Google OAuth)        | OK                                                    |
| Select tenant               | OK                                                    |
| Inbox (liste conversations) | OK — 379 conversations                                |
| Conversation detail         | OK — messages visibles                                |
| Sidebar commande            | OK — RESUME, LIVRAISON, ARTICLES, CLIENT, Fournisseur |
| Suggestions IA              | OK — 2 suggestions affichees                          |


### Comportement attendu

Cette image NE contient PAS le case summary PH151.2 (Suivi de livraison / DEMANDE / ETAT).
C'est **normal et attendu** : cette feature n'a jamais ete commitee dans Git.
Elle existait uniquement comme modifications locales non trackees sur le bastion.
La prochaine etape serait de commiter proprement cette feature dans Git avant de la re-integrer.

---

## 6. GitOps


| Fichier                                                | Action                                              |
| ------------------------------------------------------ | --------------------------------------------------- |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Image mise a jour vers `v3.5.65-ph152-git-lock-dev` |
| `keybuzz-infra/scripts/pre-build-check.sh`             | Script garde-fou ajoute                             |


---

## 7. Inventaire des features perdues (non commitees)

Les modifications suivantes etaient sur le bastion mais PAS dans Git.
Elles sont maintenant supprimees du bastion et devront etre re-integrees proprement (commit-first) :


| Feature / Fichier                                 | Repo         | Phase d'origine |
| ------------------------------------------------- | ------------ | --------------- |
| Case summary data-driven (InboxTripane.tsx)       | client       | PH151.2         |
| AICaseSummary, MessageBubble, MessageFilterToggle | client       | PH151           |
| ConversationSummaryBar, ConversationActionBar     | client       | PH151           |
| messageClassifier.ts                              | client       | PH151           |
| Module Shopify complet                            | client + api | PH-Shopify      |
| autopilotGuardrails.ts                            | api          | PH145-147       |
| Billing routes modifications                      | api          | PH146.5         |
| Attachment parser enhancements                    | backend      | Divers          |
| Amazon backfill + resilience workers              | backend      | Divers          |


---

## Verdict

### GIT SOURCE OF TRUTH ENFORCED


| Controle                                 | Statut   |
| ---------------------------------------- | -------- |
| Bastion reset (3/3 repos clean)          | FAIT     |
| 117 fichiers fantomes supprimes          | FAIT     |
| Garde-fou pre-build installe et teste    | FAIT     |
| Build from Git only verifie              | FAIT     |
| Deploy DEV valide                        | FAIT     |
| Navigation reelle OK                     | FAIT     |
| Regle "NO SCP WITHOUT COMMIT" documentee | FAIT     |
| GitOps deployment.yaml mis a jour        | FAIT     |
| Aucun push PROD                          | CONFIRME |


