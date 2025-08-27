SELECT user_id, name, email, role, password
FROM `user`
WHERE email = ?
LIMIT 1;
