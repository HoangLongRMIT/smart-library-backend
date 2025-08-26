USE library;

DROP PROCEDURE IF EXISTS list_books_with_retire_status;
DELIMITER $$
CREATE PROCEDURE list_books_with_retire_status(
    IN p_limit INT UNSIGNED
)
BEGIN
    SELECT
        b.book_id,
        b.title,
        b.publisher,
        b.genre,
        b.available_copies,
        b.image_url,
        COALESCE(GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', '), '') AS authors,
        (br.book_id IS NOT NULL) AS is_retired,
        br.retired_reason
    FROM book b
    LEFT JOIN book_retirement br ON br.book_id = b.book_id
    LEFT JOIN bookAuthor ba      ON ba.book_id = b.book_id
    LEFT JOIN author a           ON a.author_id = ba.author_id
    GROUP BY
        b.book_id, b.title, b.publisher, b.genre, b.available_copies, b.image_url,
        br.book_id, br.retired_reason
    ORDER BY b.title ASC
    LIMIT p_limit;
END$$
DELIMITER ;
