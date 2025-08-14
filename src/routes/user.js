import { Router } from "express";
import pool from "../db/mysql.js";

const r = Router();

r.get("/", async (_req, res) => {
  const [rows] = await pool.query(
    "SELECT user_id, name, email, role FROM users ORDER BY role, name"
  );
  res.json(rows);
});

export default r;
