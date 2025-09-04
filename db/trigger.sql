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