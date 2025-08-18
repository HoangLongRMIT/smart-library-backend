-- Reset database every run
DROP DATABASE IF EXISTS library;
CREATE DATABASE library;
USE library;

-- Single users table with role
CREATE TABLE user (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  role ENUM('admin','user') NOT NULL DEFAULT 'user'
);

-- Books for the frontend list (includes image_url for cover)
CREATE TABLE book (
  book_id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(255),
  publisher VARCHAR(255),
  genre VARCHAR(100),
  available_copies INT DEFAULT 0,
  image_url VARCHAR(1024)
);

-- Checkout
CREATE TABLE checkout (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  book_id INT NOT NULL,
  borrow_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  return_date TIMESTAMP NULL,
  is_late BOOLEAN DEFAULT NULL, -- null for active borrows
  CONSTRAINT fk_checkout_user FOREIGN KEY (user_id) REFERENCES user(user_id),
  CONSTRAINT fk_checkout_book FOREIGN KEY (book_id) REFERENCES book(book_id)
);


-- Borrow / Return books

/*
Procedure: borrow_book
Params: user_id INT, book_id INT
Desc: Handles borrowing a book with transaction + row locking
*/

DROP PROCEDURE IF EXISTS borrow_book;
DELIMITER $$ 
CREATE PROCEDURE borrow_book(IN user_id INT, IN book_id INT)
BEGIN
    DECLARE copies_left INT;

    -- rollback on any sql exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- verify that book is still available, lock row
    SELECT available_copies 
    INTO copies_left
    FROM book b 
    WHERE b.book_id = book_id
    FOR UPDATE;

    -- throws if no copies left
    IF copies_left <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No available copies left';
    END IF;

    -- insert borrow checkout
    INSERT INTO checkout(user_id, book_id, borrow_date) 
    VALUES (user_id, book_id, CURRENT_TIMESTAMP);

    COMMIT;
END $$ 
DELIMITER ;

/*
Procedure: return_book
Params: checkout_id INT
Desc: Handles returning a book
*/

DROP PROCEDURE IF EXISTS return_book;
DELIMITER $$
CREATE PROCEDURE return_book(IN p_checkout_id INT)
BEGIN
    DECLARE v_borrow_date TIMESTAMP;
    DECLARE v_return_date TIMESTAMP;
    DECLARE v_is_late BOOLEAN;

    -- rollback on any sql exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- fetch borrow date and return date
    SELECT borrow_date, return_date
    INTO v_borrow_date, v_return_date
    FROM checkout
    WHERE id = p_checkout_id;

    -- throws if already returned
    IF v_return_date IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Already returned checkout';
    END IF;

    -- calculate if returned late (>7 days)
    SET v_is_late = TIMESTAMPDIFF(DAY, v_borrow_date, CURRENT_TIMESTAMP) > 7;

    -- update checkout
    UPDATE checkout
    SET return_date = CURRENT_TIMESTAMP,
        is_late = v_is_late
    WHERE id = p_checkout_id;

    COMMIT;
END $$ 
DELIMITER ;

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



-- Mock data
INSERT INTO user (name, email, role) VALUES
  ('Admin One', 'admin1@example.com', 'admin'),
  ('Alice Reader', 'alice@example.com', 'user'),
  ('Bob Reader', 'bob@example.com', 'user');

INSERT INTO book (title, author, publisher, genre, available_copies, image_url) VALUES
  ('Clean Code', 'Robert C. Martin', 'Prentice Hall', 'Programming', 3, 'https://covers.openlibrary.org/b/isbn/9780132350884-L.jpg'),
  ('The Pragmatic Programmer', 'Andrew Hunt, David Thomas', 'Addison-Wesley', 'Programming', 5, 'https://covers.openlibrary.org/b/isbn/9780201616224-L.jpg'),
  ('Designing Data-Intensive Applications', 'Martin Kleppmann', 'O''Reilly', 'Data', 2, 'https://covers.openlibrary.org/b/isbn/9781449373320-L.jpg');
