# Features deployees KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : resume de l'etat des features d'apres la matrice de verite.

## Sources

- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\FEATURE_TRUTH_MATRIX_V2.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH142-O1-FEATURE-MATRIX-EXECUTION-01.md`
- `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\feature_registry.json`

Methode de la matrice V2 : tests navigateur reels + API + DB par plan. Derniere execution indiquee : 2026-04-05.

## Resume global V2

| Statut | Nombre | Pourcentage |
|---|---:|---:|
| GREEN valide | 31 | 77.5% |
| ORANGE limite structurelle | 2 | 5% |
| RED casse/absent | 7 | 17.5% |
| Total | 40 | 100% |

## Features GREEN

| ID | Feature | Notes |
|---|---|---|
| PLAY-01 | Playbooks CRUD API-backed | PRO/AUTOPILOT OK |
| PLAY-02 | Playbooks tester | PRO/AUTOPILOT OK |
| AI-01 | Aide IA manuelle | PRO/AUTOPILOT OK |
| AI-02 | Flag erreur IA | PRO/AUTOPILOT OK |
| AI-03 | Clustering erreurs IA | PRO/AUTOPILOT OK |
| AI-04 | Detection fausses promesses | PRO/AUTOPILOT OK |
| AI-06 | Contexte intelligent | PRO/AUTOPILOT OK |
| AI-07 | Journal IA | STARTER gate, PRO/AUTOPILOT OK |
| APT-01 | Settings Autopilot persistantes | PRO/AUTOPILOT OK |
| APT-02 | Engine execution | PRO gate, AUTOPILOT OK |
| APT-03 | Safe mode draft | PRO gate, AUTOPILOT OK |
| APT-04 | Draft consume | PRO gate, AUTOPILOT OK |
| APT-05 | KBActions debit | PRO/AUTOPILOT OK |
| APT-06 | UI feedback badge | PRO/AUTOPILOT OK |
| BILL-01 | Upgrade plan CTA | PRO OK |
| BILL-03 | `hasAgentKeybuzzAddon` | PRO/AUTOPILOT OK |
| BILL-04 | URL sync post-Stripe | PRO/AUTOPILOT OK |
| BILL-05 | Addon gating | PRO/AUTOPILOT OK |
| BILL-06 | `billing/current` coherent | PRO/AUTOPILOT OK |
| SET-01 | Signature tab | PRO/AUTOPILOT OK |
| SET-02 | Deep-links `?tab=` | PRO/AUTOPILOT OK |
| SET-03 | Tous les onglets settings | PRO/AUTOPILOT OK |
| AGT-01 | Limites agents | PRO/AUTOPILOT OK |
| AGT-02 | Lockdown agents KeyBuzz | PRO/AUTOPILOT OK |
| AGT-03 | Invitation agent E2E | PRO/AUTOPILOT OK |
| ESC-01 | Escalade flow | PRO/AUTOPILOT OK |
| ESC-02 | Assignment semantics | PRO/AUTOPILOT OK |
| INFRA-01 | Rollback scripte | OK |
| INFRA-04 | Build from Git | OK |
| AUTH-01 | Rate limiting | PRO/AUTOPILOT OK |

## Features ORANGE

| ID | Feature | Pourquoi |
|---|---|---|
| AI-05 | Auto-escalade | Badges escalation visibles, mais 0 evenement `AI_AUTO_ESCALATED`; necessite mode autonome reel et message declencheur. |
| BILL-02 | Addon Agent KeyBuzz | Trial AUTOPILOT deverrouille tout, donc gating post-trial non validable avec les tenants existants. |

## Features RED

| ID | Feature | Probleme |
|---|---|---|
| KNOW-01 | Knowledge templates | Route/API absente ou non enregistree. |
| AGT-04 | RBAC agent | Menu masque OK, mais garde URL page cassee pour `/settings`, `/billing`, `/dashboard`. |
| SUP-01 | Supervision panel | Route/panneau supervision absent ou casse. |
| SLA-01 | Priorite / urgence | Non fonctionnel selon matrice V2. |
| TRK-01 | Tracking multi | Non fonctionnel selon matrice V2. |
| IA-CONSIST-01 | Coherence IA | `engine.ts` Autopilot ne partage pas correctement le contexte `shared-ai-context`. |
| INFRA-02 / INFRA-03 | Pre-prod check V2 / Git assert committed | Scripts manquants cote bastion selon ancienne matrice; attention, PH152 a ensuite etabli de nouvelles regles source-of-truth. |

## Gating par plan

| Aspect | STARTER | PRO | AUTOPILOT |
|---|---|---|---|
| Mode IA autonome | gate | gate + CTA | deverrouille |
| Escalade KeyBuzz | gate | gate + CTA | deverrouille |
| Escalade les deux | gate | gate + CTA | deverrouille |
| KBActions/mois | 0 | 1000 | 2000 |
| Canaux max | 1 | 3 | 5 |
| Support | standard | prioritaire | premium |
| Journal IA | gate | oui | oui |
| Supervision avancee | gate | non | oui |
| Auto-execute | gate | non | oui |
| AI quota | 3/jour | illimite | illimite |

## Anomalies a retenir

- `ecomlg-001` avait `plan='pro'` en minuscule, tenant pilote concerne.
- Un tenant STARTER de test etait incomplet et verrouille sans abonnement.
- Aucun tenant AUTOPILOT post-trial actif n'etait disponible dans cette matrice.
- RBAC agent a un risque securite par navigation directe.
- Les phases Autopilot plus recentes ont avance apres la matrice V2 : toujours recouper avec `PH-AUTOPILOT-E2E-TRUTH-AUDIT-01.md`.
