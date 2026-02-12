-- Making of tables for silver layer
CREATE TABLE silver.crm_cust_info (
    cust_id              INT,
    cust_key             NVARCHAR(50),
    cust_firstname       NVARCHAR(50),
    cust_lastname        NVARCHAR(50),
    cust_marital_status  NVARCHAR(50),
    cust_gender          NVARCHAR(50),
    cust_create_date     DATE,
    dwh_create_date      DATETIME Default GETDATE()
);
GO
    IF OBJECT_ID ('silver.crm_prd_info','U') IS NOT NULL
    DROP Table silver.crm_prd_info;
    CREATE TABLE silver.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_key_erp  NVARCHAR(50),
    prd_key_sales NVARCHAR(50),
    prd_name     NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_date DATETIME,
    prd_end_date  DATETIME,
    dwh_create_date DATETIME Default GETDATE()
);
GO
If OBJECT_ID ('silver.crm_sales_details','U') is not null
Drop Table silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
    sales_ord_num  NVARCHAR(50),
    sales_prd_key  NVARCHAR(50),
    sales_cust_id  INT,
    sales_order_date DATE,
    sales_ship_date  DATE,
    sales_due_date   DATE,
    sales_sls   INT,
    sales_quantity INT,
    sales_price    INT,
    dwh_create_date  DATETIME Default GETDATE());
GO
CREATE TABLE silver.erp_loc (
    cust_id    NVARCHAR(50),
    country  NVARCHAR(50),
    dwh_create_date DATETIME Default GETDATE()
);
GO
CREATE TABLE silver.erp_cust (
    cust_id    NVARCHAR(50),
    birth_date Date,
    gen    NVARCHAR(50),
    dwh_create_date DATETIME Default GETDATE()
);
GO
CREATE TABLE silver.erp_prd (
    id           NVARCHAR(50),
    category          NVARCHAR(50),
    sub_category       NVARCHAR(50),
    maintenance  NVARCHAR(50),
    dwh_create_date DATETIME Default GETDATE()
);


-- It is an stored procedure for silver layer in which it automatically cleans data from the bronze layer and load into silver layer.
Create Or Alter Procedure Silver_layer As
Declare @Starttime DATETIME, @endtime DATETIME
Begin
Set @Starttime = GetDate();
-- Cleaning and inserting crm_cust_info data into Silver layer crm_cust-info.
Truncate Table silver.crm_cust_info;
Insert Into silver.crm_cust_info(cust_id, cust_key, cust_firstname, cust_lastname, cust_marital_status, cust_gender, cust_create_date) 
Select cust_id,
-- Deleting all the trailing and leading white space
Trim(cust_key) as cust_key,Trim(cust_firstname) as cust_firstname, Trim(cust_lastname) as cust_lastname,
-- applying full keyword into martial_status and gender
Case
When cust_martial_status = 'M' Then 'Married'
When cust_martial_status = 'F' Then 'Single'
Else 'n/a' 
End as cust_martial_status,
Case
When cust_gender = 'M' Then 'Male'
When cust_gender = 'F' Then 'Female'
Else 'n/a' 
End as cust_gender,
cust_create_date
from (-- Check for null and find the duplicate primary key
Select *, ROW_NUMBER() Over(Partition by cust_id Order by cust_create_date desc) as Rank from bronze.crm_cust_info
where cust_id is not null) as r
where Rank = 1

-- Cleaning bronze.crm_prd_details and Inserting into silver layer crm_prd_info
Truncate Table silver.crm_prd_info;
Insert Into silver.crm_prd_info(prd_id, prd_key, prd_key_erp, prd_key_sales, prd_name, prd_cost, prd_line, prd_start_date, prd_end_date)
Select prd_id,
-- Deleting trailing and leading blank spaces
Trim(prd_key) as prd_key,
-- For joining table with erp_prd tables
Replace(Substring(Trim(prd_key),0,6),'-','_') as prd_key_erp,
-- For joining table with sales table
Substring(Trim(prd_key),7) as prd_key_sales,
Trim(prd_name) as prd_name,
ISNULL(prd_cost,0) as prd_cost,
Case (Trim(prd_line))
When 'R' Then 'Road'
When 'M' Then 'Mountain'
When 'S' Then 'Other Sales'
When 'T' Then 'Touring'
Else 'n/a'
End as prd_line,
prd_start_date,
-- Fixing where starting date > end date
DATEADD(DAY,-1,Lead(prd_start_date) Over(Partition by prd_key order by prd_start_date)) as prd_end_date
from bronze.crm_prd_details

--Checking for duplicates and null values in sales order number.
--There are no nulls, but duplicates sales_order_number which show same customer buying different product.
--Trimming of sales_order_number, sales_prd_key, sales_cust_id.
--Casting of date which is integer to date hence checking with invalid date in these there are some zero and wrong date in which we put null in these place.
--Checking price, sales, quantity if it is null, zero, negative and check the relation price*quantity=sales.
Truncate Table silver.crm_sales_details;
Insert Into silver.crm_sales_details(sales_ord_num, sales_prd_key, sales_cust_id, sales_order_date, sales_ship_date, sales_due_date, sales_sls, sales_quantity, sales_price)
Select Trim(sales_order_number) as sales_order_number, Trim(Sales_prd_key) as sales_prd_key,
sales_cust_id,
Case 
When Len(sales_order_date) = 8 Then Cast(Cast(sales_order_date as NVARCHAR) as DATE)
Else NULL 
End as sales_order_number,
Cast(Cast(sales_ship_date as NVARCHAR) as DATE) as sales_ship_date,
Cast(Cast(sales_due_date as NVARCHAR) as DATE) as sales_due_date,
Case When sales_sls is null or sales_sls != Abs(sales_price)*sales_quantity Then Abs(sales_price)*sales_quantity
     Else sales_sls
End as sales_sls,
sales_quantity,
Case When sales_price is null Then Abs(sales_sls)/sales_quantity
     Else Abs(sales_price)
End as sales_price
from bronze.crm_sales_details

-- Cleaning bronze.erp_cust data and inserting into silver.erp_cust
Truncate Table silver.erp_cust;
Insert Into silver.erp_cust(cust_id, birth_date, gen)
Select -- Correcting it for cust_id and trim 
Case 
When Trim(cust_id) Like 'NAS%' Then Substring(Trim(cust_id),4) 
Else Trim(cust_id)
End as cust_id,
-- Checking that every customer is birthdate less than today's date
Case
When cust_birth_date >= GETDATE() Then NULL
Else cust_birth_date
End as birth_date,
-- Handling null and empty values
Case 
When cust_gender IN ('M','Male') Then 'Male'
When cust_gender IN ('F','Female') Then 'Female'
Else null
End as cust_gender
from bronze.erp_cust

-- Insert bronze.erp_prd after cleaning into silver.erp_prd
Truncate Table silver.erp_prd;
Insert Into Silver.erp_prd(id, category, sub_category, maintenance)
Select -- Handling id in required format for crm.prd_details
Replace(Trim(id),'-','_') as id,
-- Replace blank spaces with null
Case 
When Trim(category) = '' Then NULL
Else Trim(category)
End as category,
-- Replace blank spaces with null
Case 
When Trim(sub_category) = '' Then NULL
Else Trim(sub_category)
End as sub_category,
-- Replace blank spaces with null
Case 
When Trim(maintenance) = '' Then NULL
Else Upper(Trim(maintenance))
End as maintenance
from bronze.erp_prd;

-- Insert bronze.erp_loc after cleaning into silver.erp_loc
Truncate Table silver.erp_loc;
Insert Into silver.erp_loc(cust_id, country)
Select -- Handling it for crm_cust_info
Replace(Trim(id),'-','') as id,
-- Handling blank spaces and normalizing the country names.
Case 
When country = 'DE' THEN 'Denmark'
When Country in ('USA', 'US', 'United States') Then 'United States of America'
When Trim(country) = '' Then NULL
Else Trim(country)
End as country
from bronze.erp_loc
Set @endtime = GETDATE();
Print 'Time taken for completion ' + Cast(DATEDIFF(Second,@Starttime,@endtime) as NVARCHAR) + 'seconds'
End
