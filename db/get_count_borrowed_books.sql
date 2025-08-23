DROP FUNCTION IF EXISTS get_borrowed_books_count;

DELIMITER $$
CREATE FUNCTION get_borrowed_books_count(p_start DATE, p_end DATE)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) 
    INTO v_count
    FROM checkout
    WHERE borrow_date BETWEEN p_start AND p_end;

    RETURN v_count; -- return number of browwed books on a give time range
END $$
DELIMITER ;
