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
DELIMITER $$ 

CREATE PROCEDURE borrow_book(IN user_id INT, IN book_id INT)
BEGIN
    # Create borrow checkout
    INSERT INTO checkout(user_id, book_id, borrow_data) 
    values (user_id, book_id, CURRENT_TIMESTAMP);
END $$

CREATE PROCEDURE return_book(IN user_id INT, IN book_id INT)
BEGIN
    # Create return checkout
    INSERT INTO checkout(user_id, book_id, return_date) 
    values (user_id, book_id, CURRENT_TIMESTAMP);
END $$

DELIMITER ;

-- TRIGGER
DELIMITER $$

CREATE TRIGGER update_book_metadata
AFTER INSERT ON checkout
FOR EACH ROW
BEGIN
    # Decide whether it's a borrow or return operation
    DECLARE is_borrow BOOLEAN;
    IF NEW.borrow_date IS NOT NULL THEN 
        SET is_borrow = TRUE;
    ELSEIF NEW.return_data IS NOT NULL THEN 
        SET is_borrow = FALSE;
    ELSE THEN 
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = "Invalid checkout, neither borrowing or returning"
    END IF;

    # Update book metadata
    IF is_borrow = TRUE THEN 
        UPDATE books 
        set available_copies = available_copies - 1
        where books.id = NEW.book_id;
    ELSE THEN 
        UPDATE books 
        set available_copies = available_copies + 1
        where books.id = NEW.book_id;
end $$

DELIMITER $$

CREATE TRIGGER check_is_late
BEFORE INSERT ON checkout
FOR EACH ROW
BEGIN
    DECLARE borrow_date TIMESTAMP;
    DECLARE is_late TINYINT(1);

    -- Only check if return_date is provided
    IF NEW.return_date IS NOT NULL THEN
        -- Get borrow_date for the same user & book
        SELECT c.borrow_date 
        INTO borrow_date
        FROM checkout c
        WHERE c.user_id = NEW.user_id 
          AND c.book_id = NEW.book_id
        ORDER BY c.borrow_date DESC
        LIMIT 1;

        -- Compare dates to see if it's late
        SET is_late = TIMESTAMPDIFF(DAY, borrow_date, NEW.return_date) > 7;

        -- Set is_late
        SET NEW.is_late = is_late;
    END IF;
END$$

DELIMITER ;




DELIMITER ;