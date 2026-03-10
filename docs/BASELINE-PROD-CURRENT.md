# BASELINE-PROD-CURRENT — État PROD actuel

**Relevé** : 2026-02-19T10:59Z

## Deployments PROD

| Namespace | Deploy | Image | Digest | Créé |
|-----------|--------|-------|--------|------|
| keybuzz-client-prod | keybuzz-client | `v3.4.2-ph351-octopia-import-prod` | `sha256:c6d2b083d1f94f3fd4a5f57b9f2162ec6267509ed9f2e82047c7f33a8808e944` | 2026-02-18T20:25:41Z |
| keybuzz-api-prod | keybuzz-api | `v3.4.4-ph353-octopia-readonly-prod-2` | `sha256:12bc6169e4e617d81492d549c9b78c0f7a9d75da51ccf18136c91c7c85939dd1` | 2026-02-19T00:02:24Z |
| keybuzz-api-prod | keybuzz-outbound-worker | `v3.4.4-ph353-octopia-readonly-prod-2` | `sha256:12bc6169e4e617d81492d549c9b78c0f7a9d75da51ccf18136c91c7c85939dd1` | 2026-02-19T00:02:24Z |
| keybuzz-backend-prod | keybuzz-backend | `v3.1.3-ph342-inbound-prod-2` | `sha256:6ba037f2893c3c123cfe3b7b73878f23e9373150b41cc97c6bc149105e827b8d` | 2026-02-17T23:33:44Z |
| keybuzz-backend-prod | amazon-items-worker | `v1.0.34-ph263` | — | — |
| keybuzz-backend-prod | amazon-orders-worker | `v1.0.34-ph263` | — | — |

## Contenu PH actuel en PROD

| Phase | Composant concerné | Contenu |
|-------|-------------------|---------|
| PH35.1 | API + Client | Octopia import discussions (10 init), BFF routes |
| PH35.3 | API + Worker | Octopia backfill 232 convs + sync worker 10min + advisory lock (PH35.3B) |
| PH34.2 | Backend | Inbound email provisioning |
| PH34.3 | API | Sender policy + daily budget fix |
| PH33KB | API + Client | KBActions access v2 |

## Observation

L'API PROD `v3.4.4-ph353-octopia-readonly-prod-2` inclut le contenu PH35.3B (advisory lock), déployé le 2026-02-19 00:01.
