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
CREATE TABLE silver.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_name     NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_date DATETIME,
    prd_end_date  DATETIME,
    dwh_create_date DATETIME Default GETDATE()
);
GO
CREATE TABLE silver.crm_sales_details (
    sales_ord_num  NVARCHAR(50),
    sales_prd_key  NVARCHAR(50),
    sales_cust_id  INT,
    sales_order_date INT,
    sales_ship_date  INT,
    sales_due_date   INT,
    sales_sls   INT,
    sales_quantity INT,
    sales_price    INT,
    dwh_create_date  DATETIME Default GETDATE()
);
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
