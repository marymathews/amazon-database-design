-- Procedure to check whether a discount from the daily deals is applicable when placing an order
CREATE OR REPLACE PROCEDURE APPLY_DAILY_DEALS (
    CART           IN      CART.CART_ID%TYPE,
    O_DATE         IN      ORDERS.ORDER_DATE%TYPE,
    MINIMUM_PRICE  IN      CART.TOTAL_PRICE%TYPE,
    TOTAL          IN OUT  CART.TOTAL_PRICE%TYPE
) AS

    CURSOR PRODUCTS IS
    SELECT
        *
    FROM
        CART_ITEMS
    WHERE
        CART_ID = CART;

    THIS_PRODUCT      PRODUCTS%ROWTYPE;
    DISCOUNT_PERCENT  DAILY_DEALS.DISCOUNT%TYPE;
    ITEM_PRICE        PRODUCT.PRICE%TYPE;
    ITEM_DISCOUNT     NUMBER;
BEGIN
    OPEN PRODUCTS;
    LOOP
        FETCH PRODUCTS INTO THIS_PRODUCT;
        EXIT WHEN ( PRODUCTS%NOTFOUND );
        BEGIN
            SELECT
                DISCOUNT
            INTO DISCOUNT_PERCENT
            FROM
                DAILY_DEALS DD
            WHERE
                DD.P_ID = THIS_PRODUCT.P_ID
                AND DD.DEAL_DATE = O_DATE;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DISCOUNT_PERCENT := 0;
        END;

        SELECT
            PRICE
        INTO ITEM_PRICE
        FROM
            PRODUCT
        WHERE
            P_ID = THIS_PRODUCT.P_ID;

        FOR IND IN 1..THIS_PRODUCT.QTY LOOP
            ITEM_DISCOUNT := ( DISCOUNT_PERCENT / 100 ) * ITEM_PRICE;
            TOTAL := TOTAL - ITEM_DISCOUNT;
        END LOOP;

        IF TOTAL < MINIMUM_PRICE THEN
            TOTAL := MINIMUM_PRICE;
        END IF;
    END LOOP;

    CLOSE PRODUCTS;
END APPLY_DAILY_DEALS;
