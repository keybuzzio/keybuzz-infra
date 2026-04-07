# PH143-FR-FULL-FRANCISATION-01

**Date** : 7 avril 2026
**Type** : Polish global client-side (accents + francisation complète)
**Scope** : Client uniquement
**Environnement** : DEV + PROD

---

## 1. Résumé exécutif

Correction complète de la francisation du SaaS KeyBuzz :
- Remplacement de toutes les séquences unicode échappées (`\u00e9`, `\u00e0`, etc.) par les caractères accentués réels
- Correction des mojibake (double-encodage UTF-8 dans les commentaires)
- Traduction des derniers libellés anglais visibles en UI
- 7 fichiers corrigés, 0 changement de logique métier

---

## 2. Inventaire des corrections

### A. Séquences unicode échappées → caractères réels

| Fichier | Avant | Après | Occurrences |
|---------|-------|-------|-------------|
| `src/features/inbox/utils/aiSuggestions.ts` | `recommand\u00e9e`, `d\u00e9pass\u00e9`, `\u00e0 risque` | `recommandée`, `dépassé`, `à risque` | ~15 |
| `src/features/inbox/components/AISuggestionStats.tsx` | `R\u00e9ponse`, `Priorit\u00e9`, `Appliqu\u00e9e`, `Ignor\u00e9e`, `R\u00e9essayer`, `\u00c9v\u00e9nements` | `Réponse`, `Priorité`, `Appliquée`, `Ignorée`, `Réessayer`, `Événements` | ~10 |
| `src/features/ai-ui/AutopilotSection.tsx` | `L\u2019IA propose`, `Supervis\u00e9`, `s\u00e9curis\u00e9`, `\u00e9quipe` | `L'IA propose`, `Supervisé`, `sécurisé`, `équipe` | ~8 |

### B. Mojibake (double-encodage)

| Fichier | Avant | Après |
|---------|-------|-------|
| `app/api/auth/magic/start/route.ts` | `â€"` (0xC3A2 E282AC E2809D) | ` — ` (em dash) |
| `app/login/page.tsx` | `â€"` | ` — ` |

### C. Libellés anglais → français

| Fichier | Avant | Après |
|---------|-------|-------|
| `app/inbox/[conversationId]/page.tsx` | `Back to Inbox` | `Retour à la boîte de réception` |
| `app/inbox/[conversationId]/page.tsx` | `Order #12345 - Delivery Issue` | `Commande #12345 - Problème de livraison` |
| `src/features/dashboard/components/KpiCards.tsx` | `title="Total conversations"` | `title="Conversations totales"` |

### D. Éléments conservés (intentionnels)

| Élément | Raison |
|---------|--------|
| `AISuggestionSlideOver.tsx` — tables `\u00xx` | Tables de normalisation mojibake (pas d'affichage UI) |
| `OnboardingWizard.tsx` — "Save", "Edit" | Libellés Amazon Seller Central (instructions pour l'utilisateur) |
| `debug/runtime/page.tsx` — "Error" | Page debug DEV uniquement |
| API routes `{ error: 'Unauthorized' }` | Réponses machine (non visibles en UI) |

---

## 3. Zones corrigées

| Zone | Corrections |
|------|-------------|
| **Inbox / IA Suggestions** | Labels escalade, assignation, statut, brouillon — tous en français propre |
| **Supervision IA / Stats** | Type labels, action labels, section "Événements récents" |
| **Settings IA / Autopilot** | Mode labels (Suggestions, Supervisé, Autonome), descriptions, escalation targets |
| **Dashboard / KPI** | "Conversations totales" |
| **Conversation détail** | "Retour à la boîte de réception", titre page |
| **Auth / Login** | Commentaires code nettoyés (mojibake) |

---

## 4. Tests DEV

- Build DEV `v3.5.216-ph143-francisation-dev` compilé sans erreur
- Déployé et rollout OK
- Aucune erreur de compilation (corrections purement textuelles)

---

## 5. Tests PROD

### pre-prod-check-v2.sh prod
```
RESULT: 25/25 passed — ALL GREEN
>>> PROD PUSH AUTHORIZED <<<
```

### Smoke tests PROD
| Endpoint | Résultat |
|----------|----------|
| Client health | ✅ 200 |
| API health | ✅ ok |
| Auth check-user | ✅ exists + hasTenants |
| Dashboard | ✅ 11826 orders |
| Conversations | ✅ 5 conv |
| Orders | ✅ 3 orders |
| Billing | ✅ plan=PRO |
| Pages (9 routes) | ✅ Toutes accessibles |

---

## 6. Commits SHA

| SHA | Message | Branche |
|-----|---------|---------|
| `4d9d736` | PH143-FR francisation complète — unicode escapes, mojibake, labels EN | `rebuild/ph143-client` |

---

## 7. Images déployées

| Env | Tag |
|-----|-----|
| DEV | `v3.5.216-ph143-francisation-dev` |
| PROD | `v3.5.216-ph143-francisation-prod` |
| API | `v3.5.211-ph143-final-prod` (inchangé) |

---

## 8. Rollback

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.215-ph143-ux-polish-prod \
  -n keybuzz-client-prod
```

Image de rollback : `v3.5.215-ph143-ux-polish-prod`

---

## 9. Verdict

### ✅ FULL FRENCH UI CLEAN — ACCENTS FIXED — NO ENCODING ARTIFACT — DEV AND PROD ALIGNED

- ✅ 0 séquence `\u00xx` visible en UI
- ✅ 0 mojibake (double-encodage corrigé)
- ✅ 0 libellé anglais résiduel visible en UI
- ✅ Terminologie cohérente (vouvoiement, SaaS B2B)
- ✅ Build-from-git propre (clone clean)
- ✅ pre-prod-check-v2.sh : 25/25 ALL GREEN
- ✅ Smoke tests PROD : tous OK
- ✅ GitOps mis à jour
- ✅ Rollback documenté
