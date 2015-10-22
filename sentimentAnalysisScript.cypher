//make sure necessary indexes exist
CREATE INDEX ON :ReviewWords(word);
CREATE INDEX ON :Review(sentiment);

//algo starts here

MATCH (n:Review)
WHERE n.analyzed = FALSE
WITH n, split(n.review, " ") as words
UNWIND words as word
CREATE (rw:ReviewWords {word:word})
WITH n, rw
CREATE (rw)-[:IN_REVIEW]->(n);

// assigning word counts

MATCH (n:Review)
WITH n, size((n)<-[:IN_REVIEW]-()) as wordCount
SET n.wordCount = wordCount;

//creating temporary relationships between keywords and words in our reviews

MATCH (n:Review)-[:IN_REVIEW]-(wordReview)
WITH distinct wordReview
MATCH  (keyword:Keyword)
WHERE wordReview.word = keyword.word AND (keyword)-[:SENTIMENT]-()
MERGE (wordReview)-[:TEMP]->(keyword);

//scoring the reviews

MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(keyword)-[:SENTIMENT]-(:Polarity)
OPTIONAL MATCH pos = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(keyword)-[:SENTIMENT]-(:Polarity {polarity:'positive'})
WITH n, toFloat(count(pos)) as plus
OPTIONAL MATCH neg = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(keyword)-[:SENTIMENT]-(:Polarity {polarity:'negative'})
WITH ((plus - COUNT(neg))/n.wordCount) as score, n
SET n.sentimentScore = score;

//assigning postive, negative, or neutral sentiment and deleting TEMP relationships

//based on percentage of pos or negatives words in reviews, detemining sentiment pos, neg, or neutral

MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(keyword)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore >= (.001)
SET n.sentiment = 'positive', n.analyzed = TRUE
DELETE w, r, rr;

MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(keyword)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore <= (-.001)
SET n.sentiment = 'negative', n.analyzed = TRUE
DELETE w, r, rr;

MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(keyword)-[:SENTIMENT]-(:Polarity)
WHERE (.001) > n.sentimentScore > (-.001)
SET n.sentiment = 'neutral', n.analyzed = TRUE
DELETE w, r, rr;

//cleaning up our temporary review words

MATCH (:Review)-[r]-(deleteMe:ReviewWords)
DELETE r, deleteMe;
