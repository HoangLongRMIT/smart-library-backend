DROP FUNCTION IF EXISTS get_count_borrowed_books;

DELIMITER $$
CREATE FUNCTION get_count_borrowed_books(p_start DATE, p_end DATE)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) 
    INTO v_count
    FROM checkout
    WHERE borrow_date BETWEEN p_start AND p_end;
    
    -- return number of browwed books on a give time range
    RETURN v_count; 
END $$
DELIMITER ;
