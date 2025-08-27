DROP PROCEDURE IF EXISTS update_book_inventory;
DELIMITER $$
CREATE PROCEDURE update_book_inventory
(
    IN p_book_id INT,
    IN p_amount INT
)
BEGIN
    -- rollback on any sql exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        -- Lock row, prevent lost updates
        SELECT available_copies
        FROM book
        WHERE book_id = p_book_id
        FOR UPDATE;

        -- Assign new 'available_copies' value
        UPDATE book b
        SET b.available_copies = p_amount
        WHERE b.book_id = p_book_id;
    COMMIT;
END$$
DELIMITER ;