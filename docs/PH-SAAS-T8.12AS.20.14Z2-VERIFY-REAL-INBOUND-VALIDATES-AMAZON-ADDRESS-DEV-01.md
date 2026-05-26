# PH-SAAS-T8.12AS.20.14Z2-VERIFY-REAL-INBOUND-VALIDATES-AMAZON-ADDRESS-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14Z (apply DEV) / PH-20.14W (source patch) / PH-20.14V (verify PROD)
> Phase : PH-SAAS-T8.12AS.20.14Z2 (VERIFY REAL INBOUND, read-only)
> Environnement : READ-ONLY DEV + PROD (aucune mutation)

## 1. Verdict

GO VERIFY REAL INBOUND VALIDATES AMAZON ADDRESS DEV READY PH-SAAS-T8.12AS.20.14Z2

Cas A (READY_DEV). Un vrai message Amazon (compte test Switaa -> vendeur eComLG, envoye ~13:56 UTC) a atteint les DEUX environnements (mail-core poste vers backend-dev ET backend-prod). En DEV (v1.0.54, patch PH-20.14W ACTIF), le chemin real-inbound a resolu l'adresse EXACTE par emailAddress (token 3jcpvk -> adresse cmk83fvgd000k8s01agb8tf9j) et l'a marquee validationStatus=VALIDATED. En PROD (v1.0.53, patch PAS actif), l'adresse reste PENDING (attendu). Le patch est donc prouve de bout en bout sur un vrai message Amazon en DEV. Aucune mutation effectuee par cette phase (lecture seule). Decision : promouvoir v1.0.54 en PROD.

## 2. Preflight runtime (E0)

| Environment | API image | worker image | ready | restarts | verdict |
|---|---|---|---|---|---|
| DEV (keybuzz-backend-dev) | v1.0.54-amazon-validation-pipeline-dev | v1.0.54-amazon-validation-pipeline-dev | 1/1 | 0 | patch 14W actif |
| PROD (keybuzz-backend-prod) | v1.0.53-amazon-validation-pipeline-prod | v1.0.53-amazon-validation-pipeline-prod | 1/1 | 0 | patch 14W absent |

Bastion install-v3 (46.62.171.61), date 2026-05-26 ~14:01 UTC. mail-core-01 stable.

## 3. mail-core (E1)

relay=webhook recents (mail-core poste vers backend-dev ET backend-prod, dual-post avec suffixe messageId -dev/-prod) :

| Timestamp UTC | recipient | token | status |
|---|---|---|---|
| 13:52:45 | amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io | 4xfub8 | sent (webhook) |
| 13:52:45 | amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io | 3jcpvk | sent (webhook) |
| 13:56:13 | amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io | 4xfub8 | sent (webhook) |
| 13:56:13 | amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io | 3jcpvk | sent (webhook) |

Destinataire = tenant ecomlg-001 (eComLG FR). Le webhook cible les DEUX backends ; impossible de distinguer DEV/PROD au niveau mail-core (le script poste aux deux URL).

## 4. Backend logs (E2)

| Environment | log evidence | interpretation |
|---|---|---|
| DEV (v1.0.54) | "[AmazonDetection] Real Amazon message detected for ecomlg-001/amazon/FR; resolving inbound address by emailAddress" ; token 3jcpvk -> "Inbound address cmk83fvgd000k8s01agb8tf9j marked VALIDATED from real Amazon message (ecomlg-001/amazon/FR)" ; token 4xfub8 -> "Real Amazon inbound ... address not resolved (Address not found) - no validation" + "lastInboundAt matched 0 inbound address for ... 4xfub8" | patch 14W ACTIF : resolution emailAddress exact ; 3jcpvk resolu+valide, 4xfub8 absent en DEV donc refuse (comportement correct) |
| PROD (v1.0.53) | ancien log "[AmazonDetection] Updating marketplaceStatus to VALIDATED for ecomlg-001/amazon/FR" (blanket updateMany, pas le nouveau log) ; ExternalMessage + conversation crees (conv cmmpml7hy..., threaded) ; autopilot trigger 200 | code pre-patch : log emis mais updateMany casse-dependant ne persiste rien |

## 5. DB message / conversation (E3)

| Environment | tenant | conversation | createdAt | note |
|---|---|---|---|---|
| DEV | ecomlg-001 | cmmkfq1qp... (autopilot trigger threaded) | ~13:56 | ingere |
| PROD | ecomlg-001 | cmmpml7hy973b1706b3f49631 (threaded sur conversation existante) | ~13:56 | ingere |

Message inbound buyer = compte test Switaa (anonymise relais amazonses) ; PII non affichee. Aucune reponse envoyee.

## 6. DB inbound address status (E4)

| Environment | address id | token | validationStatus | marketplaceStatus | pipelineStatus | lastInboundAt | verdict |
|---|---|---|---|---|---|---|---|
| DEV | cmk83fvgd000k8s01agb8tf9j | 3jcpvk | VALIDATED | VALIDATED | VALIDATED | 2026-05-26T13:56:12Z | VALIDE par patch 14W (real inbound) |
| DEV | cmk5ty3e700033r01p8ji1lz8 | cp2hat | PENDING | VALIDATED | VALIDATED | 2026-05-26T13:37:58Z | autre adresse, validationStatus non set (traitement anterieur) |
| PROD | cmmsdn4if0003at01cwu3p6if | 4xfub8 | PENDING | PENDING | PENDING | null | INCHANGE (patch absent en PROD) |

DEV : tenant ecomlg-001 a 2 adresses FR (3jcpvk, cp2hat) ; jeu different de PROD (4xfub8 seul). PROD global validationStatus VALIDATED = 0. La validation DEV de 3jcpvk via un vrai message Amazon prouve : updateMarketplaceStatusIfAmazon -> resolution emailAddress exact -> validationStatus=VALIDATED (champ lu par le guard outbound).

## 7. Decision (E5) : Cas A READY_DEV

Le patch PH-20.14W transforme PENDING -> VALIDATED sur un VRAI message Amazon entrant, prouve en DEV (adresse 3jcpvk). PROD recoit l'inbound (routage + ingestion OK) mais reste sur v1.0.53 : validationStatus PENDING attendu jusqu'a promotion. Le 4xfub8 "Address not found" en DEV est correct (DEV n'a pas cette adresse) et ne remet pas en cause le patch.

Aucune mutation par cette phase (SELECT + logs uniquement). Aucun trigger, aucun email, aucun flip, aucun retry.

## 8. No unintended action

| Signal | etat |
|---|---|
| mutation DB par cette phase | aucune (la validation DEV de 3jcpvk vient du vrai message Ludovic, pas du CE) |
| trigger send-validation | aucun |
| email envoye / reponse marketplace | aucun |
| flip validationStatus manuel | aucun |
| retry outbound | aucun |
| secret/token/passwordHash affiche | aucun |

## 9. Rollback

Sans objet (lecture seule, aucune mutation).

## 10. Prochaine phase

GO BUILD BACKEND AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14AA

Promotion PROD du patch : build image v1.0.54-amazon-validation-pipeline-prod from-git d27f4a5 (option image PROD dediee, convention -prod), push GHCR, apply PROD GitOps (deployment.yaml API + deployment-jobs-worker.yaml PROD v1.0.53-prod -> v1.0.54-prod), rollout, verifier digest + no unintended processing. Apres promotion, un vrai message Amazon (ou self-test) validera l'adresse PROD ecomlg-001 FR (cmmsdn4if / 4xfub8) via le chemin real-inbound, debloquant le guard outbound.

Phrase cible : GO VERIFY REAL INBOUND VALIDATES AMAZON ADDRESS DEV READY PH-SAAS-T8.12AS.20.14Z2

STOP.
