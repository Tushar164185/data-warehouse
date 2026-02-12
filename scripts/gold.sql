-- Making gold dimension table customer by joining silver layer erp_loc and erp_cust with crm customer information for more information making it a business oriented table.
Create View gold.dim_customers as (
Select ROW_NUMBER() OVER(order by ci.cust_id) as id,
ci.cust_id as customer_id,
ci.cust_key as customer_key, 
ci.cust_firstname as customer_firstname,
ci.cust_lastname as customer_lastname,
cl.country as country,
Case 
When ci.cust_gender!='n/a' Then ci.cust_gender -- crm customer is superior table for infomration clashed
Else Coalesce(ca.gen,'n/a')
End as customer_gender,
ca.birth_date as birth_date,
ci.cust_marital_status as customer_martial_status,
ci.cust_create_date as customer_create_date
from silver.crm_cust_info as ci
left join silver.erp_cust as ca
on ci.cust_key = ca.cust_id
left join silver.erp_loc as cl
on ci.cust_key = cl.cust_id);

-- Making gold layer for products by joining silver layer erp_product and crm products information for more infomation making it more relevant for business.
Create View gold.dim_products as
(Select ROW_NUMBER() OVER(Order by cp.prd_id) as id,
cp.prd_id as product_id,
cp.prd_key as product_key,
cp.prd_key_sales as product_key_sales,
cp.prd_name as product_name,
ep.category as category,
ep.sub_category as sub_category,
ep.maintenance as maintenance,
cp.prd_line as product_line,
cp.prd_cost as product_cost,
cp.prd_start_date as product_start_date
from silver.crm_prd_info as cp left join silver.erp_prd as ep
on cp.prd_key_erp = ep.id
where cp.prd_end_date is null); -- only present info of product

-- Making gold layer sales as fact table using star schema connecting with product(dimensions) and customers(dimensions)
Create View gold.dim_sales as 
(Select cs.sales_ord_num as sales_order_number,
gp.id as product_id,
gc.id as customer_id,
sales_order_date as order_date,
sales_ship_date as shiping_date,
sales_due_date as due_date,
sales_sls as sales_amount,
sales_quantity as quantity,
sales_price as price
from silver.crm_sales_details as cs
left join gold.dim_products as gp
on cs.sales_prd_key = gp.product_key_sales
left join gold.dim_customers as gc
on cs.sales_cust_id = gc.customer_id)
