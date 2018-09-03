SELECT sub.last_name,
       sub.first_name
FROM   (SELECT customer.last_name,
               customer.first_name
        FROM   customer
        WHERE  customer.age > '30') AS sub
        
