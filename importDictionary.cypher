//Sentiment Dictionary Import
CREATE CONSTRAINT ON (w:Word) ASSERT w.word IS UNIQUE;
CREATE CONSTRAINT ON (p:Polarity) ASSERT p.polarity IS UNIQUE;
CREATE
(:Polarity {polarity:"positive"}),
(:Polarity {polarity:"negative"});
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///Users/kevinvangundy/Desktop/Neo4j-Projects/aGraph3Ways/sentimentDict.csv" AS line
WITH line
MERGE (a:Word {word:line.word})
ON CREATE SET a.partSpeech = line.wordType, a.wordType = line.stype;
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///Users/kevinvangundy/Desktop/Neo4j-Projects/aGraph3Ways/sentimentDict.csv" AS line
WITH line
WHERE NOT line.polarity = 'neutral'
MATCH (w:Word {word:line.word}), (p:Polarity {polarity:line.polarity})
MERGE (w)-[:SENTIMENT]->(p);
