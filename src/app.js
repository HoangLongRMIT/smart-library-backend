import "dotenv/config";
import express from "express";
import cors from "cors";
import pool from "./db/mysql.js";
import { connectMongo } from "./db/mongo.js";
import booksRouter from "./routes/books.js";

const app = express();
// app.use(cors());
app.use(express.json());
app.use(cors({ origin: "http://localhost:3001" }));

app.get("/api/health", async (req,res) => {
  const [rows] = await pool.query("SELECT 1 AS ok");
  res.json({ ok: rows[0].ok === 1 });
});

app.use("/api/books", booksRouter);

const port = process.env.PORT || 8080;
connectMongo()
  .then(() => app.listen(port, () => console.log(`API on :${port}`)))
  .catch(err => { console.error("Mongo error", err); process.exit(1); });
