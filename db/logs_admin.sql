USE library;

DROP PROCEDURE IF EXISTS log_staff_action_tx;
DELIMITER $$
CREATE PROCEDURE log_staff_action_tx(
  IN p_admin_user_id INT,
  IN p_book_id       INT,
  IN p_action        VARCHAR(255)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  INSERT INTO staffLog(user_id, book_id, action)
  VALUES (p_admin_user_id, p_book_id, p_action);

  COMMIT;
END$$
DELIMITER ;
