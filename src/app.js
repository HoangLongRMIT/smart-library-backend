import "dotenv/config";
import express from "express";
import cors from "cors";
import pool from "./db/mysql.js";
import { connectMongo } from "./db/mongo.js";
import booksRouter from "./routes/books.js";
import userRouter from "./routes/users.js";
import adminRouter from "./routes/admin.js";
import reportRouter from "./routes/reports.js";
import analyticsRouter from "./routes/analytics.js";

const app = express();
app.use(cors());
app.use(express.json());
app.use(cors({ origin: "http://localhost:3001" }));

app.get("/api/health", (_req, res) => {
  res.json({ ok: true });
});

app.use("/api/books", booksRouter);
app.use("/api/users", userRouter);
app.use("/api/admin", adminRouter);
app.use("/api/reports", reportRouter);
app.use("/api/analytics", analyticsRouter);

const port = process.env.PORT || 8080;
connectMongo()
  .then(() => app.listen(port, () => console.log(`API on :${port}`)))
  .catch(err => { console.error("Mongo error", err); process.exit(1); });
