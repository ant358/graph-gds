// Similarity Algos
// used to infer similarity between pairs of nodes
// When similar node pairs are identified according to the user specified metric 
// and threshold, a relationship with a similarity score property is drawn between the pair

// Uses
// Fraud detection: 
// finding potential fraud user accounts by analyzing how similar a set of new 
// user accounts is to flagged accounts

// Recommendation Systems: In an online retail store, identifying items that pair 
// to the one currently being viewed by a user to inform impressions and increase 
// rate of purchase

// Entity Resolution: 
// Identify nodes that are similar to one another based on activity or identifying 
// information in the graph

// Similarity Algorithms in GDS
// Node Similarity: 
// Determines similarity between nodes based on the relative proportion of shared 
// neighboring nodes in the graph. Node Similarity is a good choice where explainability 
// is important, and you can narrow down the universe of comparisons to a subset 
// of your data. Examples of narrowing down include focusing on just single communities,
// newly added nodes, or nodes within a specific proximity to a subgraph of interest.

// K-Nearest Neighbor (KNN): 
// Determines similarity based off node properties. 
// The GDS KNN implementation can scale well for global inference over large graphs 
// when tuned appropriately. it can be used in conjunction with embeddings and other graph 
// algorithms to determine the similarity between nodes based on proximity in the graph, 
// node properties, community structure, importance/centrality, etc.

// Both Node Similarity and KNN provide choices between different similarity metrics. 
// Node Similarity has choices between Jaccard and Overlap similarity. 
// KNN choice of metric is driven by the node property types. List of integers are 
// subject to Jaccard and Overlap, list of floating point numbers to Cosine Similarity, 
// Pearson, and Euclidean. Using different metrics will of course alter the similarity 
// score and change the interpretation slightly. 

// KNN example
// Project the graph
CALL gds.graph.project('proj', ['Movie', 'Person'], {
    ACTED_IN:{orientation:'UNDIRECTED'},
    DIRECTED:{orientation:'UNDIRECTED'}
});

// FastRP like in the last lesson except in mutate mode so the embeddings will be 
// saved in the projection
CALL gds.fastRP.mutate('proj',  {
    embeddingDimension:64,
    randomSeed:7474,
    mutateProperty:'embedding'
})

// run similarity. We will use the default cosine metric.
CALL gds.knn.stream('proj', {nodeLabels:['Person'], nodeProperties:['embedding'], topK:1})
YIELD  node1, node2, similarity
RETURN gds.util.asNode(node1).name AS actorName1,
    gds.util.asNode(node2).name AS actorName2,
    similarity
LIMIT 10


