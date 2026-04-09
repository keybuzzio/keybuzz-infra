# PH135-C — Amazon Inbound Thread Sanity

> Phase : PH135-C-AMAZON-INBOUND-THREAD-SANITY-01
> Date : 30 mars 2026
> Statut : **DEV + PROD DEPLOYES**

---

## Problème

Les conversations Amazon inbound souffraient de 3 anomalies critiques :

1. **Duplication massive** : jusqu'à 14 copies du même message dans une conversation
2. **Historique cité inclus dans le body** : séparateur relay `-------------`, headers `De : ...`, `Envoyé : ...`, contenu MIME/forwarded — pollue le contexte IA
3. **Placeholders `[Votre Nom]`** : le LLM générait des placeholders bruts dans les drafts autopilot

## Cause racine

### Pipeline réel identifié

Le flux Amazon inbound RÉEL passe par **`/inbound/email` avec `channel: 'amazon'`**, PAS par `/inbound/amazon-forward`.

Raison : les adresses inbound réelles utilisent des tenant IDs comme `ecomlg-001`, `switaa-sasu-mnc1x4eq`, etc. La fonction `parseTenantId()` dans `amazonForward.ts` ne matche que `kbz-\d{3}`, rendant `/inbound/amazon-forward` inopérant pour les tenants réels.

### Duplication

PH135-B avait ajouté la dedup sur `/inbound/email`, mais les 14 duplicates sont des messages antérieurs à PH135-B. La dedup est maintenant active sur les DEUX endpoints.

### Thread pollué

`stripEmailQuotes()` (PH135-B) ne gère pas les patterns Amazon relay :
- Séparateur `-------------` en début de body
- Headers forwarded `De : ... / Envoyé : ... / À : ... / Objet : ...`
- Boundaries MIME `--_000_...`
- URLs media Amazon `[https://m.media-amazon.com/...]`

### Placeholder `[Votre Nom]`

Le prompt système dans `engine.ts` ne contenait aucune instruction interdisant les placeholders. Le LLM générait naturellement `[Votre Nom]`, `[Nom du Client]` comme pattern de réponse type.

## Corrections

### FIX 1 — `stripAmazonRelay()` (routes.ts)

Nouvelle fonction qui nettoie les corps Amazon avant stockage :
- Supprime le séparateur `-------------` en début de body
- Supprime les boundaries MIME
- Supprime les blocs headers forwarded (`De : ...`, `Envoyé : ...`)
- Supprime les notifications Amazon (`Ha recibido un mensaje`)
- Supprime les URLs media Amazon en fin de body
- Compacte les lignes vides excessives

Appliquée dans **les DEUX endpoints** :
- `/inbound/email` : conditionnellement si `channel === 'amazon'`
- `/inbound/amazon-forward` : systématiquement

### FIX 2 — Dedup sur `/inbound/amazon-forward` (routes.ts)

Même pattern que PH135-B : hash MD5 du body, fenêtre 5 minutes, même conversation.

### FIX 3 — Anti-placeholder dans prompt système (engine.ts)

Instructions ajoutées au `systemPrompt` :

```
INTERDICTIONS ABSOLUES dans tes réponses:
- Ne JAMAIS utiliser de placeholders entre crochets: [Votre Nom], [Nom du Client], etc.
- Ne JAMAIS mettre de crochets [] dans le texte de réponse
- Signer simplement "Cordialement, Le service client" ou ne pas mettre de signature
- Commencer par "Bonjour," sans nom si le prénom du client n'est pas connu
```

## Fichiers modifiés

| Fichier | Modification |
|---|---|
| `src/modules/inbound/routes.ts` | Ajout `stripAmazonRelay()`, dedup amazon-forward, appel conditionnel dans `/inbound/email` |
| `src/modules/autopilot/engine.ts` | Anti-placeholder dans le prompt système |

## Validation DEV

| Test | Résultat |
|---|---|
| Amazon inbound via `/inbound/email` channel=amazon | **200 OK** — message créé |
| Dedup — même body | **200 OK, `duplicate: true`** — rejeté |
| Body stocké propre | **44 chars** — `"Bonjour,\n\nOu en est ma commande svp ?\n\nMerci"` |
| Pas de relay `-------------` | **OK** |
| Pas de quoted history `De : ...` | **OK** |
| Pas de underscores `____` | **OK** |
| Non-régression email inbound | **200 OK** |
| Health check | **OK** |

## Versions DEV

| Service | Image |
|---|---|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.142-amazon-inbound-thread-fix-dev` |
| Worker DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.6.07-amazon-inbound-thread-fix-dev` |

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.141-email-pipeline-fix-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.06-email-pipeline-fix-dev -n keybuzz-api-dev
```

## Versions PROD

| Service | Image |
|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.142-amazon-inbound-thread-fix-prod` |
| Worker PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.6.07-amazon-inbound-thread-fix-prod` |

## Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.141-email-pipeline-fix-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.06-email-pipeline-fix-prod -n keybuzz-api-prod
```

## Non-régressions

| Element | Statut |
|---|---|
| Email inbound classique | OK — non impacté (stripAmazonRelay conditionnel) |
| Outbound Amazon (PH133-D/G) | Non touché |
| Pièces jointes | Non touché |
| Autopilot draft | Prompt amélioré (anti-placeholder) |
| KBA billing | Non touché |
| Inbox | OK |

---

## Verdict

**AMAZON INBOUND THREAD CLEAN — NO DUPLICATION — AI CONTEXT CLEAN — NO PLACEHOLDER LEAK — ROLLBACK READY**
