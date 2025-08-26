export function firstResult(rows) {
return Array.isArray(rows) && Array.isArray(rows[0]) ? rows[0] : rows;
}