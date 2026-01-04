# PH11-SRE-WATCHDOG-VERSION-GUARD-FINALIZE

## Resume Executif

**Status:** âœ… TERMINÃ‰
**Date:** 2026-01-04

## Objectifs Atteints

### A) Admin /debug/version + Footer BUILD_METADATA
- âœ… Route /debug/version fonctionnelle
- âœ… Footer utilise BUILD_METADATA
- âœ… Image v1.0.55-dev dÃ©ployÃ©e

### B) Client /debug/version + Footer BUILD_METADATA
- âœ… Route /debug/version fonctionnelle
- âœ… Footer utilise BUILD_METADATA (corrigÃ© de v0.2.33-dev hardcodÃ©)
- âœ… Image v0.2.14-dev dÃ©ployÃ©e

### C) Watchdog Version Guard sur monitor-01
- âœ… Service systemd crÃ©Ã© et actif
- âœ… Timer toutes les 5 minutes
- âœ… Logs JSONL fonctionnels
- âœ… Mode READ-ONLY (aucune action destructive)

## Versions Deployees

| Service | Image K8s | Version UI | Git SHA | Status |
|---------|-----------|------------|---------|--------|
| Admin | ghcr.io/keybuzzio/keybuzz-admin:v1.0.55-dev | 1.0.55-dev | e4bffe7 | âœ… OK |
| Client | ghcr.io/keybuzzio/keybuzz-client:v0.2.14-dev | 0.2.14-dev | unknown | âœ… OK |

## Endpoints /debug/version

### Admin
`json
{
  app: app,
  version: 1.0.55-dev,
  gitSha: e4bffe7,
  buildDate: 2026-01-04T20:21:23.874469Z
}
`

### Client
`json
{
  app: app,
  version: 0.2.14-dev,
  gitSha: unknown,
  buildDate: 2026-01-04T20:41:51.191937Z
}
`

## Watchdog Version Guard

### Configuration
- **Emplacement:** /opt/keybuzz/sre/watchdog/version_guard.py
- **Config:** /opt/keybuzz/sre/watchdog/version_guard_config.yaml
- **Timer:** /etc/systemd/system/keybuzz-version-guard.timer (toutes les 5 minutes)
- **Logs:** /opt/keybuzz/logs/sre/watchdog/version_guard_YYYYMMDD.jsonl

### Exemple Log OK
`json
{timestamp: 2026-01-04T20:46:11.354650+00:00Z, level: info, message: Version consistency OK, service: keybuzz-client, namespace: keybuzz-client-dev, image: ghcr.io/keybuzzio/keybuzz-client:v0.2.14-dev, ui_version: v0.2.14-dev, git_sha: unknown, status: OK}
{timestamp: 2026-01-04T20:46:11.506010+00:00Z, level: info, message: Version consistency OK, service: keybuzz-admin, namespace: keybuzz-admin-dev, image: ghcr.io/keybuzzio/keybuzz-admin:v1.0.55-dev, ui_version: v1.0.55-dev, git_sha: e4bffe7, status: OK}
`

### Comportement READ-ONLY
Le watchdog:
- âœ… Lit les images K8s dÃ©ployÃ©es via kubectl
- âœ… Lit les endpoints /debug/version
- âœ… Compare version image vs version UI
- âœ… Ã‰crit des logs JSONL
- âŒ Ne fait JAMAIS de rollout
- âŒ Ne fait JAMAIS de reboot
- âŒ Ne fait JAMAIS de cordon/drain
- âŒ Ne modifie JAMAIS les dÃ©ploiements

## Commandes Utiles

### VÃ©rifier le timer
`ash
ssh 10.0.0.152 'systemctl status keybuzz-version-guard.timer'
`

### Voir les logs rÃ©cents
`ash
ssh 10.0.0.152 'tail -20 /opt/keybuzz/logs/sre/watchdog/version_guard_.jsonl'
`

### ExÃ©cution manuelle
`ash
ssh 10.0.0.152 'systemctl start keybuzz-version-guard.service'
`

## Notes Techniques

### gitSha = unknown pour Client
Le gitSha est unknown pour le Client car le rÃ©pertoire .git n'est pas copiÃ© dans le conteneur Docker lors du build. Solution future: passer GIT_SHA comme ARG de build Docker.

### app = app au lieu du nom rÃ©el
Le script generate-build-metadata.py utilise le nom du rÃ©pertoire de travail qui est app dans le contexte Docker. Solution future: passer APP_NAME comme variable d'environnement.

## Contraintes Respectees

- âœ… DEV ONLY (PROD intact)
- âœ… GitOps (manifests dans keybuzz-infra)
- âœ… Watchdog READ-ONLY
- âœ… Aucune action destructive
- âœ… Logs JSONL
- âœ… Cooldown 30 minutes par service

---

**PH11-SRE-WATCHDOG-VERSION-GUARD-FINALIZE - TERMINÃ‰**
**Date:** 2026-01-04
