-- Trigger to update the inventory when an order is placed 
CREATE OR REPLACE TRIGGER UPDATE_INVENTORY BEFORE
    INSERT ON ORDERS
    FOR EACH ROW
DECLARE
    CURSOR ITEMS IS
    SELECT
        CI.P_ID,
        CI.QTY
    FROM
        CART_ITEMS CI,
        CART
    WHERE
        CI.CART_ID = CART.CART_ID
        AND CART.BUYER_ID = :NEW.BUYER_ID;

    THIS_ITEM  ITEMS%ROWTYPE;
    NEW_QTY    NUMBER := 0;
    OLD_QTY    NUMBER;
BEGIN
    OPEN ITEMS;
    LOOP
        FETCH ITEMS INTO THIS_ITEM;
        EXIT WHEN ( ITEMS%NOTFOUND );
        SELECT
            QTY
        INTO OLD_QTY
        FROM
            PRODUCT
        WHERE
            P_ID = THIS_ITEM.P_ID;

        NEW_QTY := OLD_QTY - THIS_ITEM.QTY;
        IF NEW_QTY < 0 THEN
            RAISE_APPLICATION_ERROR(
                                   -20000,
                                   'Not enough stock'
            );
        END IF;
        UPDATE PRODUCT
        SET
            QTY = NEW_QTY
        WHERE
            P_ID = THIS_ITEM.P_ID;

    END LOOP;

    CLOSE ITEMS;
END;

-- Trigger to reset a user's cart after an order is placed
CREATE OR REPLACE TRIGGER EMPTY_CART AFTER
    INSERT ON ORDERS
    FOR EACH ROW
DECLARE
    CID CART.CART_ID%TYPE;
BEGIN
    SELECT
        CART_ID
    INTO CID
    FROM
        CART
    WHERE
        BUYER_ID = :NEW.BUYER_ID;

    DELETE FROM CART_ITEMS
    WHERE
        CART_ID = CID;

    UPDATE CART
    SET
        CART.TOTAL_QTY = 0,
        CART.TOTAL_PRICE = 0
    WHERE
        CART_ID = CID;

END;


-- Trigger to update total quantity and total price of the cart when an item is added
CREATE OR REPLACE TRIGGER UPDATE_CART_DETAILS AFTER
    INSERT ON CART_ITEM S
    FOR EACH ROW
DECLARE
    ITEM_PRICE   PRODUCT.PRICE%TYPE;
    ADDED_PRICE  PRODUCT.PRICE%TYPE;
BEGIN
    UPDATE CART
    SET
        TOTAL_QTY = :NEW.QTY + TOTAL_QTY
    WHERE
        CART_ID = :NEW.CART_ID;

    SELECT
        PRICE
    INTO ITEM_PRICE
    FROM
        PRODUCT
    WHERE
        P_ID = :NEW.P_ID;

    ADDED_PRICE := ITEM_PRICE * :NEW.QTY;
    UPDATE CART
    SET
        TOTAL_PRICE = TOTAL_PRICE + ADDED_PRICE
    WHERE
        CART_ID = :NEW.CART_ID;

END;