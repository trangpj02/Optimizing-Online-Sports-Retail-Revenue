-- Count all columns and non-missing entries

select 
  count(*) as total_rows, 
  count(description) as count_description, 
  count(listing_price) as count_listing_price, 
  count(last_visited) as count_last_visited,
  count(reviews) as count_review
from 
  info i 
  inner join finance f on i.product_id = f.product_id 
  inner join traffic t on i.product_id = t.product_id
  inner join review r on i.product_id = r.product_id

-- Brands and listing price aggregation

select 
  brand, 
  convert(int, listing_price) as listing_price_int, 
  count(*) as count 
from 
  finance f 
  inner join brands b on f.product_id = b.product_id 
where 
  listing_price > 0 
group by 
  brand, 
  listing_price 
order by 
  listing_price desc;

-- Price category

select 
  brand, 
  count(*) as total_product, 
  sum(revenue) as total_revenue, 
  case when listing_price < 42 then 'Low' 
       when listing_price < 74 then 'Medium' 
	   when listing_price < 129 then 'High' else 'Elite' 
	   end as price_category 
from 
  brands b 
  inner join finance f on b.product_id = f.product_id 
where 
  brand is not null 
group by 
  brand,
  case when listing_price < 42 then 'Low' 
       when listing_price < 74 then 'Medium' 
	   when listing_price < 129 then 'High' 
	   else 'Elite' end 
order by 
  total_revenue desc;

-- Average discount by brand

select 
  brand,
  round(avg(discount)*100, 0) as average_discount
from 
  brands b
  inner join finance f on b.product_id = f.product_id
where
  brand is not null
group by brand
order by average_discount;

-- Correlation between reviews and revenue

with Stats as (
    select 
        count(*) as N,
        sum(reviews) as sumReviews,
        sum(revenue) as sumRevenue,
        sum(reviews * revenue) as sumReviewsRevenue,
        sum(reviews * reviews) as sumReviews2,
        sum(revenue * revenue) as sumRevenue2
    from review r
	inner join finance f on r.product_id = f.product_id
)
select
    round((N * sumReviewsRevenue - sumReviews * sumRevenue) / 
    (sqrt(N * sumReviews2 - sumReviews * sumReviews) * sqrt(N * sumRevenue2 - sumRevenue * sumRevenue)), 2) as review_revenue_corr
from Stats;

-- Description length and average rating

select
  floor(len(description)/100)*100  AS description_length,
  round(avg(cast(rating as float)), 2) as average_rating
from 
  info i
  inner join review r on i.product_id = r.product_id
where
  description is not null
group by 
  floor(len(description)/100)*100
order by
  description_length;

-- Number of reviews by brand and month

select
  brand,
  month(last_visited) as month,
  count(*) as num_reviews
from 
  brands b
  inner join traffic t on b.product_id = t.product_id
  inner join review r on b.product_id = r.product_id
where 
  brand is not null 
  and month(last_visited) is not null
group by 
  brand,
  month(last_visited)
order by 
  brand, 
  month;

-- Top 10 highest revenue products

with highest_revenue_product as (
    select
	   product_name,
	   brand,
	   revenue
	from
	   info i
	   inner join brands b on i.product_id = b.product_id
	   inner join finance f on i.product_id = f.product_id
	where
	   product_name is not null
	   and revenue is not null
	   and brand is not null
)
select
   top 10 *,
   rank() over (order by revenue desc) as product_rank
from highest_revenue_product;
 
-- Median revenue for footwear products

with footwear as (
    select 
        description,
        revenue
    from
        info i
        inner join finance f on i.product_id = f.product_id
    where
        (description like '%shoe%'
        or description like '%trainer%'
        or description like '%foot%')
        and description is not null
)
select 
   distinct round(percentile_disc(0.5) within group (order by revenue) over(), 2) as median_footwear_revenue,
   count(*) over() as num_footwear_product
from 
    footwear;

-- Median revenue for non-footwear products

with footwear as (
    select
        description,
        revenue
    from
        info i
        inner join finance f on i.product_id = f.product_id
    where
        (description like '%shoe%'
        or description like '%trainer%'
        or description like '%foot%')
        and description is not null
)
select 
   distinct round(percentile_disc(0.5) within group (order by revenue) over(), 2) as median_clothing_revenue,
   count(*) over() as num_of_products
from
   info i
   inner join finance f on i.product_id = f.product_id
where
   i.description not in (select description from footwear);