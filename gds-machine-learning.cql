// Machine Learning Pipelines on the graph

// Node Classification Pipelines: 
// Supervised binary and multi-class classification for nodes

// At a high level, your workflow will look like the following for node classification, 
// this will be the same for link prediction as well:

// 1. Project a graph and configure the pipeline (the order doesn’t matter).

// 2. Execute the pipeline with a train command.

// 3. Predict on a projected graph with the predict command. 
// The predictions can then be written back to the database if desired using graph write 
// operations.

// Example: Predicting Movie Genre with Node Classification












// Link Prediction Pipelines: 
// Supervised prediction for whether a relationship or "link" should exist 
// between pairs of nodes

