SCD TYPE 3 (Limited History – Extra Column)

Create Dimension Table

CREATE OR REPLACE TABLE CUSTOMER_SCD3 (
    CUSTOMER_ID INT,
    CUSTOMER_NAME STRING,
    CURRENT_EMAIL STRING,
    PREVIOUS_EMAIL STRING
);


Insert Initial Data

INSERT INTO CUSTOMER_SCD3 VALUES
(1, 'Alice', 'alice@gmail.com', NULL);


Change happens (email updated)

UPDATE CUSTOMER_SCD3
SET PREVIOUS_EMAIL = CURRENT_EMAIL,
    CURRENT_EMAIL = 'alice@yahoo.com'
WHERE CUSTOMER_ID = 1;


Result

SELECT * FROM CUSTOMER_SCD3;
