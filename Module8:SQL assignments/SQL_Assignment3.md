# SQL Assignment 3

---

## 1. Completed Sales Orders (Physical Items)

**Business Problem:**
Merchants need to track only physical items requiring shipping and fulfillment for logistics and shipping-cost analysis.

**Fields:** ORDER_ID, ORDER_ITEM_SEQ_ID, PRODUCT_ID, PRODUCT_TYPE_ID, SALES_CHANNEL_ENUM_ID, ORDER_DATE, ENTRY_DATE, STATUS_ID, STATUS_DATETIME, ORDER_TYPE_ID, PRODUCT_STORE_ID

```sql
SELECT
    oh.ORDER_ID,
    oi.ORDER_ITEM_SEQ_ID,
    oi.PRODUCT_ID,
    p.PRODUCT_TYPE_ID,
    oh.SALES_CHANNEL_ENUM_ID,
    oh.ORDER_DATE,
    oh.ENTRY_DATE,
    oh.STATUS_ID,
    os.STATUS_DATETIME,
    oh.ORDER_TYPE_ID,
    oh.PRODUCT_STORE_ID
FROM order_header oh
JOIN order_item oi ON oi.ORDER_ID = oh.ORDER_ID
JOIN product p ON p.PRODUCT_ID = oi.PRODUCT_ID
JOIN product_type pt ON pt.PRODUCT_TYPE_ID = p.PRODUCT_TYPE_ID
JOIN order_status os ON os.ORDER_ID = oh.ORDER_ID
    AND os.STATUS_ID = 'ORDER_COMPLETED'
WHERE oh.ORDER_TYPE_ID = 'SALES_ORDER'
  AND oh.STATUS_ID = 'ORDER_COMPLETED'
  AND pt.IS_PHYSICAL = 'Y';
```

---

## 2. Completed Return Items

**Business Problem:**
Customer service and finance teams need insights into returned items to manage refunds, replacements, and inventory restocking.

**Fields:** RETURN_ID, ORDER_ID, PRODUCT_STORE_ID, STATUS_DATETIME, ORDER_NAME, FROM_PARTY_ID, RETURN_DATE, ENTRY_DATE, RETURN_CHANNEL_ENUM_ID

```sql
SELECT
    rh.RETURN_ID,
    ri.ORDER_ID,
    oh.PRODUCT_STORE_ID,
    rs.STATUS_DATETIME,
    oh.ORDER_NAME,
    rh.FROM_PARTY_ID,
    rh.RETURN_DATE,
    rh.ENTRY_DATE,
    rh.RETURN_CHANNEL_ENUM_ID
FROM return_header rh
JOIN return_item ri ON ri.RETURN_ID = rh.RETURN_ID
JOIN order_header oh ON oh.ORDER_ID = ri.ORDER_ID
LEFT JOIN return_status rs ON rs.RETURN_ID = rh.RETURN_ID
    AND rs.STATUS_ID = 'RETURN_COMPLETED'
WHERE rh.STATUS_ID = 'RETURN_COMPLETED';
```

---

## 3. Single-Return Orders (Last Month)

**Business Problem:**
The merchandising team needs a list of customers whose orders had exactly one return during the previous month.

**Fields:** PARTY_ID, FIRST_NAME

```sql
SELECT DISTINCT
    p.PARTY_ID,
    p.FIRST_NAME
FROM person p
JOIN order_role orl ON p.PARTY_ID = orl.PARTY_ID
JOIN (
    SELECT ri.ORDER_ID
    FROM return_item ri
    JOIN return_header rh ON rh.RETURN_ID = ri.RETURN_ID
    WHERE rh.RETURN_DATE >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01')
      AND rh.RETURN_DATE < DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY ri.ORDER_ID
    HAVING COUNT(DISTINCT ri.RETURN_ID) = 1
) r ON r.ORDER_ID = orl.ORDER_ID
WHERE orl.ROLE_TYPE_ID = 'PLACING_CUSTOMER';
```

---

## 4. Returns and Appeasements

**Business Problem:**
The retailer needs total return volume and total appeasements issued.

**Fields:** TOTAL_RETURNS, RETURN_DOLLAR_TOTAL, TOTAL_APPEASEMENTS, APPEASEMENTS_DOLLAR_TOTAL

```sql
SELECT
    (SELECT SUM(RETURN_QUANTITY)
     FROM return_item) AS TOTAL_RETURNS,

    (SELECT SUM(RETURN_QUANTITY * RETURN_PRICE)
     FROM return_item) AS RETURN_DOLLAR_TOTAL,

    (SELECT COUNT(*)
     FROM return_adjustment
     WHERE RETURN_ADJUSTMENT_TYPE_ID = 'APPEASEMENT') AS TOTAL_APPEASEMENTS,

    (SELECT SUM(AMOUNT)
     FROM return_adjustment
     WHERE RETURN_ADJUSTMENT_TYPE_ID = 'APPEASEMENT') AS APPEASEMENTS_DOLLAR_TOTAL;
```

---

## 5. Detailed Return Information

**Business Problem:**
Operations and finance teams require detailed return information for return analysis and refund tracking.

**Fields:** RETURN_ID, ENTRY_DATE, RETURN_ADJUSTMENT_TYPE_ID, AMOUNT, COMMENTS, ORDER_ID, ORDER_DATE, RETURN_DATE, PRODUCT_STORE_ID

```sql
SELECT
    rh.RETURN_ID,
    rh.ENTRY_DATE,
    ra.RETURN_ADJUSTMENT_TYPE_ID,
    ra.AMOUNT,
    ra.COMMENTS,
    ri.ORDER_ID,
    oh.ORDER_DATE,
    rh.RETURN_DATE,
    oh.PRODUCT_STORE_ID
FROM return_header rh
JOIN return_item ri ON ri.RETURN_ID = rh.RETURN_ID
JOIN order_header oh ON oh.ORDER_ID = ri.ORDER_ID
LEFT JOIN return_adjustment ra ON ra.RETURN_ID = rh.RETURN_ID;
```

---

## 6. Orders with Multiple Returns

**Business Problem:**
Orders with multiple returns may indicate fraud, product quality issues, or fulfillment problems.

**Fields:** ORDER_ID, RETURN_ID, RETURN_DATE, RETURN_REASON, RETURN_QUANTITY

```sql
SELECT
    ri.ORDER_ID,
    rh.RETURN_ID,
    rh.RETURN_DATE,
    ri.RETURN_REASON_ID AS RETURN_REASON,
    ri.RETURN_QUANTITY
FROM return_header rh
JOIN return_item ri ON rh.RETURN_ID = ri.RETURN_ID
WHERE ri.ORDER_ID IN (
    SELECT ORDER_ID
    FROM return_item
    GROUP BY ORDER_ID
    HAVING COUNT(DISTINCT RETURN_ID) > 1
)
ORDER BY ri.ORDER_ID;
```

---

## 7. Store with Most One-Day Shipped Orders (Last Month)

**Business Problem:**
Identify facilities handling the highest volume of one-day shipped orders for operational benchmarking.

**Fields:** FACILITY_ID, FACILITY_NAME, TOTAL_ONE_DAY_SHIP_ORDERS, REPORTING_PERIOD

```sql
SELECT
    s.ORIGIN_FACILITY_ID AS FACILITY_ID,
    f.FACILITY_NAME,
    COUNT(DISTINCT s.PRIMARY_ORDER_ID) AS TOTAL_ONE_DAY_SHIP_ORDERS,
    CONCAT(
        DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01'),
        ' to ',
        LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
    ) AS REPORTING_PERIOD
FROM shipment s
JOIN facility f ON f.FACILITY_ID = s.ORIGIN_FACILITY_ID
WHERE TIMESTAMPDIFF(DAY, s.ESTIMATED_SHIP_DATE, s.ESTIMATED_DELIVERY_DATE) <= 1
  AND MONTH(s.ESTIMATED_SHIP_DATE) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
  AND YEAR(s.ESTIMATED_SHIP_DATE) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
GROUP BY s.ORIGIN_FACILITY_ID, f.FACILITY_NAME
ORDER BY TOTAL_ONE_DAY_SHIP_ORDERS DESC
LIMIT 1;
```

---

## 8. List of Warehouse Pickers

**Business Problem:**
Warehouse managers need employee assignments for picking and packing operations.

**Fields:** PARTY_ID, NAME, ROLE_TYPE_ID, FACILITY_ID, STATUS

```sql
SELECT
    pr.PARTY_ID,
    CONCAT(p.FIRST_NAME, ' ', p.LAST_NAME) AS NAME,
    pr.ROLE_TYPE_ID,
    fp.FACILITY_ID,
    ps.STATUS_ID AS STATUS
FROM party_role pr
JOIN person p ON p.PARTY_ID = pr.PARTY_ID
LEFT JOIN facility_party fp ON fp.PARTY_ID = pr.PARTY_ID
LEFT JOIN party_status ps ON ps.PARTY_ID = pr.PARTY_ID
WHERE pr.ROLE_TYPE_ID = 'WAREHOUSE_PICKER';
```

---

## 9. Total Facilities That Sell the Product

**Business Problem:**
Identify how many facilities sell each product and where those products are available.

**Fields:** PRODUCT_ID, PRODUCT_NAME, FACILITY_COUNT, FACILITY_LIST

```sql
SELECT
    pf.PRODUCT_ID,
    p.INTERNAL_NAME AS PRODUCT_NAME,
    COUNT(DISTINCT pf.FACILITY_ID) AS FACILITY_COUNT,
    GROUP_CONCAT(DISTINCT pf.FACILITY_ID) AS FACILITY_LIST
FROM product_facility pf
JOIN product p ON p.PRODUCT_ID = pf.PRODUCT_ID
GROUP BY pf.PRODUCT_ID, p.INTERNAL_NAME;
```

---

## 10. Total Items in Various Facilities

**Business Problem:**
Analyze inventory levels across non-virtual facilities and facility types.

**Fields:** PRODUCT_ID, FACILITY_ID, FACILITY_TYPE_ID, QOH, ATP

```sql
SELECT
    ii.PRODUCT_ID,
    ii.FACILITY_ID,
    f.FACILITY_TYPE_ID,
    ii.QUANTITY_ON_HAND_TOTAL AS QOH,
    ii.AVAILABLE_TO_PROMISE_TOTAL AS ATP
FROM inventory_item ii
JOIN facility f ON f.FACILITY_ID = ii.FACILITY_ID
WHERE f.FACILITY_TYPE_ID != 'VIRTUAL_FACILITY';
```

---

## 11. Transfer Orders Without Inventory Reservation

**Business Problem:**
Identify transfer orders that do not have reserved inventory to prevent fulfillment failures.

**Fields:** TRANSFER_ORDER_ID, FROM_FACILITY_ID, TO_FACILITY_ID, PRODUCT_ID, REQUESTED_QUANTITY, RESERVED_QUANTITY, TRANSFER_DATE, STATUS

```sql
SELECT
    oh.ORDER_ID AS TRANSFER_ORDER_ID,
    s.ORIGIN_FACILITY_ID AS FROM_FACILITY_ID,
    s.DESTINATION_FACILITY_ID AS TO_FACILITY_ID,
    oi.PRODUCT_ID,
    oi.QUANTITY AS REQUESTED_QUANTITY,
    COALESCE(SUM(oisgir.QUANTITY), 0) AS RESERVED_QUANTITY,
    s.ESTIMATED_SHIP_DATE AS TRANSFER_DATE,
    oh.STATUS_ID AS STATUS
FROM order_header oh
JOIN order_item oi ON oi.ORDER_ID = oh.ORDER_ID
JOIN shipment s ON s.PRIMARY_ORDER_ID = oh.ORDER_ID
LEFT JOIN order_item_ship_grp_inv_res oisgir ON oisgir.ORDER_ID = oi.ORDER_ID
    AND oisgir.ORDER_ITEM_SEQ_ID = oi.ORDER_ITEM_SEQ_ID
WHERE oh.ORDER_TYPE_ID = 'TRANSFER'
GROUP BY oh.ORDER_ID, s.ORIGIN_FACILITY_ID, s.DESTINATION_FACILITY_ID,
         oi.PRODUCT_ID, oi.QUANTITY, s.ESTIMATED_SHIP_DATE, oh.STATUS_ID
HAVING RESERVED_QUANTITY = 0;
```

---

## 12. Orders Without Picklist

**Business Problem:**
Orders missing picklists may experience fulfillment delays and require operational attention.

**Fields:** ORDER_ID, ORDER_DATE, ORDER_STATUS, FACILITY_ID, DURATION_DAYS

```sql
SELECT DISTINCT
    oh.ORDER_ID,
    oh.ORDER_DATE,
    oh.STATUS_ID AS ORDER_STATUS,
    oisg.FACILITY_ID,
    TIMESTAMPDIFF(DAY, oh.ORDER_DATE, CURRENT_TIMESTAMP) AS DURATION_DAYS
FROM order_header oh
JOIN order_item_ship_group oisg ON oisg.ORDER_ID = oh.ORDER_ID
LEFT JOIN picklist_item pli ON pli.ORDER_ID = oh.ORDER_ID
WHERE pli.ORDER_ID IS NULL
  AND oh.STATUS_ID NOT IN ('ORDER_COMPLETED', 'ORDER_CANCELLED')
ORDER BY DURATION_DAYS DESC;
```
