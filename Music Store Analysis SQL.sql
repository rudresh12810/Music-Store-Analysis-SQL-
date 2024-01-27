create database music_Database;
use music_Database;
show tables;




--                Question Set 1 - Easy
-- 1. Who is the senior most employee based on job title?
select * from employee;
select distinct title from employee;


select *  from employee
order by levels desc
limit 1;

-- 2. Which countries have the most Invoices?

select * from invoice;

select billing_country, count(invoice_id) invoice 
from invoice
group by billing_country
limit 3 ;


-- 3. What are top 3 values of total invoice?

select invoice_id , total
from invoice
order by total desc;



 
/*4. Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals              */



select * from invoice ;

select billing_city, sum(total) total
from invoice 
group by billing_city
order by total desc	;






/*5. Who is the best customer? The customer who has spent the most money will be 
declared the best customer. Write a query that returns the person who has spent the 
most money  */

select customer_id, concat(first_name," ",last_name)as Name , sum(total) as Invoice_amount 
from Customer c
join invoice i 
using(customer_id)
group by customer_id,Name
order by Invoice_amount desc ;


							-- Question Set 2 – Moderate
/*1. Write query to return the email, first name, last name, & Genre of all Rock Music 
listeners. Return your list ordered alphabetically by email starting with A										*/

select * from customer;
select * from invoice ;
select * from invoice_line ;
select * from track;
select * from genre;

select distinct c.email , concat(c.first_name," ",c.last_name)as Name 
from customer c 
join invoice i on c.customer_id = i.customer_id  
join invoice_line inv on    i.invoice_id = inv.invoice_id                 
where track_id in (select track_id 
					from track t
					join genre g  on t.genre_id = g.genre_id              
					where g.name = 'Rock')
order by email;
 



/*2. Let's invite the artists who have written the most rock music in our dataset. Write a 
query that returns the Artist name and total track count of the top 10 rock bands							*/

select * from artist;
select * from album ;
select * from track;
select * from genre;

select artist.name , count(track_id) Total_Track
from artist
join album  on artist.artist_id= album.artist_id
join track on album.album_id = track.album_id
join genre on track.genre_id = genre.genre_id
where genre.name = 'rock'
group by artist.name
order by Total_track desc
limit 10;


/*
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id,artist.name
ORDER BY number_of_songs DESC
limit 10;					*/





 
/*3. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the 
longest songs listed first										*/



select track_id, name, Milliseconds
from track 
where Milliseconds > (select avg(Milliseconds) from track)
order by Milliseconds desc;






					-- 	  Question Set 3 – Advance
/*1. Find how much amount spent by each customer on artists? Write a query to return
customer name, artist name and total spent  */

WITH best_selling_artist AS (
	Select artist.artist_id AS artist_id, artist.name AS artist_name,
    SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM invoice_line
    Join track ON track.track_id = invoice_line.track_id
    Join album ON album.album_id = track.album_id
    Join artist ON artist.artist_id = album.artist_id 
    Group By artist.artist_id,artist.name			-- OR 		Group By 1
	Order By total_sales desc						-- OR 		Order By 3 Desc 
    Limit 1
)
Select c.customer_id, c.first_name, c.last_name, bsa.artist_name,
	Sum(il.unit_price * il.quantity) As amount_spent
From invoice i
Join Customer c ON c.customer_id = i.customer_id
Join invoice_line il ON il.invoice_id = i.invoice_id
Join track t ON t.track_id = il.track_id
Join album alb ON alb.album_id = t.album_id
Join best_selling_artist bsa ON bsa.artist_id = alb.artist_id
Group by 1,2,3,4
Order by 5 desc;  -- coulumn number 





/*2. We want to find out the most popular music Genre for each country. We determine the 
most popular genre as the genre with the highest amount of purchases. Write a query 
that returns each country along with the top Genre. For countries where the maximum 
number of purchases is shared return all Genres       */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


# Method 2

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;














/*3. Write a query that determines the customer that has spent the most on music for each 
country. Write a query that returns the country along with the top customer and how
much they spent. For countries where the top amount spent is shared, provide all 
customers who spent this amount            */


/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1;


/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;




