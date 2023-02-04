// Path Finding Algos
// Path finding algorithms find the shortest path between two or more nodes 
// or evaluate the availability and quality of paths.

// Common Uses
// Supply chain analytics: 
// Identifying the fastest path between an origin and a destination or between 
// a raw material and a finished product

// Customer Journey: 
// Analyzing the events that make up a customer’s experience. In healthcare for example, 
// this can be the experience of an in-patient from admission to discharge.

// Dijkstra Source-Target Shortest Path
// A common, industry standard, path finding algorithm is Dijkstra. 
// It computes the shortest path between a source and a target node.

// create the graph projection
CALL gds.graph.project('proj',
    ['Person','Movie'],
    {
        ACTED_IN:{orientation:'UNDIRECTED'},
        DIRECTED:{orientation:'UNDIRECTED'}
    }
);

// run Dijkstra’s shortest path
MATCH (a:Actor)
WHERE a.name IN ['Kevin Bacon', 'Denzel Washington']
WITH collect(id(a)) AS nodeIds
CALL gds.shortestPath.dijkstra.stream('proj', {sourceNode:nodeIds[0], TargetNode:nodeIds[1]})
YIELD sourceNode, targetNode, path
RETURN gds.util.asNode(sourceNode).name AS sourceNodeName,
    gds.util.asNode(targetNode).name AS targetNodeName,
    nodes(path) as path;
    
// A* Shortest Path: 
// An extension of Dijkstra that uses a heuristic function to speed up computation.

// Yen’s Algorithm Shortest Path: 
// An extension of Dijkstra that allows you to find multiple, the top k, shortest paths.

// Shortest path between a source node and multiple other target nodes:

// Dijkstra Single-Source Shortest Path: 
// Dijkstra implementation for shortest path between one source and multiple targets.

// Delta-Stepping Single-Source Shortest Path: 
// Parallelized shortest path computation. Computes faster than 
// Dijkstra single-source shortest Path but uses more memory.

// General path search between a source node and multiple other target nodes:

// Breadth First Search: 
// Searches paths in order of increasing distance from the source node on each iteration.

// Depth First Search: Searches as far as possible along a single multi-hop path on each iteration.

// Example
// Using just the Actor and Movie nodes and the ACTED_IN and DIRECTED relationships, what is the shortest path
// (by number of relationship hops) between Kevin Bacon and Peta Wilson.

CALL gds.graph.project('proj',
    ['Actor','Movie'],
    {
        ACTED_IN:{orientation:'UNDIRECTED'},
        DIRECTED:{orientation:'UNDIRECTED'}
    }
);

MATCH (a:Actor)
WHERE a.name IN ['Kevin Bacon', 'Peta Wilson']
WITH collect(id(a)) AS nodeIds
CALL gds.shortestPath.dijkstra.stream('proj', {sourceNode:nodeIds[0], TargetNode:nodeIds[1]})
YIELD sourceNode, targetNode, path
RETURN gds.util.asNode(sourceNode).name AS sourceNodeName,
    gds.util.asNode(targetNode).name AS targetNodeName,
    nodes(path) as path;
    
