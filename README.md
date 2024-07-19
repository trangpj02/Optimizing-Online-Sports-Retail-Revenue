# Optimizing Online Sports Retail Revenue

![image](https://github.com/user-attachments/assets/30f49844-80c5-4d91-9588-ce6d32091328)

# **Project Description**

This project leverages SQL to uncover insights from an online sports retailer's product data. By employing essential techniques like aggregation, data cleaning, labeling, Common Table Expressions (CTEs), and correlation, we can extract valuable information. Our goal is to empower the marketing and sales teams with actionable recommendations to drive revenue growth.aa

# **Data Overview**

Data sources: [**here**](https://www.kaggle.com/datasets/irenewidyastuti/datacamp-optimizing-online-sports-retail-revenue)

The dataset contains five tables, with `product_id` being the primary key for all of them:

![Screenshot (51)](https://github.com/user-attachments/assets/01b03eb4-961d-490a-ac22-e3ff99caa7f2)

# **Analysis and Insights:**

## Counting missing values

```sql-server
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
  inner join review r on i.product_id = r.product_id;
```

*Results:*

![image](https://github.com/user-attachments/assets/2cedb179-c38d-44ec-9bce-d7c1e751410b)

We have a total of 3,179 products in the database and over 5% of `last_visited` values are missing.

## Pricing

How do the price points of Nike and Adidas products differ? This question helps to build a picture of the company’s stock range and customer market.

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/2432a4b9-daae-420c-81b1-b8bd7d56325a)
…

![image](https://github.com/user-attachments/assets/eab1919f-ee7f-4ad6-b06d-ccf32caa8666)

There are 77 unique prices points across Nike and Adidas products.

Categorize the price into ranges will help understand product distribution better. This approach will allow us to see:

- which price segments each brand should focuses on
- how their pricing strategies compare

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/4a7283fe-b60d-4109-a772-33f699070ccc)

Adidas items generate more revenue overall, with "Elite" products priced at $129 or more contributing the most.

Based on this, Adidas could potentially increase revenue by focusing on a higher proportion of these high-priced products in their inventory.

## Discount

`listing_price` may not reflect the final selling price. To better understand `revenue`, we should examine the `discount`, which is the percentage reduction from the listing price at sale. We aim to see if discount amounts vary between brands, as this could influence revenue.

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/d51a5bac-6f5a-48fa-8777-f8034f1f348d)

Interestingly, Nike products appear to have no discounts. In contrast, not only do Adidas products generate the most revenue, but they also have substantial discounts.

Actionable insights:

- Adidas: Reducing the discount rate on Adidas products could potentially increase revenue, but monitor sales volume to ensure stability.
- Nike: Experiment with offering a small discount on Nike products. This might decrease average revenue per item but could increase overall revenue if sales volume rises.

## Reviews and Revenue:

Is there any correlation between `revenue` and `reviews`? And if so, how strong is it?

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/57cede9a-6650-4d77-9681-e13aafb1d6d8)

Interestingly, a strong positive correlation exists between `revenue` and `reviews`. This means, potentially, if we can get more reviews on the company's website, it may increase sales of those items with a larger number of reviews.

- Actionable Insight: Implement strategies to encourage customer reviews. Ideas include:
- Offering a small discount or some benefits on future purchases for reviews.
- Running experiments with different sales processes that incentivize reviews.

## Product Reviews and Ratings:

Does the length of a product's `description` influence a product's `rating` and `reviews`? If yes, the company can produce content guidelines for listing products on their website and test if the influences revenue.

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/3d97451a-5ddd-4306-a857-52310fce2d2e)

Regrettably, it appears that there isn't a clear, discernible pattern between product description length and ratings.

## Review Volume and Trends:

As we know a correlation exists between `reviews` and `revenue`, one approach the company could take is to run experiments with different sales processes encouraging more reviews from customers about their purchases, such as by offering a small discount on future purchases.

Let’s take a look at the volume of `reviews` by month to see if there are any trends or gaps we can look to exploit.

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/0c9ebbb1-bb56-40d7-a2fe-4d3005c30e24)

It appears that product `reviews` are most abundant during the first quarter of the calendar year (Q1). This presents a golden opportunity to experiment with strategies that can maintain or even increase review volume throughout the rest of the year.

## Top Revenue Generators: Footwear Takes the Lead

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/5866dc45-1224-46da-b3ca-d6a25b18ff6c)

Among the top ten revenue-generating products by brand, Nike stands out with sales around $64k. Notably, footwear is the top revenue-generating product category.

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/ba0fac87-6e92-4ace-b45f-b8cfb65dfd2c)

Digging deeper into footwear performance, we see that footwear makes up a significant portion of the company's inventory, at roughly 85% (2,700 out of 3,117 products). Furthermore, the median revenue for footwear products is over $3,000.

While the median revenue for footwear is interesting, it doesn't tell us the whole story. Without a point of reference, it's hard to judge if this is a good or bad performance. To gain a clearer picture, let's compare the median revenue of footwear to clothing products.

```sql-server
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
```

*Results:*

![image](https://github.com/user-attachments/assets/90544bfe-d69b-411a-b882-7731d7aa5b66)

Our analysis reveals 417 clothing products in the dataset, with a median revenue of $503.82.

Insights:

- Growth Potential in Clothing: The clothing category presents significant room for revenue growth.
- Short-Term Optimization: Focusing on footwear would likely yield the highest return on investment (ROI) in the short term due to its higher median revenue.
- Long-Term Strategy: For long-term growth, diversifying and investing in clothing, which has a lower median revenue but significant growth potential, can help ensure long-term stability and growth.

# **Conclusion**

1. Premium Product Development: Explore opportunities in the "High" and "Elite" categories to tap into higher revenue potential.
2. Strategic Discounting: Since footwear generates the highest revenue, consider offering fewer discounts on these products. This strategy can then be balanced by offering more attractive discounts on clothing to boost sales and revenue in that category.
3. Continuously monitor performance for categories like footwear and clothing. Use this data to make informed adjustments to pricing strategies and marketing campaigns to optimize results.
4. Focus on product quality, exceptional customer service, and holistic marketing strategies. This will not only improve customer reviews but also lead to increased revenue.
5. Analyzing factors that influence monthly review fluctuations and planning appropriate marketing strategies.
6. Using this data as a foundation to design more effective and customer-oriented business strategies.

By implementing these recommendations, the brand can enhance product performance
