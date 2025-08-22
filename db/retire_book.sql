/*
Procedure: retire_book
Params: 

Desc: 

*/
DELIMITER $$

CREATE PROCEDURE retire_book
(
    IN p_book_id INT
)
BEGIN
    DELETE FROM book
    WHERE book_id = p_book_id;
END$$

DELIMITER ;
