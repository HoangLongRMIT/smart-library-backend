/*
Procedure: borrow_book_no_commit
Params: user_id INT, book_id INT
Desc: No commit procedure for borrowing book operation to debug concurrency management
*/

DROP PROCEDURE IF EXISTS borrow_book_no_commit;
DELIMITER $$
CREATE PROCEDURE borrow_book_no_commit(IN user_id INT, IN book_id INT)
BEGIN
    DECLARE copies_left INT;

    START TRANSACTION;

    SELECT available_copies 
    INTO copies_left
    FROM books b 
    WHERE b.book_id = book_id
    FOR UPDATE;

    IF copies_left <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No available copies left';
    END IF;

    INSERT INTO checkouts(user_id, book_id, borrow_date) 
    VALUES (user_id, book_id, CURRENT_TIMESTAMP);

    -- No COMMIT to debug concurrency
END$$
DELIMITER ;