# PH11-PRODUCT-01A — AI Rules & Settings (DB + API)

**Date :** 2026-01-03
**Statut :** TERMINE
**Environnement :** DEV uniquement
**Image Docker :** ghcr.io/keybuzzio/keybuzz-api:v0.1.46-dev

---

## 1. Tables créées

- `ai_rules` - Règles IA (id, tenant_id, name, mode, status, priority, channel)
- `ai_rule_conditions` - Conditions des règles
- `ai_rule_actions` - Actions à exécuter
- `ai_settings` - Paramètres IA par tenant (mode, safe_mode, daily_budget)
- `ai_action_log` - Journal des actions IA

## 2. Endpoints API

| Méthode | Endpoint | Description |
|---|---|---|
| GET | /ai/settings | Récupérer paramètres IA |
| PATCH | /ai/settings | Mettre à jour paramètres |
| GET | /ai/rules | Lister règles IA |
| POST | /ai/rules | Créer règle IA |
| GET | /ai/journal | Consulter journal |
| POST | /ai/evaluate | Évaluer règles |
| POST | /ai/execute | Exécuter action |

## 3. Commits

- `keybuzz-api`: 574b700 (AI routes + migrations)
- `keybuzz-infra`: 7cc6f32 (PGHOST vers leader)

## 4. Problèmes résolus

- PGHOST vers réplica -> corrigé vers leader Patroni (10.0.0.121)
- SQL placeholders manquants -> fichier recréé via base64

## 5. Tests Validés

Tous les endpoints ont été testés et validés.

---
**DEV OK - PROD UNTOUCHED**
