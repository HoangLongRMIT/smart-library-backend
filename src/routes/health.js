import { Router } from "express";
import pool from "../db/mysql.js";
const r = Router();
r.get("/", async (_req, res) => {
  const [rows] = await pool.query("SELECT 1 AS ok");
  res.json({ ok: rows[0].ok === 1 });
});
export default r;