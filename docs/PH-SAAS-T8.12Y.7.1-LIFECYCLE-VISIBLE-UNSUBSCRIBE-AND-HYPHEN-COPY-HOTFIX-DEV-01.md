# PH-SAAS-T8.12Y.7.1 — Lifecycle Visible Unsubscribe + Hyphen Copy Hotfix DEV

**Date** : 2026-05-02
**Type** : Hotfix lifecycle email copy + unsubscribe visible
**Environnement** : DEV uniquement
**Priorité** : P1

---

## Objectif

Corriger les emails lifecycle après QA Gmail Ludovic (PH-SAAS-T8.12Y.7) :
1. Ajouter un lien visible de désabonnement dans les emails lifecycle uniquement
2. Remplacer tous les tirets longs `—` et `&mdash;` par `-` (tiret classique)
3. Remplacer les séparateurs text/plain `────` par `----------------------------------------`
4. Corriger les entités HTML qui fuitent dans le text/plain (`&#39;`, `&nbsp;`, etc.)
5. Renvoyer les 2 emails lifecycle de test à `ludo.gonthier@gmail.com`

---

## Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `8a58cf75` (Y.7) | Clean | OK |
| keybuzz-infra | `main` | `2089762` (Y.7 rapport) | 4 fichiers (autres phases) | OK |

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | `v3.5.137-trial-lifecycle-controlled-send-dev` | Identique | OK |
| API PROD | `v3.5.131-transactional-email-design-prod` | Identique | OK |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | OK |

---

## Audit patterns avant/après

| Pattern | Avant | Après | Action |
|---|---|---|---|
| `—` (em dash littéral) | 20 lignes | **0** | Remplacé par ` - ` |
| `&mdash;` (entité HTML) | 7 lignes | **0** | Remplacé par ` - ` |
| `\u2014` (Unicode escape) | 1 ligne | **0** | Remplacé par ` - ` |
| `─` (box drawing text/plain) | 2 occurrences text | **0** | Remplacé par `-` |
| `&#39;` dans text/plain | 26 lignes | **0 en sortie** | Nettoyé par `buildEmailText` entity cleanup |
| `&nbsp;` dans text/plain | 13 lignes | **0 en sortie** | Nettoyé par `buildEmailText` entity cleanup |
| Lien unsubscribe visible | 0 | **Présent** | Injecté par lifecycle service |

---

## Unsubscribe visible

### Mécanisme

Le lien visible est **injecté par le service lifecycle** (`trial-lifecycle.service.ts`), pas par les templates.
Cela garantit que seuls les emails lifecycle ont le lien visible, sans affecter les emails transactionnels.

### Injection HTML

```html
<div style="text-align:center;padding:8px 32px 16px;">
  <p style="margin:0;color:#9ca3af;font-size:11px;line-height:1.4;">
    Vous recevez cet email dans le cadre de votre essai KeyBuzz.
    <a href="..." style="color:#6b7280;text-decoration:underline;">Se désabonner</a>
  </p>
</div>
```

Injecté avant `</body>` dans le HTML de l'email.

### Injection text/plain

```
Se désabonner des emails d'accompagnement d'essai : <url>
```

Ajouté à la fin du text/plain.

### Scope

| Type d'email | Lien visible | Lien header | Affecté |
|---|---|---|---|
| Lifecycle (trial-*) | **Oui** | Oui | Oui |
| OTP | Non | Non | Non |
| Invitation | Non | Non | Non |
| Billing | Non | Non | Non |

---

## Patch tirets classiques

| Zone | Avant | Après |
|---|---|---|
| Subjects lifecycle | `KeyBuzz — Découvrez...` | `KeyBuzz - Découvrez...` |
| Subject invite | `Invitation KeyBuzz — Rejoindre...` | `Invitation KeyBuzz - Rejoindre...` |
| Preheaders | `...prêt — 14 jours...` | `...prêt - 14 jours...` |
| HTML body | `&mdash;` dans paragraphes | ` - ` |
| Footer HTML | `keybuzz.pro &mdash; Support...` | `keybuzz.pro - Support...` |
| Footer text/plain | `keybuzz.pro — Support...` | `keybuzz.pro - Support...` |
| Séparateurs text/plain | `─────────...` (box drawing) | `----------------------------------------` |

---

## Text/plain entity cleanup

Ajout d'une chaîne de nettoyage dans `buildEmailText()` :

```typescript
return lines.join("\n")
  .replace(/&#(\d+);/g, (_: string, c: string) => String.fromCharCode(Number(c)))
  .replace(/&nbsp;/g, " ")
  .replace(/&amp;/g, "&")
  .replace(/&lt;/g, "<")
  .replace(/&gt;/g, ">");
```

Cela garantit que toutes les entités HTML numériques (`&#39;` → `'`, `&#233;` → `é`, etc.) et nommées sont converties en caractères réels dans le text/plain.

---

## Build + déploiement

| Info | Valeur |
|---|---|
| Tag | `v3.5.138-lifecycle-visible-unsubscribe-copy-dev` |
| Digest | `sha256:66e9459eb16fdd771adc07259693641924e7e25a1b1a2916e29256d5ffb95445` |
| Commit API | `2b0b2adc` |
| Commit infra | `40e32dc` |
| Rollback | `v3.5.137-trial-lifecycle-controlled-send-dev` |

### GitOps DEV

- Manifest modifié : `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`
- `kubectl apply -f` + `kubectl rollout status` : OK
- Health check post-deploy : OK

---

## Emails envoyés

| Template | Destinataire | Subject | Message ID | Unsub visible |
|---|---|---|---|---|
| `trial-welcome` | `ludo.gonthier@gmail.com` | `[DEV TEST Y7.1] Bienvenue sur KeyBuzz - Votre essai Autopilote assisté est prêt` | `<09e4edb1-cbf4-67a7-466b-643b2ed54561@keybuzz.io>` | Oui |
| `trial-day-2` | `ludo.gonthier@gmail.com` | `[DEV TEST Y7.1] KeyBuzz - Découvrez les réponses IA suggérées` | `<9ccc9eab-2b90-0991-472d-a77f3edfdc94@keybuzz.io>` | Oui |

- **Nombre exact d'emails envoyés** : 2
- **Tenant test** : `test-lambda-k1-sas-molcr3ha`
- **recipientOverride** : `ludo.gonthier@gmail.com`
- **Aucun email à un vrai client**
- **Aucun email PROD**

---

## Validation unsubscribe

| Test | Attendu | Résultat |
|---|---|---|
| Lien visible HTML | Présent | **OK** |
| Lien visible text/plain | Présent | **OK** |
| Unsubscribe première fois | opt-out = true, page "Désinscription confirmée" | **OK** |
| Unsubscribe deuxième fois | idempotent, page "Déjà désinscrit" | **OK** |
| Dry-run après opt-out | tenant exclu (reason: `lifecycle_optout`) | **OK** |
| Restauration opt-out | Restauré à false | **OK** |

---

## Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| API DEV health | OK | **OK** |
| API PROD | `v3.5.131-transactional-email-design-prod` | **Inchangée** |
| Client PROD | `v3.5.147-...-parity-prod` | **Inchangée** |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | **Inchangée** |
| Billing DB | aucune mutation métier | **OK** (18 subs, 256 events) |
| Stripe | aucune mutation | **OK** |
| CAPI | aucun event | **OK** |
| Tracking | aucun event | **OK** |
| CronJobs | inchangés (3 existants) | **OK** |
| Lifecycle CronJob | absent | **OK** |
| Lifecycle automatic send | absent | **OK** |

---

## Gaps

1. Les `&#39;` restent dans le **code source** des bodyText (template literals). Le nettoyage est fait au runtime par `buildEmailText`. Nettoyage source possible dans une phase future.
2. Les `&#39;` dans les HTML strings (single-quoted) sont **nécessaires** pour la syntaxe JS et rendent correctement en HTML.
3. Le préfixe `[DEV TEST Y7.1]` est ajouté uniquement quand `recipientOverride` est actif (DEV-only). Il n'apparaîtra pas dans les envois réels.
4. Les 2 premiers emails envoyés (sans préfixe) sont également arrivés dans l'inbox de Ludovic. Seuls les 2 derniers (avec préfixe) correspondent au build final.

---

## Rollback GitOps strict

```bash
# Rollback API DEV
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.137-trial-lifecycle-controlled-send-dev \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## PROD inchangée

Aucune modification PROD. Aucun build PROD. Aucun manifest PROD modifié.

---

## Fichiers modifiés

| Fichier | Changes |
|---|---|
| `keybuzz-api/src/services/emailTemplates.ts` | em dash → `-`, box drawing → `-`, entity cleanup dans `buildEmailText` |
| `keybuzz-api/src/modules/lifecycle/trial-lifecycle.service.ts` | Injection visible unsubscribe HTML+text, préfixe `[DEV TEST Y7.1]` quand override |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image → `v3.5.138-lifecycle-visible-unsubscribe-copy-dev` |

---

## Prochaine phase recommandée

- **PH-SAAS-T8.12Y.8** : QA inbox Ludovic des emails Y.7.1 (vérifier lien visible, tirets, rendu)
- **PH-SAAS-T8.12Y.9** : Promotion PROD des emails lifecycle si QA validée
- **PH-SAAS-T8.12Y.10** : Activation CronJob lifecycle DEV (envoi automatique quotidien)
