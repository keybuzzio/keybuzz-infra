# PH-AUTOPILOT-ORDER-ID-PROMPT-FIX-PROD-PROMOTION-01

> Date : 2026-04-20
> Type : Promotion PROD
> Priorite : P1

---

## OBJECTIF

Promouvoir en PROD le correctif minimal deja valide en DEV pour que l'Autopilot
ne redemande plus un numero de commande deja present dans le message client.

Patch unique : injection de `getScenarioRules()` dans le prompt systeme Autopilot
(`src/modules/autopilot/engine.ts`).

---

## PREFLIGHT

| Element | Valeur |
|---|---|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `1adbf73b` |
| Repo clean | OUI (seul `.bak` non-suivi) |
| Commit fix present | OUI (`1adbf73b`) |
| Image DEV validee | `v3.5.90-autopilot-orderid-prompt-fix-dev` |
| Image PROD avant | `v3.5.89-autopilot-inbound-trigger-prod` |

---

## VERIFICATION SOURCE

| Point | Resultat |
|---|---|
| Import `getScenarioRules` (ligne 30) | OUI |
| Injection dans `systemPrompt` (ligne 688) | OUI — apres `GUARDRAIL_SYSTEM_RULES` |
| Aucun autre fichier touche | OUI — seul `engine.ts` modifie |

---

## BUILD PROD

| Element | Valeur |
|---|---|
| Image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.90-autopilot-orderid-prompt-fix-prod` |
| Digest | `sha256:6425beb57f85c5753371d77bac2e928451db983bbe77df341a469852c3a62080` |
| Commit source | `1adbf73b` |
| Build | `--no-cache`, build-from-git, repo clean |

---

## GITOPS PROD

| Element | Valeur |
|---|---|
| Fichier | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Commit infra | `473de74` |
| Image avant | `v3.5.89-autopilot-inbound-trigger-prod` |
| Image apres | `v3.5.90-autopilot-orderid-prompt-fix-prod` |
| Push | OK (`main`) |

---

## DEPLOY PROD

| Element | Valeur |
|---|---|
| Rollout | Succes |
| Pod | `keybuzz-api-d95bf999d-8srn4` |
| Restarts | 0 |
| Health | `{"status":"ok"}` |

---

## VALIDATION PROD REELLE

### Case A — Email avec numero de commande (conv-679ad0f6)

- **Tenant** : `switaa-sasu-mnc1ouqu` (AUTOPILOT, mode autonomous)
- **Message entrant** : "Bonjour, ma commande numero 402-1234567-8901234 n est toujours pas arrivee. Merci de verifier."
- **Autopilot declenche** : OUI
- **Resultat** : `ESCALATION_DRAFT` (safe_mode a detecte "je vais verifier")
- **Draft genere** : "Merci pour votre message concernant votre commande **402-1234567-8901234**. [...] Pourriez-vous me confirmer si vous avez un **numero de suivi** [...]"
- **Le draft utilise le numero de commande** present dans le message
- **Le draft ne redemande PAS le numero de commande** — il demande un numero de suivi (tracking), qui est une information differente et legitime
- **VERDICT : PASS**

### Preuve comparative AVANT / APRES fix

| Quand | Version | Message client | Reponse IA |
|---|---|---|---|
| 21:25 (avant fix) | v3.5.89 | "commande numero 402-1234567-8901234" | "Pourriez-vous me confirmer le **numero de commande** ou de suivi ?" — RE-DEMANDE |
| 23:02 (apres fix) | v3.5.90 | "commande numero 402-1234567-8901234" | "concernant votre commande **402-1234567-8901234**. [...] numero de **suivi** ?" — UTILISE |

### Case B — Email sans numero de commande (conv-b1dd4be4)

- **Message entrant** : "Bonjour, je souhaite savoir quand je vais recevoir mon colis. Merci d avance."
- **Autopilot declenche** : OUI (`DRAFT_GENERATED`, 510 chars, 5.49 KBA)
- **Draft genere** : "pourriez-vous me communiquer votre numero de commande ou votre numero de suivi ?"
- **Le draft demande legitimement le numero** — car absent du message
- **VERDICT : PASS**

### Case C — PRO plan gating (ecomlg-001)

- **Tenant** : `ecomlg-001` (PRO, mode supervised)
- **ai_action_log** : 64 avant → 64 apres (inchange)
- **Logs pod** : `[Autopilot] ecomlg-001 conv=conv-541d5dac → MODE_NOT_AUTOPILOT:suggestion`
- **VERDICT : PASS**

### Tableau synthese

| Test | Attendu | Resultat |
|---|---|---|
| Case A — Order ID present | Draft utilise l'ID, ne le redemande pas | **PASS** |
| Case B — Pas d'order ID | Draft peut demander legitimement | **PASS** |
| Case C — PRO plan gating | MODE_NOT_AUTOPILOT, pas d'action | **PASS** |

---

## NON-REGRESSION PROD

| Endpoint | Code |
|---|---|
| `/health` | 200 |
| `/messages/conversations` | 200 |
| `/tenant-context/me` | 200 |
| `/dashboard/summary` | 200 |
| `/autopilot/settings` | 200 |
| `/billing/current` | 200 |
| `/metrics/overview` | 200 |

| Verification | Resultat |
|---|---|
| Image DEV | Inchangee (`v3.5.90-autopilot-orderid-prompt-fix-dev`) |
| Image PROD | `v3.5.90-autopilot-orderid-prompt-fix-prod` |
| Restarts | 0 |
| Impact tracking | Aucun |
| Impact billing | Aucun |
| Impact Stripe | Aucun |
| Impact client SaaS | Aucun |
| Impact Admin | Aucun |

---

## PREUVES

### Message inbound de test (Case A)
```
From: test-prod-orderid@example.com
Subject: Probleme commande 402-1234567-8901234
Body: Bonjour, ma commande numero 402-1234567-8901234 n est toujours pas arrivee. Merci de verifier.
```

### Draft genere (Case A — ESCALATION_DRAFT)
```
Bonjour,

Merci pour votre message concernant votre commande 402-1234567-8901234.
Je vais verifier cela pour vous. Pourriez-vous me confirmer si vous avez
un numero de suivi ou tout autre detail qui pourrait m'aider a localiser
votre colis ? Des reception de ces informations, je pourrai vous donner
plus de details sur le statut de votre livraison.

Cordialement,
Ludovic Ludovic
SWITAA SASU
```

### Preuve : le numero n'est plus redemande
- Le draft mentionne "votre commande **402-1234567-8901234**" (utilise le ref)
- Le draft demande un "numero de suivi" (tracking), pas le numero de commande
- Comparaison avec le comportement AVANT fix ou l'IA redemandait "le numero de commande ou de suivi"

### Preuve logs
```
[Autopilot] switaa-sasu-mnc1ouqu conv=conv-679ad0f6 → ESCALATION_DRAFT (safe_mode, false_promises=je vais verifier)
[Autopilot] switaa-sasu-mnc1ouqu conv=conv-b1dd4be4 → DRAFT_GENERATED (safe_mode, draft=510 chars, kba=5.49)
[Autopilot] ecomlg-001 conv=conv-541d5dac → MODE_NOT_AUTOPILOT:suggestion
```

### Preuve PRO plan non casse
- `ai_action_log` ecomlg-001 : 64 → 64 (aucun increment)
- Log : `MODE_NOT_AUTOPILOT:suggestion` (gating correct)

---

## ROLLBACK

### Procedure
```bash
# 1. Restaurer le manifest PROD
# Modifier keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml :
# image: ghcr.io/keybuzzio/keybuzz-api:v3.5.89-autopilot-inbound-trigger-prod

# 2. Appliquer
kubectl apply -f keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod

# 3. Verifier
kubectl exec -n keybuzz-api-prod deploy/keybuzz-api -- curl -s http://127.0.0.1:3001/health
```

### Images de reference
| | Image |
|---|---|
| Avant (rollback cible) | `ghcr.io/keybuzzio/keybuzz-api:v3.5.89-autopilot-inbound-trigger-prod` |
| Apres (actuelle) | `ghcr.io/keybuzzio/keybuzz-api:v3.5.90-autopilot-orderid-prompt-fix-prod` |

---

## VERDICT FINAL

**AUTOPILOT ORDER-ID PROMPT FIX RESTORED IN PROD — MINIMAL PATCH — NON REGRESSION OK**
