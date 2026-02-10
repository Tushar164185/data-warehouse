-- Cleaning and inserting crm_cust_info data into Silver layer crm_cust-info.
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

