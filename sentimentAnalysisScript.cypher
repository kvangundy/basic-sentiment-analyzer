//algo starts here
CREATE INDEX ON :ReviewWords(word);
//
MATCH (n:Review)
WHERE n.analyzed = FALSE
WITH n, split(n.review, " ") as words
UNWIND words as word
CREATE (rw:ReviewWords {word:word})
WITH n, rw
CREATE (rw)-[:IN_REVIEW]->(n);
//
MATCH (n:Review)-[:IN_REVIEW]-(wordReview), (wordSentiment:Word)-[:SENTIMENT]-(sentiment)
WHERE wordReview.word = wordSentiment.word
CREATE UNIQUE (wordReview)-[:TEMP]->(wordSentiment);
//
//scoring function
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
OPTIONAL MATCH pos = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(word)-[:SENTIMENT]-(:Polarity {polarity:'positive'})
WITH n, count(pos) as plus
OPTIONAL MATCH neg = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(word)-[:SENTIMENT]-(:Polarity {polarity:'negative'})
WITH plus, COUNT(neg) as minus, n
SET n.sentimentScore = plus - minus;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore > 0
SET n.sentiment = 'positive', n.analyzed = TRUE
DELETE w, r, rr;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore < 0
SET n.sentiment = 'negative', n.analyzed = TRUE
DELETE w, r, rr;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore = 0
SET n.sentiment = 'neutral', n.analyzed = TRUE
DELETE w, r, rr;
//
//cleanup
MATCH (:Review)-[r]-(deleteMe:ReviewWords)
DELETE r, deleteMe;
