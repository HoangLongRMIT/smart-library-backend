// import { Router } from "express";
// import pool from "../db/mysql.js";

// const r = Router();

// r.get("/", async (_req, res) => {
//   const [rows] = await pool.query(
//     "SELECT book_id, title, author, publisher, genre, available_copies, image_url FROM books ORDER BY title"
//   );
//   res.json(rows);
// });

// export default r;

import { Router } from "express";
import { readFileSync } from "fs";
import { join } from "path";
import pool from "../db/mysql.js";

const r = Router();

// Read SQL once at module load
const getAllBooksSQL = readFileSync(
  join(process.cwd(), "db/get_all_books.sql"),
  "utf8"
);

r.get("/", async (_req, res) => {
  try {
    const [rows] = await pool.query(getAllBooksSQL);
    console.log(rows);
    res.json(rows);
  } catch (err) {
    console.error("Error fetching books:", err);
    res.status(500).json({ error: "Database query failed" });
  }
});

export default r;
