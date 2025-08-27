import { Router } from "express";
import pool from "../db/mysql.js";
import { firstResult } from "../utils/mysql.js";

const r = Router();

const t = (v) => (typeof v === "string" ? v.trim() : "");

function splitAuthors(csv) {
  return String(csv || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

async function upsertAuthorByName(conn, name) {
  {
    const [rows] = await conn.query(
      "SELECT author_id FROM author WHERE name = ? LIMIT 1",
      [name]
    );
    if (rows.length) return rows[0].author_id;
  }
  const [res] = await conn.query("INSERT INTO author(name) VALUES (?)", [name]);
  return res.insertId;
}

r.post("/books", async (req, res) => {
  const title = t(req.body.title);
  const authorsCsv = t(req.body.authors);
  const publisher = t(req.body.publisher);
  const genre = t(req.body.genre);
  const image_url = t(req.body.image_url);
  const available_copies = 0;

  if (!title || !authorsCsv) {
    return res.status(400).json({ error: "title and authors are required" });
  }

  let conn;
  try {
    conn = await pool.getConnection();

    const authorNames = splitAuthors(authorsCsv);
    const authorIds = [];
    for (const name of authorNames) {
      const id = await upsertAuthorByName(conn, name);
      authorIds.push(id);
    }

    const jsonIds = JSON.stringify(authorIds);
    await conn.query(
      "CALL add_book_with_authors(?, ?, ?, ?, ?, ?, @new_book_id)",
      [
        title,
        publisher || null,
        genre || null,
        image_url || null,
        available_copies,
        jsonIds,
      ]
    );
    const [[row]] = await conn.query("SELECT @new_book_id AS book_id");
    const book_id = row?.book_id;

    if (!book_id) {
      return res.status(500).json({ error: "Failed to retrieve new book id" });
    }

    res.status(201).json({ success: true, book_id });
  } catch (err) {
    console.error("add book failed:", err);
    res.status(500).json({ error: "Create failed" });
  } finally {
    if (conn) conn.release();
  }
});


r.post("/books/:bookId/inventory/update", async (req, res) => {
  const bookId = Number(req.params.bookId);
  const newCount = Number.isFinite(Number(req.body?.count))
    ? Math.max(0, Number(req.body.count))
    : NaN;

  if (!Number.isFinite(bookId) || bookId <= 0 || !Number.isFinite(newCount) || newCount < 0) {
    return res.status(400).json({ error: "bookId must be > 0 and count must be a non-negative number" });
  }

  try {
    await pool.query("CALL update_book_inventory(?, ?)", [bookId, newCount]);
    return res.json({ ok: true, book_id: bookId, available_copies: newCount });
  } catch (err) {
    console.error("inventory update failed:", err);
    return res.status(500).json({ error: "Inventory update failed" });
  }
});


r.post("/books/:bookId/retire", async (req, res) => {
  const bookId = Number(req.params.bookId);
  const reason = String(req.body?.reason || "").trim();

  if (!bookId || !reason) {
    return res.status(400).json({ error: "bookId and reason are required" });
  }

  try {
    await pool.query("CALL retire_book(?, ?)", [bookId, reason]);
    return res.json({ ok: true, book_id: bookId, retired: true, reason });
  } catch (err) {
    console.error("retire failed:", err);
    return res.status(500).json({ error: "Retire failed" });
  }
});

r.post("/books/:bookId/unretire", async (req, res) => {
  const bookId = Number(req.params.bookId);
  if (!bookId) return res.status(400).json({ error: "bookId required" });

  try {
    await pool.query("CALL unretire_book(?)", [bookId]);
    return res.json({ ok: true, book_id: bookId, retired: false });
  } catch (err) {
    console.error("unretire failed:", err);
    return res.status(500).json({ error: "Unretire failed" });
  }
});

r.get("/books", async (req, res) => {
  const limit = Math.min(1000, Number(req.query.limit) || 500);
  try {
    const [rows] = await pool.query(
      "CALL list_books_with_retire_status(?)", // or "CALL library.list_books_with_retire_status(?)"
      [limit]
    );
    res.json(firstResult(rows) || []);
  } catch (err) {
    console.error("admin list books failed:", err);
    res.status(500).json({ error: "Failed to list books" });
  }
});

export default r;
