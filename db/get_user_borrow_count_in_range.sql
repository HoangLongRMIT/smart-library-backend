DROP FUNCTION IF EXISTS get_user_borrow_count_in_range;
DELIMITER $$
CREATE FUNCTION get_user_borrow_count_in_range(
    p_user_id INT,
    p_start   TIMESTAMP,
    p_end     TIMESTAMP
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*)
      INTO v_count
      FROM checkout
     WHERE user_id = p_user_id
       AND borrow_date >= p_start
       AND borrow_date <  p_end;

    RETURN COALESCE(v_count, 0);
END$$
DELIMITER ;
