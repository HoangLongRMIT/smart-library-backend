-- retire a book (insert/replace reason)
DROP PROCEDURE IF EXISTS retire_book;
DELIMITER $$
CREATE PROCEDURE retire_book(IN p_book_id INT, IN p_reason VARCHAR(255))
BEGIN
  INSERT INTO book_retirement (book_id, retired_reason)
  VALUES (p_book_id, p_reason)
  ON DUPLICATE KEY UPDATE retired_reason = VALUES(retired_reason);
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS unretire_book;
DELIMITER $$
CREATE PROCEDURE unretire_book(IN p_book_id INT)
BEGIN
  DELETE FROM book_retirement WHERE book_id = p_book_id;
END$$
DELIMITER ;
