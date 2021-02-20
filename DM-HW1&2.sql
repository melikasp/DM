## Course: Data Managment for Data Science
## DMDS HW1
## Group members: Melika Parpinchi, 1880156, Mousaalreza Dastmard, 1852433
## Dataset info: https://relational.fit.cvut.cz/dataset/Pubs
use pubs;
##-------------------------------------------------------------------------------------------------------------------
## Q1&2-1: List of publishers that don't have business book
## Using “not exists”:
select * 
from publishers 
where not exists 
	(select * 
	 from titles 
     where titles.pub_id = publishers.pub_id and type = 'business');
## There 4 publishers located in the USA and two in Germany and France

## Optimizing (Using View and index):
create index i_type on titles(type);
drop index i_type on titles;
create view business_pub_ids as 
select pub_id 
    from titles 
    where type = 'business';

## Using “not in”:
select * 
from publishers 
where pub_id not in 
	(select * 
    from business_pub_ids 
);

##-------------------------------------------------------------------------------------------------------------------
## Q1-2: List of publishers that have published books that have mod in their type
## Using “exists”, “Like”:
select *
from publishers 
where  exists
	(select *
    from titles 
    where type like '%mod%');

## Mostly the publishers have books of type %mod% are located in the USA
##-------------------------------------------------------------------------------------------------------------------     
## Q1-3: Rasing the price by 10% for those books have total sale more than 500 Else decreasing by 5%
## Using “case when”, “group by”, “having” :
select * ,
	case when title_id in (select titles.title_id 
							from titles inner join 
								 sales on sales.title_id = titles.title_id 
								 group by titles.title_id 
								 having sum(qty*price) > 500)	then price * 1.1
																else price * .95
	end as newPrice
from titles ;
## Comparing the columns price and newPrice we can see that mostly the new calculated price is less than previous price.
##-------------------------------------------------------------------------------------------------------------------
## Q1-4: TAX calculation for each book based on total sale
## If total sale is less than 200 then TAX = 0
## If total sale is less than 500 then TAX = (Total sale - 200)*5%
## If total sale is less than 800 then TAX = 15 + (Total sale - 500)*10%
## If total sale is less than 1000 then TAX = 45 + (Total sale - 800)*15%
## else TAX = 75 + (Total sale - 1000)*20%
## Using “case when”, “drived query”, “group by”
select * ,
		 case when SaleAmount < 200  then 0
			  when SaleAmount < 500  then 0 +				 (SaleAmount - 200)  * .05
			  when SaleAmount < 800  then 0 + 15 +			 (SaleAmount - 500)  * .10
			  when SaleAmount < 1000 then 0 + 15 + 30 +		 (SaleAmount - 800)  * .15
									 else 0 + 15 + 30 + 30 + (SaleAmount - 1000) * .20   
		 end as Tax 
	 from 
		(select titles.title_id , title , sum(qty*price) as SaleAmount
		from sales inner join titles on titles.title_id = sales.title_id 
		group by titles.title_id , title) as d ;
## Rarely we can find publishers that have to pay TAX more than 100$ based on TAX scenario defined above.
## And there exist publishers have not to pay TAX.
##-------------------------------------------------------------------------------------------------------------------        
## Q1-5: Total Sale of publishers in diffrent years and in overall.
## Using “group by”, “rollup”, “YEAR”, “sum”:
	select  pub_name  , YEAR(ord_date) as Year , sum(qty * price ) as TotalSale
	from sales inner join 
		 titles on titles.title_id = sales.title_id inner join 
		 publishers on publishers.pub_id = titles.pub_id 
	group by  pub_name , YEAR(ord_date)
	with rollup;
## The ROLLUP generates the subtotal row every time the product line changes and the grand total at the end of the result.
## There are only 3 publishers that have sold books listed in titles table
## The results shows that each publishers almost sold same amount of books
## And the total sold per year is decreasing 
##-------------------------------------------------------------------------------------------------------------------    
## Q1&2-6: List of authors that don't have books
## Using “is null” :
select * 
from authors 
left join titleauthor on titleauthor.au_id = authors.au_id 
where title_id is null; ##join

## Optimizing (Subquery instead of join):
select * 
from authors 
where au_id not in 
	(select au_id 
    from titleauthor); ##subquery
## There are 4 autors that haven't published any book yet
##-------------------------------------------------------------------------------------------------------------------
## Q1-7: List of books that have at least 2 authors in ascend order 
## Using “Count”, “group by”, “having”, “order by”:
select titles.title_id , title , Count(au_id) as CountAu
	from titles 
		inner join titleauthor  on titleauthor.title_id = titles.title_id 
group by titles.title_id , title 
having  Count(au_id) > 1
order by 3;
## Among those books have at least two co-authors, there is only one book with 3 authors and the remain books have only two co-authors

##-------------------------------------------------------------------------------------------------------------------
## Q1&2-9: Pricing book based of various conditions:
## if publisher located in California then increase price by 10% 
## if the book has more than 1 authors then increase price by 5%
## if the book is sold more than 200$ then increase price by 2%
## else decrease price by 1%  
## Using “where”, “group by”, “sum”, "ELSE case when":
select title_id , title  , 
		 case when pub_id in   (select pub_id from publishers where state = 'CA')							then price * 1.1 
	else case when title_id in (select title_id from titleauthor group by title_id having count(*) > 1) then price * 1.05
	else case when title_id in (select titles.title_id 
									from titles inner join 
								 sales on sales.title_id = titles.title_id 
								 group by titles.title_id 
								 having sum(qty*price) > 200)											then price * 1.02
																										else price * .99
	end end end as newPrice
from titles ;

## Optimizing (Using view):
create view titleauthor_view as
select title_id from titleauthor group by title_id having count(*) > 1;
create view title_view as  
select titles.title_id 
									from titles inner join 
								 sales on sales.title_id = titles.title_id 
								 group by titles.title_id 
								 having sum(qty*price) > 200;

## Using “where”, "view":
select title_id , title  , 
		 case when pub_id in   (select pub_id from publishers where state = 'CA')							then price * 1.1 
	else case when title_id in (select * from titleauthor_view) then price * 1.05
	else case when title_id in (select * from title_view)											then price * 1.02
																										else price * .99
	end end end as newPrice
from titles ;

##-------------------------------------------------------------------------------------------------------------------
## Q2-10: Modifying employee table in order to have boss of each employee  
## Optimizing (Using View and index and check constraint):
create view boss_view as
select emp_id, fname, minit, lname,
case when job_lvl > 150 then 'Maria Pontes'
						else 'Francisco Chang'
	end as boss, job_id, job_lvl, pub_id, hire_date
from employee;
select * from boss_view;

## Modifying table employee:
SET SQL_SAFE_UPDATES = 0;
alter table employee ADD 
    boss varchar(50) check (boss in ('Francisco Chang','Maria Pontes'))
    AFTER lname;
alter table employee drop boss;
alter table employee modify hire_date date;
update employee
SET  boss = 'Maria Pontes'
WHERE job_lvl > 150;
update employee
SET boss = 'Francisco Chang'
WHERE job_lvl <= 150;

select * from employee;

##--------------------------------------------------------------------------------------------------------------------
## Q2-11: Migrating the jobs data into JobR which has integrity constraints and hope to make query faster from JobR 
## Lets suppose that jobs table is not well-disgned. We migrate the data in jobs table into JobR table and add constrain on values on creation of the table. 
## Optimizing (Using Integrity Constrains):
create table JobR (jobID int Primary Key, JobDesc varchar(50) unique, MinLvl tinyint not null, MaxLvl tinyint not null);
insert into JobR select * from jobs where max_lvl > 100;
select * from JobR;
select * from Jobs;
##-------------------------------------------------------------------------------------------------------------------
## Q1&2-8: Total sale of business books
## Using “where”, “group by”, “sum”:
select titles.title_id , title , sum(qty*price) as TotalSale 
	from titles inner join 
		 sales on sales.title_id = titles.title_id 
		 where type = 'business'
		 group by  titles.title_id , title;

## Optimizing (Using View):
create view title_sale_view as 
select titles.title_id , title, type , sum(qty*price) as TotalSale
	from titles inner join 
		 sales on sales.title_id = titles.title_id 
		 group by  titles.title_id , title , type
		 having type = 'business';
         
## Using “where”, “view”:
select title_id , title , TotalSale 
from title_sale_view 		 
where type = 'business';
## There are only 4 books of type business that 3 of them have been sold about 300$ and the book titled "You Cna Combat Comuter Stress!" has been sold just above 100$