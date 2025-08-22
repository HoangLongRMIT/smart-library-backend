/*
Procedure: retire_book
Params: 
    p_book_id INT
Desc: 
    Retire a book by setting 'is_retired' to TRUE
*/
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
