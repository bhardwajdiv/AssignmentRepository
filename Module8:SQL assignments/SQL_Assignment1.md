# SQL Assignment 1

---

## 1. New Customers Acquired in June 2023

**Business Problem:**
The marketing team ran a campaign in June 2023 and wants to see how many new customers signed up during that period.

**Fields:** PARTY_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, ENTRY_DATE

```sql
SELECT
    p.PARTY_ID,
    p.FIRST_NAME,
    p.LAST_NAME,
    MAX(CASE WHEN cm.CONTACT_MECH_TYPE_ID = 'EMAIL_ADDRESS' THEN cm.INFO_STRING END) AS EMAIL,
    MAX(tn.CONTACT_NUMBER) AS PHONE,
    p.CREATED_STAMP AS ENTRY_DATE
FROM person p
JOIN party_role pr ON p.PARTY_ID = pr.PARTY_ID
    AND pr.ROLE_TYPE_ID = 'CUSTOMER'
LEFT JOIN party_contact_mech pcm ON p.PARTY_ID = pcm.PARTY_ID
LEFT JOIN contact_mech cm ON pcm.CONTACT_MECH_ID = cm.CONTACT_MECH_ID
LEFT JOIN telecom_number tn ON pcm.CONTACT_MECH_ID = tn.CONTACT_MECH_ID
WHERE p.CREATED_STAMP >= '2023-06-01'
  AND p.CREATED_STAMP < '2023-07-01'
GROUP BY p.PARTY_ID, p.FIRST_NAME, p.LAST_NAME, p.CREATED_STAMP;
```

---

## 2. List All Active Physical Products

**Business Problem:**
Merchandising teams often need a list of all physical products to manage logistics, warehousing, and shipping.

**Fields:** PRODUCT_ID, PRODUCT_TYPE_ID, INTERNAL_NAME

```sql
SELECT
    p.PRODUCT_ID,
    p.PRODUCT_TYPE_ID,
    p.INTERNAL_NAME
FROM product p
JOIN product_type pt ON p.PRODUCT_TYPE_ID = pt.PRODUCT_TYPE_ID
WHERE pt.IS_PHYSICAL = 'Y'
  AND (p.SALES_DISCONTINUATION_DATE IS NULL OR p.SALES_DISCONTINUATION_DATE > CURDATE());
```

---

## 3. Products Missing NetSuite ID

**Business Problem:**
A product cannot sync to NetSuite unless it has a valid NetSuite ID. The OMS needs a list of all products that still need to be created or updated in NetSuite.

**Fields:** PRODUCT_ID, INTERNAL_NAME, PRODUCT_TYPE_ID, NETSUITE_ID

```sql
SELECT
    p.PRODUCT_ID,
    p.PRODUCT_TYPE_ID,
    p.INTERNAL_NAME,
    gi.ID_VALUE AS NETSUITE_ID
FROM product p
LEFT JOIN good_identification gi ON p.PRODUCT_ID = gi.PRODUCT_ID
    AND gi.GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID'
WHERE gi.ID_VALUE IS NULL
   OR gi.ID_VALUE = '';
```

---

## 4. Product IDs Across Systems

**Business Problem:**
To sync an order or product across multiple systems (e.g., Shopify, HotWax, ERP/NetSuite), the OMS needs to know each system's unique identifier for that product.

**Fields:** PRODUCT_ID, SHOPIFY_ID, HOTWAX_ID, ERP_ID

```sql
SELECT
    p.PRODUCT_ID,
    MAX(CASE WHEN gi.GOOD_IDENTIFICATION_TYPE_ID = 'SHOPIFY_PROD_ID' THEN gi.ID_VALUE END) AS SHOPIFY_ID,
    p.PRODUCT_ID AS HOTWAX_ID,
    MAX(CASE WHEN gi.GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID' THEN gi.ID_VALUE END) AS ERP_ID
FROM product p
LEFT JOIN good_identification gi ON p.PRODUCT_ID = gi.PRODUCT_ID
GROUP BY p.PRODUCT_ID;
```

---

## 5. Completed Orders in August 2023

**Business Problem:**
After running similar reports for a previous month, you now need all completed orders in August 2023 for analysis.

**Fields:** PRODUCT_ID, PRODUCT_TYPE_ID, PRODUCT_STORE_ID, TOTAL_QUANTITY, INTERNAL_NAME, FACILITY_ID, EXTERNAL_ID, FACILITY_TYPE_ID, ORDER_HISTORY_ID, ORDER_ID, ORDER_ITEM_SEQ_ID, SHIP_GROUP_SEQ_ID

```sql
SELECT
    oi.PRODUCT_ID,
    p.PRODUCT_TYPE_ID,
    oh.PRODUCT_STORE_ID,
    oi.QUANTITY AS TOTAL_QUANTITY,
    p.INTERNAL_NAME,
    oisg.FACILITY_ID,
    oh.EXTERNAL_ID,
    f.FACILITY_TYPE_ID,
    os.ORDER_STATUS_ID AS ORDER_HISTORY_ID,
    oh.ORDER_ID,
    oi.ORDER_ITEM_SEQ_ID,
    oisg.SHIP_GROUP_SEQ_ID
FROM order_header oh
JOIN order_item oi ON oh.ORDER_ID = oi.ORDER_ID
JOIN order_item_ship_group oisg ON oi.ORDER_ID = oisg.ORDER_ID
    AND oi.SHIP_GROUP_SEQ_ID = oisg.SHIP_GROUP_SEQ_ID
JOIN product p ON oi.PRODUCT_ID = p.PRODUCT_ID
JOIN facility f ON oisg.FACILITY_ID = f.FACILITY_ID
JOIN order_status os ON oh.ORDER_ID = os.ORDER_ID
    AND os.STATUS_ID = 'ORDER_COMPLETED'
WHERE oh.ORDER_TYPE_ID = 'SALES_ORDER'
  AND os.STATUS_DATETIME >= '2023-08-01'
  AND os.STATUS_DATETIME < '2023-09-01';
```

---

## 7. Newly Created Sales Orders and Payment Methods

**Business Problem:**
Finance teams need to see new orders and their payment methods for reconciliation and fraud checks.

**Fields:** ORDER_ID, TOTAL_AMOUNT, PAYMENT_METHOD, SHOPIFY_ORDER_ID

```sql
SELECT
    oh.ORDER_ID,
    oh.GRAND_TOTAL AS TOTAL_AMOUNT,
    opp.PAYMENT_METHOD_TYPE_ID AS PAYMENT_METHOD,
    oh.EXTERNAL_ID AS SHOPIFY_ORDER_ID
FROM order_header oh
JOIN order_payment_preference opp ON oh.ORDER_ID = opp.ORDER_ID
WHERE oh.ORDER_TYPE_ID = 'SALES_ORDER'
  AND oh.ORDER_DATE >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY oh.ORDER_DATE DESC;
```

---

## 8. Payment Captured but Not Shipped

**Business Problem:**
Finance teams want to ensure revenue is recognized properly. If payment is captured but no shipment has occurred, it warrants further review.

**Fields:** ORDER_ID, ORDER_STATUS, PAYMENT_STATUS, SHIPMENT_STATUS

```sql
SELECT
    oh.ORDER_ID,
    oh.STATUS_ID AS ORDER_STATUS,
    opp.STATUS_ID AS PAYMENT_STATUS,
    COALESCE(sh.STATUS_ID, 'NOT_SHIPPED') AS SHIPMENT_STATUS
FROM order_header oh
JOIN order_payment_preference opp ON oh.ORDER_ID = opp.ORDER_ID
LEFT JOIN order_shipment os ON oh.ORDER_ID = os.ORDER_ID
LEFT JOIN shipment sh ON os.SHIPMENT_ID = sh.SHIPMENT_ID
WHERE opp.STATUS_ID = 'PAYMENT_SETTLED'
  AND (sh.STATUS_ID IS NULL
    OR sh.STATUS_ID != 'SHIPMENT_SHIPPED');
```

---

## 9. Orders Completed Hourly

**Business Problem:**
Operations teams may want to see how orders complete across the day to schedule staffing.

**Fields:** TOTAL_ORDERS, HOUR

```sql
SELECT
    COUNT(DISTINCT oh.ORDER_ID) AS TOTAL_ORDERS,
    HOUR(os.STATUS_DATETIME) AS HOUR
FROM order_header oh
JOIN order_status os ON oh.ORDER_ID = os.ORDER_ID
WHERE oh.STATUS_ID = 'ORDER_COMPLETED'
  AND os.STATUS_ID = 'ORDER_COMPLETED'
  AND DATE(os.STATUS_DATETIME) = CURDATE()
GROUP BY HOUR(os.STATUS_DATETIME)
ORDER BY HOUR ASC;
```

---

## 10. BOPIS Orders Revenue (Last Year)

**Business Problem:**
BOPIS (Buy Online, Pickup In Store) is a key retail strategy. Finance wants to know the revenue from BOPIS orders for the previous year.

**Fields:** TOTAL_ORDERS, TOTAL_REVENUE

```sql
SELECT
    COUNT(DISTINCT oh.ORDER_ID) AS TOTAL_ORDERS,
    SUM(oi.UNIT_PRICE * oi.QUANTITY) AS TOTAL_REVENUE
FROM order_header oh
JOIN order_item oi ON oh.ORDER_ID = oi.ORDER_ID
JOIN order_item_ship_group oisg ON oh.ORDER_ID = oisg.ORDER_ID
    AND oisg.SHIPMENT_METHOD_TYPE_ID = 'STOREPICKUP'
WHERE oh.STATUS_ID = 'ORDER_COMPLETED'
  AND YEAR(oh.ORDER_DATE) = YEAR(CURDATE()) - 1;
```

---

## 11. Canceled Orders (Last Month)

**Business Problem:**
The merchandising team needs to know how many orders were canceled in the previous month and their reasons.

**Fields:** TOTAL_ORDERS, CANCELLATION_REASON

```sql
SELECT
    COUNT(DISTINCT oh.ORDER_ID) AS TOTAL_ORDERS,
    os.CHANGE_REASON AS CANCELLATION_REASON
FROM order_header oh
JOIN order_status os ON oh.ORDER_ID = os.ORDER_ID
WHERE oh.STATUS_ID = 'ORDER_CANCELLED'
  AND os.STATUS_ID = 'ORDER_CANCELLED'
  AND MONTH(os.STATUS_DATETIME) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
  AND YEAR(os.STATUS_DATETIME) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
GROUP BY os.CHANGE_REASON
ORDER BY TOTAL_ORDERS DESC;
```

---

## 12. Product Threshold Value

**Business Problem:**
The retailer has set a threshold value for products that are sold online, in order to avoid overselling.

**Fields:** PRODUCT_ID, THRESHOLD

```sql
SELECT
    PRODUCT_ID,
    MINIMUM_STOCK AS THRESHOLD
FROM product_facility
WHERE MINIMUM_STOCK IS NOT NULL
ORDER BY PRODUCT_ID;
```
