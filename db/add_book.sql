/*
Procedure: add_book_and_author
Params: 
    p_title        VARCHAR(255)   -- title of the book
    p_publisher    VARCHAR(255)   -- publisher of the book
    p_genre        VARCHAR(100)   -- genre/category of the book
    p_image_url    VARCHAR(1024)  -- cover image URL of the book
    p_author_name  VARCHAR(255)   -- name of the book’s author
Desc: 
    Inserts a new book and a new author, retrieves their IDs using LAST_INSERT_ID(),
    and records the relationship in the junction table (bookAuthor).
*/
DELIMITER $$

CREATE PROCEDURE add_book_and_author
(
    IN p_title VARCHAR(255), 
    IN p_publisher VARCHAR(255),
    IN p_genre VARCHAR(100),
    IN p_image_url VARCHAR(1024),
    IN p_author_name VARCHAR(255)
)
BEGIN
    DECLARE inserted_book_id INT;
    DECLARE inserted_author_id INT;

    -- insert book
    INSERT INTO book (title, publisher, genre, image_url)
    VALUES (p_title, p_publisher, p_genre, p_image_url);
    SET inserted_book_id = LAST_INSERT_ID();

    -- insert author
    INSERT INTO author (name)
    VALUES (p_author_name);
    SET inserted_author_id = LAST_INSERT_ID();

    -- insert into junction table
    INSERT INTO bookAuthor (book_id, author_id)
    VALUES (inserted_book_id, inserted_author_id);
END$$

DELIMITER ;


/*
Procedure: add_book_with_author
Params: 
    p_title        VARCHAR(255)   -- title of the book
    p_publisher    VARCHAR(255)   -- publisher of the book
    p_genre        VARCHAR(100)   -- genre/category of the book
    p_image_url    VARCHAR(1024)  -- cover image URL of the book
    p_author_id    INT            -- existing author ID
Desc: 
    Inserts a new book, retrieves its ID using LAST_INSERT_ID(),
    and records the relationship with an existing author in the junction table (bookAuthor).
*/
DELIMITER $$

CREATE PROCEDURE add_book_with_author
(
    IN p_title VARCHAR(255), 
    IN p_publisher VARCHAR(255),
    IN p_genre VARCHAR(100),
    IN p_image_url VARCHAR(1024),
    IN p_author_id INT
)
BEGIN
    DECLARE inserted_book_id INT;

    -- insert book
    INSERT INTO book (title, publisher, genre, image_url)
    VALUES (p_title, p_publisher, p_genre, p_image_url);
    SET inserted_book_id = LAST_INSERT_ID();

    -- insert into junction table
    INSERT INTO bookAuthor (book_id, author_id)
    VALUES (inserted_book_id, p_author_id);
END$$

DELIMITER ;