# SQL Assignment 2

---

## 5.1 Shipping Addresses for October 2023 Orders

**Business Problem:**
Customer Service might need to verify addresses for orders placed in October 2023. This helps ensure shipments are delivered correctly and prevents address-related issues.

**Fields:** ORDER_ID, PARTY_ID, CUSTOMER_NAME, STREET_ADDRESS, CITY, STATE_PROVINCE, POSTAL_CODE, COUNTRY_CODE, ORDER_STATUS, ORDER_DATE

```sql
SELECT
    oh.ORDER_ID,
    orl.PARTY_ID,
    CONCAT(p.FIRST_NAME, ' ', p.LAST_NAME) AS CUSTOMER_NAME,
    pa.ADDRESS1 AS STREET_ADDRESS,
    pa.CITY,
    pa.STATE_PROVINCE_GEO_ID AS STATE_PROVINCE,
    pa.POSTAL_CODE,
    pa.COUNTRY_GEO_ID AS COUNTRY_CODE,
    oh.STATUS_ID AS ORDER_STATUS,
    oh.ORDER_DATE
FROM order_header oh
JOIN order_role orl ON oh.ORDER_ID = orl.ORDER_ID
    AND orl.ROLE_TYPE_ID = 'PLACING_CUSTOMER'
JOIN person p ON orl.PARTY_ID = p.PARTY_ID
JOIN order_contact_mech ocm ON oh.ORDER_ID = ocm.ORDER_ID
    AND ocm.CONTACT_MECH_PURPOSE_TYPE_ID = 'SHIPPING_LOCATION'
JOIN postal_address pa ON ocm.CONTACT_MECH_ID = pa.CONTACT_MECH_ID
WHERE oh.ORDER_DATE >= '2023-10-01'
  AND oh.ORDER_DATE < '2023-11-01';
```

---

## 5.2 Orders From New York

**Business Problem:**
Companies often want region-specific analysis to plan local marketing, staffing, or promotions in certain areas — here, specifically, New York.

**Fields:** ORDER_ID, CUSTOMER_NAME, STREET_ADDRESS, CITY, STATE_PROVINCE, POSTAL_CODE, TOTAL_AMOUNT, ORDER_DATE, ORDER_STATUS

```sql
SELECT
    oh.ORDER_ID,
    CONCAT(p.FIRST_NAME, ' ', p.LAST_NAME) AS CUSTOMER_NAME,
    pa.ADDRESS1 AS STREET_ADDRESS,
    pa.CITY,
    pa.STATE_PROVINCE_GEO_ID AS STATE_PROVINCE,
    pa.POSTAL_CODE,
    oh.GRAND_TOTAL AS TOTAL_AMOUNT,
    oh.ORDER_DATE,
    oh.STATUS_ID AS ORDER_STATUS
FROM order_header oh
JOIN order_role orl ON oh.ORDER_ID = orl.ORDER_ID
    AND orl.ROLE_TYPE_ID = 'PLACING_CUSTOMER'
JOIN person p ON orl.PARTY_ID = p.PARTY_ID
JOIN order_contact_mech ocm ON oh.ORDER_ID = ocm.ORDER_ID
    AND ocm.CONTACT_MECH_PURPOSE_TYPE_ID = 'SHIPPING_LOCATION'
JOIN postal_address pa ON ocm.CONTACT_MECH_ID = pa.CONTACT_MECH_ID
WHERE pa.STATE_PROVINCE_GEO_ID = 'NY';
```

---

## 5.3 Top-Selling Product in New York

**Business Problem:**
Merchandising teams need to identify the best-selling product(s) in a specific region (New York) for targeted restocking or promotions.

**Fields:** PRODUCT_ID, INTERNAL_NAME, TOTAL_QUANTITY_SOLD, REVENUE

```sql
SELECT
    oi.PRODUCT_ID,
    p.INTERNAL_NAME,
    SUM(oi.QUANTITY) AS TOTAL_QUANTITY_SOLD,
    SUM(oi.QUANTITY * oi.UNIT_PRICE) AS REVENUE
FROM order_header oh
JOIN order_contact_mech ocm ON oh.ORDER_ID = ocm.ORDER_ID
    AND ocm.CONTACT_MECH_PURPOSE_TYPE_ID = 'SHIPPING_LOCATION'
JOIN postal_address pa ON ocm.CONTACT_MECH_ID = pa.CONTACT_MECH_ID
JOIN order_item oi ON oh.ORDER_ID = oi.ORDER_ID
JOIN product p ON oi.PRODUCT_ID = p.PRODUCT_ID
WHERE pa.STATE_PROVINCE_GEO_ID = 'NY'
  AND oh.STATUS_ID NOT IN ('ORDER_CANCELLED', 'ORDER_REJECTED')
GROUP BY oi.PRODUCT_ID, p.INTERNAL_NAME
ORDER BY TOTAL_QUANTITY_SOLD DESC;
```

---

## 7.3 Store-Specific (Facility-Wise) Revenue

**Business Problem:**
Different physical or online stores (facilities) may have varying levels of performance. The business wants to compare revenue across facilities for sales planning and budgeting.

**Fields:** FACILITY_ID, FACILITY_NAME, TOTAL_ORDERS, TOTAL_REVENUE, DATE_RANGE

```sql
SELECT
    f.FACILITY_ID,
    f.FACILITY_NAME,
    COUNT(DISTINCT oh.ORDER_ID) AS TOTAL_ORDERS,
    SUM(oi.QUANTITY * oi.UNIT_PRICE) AS TOTAL_REVENUE,
    CONCAT(
        MIN(DATE(oh.ORDER_DATE)),
        ' to ',
        MAX(DATE(oh.ORDER_DATE))
    ) AS DATE_RANGE
FROM order_item oi
JOIN order_item_ship_group oisg ON oi.ORDER_ID = oisg.ORDER_ID
    AND oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID
JOIN facility f ON oisg.FACILITY_ID = f.FACILITY_ID
JOIN order_header oh ON oi.ORDER_ID = oh.ORDER_ID
WHERE oh.STATUS_ID = 'ORDER_COMPLETED'
GROUP BY f.FACILITY_ID, f.FACILITY_NAME
ORDER BY TOTAL_REVENUE DESC;
```

---

## 8.1 Lost and Damaged Inventory

**Business Problem:**
Warehouse managers need to track shrinkage such as lost, damaged, or stolen inventory to reconcile physical versus system counts.

**Fields:** INVENTORY_ITEM_ID, PRODUCT_ID, FACILITY_ID, QUANTITY_LOST_OR_DAMAGED, REASON_CODE, TRANSACTION_DATE

```sql
SELECT
    ii.INVENTORY_ITEM_ID,
    ii.PRODUCT_ID,
    ii.FACILITY_ID,
    ABS(iid.QUANTITY_ON_HAND_DIFF) AS QUANTITY_LOST_OR_DAMAGED,
    iid.REASON_ENUM_ID AS REASON_CODE,
    iid.EFFECTIVE_DATE AS TRANSACTION_DATE
FROM inventory_item_detail iid
JOIN inventory_item ii ON iid.INVENTORY_ITEM_ID = ii.INVENTORY_ITEM_ID
WHERE iid.REASON_ENUM_ID IN (
    'VAR_LOST',
    'VAR_DAMAGED',
    'VAR_STOLEN',
    'REJ_RSN_DAMAGED',
    'WORN_DISPLAY'
);
```

---

## 8.2 Low Stock or Out of Stock Items Report

**Business Problem:**
Avoiding out-of-stock situations is critical. This report flags items that have fallen below a reorder threshold or have zero available stock.

**Fields:** PRODUCT_ID, PRODUCT_NAME, FACILITY_ID, QOH, ATP, REORDER_THRESHOLD, DATE_CHECKED

```sql
SELECT
    ii.PRODUCT_ID,
    p.INTERNAL_NAME AS PRODUCT_NAME,
    ii.FACILITY_ID,
    ii.QUANTITY_ON_HAND AS QOH,
    ii.AVAILABLE_TO_PROMISE AS ATP,
    pf.MINIMUM_STOCK AS REORDER_THRESHOLD,
    NOW() AS DATE_CHECKED
FROM inventory_item ii
JOIN product p ON ii.PRODUCT_ID = p.PRODUCT_ID
LEFT JOIN product_facility pf ON ii.PRODUCT_ID = pf.PRODUCT_ID
    AND ii.FACILITY_ID = pf.FACILITY_ID
WHERE ii.QUANTITY_ON_HAND = 0
   OR (pf.MINIMUM_STOCK IS NOT NULL AND ii.QUANTITY_ON_HAND <= pf.MINIMUM_STOCK);
```

---

## 8.3 Retrieve the Current Facility of Open Orders

**Business Problem:**
The business wants to know where open orders are currently assigned, whether in a physical store or a virtual fulfillment location.

**Fields:** ORDER_ID, ORDER_STATUS, FACILITY_ID, FACILITY_NAME, FACILITY_TYPE_ID

```sql
SELECT DISTINCT
    oh.ORDER_ID,
    oh.STATUS_ID AS ORDER_STATUS,
    f.FACILITY_ID,
    f.FACILITY_NAME,
    f.FACILITY_TYPE_ID
FROM order_header oh
JOIN order_item oi ON oh.ORDER_ID = oi.ORDER_ID
JOIN order_item_ship_group oisg ON oi.ORDER_ID = oisg.ORDER_ID
    AND oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID
JOIN facility f ON oisg.FACILITY_ID = f.FACILITY_ID
WHERE oh.STATUS_ID IN ('ORDER_CREATED', 'ORDER_APPROVED');
```

---

## 8.4 Items Where QOH and ATP Differ

**Business Problem:**
Sometimes Quantity on Hand (QOH) doesn't match Available to Promise (ATP) due to reservations, pending orders, or inventory discrepancies.

**Fields:** PRODUCT_ID, FACILITY_ID, QOH, ATP, DIFFERENCE

```sql
SELECT
    PRODUCT_ID,
    FACILITY_ID,
    QUANTITY_ON_HAND AS QOH,
    AVAILABLE_TO_PROMISE AS ATP,
    (QUANTITY_ON_HAND - AVAILABLE_TO_PROMISE) AS DIFFERENCE
FROM inventory_item
WHERE QUANTITY_ON_HAND <> AVAILABLE_TO_PROMISE;
```

---

## 8.5 Order Item Current Status Changed Date-Time

**Business Problem:**
Operations teams need to audit when an order item's status was last changed for tracking and dispute resolution.

**Fields:** ORDER_ID, ORDER_ITEM_SEQ_ID, CURRENT_STATUS_ID, STATUS_CHANGE_DATETIME, CHANGED_BY

```sql
SELECT
    os.ORDER_ID,
    os.ORDER_ITEM_SEQ_ID,
    os.STATUS_ID AS CURRENT_STATUS_ID,
    os.STATUS_DATETIME AS STATUS_CHANGE_DATETIME,
    os.STATUS_USER_LOGIN AS CHANGED_BY
FROM order_status os
JOIN (
    SELECT
        ORDER_ID,
        ORDER_ITEM_SEQ_ID,
        MAX(STATUS_DATETIME) AS MAX_STATUS_TIME
    FROM order_status
    WHERE ORDER_ITEM_SEQ_ID IS NOT NULL
    GROUP BY ORDER_ID, ORDER_ITEM_SEQ_ID
) latest ON os.ORDER_ID = latest.ORDER_ID
    AND os.ORDER_ITEM_SEQ_ID = latest.ORDER_ITEM_SEQ_ID
    AND os.STATUS_DATETIME = latest.MAX_STATUS_TIME;
```

---

## 8.6 Total Orders by Sales Channel

**Business Problem:**
Marketing and sales teams want to see how many orders come from each sales channel and the revenue generated by each channel.

**Fields:** SALES_CHANNEL, TOTAL_ORDERS, TOTAL_REVENUE, REPORTING_PERIOD

```sql
SELECT
    SALES_CHANNEL_ENUM_ID AS SALES_CHANNEL,
    COUNT(*) AS TOTAL_ORDERS,
    SUM(GRAND_TOTAL) AS TOTAL_REVENUE,
    CONCAT(
        MIN(DATE(ORDER_DATE)),
        ' to ',
        MAX(DATE(ORDER_DATE))
    ) AS REPORTING_PERIOD
FROM order_header
GROUP BY SALES_CHANNEL_ENUM_ID
ORDER BY TOTAL_REVENUE DESC;
```
