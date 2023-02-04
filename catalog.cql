// Create a native graph projection

// The native projection takes three mandatory arguments: 
// graphName, nodeProjection and relationshipProjection. 
// In addition, the optional configuration parameter allows us to 
// further configure the graph creation.

// list the graph projections that currently exist in our database
CALL gds.graph.list()

// create a projection from the Actor and Movie nodes and the ACTED_IN relationship
  CALL gds.graph.project('my-graph-projection', ['Actor','Movie'], 'ACTED_IN')
// project the User and Movie nodes with the RATED relationship. 
// This type of projection is very common for graph data science based Recommendation Systems
  CALL gds.graph.project('native-proj',['User', 'Movie'], ['RATED']);
// The wildcard character '*' can be used to include all nodes and/or relationships in the database.
  CALL gds.graph.project('native-proj','*', '*');
// add relationship properties to the projection
  CALL gds.degree.mutate('native-proj', {mutateProperty: 'ratingCount'});
// Display (stream) the results
  CALL gds.graph.nodeProperty.stream('native-proj','ratingCount', ['Movie'])
  YIELD nodeId, propertyValue
  RETURN gds.util.asNode(nodeId).title AS movieTitle, propertyValue AS ratingCount
  ORDER BY movieTitle DESCENDING LIMIT 10
// If the values are zero - it is due to the relantionship direction - fix
  CALL gds.graph.drop('native-proj', false);

  //replace with a project that has reversed relationship orientation
  CALL gds.graph.project(
      'native-proj',
      ['User', 'Movie'],
      {RATED_BY: {type: 'RATED', orientation: 'REVERSE'}}
  );

  CALL gds.degree.mutate('native-proj', {mutateProperty: 'ratingCount'});

// Add multiple node properties and relationship properties
  CALL gds.graph.drop('native-proj', false);

  CALL gds.graph.project(
      'native-proj',
      ['User', 'Movie'],
      {RATED: {orientation: 'UNDIRECTED'}},
      {
          nodeProperties:{
              revenue: {defaultValue: 0}, // the defaultValue parameter allows us to fill in missing values with a default. In this case we use 0.
              budget: {defaultValue: 0},
              runtime: {defaultValue: 0}
          },
          relationshipProperties: ['rating'] // simpler syntax with no default values as these should not be missing according to the data model.
      }
  );

// Aggregate parrell relationships into a single relationship
  CALL gds.graph.project(
    'user-proj',
    ['User'],
    {
      SENT_MONEY_TO: {
        properties: {
          totalAmount: {
            property: 'amount',
            aggregation: 'SUM'
          }
        }
      }
    }
  );


// see information on the graph we just made
  CALL gds.graph.list() YIELD graphName, nodeCount, relationshipCount, schema

// If the projection already exists you will have to drop it first
  CALL gds.graph.drop('native-proj');


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




