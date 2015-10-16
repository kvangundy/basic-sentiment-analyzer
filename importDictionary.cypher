//Sentiment Dictionary Import
CREATE CONSTRAINT ON (w:Word) ASSERT w.word IS UNIQUE;
CREATE CONSTRAINT ON (p:Polarity) ASSERT p.polarity IS UNIQUE;

//create poles

CREATE
(:Polarity {polarity:"positive"}),
(:Polarity {polarity:"negative"});

//import corpus

USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/kvangundy/neo4j-sentiment-analysis/master/sentimentDict.csv" AS line
WITH line
CREATE (a:Word {word:line.word});
USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/kvangundy/neo4j-sentiment-analysis/master/sentimentDict.csv" AS line
WITH line
MATCH (w:Word {word:line.word}), (p:Polarity {polarity:line.polarity})
MERGE (w)-[:SENTIMENT]->(p);
