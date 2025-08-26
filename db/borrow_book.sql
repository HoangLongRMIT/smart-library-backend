DROP PROCEDURE IF EXISTS borrow_book;
DELIMITER $$
CREATE PROCEDURE borrow_book(IN p_user_id INT, IN p_book_id INT)
BEGIN
  DECLARE v_copies_left INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT available_copies
    INTO v_copies_left
    FROM book
   WHERE book_id = p_book_id
     FOR UPDATE;

  IF is_book_available(p_book_id) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available copies left';
  END IF;

  INSERT INTO checkout (user_id, book_id, borrow_date, due_date)
  VALUES (p_user_id, p_book_id, CURRENT_TIMESTAMP,
          DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 MONTH));

  COMMIT;
END $$
DELIMITER ;