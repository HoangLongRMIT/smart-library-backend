/*
Procedure: get_low_availability_books
Params: 
    p_availability_count INT UNSIGNED
    p_book_count INT UNSIGNED
Desc:
    Return the top "n" lowest availability books
*/
DROP PROCEDURE IF EXISTS get_low_availability_books;
DELIMITER $$
CREATE PROCEDURE get_low_availability_books(
    IN p_availability_count INT UNSIGNED, 
    IN p_book_count INT UNSIGNED
)
BEGIN
    SELECT * 
    FROM book 
    WHERE available_copies <= p_availability_count
    AND is_retired = FALSE
    ORDER BY available_copies ASC
    LIMIT p_book_count;
END$$
DELIMITER ;

/*
Procedure: get_most_borrowed_books
Params: 
    p_book_count INT UNSIGNED
    p_start_date TIMESTAMP
    p_end_date TIMESTAMP
Desc:
    Return the top "n" most borrowed books by number of checkouts.
*/
DROP PROCEDURE IF EXISTS get_most_borrowed_books;
DELIMITER $$
CREATE PROCEDURE get_most_borrowed_books(
    IN p_book_count INT UNSIGNED,
    IN p_start_date TIMESTAMP,
    IN p_end_date TIMESTAMP
)
BEGIN
    SELECT *
    FROM book b
	JOIN (
        -- Sub query to find 'n' book ids that has most checkouts
        SELECT 
        c.book_id, 
        COUNT(*) as checkout_count 
        FROM checkout c
        WHERE c.borrow_date BETWEEN p_start_date AND p_end_date -- Filter by time range
        GROUP BY c.book_id
        ORDER BY checkout_count DESC
        LIMIT p_book_count
    ) s ON b.book_id = s.book_id;
END$$
DELIMITER ;

/*
Procedure: get_top_active_readers
Params: 
    p_reader_count INT UNSIGNED
Desc:
    Return the top "n" active readers by number of checkouts
*/
DROP PROCEDURE IF EXISTS get_top_active_readers;
DELIMITER $$
CREATE PROCEDURE get_top_active_readers(
    IN p_reader_count INT UNSIGNED
)
BEGIN
    SELECT u.user_id, u.name, COUNT(*) as checkout_count
    FROM user u 
    JOIN checkout c 
    ON u.user_id = c.user_id 
    -- If last checkout date is <= 30 days, that user is considered active
    WHERE datediff(CURRENT_TIMESTAMP, u.last_checkout_date) <= 30 
    GROUP BY u.user_id
    ORDER BY checkout_count desc
    LIMIT p_reader_count;
END$$
DELIMITER ;