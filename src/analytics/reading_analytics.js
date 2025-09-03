export function parseISO(d) {
    if (!d) return null;
    const dt = new Date(d);
    return isNaN(dt.getTime()) ? null : dt;
}
  
export function dateMatch(start, end) {
    const clauses = [
      { start_time: { $type: "date" } },
      { end_time: { $type: "date" } },
    ];
    if (start) clauses.push({ start_time: { $gte: start } });
    if (end) clauses.push({ end_time: { $lte: end } });
    return clauses.length ? { $and: clauses } : {};
}
  
export function buildAvgSessionMinutesPipeline(
    start,
    end,
    { limit = 5, sort = "avg_desc" } = {}
  ) {
    const sortStage =
      sort === "avg_desc"
        ? { avgSessionMinutes: -1 }
        : sort === "avg_asc"
        ? { avgSessionMinutes: 1 }
        : { user_id: 1 };
  
    return [
      { $match: dateMatch(start, end) },
      {
        $group: {
          _id: "$user_id",
          avgSessionMinutes: {
            $avg: { $divide: [{ $subtract: ["$end_time", "$start_time"] }, 60000] },
          },
        },
      },
      {
        $project: {
          _id: 0,
          user_id: "$_id",
          avgSessionMinutes: { $round: ["$avgSessionMinutes", 2] },
        },
      },
      { $sort: sortStage },
      { $limit: Math.max(1, Math.min(100, Number(limit) || 5)) },
    ];
}
  
export function buildMostHighlightedBooksPipeline(start, end, limit = 5) {
    return [
      { $match: dateMatch(start, end) },
      { $unwind: "$highlights" },
      { $group: { _id: "$book_id", totalHighlights: { $sum: 1 } } },
      {
        $group: {
          _id: null,
          maxHighlights: { $max: "$totalHighlights" },
          items: { $push: { book_id: "$_id", totalHighlights: "$totalHighlights" } },
        },
      },
      {
        $project: {
          _id: 0,
          items: {
            $filter: {
              input: "$items",
              as: "it",
              cond: { $eq: ["$$it.totalHighlights", "$maxHighlights"] },
            },
          },
        },
      },
      { $unwind: "$items" },
      { $replaceWith: "$items" },
      { $sort: { book_id: 1 } },
      { $limit: Math.max(1, Math.min(100, Number(limit) || 5)) },
    ];
}
  
export function buildTopBooksByReadingTimePipeline(start, end, limit = 5) {
    const lim = Math.max(1, Math.min(100, Number(limit) || 10));
    return [
      { $match: dateMatch(start, end) },
      {
        $group: {
          _id: "$book_id",
          totalReadingMinutes: {
            $sum: { $divide: [{ $subtract: ["$end_time", "$start_time"] }, 60000] },
          },
        },
      },
      {
        $project: {
          _id: 0,
          book_id: "$_id",
          totalReadingMinutes: { $round: ["$totalReadingMinutes", 2] },
        },
      },
      { $sort: { totalReadingMinutes: -1 } },
      { $limit: lim },
    ];
}
  
export async function avgSessionMinutes(coll, start, end) {
    return coll.aggregate(buildAvgSessionMinutesPipeline(start, end)).toArray();
}
  
export async function mostHighlightedBooks(coll, start, end) {
    return coll.aggregate(buildMostHighlightedBooksPipeline(start, end)).toArray();
}
  
export async function topBooksByReadingTime(coll, start, end, limit) {
    return coll
      .aggregate(buildTopBooksByReadingTimePipeline(start, end, limit))
      .toArray();
}
  