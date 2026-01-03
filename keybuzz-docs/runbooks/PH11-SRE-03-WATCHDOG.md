# PH11-SRE-03: KeyBuzz Kubernetes Node Watchdog

## Overview

Le watchdog KeyBuzz surveille l'état des nœuds Kubernetes et effectue une récupération automatique via l'API Hetzner Cloud en cas de défaillance.

**Version:** 1.0.0  
**Localisation:** monitor-01 (10.0.0.152)  
**Auteur:** KeyBuzz SRE Team

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       monitor-01                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │           keybuzz-watchdog.timer (60s)                    │  │
│  │                       │                                    │  │
│  │                       ▼                                    │  │
│  │           keybuzz-watchdog.service                        │  │
│  │                       │                                    │  │
│  │                       ▼                                    │  │
│  │              watchdog.py                                   │  │
│  │           ┌─────────────────┐                              │  │
│  │           │  kubectl        │──► K8s API (nodes status)   │  │
│  │           │  hcloud         │──► Hetzner API (power ops)  │  │
│  │           └─────────────────┘                              │  │
│  │                       │                                    │  │
│  │                       ▼                                    │  │
│  │    /opt/keybuzz/logs/sre/watchdog/*.jsonl                 │  │
│  │    /opt/keybuzz/state/sre/watchdog_state.json             │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Fichiers et Emplacements

| Fichier | Emplacement | Description |
|---------|-------------|-------------|
| Script principal | `/opt/keybuzz/sre/watchdog/watchdog.py` | Code Python du watchdog |
| Configuration | `/opt/keybuzz/sre/watchdog/config.yaml` | Paramètres configurables |
| État | `/opt/keybuzz/state/sre/watchdog_state.json` | Cooldowns, tentatives |
| Logs | `/opt/keybuzz/logs/sre/watchdog/watchdog_*.jsonl` | Logs JSON lines |
| Status | `/opt/keybuzz/logs/sre/watchdog/watchdog_last_status.json` | Dernier état |
| Alertes | `/opt/keybuzz/logs/sre/watchdog/alerts.jsonl` | Alertes (NEEDS_HUMAN) |
| Credentials | `/opt/keybuzz/credentials/hcloud.env` | Token Hetzner |
| Service | `/etc/systemd/system/keybuzz-watchdog.service` | Unit systemd |
| Timer | `/etc/systemd/system/keybuzz-watchdog.timer` | Timer 60s |
| Logrotate | `/etc/logrotate.d/keybuzz-watchdog` | Rotation logs |

## Configuration

```yaml
# /opt/keybuzz/sre/watchdog/config.yaml

# Nombre d'échecs consécutifs avant action
consecutive_failures_threshold: 3

# Période de cooldown après action (minutes)
cooldown_minutes: 20

# Maximum de tentatives par nœud par 24h
max_attempts_per_24h: 3

# Timeout de récupération (secondes)
recovery_timeout_seconds: 180

# Mode dry-run (log sans exécuter)
dry_run: false

# Nœuds exclus (jamais touchés)
excluded_nodes: []
  # - k8s-master-01
```

## Logique de Récupération

### 1. Détection

Le watchdog vérifie l'état de tous les nœuds K8s toutes les 60 secondes:

```
kubectl get nodes -o json
```

Un nœud est considéré "problématique" si:
- Condition `Ready != True`
- Ou nœud absent de la liste

### 2. Seuil d'Action

Le watchdog ne prend action qu'après **N échecs consécutifs** (par défaut: 3).

Cela évite les faux positifs lors de:
- Redémarrages planifiés
- Mises à jour kubelet
- Latences réseau temporaires

### 3. Actions de Récupération (ordre strict)

```
1. kubectl cordon <node>          # Marquer non-schedulable
2. kubectl drain <node>           # Évacuer les pods
3. hcloud server poweroff <id>    # Éteindre via Hetzner
4. hcloud server poweron <id>     # Rallumer via Hetzner
5. Attendre Ready (180s)          # Vérifier retour
6. Si échec: hcloud server reset  # Reset hardware
7. Si OK: kubectl uncordon        # Remettre schedulable
```

### 4. Garde-fous

| Protection | Valeur par défaut | Description |
|------------|-------------------|-------------|
| Cooldown | 20 minutes | Période d'attente après une action |
| Max attempts/24h | 3 | Limite de tentatives par nœud |
| Recovery timeout | 180s | Temps max d'attente pour Ready |
| Excluded nodes | [] | Nœuds à ne jamais toucher |

### 5. État NEEDS_HUMAN

Si un nœud dépasse les limites (max attempts), le watchdog:
- Écrit une alerte dans `alerts.jsonl`
- Log le statut "NEEDS_HUMAN"
- Ne tente plus de récupération automatique

## Commandes Opérationnelles

### Démarrer/Arrêter

```bash
# Démarrer le timer
systemctl start keybuzz-watchdog.timer

# Arrêter le timer
systemctl stop keybuzz-watchdog.timer

# Exécution manuelle unique
systemctl start keybuzz-watchdog.service

# Status
systemctl status keybuzz-watchdog.timer
systemctl status keybuzz-watchdog.service
```

### Logs et Monitoring

```bash
# Logs en temps réel
tail -f /opt/keybuzz/logs/sre/watchdog/watchdog_*.jsonl

# Dernier status
cat /opt/keybuzz/logs/sre/watchdog/watchdog_last_status.json | python3 -m json.tool

# Alertes
cat /opt/keybuzz/logs/sre/watchdog/alerts.jsonl

# État persistant (cooldowns, attempts)
cat /opt/keybuzz/state/sre/watchdog_state.json | python3 -m json.tool
```

### Reset d'État

```bash
# Reset complet de l'état (après intervention manuelle)
rm /opt/keybuzz/state/sre/watchdog_state.json

# Reset état d'un nœud spécifique
# Éditer watchdog_state.json et supprimer l'entrée du nœud
```

## Tests

### Test 1: Dry-run

Activer le mode dry-run pour vérifier la détection sans actions:

```yaml
# config.yaml
dry_run: true
```

```bash
systemctl start keybuzz-watchdog.service
cat /opt/keybuzz/logs/sre/watchdog/watchdog_last_status.json
```

### Test 2: Simulation NotReady

```bash
# Sur un worker, simuler un problème kubelet
ssh root@<worker-ip> 'systemctl stop kubelet'

# Attendre 3 cycles (3 minutes)
# Observer les logs du watchdog

# Le watchdog devrait:
# 1. Détecter NotReady
# 2. Après 3 échecs, tenter récupération
# 3. Power cycle via Hetzner
# 4. Uncordon après retour Ready

# Vérifier
kubectl get nodes
cat /opt/keybuzz/logs/sre/watchdog/watchdog_last_status.json
```

### Test 3: Vérifier Cooldown

```bash
# Après une récupération, vérifier que le nœud est en cooldown
cat /opt/keybuzz/state/sre/watchdog_state.json | python3 -m json.tool

# Le nœud ne devrait pas être re-traité pendant 20 minutes
```

## Rollback

### Désactiver le Watchdog

```bash
# Arrêter et désactiver
systemctl stop keybuzz-watchdog.timer
systemctl disable keybuzz-watchdog.timer

# Vérifier
systemctl list-timers | grep keybuzz
```

### Supprimer Complètement

```bash
# Arrêter
systemctl stop keybuzz-watchdog.timer
systemctl stop keybuzz-watchdog.service

# Désactiver
systemctl disable keybuzz-watchdog.timer

# Supprimer les fichiers
rm /etc/systemd/system/keybuzz-watchdog.*
rm -rf /opt/keybuzz/sre/watchdog
rm /etc/logrotate.d/keybuzz-watchdog

# Reload systemd
systemctl daemon-reload
```

## Sécurité

### Token Hetzner

- Stocké dans `/opt/keybuzz/credentials/hcloud.env`
- Permissions: `chmod 600`
- **JAMAIS** committé dans Git

### Permissions systemd

- `NoNewPrivileges=yes`
- `ProtectSystem=strict`
- `ProtectHome=yes`
- `ReadWritePaths=/opt/keybuzz/logs /opt/keybuzz/state`

### Ce que le Watchdog ne fait JAMAIS

| ❌ Interdit | Raison |
|-------------|--------|
| Toucher Vault | SPOF critique |
| Toucher PostgreSQL | Données critiques |
| Toucher MariaDB | Données critiques |
| Modifier secrets | Risque de corruption |
| Actions sans cooldown | Éviter boucles |

## FAQ

### Q: Le watchdog peut-il créer une boucle de redémarrage?

Non, grâce aux protections:
- Cooldown de 20 minutes après chaque action
- Maximum 3 tentatives par 24h
- État "NEEDS_HUMAN" si limites dépassées

### Q: Que se passe-t-il si monitor-01 tombe?

Le watchdog ne fonctionne plus. C'est une limitation connue.
Solution future: déployer le watchdog en HA ou dans K8s lui-même.

### Q: Comment exclure temporairement un nœud?

```yaml
# config.yaml
excluded_nodes:
  - k8s-worker-03
```

Puis: `systemctl restart keybuzz-watchdog.service`

### Q: Les masters sont-ils protégés?

Oui, ils sont traités comme les workers. Cependant, le watchdog utilise kubectl qui dépend du control-plane. Si tous les masters tombent, le watchdog ne peut plus fonctionner.

### Q: Comment voir l'historique des actions?

```bash
# Tous les logs du jour
cat /opt/keybuzz/logs/sre/watchdog/watchdog_$(date +%Y%m%d).jsonl | grep action

# Toutes les récupérations
grep "recovered\|poweron\|poweroff\|reset" /opt/keybuzz/logs/sre/watchdog/*.jsonl
```

## Changelog

### v1.0.0 (2026-01-03)
- Version initiale
- Détection NotReady
- Récupération via Hetzner API
- Cooldown et max attempts
- Logs JSON structurés
