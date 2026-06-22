# PH-SAAS-T8.12AS.21.89 - Apply Client onboarding register_started owner payload DEV GitOps

Date UTC: 2026-06-22T14:42:22Z

Verdict: READY

Phrase finale:

`GO APPLY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV GITOPS READY PH-SAAS-T8.12AS.21.89`

## Resume Ludovic

Client DEV deployee via GitOps strict sur `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev`. Manifest committe et pousse avant `kubectl apply -f`. Rollout successful. Runtime digest conforme `sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9`. Equality OK: manifest = last-applied = deployment spec = pod spec. Bundle/pod audit OK: `register_started`, `marketing_owner_tenant_id`, UTM/click IDs et API DEV presents; API PROD absente; fake triggers absents. Aucun build, docker push, DB mutation, event, formulaire, checkout, Webflow ou Linear.

## Sources relues

- Mission PH-21.89.
- AI_MEMORY: CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP, CE_PROMPTING_STANDARD.
- Retour PH-21.88.
- Rapports PH-21.88, PH-21.87, PH-21.86.

## Preflight bastion

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Hostname | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| Date UTC | actuelle | 2026-06-22T14:42:22Z | PASS |
| Kube context | present | kubernetes-admin@kubernetes | PASS |
| Image GHCR digest | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| Image config digest | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | PASS |

## Repos

| Repo | Branche | Remote | HEAD | Origin HEAD | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-client | ph148/onboarding-activation-replay | origin/ph148/onboarding-activation-replay | d9631ca087f1 | d9631ca087f1 | 0/0 |  M tsconfig.tsbuildinfo | PASS |
| keybuzz-infra avant manifest | main | origin/main | b3dd49ebc752 | b3dd49ebc752 | 0/0 | 0 | PASS |

## Confirmation PH-21.88

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Verdict PH-21.88 | DONE | confirme | PASS |
| Image poussee | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | confirme | PASS |
| Manifest digest | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| Pull-back | OK | confirme PH-21.88 | PASS |
| Runtime baseline | inchange | confirme PH-21.88 | PASS |

## Manifest Client DEV

| Candidat | Namespace | Deployment | Image actuelle | Verdict |
| --- | --- | --- | --- | --- |
| k8s/keybuzz-client-dev/deployment.yaml | keybuzz-client-dev | keybuzz-client | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | UNIQUE_PASS |

## Snapshot avant

| Surface | Avant |
| --- | --- |
| Client DEV image | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev |
| Client DEV ready/restarts | 1/1 / keybuzz-client-5757fcd8fc-lt5bm:0 |
| Client PROD image | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod |
| Client PROD ready/restarts | 1/1 / keybuzz-client-778b4879bf-dtrpj:0 |
| DB snapshot | DB_SNAPSHOT_SKIPPED_SAFE_SCOPE |

## Diff manifest

| Fichier | Image avant | Image apres | Commit | Verdict |
| --- | --- | --- | --- | --- |
| k8s/keybuzz-client-dev/deployment.yaml | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | bf7c18b4 | PASS |

```diff
diff --git a/k8s/keybuzz-client-dev/deployment.yaml b/k8s/keybuzz-client-dev/deployment.yaml
index 4c776e1..570ac5e 100644
--- a/k8s/keybuzz-client-dev/deployment.yaml
+++ b/k8s/keybuzz-client-dev/deployment.yaml
@@ -74,7 +74,7 @@ spec:
           # PH-SAAS-T8.12AP.2: escalation UX — show target + action-needed (KEY-255)
           # PH-SAAS-T8.12AP.2.1: conversation lifecycle — handler Prenom.N + last handler label (KEY-265)
           # PH-SAAS-T8.12AP.2.2: outbound author_name — inject X-User-Email in sendReply (KEY-266)
-          image: ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev  # PH-SAAS-T8.12AS.20.45 (2026-05-27) KEY-323 AI Assist notification skip SCOPE FIX DEV (PH-20.42-TER src ad4e862) ; build-args DEV api-dev.keybuzz.io + Clarity wuk12h9i33 ; manifest digest sha256:019dea6325fc ; config sha256:8f41c7a48896 ; rollback: v3.5.214-ai-draft-blocked-reason-dev
+          image: ghcr.io/keybuzzio/keybuzz-client:v3.5.[REDACTED_LONG_VALUE]  # PH-SAAS-T8.12AS.20.45 (2026-05-27) KEY-323 AI Assist notification skip SCOPE FIX DEV (PH-20.42-TER src ad4e862) ; build-args DEV api-dev.keybuzz.io + Clarity wuk12h9i33 ; manifest digest sha256:019dea6325fc ; config sha256:8f41c7a48896 ; rollback: v3.5.214-ai-draft-blocked-reason-dev
           imagePullPolicy: Always
           ports:
             - containerPort: 3000
```

## Commit/push manifest

| Repo | Commit | Pushed | Ahead/behind | Dirty |
| --- | --- | --- | --- | --- |
| keybuzz-infra | bf7c18b4 | yes | 0/0 | 0 |

## Dry-run / apply / rollout

| Commande | Attendu | Resultat |
| --- | --- | --- |
| kubectl apply --dry-run=client -f k8s/keybuzz-client-dev/deployment.yaml | OK | deployment.apps/keybuzz-client configured (dry run) |
| kubectl apply --dry-run=server -f k8s/keybuzz-client-dev/deployment.yaml | OK | deployment.apps/keybuzz-client configured (server dry run) |
| kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml | OK | deployment.apps/keybuzz-client configured |
| kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev | successful | Waiting for deployment "keybuzz-client" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "keybuzz-client" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "keybuzz-client" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-client" successfully rolled out |

## Runtime equality

| Surface | Attendu | Resultat |
| --- | --- | --- |
| Manifest image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev |
| Last-applied image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev |
| Deployment spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev |
| Pod spec image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev |
| Pod imageID digest | sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 |
| Pod ready/restarts | ready true | ready=true, restarts=0 |
| HTTP GET/HEAD passif home DEV | no browser JS | HTTP/2 307  |

## Bundle/pod audit

| Marker | Attendu | Resultat |
| --- | --- | --- |
| https://api-dev.keybuzz.io | present | 87 |
| https://api.keybuzz.io | absent | 0 |
| register_started | present | 1 |
| marketing_owner_tenant_id | present | 3 |
| utm_source | present | 1 |
| fbclid / gclid / ttclid / li_fat_id | present | 1/1/1/1 |
| trial_page_viewed | absent browser-side direct | 0 |
| fbq trackCustom trial_page_viewed | absent | 0 |
| complete private key markers | absent | END=0, RSA=0, OPENSSH=0 |
| token candidates applicatifs | absent | sk_live=0, ghp=0, xoxb=0, EAAG-app=0 |

## Non-regression

| Surface | Attendu | Resultat |
| --- | --- | --- |
| Client PROD | inchange | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod |
| API/Website/Admin/Backend et autres deployments | inchanges | 0 |
| latest GHCR Client | non utilise runtime | aucun runtime latest detecte dans Client DEV/PROD |
| DB delta | 0 attribuable CE | DB_SNAPSHOT_SKIPPED_SAFE_SCOPE |

## No fake metrics / no fake events

| Surface | Attendu | Resultat |
| --- | --- | --- |
| Build Docker | 0 | 0 |
| Docker push | 0 | 0 |
| Manifest PROD | 0 | 0 |
| DB mutation | 0 | 0 |
| POST /funnel/event | 0 | 0 |
| Event reel/fake | 0 | 0 |
| Formulaire /register | 0 | 0 |
| Checkout Stripe | 0 | 0 |
| Browser JS | 0 | 0 |
| Webflow / Linear | 0 | 0 |

## Dettes / limites

- DB snapshot non effectue volontairement: DB_SNAPSHOT_SKIPPED_SAFE_SCOPE.
- PH-21.89 ne lance pas la verification READONLY PH-21.90.

## Prochain GO

`GO READONLY VERIFY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV PH-SAAS-T8.12AS.21.90`
