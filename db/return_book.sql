DROP PROCEDURE IF EXISTS return_book;
DELIMITER $$
CREATE PROCEDURE return_book(IN p_checkout_id INT)
BEGIN
    DECLARE v_borrow_date TIMESTAMP;
    DECLARE v_due_date    TIMESTAMP;
    DECLARE v_return_date TIMESTAMP;
    DECLARE v_is_late     BOOLEAN;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT c.borrow_date, c.due_date, c.return_date
      INTO v_borrow_date, v_due_date, v_return_date
      FROM checkout c
     WHERE c.checkout_id = p_checkout_id
       FOR UPDATE;

    IF v_borrow_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Checkout not found';
    END IF;

    IF v_return_date IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Already returned checkout';
    END IF;

    IF v_due_date IS NOT NULL THEN
        SET v_is_late = (CURRENT_TIMESTAMP > v_due_date);
    ELSE
        SET v_is_late = TIMESTAMPDIFF(DAY, v_borrow_date, CURRENT_TIMESTAMP) > 7;
    END IF;

    UPDATE checkout
       SET return_date = CURRENT_TIMESTAMP,
           is_late     = v_is_late
     WHERE checkout_id = p_checkout_id;

    COMMIT;
END $$
DELIMITER ;