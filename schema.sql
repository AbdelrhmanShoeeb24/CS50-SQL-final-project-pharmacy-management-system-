--this is the schema of pharmacy management SQLite

-- pharmacy products table, the bool in which all sellable items in the pharmacy
CREATE TABLE IF NOT EXISTS "pharmacy_products"(
    "id" INTEGER,
    "name" TEXT,                     --the name of the product (contain the concentration, pharmaceutical form and num of pills or ml in it)
    "type" TEXT CHECK IN('cosmoticis', 'medicine', 'medical_supplies', 'supplements', 'accessories', 'services'),
    "barcode" TEXT,                  --international barcode
    "price" NUMERIC,                 --the price in the order pill
    "limit_to_order" INT,            --the amount after it , we will order this med
    "amount_available" DECIMAL,      --total amount , may contain some strips
    "sale" DECIMAL(2,2),             --if there is a sale related to some products
    "active_ingrediants" TEXT,       -- one or more scientific name
    "supplier" TEXT,                 -- the company which distribute this medication
    "storage_degree" INT DEFAULT 25, -- some drugs MUST be refrigrated
    "schedule" TEXT CHECK IN ('first', 'second', 'third', 'non') DEFAULT 'non', -- (abused drugs)govenmental classification
    "deleted" BOOLEAN DEFAULT 0,
    "expire" DATETIME DEFAULT '2030-12-31',
    PRIMARY KEY ("id")
);
-- customers table, contain the information of pharmacy customers(usually come )
CREATE TABLE IF NOT EXISTS "customers"(
    "customer_id" DECIMAL(6,1) DEFAULT 1.0, -- ONE DIGIT (is 1,2,3)--> customer type, post dicimal 5 digits indicate (customer id)
    "name" TEXT, --the name of the customer
    "previx" TEXT, --the called formal word (sir, Mr, teacher ,.....) --it is better to call with it , create some engagement
    "activity" boolean DEFAULT 1, --DOes this customer come to the pharmacy in the last 6 monthes, at least once => active (1)
    "address" TEXT, --for the delivary and orders
    "telephone1" TEXT DEFAULT '01_________',
    "telephone2" TEXT DEFAULT NULL,
    "email" TEXT DEFAULT NULL,
    "category" INT, -- *** under development
    "entry_date" datetime default datetime('now') -- the date this customer (singned) in the pharmacy for the 1st time , he may purshased before this time
    "points" decimal(5,2) DEFAULT 0, --for each x (1000) value the customer pay , gains y (10) points which could later exchanged by other products.
    "loyality" INT, --for marketing *** under development
    "customer_type" INT CHECK IN (1,2,3) DEFAULT 1, -- 'normal'--> 2, 'foriegn'-->1 , 'contracted'-->3 ***  (3)under development
-- usually foreign (1) because not every customer should sign with the pharmacy , foreign mens usual customer, NORMAL is the forein after he signed in the pharmacy
    PRIMARY KEY ("customer_id")
);
-- transactions table, contain each purchased_id(product with price and quantity) by a customer_id from a certain doctor(or not) , at a time stamp , and dispensed by the customer(id)
CREATE TABLE IF NOT EXISTS "transactions"(
    "pharmacist_id" INT, --links the pharmacists table
    "transaction_id" INT, --the id of the product(s) purshased by a customer, it is repeated for each entery in the sane sail , not unique for transaction unique for sail
    "customer_id" DECIMAL(6,1) DEFAULT 1.0, --usually we sell for the foreign
    "purchased_id" INT, -- ID OF PRODUCT PURSHASED
    "doctor_id" INT DEFAULT NULL, --usually we sell without prescription
    --the unique for ech row is (purshaed_id AND transaction_id)
    "price" DECIMAL DEFAULT (SELECT "price" FROM "phamacy_pruducts" AS P WHERE "transactions"."id" = P."purchased_id"),
    "quantity" INT,
    "reversal_quantity" INT DEFAULT 0, -- if the patient would like to reverse the product
    "end_quantity" INT DEFAULT "transactions"("quantity")- "transactions"("reversal_quantity"), --totla quantity
    "total_cost" DECIMAL DEFAULT ("price" * "quality"),
    "date_time" DATETIME DEFAULT CURRENT_TIMESTAMP,
    "saved" boolean default 0,
    FOREIGN KEY ("purchased_id") REFERENCES "pharmacy_products"("id"),
    FOREIGN KEY ("customer_id") REFERENCES "customers"("customer_id"),
    FOREIGN KEY ("doctor_id") REFERENCES "doctors"("doctor_id"),
    FOREIGN KEY ("pharmacist_id") REFERENCES "pharmacists"("pharmacist_id"),
    FOREIGN KEY ("transaction_id") REFERENCES "cashair"("transaction_id")
);
-- table cashair, the bool in which products translated to money
CREATE TABLE IF NOT EXISTS "cashair" (
    "date_time" DATETIME DEFAULT CURRENT_DATETIME, -- the date_time in which it is saved
    "transaction_id" INT, --unifies the products selled to the customer in this sail, their quantities and prices
    "total_cost" DECIMAL, -- calculate the total cost
    "payment_method" TEXT DEFAULT 'cash' CHECK IN ('cash','visa'), --imporant for total shift closure *** under development
    "customer_id" DECIMAL(6,1), --links to the customers table
    "customer_type" INT DEFAULT(LOWER("customer_id")) CHECK IN (1,2,3), --'normal'-->2, 'foriegn'-->1 , 'contracted'-->3
    PRIMARY KEY ("transaction_id"),
    FOREIGN KEY "customer_id" REFERENCES "customers"("customer_id")
);
--need to create shifts table of the end amount of cash for each shift, the pharmacist(s), date_time. And relate this to the fingerprint ***
-- other idea is the development of main stock table away from the pharmacy and link both together ***
--doctors table, keep info of the routinaly coming prescription
CREATE TABLE IF NOT EXISTS "doctors"(
    "doctor_id" INT,
    "doc_name" TEXT,
    "address" TEXT,
    "phone1" TEXT,
    "phone2" TEXT,
    "clinic_name" TEXT
    "clinic_phone1" TEXT,
    "clinic_phone2" TEXT,
--  "product_id" INT, -- need to include a (list) of commercial drugs written by this doctor ***
    PRIMARY KEY ("doctor_id")
);
--need to develop a table for each workers category , like the delivary_men, accountants,... ***
--pharmacists table, include all needed information about community pharmacists
CREATE TABLE IF NOT EXISTS "pharmacists"(
    "pharmacist_id" INT,
    "name" TEXT,
    "degree" TEXT CHECK IN ('INTERN', 'FIRST', 'SECOND', 'SHIIFT_MANEGAR', 'HEAD'),
    "payment_rate" INT, -- pharmacist in egypt has (hour price) , total salary = hour price * hours of the shift , under development ***
    "previous_violations_num" INT, --number of previous violations(like delay in openning more than once)
    "last_assessment_score" INT,   --score in the last assessment
    "last_assessment_date" DATETIME, --date of last assessment
    "employment_date" DATE,
    "achievements" TEXT, --like 'breaking target for 5 consequtive monthes', 'increase customer satsifaction'
    "total_score" INT, -- HR  department related score ***
    PRIMARY KEY ("pharmacist_id")
);
--orders table, contain data of the incoming orders from different suppliers, those orders make our stock (pharmacy_products table)
CREATE TABLE IF NOT EXISTS "orders"(
    "order_id" INT, -- not unique for the row, but for each order
    "product_id" INT, --(order id AND product id) together are unique
    "date_time" DATETIME DEFAULT CURRENT_TIMESTAMP,
    "quantity" INT CHECK "quantity" > 0,
    "pharm_price" DECIMAL, --the price for the pharmacy
    "discount_percentage" DECIMAL(2,2),
    "pharmacist_id", -- who ordered this order
    "final_cost" DECIMAL DEFAULT ("quantity" * "pharm_price" * "discount_percentage"), -- ***
    "public_cost" DECIMAL,
    "from" TEXT, --DISTRIPUTION COMPANY NAME
    "supplier_id"
    FOREIGN KEY ("product_id") REFERENCES "pharmacy_products"("id"),
    FOREIGN KEY ("pharmacis_id") REFERENCES "pharmacists"("id"),
    FOREIGN KEY ("suppliers")  REFERENCES "suppliers"("supplier_id")
    PRIMARY KEY ("order_id", "product_id")
);
--suppliers info
CREATE TABLE IF NOT EXISTS "suppliers"(
    "name" TEXT,
    "supplier_id" INT,
    "telephone" TEXT,
    "address" TEXT,
    "amount_of_work",
    "class",
    PRIMARY KEY ("id")
);

CREATE TRIGGER orders_update
BEFORE INSERT ON "orders"
FOR EACH ROW
BEGIN
    UPDATE pharmacy_products
    SET price = NEW.public_cost,
        amount_available = NEW.quantity + amount_available
    WHERE id = NEW.product_id;
END;

CREATE TRIGGER transaction
AFTER INSERT ON transactions
BEGIN
    -- Begin transaction
    BEGIN TRANSACTION;

    -- Declare variables to store data from NEW row
    DECLARE transaction_id_var INT;
    DECLARE saved_var boolean;
    DECLARE quantity_var INT;
    DECLARE purchased_id_var INT;
    DECLARE total_cost_var DECIMAL;
    DECLARE customer_id_var DECIMAL;

    -- Fetch data from NEW row into variables
    SELECT transaction_id, saved, quantity, purchased_id, total_cost, customer_id
    INTO transaction_id_var, saved_var, quantity_var, purchased_id_var, total_cost_var, customer_id_var
    FROM transactions WHERE ROWID = NEW.ROWID;

    -- Mark transaction as saved
    UPDATE transactions
    SET saved = 1
    WHERE transaction_id = transaction_id_var;

    -- Update amount available in pharmacy_products if status is 'saved'
    IF saved_var = 1 THEN
        UPDATE pharmacy_products
        SET amount_available = amount_available - quantity_var
        WHERE id = purchased_id_var;
    END IF;

    -- Insert into cashair if all transactions are saved
    IF NOT EXISTS (
        SELECT saved
        FROM transactions
        WHERE transaction_id = transaction_id_var
        AND saved = 0
    ) THEN
        INSERT INTO cashair (transaction_id, total_cost, customer_id)
        VALUES (transaction_id_var, total_cost_var, customer_id_var);
    END IF;

    -- Commit transaction
    COMMIT;

    -- Drop variables to clear memory
    DROP VARIABLE transaction_id_var;
    DROP VARIABLE saved_var;
    DROP VARIABLE quantity_var;
    DROP VARIABLE purchased_id_var;
    DROP VARIABLE total_cost_var;
    DROP VARIABLE customer_id_var;
END;

CREATE TRIGGER points
AFTER INSERT ON cashair
BEGIN
    UPDATE customers
    SET total_payed = (SELECT total_payed FROM customers WHERE customer_id = NEW.customer_id) + NEW.total_cost,
        points = (SELECT points FROM customers WHERE customer_id = NEW.customer_id) + NEW.total_cost / 1000,
        activity = 1
        END
    WHERE customer_id = NEW.customer_id AND customer_type = 2;
END;
------------------------------------------------------------------------------------------------------------------------------------------


CREATE INDEX transactions_date_time ON transactions (date_time);
CREATE INDEX transactions_purchased_id ON transactions (purchased_id);
CREATE INDEX transactions_customer_id ON transactions (customer_id);
CREATE INDEX transactions_product_id ON transactions (product_id);
CREATE INDEX transactions_date_time ON transactions (date_time);
CREATE INDEX transactions_purchased_id ON transactions (purchased_id);

-- *** need some work on the treasure mangement
