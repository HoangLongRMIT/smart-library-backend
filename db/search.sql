USE library;

DROP PROCEDURE IF EXISTS search_books;
DELIMITER $$
CREATE PROCEDURE search_books(
  IN p_title     VARCHAR(255),
  IN p_author    VARCHAR(255),
  IN p_genre     VARCHAR(255),
  IN p_publisher VARCHAR(255)
)
BEGIN
  SET p_title     = IFNULL(TRIM(p_title), '');
  SET p_author    = IFNULL(TRIM(p_author), '');
  SET p_genre     = IFNULL(TRIM(p_genre), '');
  SET p_publisher = IFNULL(TRIM(p_publisher), '');

  SET SESSION group_concat_max_len = 8192;

  SELECT
    b.book_id,
    b.title,
    COALESCE(GROUP_CONCAT(a.name ORDER BY a.name SEPARATOR ', '), '') AS author,
    b.publisher,
    b.genre,
    b.available_copies,
    b.average_rating,
    b.image_url
  FROM book b
  LEFT JOIN book_retirement r ON r.book_id = b.book_id          -- exclude retired
  LEFT JOIN bookAuthor ba     ON ba.book_id = b.book_id
  LEFT JOIN author a          ON a.author_id = ba.author_id
  WHERE
    r.book_id IS NULL                                            -- <- key line
    AND (p_title     = '' OR b.title     LIKE CONCAT('%', p_title, '%'))
    AND (p_genre     = '' OR b.genre     LIKE CONCAT('%', p_genre, '%'))
    AND (p_publisher = '' OR b.publisher LIKE CONCAT('%', p_publisher, '%'))
    AND (p_author    = '' OR EXISTS (
      SELECT 1
      FROM bookAuthor ba2
      JOIN author a2 ON a2.author_id = ba2.author_id
      WHERE ba2.book_id = b.book_id
        AND a2.name LIKE CONCAT('%', p_author, '%')
    ))
  GROUP BY b.book_id, b.title, b.publisher, b.genre, b.available_copies, b.image_url
  ORDER BY b.title;
END $$
DELIMITER ;