# PH133-G — Amazon Visual Line Preservation

> Phase : PH133-G-AMAZON-VISUAL-LINE-PRESERVATION-01
> Date : 2026-03-30
> Statut : **DEV + PROD DEPLOYES**

---

## Probleme

PH133-F avait remplace `<p>` par `<br>` pour Amazon.
Resultat : `\n\n` devenait `<br><br>`, mais Amazon compresse visuellement les `<br>` consecutifs, provoquant un effet de texte "colle" entre paragraphes.

## Cause racine

Amazon Buyer-Seller Messaging ignore ou compresse les `<br>` multiples consecutifs. Un `<br><br>` ne produit pas toujours un espacement visuel de paragraphe.

## Solution

Modifier `textToHtmlAmazon()` pour inserer un caractere `&nbsp;` (espace insecable) entre les deux `<br>` de separation de paragraphe.

### Avant (PH133-F)

```javascript
return escaped
  .replace(/\n/g, '<br>');
// \n\n -> <br><br> (compresse par Amazon)
```

### Apres (PH133-G)

```javascript
return escaped
  .replace(/\n\n/g, '<br>&nbsp;<br>')
  .replace(/\n/g, '<br>');
```

L'ordre est critique : `\n\n` est traite EN PREMIER, puis les `\n` restants.

Le `&nbsp;` force Amazon a rendre une ligne visible entre les paragraphes.

## Perimetre du changement

| Fichier | Fonction | Changement |
|---|---|---|
| `outboundWorker.ts` | `textToHtmlAmazon()` | `\n\n` -> `<br>&nbsp;<br>` puis `\n` -> `<br>` |
| `outboundWorker.ts` | version | `4.7.0-linebreak-fidelity` -> `4.8.0-visual-line-preservation` |

## Non-regressions

| Element | Statut |
|---|---|
| Email outbound (textToHtml) | Non touche - utilise `textToHtml()` ligne 686 |
| Octopia outbound | Non touche |
| sanitizeForAmazon() | Non modifie |
| Pipeline SMTP | Non modifie |
| Encoding UTF-8 | Conserve |
| Emojis | Toujours supprimes par sanitizer |
| Pieces jointes | Non impactees |

## Exemples de transformation

| Input | HTML Output |
|---|---|
| `Bonjour\nTest` | `Bonjour<br>Test` |
| `Bonjour\n\nTest\n\nFin` | `Bonjour<br>&nbsp;<br>Test<br>&nbsp;<br>Fin` |
| `Ligne 1\nLigne 2\n\nParagraphe 2` | `Ligne 1<br>Ligne 2<br>&nbsp;<br>Paragraphe 2` |

## Versions DEV

| Service | Image |
|---|---|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.138-amazon-line-visual-fix-dev` |
| Worker DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.6.05-amazon-line-visual-fix-dev` |
| Worker version | `v4.8.0-visual-line-preservation` |

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.137-amazon-linebreak-fix-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.04-amazon-linebreak-fix-dev -n keybuzz-api-dev
```

## Versions PROD

| Service | Image |
|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.138-amazon-line-visual-fix-prod` |
| Worker PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.6.05-amazon-line-visual-fix-prod` |
| Worker version | `v4.8.0-visual-line-preservation` |

## Rollback PROD

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.137-amazon-linebreak-fix-prod -n keybuzz-api-prod
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.6.04-amazon-linebreak-fix-prod -n keybuzz-api-prod
```

## Verdict

AMAZON VISUAL LINE PRESERVATION FIXED — PARAGRAPHS VISIBLE — NO TEXT COLLAPSE — SANITIZER SAFE — ROLLBACK READY
