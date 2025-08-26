DROP PROCEDURE IF EXISTS get_low_availability_books;
DELIMITER $$
CREATE PROCEDURE get_low_availability_books(
    IN p_availability_count INT UNSIGNED,
    IN p_book_count INT UNSIGNED
)
BEGIN
    SELECT b.*
    FROM book b
    LEFT JOIN book_retirement br
      ON br.book_id = b.book_id
    WHERE b.available_copies <= p_availability_count
      AND br.book_id IS NULL
    ORDER BY b.available_copies ASC, b.title ASC
    LIMIT p_book_count;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_most_borrowed_books;
DELIMITER $$
CREATE PROCEDURE get_most_borrowed_books(
    IN p_book_count INT UNSIGNED,
    IN p_start_date TIMESTAMP,
    IN p_end_date   TIMESTAMP
)
BEGIN
    /* Top N books in [p_start_date, p_end_date) with authors + borrow_count */
    SELECT
        b.book_id,
        b.title,
        COALESCE(GROUP_CONCAT(a.name ORDER BY a.name SEPARATOR ', '), '') AS authors,
        t.borrow_count
    FROM (
        SELECT
            c.book_id,
            COUNT(c.checkout_id) AS borrow_count
        FROM checkout c
        WHERE c.borrow_date >= p_start_date
          AND c.borrow_date <  p_end_date   -- exclusive end, like before
        GROUP BY c.book_id
        ORDER BY borrow_count DESC
        LIMIT p_book_count
    ) AS t
    JOIN book b             ON b.book_id = t.book_id
    LEFT JOIN bookAuthor ba ON ba.book_id = b.book_id
    LEFT JOIN author a      ON a.author_id = ba.author_id
    GROUP BY b.book_id, b.title, t.borrow_count
    ORDER BY t.borrow_count DESC, b.title ASC;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS get_top_readers_in_range;
DELIMITER $$
CREATE PROCEDURE get_top_readers_in_range(
    IN p_start TIMESTAMP,
    IN p_end   TIMESTAMP,
    IN p_limit INT UNSIGNED
)
BEGIN
    SELECT
        u.user_id,
        u.name,
        get_user_borrow_count_in_range(u.user_id, p_start, p_end) AS checkout_count
    FROM (
        SELECT DISTINCT c.user_id
        FROM checkout c
        WHERE c.borrow_date >= p_start
          AND c.borrow_date <  p_end
    ) AS active
    JOIN user u ON u.user_id = active.user_id
    ORDER BY checkout_count DESC, u.name ASC
    LIMIT p_limit;
END$$
DELIMITER ;