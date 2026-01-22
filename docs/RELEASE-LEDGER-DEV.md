
## 2026-01-22 - v0.5.9-order-badge-detail (PH24.2C)
- Client: keybuzz-client:v0.5.9-order-badge-detail
- Changements:
  - Helper partage resolveOrderId() cree
  - Clic sur badge/bouton resout orderId via API
  - Navigation vers /orders/{orderId} si trouve, sinon /orders?q=...
- Rapport: PH24.2C-INBOX-ORDER-BADGE-OPEN-DETAIL-01-REPORT.md
## 2026-01-22 - v1.0.29-backfill-365d (PH15.2)
- Backend: keybuzz-backend:v1.0.29-backfill-365d
- Changements:
  - Migration DB: colonnes initialBackfillDays/DoneAt/Status dans MarketplaceSyncState
  - Index: Order_tenantId_externalOrderId_idx, Order_tenantId_orderDate_desc_idx
  - Nouveau service amazonOrdersBackfill.service.ts
  - Sync global detecte automatiquement besoin backfill 365j
  - Routes: GET /api/v1/orders/sync/backfill/status, POST /api/v1/orders/sync/backfill/run
- Rapport: PH15.2-AMAZON-ORDERS-BACKFILL-365D-01-REPORT.md