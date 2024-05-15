--queries
--Orders management:
--Orders management: problem #0 What med transactioned through past 30 days ordered desc
SELECT "purchased_id" , COUNT(*) AS "num_products" FROM "transactions"
WHERE "date_time" > DATETIME('now', '-30 days') GROUP BY "purchased_id"
ORDER BY "num_products" DESC;

-- Orders management: problem #1 which medication makes the most revenue last 30 days?
    -- approach #1 the most profitable = transactioned the most
SELECT * FROM "pharmacy_products" WHERE "id" IN(
    SELECT "purchased_id" FROM "transactions"
    WHERE "date_time" > datetime('now', '-30 days')
    GROUP BY "purchased_id"
    ORDER BY COUNT("purchased_id") DESC
    LIMIT 10
);
    -- approach #2 the most profitable = the most revenue , as revenue determined by both (price and percentage)
SELECT * FROM "pharmacy_products" WHERE "id" IN(
    SELECT "product_id" FROM "orders"
    WHERE "date_time" > datetime('now', '-30 days')
    ORDER BY ("public_cost" * "discount_percentage") DESC
    LIMIT 10
);
    -- approach #3 combine both to get real insights(most revenue + most transactioned)
WITH "most_transactioned" AS (
    SELECT "purchased_id", COUNT("purchased_id") AS "most_purshased" FROM "transactions"
    WHERE "date_time" > datetime('now', '-30 days')
)
SELECT "product_id" , ("public_cost" * "discount_percentage") AS "rev" , COUNT("transaction_id") FROM "orders"
RIGHT JOIN "pharmacy_products" AS P ON "orders"."product_id" = P."id"
LEFT JOIN "most_transactioned" ON "orders"."product_id" = "most_transactioned"."purchased_id"
ORDER BY ("most_purshased" * "rev") DESC
LIMIT 100;

-- Orders management: problem #2 which medication seems to be decaining from th market?
-- drug declain in egyptian drug market take the pattern of decrese in the discount percentage
--better to excuted in python

    -- Step 0 : Create a view of the upcoming deficiencies
CREATE VIEW "upcoming_defecancies" AS(
    SELECT "product_id", "date_time", "discount_percentage" FROM "orders"
    WHERE "date_time" > datetime('now', '-60 days')
    ORDER BY "product_id" , "date_time"
);
    -- Step 1: Create a view to calculate the trend of discount percentage over time
CREATE VIEW "discount_trend" AS(
    SELECT
       "product_id",
        AVG("discount_percentage") AS avg_discount_percentage,
        COUNT(*) AS num_orders,
        MIN("date_time") BETWEEN DATETIME('now', '-30 days')  AND DATETIME('now') AS start_date,
        MAX("date_time") AS end_date
    FROM upcoming_defecancies
    GROUP BY product_id
);
    -- Step 2: Calculate the slope of the discount percentage trend using linear regression
/* We'll use the formula: slope = (n * Σ(xy) - Σx * Σy) / (n * Σ(x^2) - (Σx)^2)
 Where:
- n is the number of data points (num_orders)
- Σxy is the sum of (date_time - start_date) * discount_percentage
- Σx is the sum of (date_time - start_date)
- Σy is the sum of discount_percentage
- Σ(x^2) is the sum of (date_time - start_date)^2 */
SELECT
    product_id,
    ( COUNT(*) * SUM((julianday("date_time") - julianday(start_date)) * discount_percentage) - SUM(julianday("date_time")
    - julianday(start_date)) * SUM(discount_percentage) ) /
    ( COUNT(*) * SUM((julianday("date_time") - julianday(start_date)) * (julianday("date_time") - julianday(start_date)))
     - SUM(julianday("date_time") - julianday(start_date)) * SUM(julianday("date_time") - julianday(start_date)) )
    AS "slope"
FROM "discount_trend"
GROUP BY product_id;

-- Orders management: problem #3 which products are Stagnant(did rarly transactioned in the last 6 monthes),
-- get them sorted by SELLED amount ?
SELECT* FROM "pharmacy_products"
WHERE "amount_available" > 1 AND "id" IN(
    SELECT "purchased_id" FROM "transactions"
    WHERE "date_time" > datetime('now', '-180 days')
    GROUP BY "purchased_id"
    ORDER BY COUNT("purchased_id") ASC
    LIMIT 100
);

-- Orders management: problem #4
--(has a seasonal trend), like telfast, ticanase in winter
              -- Step 1: Analyze weekly trends
CREATE VIEW "weekly_trends" AS (
    WITH "weekly_trends" AS(
        SELECT  "purchased_id","date_time", strftime('%Y-%W', "date_time") AS "year_week", strftime('%Y', date_time) AS "year",
                 strftime('%W', date_time) AS "week_number", SUM("end_quantity") AS "weekly_quantity_sold",
            CASE
                WHEN SUM(quantity) > LAG(SUM(quantity), 1, 0) OVER (PARTITION BY purchased_id, strftime('%Y-%W', date_time) ORDER BY strftime('%Y-%W', date_time)) THEN 'Upward'
                WHEN SUM(quantity) < LAG(SUM(quantity), 1, 0) OVER (PARTITION BY purchased_id, strftime('%Y-%W', date_time) ORDER BY strftime('%Y-%W', date_time)) THEN 'Downward'
                ELSE 'Flat'
            END AS "week_trend",
            SUM("end_quantity") - LAG(SUM("end_quantity"),1,0) OVER (PARTITION BY  "purchased_id", strftime('%Y-%W',"date_time") ORDER BY strftime('%Y-%W', date_time)) AS "back_comparison"
        FROM "transactions"
        GROUP BY "purchased_id", "week_number", "year";
    )        -- Step 2: Visualize and interpret
        SELECT "name", " supplier", "amount_available", strftime('%M',"date_time") AS "month",
               "monthly_quantity_sold",
               "purchased_id", "year", "week_number", "weekly_quantity_sold", "week_trend",
               CASE
                   WHEN "week_number" BETWEEN 1 AND 3 THEN 1
                   WHEN "week_number" BETWEEN 4 AND 6 THEN 2
                   WHEN "week_number" BETWEEN 7 AND 9 THEN 3
                   ELSE 4
                END
                AS "quarter_trend"
        FROM "weekly_trends"
        LEFT JOIN "pharmacy_products" AS P ON "weekly_trends"."purchased_id" = P."id"
        GROUP BY "purchased_id", "week_number", "year";
    )
);

-- Orders management: take us a step forward! SHOW the trends for a quarter (example : second one)
-- for the fixed consumed products, important to buy a sufecient (but suitable) quantity, this helps us to get better offers.
SELECT* FROM "weekly_trends" WHERE "quarter_trend" = 2;

-- Orders management: problem #5 make my order forcast 5 days needs
    -- approch #1
SELECT "id", "name", "barcode", "supplier", "amount_available",("amount_available"-"limit_to_order") + 1 AS "amount_to_order" ,"limit_to_order"
FROM "pharmacy_products" WHERE "amount_available" < "limit_to_order" AND "id" IN
    (SELECT "purchased_id" FROM "transactions" WHERE "date_time" > DATETIME('now', '-30 days'))
ORDER BY "amount_available" /"limit_to_order" ASC;

    --approach #2 Forecasted num.transactions = w1​ × Q1​ + w2​ × Q2​ + w3​ × Q3
    -- used exponential weights to cope the sudden changes in market.

WITH "transaction_distriburtion" AS(
    SELECT "purchased_id",
           COUNT("purchased_id") WHERE "date_time" BETWEEN datetime('now') AND datetime('now', '-5 days') AS "one",
           COUNT("purchased_id") WHERE "date_time" BETWEEN datetime('-10 days') AND datetime('-5 days', '-10 days') AS "two",
           COUNT("purchased_id") WHERE "date_time" BETWEEN datetime('-20 days') AND datetime('-10 days', '-15 days') AS "three",
           COUNT("purchased_id") WHERE "date_time" BETWEEN datetime('-20 days') AND datetime('-15 days', '-20 days') AS "four",
           COUNT("purchased_id") WHERE "date_time" BETWEEN datetime('-20 days') AND datetime('-20 days', '-25 days') AS "five",
           COUNT("purchased_id") WHERE "date_time" BETWEEN datetime('-20 days') AND datetime('-25 days', '-30 days') AS "six"

    FROM "transactions"
    WHERE "date_time" BETWEEN datetime('now') AND datetime('-30 days')
)
SELECT "purchased_id" ,  "one"*0.5​ + "two"​*0.25​ + "three"* 0.125 + "four"*0.0625 + "five"*0.03125 + "six"*0.015625 AS "forcasted_sales",
       "available_quantity", "available_quantity" - "forcasted_sales" AS "quantity_to_order", "supplier", "barcode"
FROM "transaction_distriburtion"
LEFT JOIN "pharmacy_products" AS P ON "transaction_distriburtion"."purchased_id"= P."id";

    --approach #3 Forecasted quantity = w1​ × Q1​ + w2​ × Q2​ + w3​ × Q3
    -- used exponential weights to cope the sudden changes in market.

WITH "dispensed_amount_distriburtion" AS(
    SELECT "purchased_id",
           COUNT("end_quantity") GROUP BY "purchased_id"
           WHERE "date_time" BETWEEN datetime('now') AND datetime('now', '-5 days') AS "one",
           COUNT("end_quantity") GROUP BY "purchased_id"
           WHERE "date_time" BETWEEN datetime('-10 days') AND datetime('-5 days', '-10 days') AS "two",
           COUNT("end_quantity") GROUP BY "purchased_id"
           WHERE "date_time" BETWEEN datetime('-20 days') AND datetime('-10 days', '-15 days') AS "three",
           COUNT("end_quantity") GROUP BY "purchased_id"
           WHERE "date_time" BETWEEN datetime('-20 days') AND datetime('-15 days', '-20 days') AS "four",
           COUNT("end_quantity") GROUP BY "purchased_id"
           WHERE "date_time" BETWEEN datetime('-20 days') AND datetime('-20 days', '-25 days') AS "five",
           COUNT("end_quantity") GROUP BY "purchased_id"
           WHERE "date_time" BETWEEN datetime('-20 days') AND datetime('-25 days', '-30 days') AS "six"

    FROM "transactions"
    WHERE "date_time" BETWEEN datetime('now') AND datetime('-30 days')
)
SELECT "purchased_id" ,  ("one"*0.5​ + "two"​*0.25​ + "three"* 0.125 + "four"*0.0625 + "five"*0.03125 + "six"*0.015625) AS "forcasted_sales",
       "available_quantity", ("available_quantity" - "forcasted_sales") AS "quantity_to_order", "supplier", "barcode"
FROM "dispensed_amount_distriburtion"
LEFT JOIN "pharmacy_products" AS P ON "transaction_distriburtion"."purchased_id"= P."id";

-- Orders management: problem #5 Which distribution company we could stop dealing with -- need un achievable data

-- Orders management: problem #6 Which medications in last 30 days related to a doctor and have low quantity
-- To order it. IMPORTANT to order in limited amounts to avoid loss in case doctor decided to shift to other brand.

SELECT "purchased_id", "doctor_id", SUM("quantity"), "price", "doc_name", "clinic_name",
       "name", "amount_available"- "limit_to_order" AS "order_amount"FROM "transactions" AS T
WHERE "doctor_id" IS NOT NULL AND "date_time" BETWEEN datetime('now') AND datetime('-30 days')
GROUP BY "doctor_id","purchased_id"
ORDER BY "amount_available" ASC

LEFT JOIN "doctors" AS D ON T."doctor_id" = D."doctor_id"
LEFT JOIN "pharmacy_products" AS P ON T."purchased_id" = P."id";

------------------------------------------------------------------------------------------------------------------------------------------

-- Inventory Management: Tell me capital cycle()

WITH --Problem (a)get sales at cost price in the month

"month_transactions" AS(
    SELECT "purchased_id", "end_quantity" , "price", "pharm_price"
    FROM "transactions" T
    LEFT JOIN "orders" O ON T."purchased_id" = O."product_id"
    WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME ('now', '-30 days')
    GROUP BY "purchased_id"
),
"ID_sold" AS (
    SELECT "purchased_id", SUM("end_quantity")*"pharm_price" AS "total_month_sales", "name"
    FROM "month_transactions"
    LEFT JOIN "pharmacy_products" P ON "month_transactions"."purchased_id" = P."id"
    GROUP BY "purchased_id";
),  --Problem (b)get inventory at cost price at the month end
"inventory_at_cost_price_end" AS (
    SELECT SUM ("orders"."pharm_price" * "amount_available") AS "endInventory_cost"
    FROM "pharmacy_products" AS P
    JOIN "orders" AS O ON P."id" = O."product_id"
),  --Problem (c)total orders to be subtracted
 "total_orders to_be_subtracted" AS (
    SELECT SUM ("pharm_price" * "quantity") AS "orders_cost"
    FROM "orders"
),
"month_sales" AS(
    SELECT SUM (quantity) AS "total_quantity", purchased_id
    FROM "transactions" AS T
    GROUP BY "purchased_id"
),  --Problem (d)total transactioned to be added
"total_transactioned_to_be_added" AS (
    SELECT "month_sales"."total_quantity"* "pharm_price" AS "cost_of_month_sales", purchased_id
    FROM "month_sales"
    LEFT JOIN "orders" AS O ON "month_sales"."purchased_id" = O."product_id"
),  -- Problem (e)get inventory at cost price at the month start
"inventory_at_start_of_month" AS(
    "inventory_at_cost_price_end"."endInventory_cost" - "total_orders to_be_subtracted"."orders_cost" +"total_transactioned_to_be_added"."cost_of_month_sales" AS "startInventory_cost"
)     --Problem (g) Capital cycle ---> better to become between 1/3 and 1/4
SELECT "ID_sold"."total_month_sales" /"avg_inventory_cost" AS "capital_cycle",
       "ID_sold"."total_month_sales",
       "inventory_at_cost_price_end"."endInventory_cost",
       "month_sales"."total_quantity",
       "total_transactioned_to_be_added"."cost_of_month_sales",
       "inventory_at_start_of_month"."startInventory_cost",
     --Problem (f) average inventory cost of a month
       "avg_inventory_cost" as ("inventory_at_start_of_month"."startInventory_cost" +"inventory_at_cost_price_end"."endInventory_cost") /2

FROM "ID_sold", "inventory_at_cost_price_end",
       "month_sales", "total_transactioned_to_be_added", "inventory_at_start_of_month";

------------------------------------------------------------------------------------------------------------------------------------------

--Revenue Management: calculate my revenue for the last month

WITH
"sales_at_puplic_price_in_the_month" AS(
    SELECT SUM("total_cost") AS "total_month_sales_puplic"
    FROM "cashair" WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME ('now', '-30 days')
),
"month_transactions" AS(
    SELECT "purchased_id", "end_quantity" , "price", "pharm_price"
    FROM "transactions" T
    LEFT JOIN "orders" O ON T."purchased_id" = O."product_id"
    WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME ('now', '-30 days')
    GROUP BY "purchased_id"
),
"ID_sold" AS (
    SELECT "purchased_id", SUM("end_quantity")*"pharm_price" AS "total_id_sold", "name"
    FROM "month_transactions"
    LEFT JOIN "pharmacy_products" P ON "month_transactions"."purchased_id" = P."id"
    GROUP BY "purchased_id";
)
SELECT "sum_total_sold_id" AS (SELECT SUM("total_id_sold") FROM "ID_sold"),"sales_at_puplic_price_in_the_month"."total_month_sales_puplic" - "sum_total_sold_id"
FROM "sales_at_puplic_price_in_the_month" ;

--Revenue Management: calculate my revenue for this quarter

WITH
"sales_at_puplic_price_in_the_month" AS(
    SELECT SUM("total_cost") AS "total_month_sales_puplic"
    FROM "cashair" WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME ('now', '-120 days')
),
"month_transactions" AS(
    SELECT "purchased_id", "end_quantity" , "price", "pharm_price"
    FROM "transactions" T
    LEFT JOIN "orders" O ON T."purchased_id" = O."product_id"
    WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME ('now', '-120 days')
    GROUP BY "purchased_id"
),
"ID_sold" AS (
    SELECT "purchased_id", SUM("end_quantity")*"pharm_price" AS "total_id_sold", "name"
    FROM "month_transactions"
    LEFT JOIN "pharmacy_products" P ON "month_transactions"."purchased_id" = P."id"
    GROUP BY "purchased_id";
)
SELECT "sales_at_puplic_price_in_the_month"."total_month_sales_puplic" - "ID_sold".SUM("total_id_sold")
FROM "sales_at_puplic_price_in_the_month", "ID_sold";

------------------------------------------------------------------------------------------------------------------------------------------

--Sales Management
--Problem #0 what is the week sales:
SELECT SUM("total_cost") FROM "cashair" GROUP BY "customer_type"
WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME('now', '-7 days');

--Problem #1 what is the month sales:
SELECT SUM("total_cost") FROM "cashair" GROUP BY "customer_type"
WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME('now', '-30 days');

--Problem #2 what is the year sales:
SELECT SUM("total_cost") FROM "cashair" GROUP BY "customer_type"
WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME('now', '-3565 days');

--Problem #3 What is the average sales for each month of the year, sort by most sales average to least
WITH "total_sales_in_"AS (
    SELECT
        SUM("total_cost") OVER (PARTITION BY strftime('%M-%Y',"date_time"))AS "total_sales_in_month" ,strftime('%M',"date_time")AS "month",
        strftime('%Y', "date_time")
    FROM "cashair"
)
SELECT AVG("total_sales_in_month") OVER(PARTITION BY "month"), "average_sales_in_month", "month"
FROM "total_sales_in_"
ORDER BY "average_sales_in_month";

--Problem #4 What is the average sales for each day of the week, sort by most sales average to least
WITH "total_sales_in_"AS (
    SELECT
        SUM("total_cost") OVER (PARTITION BY strftime('%M-%Y',"date_time"))AS "total_sales_in_month" ,strftime('%M',"date_time")AS "month",
        strftime('%w', "date_time") AS "week_day"
    FROM "cashair"
)
SELECT AVG("total_sales_in_month") OVER(PARTITION BY "week_day"), "average_sales_in_week_day", "week_day"
FROM "total_sales_in_"
ORDER BY "average_sales_in_week_day";

--Problem #5 what is total cash come by each pharmacist, sort
SELECT SUM("total_cost")OVER (PARTITION BY "pharmacist_id") AS "pharmacist_month_sales", "date_time","name", "pharmacist_id"
FROM "cashair"
LEFT JOIN "pharmacists" ON "cashair"."pharmacist_id" = "pharmacists"."pharmacist_id"
WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME('now', '-30 days');
ORDER BY "pharmacist_month_sales" DESC;

--Problem #6 what is total NUMBER OF TRANSACTIONS done by each pharmacist, sort
SELECT SUM(DISTINCT("transaction_id"))OVER (PARTITION BY "pharmacist_id") AS "pharmacist_month_transactions_num", "date_time","name", "pharmacist_id"
FROM "cashair"
LEFT JOIN "pharmacists" ON "cashair"."pharmacist_id" = "pharmacists"."pharmacist_id"
WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME('now', '-30 days');
ORDER BY "pharmacist_month_transactions_num" DESC;

--Problem #7 what is total NUMBER OF TRANSACTIONS of each product category, sort
SELECT SUM(DISTINCT("transaction_id","purchased_id"))OVER (PARTITION BY "type") AS "category_month_transactions_num", "date_time","type"
FROM "transactions"
LEFT JOIN "pharmacy_products" ON "transactions"."purchased_id" = "pharmacy_products"."id"
WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME('now', '-30 days');
ORDER BY "category_month_transactions_num" DESC;

--Problem #8 what is the percentage of each pharmacist from total sales of last month, sort
SELECT SUM("total_cost")OVER (PARTITION BY "pharmacist_id") / SUM("total_cost") AS "pharmacist_month_sales%", "date_time","name", "pharmacist_id"
FROM "cashair"
LEFT JOIN "pharmacists" ON "cashair"."pharmacist_id" = "pharmacists"."pharmacist_id"
WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME('now', '-30 days');
ORDER BY "pharmacist_month_sales%" DESC;

------------------------------------------------------------------------------------------------------------------------------------------

--Customer Management
--Problem #0 Update customer activity
WITH"inactive_customers" AS(
    SELECT "customer_id", "name", "telephone1" FROM "customers" WHERE "id" NOT IN
        ( SELECT DISTINCT("customer_id") FROM "transaction" WHERE "date_time" BETWEEN DATETIME('now') AND DATETIME('now','-90 days') )
    WHERE "date_time" > datetime('now', '-60 days')
    ORDER BY "product_id" , "date_time"
)
UPDATE "customers"
SET "activity" = 0
WHERE "customer_id" IN "inactive_customers"."customer_id";


--Problem #RCR (Repeat Customer Rate): What is the PERCENTAGE of customers come to pharmacy periodically
    ---- create view of each month total sales and num of transactions for each customer
CREATE VIEW "rcr" AS(
    SELECT
        "name", "customer_id", "customer_type", strftime('%M-%Y',"date_time") AS "month_year", SUM("total_cost") AS "total_purchased_per_month",
        SUM(DISTINCT("transaction_id")) AS "num_transactions_per_month",
    ---- create trend based on num of transactions
        CASE
            WHEN "num_transactions_per_month" < LAG("num_transactions_per_month") OVER (PARTITION BY "customer_id","month_year") * 0.7
            THEN 'risk',
            WHEN "num_transactions_per_month" > LAG("num_transactions_per_month") OVER (PARTITION BY "customer_id","month_year") * 1.2
            THEN 'up',
            ELSE 'subtle'
        END
        AS "status_on_transactions_num",
    ---- create trend based on vol of sales
        CASE
            WHEN "total_purchased_per_month" < LAG("total_purchased_per_month") OVER (PARTITION BY "customer_id","month_year") * 0.7
            THEN 'risk',
            WHEN "total_purchased_per_month" > LAG("total_purchased_per_month") OVER (PARTITION BY "customer_id","month_year") * 1.2
            THEN 'up',
            ELSE 'subtle'
        END
        AS "status_on_total_purshed"
    FROM "cashair"
    RIGHT JOIN "customers" AS C ON "cashair"."customer_id" = C."customer_id"
    WHERE "cashair"."date_time" BETWEEN DATETIME('now') AND DATETIME('now', '-365 days') AND C."activity" = 1
    GROUP BY "customer_id", "month"
);
    ---- what is total number of customers
DECLARE "customers_total_num" INT;
SELECT COUNT(*) INTO "customers_total_num" FROM "customers"
----------------------------------- BASED ON NUM OF TRANSACTION ----------------------------------
    ----The at risk of lossing loyality customers
    --SHOW
SELECT "name", "customer_id" AS  "risk", "customer_type", "total_purchased_per_month" FROM "rcr" WHERE "status_on_transactions_num" = 'risk';
    --percentage%
SELECT (COUNT("customer_id") FROM "rcr"/ "customers_total_num") as "customers_risk_percentage" WHERE "status_on_transactions_num" = 'risk' ;

    ----the up saled customers
    --SHOW
SELECT "name", "customer_id" AS "up", "customer_type", "total_purchased_per_month" FROM "rcr" WHERE "status_on_transactions_num" = 'up';
    --percentage%
SELECT (COUNT("customer_id") / "customers_total_num")as "customers_risk_percentage"  FROM "rcr" WHERE "status_on_transactions_num" = 'up' ;

    ---- The SUBTLE customers
    -- SHOW
SELECT "name", "customer_id" AS "subtle", "customer_type", "total_purchased_per_month" FROM "rcr" WHERE "status_on_transactions_num" = 'subtle';
    --percentage%
SELECT (COUNT("customer_id")    / "customers_total_num" )as "customers_risk_percentage" FROM "rcr" WHERE "status_on_transactions_num" = 'subtle';

----------------------------------- BASED ON VOL OF SALES  --------------------------------------
   ----The at risk of lossing loyality customers
    --SHOW
SELECT "name", "customer_id" AS  "risk", "customer_type", "status_on_total_purshed" FROM "rcr" WHERE "status_on_total_purshed" = 'risk';
    --percentage%
SELECT (COUNT("customer_id") / "customers_total_num") as "customers_risk_percentage" FROM "rcr" WHERE "status_on_total_purshed" = 'risk' ;

    ----the up saled customers
    --SHOW
SELECT "name", "customer_id" AS "up", "customer_type", "total_purchased_per_month" FROM "rcr" WHERE "status_on_total_purshed" = 'up';
    --percentage%
SELECT( COUNT("customer_id") FROM "rcr" / "customers_total_num") as "customers_risk_percentage"WHERE "status_on_total_purshed" = 'up' ;

    ---- The SUBTLE customers
    -- SHOW
SELECT "name", "customer_id" AS "subtle", "customer_type", "total_purchased_per_month" FROM "rcr" WHERE "status_on_total_purshed" = 'subtle';
    --percentage%
SELECT (COUNT("customer_id") FROM "rcr" / "customers_total_num" )as "customers_risk_percentage" WHERE "status_on_total_purshed" = 'subtle' ;


--Problem #RR (retention rate) what is the percentage of customers stayed with me this month
SELECT (COUNT(*) / "customers_total_num") AS "retention_ratio" , 1- "retention_ratio" AS "loss_ration"
FROM "rcr"
WHERE "rcr"."date_time" = strftime('%M-%Y',DATETIME('now')) AND
      "status_on_total_purshed" IN('up', 'subtle') OR "status_on_transactions_num" IN('up', 'subtle');

--Problem #New_customers? look at the pecentage of new customers in the last 45 days
SELECT COUNT(*) , (COUNT(*) / "customers_total_num")  AS "new_in_last_45"
FROM "customers"
WHERE "entery_date" BETWEEN DATETIME('now') AND DATETIME('now','-45 days');


--Problem #Follow up, follw the new customers in the previous 45 days
WITH
"previous" AS (
    SELECT*, COUNT(*) AS "previous_total" , (COUNT(*) / "customers_total_num" )AS "percentage_to_total"
    FROM "customers"
    WHERE "entery_date" BETWEEN DATETIME('-45 days') AND DATETIME('-90 days')
),
"previous_up_transactions"AS (SELECT COUNT(*) AS "previous_up_transactions" FROM "rcr" WHERE "customer_id" IN (SELECT "customer_id" FROM "previous") AND "status_on_transactions_num" = 'up' ),
"previous_risk_transactions"AS (SELECT COUNT(*) AS "previous_risk_transactions" FROM "rcr" WHERE "customer_id" IN (SELECT "customer_id" FROM "previous") AND "status_on_transactions_num" = 'risk' ),
"previous_suble_transactions"AS (SELECT COUNT(*) AS "previous_suble_transactions"FROM "rcr" WHERE "customer_id" IN (SELECT "customer_id" FROM "previous") AND "status_on_transactions_num" = 'subtle' ),
"previous_up_sales"AS (SELECT COUNT(*) AS "previous_up_sales" FROM "rcr" WHERE "customer_id" IN (SELECT "customer_id" FROM "previous") AND "status_on_total_purshed" = 'up' ),
"previous_down_sales"AS (SELECT COUNT(*) AS "previous_down_sales" FROM "rcr" WHERE "customer_id" IN (SELECT "customer_id" FROM "previous") AND "status_on_total_purshed" = 'down' ),
"previous_subtle_sales"AS (SELECT COUNT(*) AS "previous_subtle_sales" FROM "rcr" WHERE "customer_id" IN (SELECT "customer_id" FROM "previous") AND "status_on_total_purshed" = 'subtle' )

SELECT
    "previous_up_transactions"."previous_up_transactions" AS "previous_up_transactions",
    "previous_risk_transactions"."previous_risk_transactions"AS "previous_risk_transactions",
    "previous_suble_transactions"."previous_suble_transactions" AS "previous_suble_transactions",
    "previous_up_sales"."previous_up_sales" AS "previous_up_sales",
    "previous_down_sales"."previous_down_sales" AS "previous_down_sales",
    "previous_subtle_sales"."previous_subtle_sales" AS "previous_subtle_sales"
;



/*
To gauge patient loyalty in a pharmacy setting, you can track various metrics that reflect their engagement, satisfaction,
 and retention. Here are some key metrics you could use:
1. **Repeat Customer Rate:** This metric measures the percentage of customers who make repeat visits to your pharmacy within a specific
period, such as monthly or annually.
2. **Retention Rate:** The retention rate indicates the percentage of customers who continue to use your pharmacy over time.
It compares the number of retained customers to the total number of customers within a specified period.
3. **Referral Rate:** Measure the number of new customers acquired through referrals from existing customers.
 A high referral rate suggests satisfied and loyal customers who are willing to recommend your pharmacy to others.
4. **Purchase Frequency:** Track how often individual customers make purchases at your pharmacy.
Higher purchase frequency may indicate loyalty and satisfaction with your services.
5. **Average Order Value (AOV):** AOV measures the average amount spent by customers in each transaction.
Increasing AOV over time may indicate growing loyalty or the effectiveness of upselling and cross-selling strategies.
6. **Customer Feedback:** Gather feedback from customers through surveys, reviews, or direct interactions.
Positive feedback and high satisfaction scores often correlate with customer loyalty.
7. **Customer Lifetime Value (CLV):** CLV estimates the total revenue a customer is expected to generate over their
 entire relationship with your pharmacy. Higher CLV indicates more loyal and valuable customers.
8. **Net Promoter Score (NPS):** NPS measures customer satisfaction and loyalty by asking customers how likely they
are to recommend your pharmacy to others. It provides a simple indicator of overall customer loyalty.
9. **Participation in Loyalty Programs:** Track the number of customers enrolled in loyalty programs and their
 level of engagement with program benefits. Active participation indicates loyalty and interest in your pharmacy's offerings.
10. **Customer Churn Rate:** Churn rate measures the percentage of customers who stop using your pharmacy's services
 within a given period. A low churn rate suggests higher customer loyalty and retention.
By analyzing these metrics regularly, you can gain insights into your pharmacy's customer loyalty levels, identify areas for improvement,
 and implement strategies to enhance customer satisfaction and retention.
*/


------------------------------------------------------------------------------------------------------------------------------------------
--TRYING SOME INSERTIONS
INSERT INTO pharmacy_products (name, type, barcode, price, limit_to_order, amount_available, sale, active_ingrediants, supplier, storage_degree, schedule, deleted, expire)
VALUES
('Aspirin 100mg Tablets', 'medicine', '1234567890123', 10.99, 50, 1000, 0, 'Acetylsalicylic acid', 'Pharma Inc.', 25, 'non', 0, '2030-12-31'),
('Paracetamol 500mg Tablets', 'medicine', '2345678901234', 5.99, 100, 500, 0, 'Paracetamol', 'Generic Pharma', 25, 'non', 0, '2025-06-30'),
('Ibuprofen 200mg Tablets', 'medicine', '3456789012345', 7.99, 80, 800, 0, 'Ibuprofen', 'MediCorp', 25, 'non', 0, '2023-10-15'),
('Cetirizine 10mg Tablets', 'medicine', '4567890123456', 9.49, 60, 600, 0, 'Cetirizine', 'PharmaCare', 25, 'non', 0, '2024-08-20'),
('Amoxicillin 500mg Capsules', 'medicine', '5678901234567', 12.99, 40, 400, 0, 'Amoxicillin', 'DrugCo', 25, 'non', 0, '2023-12-31'),
('Simvastatin 20mg Tablets', 'medicine', '6789012345678', 15.49, 30, 300, 0, 'Simvastatin', 'Pharma Solutions', 25, 'non', 0, '2025-04-28'),
('Omeprazole 20mg Capsules', 'medicine', '7890123456789', 8.99, 70, 700, 0, 'Omeprazole', 'MediLink', 25, 'non', 0, '2024-11-10'),
('Loratadine 10mg Tablets', 'medicine', '8901234567890', 6.49, 90, 900, 0, 'Loratadine', 'PharmaNet', 25, 'non', 0, '2026-02-15'),
('Albuterol Inhaler', 'medicine', '9012345678901', 24.99, 20, 200, 0, 'Albuterol', 'BreatheEasy', 25, 'non', 0, '2022-09-05'),
('Hydrocortisone Cream 1%', 'medicine', '0123456789012', 14.99, 50, 500, 0, 'Hydrocortisone', 'SkinCare Inc.', 25, 'non', 0, '2023-07-22');

INSERT INTO customers (customer_id, name, activity, address, telephone1, telephone2, email, category, entry_date, points, loyalty, customer_type)
VALUES
(1.1, 'John Doe', 1, '123 Main Street', '0123456789', NULL, 'john@example.com', 1, DATETIME('now'), 0, 0, 2),
(1.2, 'Alice Smith', 1, '456 Elm Street', '9876543210', NULL, 'alice@example.com', 1, DATETIME('now'), 0, 0, 2),
(1.3, 'Bob Johnson', 1, '789 Oak Street', '5556667777', NULL, 'bob@example.com', 1, DATETIME('now'), 0, 0, 1),
(1.4, 'Emily Wilson', 1, '321 Pine Avenue', '1234567890', NULL, 'emily@example.com', 1, DATETIME('now'), 0, 0, 2),
(1.5, 'Michael Brown', 1, '654 Cedar Road', '2345678901', NULL, 'michael@example.com', 1, DATETIME('now'), 0, 0, 1),
(1.6, 'Sophia Martinez', 1, '987 Birch Lane', '3456789012', NULL, 'sophia@example.com', 1, DATETIME('now'), 0, 0, 2),
(1.7, 'William Taylor', 1, '741 Elm Street', '4567890123', NULL, 'william@example.com', 1, DATETIME('now'), 0, 0, 1),
(1.8, 'Olivia Anderson', 1, '852 Oak Avenue', '5678901234', NULL, 'olivia@example.com', 1, DATETIME('now'), 0, 0, 2),
(1.9, 'Ethan Thomas', 1, '963 Maple Drive', '6789012345', NULL, 'ethan@example.com', 1, DATETIME('now'), 0, 0, 2),
(1.10, 'Ava Hernandez', 1, '159 Cedar Road', '7890123456', NULL, 'ava@example.com', 1, DATETIME('now'), 0, 0, 1

INSERT INTO pharmacists (pharmacist_id, name, degree, payment_rate, previous_violations_num, last_assessment_score, last_assessment_date, employment_date, achievements, total_score)
VALUES
(1, 'John Smith', 'FIRST', 20, 0, 90, DATETIME('now'), DATETIME('now'), 'Employee of the Month', 95),
(2, 'Emily Johnson', 'FIRST', 20, 0, 85, DATETIME('now'), DATETIME('now'), 'Exceeded Sales Targets', 92),
(3, 'Michael Brown', 'SECOND', 18, 1, 80, DATETIME('now'), DATETIME('now'), 'Best Customer Service', 88),
(4, 'Sophia Martinez', 'SECOND', 18, 2, 75, DATETIME('now'), DATETIME('now'), 'Outstanding Teamwork', 85),
(5, 'William Taylor', 'INTERN', 15, 3, 70, DATETIME('now'), DATETIME('now'), 'High Accuracy', 82),
(6, 'Olivia Anderson', 'INTERN', 15, 4, 65, DATETIME('now'), DATETIME('now'), 'Quick Learner', 80),
(7, 'Ethan Thomas', 'INTERN', 15, 5, 60, DATETIME('now'), DATETIME('now'), 'Excellent Communication', 78),
(8, 'Ava Hernandez', 'INTERN', 15, 6, 55, DATETIME('now'), DATETIME('now'), 'Exceptional Adaptability', 75),
(9, 'Noah Wilson', 'INTERN', 15, 7, 50, DATETIME('now'), DATETIME('now'), 'Resourceful Problem Solver', 72),
(10, 'Isabella Garcia', 'INTERN', 15, 8, 45, DATETIME('now'), DATETIME('now'), 'Creative Thinker', 70);

INSERT INTO orders (order_id, product_id, date_time, quantity, pharm_price, discount_percentage, pharmacist_id, final_cost, public_cost, from, supplier_id)
VALUES
(1001, 1, DATETIME('now'), 100, 9.99, 0.05, 1, 949.05, 10.99, 'Pharma Distributors', 1),
(1002, 2, DATETIME('now'), 150, 4.99, 0.03, 2, 746.53, 5.49, 'MediCorp Suppliers', 2),
(1003, 3, DATETIME('now'), 80, 7.49, 0.02, 3, 593.44, 7.99, 'DrugCo Distribution', 3),
(1004, 4, DATETIME('now'), 120, 8.99, 0.04, 4, 1021.44, 9.49, 'PharmaCare', 4),
(1005, 5, DATETIME('now'), 200, 11.99, 0.06, 5, 2276.96, 12.99, 'Pharma Solutions', 5),
(1006, 6, DATETIME('now'), 90, 14.49, 0.03, 6, 1227.92, 14.99, 'MediLink', 6),
(1007, 7, DATETIME('now'), 110, 10.99, 0.02, 7, 1210.78, 11.49, 'PharmaNet Distributors', 7),
(1008, 8, DATETIME('now'), 70, 6.49, 0.05, 8, 454.53, 6.99, 'BreatheEasy Pharma', 8),
(1009, 9, DATETIME('now'), 130, 19.99, 0.04, 9, 2564.36, 20.49, 'SkinCare Inc.', 9),
(1010, 10, DATETIME('now'), 180, 13.99, 0.03, 10, 2388.84, 14.49, 'Pharma Distribution Co.', 10);

INSERT INTO suppliers (name, supplier_id, telephone, address, amount_of_work, class)
VALUES
('Pharma Distributors', 1, '123-456-7890', '123 Supplier Street', 'High', 'Class A'),
('MediCorp Suppliers', 2, '234-567-8901', '456 Distributor Avenue', 'Medium', 'Class B'),
('DrugCo Distribution', 3, '345-678-9012', '789 Wholesale Road', 'Low', 'Class C'),
('PharmaCare', 4, '456-789-0123', '987 Pharmacy Lane', 'High', 'Class A'),
('Pharma Solutions', 5, '567-890-1234', '321 Pharma Plaza', 'Medium', 'Class B'),
('MediLink', 6, '678-901-2345', '654 Supplier Circle', 'Low', 'Class C'),
('PharmaNet Distributors', 7, '789-012-3456', '159 Distributor Boulevard', 'High', 'Class A'),
('BreatheEasy Pharma', 8, '890-123-4567', '852 Pharma Street', 'Medium', 'Class B'),
('SkinCare Inc.', 9, '901-234-5678', '963 SkinCare Avenue', 'Low', 'Class C'),
('Pharma Distribution Co.', 10, '012-345-6789', '741 Pharma Drive', 'High', 'Class A');

INSERT INTO transactions (pharmacist_id, transaction_id, customer_id, purchased_id, doctor_id, price, quantity, reversal_quantity, total_cost, date_time, saved)
VALUES
(1, 1001, 1.1, 1, NULL, 9.99, 2, 0, 19.98, DATETIME('now'), 1),
(2, 1002, 1.2, 2, NULL, 4.99, 3, 0, 14.97, DATETIME('now'), 1),
(3, 1003, 1.3, 3, NULL, 7.49, 1, 0, 7.49, DATETIME('now'), 1),
(4, 1004, 1.1, 4, NULL, 8.99, 2, 0, 17.98, DATETIME('now'), 1),
(5, 1005, 1.2, 5, NULL, 11.99, 1, 0, 11.99, DATETIME('now'), 1),
(6, 1006, 1.3, 6, NULL, 14.49, 4, 0, 57.96, DATETIME('now'), 1),
(7, 1007, 1.1, 7, NULL, 10.99, 2, 0, 21.98, DATETIME('now'), 1),
(8, 1008, 1.2, 8, NULL, 6.49, 3, 0, 19.47, DATETIME('now'), 1),
(9, 1009, 1.3, 9, NULL, 19.99, 1, 0, 19.99, DATETIME('now'), 1),
(10, 1010, 1.1, 10, NULL, 13.99, 2, 0, 27.98, DATETIME('now'), 1),
(11, 1011, 1.2, 11, NULL, 8.49, 3, 0, 25.47, DATETIME('now'), 1),
(12, 1012, 1.3, 12, NULL, 12.99, 1, 0, 12.99, DATETIME('now'), 1),
(13, 1013, 1.1, 13, NULL, 16.49, 2, 0, 32.98, DATETIME('now'), 1),
(14, 1014, 1.2, 14, NULL, 9.99, 1, 0, 9.99, DATETIME('now'), 1),
(15, 1015, 1.3, 15, NULL, 7.99, 3, 0, 23.97, DATETIME('now'), 1),
(16, 1016, 1.1, 16, NULL, 18.49, 1, 0, 18.49, DATETIME('now'), 1),
(17, 1017, 1.2, 17, NULL, 10.49, 2, 0, 20.98, DATETIME('now'), 1),
(18, 1018, 1.3, 18, NULL, 14.99, 3, 0, 44.97, DATETIME('now'), 1),
(19, 1019, 1.1, 19, NULL, 7.49, 2, 0, 14.98, DATETIME('now'), 1),
(20, 1020, 1.2, 20, NULL, 11.99, 1, 0, 11.99, DATETIME('now'), 1),
(21, 1021, 1.3, 21, NULL, 8.99, 4, 0, 35.96, DATETIME('now'), 1),
(22, 1022, 1.1, 22, NULL, 10.99, 1, 0, 10.99, DATETIME('now'), 1),
(23, 1023, 1.2, 23, NULL, 14.49, 3, 0, 43.47, DATETIME('now'), 1),
(24, 1024, 1.3, 24, NULL, 17.99, 2, 0, 35.98, DATETIME('now'), 1),
(25, 1025, 1.1, 25, NULL, 9.99, 1, 0, 9.99, DATETIME('now'), 1),
(26, 1026, 1.2, 26, NULL, 12.99, 2, 0, 25.98, DATETIME('now'), 1),
(27, 1027, 1.3, 27, NULL, 8.49, 3, 0, 25.47, DATETIME('now'), 1),
(28, 1028, 1.1, 28, NULL, 11.99, 1, 0, 11.99, DATETIME('now'), 1),
(29, 1029, 1.2, 29, NULL, 16.49, 2, 0, 32.98, DATETIME('now'), 1),
(30, 1030, 1.3, 30, NULL, 7.99, 3, 0, 23.97, DATETIME('now'), 1),
(31, 1031, 1.1, 31, NULL, 18.49, 1, 0, 18.49, DATETIME('now'), 1),
(32, 1032, 1.2, 32, NULL, 10.49, 2, 0, 20.98, DATETIME('now'), 1),
(33, 1033, 1.3, 33, NULL, 14.99, 3, 0, 44.97, DATETIME('now'), 1),
(34, 1034, 1.1, 34, NULL, 7.49, 2, 0, 14.98, DATETIME('now'), 1),
(35, 1035, 1.2, 35, NULL, 11.99, 1, 0, 11.99, DATETIME('now'), 1),
(36, 1036, 1.3, 36, NULL, 8.99, 4, 0, 35.96, DATETIME('now'), 1),
(37, 1037, 1.1, 37, NULL, 10.99, 1, 0, 10.99, DATETIME('now'), 1),
(38, 1038, 1.2, 38, NULL, 14.49, 3, 0, 43.47, DATETIME('now'), 1),
(39, 1039, 1.3, 39, NULL, 17.99, 2, 0, 35.98, DATETIME('now'), 1),
(40, 1040, 1.1, 40, NULL, 9.99, 1, 0, 9.99, DATETIME('now'), 1),
(41, 1041, 1.2, 41, NULL, 12.99, 2, 0, 25.98, DATETIME('now'), 1),
(42, 1042, 1.3, 42, NULL, 8.49, 3, 0, 25.47, DATETIME('now'), 1),
(43, 1043, 1.1, 43, NULL, 11.99, 1, 0, 11.99, DATETIME('now'), 1),
(44, 1044, 1.2, 44, NULL, 16.49, 2, 0, 32.98, DATETIME('now'), 1),
(45, 1045, 1.3, 45, NULL, 7.99, 3, 0, 23.97, DATETIME('now'), 1),
(46, 1046, 1.1, 46, NULL, 18.49, 1, 0, 18.49, DATETIME('now'), 1),
(47, 1047, 1.2, 47, NULL, 10.49, 2, 0, 20.98, DATETIME('now'), 1),
(48, 1048, 1.3, 48, NULL, 14.99, 3, 0, 44.97, DATETIME('now'), 1),
(49, 1049, 1.1, 49, NULL, 7.49, 2, 0, 14.98, DATETIME('now'), 1),
(50, 1050, 1.2, 50, NULL, 11.99, 1, 0, 11.99, DATETIME('now'), 1),
(51, 1051, 1.3, 51, NULL, 8.99, 4, 0, 35.96, DATETIME('now'), 1);

------------------------------------------------------------------------------------------------------------------------------------------

-- *** need some work on the treasure mangement

-----------------------------
-------------------------done
