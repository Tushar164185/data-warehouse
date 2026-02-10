-- Cleaning and inserting crm_cust_info data into Silver layer.
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

