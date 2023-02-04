// Node Embedding
// The goal of node embedding is to compute low-dimensional vector representations of nodes 
// such that similarity between vectors

// Uses

// Exploratory Data Analysis (EDA)
// such as visualizing the embeddings in a TSNE plot to better understand the graph 
// structure and potential clusters of nodes

// Similarity Measurements: Node embedding allows you to scale similarity inferences 
// in large graphs using K Nearest Neighbor (KNN) or other techniques. 
// This can be useful for scaling memory based recommendation systems, such as variations of collaborative filtering. It can also be used for semi-supervised techniques in areas like fraud detection, where, for example, we may want to generate leads that are similar to a group of known fraudulent entities.

// Features for Machine Learning: Node embedding vectors naturally plug in as features 
// for a variety of machine learning problems. For example, in a graph of user purchases 
// for on online retailer, we could use embeddings to train a machine learning model to 
// predict what products a user may be interested in buying next.

// FastRP
// FastRP leverages probabilistic sampling techniques to generate sparse representations 
// of the graph allowing for extremely fast calculation of embedding vectors
// There are multiple tuning parameters for FastRP
// FastRP is that, while we won’t cover it here, it has the ability to consider node and 
// relationship property weights when generating embeddings.

// FastRPP example
// Generate FastRP embeddings on person nodes in the movies graph based 
// on the movies they acted in and/or directed.

CALL gds.graph.project('proj', ['Movie', 'Person'], {
    ACTED_IN:{orientation:'UNDIRECTED'},
    DIRECTED:{orientation:'UNDIRECTED'}
});

// For demonstration purposes we will just use an embedding dimension of 64. We have the option of setting a randomSeed 
// here as well to control consistency between runs.

CALL gds.fastRP.stream('proj',  {embeddingDimension:64, randomSeed:7474})
YIELD nodeId, embedding
WITH gds.util.asNode(nodeId) AS n, embedding
WHERE n:Person
RETURN id(n), n.name, embedding LIMIT 10

// These embeddings, can, in theory, be used for similarity measurements to understand 
// which actors are most similar and can be used in a content recommendation system to 
// recommend movies to users based on the actors and/or directors for movies they recently 
// viewed.

// Other Node Embedding Algorithms

// Node2Vec
// which computes a vector representation of a node based on random walks in the graph

// GraphSage
// which is an inductive modeling approach for computing node embeddings using node 
// properties and graph structure.

