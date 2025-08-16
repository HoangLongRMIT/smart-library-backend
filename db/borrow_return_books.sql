/*
Create stored procedures to handle: 
• Borrow a Book 
• Return a Book

Implement triggers to automate: 
• When a book is borrowed and returned, book metadata should be updated 
automatically

Use transaction and concurrency management in the following processes: 
• Borrow a Book (for example, two or more readers borrow the last book at the same 
time, etc.)
*/

-- STORED PROCEDURES
/*
Procedure: borrow_book
Params: user_id INT, book_id INT
Returns: none
Desc: Procedure for handling book borrow
*/
DELIMITER $$ 

CREATE PROCEDURE borrow_book(IN user_id INT, IN book_id INT)
BEGIN
    DECLARE copies_left INT;

    -- rollback on any sql exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;

    START TRANSACTION;
    -- verify that book is still available
    SELECT available_copies 
    INTO copies_left
    FROM books b 
    WHERE b.id = book_id    
    FOR UPDATE  -- lock the row to prevent dirty read

    -- throws if no copies left
    IF copies_left <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = "No available copies left";
    END IF;

    -- insert borrow checkout
    INSERT INTO checkout(user_id, book_id, borrow_date) 
    values (user_id, book_id, CURRENT_TIMESTAMP);

    COMMIT;
END $$

DELIMITER ;

/*
Procedure: return_book
Params: checkout_id INT
Returns: none
Desc: Procedure for handling book return using checkout transaction ID
*/
DELIMITER $$

CREATE PROCEDURE return_book(IN p_checkout_id INT)
BEGIN
    DECLARE v_borrow_date TIMESTAMP;
    DECLARE v_return_date TIMESTAMP;
    DECLARE v_is_late BOOLEAN;

    -- rollback on any sql exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- fetch borrow date and return date
    SELECT borrow_date, return_date
    INTO v_borrow_date, v_return_date
    FROM checkout
    WHERE id = p_checkout_id;

    -- throws if already returned
    IF v_return_date IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Already returned checkout';
    END IF;

    -- calculate if returned late
    SET v_is_late = TIMESTAMPDIFF(DAY, v_borrow_date, CURRENT_TIMESTAMP) > 7;

    -- update checkout
    UPDATE checkout
    SET return_date = CURRENT_TIMESTAMP,
        is_late = v_is_late
    WHERE id = p_checkout_id;

    COMMIT;
END$$

DELIMITER ;



-- TRIGGER
/*
Trigger: ins_checkout
Desc: Update book metadata after a borrow
*/
DELIMITER $$

CREATE TRIGGER ins_checkout
AFTER INSERT ON checkout
FOR EACH ROW
BEGIN
    -- guard
    IF NEW.borrow_date IS NOT NULL AND NEW.return_date IS NULL THEN
        -- decrease available_copies after borrow
        UPDATE books 
        set available_copies = available_copies - 1
        where books.id = NEW.book_id;
    END IF;
end $$

DELIMITER ;

/*
Trigger: upd_checkout
Desc: Update book metadata after a borrow
*/
DELIMITER $$

CREATE TRIGGER upd_checkout
AFTER UPDATE ON checkout
FOR EACH ROW
BEGIN
    -- guard
    IF NEW.return_date IS NOT NULL THEN AND OLD.return_date IS NULL
        -- increase available_copies after return
        UPDATE books 
        set available_copies = available_copies + 1
        where books.id = NEW.book_id;
    END IF;
end $$

DELIMITER ;