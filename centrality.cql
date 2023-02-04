// Centrality Algos

// Uses - Recomendations, Supply chain analytics, Fraud and anomaly detection

// Degree Centrality example
// It counts the number of relationships a node has
CALL gds.graph.project('proj', ['Actor','Movie'], 'ACTED_IN');

//get top 5 most prolific actors (those in the most movies)
//using degree centrality which counts number of `ACTED_IN` relationships
CALL gds.degree.stream('proj')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS actorName, score AS numberOfMoviesActedIn
ORDER BY numberOfMoviesActedIn DESCENDING, actorName LIMIT 5

// PageRank Algorithim
// A good algorithm for measuring the influence of nodes in a directed graph, 
// particularly where the relationships imply some form of flow of movement 
// such as in payment networks.

// In summary, PageRank estimates the importance of a node by counting the number 
// of incoming relationships from neighboring nodes weighted by the importance and 
// out-degree centrality of those neighbors. The underlying assumption is that more 
// important nodes are likely to have proportionately more incoming relationships from 
// other important nodes.

// Below is an example of applying PageRank to find the most influential persons in 
// the Director → Actor network from movies released on or after 1990 with a revenue 
// of at least 10 Million dollars.

//drop last graph projection
CALL gds.graph.drop('proj', false);

//create Cypher projection for network of people directing actors
//filter to recent high grossing movies
CALL gds.graph.project.cypher(
  'proj',
  'MATCH (a:Person) RETURN id(a) AS id, labels(a) AS labels',
  'MATCH (a1:Person)-[:DIRECTED]->(m:Movie)<-[:ACTED_IN]-(a2)
   WHERE m.year >= 1990 AND m.revenue >= 10000000
   RETURN id(a1) AS source , id(a2) AS target, count(*) AS actedWithCount,
    "DIRECTED_ACTOR" AS type'
);

// stream PageRank to find the top 5 most influential people in director-actor
CALL gds.pageRank.stream('proj')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS personName, score AS influence
ORDER BY influence DESCENDING, personName LIMIT 5

// Betweenness Centrality: 
// Measures the extent to which a node stands between the other 
// nodes in a graph. It is often used to find nodes that serve as a bridge 
//from one part of a graph to another.

// Eigenvector Centrality: 
// Measures the transitive influence of nodes. Similar to PageRank, 
// but works only on the largest eigenvector of the adjacency matrix so does 
// not converge in the same way and tends to more strongly favor high degree nodes. 
// It can be more appropriate in certain use cases, particularly those with undirected 
// relationships.

// Article Rank: 
// A variant of PageRank which assumes that relationships originating from low-degree 
// nodes have a higher influence than relationships from high-degree nodes.

