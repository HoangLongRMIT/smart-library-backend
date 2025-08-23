/*
Procedure: add_book
Params: 
    p_title     VARCHAR
    p_publisher     VARCHAR
    p_genre     VARCHAR
    p_image_url     VARCHAR
Returns:
    p_book_id   INT
Desc: 
    Inserts a new book record into the `book` table.
    And return the inserted book id
*/
DROP PROCEDURE IF EXISTS add_book;
DELIMITER $$

CREATE PROCEDURE add_book
(
    IN p_title VARCHAR(255), 
    IN p_publisher VARCHAR(255),
    IN p_genre VARCHAR(100),
    IN p_image_url VARCHAR(1024),
    OUT p_inserted_book_id INT
)
BEGIN
    INSERT INTO book (title, publisher, genre, image_url)
    VALUES (p_title, p_publisher, p_genre, p_image_url);

    SET p_inserted_book_id = LAST_INSERT_ID();
END$$

DELIMITER ;

/*
Procedure: add_book_author
Params: 
    p_book_id      INT
    p_author_id    INT
Desc:
    Creates a record in the `bookAuthor` junction table.
*/
DROP PROCEDURE IF EXISTS add_book_author;
DELIMITER $$
CREATE PROCEDURE add_book_author
(
  IN p_book_id INT,
  IN p_author_id INT
)
BEGIN
  INSERT INTO bookAuthor (book_id, author_id)
  VALUES (p_book_id, p_author_id);
END$$
DELIMITER ;

/*
Procedure: retire_book
Params: 
    p_book_id INT
Desc: 
    Retire a book by setting 'is_retired' to TRUE
*/
DROP PROCEDURE IF EXISTS retire_book;
DELIMITER $$
CREATE PROCEDURE retire_book
(
  IN p_book_id INT
)
BEGIN
    UPDATE book
    SET is_retired = TRUE 
    WHERE book_id = p_book_id;
END$$
DELIMITER ;

/*
Procedure: unretire_book
Params: 
    p_book_id INT
Desc: 
    Unretire a book by setting 'is_retired' to TRUE
*/
DROP PROCEDURE IF EXISTS unretire_book;
DELIMITER $$
CREATE PROCEDURE unretire_book
(
  IN p_book_id INT
)
BEGIN
    UPDATE book
    SET is_retired = FALSE 
    WHERE book_id = p_book_id;
END$$
DELIMITER ;

/*
Procedure: update_book_inventory
Params: 
    p_book_id INT
    p_amount INT
Desc: 
    Update the available copies of a book to the input amount
*/
DROP PROCEDURE IF EXISTS update_book_inventory;
DELIMITER $$
CREATE PROCEDURE update_book_inventory
(
    IN p_book_id INT,
    IN p_amount INT
)
BEGIN
    -- rollback on any sql exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        -- Lock row, prevent lost updates
        SELECT available_copies
        FROM book
        WHERE book_id = p_book_id
        FOR UPDATE;

        -- Assign new 'available_copies' value
        UPDATE book b
        SET b.available_copies = p_amount
        WHERE b.book_id = p_book_id;
    COMMIT;
END$$
DELIMITER ;