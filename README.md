# CS50-SQL-final-project-pharmacy-management-system
 Pharmacy Management SQLite Documentation

Our database intertwines pharmaceutical practices with insightful data analysis, offering a comprehensive solution for optimizing customer relationships, revenue streams, and product inventories. By delving into customer behaviors and sales trends, it empowers informed decision-making, fostering profitability and operational efficiency. Moreover, it provides valuable insights into pharmacist performance, fostering continuous improvement and professional development. Through meticulous transaction management, it streamlines pharmacy operations, enabling strategic decision-making and elevating patient care standards.




## Scope

The pharmacy management SQLite database is designed to handle various aspects of pharmacy operations, including inventory management, customer management, transactions, and orders. It aims to streamline the processes involved in managing pharmacy products, customer information, and transactions efficiently.

## Functional Requirements

The database supports the following functionalities:

1. **Customer Management**: Manages customer information such as names, telephone numbers, activities, and entry dates. It updates customer activity based on transaction history to identify inactive customers.

2. **Revenue Management**: Calculates revenue for the last month and quarter based on cash transactions, considering sales at public prices and total sales by pharmacists.

3. **Sales Management**: Provides insights into sales activities, including weekly, monthly, and yearly sales. It also analyzes average sales for each month and day of the week, tracks sales performance by pharmacists, and monitors transaction volumes for different product categories.

4. **Retention and Acquisition Analysis**: Calculates metrics such as Repeat Customer Rate (RCR), Retention Rate (RR), and the percentage of new customers in the last 45 days. It also tracks follow-up activities for new customers in the previous 45 days.

5. **Inventory Management**: Tracks pharmacy product inventory, including product types, quantities, prices, and expiration dates. It also manages supplier information and tracks orders placed for pharmacy products.

6. **Pharmacist Management**: Manages pharmacist details such as names and IDs. It also analyzes pharmacist performance based on sales data and tracks the percentage contribution of each pharmacist to total sales.

7. **Transaction Management**: Records transaction details such as transaction IDs, dates, total costs, customer IDs, and product IDs. It also links transactions to specific pharmacists and tracks cash transactions associated with each transaction.

------------------------------------------------------------------------------------------------------------

### Entity-Relationship Diagram (ERD)

#### Entities
1. **Customers**
   - Attributes: customer_id, name, telephone1, activity, entry_date

2. **Transactions**
   - Attributes: transaction_id, date_time, total_cost, customer_id, purchased_id

3. **Pharmacists**
   - Attributes: pharmacist_id, name

4. **Pharmacy Products**
   - Attributes: id, type

#### Relationships
1. **Customers - Transactions**: One-to-Many
   - A customer can have multiple transactions.

2. **Transactions - Pharmacy Products**: Many-to-One
   - Each transaction involves a pharmacy product.

3. **Transactions - Pharmacists**: Many-to-One
   - Each transaction is conducted by a pharmacist.

4. **Transactions - Customers**: Many-to-One
   - Each transaction belongs to a customer.

5. **Transactions - Cashair**: One-to-Many
   - A transaction can have multiple cash transactions.

6. **Pharmacy Products - Transactions**: One-to-Many
   - Each pharmacy product can have multiple transactions.

7. **Pharmacists - Cashair**: One-to-Many
   - A pharmacist can have multiple cash transactions.

8. **Customers - Cashair**: One-to-Many
   - A customer can have multiple cash transactions.

------------------------------------------------------------------------------------------------------------

## Scope

The pharmacy management SQLite database is designed to handle various aspects of pharmacy operations, including inventory management, customer management, transactions, and orders. It aims to streamline the processes involved in managing pharmacy products, customer information, and transactions efficiently.

## Functional Requirements

The database supports the following functionalities:

1. **Inventory Management**: Tracks pharmacy products including their names, types, barcodes, prices, available quantities, expiration dates, active ingredients, suppliers, storage requirements, and sale information.
2. **Customer Management**: Manages customer information such as names, addresses, contact details, purchase history, loyalty points, and customer types.
3. **Transaction Management**: Records transactions including purchased products, quantities, prices, transaction dates, associated customers, and doctors.
4. **Order Management**: Handles orders placed for pharmacy products, including order IDs, product IDs, order dates, quantities, prices, discounts, pharmacist IDs, and distribution company names.
5. **Pharmacist Management**: Manages pharmacist details such as names, degrees, payment rates, previous violations, assessment scores, employment dates, and achievements.

## Representation

### Entities

#### Pharmacy Products

- **Attributes**:
  - `id`: Unique ID for the product.
  - `name`: Name of the product.
  - `type`: Type of the product (e.g., cosmetics, medicines, medical supplies).
  - `barcode`: Barcode of the product.
  - `price`: Price of the product.
  - `limit_to_order`: Quantity threshold for ordering the product.
  - `amount_available`: Available quantity of the product.
  - `sale`: Sale discount applied to the product.
  - `active_ingredients`: Active ingredients of the product.
  - `supplier`: Supplier of the product.
  - `storage_degree`: Storage temperature requirement for the product.
  - `schedule`: Classification schedule of the product.
  - `deleted`: Flag indicating if the product is deleted.
  - `expire`: Expiration date of the product.

#### Customers

- **Attributes**:
  - `customer_id`: Unique ID for the customer.
  - `name`: Name of the customer.
  - `address`: Address of the customer.
  - `telephone1`: Primary telephone number of the customer.
  - `telephone2`: Secondary telephone number of the customer.
  - `email`: Email address of the customer.
  - `payed`: Total amount spent by the customer.
  - `points`: Loyalty points accumulated by the customer.
  - `loyalty`: Loyalty status of the customer.
  - `customer_type`: Type of customer (e.g., normal, foreign, contracted).

#### Transactions

- **Attributes**:
  - `transaction_id`: Unique ID for the transaction.
  - `customer_id`: ID of the customer involved in the transaction.
  - `purchased_id`: ID of the purchased product.
  - `doctor_id`: ID of the doctor associated with the transaction.
  - `price`: Price of the product.
  - `quantity`: Quantity of the product purchased.
  - `reversal_quantity`: Quantity of reversed transaction.
  - `end_quantity`: Final quantity after transaction.
  - `total_cost`: Total cost of the transaction.
  - `date_time`: Date and time of the transaction.
  - `saved`: Flag indicating if the transaction is saved.

#### Cashair

- **Attributes**:
  - `transaction_id`: Unique ID for the transaction.
  - `total_cost`: Total cost of the transaction.
  - `payment_method`: Payment method used.
  - `customer_id`: ID of the customer involved.
  - `customer_type`: Type of customer.

#### Orders

- **Attributes**:
  - `order_id`: Unique ID for the order.
  - `product_id`: ID of the ordered product.
  - `date_time`: Date and time of the order.
  - `quantity`: Quantity of the ordered product.
  - `pharm_price`: Price for the pharmacy.
  - `discount_percentage`: Discount percentage applied to the order.
  - `pharmacist_id`: ID of the pharmacist who placed the order.
  - `final_cost`: Final cost of the order.
  - `public_cost`: Public cost of the order.
  - `from`: Distribution company name.
  - `supplier_id`: ID of the supplier.

#### Doctors

- **Attributes**:
  - `doctor_id`: Unique ID for the doctor.
  - `doc_name`: Name of the doctor.
  - `address`: Address of the doctor.
  - `phone1`: Primary phone number of the doctor.
  - `phone2`: Secondary phone number of the doctor.
  - `clinic_name`: Name of the clinic.
  - `clinic_phone1`: Primary phone number of the clinic.
  - `clinic_phone2`: Secondary phone number of the clinic.

#### Pharmacists

- **Attributes**:
  - `pharmacist_id`: Unique ID for the pharmacist.
  - `name`: Name of the pharmacist.
  - `degree`: Degree of the pharmacist.
  - `payment_rate`: Payment rate for the pharmacist.
  - `previous_violations_num`: Number of previous violations for the pharmacist.
  - `last_assessment_score`: Last assessment score for the pharmacist.
  - `last_assessment_date`: Date of the last assessment for the pharmacist.
  - `employment_date`: Date of employment for the pharmacist.
  - `achievements`: Achievements of the pharmacist.
  - `total_score`: Total score for the pharmacist.

#### Suppliers

- **Attributes**:
  - `name`: Name of the supplier.
  - `supplier_id`: Unique ID for the supplier.
  - `telephone`: Telephone number of the supplier.
  - `address`: Address of the supplier.

### Views

#### Upcoming Deficiencies

- **Purpose**: Provides information about upcoming deficiencies in product quantities.
- **Attributes**:
  - `product_id`: ID of the product.
  - `date_time`: Date and time of the deficiency.
  - `discount_percentage`: Discount percentage for the product.

#### Discount Trend

- **Purpose**: Calculates the trend of discount percentages over time.
- **Attributes**:
  - `product_id`: ID of the product.
  - `avg_discount_percentage`: Average discount percentage for the product.
  - `num_orders`: Number of orders for the product.
  - `start_date`: Start date for the trend analysis.
  - `end_date`: End date for the trend analysis.

#### Weekly Trends

- **Purpose**: Analyzes weekly trends in product quantities sold.
- **Attributes**:
  - `name`: Name of the product.
  - `supplier`: Supplier of the product.
  - `amount_available`: Available quantity of the product.
  - `month`: Month of the trend.
  - `monthly_quantity_sold`: Quantity sold in the month.
  - `purchased_id`: ID of the purchased product.
  - `year`: Year of the trend.
  - `week_number`: Week number of the trend.
  - `weekly_quantity_sold`: Quantity sold in the week.
  - `week_trend`: Trend in sales for the week.
  - `quarter_trend`: Trend in sales for the quarter.

####  RCR (Repeat Customer Rate)

- **Purpose**: Calculate the percentage of customers who visit the pharmacy periodically.
- **Attributes**:
  - `name`: Name of the customer.
  - `customer_id`: ID of the customer.
  - `customer_type`: Type of the customer.
  - `month_year`: Month and year of the transaction.
  - `total_purchased_per_month`: Total purchased amount by the customer in a month.
  - `num_transactions_per_month`: Number of transactions made by the customer in a month.
  - `status_on_transactions_num`: Trend status based on the number of transactions.
  - `status_on_total_purchased`: Trend status based on the total amount purchased.

------------------------------------------------------------------------------------------------------------

### Orders Management Queries Documentation

#### Problem #0: Medication Transaction Analysis in the Last 30 Days

This query aims to identify the medications that have been transacted the most over the past 30 days. It counts the number of transactions for each medication and orders them in descending order based on the transaction count.

#### Problem #1: Medication Revenue Analysis in the Last 30 Days

##### Approach 1: Most Transactioned
This approach focuses on identifying the medications that have been transacted the most in terms of revenue over the last 30 days. It retrieves the top 10 medications based on the number of transactions.

##### Approach 2: Most Profitable
Here, the query aims to find the top 10 medications that have generated the most revenue in the last 30 days. Revenue is calculated based on the product price and discount percentage.

##### Approach 3: Combined Analysis
This approach combines both transaction count and revenue to provide a comprehensive view. It joins transaction data with product data, considering both transaction count and revenue to determine the top products.

#### Problem #2: Medication Decline Analysis

This problem investigates medications that are experiencing a decline in the market, primarily measured by a decrease in the discount percentage. The process involves creating views to analyze the trend of discount percentage over time and calculating the slope of the discount percentage trend using linear regression.

#### Problem #3: Analysis of Stagnant Products

The goal is to identify products that have had rare transactions in the last 6 months and sort them based on the sold amount. This query retrieves pharmacy products that have been transacted infrequently in the past 6 months and sorts them by the sold amount in ascending order.

#### Problem #4: Seasonal Trend Analysis

This problem involves analyzing weekly trends for products with seasonal variations. The query creates a view to analyze weekly trends in product transactions and categorizes them into quarters. It aims to identify products that exhibit seasonal trends, such as increased sales during specific quarters.

#### Problem #5: Order Forecast for Next 5 Days

##### Approach 1: Basic Forecasting
This approach forecasts the quantity of products to order for the next 5 days based on the available quantity and threshold limit for ordering. It calculates the amount to order for each product based on its current availability.

##### Approach 2: Weighted Forecasting
This approach uses exponential weights to forecast the number of transactions for the next 5 days. It calculates the forecasted sales based on the weighted average of past transaction counts over different time intervals.

##### Approach 3: Quantity Forecasting
Similar to approach 2, this method forecasts the quantity to order for the next 5 days using exponential weights. It calculates the forecasted quantity based on the weighted average of past dispensed amounts over different time intervals.

#### Problem #6: Analysis of Medications Related to Doctors with Low Quantity

This query identifies medications related to doctors in the last 30 days that have a low quantity available. It aims to highlight medications that need to be ordered in limited amounts to avoid losses if doctors decide to shift to other brands.

------------------------------------------------------------------------------------------------------------

### Inventory Management: Capital Cycle Calculation

The capital cycle in inventory management refers to the duration between the purchase of inventory and the realization of cash from its sale. It represents the time it takes for a company to convert its investment in inventory into cash flow.

#### Problem Overview:
This query aims to calculate the capital cycle by analyzing various aspects of inventory management, including sales, inventory levels, and orders.

#### Problem Solving Steps:
1. **(a) Get Sales at Cost Price in the Month**:
   - Retrieve the sales transactions for the last 30 days, including product ID, end quantity, price, and pharmaceutical price.

2. **(b) Get Inventory at Cost Price at the Month End**:
   - Calculate the total value of inventory at cost price at the end of the month.

3. **(c) Total Orders to be Subtracted**:
   - Calculate the total value of orders placed during the month to be subtracted from the inventory.

4. **(d) Total Transactioned to be Added**:
   - Calculate the total value of transactioned products to be added to the inventory.

5. **(e) Get Inventory at Cost Price at the Month Start**:
   - Calculate the value of inventory at cost price at the start of the month by adjusting for orders and transactioned products.

6. **(f) Average Inventory Cost of a Month**:
   - Calculate the average inventory cost for the month by taking the average of the inventory at the start and end of the month.

7. **(g) Calculate Capital Cycle**:
   - Finally, compute the capital cycle using the formula:

     [ Capital Cycle = Total Monthly Sales \ Average Inventory Cost  ]

#### Output:
- **Capital Cycle**: The calculated duration representing the capital cycle.
- **Total Monthly Sales**: Total sales value of pharmaceutical products in the last 30 days.
- **End Inventory Cost**: Total value of inventory at cost price at the end of the month.
- **Total Quantity**: Total quantity of pharmaceutical products transacted in the last 30 days.
- **Cost of Monthly Sales**: Total cost of pharmaceutical products sold in the last 30 days.
- **Start Inventory Cost**: Value of inventory at cost price at the start of the month.
- **Average Inventory Cost**: Average cost of inventory throughout the month.


------------------------------------------------------------------------------------------------------------


### Revenue Management: Calculate Revenue for Last Month

#### Problem Overview:
This query aims to calculate the revenue generated in the last month by comparing the total sales at public prices with the total sales at pharmaceutical prices.

#### Problem Solving Steps:
1. **Get Sales at Public Price in the Month**:
   - Retrieve the total sales amount at public prices for the last 30 days from the "cashair" table.

2. **Get Sales at Pharmaceutical Price in the Month**:
   - Retrieve the total sales amount at pharmaceutical prices for the last 30 days from the "transactions" and "orders" tables.

3. **Calculate Total Sales of Pharmaceutical Products**:
   - Calculate the total sales of pharmaceutical products by summing the product of end quantity and pharmaceutical price for each product.

4. **Calculate Revenue for Last Month**:
   - Subtract the total sales of pharmaceutical products from the total sales at public prices to determine the revenue generated in the last month.

#### Output:
- **Revenue for Last Month**: The calculated revenue generated in the last month.

### Revenue Management: Calculate Revenue for This Quarter

#### Problem Overview:
This query calculates the revenue generated in the current quarter by comparing the total sales at public prices with the total sales at pharmaceutical prices.

#### Problem Solving Steps:
1. **Get Sales at Public Price in the Quarter**:
   - Retrieve the total sales amount at public prices for the last 120 days from the "cashair" table.

2. **Get Sales at Pharmaceutical Price in the Quarter**:
   - Retrieve the total sales amount at pharmaceutical prices for the last 120 days from the "transactions" and "orders" tables.

3. **Calculate Total Sales of Pharmaceutical Products**:
   - Calculate the total sales of pharmaceutical products by summing the product of end quantity and pharmaceutical price for each product.

4. **Calculate Revenue for This Quarter**:
   - Subtract the total sales of pharmaceutical products from the total sales at public prices to determine the revenue generated in this quarter.

#### Output:
- **Revenue for This Quarter**: The calculated revenue generated in this quarter.


------------------------------------------------------------------------------------------------------------

### Sales Management: Calculate Revenue for Last Month

#### Problem #0: Weekly Sales
- **Objective**: Determine the total sales for each customer type within the last week.

#### Problem #1: Monthly Sales
- **Objective**: Calculate the total sales for each customer type within the last month.

#### Problem #2: Yearly Sales
- **Objective**: Determine the total sales for each customer type over the past year.

#### Problem #3: Average Monthly Sales
- **Objective**: Find the average sales for each month of the year, sorted from the highest to the lowest average.

#### Problem #4: Average Daily Sales
- **Objective**: Find the average sales for each day of the week, sorted from the highest to the lowest average.

#### Problem #5: Total Sales by Pharmacist
- **Objective**: Calculate the total sales made by each pharmacist in the last month.

#### Problem #6: Total Transactions by Pharmacist
- **Objective**: Determine the total number of transactions conducted by each pharmacist in the last month.

#### Problem #7: Total Transactions by Product Category
- **Objective**: Find the total number of transactions for each product category within the last month.

#### Problem #8: Percentage of Total Sales by Pharmacist
- **Objective**: Calculate the percentage of total sales contributed by each pharmacist within the last month.

------------------------------------------------------------------------------------------------------------

### Customer Management

#### Problem #0: Update Customer Activity
- **Objective**: Update the activity status of customers based on their transaction history.

#### Problem #RCR (Repeat Customer Rate)
- **Objective**: Calculate the percentage of customers who come to the pharmacy periodically.
- **View Creation**: Create a view to analyze monthly sales and transactions for each customer.

#### Problem #RR (Retention Rate)
- **Objective**: Determine the percentage of customers who stayed with the pharmacy in the current month.

#### Problem #New Customers
- **Objective**: Analyze the percentage of new customers acquired in the last 45 days.

#### Problem #Follow Up
- **Objective**: Track the behavior of new customers acquired in the previous 45 days.




