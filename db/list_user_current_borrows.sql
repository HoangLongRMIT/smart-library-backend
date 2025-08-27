USE library;

DROP PROCEDURE IF EXISTS list_user_current_borrows;
DELIMITER $$
CREATE PROCEDURE list_user_current_borrows(
    IN p_user_id INT
)
BEGIN
    SELECT
        c.checkout_id,
        b.book_id,
        b.title,
        COALESCE(GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', '), '') AS author,
        b.genre,
        b.image_url,
        c.borrow_date,
        c.due_date,
        c.return_date,
        c.is_late
    FROM checkout c
    JOIN book b            ON b.book_id = c.book_id
    LEFT JOIN bookAuthor ba ON ba.book_id = b.book_id
    LEFT JOIN author a      ON a.author_id = ba.author_id
    WHERE c.user_id = p_user_id
      AND c.return_date IS NULL
    GROUP BY
        c.checkout_id, b.book_id, b.title, b.genre, b.image_url,
        c.borrow_date, c.due_date, c.return_date, c.is_late
    ORDER BY c.borrow_date DESC;
END$$
DELIMITER ;
