//  Community Detection

// Community detection algorithms are used to evaluate how groups of nodes may be clustered 
// or partitioned in the graph. Much of the community detection functionality in GDS is 
// focused on distinguishing and assigning ids to these node groups for downstream analytics,
// visualization, or other processing.

// Common use cases of community detection include:

//Fraud detection: 
// Finding fraud rings by identifying accounts that have frequent suspicious transactions 
// and/or share identifiers between one another.

// Customer 360: 
// Disambiguating multiple records and interactions into a single customer profile so an 
// organization has an aggregated source of truth for each customer.

// Market segmentation: 
// dividing a target market into approachable subgroups based on priorities, 
// behaviors, interests, and other criteria.

// Louvian Community Detection
// Louvain optimizes this modularity with a hierarchical clustering 
// approach that recursively merges communities together
// Louvain is a stochastic algorithm. As such, the community assignments may change a bit when re-run

// Louvian Example
// understand communities of actors and directors in our movies recommendations graph.
// relationships with an UNDIRECTED orientation as that works best with the Louvain
CALL gds.graph.project('proj', ['Movie', 'Person'], {
    ACTED_IN:{orientation:'UNDIRECTED'},
    DIRECTED:{orientation:'UNDIRECTED'}
});

// Here we will run Louvain in mutate mode to save community Ids and return high level
// statistics on the community counts, distribution, modularity score, and information 
// for how Louvain processed the graph.
CALL gds.louvain.mutate('proj', {mutateProperty:'communityId'})

// We can verify the communityId node properties in the projection with a stream operation
CALL gds.graph.nodeProperty.stream('proj','communityId', ['Person'])
YIELD nodeId, propertyValue
WITH gds.util.asNode(nodeId) AS n, propertyValue AS communityId
WHERE n:Person
RETURN n.name, communityId LIMIT 10

// write the communityId to the node
CALL gds.graph.nodeProperties.write('proj','communityId', ['Person'])

// Q how to create a node for each Id? and :IS_IN_COMMUNITY ? 

// Other Community Detection Algorithms

// Label Propagation: 
// Similar intent as Louvain. Fast algorithm that parallelizes well. Great for large graphs.

// Weakly Connected Components (WCC): 
// Partitions the graph into sets of connected nodes such that
// Every node is reachable from any other node in the same set
// No path exists between nodes from different sets

// Triangle Count: 
// Counts the number of triangles for each node. 
// Can be used to detect the cohesiveness of communities and stability of the graph.

// Local Clustering Coefficient: Computes the local clustering coefficient for each node 
// in the graph which is an indicator for how the node clusters with its neighbors.




