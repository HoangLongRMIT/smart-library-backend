DELIMITER $$
-- Stored procedure to add a review for a book
CREATE PROCEDURE add_review(
    IN p_user_id INT,
    IN p_book_id INT,
    IN p_rating INT,
    IN p_comment TEXT
)
BEGIN
    INSERT INTO reviews (user_id, book_id, rating, comment)
    VALUES (p_user_id, p_book_id, p_rating, p_comment);
END$$

DELIMITER ;