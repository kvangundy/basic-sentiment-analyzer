//stanfordTest
//using test data from: http://ai.stanford.edu/~amaas/data/sentiment/

USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/kvangundy/neo4j-sentiment-analysis/master/efficacyTesting/negatives.csv" as line
WITH line
CREATE (r:Review {review:toLOWER(line.review), trueSentiment:0, analyzed:FALSE});
//
USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/kvangundy/neo4j-sentiment-analysis/master/efficacyTesting/positives.csv" as line
WITH line
CREATE (r:Review {review:toLOWER(line.review), trueSentiment:1, analyzed:FALSE});
//
//algo starts here
CREATE INDEX ON :ReviewWords(word);
CREATE INDEX ON :Review(sentiment);
//
MATCH (n:Review)
WHERE n.analyzed = FALSE
WITH n, split(n.review, " ") as words
UNWIND words as word
CREATE (rw:ReviewWords {word:word})
WITH n, rw
CREATE (rw)-[:IN_REVIEW]->(n);
//
//wordCounts
MATCH (n:Review)
WITH n, size((n)<-[:IN_REVIEW]-()) as wordCount
SET n.wordCount = wordCount;
//
MATCH (n:Review)-[:IN_REVIEW]-(wordReview), (wordSentiment:Word)-[:SENTIMENT]-(sentiment)
WHERE wordReview.word = wordSentiment.word
CREATE UNIQUE (wordReview)-[:TEMP]->(wordSentiment);
//
//scoring function
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
OPTIONAL MATCH pos = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(word)-[:SENTIMENT]-(:Polarity {polarity:'positive'})
WITH n, toFloat(count(pos)) as plus
OPTIONAL MATCH neg = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(word)-[:SENTIMENT]-(:Polarity {polarity:'negative'})
WITH ((plus - COUNT(neg))/n.wordCount) as score, n
SET n.sentimentScore = score;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
//5% polarization
WHERE n.sentimentScore >= (.05)
SET n.sentiment = 'positive', n.analyzed = TRUE
DELETE w, r, rr;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
//5% polarization
WHERE n.sentimentScore <= (-.05)
SET n.sentiment = 'negative', n.analyzed = TRUE
DELETE w, r, rr;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
//5% polarization
WHERE (.05) > n.sentimentScore > (-.05)
SET n.sentiment = 'neutral', n.analyzed = TRUE
DELETE w, r, rr;
//
//cleanup
MATCH (:Review)-[r]-(deleteMe:ReviewWords)
DELETE r, deleteMe;
//
//how’d we do?
MATCH (n:Tweet {trueSentiment:1, sentiment:'negative'}) 
WITH toFloat(count(n)) as wrongs
MATCH (nn:Tweet {trueSentiment:0, sentiment:'positive'})
WITH (wrongs + count(nn)) as wrong
MATCH (nnn:Tweet {sentiment:'neutral'})
WITH (wrong + count(nnn)) as wrongCount
MATCH (total:Tweet)
WITH 100*(1-toFloat(wrongCount/(COUNT(total)))) as percentCorrect
RETURN percentCorrect;
