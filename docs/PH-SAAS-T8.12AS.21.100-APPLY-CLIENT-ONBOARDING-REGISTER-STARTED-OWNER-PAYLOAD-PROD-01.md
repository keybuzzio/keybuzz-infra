# PH-SAAS-T8.12AS.21.100 - APPLY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD

Date UTC: 2026-06-23T09:23:55Z
Mode: PROD GitOps apply - Client only
Verdict: READY_WITH_LIMITS

## Resume

Client PROD a ete applique via GitOps strict sur:

- ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod
- digest runtime: sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115
- config digest: sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca

Manifest commit: 7a8bdef

## Preflight

| controle | attendu | observe | verdict |
| --- | --- | --- | --- |
| host | install-v3 | install-v3 | PASS |
| IPv4 publique | 46.62.171.61 | 46.62.171.61 | PASS |
| UTC | date affichee | 2026-06-23T09:23:55Z | PASS |
| kube context | disponible | kubernetes-admin@kubernetes | PASS |
| infra before report | clean | dirty=0 ahead/behind=0/0 | PASS |

## Registry

| image | attendu | observe | verdict |
| --- | --- | --- | --- |
| target digest | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | PASS |
| config digest | sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca | sha256:a2e1fe3a9fbe31b50e915b76a82b3cca86c29af8679c38d9933ef2adf3feadca | PASS |
| latest hash | 151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341 | 151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341 -> 151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341 | PASS |

## Runtime equality

| item | attendu | observe | verdict |
| --- | --- | --- | --- |
| manifest image | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| deployment spec | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| last-applied | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| pod spec | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | PASS |
| pod imageID | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | ghcr.io/keybuzzio/keybuzz-client@sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | PASS |
| pod ready | true | true | PASS |
| pod restarts | 0 | 0 | PASS |
| generation | observed | 428/428 | PASS |

## Bundle/runtime audit

Audit effectue sur l'image filesystem correspondant au digest runtime, apres verification pod imageID.

| marqueur | attendu | observe | verdict |
| --- | --- | --- | --- |
| register_started | present | 1 | PASS |
| marketing_owner_tenant_id | present | 3 | PASS |
| UTM | present | source=1 medium=1 campaign=1 | PASS |
| click IDs | present | fbclid=1 gclid=1 ttclid=1 li_fat_id=1 | PASS |
| API PROD | present | 87 | PASS |
| API DEV | absent | 0 | PASS |
| CompletePayment fake | absent | 0 | PASS |
| trial_page_viewed browser fake | absent | 0 | PASS |
| secret-like public markers | absent | private_key=0 bearer=0 internal_assignment=0 | PASS |

## Smoke passif

| check | resultat |
| --- | --- |
| curl HTML passif /register | rc=0 200 9274 |

Curl HTML passif uniquement, sans JS, sans formulaire, sans POST.

## Snapshot DB read-only final

```
funnel_events.register_started=182
funnel_events.trial_page_viewed=0
conversion_events.trial_page_viewed=0
conversion_events.StartTrial=2
conversion_events.Purchase=1
outbound_conversion_deliveries.trial_page_viewed=MISSING
outbound_conversion_deliveries.StartTrial=MISSING
outbound_conversion_deliveries.Purchase=MISSING
ai_usage.total=347
ai_actions_ledger.total=394
```

## Non-regression

| service | attendu | observe | verdict |
| --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod / sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod / ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev / sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev / ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| Website PROD | inchange |  | PASS |
| Admin PROD | inchange | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod | PASS |
| Backend PROD | inchange | ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod | PASS |

## No fake metrics / no fake events

| surface | resultat |
| --- | --- |
| docker build / docker push | 0 |
| kubectl apply | effectue precedemment sur le seul manifest Client PROD cible |
| kubectl set image/env/patch/edit | 0 |
| DB mutation | 0 |
| POST /funnel/event | 0 |
| formulaire /register | 0 |
| checkout Stripe | 0 |
| CAPI test endpoint | 0 |
| fake event | 0 |
| Linear | 0 |

## Gaps et limites

- READY_WITH_LIMITS: runtime PROD complet, mais Ads Manager / Meta real traffic non prouve sans vrai parcours utilisateur.
- L'event Antoine sera prouve en bout-en-bout seulement apres un vrai /register PROD qui produit register_started naturellement.

## Rollback

Rollback non execute.
Rollback GitOps documente si besoin: remettre ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod dans k8s/keybuzz-client-prod/deployment.yaml, commit, push, kubectl apply -f, rollout status.

## Verdict

GO APPLY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD GITOPS READY_WITH_LIMITS PH-SAAS-T8.12AS.21.100

## Prochain GO

GO READONLY VERIFY CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD PROD PH-SAAS-T8.12AS.21.101
