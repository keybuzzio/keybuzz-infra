# PH143-R1 — Release Line Recovery Audit

> Date : 2026-04-07
> Type : Audit lecture seule — zero modification
> Environnement : DEV uniquement (lecture)
> Prerequis : rollback PH143-ROLLBACK-URGENT-01 effectif

---

## 1. Etat exact des branches

### Cartographie du repo `keybuzz-client` (bastion)

| Branche | HEAD | SHA | Studio | Role | Fiable |
|---|---|---|---|---|---|
| `rebuild/ph143-client` (local) | PH143-FR.4 SupervisionPanel fix | `6ffeebd` | **191 fichiers** | PH143 post-merge FR.4 | **NON** — contaminee |
| `origin/rebuild/ph143-client` (remote) | PH143-FR.3 accents + playbooks | `e87da0e` | **0** | PH143 pre-merge | **OUI** |
| `origin/main` | PH148-O3 AgentWorkbenchBar types | `1a7c51d` | **191 fichiers** | Branche dev principale | **NON** pour release client |
| `main` (local bastion) | PH148-O3 (tracking origin/main) | `1a7c51d` | **191 fichiers** | Copie locale origin/main | **NON** pour release client |
| `d16-settings` | PH-TD-08 sync bastion | `db8f4a8` | ? | Ancienne branche settings | Non pertinente |
| `backup/pre-ph143-client-20260301` | = origin/main | `1a7c51d` | **191 fichiers** | Tag backup = origin/main | **NON** — IS origin/main |

**Comptage Studio :** 139 fichiers `keybuzz-studio/` + 52 fichiers `keybuzz-studio-api/` = **191 fichiers parasites**

### Point de divergence

`rebuild/ph143-client` a ete forkee depuis le commit `8542bf0` (PH131-B.2: rename Autopilot to Pilotage IA).

La contamination Studio est entree UNIQUEMENT via le merge `7801ad1` (FR.4).

---

## 2. Base saine recommandee

### Reponses explicites

| Question | Reponse |
|---|---|
| Dernier commit reellement sur pour repartir | **`e87da0e`** (PH143-FR.3) |
| Commit correspondant au rollback DEV actuel | **`e87da0e`** — build `v3.5.218-ph143-fr-real-fix-dev` |
| Commit correspondant a la PROD actuelle | **`4d9d736`** — build `v3.5.216-ph143-francisation-prod` |
| Branche exploitable comme base propre | **`origin/rebuild/ph143-client`** pointant sur `e87da0e` |
| `origin/main` est-elle exploitable ? | **NON** — contient 191 fichiers Studio |

### Pourquoi `e87da0e` est la base saine

1. **0 fichier Studio** — verifie par `git ls-tree`
2. **Prouve stable** — build `v3.5.218` deployee et fonctionnelle en DEV
3. **Contient tout PH143** — 21 commits de la chaine PH143 (B → H, E.4-E.10, UX, FR.1-FR.3)
4. **Superset de PROD** — contient tout ce que PROD a, plus FR.2 et FR.3

---

## 3. Diff DEV / PROD / branche polluee

### A. DEV stable (`e87da0e`) vs PROD (`4d9d736`)

**Delta : 2 commits, 12 fichiers, +36/-33 lignes**

| Fichier | Type de modification |
|---|---|
| `app/orders/page.tsx` | Accents francisation |
| `app/playbooks/page.tsx` | Fix overrideTenantId |
| `app/settings/components/AgentsTab.tsx` | Accents |
| `app/settings/components/HoursTab.tsx` | Accents |
| `app/settings/components/VacationsTab.tsx` | Accents |
| `app/settings/constants.ts` | Accents |
| `app/settings/page.tsx` | Accents |
| `src/features/ai-ui/LearningControlSection.tsx` | Accents IA |
| `src/features/inbox/components/EscalationPanel.tsx` | Accent |
| `src/features/knowledge/seedTemplates.ts` | Accent |
| `src/features/pricing/config.ts` | Accent |
| `src/services/playbooks.service.ts` | Fix overrideTenantId |

**Conclusion :** le delta DEV/PROD est minime et exclusivement cosmétique (accents + un fix playbooks localStorage inefficace).

### B. DEV stable (`e87da0e`) vs branche polluee (`6ffeebd`)

**Delta : 210 fichiers, +39 232 / -1 366 lignes**

| Categorie | Fichiers | Lignes |
|---|---|---|
| `keybuzz-studio/` | 139 | ~25 000+ |
| `keybuzz-studio-api/` | 52 | ~3 000+ |
| `.cursor/rules/studio-rules.mdc` | 1 | ~200 |
| Fichiers client modifies | 18 | ~11 000 |
| **Total** | **210** | **+39 232** |

### C. Fichiers client modifies par le merge (hors Studio)

| Fichier | Source probable | Evaluation |
|---|---|---|
| `app/api/amazon/inbound-address/route.ts` | PH-AMZ-INBOUND-ADDRESS | a evaluer |
| `app/api/amazon/inbound-address/send-validation/route.ts` | PH-AMZ-INBOUND-ADDRESS | a evaluer |
| `app/api/playbooks/[id]/simulate/route.ts` | PH-PLAYBOOKS-ENGINE | candidat |
| `app/api/space-invites/resolve/route.ts` | PH142 | a evaluer |
| `app/channels/page.tsx` | inconnu | a evaluer |
| `app/inbox/InboxTripane.tsx` | PH142/PH148 | a evaluer |
| `app/playbooks/[playbookId]/page.tsx` | PH-PLAYBOOKS-BACKEND | candidat |
| `app/playbooks/[playbookId]/tester/page.tsx` | PH-PLAYBOOKS-ENGINE | candidat |
| `app/playbooks/new/page.tsx` | PH-PLAYBOOKS-BACKEND | candidat |
| `app/playbooks/page.tsx` | PH-PLAYBOOKS-BACKEND | candidat |
| `app/settings/components/SignatureTab.tsx` | inconnu | a evaluer |
| `src/features/ai-ui/AutopilotSection.tsx` | PH131/PH142 | a evaluer |
| `src/features/inbox/components/AgentWorkbenchBar.tsx` | PH148 | a evaluer |
| `src/features/inbox/components/AutopilotConversationFeedback.tsx` | NOUVEAU | a evaluer |
| `src/features/inbox/components/AutopilotDraftBanner.tsx` | NOUVEAU | a evaluer |
| `src/features/inbox/components/ConversationActionBar.tsx` | NOUVEAU | a evaluer |
| `src/hooks/usePlaybooks.ts` | PH-PLAYBOOKS-BACKEND | **candidat prioritaire** |

---

## 4. Inventaire des fixes a conserver

### Fixes PH143 valides (tous dans `e87da0e`, deja en DEV + PROD)

| Feature | Phase | Commit | DEV | PROD | Conserver |
|---|---|---|---|---|---|
| Billing plans addon rebuild | PH143-B | `d5c7acb` | oui | oui | **oui** |
| Agents RBAC rebuild | PH143-C | `a5d5988` | oui | oui | **oui** |
| IA Assist rebuild | PH143-D | `88c6d31` | oui | oui | **oui** |
| Autopilot BFF routes | PH143-E | `9918196` | oui | oui | **oui** |
| Signature deep-links | PH143-F | `909a9e8..622439d` | oui | oui | **oui** |
| SupervisionPanel dashboard | PH143-G | `5a19a23` | oui | oui | **oui** |
| BFF tracking/status | PH143-H | `924f4a1` | oui | oui | **oui** |
| Autopilot pipeline fix | PH143-E.4 | `0d6d475` | oui | oui | **oui** |
| Escalation visibility | PH143-E.5 | `4492b8d` | oui | oui | **oui** |
| Escalation refresh | PH143-E.6 | `81d5efb` | oui | oui | **oui** |
| Escalation reload | PH143-E.10 | `61a0257` | oui | oui | **oui** |
| UX escalation compact + tooltip | PH143 | `2d7d686..8424b5b` | oui | oui | **oui** |
| Mon travail compact filters | PH143 | `bc18024` | oui | oui | **oui** |
| Tous filter always visible | PH143 | `df3aca9` | oui | oui | **oui** |
| Francisation complete | PH143-FR | `4d9d736` | oui | oui | **oui** |
| Fix full french + regressions | PH143-FR.2 | `45c2682` | oui | non | **oui** |
| Fix IA accents + playbooks | PH143-FR.3 | `e87da0e` | oui | non | **oui** |

### Fixes hors PH143 (dans `origin/main`, candidats futurs)

| Feature | Phase | Commit | Fichiers | A conserver | A exclure |
|---|---|---|---|---|---|
| Playbooks backend migration | PH-PLAYBOOKS-BACKEND-02 | `e5034ab` | 5 | **candidat** | |
| Playbooks engine alignment | PH-PLAYBOOKS-ENGINE-02B | `032f0d0` | 2 | **candidat** | |
| PlanProvider fix | PH-BILLING-TRUTH-02 | `3fae402` | ? | a evaluer | |
| Amazon inbound address | PH-AMZ-INBOUND | `8dc1ca5..3ce2f3a` | ? | a evaluer | |
| Autopilot badge | PH131-C | `364222e` | ? | a evaluer | |
| PH142 changes | PH142-N..O2 | `1b22fac..f3cb7e2` | ? | a evaluer | |
| PH148 SLA+SUP+TRK routes | PH148-O3 | `29ee06e..1a7c51d` | ? | a evaluer | |

### Elements a exclure formellement

| Element | Phase | Raison |
|---|---|---|
| `keybuzz-studio/` (139 fichiers) | PH-STUDIO-01..07A.1 | Produit separe |
| `keybuzz-studio-api/` (52 fichiers) | PH-STUDIO-01..07A.1 | Produit separe |
| `.cursor/rules/studio-rules.mdc` | PH-STUDIO | Config Studio |
| Merge `7801ad1` | PH143-FR.4 | Merge large non controle |
| Fix `6ffeebd` | PH143-FR.4 | Patch sur merge contamine |

---

## 5. Audit de contamination Studio

### Comment Studio est entre dans la ligne client

| Vecteur | Detail |
|---|---|
| **Repo partage** | `keybuzz-studio/` et `keybuzz-studio-api/` vivent dans le meme repo git que `keybuzz-client` |
| **Branche partagee** | `origin/main` contient les deux produits (client + Studio) |
| **Commits source** | `f9d59ae` (PH-STUDIO-01+02), `ecce67f` (sync PH-STUDIO-03..07A), `375753b` (07A), `f4bfa03` (07A.1) |
| **Moment de contamination** | Le merge `7801ad1` (FR.4) a importe `origin/main` en entier dans `rebuild/ph143-client` |
| **Avant le merge** | `e87da0e` = 0 fichiers Studio |
| **Apres le merge** | `6ffeebd` = 191 fichiers Studio |

### Analyse des garde-fous

| Garde-fou | Statut | Analyse |
|---|---|---|
| Repo separe pour Studio | **ABSENT** | Studio vit dans le meme repo que Client |
| Branche dediee pour Studio | **ABSENT** | Les commits Studio sont directement sur `main` |
| `.dockerignore` pour Studio | **Inconnu** | A verifier — possiblement absent dans le Dockerfile client |
| Gate de diff avant build | **ABSENT** | Aucune verification du nombre de fichiers/lignes avant build |
| Review humaine du merge | **ABSENT** | Le merge FR.4 n'a pas ete revu avant build |
| Test visuel automatise | **INDISPONIBLE** | Le subagent browser-use n'a pas pu valider |

### Reponses explicites

| Question | Reponse |
|---|---|
| Bastion partage = probleme ? | **Non directement** — le bastion peut heberger les deux tant que les branches sont separees |
| Repo partage = probleme ? | **OUI** — c'est la cause racine. Un `git merge main` importe tout Studio |
| Branche partagee = probleme ? | **OUI** — `origin/main` melange client et Studio, rendant tout merge risque |
| Separation stricte recommandee | **OUI** — soit repo separe, soit convention de branches strictes avec `.gitignore` cible |

### Recommandation de separation

**Court terme (R2)** : Ne jamais merger `origin/main` dans une branche release client. Cherry-pick uniquement les commits client identifies.

**Moyen terme** : Ajouter dans `.dockerignore` du client :
```
keybuzz-studio/
keybuzz-studio-api/
.cursor/rules/studio-rules.mdc
```

**Long terme** : Migrer `keybuzz-studio` et `keybuzz-studio-api` dans un repo git separe.

---

## 6. Strategie de reconstruction propre

### Options evaluees

#### Option A — Nouvelle branche depuis DEV stable (`e87da0e`)

- **Base** : `e87da0e` (PH143-FR.3, 0 Studio, build `v3.5.218` prouvee)
- **Methode** : `git checkout -b release/client-v3.5.220 e87da0e`
- **Ajouts futurs** : cherry-pick cible si necessaire (ex: `e5034ab` pour playbooks API)
- **Risque** : **minimal** — la base est identique a ce qui tourne en DEV aujourd'hui
- **Avantage** : contient tout PH143 FR.1-FR.3, superset de PROD

#### Option B — Nouvelle branche depuis PROD (`4d9d736`)

- **Base** : `4d9d736` (PH143-FR.1, 0 Studio, build `v3.5.216` en production)
- **Methode** : `git checkout -b release/client-v3.5.220 4d9d736`
- **Ajouts** : cherry-pick de `45c2682` (FR.2) et `e87da0e` (FR.3) + tout ajout cible
- **Risque** : faible mais travail supplementaire (re-appliquer FR.2 et FR.3)
- **Avantage** : le point de depart le plus conservateur possible

#### Option C — Depuis `origin/main` avec exclusion Studio

- **NON RECOMMANDE**
- `origin/main` contient 191 fichiers Studio + des commits PH142/PH148 non valides
- Necessiterait un `git rm` massif et un revert complexe
- Risque eleve de regression

### Recommandation : Option A

| Critere | Valeur |
|---|---|
| **Base** | `e87da0e` |
| **Nom de branche** | `release/client-v3.5.220` |
| **Methode** | Branche directe, zero merge, cherry-pick cible uniquement |
| **Risque** | Minimal — base identique au DEV stable actuel |
| **Contenu garanti** | 21 commits PH143, 0 Studio, 0 PH142/PH148 |
| **Raison** | C'est exactement le code qui tourne en DEV maintenant, prouve fonctionnel |

### Si le fix Playbooks API est requis ensuite

Cherry-pick cible de 2 commits seulement :
1. `e5034ab` — PH-PLAYBOOKS-BACKEND-MIGRATION-02 (5 fichiers)
2. `032f0d0` — PH-PLAYBOOKS-ENGINE-ALIGNMENT-02B (2 fichiers)

Total : **7 fichiers** au lieu des 210 du merge FR.4.

---

## 7. Workflow conventionnel et deviations

### Workflow attendu

```
1. Branche release propre depuis base validee
2. Cherry-pick cible des commits voulus (zero merge large)
3. Build Docker depuis la branche release (--no-cache)
4. Deploy image candidate en DEV
5. Validation visuelle humaine sur DEV
6. Si GO : rebuild avec tag -prod, deploy PROD
7. Si NOGO : rollback DEV, analyser, corriger
8. GitOps : commit deployment.yaml a chaque etape
9. Rollback documente avec rollback-service.sh
```

### Ce qui a devie dans PH143-FR.4

| Etape | Deviation | Consequence |
|---|---|---|
| 2 | **Merge entier de `origin/main`** au lieu de cherry-pick | 210 fichiers, +39K lignes, contamination Studio |
| 3 | **Build depuis branche contaminee** sans revue du diff | Image instable avec code hors scope |
| 5 | **Pas de validation visuelle** (browser-use indisponible, validation API seulement) | Regressions non detectees avant deploiement |
| 8 | **Desync GitOps** (manifest bastion a v3.5.216 alors que cluster a v3.5.219) | Indicateur que le deploiement a contourne le chemin GitOps |

### Comment empecher que ca recommence

| Garde-fou | Implementation |
|---|---|
| **Interdire `git merge main`** dans les branches release | Regle de processus documentee + verification pre-build |
| **Cherry-pick only** | Tout ajout a une branche release = cherry-pick cible, jamais merge |
| **Diff check pre-build** | Verifier `git diff --stat base..HEAD` avant build : si > 50 fichiers, STOP |
| **Validation visuelle obligatoire** | Aucun verdict GO sans capture d'ecran reelle ou validation humaine |
| **`.dockerignore` Studio** | Ajouter `keybuzz-studio/`, `keybuzz-studio-api/` au `.dockerignore` client |
| **GitOps coherent** | Toujours deployer via `rollback-service.sh` ou manifest → apply, jamais `kubectl set image` direct |

---

## 8. Verdict

```
RELEASE RECOVERY PLAN READY
```

### Resume

| Element | Valeur |
|---|---|
| Base saine identifiee | **`e87da0e`** (PH143-FR.3, 0 Studio, DEV stable) |
| Branche exploitable | **`origin/rebuild/ph143-client`** (remote, pointe sur `e87da0e`) |
| Strategie recommandee | **Option A** — nouvelle branche release depuis `e87da0e` |
| Fix playbooks si necessaire | Cherry-pick `e5034ab` + `032f0d0` (7 fichiers) |
| Elements a exclure | 191 fichiers Studio, commits PH142/PH148 non evalues |
| Prochaine etape | **PH143-R2** — creation branche release + build + validation |

### Pre-requis pour R2

- [ ] Validation de Ludovic sur la strategie Option A
- [ ] Decision sur l'inclusion du fix Playbooks API (cherry-pick ou non)
- [ ] Decision sur les autres commits candidats (PH-BILLING-TRUTH, PH-AMZ-INBOUND, etc.)
- [ ] Ajout de `keybuzz-studio/` et `keybuzz-studio-api/` au `.dockerignore` client
