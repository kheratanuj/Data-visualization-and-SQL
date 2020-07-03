
use POS
--DATA PREPARATION AND UNDERSTANDING
--1. What is total number of rows in each of 3 tables in the database?
select * from (
				select 'CUSTOMER' AS TABLE_NAME,count(*) as no_of_records from CUSTOMER UNION ALL
				select 'PROD_CAT_INFO' as TABLE_NAME,count(*) as no_of_records from PRODUCT UNION ALL
				select 'TRANSACTIONS' as TABLE_NAME,count(*) as no_of_records from TRANC
			  )TBL
--select count(customer_Id) Total_Customer,count(transaction_id) Total_Transaction,count(prod_sub_cat_code) [Total Subcategories] from CUSTOMER C FULL JOIN PRODUCT P on C.customer_Id=P.prod_cat_code
--FULL JOIN TRANC T ON C.customer_Id=T.transaction_id

--2. What is total number of transactions that have a return?
select count(*) no_of_returns from TRANC 
where Qty<0

--3. As you would have noticed, the dates provided across the datasets are 
--not in a correct format. As first steps, pls convert the date variables into 
--valid date formats before proceeding ahead.

select convert(varchar,tran_date,105) from TRANC
--sp_help TRANC
--alter table TRANC add tranc_date as (CONVERT(varchar,tran_date,105))
--alter table TRANC alter column tranc_date Date
--alter table TRANC drop column tranc_date,transc_date

--4.	What is the time range of the transaction data available for analysis? Show the 
--output in number of days,months and years simultaneously in different columns.
SELECT
DATEDIFF(DD,MIN(TRAN_DATE),MAX(TRAN_DATE)) as [DAYS],
DATEDIFF(MM,MIN(TRAN_DATE),MAX(TRAN_DATE)) as [MONTHS],
DATEDIFF(YYYY,MIN(TRAN_DATE),MAX(TRAN_DATE)) as [YEARS]
FROM TRANC

--5.	Which product category does the sub-category “DIY” belong to?

select prod_cat from PRODUCT
where prod_subcat='DIY'

--DATA ANALYSIS

--1.	Which channel is most frequently used for transactions?
select top 1
Store_type as Channel,COUNT(transaction_id) [Transaction Count]
from TRANC group by Store_type
order by [Transaction Count] DESC

--2.	What is the count of Male and Female customers in the database?
select Gender,COUNT(customer_Id) [Customer Count]
from CUSTOMER group by Gender

--3.	From which city do we have the maximum number of customers and how many?
select TOP 1
city_code,count(customer_Id) Customer_count from CUSTOMER
group by city_code order by count(customer_Id) desc

--4.	How many sub-categories are there under the Books category?
select count(prod_subcat) [No of subcategory in Books] from PRODUCT
where prod_cat='Books'

--5.	What is the maximum quantity of products ever ordered?
select MAX(Qty) Max_quantity_ordered from TRANC

--6. What is the net total revenue generated in categories Electronics and Books?
select SUM(total_amt) Total_Revenue from TRANC T 
where prod_cat_code IN (select prod_cat_code from PRODUCT where prod_cat IN 
('Electronics','Books'))

--7.	How many customers have >10 transactions with us, excluding returns?
select count(*)as No_of_customers from
(
select cust_id,count(transaction_id)[No of Transactions]  from TRANC
where Qty>0
group by cust_id
having count(transaction_id)>10 
)as T1

--8.	What is the combined revenue earned from the “Electronics” & 
--“Clothing” categories, from “Flagship stores”?
select sum(total_amt) [Combined Revenue] from TRANC
where Store_type='Flagship store' and prod_cat_code IN (select prod_cat_code from PRODUCT where prod_cat IN 
('Electronics','Clothing'))

--9.	What is the total revenue generated from “Male” customers in “Electronics” 
--category? Output should display total revenue by prod sub-cat.
select prod_subcat,sum(total_amt) [Total Revenue] from TRANC T inner join
CUSTOMER C on T.cust_id=C.customer_Id inner join PRODUCT P on P.prod_cat_code=T.prod_cat_code and P.prod_sub_cat_code=T.prod_subcat_code
where Gender='M'and 
prod_cat IN 
('Electronics')
group by prod_subcat

--10. 10.	What is percentage of sales and returns by product sub category; 
--display only top 5 sub categories in terms of sales?
 select top 5
     P.prod_subcat [Subcategory] ,
      Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2)[Sales]  , 
     Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2) [Returns] ,
    Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2)
                 - Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2)[total_qty],
    ((Round(SUM(cast( case when T.Qty < 0 then T.Qty  else 0 end as float)),2))/
                  (Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2)
                 - Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2)))*100[%_Returns],
    ((Round(SUM(cast( case when T.Qty > 0 then T.Qty  else 0 end as float)),2))/
                  (Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2)
                 - Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2)))*100[%_Sales]
    from TRANC as T
    INNER JOIN PRODUCT as P ON T.prod_subcat_code = P.prod_sub_cat_code
    group by P.prod_subcat
    order by [Sales] desc
--11.	For all customers aged between 25 to 35 years find what is the 
--net total revenue generated by these consumers in last 30 days of 
--transactions from max transaction date available in the data?
select sum(total_amt)[Total Revenue]  from TRANC T inner join CUSTOMER C on T.cust_id=C.customer_Id
where cust_id in (select customer_Id from CUSTOMER
where DATEDIFF(YYYY,DOB,(select max(tran_date)from TRANC)) between 25 AND 35 )
and
tran_date in (select tran_date from TRANC where
DATEDIFF(DD,tran_date,(select max(tran_date)from TRANC))<31)

--alternate way
select sum(T3.Revenue)[Total Revenue] from
(select cust_id,sum(total_amt) as [Revenue],DATEDIFF(YY,DOB,(select max(tran_date)from TRANC)) as [Age]
from TRANC T inner join CUSTOMER C on T.cust_id=C.customer_Id
where DATEDIFF(YY,DOB,(select max(tran_date)from TRANC)) between 25 and 35
and tran_date between DATEADD(D,-30,(select max(tran_date)from TRANC)) and (select max(tran_date)from TRANC)
group by cust_id,DOB
) as T3


--12.	Which product category has seen the max value of returns in the last 3 months of transactions?
select top 1
 P.prod_cat,sum(Qty)[no of returns] 
from PRODUCT P inner join TRANC T on P.prod_cat_code=T.prod_cat_code and P.prod_sub_cat_code=T.prod_subcat_code
where Qty<0 and tran_date in (select tran_date from TRANC where
DATEDIFF(MM,tran_date,(select max(tran_date)from TRANC))<3)
group by P.prod_cat
order by [no of returns]


--13.	Which store-type sells the maximum products; by value of sales amount and by quantity sold?

select TOP 1
Store_type,sum(total_amt)as Total_Sales_Value,sum(Qty) as Total_Quantity from TRANC
group by Store_type
order by Total_Sales_Value desc

--14.	What are the categories for which average revenue is above the overall average.

select  P.prod_cat,avg(total_amt) as [Average Revenue] from
PRODUCT P inner join TRANC T on P.prod_cat_code=T.prod_cat_code and P.prod_sub_cat_code=T.prod_subcat_code
group by P.prod_cat
having avg(total_amt)>(select avg(total_amt) from TRANC)


--15.	Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.

select 
P.prod_cat,P.prod_subcat,AVG(total_amt) as Average_Revenue,sum(total_amt) as Total_Revenue from 
PRODUCT P inner join TRANC T on P.prod_cat_code=T.prod_cat_code and P.prod_sub_cat_code=T.prod_subcat_code 
where P.prod_cat in 
(select prod_cat from 

(select top 5 prod_cat,sum(Qty) as Total_Quantity from 
PRODUCT P inner join TRANC T on P.prod_cat_code=T.prod_cat_code and P.prod_sub_cat_code=T.prod_subcat_code
group by prod_cat
order by Total_Quantity desc
) as T5 )

group by P.prod_cat,P.prod_subcat
order by P.prod_cat



