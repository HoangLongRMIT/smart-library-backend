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

