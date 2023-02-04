// A Cypher projection takes three mandatory arguments: 
// graphName, nodeQuery, and relationshipQuery. 
// In addition, the optional configuration parameter allows us to further configure 
// graph creation.

// The graph is not set up to answer this question well with a direct native projection.
// However, we can use a cypher projection to filter to the appropriate nodes and 
// perform an aggregation to create an ACTED_WITH relationship that has a actedWithCount 
// property going directly between actor nodes.

CALL gds.graph.project.cypher(
  'proj-cypher',
  'MATCH (a:Actor) RETURN id(a) AS id, labels(a) AS labels',
  'MATCH (a1:Actor)-[:ACTED_IN]->(m:Movie)<-[:ACTED_IN]-(a2)
   WHERE m.year >= 1990 AND m.revenue >= 1000000
   RETURN id(a1) AS source , id(a2) AS target, count(*) AS actedWithCount, "ACTED_WITH" AS type'
);

// Run degree centality

// Once that is done we can apply degree centrality like we did last lesson. 
// Except we will weight the degree centrality by actedWithCount property and 
// also directly stream the top 10 results back. 
// This counts how many times the actor has acted with other actors in recent,
// high grossing movies


// Create a cypher projection representing all User nodes that have rated a Movie 
// with a release year greater than 2014. Only include RATED relationships with 
// ratings greater than or equal to 4 stars.
CALL gds.degree.stream('proj-cypher',{relationshipWeightProperty: 'actedWithCount'})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC LIMIT 10

CALL gds.graph.project.cypher(
  // Projection name
  'movie-ratings-after-2014',
  // Cypher statement to find all nodes in projection
  '
    MATCH (u:User) RETURN id(u) AS id, labels(u) AS labels
    UNION MATCH (m:Movie) WHERE m.year > 2014 RETURN id(m) AS id, labels(m) AS labels
  ',
  // Cypher statement to find every User that rated a Movie
  // where the rating property is greater than or equal to 4
  // and the movie was released after 2014 (year > 2014)
  '
    MATCH (u:User)-[r:RATED]->(m:Movie)
    WHERE r.rating >= 4 AND m.year > 2014
    RETURN id(u) AS source,
        id(m) AS target,
        r.rating AS rating,
        "RATED" AS type
  '
);
