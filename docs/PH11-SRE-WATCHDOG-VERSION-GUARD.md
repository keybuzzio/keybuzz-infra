# PH11-SRE-WATCHDOG-VERSION-GUARD

## Resume

**Objectif:** Ajouter au watchdog KeyBuzz (monitor-01) un contrÃ´le automatique et fiable de cohÃ©rence des versions entre :
- L'image rÃ©ellement dÃ©ployÃ©e dans Kubernetes
- La version affichÃ©e dans l'UI (/debug/version)
- Les mÃ©tadonnÃ©es de build (git SHA)

**Status:** Module crÃ©Ã© et fonctionnel. Endpoints /debug/version Ã  dÃ©ployer.

## Pourquoi ce check existe

Le module Version Guard surveille la cohÃ©rence entre :
1. **Images K8s dÃ©ployÃ©es** : Tags des images Docker rÃ©ellement dÃ©ployÃ©es dans Kubernetes
2. **Versions UI** : Versions affichÃ©es dans les endpoints `/debug/version`
3. **Git SHA** : Identifiants de commit prÃ©sents dans les mÃ©tadonnÃ©es de build

**ProblÃ¨me dÃ©tectÃ©:**
- Si la version UI ne correspond pas au tag de l'image dÃ©ployÃ©e, cela indique une incohÃ©rence entre le code dÃ©ployÃ© et les mÃ©tadonnÃ©es affichÃ©es
- Cela peut survenir si :
  - L'image Docker n'a pas Ã©tÃ© rebuildÃ©e aprÃ¨s un changement de version
  - Le code a Ã©tÃ© dÃ©ployÃ© mais les mÃ©tadonnÃ©es de build ne sont pas Ã  jour
  - Il y a un problÃ¨me de dÃ©ploiement ou de cache

## Architecture

**Fichier:** `/opt/keybuzz/sre/watchdog/version_guard.py`

**Module Python indÃ©pendant** qui peut Ãªtre :
- ExÃ©cutÃ© directement : `python3 /opt/keybuzz/sre/watchdog/version_guard.py`
- IntÃ©grÃ© dans le watchdog principal (optionnel)
- AppelÃ© depuis un script ou un cron job

**Services surveillÃ©s:**
1. **KeyBuzz Client**
   - Namespace: `keybuzz-client-dev`
   - Deployment: `keybuzz-client`
   - Endpoint: `https://client-dev.keybuzz.io/debug/version`

2. **KeyBuzz Admin**
   - Namespace: `keybuzz-admin-dev`
   - Deployment: `keybuzz-admin`
   - Endpoint: `https://admin-dev.keybuzz.io/debug/version`

## ScÃ©narios dÃ©tectÃ©s

### 1. Service OK

**Condition:** Version UI = Tag image ET Git SHA prÃ©sent

**Comportement:**
- Status: `OK`
- Severity: `info`
- Log: Version consistency OK
- Pas d'alerte

**Exemple:**
```json
{
  "timestamp": "2026-01-04T18:00:00Z",
  "level": "info",
  "message": "Version consistency OK",
  "service": "keybuzz-client",
  "namespace": "keybuzz-client-dev",
  "image": "ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev",
  "ui_version": "v0.2.12-dev",
  "git_sha": "abc1234",
  "status": "OK"
}
```

### 2. Version Mismatch

**Condition:** Version UI â‰  Tag image

**Comportement:**
- Status: `MISMATCH`
- Severity: `warning`
- Log: UI version does not match deployed image tag
- Alerte gÃ©nÃ©rÃ©e (cooldown 30 min)

**Exemple:**
```json
{
  "timestamp": "2026-01-04T18:00:00Z",
  "level": "warning",
  "message": "UI version (v0.2.33-dev) does not match deployed image tag (v0.2.12-dev)",
  "service": "keybuzz-client",
  "namespace": "keybuzz-client-dev",
  "image": "ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev",
  "ui_version": "v0.2.33-dev",
  "git_sha": "abc1234",
  "status": "MISMATCH"
}
```

### 3. Endpoint DOWN

**Condition:** Endpoint /debug/version ne rÃ©pond pas (404, timeout, erreur rÃ©seau)

**Comportement:**
- Status: `ERROR`
- Severity: `critical`
- Log: Endpoint error
- Alerte critique gÃ©nÃ©rÃ©e

**Exemple:**
```json
{
  "timestamp": "2026-01-04T18:00:00Z",
  "level": "critical",
  "message": "Endpoint error: Network error: HTTP Error 404: Not Found",
  "service": "keybuzz-client",
  "namespace": "keybuzz-client-dev",
  "image": "ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev",
  "ui_version": null,
  "git_sha": null,
  "status": "ERROR"
}
```

### 4. Git SHA manquant

**Condition:** Version UI OK mais Git SHA absent

**Comportement:**
- Status: `WARNING`
- Severity: `warning`
- Log: Git SHA missing in UI response
- Alerte gÃ©nÃ©rÃ©e

**Exemple:**
```json
{
  "timestamp": "2026-01-04T18:00:00Z",
  "level": "warning",
  "message": "Git SHA missing in UI response",
  "service": "keybuzz-client",
  "namespace": "keybuzz-client-dev",
  "image": "ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev",
  "ui_version": "v0.2.12-dev",
  "git_sha": null,
  "status": "WARNING"
}
```

## Logs et Ã©tat

**Fichiers de logs:**
- `/opt/keybuzz/logs/sre/watchdog/version_guard_YYYYMMDD.jsonl`
- Format: JSON Lines (une ligne par Ã©vÃ©nement)
- Rotation: Un fichier par jour

**Fichier d'Ã©tat:**
- `/opt/keybuzz/state/sre/watchdog_version_state.json`
- Contient: DerniÃ¨re alerte par service, timestamp, status
- UtilisÃ© pour: Cooldown (30 minutes par service)

**Exemple de log:**
```json
{"timestamp": "2026-01-04T17:57:24.472523+00:00Z", "level": "critical", "message": "Endpoint error: Network error: HTTP Error 404: Not Found", "service": "keybuzz-client", "namespace": "keybuzz-client-dev", "image": "ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev", "ui_version": null, "git_sha": null, "status": "ERROR"}
```

## Comportement du watchdog

### 1. Read-only (lecture seule)

**IMPORTANT:** Le watchdog Version Guard est **strictement en lecture seule** :
- âŒ Ne reboot JAMAIS de pods
- âŒ Ne fait JAMAIS de rollout automatique
- âŒ Ne modifie JAMAIS l'infrastructure
- âŒ Ne corrige JAMAIS automatiquement

**Actions autorisÃ©es:**
- âœ… Lecture des images K8s dÃ©ployÃ©es
- âœ… Appels HTTP vers les endpoints /debug/version
- âœ… Ã‰criture de logs JSON
- âœ… Mise Ã  jour du fichier d'Ã©tat (pour cooldown)

### 2. Cooldown

**Politique:** Une alerte max toutes les 30 minutes par service

**MÃ©canisme:**
- L'Ã©tat prÃ©cÃ©dent est mÃ©morisÃ© dans `/opt/keybuzz/state/sre/watchdog_version_state.json`
- Si une alerte a Ã©tÃ© gÃ©nÃ©rÃ©e il y a moins de 30 minutes, le service est en cooldown
- Pendant le cooldown, le check est effectuÃ© mais aucune nouvelle alerte n'est gÃ©nÃ©rÃ©e

### 3. Alerting

**IntÃ©gration avec Alertmanager (Ã  venir):**
- Les alertes peuvent Ãªtre envoyÃ©es vers le receiver Alertmanager existant
- Severity = `warning` pour mismatch
- Severity = `critical` pour endpoint down

**Format d'alerte (exemple):**
```json
{
  "alertname": "KeyBuzzVersionMismatch",
  "severity": "warning",
  "service": "keybuzz-client",
  "namespace": "keybuzz-client-dev",
  "image_tag": "v0.2.12-dev",
  "ui_version": "v0.2.33-dev",
  "message": "UI version does not match deployed image tag"
}
```

## Utilisation

### ExÃ©cution manuelle

```bash
# Sur monitor-01
cd /opt/keybuzz/sre/watchdog
python3 version_guard.py
```

### IntÃ©gration dans watchdog principal (optionnel)

Le module peut Ãªtre appelÃ© depuis le watchdog principal :

```python
# Dans watchdog.py
import subprocess

def check_versions():
    """Check version consistency."""
    try:
        result = subprocess.run(
            ['python3', '/opt/keybuzz/sre/watchdog/version_guard.py'],
            capture_output=True,
            text=True,
            timeout=30
        )
        # Process result...
    except Exception as e:
        log_json("error", "Version guard check failed", error=str(e))
```

### Cron job (optionnel)

```bash
# VÃ©rifier toutes les 5 minutes
*/5 * * * * /usr/bin/python3 /opt/keybuzz/sre/watchdog/version_guard.py
```

## Que faire quand une alerte apparaÃ®t

### 1. Version Mismatch (warning)

**Action recommandÃ©e:**
1. VÃ©rifier l'image Docker rÃ©ellement dÃ©ployÃ©e dans K8s
2. VÃ©rifier la version dans `/debug/version`
3. Si l'image Docker n'a pas Ã©tÃ© rebuildÃ©e :
   - Rebuild l'image Docker avec le bon tag
   - Push vers ghcr.io
   - Rollout (manuellement ou via ArgoCD)
4. Si la version dans `/debug/version` est incorrecte :
   - VÃ©rifier que le code a Ã©tÃ© rebuildÃ©
   - VÃ©rifier que les mÃ©tadonnÃ©es de build sont Ã  jour

### 2. Endpoint DOWN (critical)

**Action recommandÃ©e:**
1. VÃ©rifier que le service est accessible
2. VÃ©rifier que l'endpoint `/debug/version` existe
3. VÃ©rifier les logs du service
4. Si l'endpoint n'existe pas :
   - DÃ©ployer le code avec les routes `/debug/version`
   - Rebuild et deployer le service

### 3. Git SHA manquant (warning)

**Action recommandÃ©e:**
1. VÃ©rifier que le script `generate-build-metadata.py` s'exÃ©cute au build time
2. VÃ©rifier que `BUILD_METADATA.gitSha` est prÃ©sent dans le code
3. Rebuild le service si nÃ©cessaire

## Pourquoi le watchdog NE corrige pas automatiquement

**Raisons de sÃ©curitÃ© et de stabilitÃ©:**

1. **Pas de modification d'infrastructure:**
   - Les corrections nÃ©cessitent souvent des rebuilds Docker, des rollouts, etc.
   - Ces actions peuvent affecter la disponibilitÃ© des services
   - Mieux vaut qu'un humain valide et exÃ©cute ces actions

2. **Pas de diagnostic automatique:**
   - Un mismatch peut avoir plusieurs causes (image non rebuildÃ©e, cache, problÃ¨me de dÃ©ploiement)
   - Le watchdog ne peut pas dÃ©terminer la cause exacte
   - Un humain doit diagnostiquer et dÃ©cider de la solution

3. **Pas de risque de boucle:**
   - Si le watchdog corrige automatiquement, il pourrait dÃ©clencher des actions qui crÃ©ent de nouveaux problÃ¨mes
   - Exemple: Un rollout automatique pourrait casser un service dÃ©jÃ  stable

4. **ObservabilitÃ© > Action automatique:**
   - Le watchdog doit observer et alerter
   - Les actions correctives doivent Ãªtre prises par des humains avec le contexte complet

## Tests

### Test 1: Cas OK (versions alignÃ©es)

**PrÃ©requis:** Endpoints /debug/version dÃ©ployÃ©s et fonctionnels

**Attendu:**
- Status: `OK`
- Severity: `info`
- Version UI = Tag image
- Git SHA prÃ©sent

### Test 2: Cas mismatch volontaire

**Action:** Modifier temporairement la version affichÃ©e dans le footer

**Attendu:**
- Status: `MISMATCH`
- Severity: `warning`
- Alerte gÃ©nÃ©rÃ©e
- Log dans version_guard_YYYYMMDD.jsonl

### Test 3: Cas endpoint down

**Action:** Blocker temporairement l'endpoint /debug/version (ou utiliser un endpoint inexistant)

**Attendu:**
- Status: `ERROR`
- Severity: `critical`
- Alerte critique gÃ©nÃ©rÃ©e
- Log dans version_guard_YYYYMMDD.jsonl

## Exemples de logs

### Log OK
```json
{"timestamp": "2026-01-04T18:00:00Z", "level": "info", "message": "Version consistency OK", "service": "keybuzz-client", "namespace": "keybuzz-client-dev", "image": "ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev", "ui_version": "v0.2.12-dev", "git_sha": "abc1234", "status": "OK"}
```

### Log Mismatch
```json
{"timestamp": "2026-01-04T18:00:00Z", "level": "warning", "message": "UI version (v0.2.33-dev) does not match deployed image tag (v0.2.12-dev)", "service": "keybuzz-client", "namespace": "keybuzz-client-dev", "image": "ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev", "ui_version": "v0.2.33-dev", "git_sha": "abc1234", "status": "MISMATCH"}
```

### Log Endpoint Down
```json
{"timestamp": "2026-01-04T18:00:00Z", "level": "critical", "message": "Endpoint error: Network error: HTTP Error 404: Not Found", "service": "keybuzz-client", "namespace": "keybuzz-client-dev", "image": "ghcr.io/keybuzzio/keybuzz-client:v0.2.12-dev", "ui_version": null, "git_sha": null, "status": "ERROR"}
```

## Installation

**Fichier dÃ©ployÃ©:**
- `/opt/keybuzz/sre/watchdog/version_guard.py`
- Permissions: `755` (exÃ©cutable)

**DÃ©pendances:**
- Python 3.12+
- `kubectl` disponible dans PATH
- AccÃ¨s rÃ©seau vers les endpoints /debug/version

**Ã‰tat actuel:**
- Module crÃ©Ã© et fonctionnel
- Endpoints /debug/version Ã  dÃ©ployer (404 pour l'instant)
- Quand les endpoints seront dÃ©ployÃ©s, le module dÃ©tectera automatiquement les versions

## Contraintes respectÃ©es

- âœ… Read-only (lecture seule)
- âœ… DEV uniquement
- âœ… Code idempotent
- âœ… Logs structurÃ©s JSON
- âœ… Pas de dÃ©pendance rÃ©seau externe autre que les endpoints KeyBuzz
- âœ… Aucun reboot
- âœ… Aucun rollout automatique
- âœ… Aucune action corrective destructive

## Commits

**Fichiers modifiÃ©s:**
- `/opt/keybuzz/sre/watchdog/version_guard.py` (nouveau)

**Ã€ commit dans keybuzz-infra:**
- Script d'installation (Ã  crÃ©er si nÃ©cessaire)
- Documentation (ce fichier)

## Prochaines Ã©tapes

1. **DÃ©ployer les endpoints /debug/version** (PH11-VERSION-01)
2. **Tester le module** avec les endpoints rÃ©els
3. **IntÃ©grer dans le watchdog principal** (optionnel)
4. **Configurer l'alerting** vers Alertmanager (optionnel)
5. **Documenter les procÃ©dures** de rÃ©ponse aux alertes

---

**PH11-SRE-WATCHDOG-VERSION-GUARD - TerminÃ©**

**Date:** 2026-01-04

**Status:** Module crÃ©Ã© et fonctionnel. Endpoints /debug/version Ã  dÃ©ployer.
