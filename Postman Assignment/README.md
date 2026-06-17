# Postman Fulfillment Lifecycle Assignment

## Overview
This Postman collection automates the complete Pick → Pack → Ship fulfillment lifecycle of an order item without using the application UI.

## Files
- `Fulfillment Lifecycle.postman_collection.json` — Postman collection with all API requests
- `Fulfillment Environment.postman_environment.json` — Environment file with all configurable variables

## Flow

```
Find Open Orders → Pick Order → Pack Order → Ship Order
                                    ↑               |
                                    |___ (loop) ____|
```

### Requests

1. **Find Open Orders** — Queries Solr to fetch all approved, unfulfilled orders for a facility. Extracts order groups and stores them in environment variables.

2. **Pick Order** — Creates a fulfillment wave (`createOrderFulfillmentWave`) for the current order group. Returns `picklistId` and `shipmentId`.

3. **Pack Order** — Packs the shipment using the `shipmentId` from the previous step.

4. **Ship Order** — Marks the shipment as shipped. Loops back to Pick Order if more orders remain, otherwise stops.

## Environment Variables

| Variable | Description |
|---|---|
| `baseSolrUrl` | Solr endpoint for order search |
| `basePoortiUrl` | Poorti API base URL |
| `facilityId` | Warehouse/facility identifier |
| `productStoreId` | Product store identifier |
| `pickerPartyId` | Party ID of the warehouse picker |
| `shipmentGroups` | Auto-populated — order groups from Solr |
| `groupIndex` | Auto-populated — current loop index |
| `orderId` | Auto-populated — current order ID |
| `shipmentId` | Auto-populated — shipment ID from Pick step |
| `packedShipmentId` | Auto-populated — packed shipment ID |

## How to Run

1. Import both files into Postman
2. Select `Fulfillment Environment` as the active environment
3. Fill in `baseSolrUrl`, `basePoortiUrl`, `facilityId`, `productStoreId`, `pickerPartyId`
4. Run the collection using **Collection Runner** in sequence

## GitHub Repository
https://github.com/bhardwajdiv/AssignmentRepository/tree/main/Postman%20Assignment
