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

// Setting up the Problem
// For this example, we will train a model to predict which movies in the graph are comedies 
// which we will define as any movie that has a Genre of "Comedy".

// Genre is currently represented by its own node in the graph. 
// For this problem we need it represented as a property of the Movie node. 
// For demonstration purposes we will assign a cls property which is 1 if the movie 
// is a comedy and 0 otherwise

MATCH(m:Movie)-[:IN_GENRE]->(g)
WITH m , collect(g.name) AS genres
SET m.cls = toInteger('Comedy' IN genres)
RETURN count(m), m.cls;

// The Movie node also has some missing property values for runtime and imdbRating, 
// which could carry predictive signal for this problem. In a real-world scenario we 
// may want to impute values for these, for purposes of quick demonstration we will 
// just exclude them from the sample via label assignment. While we do this we will 
// filter the movies to only consider those released on or after 2010 as this type of 
// data may drift overtime making data further in the past less relevant.

MATCH(m:Movie)
WHERE m.year >= 2010
    AND m.runtime IS NOT NULL
    AND m.imdbRating IS NOT NULL
SET m:TrainMovie
RETURN count(m)

// Now we can project a graph using the TrainMovie node label. We will project mirroring 
// natural and reverse relationships then use collapsePath to provide a monopartite projection
// which will make the graph easier to handle inside the pipeline for a quick demonstration.

CALL gds.graph.project('proj',
    {
        Actor:{},
        TrainMovie:{ properties: ['cls', 'imdbRating', 'runtime']}
    },
    {
        ACTED_IN:{},
        HAD_ACTOR:{type:'ACTED_IN', orientation:'REVERSE'}
    }
);

CALL gds.beta.collapsePath.mutate('proj',
  {
    pathTemplates: [['HAD_ACTOR', 'ACTED_IN']],
    allowSelfLoops: false,
    mutateRelationshipType: 'SHARES_ACTOR_WITH'
  }
) YIELD relationshipsWritten;

// Configure the Pipeline
// The configuration steps are as follows. Technically they need not be configured in order,
// though it helps to do so to make things easy to follow.

// 1 Create the Pipeline

// 2 Add Node Properties

// 3 Select Node Properties as Features

// 4 Configure Node Splits

// 5 Add Model Candidates

// To get started, create the pipeline by running the following command

CALL gds.beta.pipeline.nodeClassification.create('pipe')

// Once that is complete we will add node properties. 
// A node classification pipeline can execute one or several GDS algorithms in mutate mode 
// that create node properties in the projection.

// For our problem, let’s do a few things

// First, lets generate FastRP embeddings which will encapsulate the locality of 
// movie nodes in the graph

CALL gds.beta.pipeline.nodeClassification.addNodeProperty('pipe', 'fastRP', {
  embeddingDimension: 32,
  randomSeed: 7474,
  mutateProperty:'embedding'
})
YIELD name, nodePropertySteps;

// Next, we can add degree centrality which will measure the number of other movies 
// that share actors.

CALL gds.beta.pipeline.nodeClassification.addNodeProperty('pipe', 'degree', {
  mutateProperty:'degree'
})
YIELD name, nodePropertySteps;

// Lastly, we will scale the runtime property which is good practice for values like this one 
// that are relatively high magnitude compared to the other properties.

CALL gds.beta.pipeline.nodeClassification.addNodeProperty('pipe', 'alpha.scaleProperties', {
  nodeProperties: ['runtime'],
    scaler: 'Log',
  mutateProperty:'logRuntime'
})
YIELD name, nodePropertySteps;

// Once the properties are configured, we can configure the subset of node properties that we 
// want to use as features for the model

CALL gds.beta.pipeline.nodeClassification.selectFeatures(
    'pipe',
    ['imdbRating', 'logRuntime', 'embedding', 'degree'])
YIELD name, featureProperties;

// After that we can configure the data splitting. In this case, it is fairly straightforward.
// We configure a testFraction which determines how to randomly split between test and training 
// nodes. Since the pipeline uses a cross-validation strategy, we can also set the number of 
// validation folds we want here.

CALL gds.beta.pipeline.nodeClassification.configureSplit('pipe', {
 testFraction: 0.2,
  validationFolds: 5
})
YIELD splitConfig;

// The final step to pipeline configuration is creating model candidates. 
// The pipeline is capable of running multiple models with different training methods and
// hyperparameter configurations. The best performing model will be selected after the 
// training step completes.

// To demonstrate, we will just add a few different logistic regressions here with different 
// penalty hyperparameters. GDS also has a random forest model and there are more 
// hyperparameters for each that we could adjust, see the Training methods docs for more details.

CALL gds.beta.pipeline.nodeClassification.addLogisticRegression('pipe', {penalty: 0.0})
YIELD parameterSpace;

CALL gds.beta.pipeline.nodeClassification.addLogisticRegression('pipe', {penalty: 0.1})
YIELD parameterSpace;

CALL gds.beta.pipeline.nodeClassification.addLogisticRegression('pipe', {penalty: 1.0})
YIELD parameterSpace;

// Train the Pipeline
// The following command will train the pipeline. This process will

// 1 Apply node and relationship filters

// 2 Execute the above pipeline configuration steps

// 3 Train with cross-validation for all the candidate models

// 4 Select the best candidate according to the metric parameter. 
// We will use ACCURACY for ease of interpretation but other F1 and precision/recall metrics
// exists, you can reference them in the documentation node classification pipelines 
// documentation here

// 5 Retrain the winning model on the entire training set and perform a final evaluation 
// on the test set according to the metric

// 6 Register the winning model in the model catalog

CALL gds.beta.pipeline.nodeClassification.train('proj', {
  pipeline: 'pipe',
  targetNodeLabels: ['TrainMovie'],
  modelName: 'nc-pipeline-model',
  targetProperty: 'cls',
  randomSeed: 7474,
  metrics: ['ACCURACY']
}) YIELD modelInfo
RETURN
  modelInfo.bestParameters AS winningModel,
  modelInfo.metrics.ACCURACY.train.avg AS avgTrainScore,
  modelInfo.metrics.ACCURACY.outerTrain AS outerTrainScore,
  modelInfo.metrics.ACCURACY.test AS testScore;
  
// This command should output training scores according to metric. 
// In this case we will get an accuracy of ~70%. Certainly a lot of room for improvement 
// given the class balance. There are plenty of ways this problem could be remodeled with 
// different features from the graph.

// Predict with the Pipeline
// The operation for predicting with the trained model and writing back to the graph has the 
// following form  

CALL gds.beta.pipeline.nodeClassification.predict.write(
  graphName: String,
  configuration: Map
)
YIELD
  preProcessingMillis: Integer,
  computeMillis: Integer,
  postProcessingMillis: Integer,
  writeMillis: Integer,
  nodePropertiesWritten: Integer,
  configuration: Map
 
 // The operation also supports stream and mutate execution modes.

// You can use this to classify newly added nodes or nodes in other regions of the graph. 
// We will not go over a specific example here (We will spend some time on using predict in the 
// link prediction lesson).
 
  

// Link Prediction Pipelines: 
// Supervised prediction for whether a relationship or "link" should exist 
// between pairs of nodes


//Example: Predicting Actor Relationships with Link Prediction
// Setting up the Problem
// Our movie recommendations dataset, as-is, is not the best candidate for this type of 
// link prediction since it is a k-partite graph, i.e. relationships only go between 
// disjoint sets of nodes. In this case those sets can align with the node labels: 
// User, Movie, Person, and Genre. For sake of showing a quick example, we will manufacture
// a social network out of the graph. We will filter down to just big, high grossing movies 
// then create ACTED_WITH relationships between actors that were in the same movies together. 
// There are a couple extra steps here to get the graph truly undirected as we need it.

//set a node label based on recent release and revenue conditions
MATCH (m:Movie)
WHERE m.year >= 1990 AND m.revenue >= 1000000
SET m:RecentBigMovie;

//native projection with reverse relationships
CALL gds.graph.project('proj',
  ['Actor','RecentBigMovie'],
  {
  	ACTED_IN:{type:'ACTED_IN'},
    HAS_ACTOR:{type:'ACTED_IN', orientation: 'REVERSE'}
  }
);

//collapse path utility for relationship aggregation - no weight property
CALL gds.beta.collapsePath.mutate('proj',{
    pathTemplates: [['ACTED_IN', 'HAS_ACTOR']],
    allowSelfLoops: false,
    mutateRelationshipType: 'ACTED_WITH'
});

//write relationships back to graph
CALL gds.graph.writeRelationship('proj', 'ACTED_WITH');

//drop duplicates
MATCH (a1:Actor)-[s:ACTED_WITH]->(a2)
WHERE id(a1) < id(a2)
DELETE s;

//clean up extra labels
MATCH (m:RecentBigMovie) REMOVE m:RecentBigMovie;

//project the graph
CALL gds.graph.drop('proj');
CALL gds.graph.project('proj', 'Actor', {ACTED_WITH:{orientation: 'UNDIRECTED'}});

// This gives us a graph projection with just Actor nodes and ACTED_WITH relationships, 
// like a 'co-acting' social network. When we use link prediction in this context, we will be
// training a model to predict which actors are most likely to be in the same movies together 
// given other ACTED_WITH relationships already present in the graph. This same methodology 
// can be used for different social network recommendation problems. For example, if instead 
// of actors co-acting with each other we had users who were friends with each other, we 
// could use a model like this to make friend recommendations. Likewise in fraud detection 
// and law enforcement applications, if we have communities of suspects and victims who know 
// or interact with each other, we could use link prediction to infer real-world relationships 
// not already known in the graph.

// Configure the Pipeline
// The configuration steps are as follows. Technically they need not be configured in order, 
// though it helps to do so to make things easy to follow.

// 1 Create the Pipeline

// 2 Add Node Properties

// 3 Add Link Features

// 4 Configure Relationship Splits

// 5 Add Model Candidates

To get started, create the pipeline by running the following command:

CALL gds.beta.pipeline.linkPrediction.create('pipe');

// This stores the pipeline in the pipeline catalog.

// Next, we can add node properties, just like we did with the node classification pipeline.

// For this example, let’s use fastRP node embeddings with the logic that if two actors are 
// close to each other in the ACTED_WITH network they are more likely to also play roles in 
// the same movies. Degree centrality is also another potentially interesting feature, 
// i.e. more prolific actors are more likely to be in the same movies with other actors.

CALL gds.beta.pipeline.linkPrediction.addNodeProperty('pipe', 'fastRP', {
    mutateProperty: 'embedding',
    embeddingDimension: 128,
    randomSeed: 7474
}) YIELD nodePropertySteps;

CALL gds.beta.pipeline.linkPrediction.addNodeProperty('pipe', 'degree', {
    mutateProperty: 'degree'
}) YIELD nodePropertySteps;

// Next we will add link features. This step configures a symmetric function that takes the 
// properties from the node pair and computes features for the link prediction model. 
// The types of link feature functions you can use are covered in the link prediction 
// pipelines documentation here. For this problem we use cosine distance and L2 for the 
// FastRP embeddings, which are good measure of similarity/distance and hadamard for the degree 
// centrality which are a good measure of total magnitude between the 2 nodes.

CALL gds.beta.pipeline.linkPrediction.addFeature('pipe', 'l2', {
  nodeProperties: ['embedding']
}) YIELD featureSteps;

CALL gds.beta.pipeline.linkPrediction.addFeature('pipe', 'cosine', {
  nodeProperties: ['embedding']
}) YIELD featureSteps;

CALL gds.beta.pipeline.linkPrediction.addFeature('pipe', 'hadamard', {
  nodeProperties: ['degree']
}) YIELD featureSteps;

// After that we configure the relationship splitting which sets the train/test/feature set 
// proportions, the negative sampling ratio, and the number of validations folds used in 
// cross-validation. For our example, we will split the relationship into 20% test, 40% train, 
// and 40% feature-input. This gives us a good balance between all the sets. We will also use 
// 2.0 for the negative sampling ratio, giving us a sizable negative example for demonstration 
// that won’t take too long to estimate. In the context of link prediction, a negative example 
// is any node pair without a link between it. These are randomly sampled in the relationship 
// splitting step. You can read more on different strategies for setting the negative sample 
// ratio in the Link Prediction Pipelines documentation.

CALL gds.beta.pipeline.linkPrediction.configureSplit('pipe', {
    testFraction: 0.2,
    trainFraction: 0.5,
    negativeSamplingRatio: 2.0
}) YIELD splitConfig;

// Just like with node classification, the final step to pipeline configuration is creating 
// model candidates. The pipeline is capable of running multiple models with different training
// methods and hyperparameter configurations. The best performing model will be selected after 
// the training step completes.

// To demonstrate, we will just add a few different logistic regressions here with different 
// penalty hyperparameters. GDS also has a random forest model and there are more hyperparameters
// for each that we could adjust, see the docs for more details.

CALL gds.beta.pipeline.linkPrediction.addLogisticRegression('pipe', {
    penalty: 0.001,
    patience: 2
}) YIELD parameterSpace;

CALL gds.beta.pipeline.linkPrediction.addLogisticRegression('pipe', {
    penalty: 1.0,
    patience: 2
}) YIELD parameterSpace;

// Train the Pipeline
// The following command will train the pipeline. This process will:

// 1 Apply node and relationship filters

// 2 Execute the above pipeline configuration steps

// 3 Train with cross-validation for all the candidate models

// 4 Select the best candidate according to the average precision-recall, a.k.a. AUCPR.

// 5 Retrain the winning model on the entire training set and do a final evaluation on the test with AUCPR

// 6 Register the winning model in the model catalog

CALL gds.beta.pipeline.linkPrediction.train('proj', {
    pipeline: 'pipe',
    modelName: 'lp-pipeline-model',
    targetRelationshipType: 'ACTED_WITH',
    randomSeed: 7474 //usually a good idea to set a random seed for reproducibility.
}) YIELD modelInfo
RETURN
modelInfo.bestParameters AS winningModel,
modelInfo.metrics.AUCPR.train.avg AS avgTrainScore,
modelInfo.metrics.AUCPR.outerTrain AS outerTrainScore,
modelInfo.metrics.AUCPR.test AS testScore

// Prediction with the Model
// Once the pipeline is trained we can use it to predict new links in the graph. 
// The pipeline can be re-applied to data with the same schema. Below we show a streaming 
// example, but this also has a mutate mode which can then be used

CALL gds.beta.pipeline.linkPrediction.predict.stream('proj', {
  modelName: 'lp-pipeline-model',
  sampleRate:0.1,
  topK:1,
  randomSeed: 7474,
  concurrency: 1
})
 YIELD node1, node2, probability
 RETURN gds.util.asNode(node1).name AS actor1, gds.util.asNode(node2).name AS actor2, probability
 ORDER BY probability DESC, actor1
 
 // This operation supports a mutate execution mode to save the predicted links in the graph projection. If you want to write back to the database you can use the mutate mode followed by the gds.graph.writeRelationship command covered in the graph catalog documentation.

This predict operation also has various sampling parameters that can be leveraged to more 
// efficiently evaluate the large number of possible node pairs. The procedure will only 
// select node pairs that do not currently have a link between them. You can read more about 
// the procedure and parameters for sampling in the link prediction pipelines documentation here.







