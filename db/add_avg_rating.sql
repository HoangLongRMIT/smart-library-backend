-- Add AVG rating column to books table
ALTER TABLE book
ADD COLUMN avg_rating DECIMAL(2,1) DEFAULT 0;

-- Update avg_rating for existing books
UPDATE book 
SET avg_rating = (
    SELECT AVG(rating) 
    FROM review 
    WHERE review.book_id = book.book_id
);
WHERE EXISTS (
    SELECT 1 
    FROM review 
    WHERE review.book_id = book.book_id
);