// Report for average session duration per user
db.reading_sessions.aggregate([
    {
        $group: {
            _id: "$user_id",
            avgSessionMinutes: {
                $avg: { $divide: [{ $subtract: ["$end_time", "$start_time"] }, 60000] } // milisecond to minute
            }
        }
    },
    { $project: { _id: 0, user_id: "$_id", avgSessionMinutes: { $round: ["$avgSessionMinutes", 2] } } },
    {
        $sort: { user_id: 1 }
    }
])

// Report for most highlighted books
// Find the max number of highlights and store it in a variable
const result = db.reading_sessions.aggregate([
    { $unwind: "$highlights" },
    {
        $group: {
            _id: "$book_id",
            totalHighlights: { $sum: 1 }
        }
    },
    { $sort: { totalHighlights: -1 } },
    { $limit: 1 }
]).toArray();
// Query again for all books that have the match with this max value
const maxHighlights = result[0].totalHighlights;

db.reading_sessions.aggregate([
    { $unwind: "$highlights" },
    {
        $group: {
            _id: "$book_id",
            book_id: { $first: "$book_id" },
            totalHighlights: { $sum: 1 }
        }
    },
    { $project: { _id: 0 } },
    { $match: { totalHighlights: maxHighlights } }
])

// Report for Top 10 books by reading time
db.reading_sessions.aggregate([
    {
        $group: {
            _id: "$book_id",
            totalReadingMinutes: {
                $sum: { $divide: [{ $subtract: ["$end_time", "$start_time"] }, 60000] }  // milisecond to minute
            }
        }
    },
    { $project: { _id: 0, book_id: "$_id", totalReadingMinutes: { $round: ["$totalReadingMinutes", 2] } } },
    {
        $sort: { totalReadingMinutes: -1 }
    },
    { $limit: 10 }
])