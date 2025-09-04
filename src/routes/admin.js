import { Router } from "express";
import pool from "../db/mysql.js";
import { firstResult } from "../utils/mysql.js";

const r = Router();

const PROC_SCHEMA = process.env.PROC_SCHEMA || "library";
const STRICT_LOG = process.env.STRICT_LOG === "1";

const t = (v) => (typeof v === "string" ? v.trim() : "");

function splitAuthors(csv) {
  return String(csv || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

function parseAdminId(req) {
  const candidates = [
    req.user?.user_id,
    req.body?.admin_user_id,
    req.query?.admin_user_id,
    req.headers["x-admin-user-id"],
  ];
  for (const raw of candidates) {
    const n = Number(raw);
    if (Number.isInteger(n) && n > 0) return n;
  }
  return null;
}

async function callProc(connOrPool, name, params = [], { label = name, fatal = false } = {}) {
  const sql = `CALL ${PROC_SCHEMA}.${name}(${params.map(() => "?").join(", ")})`;
  try {
    return await connOrPool.query(sql, params);
  } catch (e) {
    const msg = `[proc:${label}] ${e?.message || e}`;
    if (fatal || STRICT_LOG) {
      throw new Error(msg);
    } else {
      console.warn(msg);
      return null;
    }
  }
}

async function upsertAuthorByName(conn, name) {
  {
    const [rows] = await conn.query(
      `SELECT author_id FROM author WHERE name = ? LIMIT 1`,
      [name]
    );
    if (rows.length) return rows[0].author_id;
  }
  const [res] = await conn.query(
    `INSERT INTO author(name) VALUES (?)`,
    [name]
  );
  return res.insertId;
}

r.post("/books", async (req, res) => {
  const adminId = parseAdminId(req);
  if (adminId === null) {
    return res.status(400).json({ error: "Missing/invalid admin_user_id" });
  }

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
    if (authorNames.length === 0) {
      return res.status(400).json({ error: "authors list is empty" });
    }

    const authorIds = [];
    for (const name of authorNames) {
      const id = await upsertAuthorByName(conn, name);
      authorIds.push(id);
    }

    const jsonIds = JSON.stringify(authorIds);
    await conn.query(
    `CALL ${PROC_SCHEMA}.add_book_with_authors(?, ?, ?, ?, ?, ?, @new_book_id)`,
    [title, publisher || null, genre || null, image_url || null, available_copies, jsonIds]
  );

    const [[row]] = await conn.query("SELECT @new_book_id AS book_id");
    const book_id = row?.book_id;
    if (!book_id) {
      return res.status(500).json({ error: "Failed to retrieve new book id" });
    }

    await callProc(
      conn,
      "log_staff_action_tx",
      [adminId, book_id, "Added new book"],
      { label: "log_staff_action_tx (add book)" }
    );

    return res.status(201).json({ success: true, book_id });
  } catch (err) {
    console.error("add book failed:", err);
    return res.status(500).json({ error: "Create failed", detail: String(err?.message || err) });
  } finally {
    if (conn) conn.release();
  }
});

r.post("/books/:bookId/inventory/update", async (req, res) => {
  const adminId = parseAdminId(req);
  if (adminId === null) {
    console.error("[adminId check failed]", {
      body: req.body,
      query: req.query,
      headers: req.headers,
      user: req.user,
    });
    return res.status(400).json({ error: "Missing/invalid admin_user_id" });
  }

  const bookId = Number(req.params.bookId);
  const newCount = Number.isFinite(Number(req.body?.count))
    ? Math.max(0, Number(req.body.count))
    : NaN;

  if (!Number.isFinite(bookId) || bookId <= 0 || !Number.isFinite(newCount) || newCount < 0) {
    return res.status(400).json({ error: "bookId must be > 0 and count must be a non-negative number" });
  }

  try {
    await callProc(
      pool,
      "update_book_inventory",
      [bookId, newCount],
      { label: "update_book_inventory", fatal: true }
    );

    await callProc(
      pool,
      "log_staff_action_tx",
      [adminId, bookId, `Inventory set to ${newCount}`],
      { label: "log_staff_action_tx (inventory)" }
    );

    return res.json({ ok: true, book_id: bookId, available_copies: newCount });
  } catch (err) {
    console.error("inventory update failed:", err);
    return res.status(500).json({ error: "Inventory update failed", detail: String(err?.message || err) });
  }
});

r.post("/books/:bookId/retire", async (req, res) => {
  const adminId = parseAdminId(req);
  if (adminId === null) {
    return res.status(400).json({ error: "Missing/invalid admin_user_id" });
  }

  const bookId = Number(req.params.bookId);
  const reason = String(req.body?.reason || "").trim();

  if (!Number.isFinite(bookId) || bookId <= 0 || !reason) {
    return res.status(400).json({ error: "bookId and reason are required" });
  }

  try {
    await callProc(
      pool,
      "retire_book",
      [bookId, reason],
      { label: "retire_book", fatal: true }
    );

    await callProc(
      pool,
      "log_staff_action_tx",
      [adminId, bookId, `Retired: ${reason}`],
      { label: "log_staff_action_tx (retire)" }
    );

    return res.json({ ok: true, book_id: bookId, retired: true, reason });
  } catch (err) {
    console.error("retire failed:", err);
    return res.status(500).json({ error: "Retire failed", detail: String(err?.message || err) });
  }
});

r.post("/books/:bookId/unretire", async (req, res) => {
  const adminId = parseAdminId(req);
  if (adminId === null) {
    return res.status(400).json({ error: "Missing/invalid admin_user_id" });
  }

  const bookId = Number(req.params.bookId);
  if (!Number.isFinite(bookId) || bookId <= 0) {
    return res.status(400).json({ error: "bookId required" });
  }

  try {
    await callProc(
      pool,
      "unretire_book",
      [bookId],
      { label: "unretire_book", fatal: true }
    );

    await callProc(
      pool,
      "log_staff_action_tx",
      [adminId, bookId, "Unretired"],
      { label: "log_staff_action_tx (unretire)" }
    );

    return res.json({ ok: true, book_id: bookId, retired: false });
  } catch (err) {
    console.error("unretire failed:", err);
    return res.status(500).json({ error: "Unretire failed", detail: String(err?.message || err) });
  }
});

r.get("/books", async (req, res) => {
  const limit = Math.min(1000, Number(req.query.limit) || 500);
  try {
    const [rows] = await callProc(
      pool,
      "list_books_with_retire_status",
      [limit],
      { label: "list_books_with_retire_status", fatal: true }
    );
    return res.json(firstResult(rows) || []);
  } catch (err) {
    console.error("admin list books failed:", err);
    return res.status(500).json({ error: "Failed to list books", detail: String(err?.message || err) });
  }
});

export default r;
