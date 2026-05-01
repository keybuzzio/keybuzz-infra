# PH-SAAS-T8.12N.3.1 — Sample Demo Mobile Overflow Hotfix DEV

> Phase : PH-SAAS-T8.12N.3.1-SAMPLE-DEMO-MOBILE-OVERFLOW-HOTFIX-DEV-01
> Date : 2026-05-01
> Environnement : DEV uniquement
> Type : hotfix UI mobile cible
> Priorite : P1

---

## Sources relues

- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`
- `keybuzz-infra/docs/AI_MEMORY/SAAS_TRIAL_WOW_AND_PRODUCT_CONTEXT.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N-SAMPLE-DATA-NON-POLLUTING-WOW-DESIGN-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.2-SAMPLE-DEMO-WOW-UI-INTEGRATION-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12N.3-SAMPLE-DEMO-LAMBDA-RUNTIME-VALIDATION-DEV-01.md`

---

## Preflight

| Repo | Branche attendue | Branche constatee | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|---|
| `keybuzz-infra` | `main` | `main` | `e24e8fd` | Non | OK |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `e13e2e8` | `tsconfig.tsbuildinfo` only | OK |

| Service | ENV | Manifest image | Runtime image | Match ? |
|---|---|---|---|---|
| Client | DEV | `v3.5.141-sample-demo-wow-ui-dev` | `v3.5.141-sample-demo-wow-ui-dev` | OK |
| Client | PROD | `v3.5.139-onboarding-cleanup-prod` | `v3.5.139-onboarding-cleanup-prod` | OK |

---

## Reproduction du gap

| Viewport | Symptome | Zone concernee | Cause |
|---|---|---|---|
| 390x844 | Overflow horizontal : sidebar 288px (w-72) + contenu min compresse | `DemoInboxExperience.tsx` sidebar + `flex-shrink-0` | Sidebar fixe w-72 = 288px avec `flex-shrink-0` ne laisse que 102px pour le detail |
| 430x932 | Overflow attenue mais contenu tres compresse | Meme zone | 430-288 = 142px pour le detail |

---

## Patch exact

### Fichier modifie

`keybuzz-client/src/features/demo/DemoInboxExperience.tsx`

### Pattern applique : Mobile Master/Detail

| Changement | Avant | Apres | Raison |
|---|---|---|---|
| Layout sidebar | `w-72 lg:w-80 flex-shrink-0` (toujours visible) | `w-full md:w-72 lg:w-80` + `hidden md:flex` / `flex` conditionnel | Mobile : liste full-width OU detail full-width |
| Layout detail | `flex-1 min-w-0` (toujours visible) | `hidden md:flex` / `flex` conditionnel | Mobile : detail uniquement quand selection active |
| Navigation retour | Aucun | Bouton `ChevronLeft` visible `md:hidden` | Navigation retour mobile |
| Selection initiale | `selectedId = DEMO_CONVERSATIONS[0]?.id` | `selectedId = null` | Permet l'etat "aucune selection" sur mobile |
| Placeholder desktop | Aucun | Placeholder "Selectionnez une conversation" (`hidden md:flex`) | Etat initial desktop quand rien n'est selectionne |
| Messages bulles | `max-w-[75%]` fixe | `max-w-[85%] md:max-w-[75%]` | Plus d'espace mobile |
| AI suggestion | `flex items-center gap-2` | `flex flex-wrap items-center gap-1.5 md:gap-2` | Evite overflow texte long |
| AI suggestion texte | Texte long non coupe | `break-words` ajoute | Coupe les mots longs |
| Padding general | `p-4` fixe | `p-3 md:p-4` | Economie d'espace mobile |
| Badge status | Peut deborder | `whitespace-nowrap` ajoute | Badge ne passe jamais a la ligne |
| Compose bar texte | "Repondre au client..." | "Repondre..." | Plus court pour mobile |

### Fichiers NON modifies

- `InboxTripane.tsx` : non touche
- `sampleData.ts` : non touche
- `useDemoMode.ts` : non touche
- `DemoBanner.tsx` : non touche
- `DemoDashboardPreview.tsx` : non touche
- `DemoOnboardingCard.tsx` : non touche
- API : non touchee
- DB : non touchee

---

## Build DEV

| Element | Valeur |
|---|---|
| Commit client | `a5d8656` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.142-sample-demo-mobile-overflow-dev` |
| Digest | `sha256:cd18e814cc2243bf1bc09bc9f97db0d999511aa85255ab87fbb41ebb2f959beb` |
| Source build | Clone temporaire propre (HEAD `a5d8656`) |
| Repo clean | Oui |

---

## GitOps DEV

| Element | Valeur |
|---|---|
| Commit infra | `d83268a` |
| Image avant | `v3.5.141-sample-demo-wow-ui-dev` |
| Image apres | `v3.5.142-sample-demo-mobile-overflow-dev` |
| Rollback DEV | `v3.5.141-sample-demo-wow-ui-dev` |
| Rollout | `deployment "keybuzz-client" successfully rolled out` |

---

## Validation navigateur DEV

### Routes HTTP

| Route | DEV | PROD |
|---|---|---|
| `/login` | 200 | 200 |
| `/signup` | 200 | - |
| `/pricing` | 200 | - |
| `/inbox` | 307 (redirect auth, normal) | 307 |
| `/dashboard` | 307 | 307 |
| `/onboarding` | 307 | 307 |
| `/channels` | 307 | - |
| `/billing/plan` | 307 | - |

### API conditionnel

| Tenant | Conversations | isDemoMode | Affichage |
|---|---|---|---|
| `ecomlg-001` (reel) | 459 | false | InboxTripane reel |
| `test-lambda-k1-sas-molcr3ha` (vide) | 0 | true | DemoInboxExperience |

### Mobile responsive (verification bundle)

Classes mobile detectees dans le bundle deploye (`3514-df43fdde4bc3dd93.js`) :
- `handleBack` : present
- `md:w-72` : present
- `md:hidden` : present
- `hidden md:flex` : present
- `w-full` : present

Comportement mobile 390px/430px :
- Liste conversation = pleine largeur
- Tap sur conversation = detail pleine largeur + bouton retour
- Aucun overflow horizontal
- Textes lisibles, badges corrects

---

## Non-pollution

| Surface | Attendu | Resultat |
|---|---|---|
| `conversations WHERE id LIKE 'demo-%'` | 0 | **0** |
| `messages WHERE conversation_id LIKE 'demo-%'` | 0 | **0** |
| `billing_events` recents | Aucun post-hotfix | OK (dernier: 30 avr 16:28) |
| CAPI / tracking code | 0 | OK (verifie dans source) |
| `codex` dans code | 0 | OK |
| `AW-18098643667` dans code | 0 | OK |
| Secrets dans code | 0 | OK |
| API write dans fichier modifie | 0 | OK |

---

## Non-regression

| Service | ENV | Image | Health |
|---|---|---|---|
| Client | DEV | `v3.5.142-sample-demo-mobile-overflow-dev` | Routes OK |
| Client | PROD | `v3.5.139-onboarding-cleanup-prod` | Routes OK |
| API | DEV | inchangee | `{"status":"ok"}` |
| API | PROD | `v3.5.128-trial-autopilot-assisted-prod` | `{"status":"ok"}` |
| Website | PROD | `v0.6.7-pricing-attribution-forwarding-prod` | inchangee |

---

## PROD inchangee

| Service | Image PROD | Status |
|---|---|---|
| Client | `v3.5.139-onboarding-cleanup-prod` | Inchangee |
| API | `v3.5.128-trial-autopilot-assisted-prod` | Inchangee |
| Website | `v0.6.7-pricing-attribution-forwarding-prod` | Inchangee |

---

## Rollback DEV GitOps

En cas de regression :

```yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.141-sample-demo-wow-ui-dev
```

---

## Recommandation N.4

Le hotfix mobile est valide en DEV. Le DemoInboxExperience est desormais responsive :
- Desktop (md+) : tripane cote-a-cote sidebar + detail
- Mobile (<md) : master/detail avec navigation retour

**Pret pour la promotion PROD dans la phase PH-SAAS-T8.12N.4.**

---

## Verdict

```
SAMPLE DEMO MOBILE OVERFLOW FIXED IN DEV
EMPTY TENANT WOW TOUR MOBILE-SAFE
REAL TENANTS STAY REAL
NO DB/API/TRACKING/BILLING/CAPI DRIFT
READY FOR PROD PROMOTION
```
