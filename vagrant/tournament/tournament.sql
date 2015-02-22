-- Table definitions for the tournament project.
--
-- Put your SQL 'create table' statements in this file; also 'create view'
-- statements if you choose to use it.
--
-- You can write comments in this file by starting them with two dashes, like
-- these lines here.

CREATE TABLE player ( id SERIAL PRIMARY KEY,
                      name TEXT );
                       
CREATE TABLE match ( player1_id INTEGER REFERENCES player (id),
                       player2_id INTEGER REFERENCES player (id),
                       winner_id INTEGER NULL REFERENCES player (id), -- So that draws can be recorded as null, not yet used
                       PRIMARY KEY (player1_id, player2_id),
                       CHECK (player1_id < player2_id) ); -- constraints to ensure that players are matched only once

CREATE VIEW matches_winners_losers AS
    SELECT player1_id,
           player2_id,
           winner_id,
           CASE 
                WHEN winner_id = player1_id THEN player2_id
                WHEN winner_id = player2_id THEN player1_id
                WHEN winner_id IS NULL THEN NULL
           END AS loser_id
    FROM match;

CREATE VIEW wins AS 
    SELECT player.id as winner_id,
           COUNT(match.winner_id)
    FROM player LEFT JOIN match -- has to be a left join to get zero values
    ON player.id = match.winner_id
    GROUP BY player.id;

CREATE VIEW losses AS 
    SELECT player.id as loser_id,
           COUNT(matches_winners_losers.loser_id)
    FROM player LEFT JOIN matches_winners_losers -- has to be a left join to get zero values
    ON player.id = matches_winners_losers.loser_id
    GROUP BY player.id;

CREATE VIEW matches_count AS
    SELECT player.id AS player_id,
           COUNT(player1_id) 
    FROM player LEFT JOIN match
    ON player.id = player1_id OR player.id = player2_id
    GROUP BY player.id;

CREATE VIEW player_standings AS
    SELECT winner_id as player_id,
           player.name,
           wins.count as win_count,
           losses.count as lose_count,
           matches_count.count as match_count
    FROM wins
        JOIN losses
        ON winner_id = loser_id
        JOIN player
        ON winner_id = player.id
        JOIN matches_count
        ON winner_id = matches_count.player_id
    ORDER BY win_count;

CREATE VIEW numbered_standings AS
    SELECT 
        ROW_NUMBER() OVER(ORDER BY win_count DESC) as row,
        ROW_NUMBER() OVER(ORDER BY win_count DESC) % 2 = 0 as even_row, * 
    FROM player_standings;

CREATE VIEW swiss_pairings AS
    SELECT
        a.player_id as id1, 
        a.name as name1, 
        b.player_id as id2, 
        b.name as name2
    FROM 
            (SELECT * FROM numbered_standings WHERE even_row = FALSE) AS a 
        JOIN
            (SELECT * FROM numbered_standings WHERE even_row = TRUE) AS b
        ON a.row = b.row - 1;

