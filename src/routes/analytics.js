import { Router } from "express";
import { MongoClient } from "mongodb";
import {
  parseISO,
  buildAvgSessionMinutesPipeline,
  buildMostHighlightedBooksPipeline,
  buildTopBooksByReadingTimePipeline,
} from "../analytics/reading_analytics.js";

const r = Router();

const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017";
const MONGO_DB  = process.env.MONGO_DB  || "library";
const COLL_NAME = "reading_sessions";

let _client;
async function getColl() {
  if (!_client) {
    _client = new MongoClient(MONGO_URI, { maxPoolSize: 10 });
    await _client.connect();
  }
  return _client.db(MONGO_DB).collection(COLL_NAME);
}

r.get("/avg-session-minutes", async (req, res) => {
  try {
    const start = parseISO(req.query.start);
    const end   = parseISO(req.query.end);
    const coll  = await getColl();

    const data = await coll.aggregate(
      buildAvgSessionMinutesPipeline(start, end)
    ).toArray();

    res.json(data);
  } catch (e) {
    console.error("avg-session-minutes failed:", e);
    res.status(500).json({ error: "Failed to compute average session minutes" });
  }
});

r.get("/most-highlighted-books", async (req, res) => {
  try {
    const start = parseISO(req.query.start);
    const end   = parseISO(req.query.end);
    const coll  = await getColl();

    const data = await coll.aggregate(
      buildMostHighlightedBooksPipeline(start, end)
    ).toArray();

    res.json(data);
  } catch (e) {
    console.error("most-highlighted-books failed:", e);
    res.status(500).json({ error: "Failed to compute most highlighted books" });
  }
});

r.get("/top-books-by-reading-time", async (req, res) => {
  try {
    const start = parseISO(req.query.start);
    const end   = parseISO(req.query.end);
    const coll  = await getColl();

    const data = await coll.aggregate(
      buildTopBooksByReadingTimePipeline(start, end, req.query.limit)
    ).toArray();

    res.json(data);
  } catch (e) {
    console.error("top-books-by-reading-time failed:", e);
    res.status(500).json({ error: "Failed to compute top books by reading time" });
  }
});

export default r;
