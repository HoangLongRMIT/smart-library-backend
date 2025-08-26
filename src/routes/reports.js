import { Router } from "express";
import pool from "../db/mysql.js";
import { firstResult } from "../utils/mysql.js";

const r = Router();

function parseRange(startStr, endStr) {
  const start = startStr ? new Date(startStr + "T00:00:00") : new Date("1970-01-01T00:00:00");
  const end = endStr ? new Date(endStr + "T00:00:00") : new Date();
  const endExclusive = new Date(end.getTime());
  endExclusive.setDate(endExclusive.getDate() + 1);
  return [start, endExclusive];
}

r.get("/most-borrowed", async (req, res) => {
  try {
    const limit = Math.max(1, Math.min(100, Number(req.query.limit) || 10));
    const [start, endExclusive] = parseRange(req.query.start, req.query.end);
    const endInclusive = new Date(endExclusive.getTime() - 1);

    const [rows] = await pool.query(
      "CALL get_most_borrowed_books(?, ?, ?)",
      [limit, start, endInclusive]
    );

    const data = firstResult(rows);
    res.json(data || []);
  } catch (err) {
    console.error("most-borrowed failed:", err);
    res.status(500).json({ error: "Failed to load most-borrowed" });
  }
});

r.get("/top-readers", async (req, res) => {
  try {
    const limit = Math.max(1, Math.min(100, Number(req.query.limit) || 10));
    const [start, endExclusive] = parseRange(req.query.start, req.query.end);

    const [rows] = await pool.query(
      "CALL get_top_readers_in_range(?, ?, ?)",
      [start, endExclusive, limit]
    );

    const data = firstResult(rows).map(r => ({
      user_id: r.user_id,
      reader_name: r.name,            // alias for UI
      checkouts_count: r.checkout_count
    }));

    res.json(data || []);
  } catch (err) {
    console.error("top-readers failed:", err);
    res.status(500).json({ error: "Failed to load top readers" });
  }
});

r.get("/low-availability", async (req, res) => {
  try {
    const limit = Math.max(1, Math.min(100, Number(req.query.limit) || 10));
    const threshold = Number.isFinite(Number(req.query.threshold))
      ? Number(req.query.threshold)
      : 3;

    const [rows] = await pool.query(
      "CALL get_low_availability_books(?, ?)",
      [threshold, limit]
    );

    const data = firstResult(rows).map(b => ({
      book_id: b.book_id,
      title: b.title,
      available_copies: b.available_copies,
      total_copies: null,
    }));

    res.json(data || []);
  } catch (err) {
    console.error("low-availability failed:", err);
    res.status(500).json({ error: "Failed to load low availability" });
  }
});

export default r;
