Create Dimension Table

CREATE OR REPLACE TABLE CUSTOMER_SCD1 (
    CUSTOMER_ID INT,
    CUSTOMER_NAME STRING,
    EMAIL STRING
);

Insert Initial Data

INSERT INTO CUSTOMER_SCD1 VALUES
(1, 'Alice', 'alice@gmail.com');


Change happens (email updated)

UPDATE CUSTOMER_SCD1
SET EMAIL = 'alice@yahoo.com'
WHERE CUSTOMER_ID = 1;

Result

SELECT * FROM CUSTOMER_SCD1;
