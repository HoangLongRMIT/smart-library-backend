-- Stored procedure to search books by title or author or publisher or genre
DELIMITER $$

CREATE PROCEDURE search_books(IN searchTerm VARCHAR(255))
BEGIN
    SELECT *
    FROM book
    WHERE title     LIKE CONCAT('%', searchTerm, '%')
       OR author    LIKE CONCAT('%', searchTerm, '%')
       OR publisher LIKE CONCAT('%', searchTerm, '%')
       OR genre     LIKE CONCAT('%', searchTerm, '%');
END$$

DELIMITER ;