/*
Procedure: get_most_borrowed_books
Params: 
    p_book_count INT

Desc:
    Return the top "n" borrowed books, defined by number of checkouts.
*/
DROP PROCEDURE IF EXISTS get_most_borrowed_books

DELIMITER $

CREATE PROCEDURE get_most_borrowed_books(
    IN p_book_count INT DEFAULT 5
)
BEGIN
    -- Return all attributes along with checkout count
    SELECT *
    FROM book b
	JOIN (
        -- Sub query to find 'n' book ids that has most checkouts
        SELECT c.book_id, COUNT(*) as checkout_count
        FROM checkout c
        GROUP BY c.book_id
        ORDER BY checkout_count DESC
        LIMIT p_book_count
    ) s ON b.book_id = s.book_id;
END $

DELIMITER ;