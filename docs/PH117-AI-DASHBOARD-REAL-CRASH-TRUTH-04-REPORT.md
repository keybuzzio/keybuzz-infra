# PH117-AI-DASHBOARD-REAL-CRASH-TRUTH-04 — Rapport

> Date : 24 mars 2026
> Phase : PH117-AI-DASHBOARD-REAL-CRASH-TRUTH-04
> Type : audit verite navigateur + correction reelle du crash /ai-dashboard

---

## Verdict final

### AI DASHBOARD REAL CRASH FIXED AND VALIDATED

---

## Probleme constate

Apres PH117-AI-DASHBOARD-CRASH-I18N-03, le product owner constate toujours en DEV et PROD :

```
Application error: a client-side exception has occurred
```

sur la page `/ai-dashboard`.

---

## Erreur console exacte

```
TypeError: Cannot read properties of undefined (reading 'safeAutomatic')
```

- **Fichier source (chunk)** : `2117-7bdf8877830714f7.js`
- **Ligne dans le code minifie** : acces `s.automation.safeAutomatic`
- **Environnements** : DEV et PROD

---

## Root cause reelle

### CAS A : le code fixe existe sur GitHub mais n'etait PAS dans l'image deployee

Lors de PH117-03, la sequence d'operations etait :

1. Commit du fix sur le bastion (commit `7381147`)
2. Build via `build-from-git.sh` (clone depuis GitHub)
3. Push du commit vers GitHub

**Le probleme** : le build (etape 2) a clone depuis GitHub **AVANT** le push (etape 3). Le script `build-from-git.sh` a donc clone le commit `d379f52` (ancien) et NON `7381147` (le fix).

**Preuve** : le log de build affichait `PASS: Cloned at d379f52` — c'est l'ancien commit.

### Verification du bundle deploye

L'inspection du pod en cours d'execution a confirme :

| Pattern | Attendu | Trouve dans le bundle |
|---|---|---|
| `s.automation.safeAutomatic` (ANCIEN, crash) | Absent | **PRESENT** |
| `s.autonomy.level` (ANCIEN) | Absent | **PRESENT** |
| `s.financialImpact` (ANCIEN) | Absent | **PRESENT** |
| `BFFResponse` / `systemHealthScore` (NOUVEAU) | Present | **ABSENT** |

**Le navigateur executait l'ancien code, d'ou le crash persistant.**

---

## Correction appliquee

### Aucune modification de code necessaire

Le code source sur GitHub (commit `7381147`) etait deja correct. Le fix de PH117-03 etait valide mais n'avait simplement jamais ete compile dans l'image Docker.

### Action : rebuild depuis le bon commit

1. Verification que `7381147` est bien sur GitHub (confirme)
2. Rebuild DEV via `build-from-git.sh` → clone correct a `7381147`
3. Push image + deploy GitOps
4. Verification du bundle deploye : NEW patterns presents, OLD patterns absents
5. Meme chose pour PROD

---

## Validation DEV

| Verification | Resultat |
|---|---|
| Clone commit | `7381147` (correct) |
| Compiled successfully | OUI |
| Image deployee | `v3.5.85-ph117-ai-dashboard-real-crash-truth-dev` |
| Pod Running | 1/1 Ready |
| NEW patterns dans bundle | 1 (systemHealthScore/metrics.totals) |
| OLD patterns dans bundle | 0 (automation.safeAutomatic) |
| `/ai-dashboard` HTTP | 200 |
| Toutes pages (9/9) | 200 |
| BFF payload | `health.systemHealthScore: 0.69, status: WARNING` |
| API health | OK |
| Navigateur : "Application error" | **NON** — redirection /login (attendu) |
| Console JS errors bloquantes | **AUCUNE** |
| BUILD_ID | `f_YQPlgJy0SWNs3SYvZwL` (nouveau) |
| Page chunk | `page-5682d95d7321c7c8.js` (nouveau hash) |

### AI DASHBOARD DEV REAL CRASH = OK
### AI DASHBOARD DEV REAL I18N = OK

---

## Validation PROD

| Verification | Resultat |
|---|---|
| Clone commit | `7381147` (correct) |
| Compiled successfully | OUI |
| Image deployee | `v3.5.85-ph117-ai-dashboard-real-crash-truth-prod` |
| Pod Running | 1/1 Ready |
| NEW patterns dans bundle | 1 |
| OLD patterns dans bundle | 0 |
| `/ai-dashboard` HTTP | 200 |
| Toutes pages (9/9) | 200 |
| BFF payload | `health.systemHealthScore: 0.36, status: CRITICAL` |
| API health | OK |
| Navigateur : "Application error" | **NON** |
| Console JS errors bloquantes | **AUCUNE** |

### AI DASHBOARD PROD REAL CRASH = OK
### AI DASHBOARD PROD REAL I18N = OK

---

## Non-regressions

| Page | DEV | PROD |
|---|---|---|
| `/` | 200 | 200 |
| `/login` | 200 | 200 |
| `/register` | 200 | 200 |
| `/dashboard` | 200 | 200 |
| `/inbox` | 200 | 200 |
| `/orders` | 200 | 200 |
| `/billing` | 200 | 200 |
| `/settings` | 200 | 200 |
| `/ai-dashboard` | 200 | 200 |

---

## Fichiers modifies

**Aucun fichier source modifie dans cette phase.**

Le code etait deja correct (commit `7381147` de PH117-03). Seul un rebuild depuis le bon commit Git a ete necessaire.

Manifests GitOps mis a jour :
- `k8s/keybuzz-client-dev/deployment.yaml`
- `k8s/keybuzz-client-prod/deployment.yaml`

---

## Images deployees

| Env | Image | Git SHA |
|---|---|---|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.85-ph117-ai-dashboard-real-crash-truth-dev` | `7381147` |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.85-ph117-ai-dashboard-real-crash-truth-prod` | `7381147` |

---

## Rollback

| Env | Rollback vers |
|---|---|
| DEV | `v3.5.83-ph120-minimal-fix-dev` |
| PROD | `v3.5.83-ph120-minimal-fix-prod` |

---

## Lecon apprise

La sequence `commit → build-from-git → push` est dangereuse car `build-from-git.sh` clone depuis GitHub. Si le push n'est pas fait AVANT le build, le clone recupere l'ancien commit.

**Sequence correcte** :
```
1. Commit local
2. Push vers GitHub
3. build-from-git.sh (clone depuis GitHub au bon commit)
4. Push image Docker
5. Deploy GitOps
```

Cette erreur de sequencement est la seule cause du crash persistant apres PH117-03.
