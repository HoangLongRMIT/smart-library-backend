DELIMITER $$
CREATE FUNCTION is_returned_on_time(p_checkout_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_late BOOLEAN;

    SELECT is_late 
    INTO v_late
    FROM checkout
    WHERE checkout_id = p_checkout_id;

    RETURN NOT v_late; -- return true if is_late is false and false if is_late is true
END $$
DELIMITER ;