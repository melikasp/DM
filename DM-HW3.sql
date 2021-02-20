use pubs;

#1:
select * from publishers 
where exists 
(select *  from titles where titles.pub_id = publishers.pub_id and type = 'business');

create index i_type on titles(type);
drop index i_type on titles;


#2:
select * , case when title_id in (select titles.title_id 
from titles inner join sales on sales.title_id = titles.title_id 
group by titles.title_id 			
having sum(qty*price) > 500) then price * 1.1				      else price * .95	
end as newPrice
from titles
order by price desc;

#3:
select * , case 
when SaleAmount < 200  then 0			  
when SaleAmount < 500  then 0 + (SaleAmount - 200)  * .05			  
when SaleAmount < 800  then 0 + 15 + (SaleAmount - 500)  * .10		
when SaleAmount < 1000 then 0 + 15 + 30 + (SaleAmount - 800)  * .15		
else 0 + 15 + 30 + 30 + (SaleAmount - 1000) * .20   		 
end as Tax 	 
from (select titles.title_id , title , sum(qty*price) as SaleAmount from sales
 inner join titles on titles.title_id = sales.title_id 		
group by titles.title_id , title) as d
order by Tax Desc;

#4:
select  pub_name  , YEAR(ord_date) as Year , sum(qty * price ) as TotalSale	
from sales inner join titles on titles.title_id = sales.title_id
                inner join publishers on publishers.pub_id = titles.pub_id group by  pub_name , YEAR(ord_date);

#5:
select * from authors 
where au_id not in (select au_id from titleauthor); 

#6:
select titles.title_id , title , Count(au_id) as CountAu	
from titles 
inner join titleauthor  on titleauthor.title_id = titles.title_id 
group by titles.title_id , title 
having  Count(au_id) > 1
order by 3;


