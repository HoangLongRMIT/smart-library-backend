import { Router } from "express";
import pool from "../db/mysql.js";
import { firstResult } from "../utils/mysql.js";

const r = Router();

const norm = (v) => (typeof v === "string" ? v.trim() : "");

r.get("/", async (req, res) => {
  try {
    const title     = norm(req.query.title);
    const author    = norm(req.query.author);
    const genre     = norm(req.query.genre);
    const publisher = norm(req.query.publisher);

    const [sets] = await pool.query(
      "CALL `library`.`search_books`(?, ?, ?, ?)",
      [title || "", author || "", genre || "", publisher || ""]
    );

    const rows = Array.isArray(sets) ? sets[0] : sets;
    res.json(rows || []);
  } catch (err) {
    console.error("Error fetching books:", err);
    res.status(500).json({ error: "Database query failed" });
  }
});

r.post("/:bookId/borrow", async (req, res) => {
  const bookId = Number(req.params.bookId);
  const userId = Number(req.body?.user_id);
  if (!bookId || !userId) {
    return res.status(400).json({ error: "user_id and bookId are required" });
  }

  let conn;
  try {
    conn = await pool.getConnection();

    await conn.query("CALL `library`.`borrow_book`(?, ?)", [userId, bookId]);

    return res.status(201).json({ ok: true, book_id: bookId, user_id: userId });
  } catch (err) {
    console.error("borrow failed:", err);
    const msg =
      err?.sqlMessage?.toLowerCase().includes("no available copies")
        ? "No available copies left"
        : "Borrow failed";
    res.status(400).json({ error: msg });
  } finally {
    if (conn) conn.release();
  }
});

r.get("/:userId/borrowed", async (req, res) => {
  const userId = Number(req.params.userId);
  if (!Number.isFinite(userId) || userId <= 0) {
    return res.status(400).json({ error: "Invalid userId" });
  }

  try {
    const [rows] = await pool.query(
      "CALL list_user_current_borrows(?)",
      [userId]
    );
    res.json(firstResult(rows) || []);
  } catch (err) {
    console.error("load borrowed failed:", err);
    res.status(500).json({ error: "Failed to load borrowed books" });
  }
});

r.post("/:checkoutId/return", async (req, res) => {
  const checkoutId = Number(req.params.checkoutId);
  if (!checkoutId) {
    return res.status(400).json({ error: "checkoutId is required" });
  }

  let conn;
  try {
    conn = await pool.getConnection();

    await conn.query("CALL return_book(?)", [checkoutId]);

    return res.json({ ok: true, checkout_id: checkoutId });
  } catch (err) {
    console.error("return failed:", err);
    const msg = String(err?.sqlMessage || "").toLowerCase();
    if (msg.includes("checkout not found")) {
      return res.status(404).json({ error: "Checkout not found" });
    }
    if (msg.includes("already returned")) {
      return res.status(400).json({ error: "Already returned" });
    }
    res.status(500).json({ error: "Return failed" });
  } finally {
    if (conn) conn.release();
  }
});

r.post("/reviews", async (req, res) => {
  const userId = Number(req.body?.user_id ?? 1);
  const bookId = Number(req.body?.book_id);
  const rating = Number(req.body?.rating);
  const comment = (req.body?.comment ?? "").trim();

  if (!Number.isFinite(bookId) || bookId <= 0) {
    return res.status(400).json({ error: "book_id is required" });
  }
  if (!(rating >= 1 && rating <= 5)) {
    return res.status(400).json({ error: "rating must be between 1 and 5" });
  }

  let conn;
  try {
    conn = await pool.getConnection();

    await conn.query("CALL `library`.`add_review`(?, ?, ?, ?)", [
      userId,
      bookId,
      rating,
      comment || null,
    ]);

    return res.status(201).json({ ok: true });
  } catch (err) {
    console.error("add review failed:", err);
    return res.status(500).json({ error: "Review failed" });
  } finally {
    if (conn) conn.release();
  }
});

export default r;
