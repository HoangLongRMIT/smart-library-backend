import { Router } from "express";
import { readFileSync } from "fs";
import { join } from "path";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import pool from "../db/mysql.js";

const r = Router();

const getUserByEmailSQL = readFileSync(
  join(process.cwd(), "db/get_user_by_email.sql"),
  "utf8"
);

const JWT_SECRET = process.env.JWT_SECRET || "dev-secret-change-me";
const TOKEN_TTL = process.env.JWT_TTL || "7d";

function signToken(user) {
  const payload = {
    uid: user.user_id,
    name: user.name,
    email: user.email,
    role: user.role,
  };
  return jwt.sign(payload, JWT_SECRET, { expiresIn: TOKEN_TTL });
}

function requireAuth(req, res, next) {
  const h = req.headers.authorization || "";
  const token = h.startsWith("Bearer ") ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: "Missing token" });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: "Invalid token" });
  }
}

r.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: "email and password are required" });
    }

    const [rows] = await pool.query(getUserByEmailSQL, [email]);
    const user = rows?.[0];
    if (!user) return res.status(401).json({ error: "Invalid email or password" });

    const plainOK = password === user.password;
    let hashOK = false;
    try { hashOK = await bcrypt.compare(password, user.password); } catch {}

    if (!plainOK && !hashOK) {
      return res.status(401).json({ error: "Invalid email or password" });
    }

    const token = signToken(user);
    const { password: _pw, ...safeUser } = user;

    res.json({ token, user: safeUser });
  } catch (err) {
    console.error("Error during login:", err);
    res.status(500).json({ error: "Login failed" });
  }
});

r.get("/me", requireAuth, (req, res) => {
  res.json({ user: req.user });
});

export default r;
