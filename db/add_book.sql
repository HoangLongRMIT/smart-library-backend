USE library;

DROP PROCEDURE IF EXISTS add_book_with_authors;
DELIMITER $$
CREATE PROCEDURE add_book_with_authors
(
    IN  p_title              VARCHAR(255),
    IN  p_publisher          VARCHAR(255),
    IN  p_genre              VARCHAR(100),
    IN  p_image_url          VARCHAR(1024),
    IN  p_available_copies   INT,
    IN  p_author_ids_json    JSON,
    OUT p_inserted_book_id   INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  INSERT INTO book (title, publisher, genre, available_copies, image_url)
  VALUES (p_title, p_publisher, p_genre, COALESCE(p_available_copies, 0), p_image_url);

  SET p_inserted_book_id = LAST_INSERT_ID();

  IF p_author_ids_json IS NOT NULL AND JSON_LENGTH(p_author_ids_json) > 0 THEN
    INSERT IGNORE INTO bookAuthor (book_id, author_id)
    SELECT p_inserted_book_id, jt.author_id
    FROM JSON_TABLE(p_author_ids_json, '$[*]'
         COLUMNS (author_id INT PATH '$')) AS jt;
  END IF;

  COMMIT;
END$$
DELIMITER ;
