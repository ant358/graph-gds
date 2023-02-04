// list the graph projections that currently exist in our database
CALL gds.graph.list()
// create a projection from the Actor and Movie nodes and the ACTED_IN relationship
CALL gds.graph.project('my-graph-projection', ['Actor','Movie'], 'ACTED_IN')
// see information on the graph we just made
CALL gds.graph.list() YIELD graphName, nodeCount, relationshipCount, schema

//Running Algos

