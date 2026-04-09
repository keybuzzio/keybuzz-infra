# KeyBuzz Studio — Architecture

> Last update: 2026-04-02
> Phase: PH-STUDIO-01

---

## Overview

KeyBuzz Studio is a Marketing Operating System designed to centralize content creation, scheduling, knowledge management, and marketing automation for the KeyBuzz ecosystem.

## Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | Next.js (App Router) | 16.0.2 |
| UI Kit | Metronic Tailwind React | 9.3.7 |
| Styling | Tailwind CSS | 4.1 |
| Language | TypeScript | 5.9 |
| Backend | Fastify | 5.x |
| Database | PostgreSQL | 17 |
| Container | Docker (Node 20 Alpine) | — |
| Orchestration | Kubernetes + ArgoCD | — |
| Registry | ghcr.io/keybuzzio | — |

## Repository Structure

```
keybuzz-studio/                 # Frontend (Next.js + Metronic)
  app/
    (studio)/                   # All Studio pages (route group)
      dashboard/
      ideas/
      content/
      calendar/
      assets/
      knowledge/
      automations/
      reports/
      settings/
  components/
    layouts/studio/             # App shell (sidebar, header, footer)
    ui/                         # Metronic UI component library
  config/                       # Menu config, types
  hooks/                        # React hooks (from Metronic)
  lib/                          # Utility functions
  services/                     # API client
  styles/                       # CSS (Tailwind + Metronic theme)
  types/                        # Domain type definitions

keybuzz-studio-api/             # Backend (Fastify)
  src/
    index.ts                    # Server entrypoint
    config/                     # Env validation, DB pool
    common/                     # Auth middleware, error handlers, logger
    modules/
      health/                   # GET /health, GET /ready
      auth/                     # Auth skeleton
      content/                  # Content CRUD
      automation/               # Automation runs
      knowledge/                # Knowledge documents
      reporting/                # Reports
    routes/                     # Route registration
    db/                         # Schema SQL + migration runner

keybuzz-infra/
  k8s/keybuzz-studio-dev/       # K8s manifests for Studio frontend DEV
  k8s/keybuzz-studio-api-dev/   # K8s manifests for Studio API DEV
  docs/                         # Documentation (this file, reports, etc.)
```

## Deployment

### DNS Plan
| Environment | Frontend | API |
|-------------|----------|-----|
| DEV | studio-dev.keybuzz.io | studio-api-dev.keybuzz.io |
| PROD | studio.keybuzz.io | studio-api.keybuzz.io |

### Ports
| Service | Container Port | Service Port |
|---------|---------------|-------------|
| Studio Frontend | 3000 | 80 |
| Studio API | 4010 | 80 |

### Image Tags
```
ghcr.io/keybuzzio/keybuzz-studio:v1.0.0-foundation-dev
ghcr.io/keybuzzio/keybuzz-studio-api:v1.0.0-foundation-dev
```

## Database

- **Database name**: keybuzz_studio
- **12 tables**: workspaces, users, memberships, content_items, content_versions, content_assets, content_calendars, publication_targets, knowledge_documents, automation_runs, activity_logs, master_reports
- **Schema**: keybuzz-studio-api/src/db/schema.sql
- **Extensions**: uuid-ossp, pgcrypto
- **Triggers**: auto-update updated_at on mutable tables

## Separation from Other Products

Studio shares NOTHING with:
- keybuzz-client (client.keybuzz.io)
- keybuzz-seller (seller.keybuzz.io)
- keybuzz-admin
- keybuzz-api (the existing order/inbox API)
- keybuzz-backend

Future integrations will use:
- REST API calls between services
- Shared database views (read-only)
- Event-driven messaging (n8n webhooks)
- Explicit connector modules in keybuzz-studio-api
