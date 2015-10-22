//stanford cs lab movie review sentiment test data
//using test data from: http://ai.stanford.edu/~amaas/data/sentiment/

CREATE INDEX ON :ReviewWords(word);
CREATE INDEX ON :Keyword(word);
CREATE INDEX ON :Review(sentiment);

USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/kvangundy/neo4j-sentiment-analysis/master/efficacyTesting/negatives.csv" as line
WITH line
CREATE (r:Review {review:toLOWER(line.review), trueSentiment:0, analyzed:FALSE});

USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/kvangundy/neo4j-sentiment-analysis/master/efficacyTesting/positives.csv" as line
WITH line
CREATE (r:Review {review:toLOWER(line.review), trueSentiment:1, analyzed:FALSE});

//algo starts here

MATCH (n:Review)
WHERE n.analyzed = FALSE
WITH n, split(n.review, " ") as words
UNWIND words as word
CREATE (rw:ReviewWords {word:word})
WITH n, rw
CREATE (rw)-[:IN_REVIEW]->(n);

//assigning word count

MATCH (n:Review)
WITH n, size((n)<-[:IN_REVIEW]-()) as wordCount
SET n.wordCount = wordCount;

//creating "TEMP" relationships between words in reviews and keywords in corpus

MATCH (n:Review)-[:IN_REVIEW]-(wordReview)
WITH distinct wordReview
MATCH  (keyword:Keyword)
WHERE wordReview.word = keyword.word AND (keyword)-[:SENTIMENT]-()
MERGE (wordReview)-[:TEMP]->(keyword);


//start of sentiment scoring function

MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
OPTIONAL MATCH pos = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(word)-[:SENTIMENT]-(:Polarity {polarity:'positive'})
WITH n, toFloat(count(pos)) as plus
OPTIONAL MATCH neg = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(word)-[:SENTIMENT]-(:Polarity {polarity:'negative'})
WITH ((plus - COUNT(neg))/n.wordCount) as score, n
SET n.sentimentScore = score;

//based on percentage of pos or negatives words in reviews, detemining sentiment pos, neg, or neutral

MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore >= (.001)
SET n.sentiment = 'positive', n.analyzed = TRUE
DELETE w, r, rr;

MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore <= (-.001)
SET n.sentiment = 'negative', n.analyzed = TRUE
DELETE w, r, rr;

MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE (.001) > n.sentimentScore > (-.001)
SET n.sentiment = 'neutral', n.analyzed = TRUE
DELETE w, r, rr;

//cleanup

MATCH (:Review)-[r]-(deleteMe:ReviewWords)
DELETE r, deleteMe;

//finally comparing our test movie reviews' true scores to the results determined by our algorithim

MATCH (n:Review {trueSentiment:1, sentiment:'negative'}) 
WITH toFloat(count(n)) as wrongs
MATCH (nn:Review {trueSentiment:0, sentiment:'positive'})
WITH (wrongs + count(nn)) as wrong
MATCH (nnn:Review {sentiment:'neutral'})
WITH (wrong + count(nnn)) as wrongCount
MATCH (total:Review)
WITH 100*(1-toFloat(wrongCount/(COUNT(total)))) as percentCorrect
RETURN percentCorrect;
