// Create a graph projection

// list the graph projections that currently exist in our database
CALL gds.graph.list()
// create a projection from the Actor and Movie nodes and the ACTED_IN relationship
CALL gds.graph.project('my-graph-projection', ['Actor','Movie'], 'ACTED_IN')
// see information on the graph we just made
CALL gds.graph.list() YIELD graphName, nodeCount, relationshipCount, schema

//Running Algos

// run degree centrality on Actor nodes
CALL gds.degree.mutate('my-graph-projection', {mutateProperty:'numberOfMoviesActedIn'})

// run degree centrality on Actor nodes and stream the results
CALL gds.graph.nodeProperty.stream('my-graph-projection','numberOfMoviesActedIn')
YIELD nodeId, propertyValue
RETURN gds.util.asNode(nodeId).name AS actorName, propertyValue AS numberOfMoviesActedIn
ORDER BY numberOfMoviesActedIn DESCENDING, actorName LIMIT 10

// run degree centrality on Actor nodes and write the results back to the graph
CALL gds.graph.nodeProperties.write('my-graph-projection',['numberOfMoviesActedIn'], ['Actor'])
// We can then query the top 10 most prolific actors by movie count with Cypher.
MATCH (a:Actor)
RETURN a.name, a.numberOfMoviesActedIn
ORDER BY a.numberOfMoviesActedIn DESCENDING, a.name LIMIT 10

// Export graphs

// export a graph into a new database - effectively copying the projection 
// into a separate Neo4j database
gds.graph.export

// export a graph to csv files
gds.beta.graph.export.csv


// Drop the projected graph

// drop command
CALL gds.graph.drop('my-graph-projection')




