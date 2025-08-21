-- Stored procedure to search books by title or author or publisher or genre
DROP PROCEDURE IF EXISTS search_books;
DELIMITER $$

CREATE PROCEDURE search_books(IN searchTerm VARCHAR(255))
BEGIN
    SELECT *
    FROM book
    WHERE title     LIKE CONCAT('%', searchTerm, '%')
       OR author    LIKE CONCAT('%', searchTerm, '%')
       OR publisher LIKE CONCAT('%', searchTerm, '%')
       OR genre     LIKE CONCAT('%', searchTerm, '%');
END$$

DELIMITER ;

-- Stored procedure to add a review for a book
DROP PROCEDURE IF EXISTS add_review;
DELIMITER $$

CREATE PROCEDURE add_review(
    IN p_user_id INT,
    IN p_book_id INT,
    IN p_rating INT,
    IN p_comment TEXT
)
BEGIN
    INSERT INTO review (user_id, book_id, rating, comment)
    VALUES (p_user_id, p_book_id, p_rating, p_comment);
END$$

DELIMITER ;

-- Borrow / Return books

/*
Procedure: borrow_book
Params: user_id INT, book_id INT
Desc: Handles borrowing a book with transaction + row locking
*/

DROP PROCEDURE IF EXISTS borrow_book;
DELIMITER $$ 
CREATE PROCEDURE borrow_book(IN user_id INT, IN book_id INT)
BEGIN
    DECLARE copies_left INT;

    -- rollback on any sql exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- verify that book is still available, lock row
    SELECT available_copies 
    INTO copies_left
    FROM book b 
    WHERE b.book_id = book_id
    FOR UPDATE;

    -- throws if no copies left
    IF copies_left <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No available copies left';
    END IF;

    -- insert borrow checkout
    INSERT INTO checkout(user_id, book_id, borrow_date) 
    VALUES (user_id, book_id, CURRENT_TIMESTAMP);

    COMMIT;
END $$ 
DELIMITER ;

/*
Procedure: return_book
Params: checkout_id INT
Desc: Handles returning a book
*/

DROP PROCEDURE IF EXISTS return_book;
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
        RESIGNAL;
    END;

    START TRANSACTION;

    -- fetch borrow date and return date
    SELECT c.borrow_date, c.return_date
    INTO v_borrow_date, v_return_date
    FROM checkout c
    WHERE c.checkout_id = p_checkout_id;

    -- throws if already returned
    IF v_return_date IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Already returned checkout';
    END IF;

    -- calculate if returned late (>7 days)
    SET v_is_late = TIMESTAMPDIFF(DAY, v_borrow_date, CURRENT_TIMESTAMP) > 7;

    -- update checkout
    UPDATE checkout c
    SET c.return_date = CURRENT_TIMESTAMP,
        c.is_late = v_is_late
    WHERE c.checkout_id = p_checkout_id;

    COMMIT;
END $$ 
DELIMITER ;