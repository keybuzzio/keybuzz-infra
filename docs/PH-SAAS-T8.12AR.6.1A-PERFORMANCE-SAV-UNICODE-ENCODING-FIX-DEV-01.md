# PH-SAAS-T8.12AR.6.1A — Performance SAV Unicode Encoding Fix DEV

> Date : 2026-05-10
> Linear : KEY-289 / Parent KEY-282
> Phase : bugfix DEV cible
> Environnement : DEV uniquement

## VERDICT

**PERFORMANCE SAV UNICODE ENCODING FIX READY IN DEV** — NO LITERAL `\u00` SEQUENCES VISIBLE — FRENCH COPY RENDERS CORRECTLY — CURVES / AI KPI / MILESTONES / LIMITATIONS PRESERVED — NO FAKE METRICS — NO DB MUTATION — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR LUDOVIC QA

---

## 1. Root Cause

Le script Python AR.6.1 (`tmp_ar61_patch_api.py` et `tmp_ar61_patch_client.py`) utilisait des sequences Unicode echappees en Python : `\\u00e9` (double backslash). En Python, `\\u00e9` produit la chaine literale `\u00e9` (6 caracteres) au lieu du caractere `e` (U+00E9).

**Impact API** : Dans les string literals TypeScript (`'...'` et `` `...` ``), `\u00e9` est un escape JavaScript valide. Node.js l'interprete correctement comme `e`. L'API renvoyait donc des caracteres FR corrects.

**Impact Client** : Dans les JSXStrings (attributs `title="..."`, `label="..."`) et le texte JSX (`<p>...text...</p>`), les sequences `\u00XX` ne sont PAS traitees comme des escapes JavaScript — elles sont affichees litteralement. Le navigateur montre `\u00e9` au lieu de `e`.

**Conclusion** : 65 occurrences de `\u00XXXX` literal dans les deux fichiers source. Fix : remplacement par les vrais caracteres UTF-8.

---

## 2. Fichiers corriges

| Fichier | Escapes trouves | Restants apres fix |
|---|---|---|
| API: `performance-stats.service.ts` | 25 | 0 |
| Client: `app/performance/page.tsx` | 40 | 0 |

### Exemples avant / apres

| Avant (literal escape) | Apres (UTF-8) | Fichier |
|---|---|---|
| `Espace cr\u00e9\u00e9` | `Espace cree` | API |
| `Premi\u00e8re r\u00e9ponse envoy\u00e9e` | `Premiere reponse envoyee` | API |
| `title="R\u00e9ponses envoy\u00e9es"` | `title="Reponses envoyees"` | Client |
| `Bient\u00f4t disponible` | `Bientot disponible` | Client |
| `Suggestions g\u00e9n\u00e9r\u00e9es` | `Suggestions generees` | Client |
| `Brouillons appliqu\u00e9s` | `Brouillons appliques` | Client |
| `Non instrument\u00e9s` | `Non instrumentes` | Client |
| `Aucune activit\u00e9 sur cette p\u00e9riode.` | `Aucune activite sur cette periode.` | Client |

(Note : les accents sont presents dans les fichiers reels. Ce rapport Markdown evite les accents pour la lisibilite brute.)

---

## 3. Methode de fix

Script Python `tmp_ar61a_fix.py` utilisant `re.sub(r'\\u([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1), 16)), content)` pour convertir toutes les sequences `\uXXXX` en caracteres Unicode reels.

- Scope limite aux deux fichiers modifies en AR.6.1
- Aucun autre fichier touche
- Aucune donnee metier modifiee

---

## 4. Checks

| Check | Resultat |
|---|---|
| TypeScript API (`tsc --noEmit`) | OK |
| `grep -F '\u00'` API source | 0 occurrences |
| `grep -F '\u00'` Client source | 0 occurrences |
| API JSON `HAS_LITERAL_ESCAPES` | false |
| Aucune URL DEV dans config PROD | OK |
| Aucun tracking ajoute | OK |
| Aucune fake metric | OK |

---

## 5. Build DEV

| Service | Commit | Tag | Digest | Rollback |
|---|---|---|---|---|
| API DEV | fbb45c0c | v3.5.166-performance-sav-encoding-fix-dev | sha256:07d0c8ea92a9... | v3.5.165-performance-sav-polish-dev |
| Client DEV | ce1bdd2 | v3.5.175-performance-sav-encoding-fix-dev | sha256:4bbea97d6d63... | v3.5.174-performance-sav-polish-dev |

---

## 6. GitOps DEV

| Manifest | Image avant | Image apres |
|---|---|---|
| k8s/keybuzz-api-dev/deployment.yaml | v3.5.165-performance-sav-polish-dev | v3.5.166-performance-sav-encoding-fix-dev |
| k8s/keybuzz-client-dev/deployment.yaml | v3.5.174-performance-sav-polish-dev | v3.5.175-performance-sav-encoding-fix-dev |

Commit infra : `b797495` (main, pousse)

---

## 7. Runtime validation DEV

| Surface | Resultat |
|---|---|
| Pod API DEV | Running (v3.5.166) |
| Pod Client DEV | Running (v3.5.175) |
| Milestones FR | Espace cree, Premier canal connecte, Premiere reponse envoyee... OK |
| Unavailable FR | Mode suggestion active, Mode autopilot active, Agent KeyBuzz active OK |
| Limitations FR | 4 phrases francais avec accents OK |
| AI KPI | draftsUsed=20, suggestionsGenerated=9, structure preservee OK |
| Satisfaction | null, not instrumented OK |
| Series | 21 points chacune OK |
| Literal escapes in API JSON | false OK |

---

## 8. Non-regression PROD

| Service PROD | Image avant | Image apres | Verdict |
|---|---|---|---|
| API PROD | v3.5.149-message-source-enrichment-prod | v3.5.149-message-source-enrichment-prod | INCHANGEE |
| Client PROD | v3.5.172-message-source-enrichment-ux-prod | v3.5.172-message-source-enrichment-ux-prod | INCHANGEE |
| Backend PROD | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | INCHANGEE |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | INCHANGEE |

---

## 9. Rollback DEV

```bash
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.165-performance-sav-polish-dev -n keybuzz-api-dev
# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.174-performance-sav-polish-dev -n keybuzz-client-dev
```

---

## 10. Linear

- KEY-289 : AR.6.1A encoding fix complete. API v3.5.166 + Client v3.5.175 DEV.
- KEY-282 : Encoding fix pret, prochaine etape QA Ludovic.
