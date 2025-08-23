/*
Procedure: add_book
Params: 
    p_title        VARCHAR(255)   -- Title of the book
    p_publisher    VARCHAR(255)   -- Publisher of the book
    p_genre        VARCHAR(100)   -- Genre or category of the book
    p_image_url    VARCHAR(1024)  -- Cover image URL of the book

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
    IN p_image_url VARCHAR(1024)
)
BEGIN
    INSERT INTO book (title, publisher, genre, image_url)
    VALUES (p_title, p_publisher, p_genre, p_image_url);

    -- Return the inserted book_id
    SELECT LAST_INSERT_ID() AS inserted_id;
END$$

DELIMITER ;

/*
Procedure: add_book_author
Params: 
    p_book_id      INT   -- ID of the book
    p_author_id    INT   -- ID of the author

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
    WHERE book_id = p_book_id
END$$

DELIMITER ;
