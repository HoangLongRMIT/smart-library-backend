/*
Procedure: add_book_author
Params: 
    p_book_id      INT   -- ID of the book
    p_author_id    INT   -- ID of the author

Desc:
    Creates a record in the `bookAuthor` junction table.
*/

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