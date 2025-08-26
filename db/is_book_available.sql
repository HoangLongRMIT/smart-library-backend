DROP FUNCTION IF EXISTS is_book_available;

DELIMITER $$
CREATE FUNCTION is_book_available(p_book_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_copies INT;

    SELECT available_copies 
    INTO v_copies
    FROM book
    WHERE book_id = p_book_id;
    
    -- return true if the copies is greater than 0 or else return false
    RETURN v_copies > 0; 
END $$
DELIMITER ;
