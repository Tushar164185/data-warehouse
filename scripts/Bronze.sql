Create Or Alter Procedure bronze.load_layer as 
Begin
Declare @starttime DATETIME, @endtime DATETIME;
Begin
Set @starttime = GETDATE();
Bulk Insert bronze.crm_cust_info
from 'C:\Users\gupta\Downloads\cust_info.csv'
With(
Firstrow = 2,
FieldTerminator=',',
TABLOCK);
Bulk Insert bronze.crm_sales_details
from 'C:\Users\gupta\Downloads\sales_details.csv'
With(
Firstrow = 2,
FieldTerminator=',',
TABLOCK);
Bulk Insert bronze.crm_prd_details
from 'C:\Users\gupta\Downloads\prd_info.csv'
With(
Firstrow = 2,
FieldTerminator=',',
TABLOCK);
Bulk Insert bronze.erp_cust
from 'C:\Users\gupta\Downloads\CUST_AZ12.csv'
With(
Firstrow = 2,
FieldTerminator=',',
TABLOCK);
Bulk Insert bronze.erp_loc
from 'C:\Users\gupta\Downloads\LOC_A101.csv'
With(
Firstrow = 2,
FieldTerminator=',',
TABLOCK);
Bulk Insert bronze.erp_prd
from 'C:\Users\gupta\Downloads\PX_CAT_G1V2.csv'
With(
Firstrow = 2,
FieldTerminator=',',
TABLOCK);
End
Set @endtime = GETDATE();
Print 'Time duration = ' + Cast(DATEDIFF(Second,@starttime,@endtime) as Varchar) + ' seconds';
End
Go
Exec bronze.load_layer;
