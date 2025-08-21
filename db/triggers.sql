/*
Trigger: after_checkout_insert
Desc: Update book metadata after a borrow
*/

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

/*
Trigger: after_checkout_update
Desc: Update book metadata after a return
*/

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

/*
Trigger: update_rating_after_review
Desc: Update book average rating after a new review
*/

DROP TRIGGER IF EXISTS update_rating_after_review;

DELIMITER $$

CREATE TRIGGER update_rating_after_review
AFTER INSERT ON review
FOR EACH ROW
BEGIN
    UPDATE book
    SET avg_rating = (
        SELECT AVG(rating)
        FROM review
        WHERE book_id = NEW.book_id
    )
    WHERE book_id = NEW.book_id;
END $$

DELIMITER ;