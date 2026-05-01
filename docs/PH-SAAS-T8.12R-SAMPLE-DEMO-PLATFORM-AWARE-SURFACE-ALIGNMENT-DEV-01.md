# PH-SAAS-T8.12R — Sample Demo Platform-Aware Surface Alignment DEV

**Phase** : PH-SAAS-T8.12R-SAMPLE-DEMO-PLATFORM-AWARE-SURFACE-ALIGNMENT-DEV-01
**Date** : 2026-05-01
**Linear** : KEY-235 (ouvert — en attente promotion PROD)
**Environnement** : DEV uniquement
**Type** : réalignement surfaces visibles — Sample Demo Wow platform-aware

---

## Objectif

Réaligner les surfaces demo visibles côté client SaaS avec la vérité API PROD :
- L'IA KeyBuzz est platform-aware
- Amazon/Octopia = posture marketplace stricte
- Email = canal direct seller-controlled
- La demo ne donne plus l'impression que KeyBuzz est Amazon-only
- Aucun texte ne promet de remboursement prématuré
- Zero DB/API/tracking/billing/CAPI drift

## Sources relues

- `AI_MEMORY/SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md`
- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- Rapports PH-SAAS-T8.12O, T8.12O.1, T8.12P, T8.12Q, T8.12Q.1, T8.12Q.2
- Rapports PH-SAAS-T8.12N, N.1, N.2, N.3, N.3.1, N.4

## Préflight

| Repo | Branche | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay | f6ae911c | Non | OK |
| keybuzz-infra | main | 1614d22 | Non | OK |

| ENV | Image manifest | Image runtime | Match ? |
|---|---|---|---|
| Client DEV | v3.5.143-sample-demo-seller-first-dev | idem | OK |
| Client PROD | v3.5.145-client-ga4-sgtm-parity-prod | idem | OK |
| API DEV | v3.5.130-platform-aware-refund-strategy-dev | idem | OK |
| API PROD | v3.5.130-platform-aware-refund-strategy-prod | idem | OK |

## Audit surfaces

| Surface | Problème | Action |
|---|---|---|
| sampleData.ts: 5/5 conversations = Amazon | Amazon-only implicite | conv-003 → email, conv-004 → octopia |
| DemoBanner: "Connecter Amazon", "compte Amazon" | Amazon-only CTA | → "Connecter un canal", "canal de vente" |
| DemoDashboardPreview: "connexion Amazon" | Amazon-only | → "connexion d'un canal" |
| DemoInboxExperience: "Connectez Amazon" | Amazon-only | → "Connectez un canal de vente" |
| Prop onConnectAmazon | Convention Amazon-only | → onConnect |

## Patch

| Fichier | Changement |
|---|---|
| sampleData.ts | conv-003: channel amazon→email, handle→marie.l@exemple-client.fr |
| sampleData.ts | conv-004: channel amazon→octopia, handle→acheteur-exemple-4@cdiscount |
| sampleData.ts | conv-004 suggestion: "sur Amazon"→"sur la marketplace", "Amazon"→"marketplace" |
| DemoBanner.tsx | onConnectAmazon→onConnect, "Connecter Amazon"→"Connecter un canal", texte généralisé |
| DemoInboxExperience.tsx | onConnectAmazon→onConnect, "Connectez Amazon"→"Connectez un canal de vente" |
| DemoDashboardPreview.tsx | onConnectAmazon→onConnect, "connexion Amazon"→"connexion d'un canal" |
| DemoOnboardingCard.tsx | Ré-encodé UTF-8 proprement (texte déjà neutre) |

## Validation statique

| Check | Résultat |
|---|---|
| 0 appel API write dans demo/ | OK |
| 0 AW-18098643667 | OK |
| 0 secret | OK |
| 0 codex | OK |
| 0 wording refund-first | OK |
| 0 "Connecter Amazon" résiduel | OK |
| dismiss tenant-scoped | OK (kb_demo_dismissed:v1:) |
| 0 onConnectAmazon résiduel | OK |

## Build DEV

| Élément | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.146-sample-demo-platform-aware-dev |
| Source | Clone propre ph148/onboarding-activation-replay HEAD: 3d858a8 |
| Build args | NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io |
| Digest | sha256:a99d8b934c7a11b8b3f120367f29a3b77904f37e1afef99f41140cb28f02cdff |
| Build depuis bastion | /tmp/keybuzz-client-rebuild-dev-r (clone propre, nettoyé) |

## GitOps DEV

| Manifest | Avant | Après | Runtime |
|---|---|---|---|
| keybuzz-client-dev/deployment.yaml | v3.5.143-sample-demo-seller-first-dev | v3.5.146-sample-demo-platform-aware-dev | v3.5.146-sample-demo-platform-aware-dev |

Commit infra : `0b375f0` → `main`

## Validation navigateur DEV

- Bundle contient `onConnect` (pas onConnectAmazon)
- Bundle contient "Connecter un canal" (pas "Connecter Amazon")
- Bundle contient "Connectez un canal de vente"
- Bundle contient "connexion d'un canal"
- Bundle contient channel:"email" (conv-003) et channel:"octopia" (conv-004)
- 0 restarts
- Client PROD inchangé : v3.5.145-client-ga4-sgtm-parity-prod

## Non-pollution / Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| DB demo-* rows | 0 | 0 |
| Billing events récents | 0 | 0 |
| API DEV health | ok | ok |
| API PROD health | ok | ok |
| Client PROD | v3.5.145 (inchangé) | OK |
| Website PROD | v0.6.8 (inchangé) | OK |
| Backend PROD | v1.0.46 (inchangé) | OK |
| Client DEV restarts | 0 | 0 |

## Gaps restants

| Gap | Sévérité | Phase |
|---|---|---|
| Octopia/Cdiscount/FNAC non différenciés (tous "octopia") | Faible | Future si API distingue |
| Pages non-demo mentionnent Amazon légitimement | N/A | Hors scope |
| Admin/Playbook docs pas mis à jour | Faible | Phase admin séparée |
| KEY-235 ouvert jusqu'à promotion PROD | Normal | PH-SAAS-T8.12R.1 |

## Rollback GitOps DEV

```bash
# Modifier deployment.yaml :
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.143-sample-demo-seller-first-dev
# Puis : kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
```

## PROD

**PROD strictement inchangée.**

| Service | Image PROD |
|---|---|
| Client | v3.5.145-client-ga4-sgtm-parity-prod |
| API | v3.5.130-platform-aware-refund-strategy-prod |
| Backend | v1.0.46-ph-recovery-01-prod |
| Website | v0.6.8-tiktok-browser-pixel-prod |

## KEY-235

- Statut : ouvert
- API PROD platform-aware : DONE (T8.12Q.2)
- Client DEV platform-aware demo : DONE (T8.12R)
- Restant : promotion PROD client (PH-SAAS-T8.12R.1)

---

## Verdict

**SAMPLE DEMO PLATFORM-AWARE ALIGNMENT READY IN DEV — DEMO NOW REFLECTS MARKETPLACE VS DIRECT CHANNEL DIFFERENCES — REFUND-FIRST WORDING ABSENT — NO DB/API/TRACKING/BILLING/CAPI DRIFT — PROD UNCHANGED**

Rapport : `keybuzz-infra/docs/PH-SAAS-T8.12R-SAMPLE-DEMO-PLATFORM-AWARE-SURFACE-ALIGNMENT-DEV-01.md`
