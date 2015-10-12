//Sample Reviews:
//CREATE (:Review {review:' The official Blu-ray has seven mini-featurettes If this seems like it is a half-assed release its because Paramount has divvied up all the other features including the commentary tracks with the cast and director JJ Abrams and several additional featurettes The list of missing content on the US wide-release Blu-ray which is what is being sold on Amazon includes 5 more featurettes The Journey Continues Again Rebuilding the Enterprise Full of Wrath Kirk  Spock and Visual Preferences plus the commentary with JJ Abrams and the crew and a theatrical trailer The featurettes and trailer are likely whats on the Bonus Discs at Target and Best Buy and the CinemaNow downloads Best Buy US appears to have its content via CinemaNow download while the same content is on a Bonus Disc in Canada and the commentary is obviously with iTunes All this means if you buy the normal version here on Amazon youre getting less than half the special features created for the home video release and if you want all of them youre going to need to purchase at least three separate versions Shame on you Paramount I loved the movie when I saw it but this review is specifically about this product and its release practices', rating:1, analyzed:FALSE});
//
//analizamatic
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
MATCH
pos = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(word)-[:SENTIMENT]-(:Polarity {polarity:'positive'})
WITH n, count(pos) as plus
MATCH
neg = (n:Review)-[:IN_REVIEW]-(wordReview)-[:TEMP]-(word)-[:SENTIMENT]-(:Polarity {polarity:'negative'})
WITH plus, COUNT(neg) as minus, n
SET n.sentimentScore = plus - minus;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore > 0
SET n.sentiment = 'positive', n.analyzed = TRUE
DELETE w, r, rr;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore < 0
SET n.sentiment = 'negative', n.analyzed = TRUE
DELETE w, r, rr;
//
MATCH (n:Review)-[rr:IN_REVIEW]-(w)-[r:TEMP]-(word)-[:SENTIMENT]-(:Polarity)
WHERE n.sentimentScore = 0
SET n.sentiment = 'neutral', n.analyzed = TRUE
DELETE w, r, rr;
