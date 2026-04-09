# PH142-I — Pre-PROD Safety Check

> Date : 1 mars 2026
> Statut : Operationnel

---

## Objectif

Checklist automatisee minimale obligatoire avant chaque push PROD.
Execute 10 verifications en < 10 secondes depuis le bastion.

## Usage

```bash
# Depuis le bastion (obligatoire avant push PROD)
bash /opt/keybuzz/keybuzz-infra/scripts/pre-prod-check.sh dev

# Verification PROD post-deploy
bash /opt/keybuzz/keybuzz-infra/scripts/pre-prod-check.sh prod
```

## Checks effectues (10)

| # | Check | Methode |
|---|---|---|
| 1 | API health | curl public URL `/health` |
| 2 | Client health | curl public URL HTTP 200 |
| 3 | Inbox API endpoint | HTTP GET interne `/health` |
| 4 | Dashboard API endpoint | HTTP GET `/dashboard/summary` |
| 5 | AI Settings endpoint | HTTP GET `/ai/settings` |
| 6 | AI Journal endpoint | HTTP GET `/ai/journal` |
| 7 | Autopilot draft endpoint | HTTP GET `/autopilot/draft` |
| 8 | Signature config in DB | SQL `tenant_settings` count > 0 |
| 9 | Orders count > 0 | SQL `orders` count > 0 |
| 10 | Channels count > 0 | SQL `inbound_connections` count > 0 |

## Resultats valides

### DEV : 10/10 ALL GREEN
```
  [OK] API health (https://api-dev.keybuzz.io)
  [OK] Client health (https://client-dev.keybuzz.io)
  [OK] Inbox API endpoint
  [OK] Dashboard API endpoint
  [OK] AI Settings endpoint
  [OK] AI Journal endpoint
  [OK] Autopilot draft endpoint
  [OK] Signature config in DB
  [OK] Orders count > 0
  [OK] Channels count > 0
  RESULT: 10/10 passed — ALL GREEN
  >>> PROD PUSH AUTHORIZED <<<
```

### PROD : 9/10 (signature config pas encore renseignee en PROD)

## Fichiers

| Fichier | Role |
|---|---|
| `scripts/pre-prod-check.sh` | Script principal (bash) |
| `scripts/pre-prod-checks.js` | Checks internes (Node.js, execute dans le pod API) |

## Comportement

- Si tous les checks passent : `exit 0` + `PROD PUSH AUTHORIZED`
- Si un ou plusieurs echouent : `exit 1` + `PROD PUSH BLOCKED`
- Execution totale : < 10 secondes
- Le script JS est copie dans le pod via `kubectl cp`, execute, puis supprime

## Procedure avant push PROD

```bash
# 1. Executer le check sur DEV
bash /opt/keybuzz/keybuzz-infra/scripts/pre-prod-check.sh dev

# 2. Si ALL GREEN -> proceder au push PROD
# 3. Si FAIL -> corriger avant de pusher

# 4. Apres deploy PROD, verifier :
bash /opt/keybuzz/keybuzz-infra/scripts/pre-prod-check.sh prod
```
