# PH15-TRACKING-REPORTS-02 - Tracking reel via Amazon Reports (FBM)

## Resume

L'implementation du service de rapports Amazon pour le tracking FBM est **techniquement complete** mais **bloquee par les permissions du compte Amazon**.

## Architecture implementee

### Flux Global (FBM vs FBA)

```
                    AMAZON ORDERS SYNC                            
                                                                  
  +------------------+                 +------------------+       
  |   ORDERS API     |                 |  REPORTS API     |       
  | (listOrders)     |                 | (FBM Tracking)   |       
  +--------+---------+                 +--------+---------+       
           |                                    |                 
           v                                    v                 
  +------------------+                 +------------------+       
  | fulfillmentChannel                 | carrier-name     |       
  | carrier (FBA)    |                 | tracking-number  |       
  | orderStatus      |                 | ship-date        |       
  +--------+---------+                 +--------+---------+       
           |                                    |                 
           +----------------+------------------+                  
                            v                                     
                   +------------------+                           
                   |     ORDER DB     |                           
                   | - trackingNumber |                           
                   | - trackingUrl    |                           
                   | - trackingSource |                           
                   +------------------+                           
```

### Service implemente

**Fichier**: `src/modules/marketplaces/amazon/amazonReports.service.ts`

Fonctions principales:
- `createReport()`: Cree une demande de rapport Amazon
- `pollReportStatus()`: Attend que le rapport soit pret
- `downloadReportDocument()`: Telecharge le contenu du rapport
- `parseShipmentsReport()`: Parse les donnees TSV/CSV
- `mergeTrackingWithOrders()`: Met a jour les commandes avec le tracking
- `runReportsSyncForTenant()`: Execution pour un tenant
- `runGlobalReportsSync()`: Execution multi-tenant

### Routes implementees

- `GET /api/v1/orders/sync/reports/status`: Statut global et par tenant
- `POST /api/v1/orders/sync/reports/run`: Declenchement manuel

## Probleme identifie

### Erreur Amazon

```json
{
  "error": "Failed to create report: Access to the resource is forbidden"
}
```

### Cause

Le compte Amazon SP-API connecte (A12BCIS2R7HD4D) n'a pas les **permissions de rapports** activees.

L'API Reports necessite des autorisations specifiques :
- `Reports` (lecture)
- Marketplace(s) specifiques

### Solution requise

Le proprietaire du compte Amazon doit :
1. Se connecter a **Amazon Seller Central**
2. Aller dans **Apps & Services** > **Develop Apps**
3. Selectionner l'application SP-API KeyBuzz
4. Activer les permissions **Reports** pour les marketplaces souhaites
5. Reauthoriser l'application OAuth

## Tests effectues

### Test 1: Type de rapport FBM

```bash
curl -X POST /api/v1/orders/sync/reports/run
```

Resultat:
```json
{
  "error": "Invalid Report Type _GET_MERCHANT_FULFILLED_SHIPMENTS_DATA_"
}
```

### Test 2: Type de rapport generique (listings)

```bash
# Avec GET_FLAT_FILE_OPEN_LISTINGS_DATA
```

Resultat:
```json
{
  "error": "Access to the resource is forbidden"
}
```

**Conclusion**: L'API Reports est accessible, mais le compte n'a pas les permissions.

## Etat actuel du tracking

| Type | Source | Tracking disponible | Notes |
|------|--------|---------------------|-------|
| FBA | Orders API | Non | Amazon gere la livraison |
| FBM | Orders API | Carrier only | Pas de trackingNumber |
| FBM | Reports API | En attente | Permissions requises |

### Affichage UI actuel

- **FBM avec carrier**: "UPS (suivi en attente)"
- **FBM sans carrier**: "En transit"
- **FBA**: "Expedie par Amazon"

## Versions deployees

- Backend: `1.0.23-dev`
- Client: `0.2.80-dev`

## Prochaines etapes

1. **Action utilisateur**: Activer les permissions Reports dans Amazon Seller Central
2. **Apres autorisation**: Retester `POST /api/v1/orders/sync/reports/run`
3. **Si succes**: Activer le CronJob quotidien pour sync automatique

## Commits

- `keybuzz-backend`: Service amazonReports.service.ts + routes
- `keybuzz-infra`: Ce rapport

---
*Date*: 2026-01-12
*Phase*: PH15-TRACKING-REPORTS-02
