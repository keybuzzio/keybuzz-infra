# PH133-F — Amazon Line Break Fidelity

> Date : 30 mars 2026
> Auteur : Agent Cursor (CE)
> Phase precedente : PH133-E (Amazon Safe Formatter)
> Statut : **DEV + PROD DEPLOYES ET VALIDES**

---

## 1. OBJECTIF

Corriger la perte de formatage (paragraphes / sauts de ligne) dans les messages envoyes vers Amazon.

---

## 2. DIAGNOSTIC

### 2.1 Donnees en DB = correctes

Les messages stockes dans `messages.body` contiennent les `\n` et `\n\n` corrects.
Pas de `\r`, pas de corruption.

### 2.2 sanitizeForAmazon = correct

La fonction preserve les `\n` et `\n\n`. Seuls les emojis et chars invisibles sont supprimes.
Les espaces multiples residuels sont collapses, les `\n{3+}` ramenes a `\n\n`.

### 2.3 textToHtmlAmazon = probleme identifie

**Avant (PH133-E)** : utilisait des `<p>` tags pour les paragraphes.

Amazon Buyer-Seller Messaging **ne rend pas les `<p>` correctement** :
- Les `<p>` sont soit ignores, soit rendus sans espacement
- Resultat : texte compacte en un seul bloc

### 2.4 Preuve avec message reel PROD

Input :
```
Bonjour,

Merci pour votre retour [emoji]

Je vous confirme que l'etiquette est en piece jointe.
Le transporteur FedEx passera entre 9h et 17h.

Cordialement,
L'equipe eComLG
```

HTML avant (PH133-E) :
```html
<p>Bonjour,</p>
<p>Merci pour votre retour</p>
<p>Je vous confirme...piece jointe.<br> Le transporteur...</p>
<p>Cordialement,<br>L'equipe eComLG</p>
```

HTML apres (PH133-F) :
```html
Bonjour,<br><br>Merci pour votre retour<br><br>Je vous confirme...piece jointe.<br>Le transporteur...<br><br>Cordialement,<br>L'equipe eComLG
```

---

## 3. CORRECTION

### Fichier modifie

`src/workers/outboundWorker.ts` — fonction `textToHtmlAmazon()`

### Avant

```javascript
function textToHtmlAmazon(text) {
  // ... sanitize + escape ...
  const paragraphs = escaped.split(/\n\s*\n/).filter(p => p.trim());
  return paragraphs.map(p => '<p>' + p.trim().replace(/\n/g, '<br>') + '</p>').join('\n');
}
```

### Apres

```javascript
function textToHtmlAmazon(text) {
  // ... sanitize + escape ...
  // PH133-F: Amazon only renders <br>, not <p>
  return escaped.replace(/\n/g, '<br>');
}
```

### Logique

| Input | Output HTML |
|-------|-------------|
| `\n` (saut de ligne) | `<br>` |
| `\n\n` (paragraphe) | `<br><br>` |
| `\n\n\n` (deja collapse par sanitize) | `<br><br>` |

### Ce qui n'est PAS touche

| Element | Statut |
|---------|--------|
| `sanitizeForAmazon()` | Inchange (PH133-E) |
| `textToHtml()` (email path) | Inchange — utilise toujours `<p>` |
| emailService.ts | Inchange |
| Octopia outbound | Inchange |
| Inbox / playbooks / autopilot | Inchanges |

---

## 4. VERSIONS

### DEV

| Service | Image |
|---------|-------|
| API | `v3.5.137-amazon-linebreak-fix-dev` |
| Worker | `v3.6.04-amazon-linebreak-fix-dev` |

Worker interne : `v4.7.0-linebreak-fidelity`

### PROD

| Service | Image |
|---------|-------|
| API | `v3.5.137-amazon-linebreak-fix-prod` |
| Worker | `v3.6.04-amazon-linebreak-fix-prod` |

Worker interne : `v4.7.0-linebreak-fidelity`

### Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.136-amazon-safe-formatter-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.03-amazon-safe-formatter-dev -n keybuzz-api-dev
```

### Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.136-amazon-safe-formatter-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.03-amazon-safe-formatter-prod -n keybuzz-api-prod
```

---

## VERDICT

**AMAZON LINE BREAK FIDELITY RESTORED — PARAGRAPHS PRESERVED — NO TEXT COLLAPSE — SANITIZER SAFE — DEV + PROD DEPLOYED — ROLLBACK READY**

DEV + PROD deployes et valides le 30 mars 2026.
