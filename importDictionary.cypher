//Sentiment Dictionary Import
CREATE CONSTRAINT ON (w:Word) ASSERT w.word IS UNIQUE;
CREATE CONSTRAINT ON (w:Keyword) ASSERT w.word IS UNIQUE;
CREATE CONSTRAINT ON (p:Polarity) ASSERT p.polarity IS UNIQUE;

//create poles

CREATE
(:Polarity {polarity:"positive"}),
(:Polarity {polarity:"negative"});

//import corpus

USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/kvangundy/ThreeEye-neo4j-sentiment-analyzer/master/sentimentDict.csv" AS line
WITH line
MERGE (a:Keyword {word:line.word});
USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/kvangundy/ThreeEye-neo4j-sentiment-analyzer/master/sentimentDict.csv" AS line
WITH line
MATCH (w:Keyword {word:line.word}), (p:Polarity {polarity:line.polarity})
MERGE (w)-[:SENTIMENT]->(p);
