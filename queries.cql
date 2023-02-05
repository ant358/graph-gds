
// Find the directors of Horror movies in the year 2000
MATCH(m:Movie)-[]->(g:Genre)
WHERE g.name = "Horror" AND m.year = 2000
MATCH (p:Person)-[:DIRECTED]->(m)
RETURN p

// query for NULL values
MATCH(m:Movie)
WHERE m.tmdbId IS NULL
RETURN COUNT(*)

// Where node labels and between
MATCH (p:Person)
WHERE p:Actor AND p:Director
AND  1950 <= p.born.year < 1960
RETURN p.name, labels(p), p.born

