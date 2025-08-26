DROP TRIGGER IF EXISTS after_checkout_update;
DELIMITER $$
CREATE TRIGGER after_checkout_update
AFTER UPDATE ON checkout
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        UPDATE book 
        SET available_copies = available_copies + 1
        WHERE book.book_id = NEW.book_id;
    END IF;
END $$ 
DELIMITER ;

DROP TRIGGER IF EXISTS after_checkout_insert;
DELIMITER $$
CREATE TRIGGER after_checkout_insert
AFTER INSERT ON checkout
FOR EACH ROW
BEGIN
    IF NEW.borrow_date IS NOT NULL AND NEW.return_date IS NULL THEN
        UPDATE book 
        SET available_copies = available_copies - 1
        WHERE book.book_id = NEW.book_id;
    END IF;
END $$ 
DELIMITER ;

DROP TRIGGER IF EXISTS trg_review_ai_avg;
DELIMITER $$
CREATE TRIGGER trg_review_ai_avg
AFTER INSERT ON review
FOR EACH ROW
BEGIN
  UPDATE book b
  SET b.average_rating = COALESCE(
      (SELECT ROUND(AVG(r.rating), 1) FROM review r WHERE r.book_id = NEW.book_id),
      0
  )
  WHERE b.book_id = NEW.book_id;
END$$
DELIMITER ;