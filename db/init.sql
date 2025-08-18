-- Reset database every run
DROP DATABASE IF EXISTS library;
CREATE DATABASE library;
USE library;

-- Single users table with role
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  role ENUM('admin','user') NOT NULL DEFAULT 'user'
);

-- Books for the frontend list (includes image_url for cover)
CREATE TABLE books (
  book_id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(255),
  publisher VARCHAR(255),
  genre VARCHAR(100),
  available_copies INT DEFAULT 0,
  image_url VARCHAR(1024)
);

CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
); ENGINE = InnoDB;

-- Mock data
INSERT INTO users (name, email, role) VALUES
  ('Admin One', 'admin1@example.com', 'admin'),
  ('Alice Reader', 'alice@example.com', 'user'),
  ('Bob Reader', 'bob@example.com', 'user');

INSERT INTO books (title, author, publisher, genre, available_copies, image_url) VALUES
  ('Clean Code', 'Robert C. Martin', 'Prentice Hall', 'Programming', 3, 'https://covers.openlibrary.org/b/isbn/9780132350884-L.jpg'),
  ('The Pragmatic Programmer', 'Andrew Hunt, David Thomas', 'Addison-Wesley', 'Programming', 5, 'https://covers.openlibrary.org/b/isbn/9780201616224-L.jpg'),
  ('Designing Data-Intensive Applications', 'Martin Kleppmann', 'O''Reilly', 'Data', 2, 'https://covers.openlibrary.org/b/isbn/9781449373320-L.jpg');


