-- Segmentation RFM

USE PortfolioSQL_Superstore;
GO

--  1 : Calculer recence, frequence, montant (valeurs brutes)
SELECT 
    fact_order_item.customer_id,
    customer_name,
    DATEDIFF(DAY, MAX(order_date), '2018-12-30') AS recence,
    COUNT(DISTINCT order_id) AS frequence,
    SUM(sales) AS montant
FROM fact_order_item
JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
GROUP BY fact_order_item.customer_id, customer_name
ORDER BY montant DESC;


--  2 : Ajouter les scores (1 a 5)
WITH scores AS (
    SELECT 
        fact_order_item.customer_id,
        customer_name,
        DATEDIFF(DAY, MAX(order_date), '2018-12-30') AS recence,
        COUNT(DISTINCT order_id) AS frequence,
        SUM(sales) AS montant,
        NTILE(5) OVER (ORDER BY DATEDIFF(DAY, MAX(order_date), '2018-12-30') DESC) AS score_r,
        NTILE(5) OVER (ORDER BY COUNT(DISTINCT order_id)) AS score_f,
        NTILE(5) OVER (ORDER BY SUM(sales)) AS score_m
    FROM fact_order_item
    JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
    GROUP BY fact_order_item.customer_id, customer_name
)
SELECT * FROM scores
ORDER BY montant DESC;


--  3 : Creer les segments
WITH scores AS (
    SELECT 
        fact_order_item.customer_id,
        customer_name,
        DATEDIFF(DAY, MAX(order_date), '2018-12-30') AS recence,
        COUNT(DISTINCT order_id) AS frequence,
        SUM(sales) AS montant,
        NTILE(5) OVER (ORDER BY DATEDIFF(DAY, MAX(order_date), '2018-12-30') DESC) AS score_r,
        NTILE(5) OVER (ORDER BY COUNT(DISTINCT order_id)) AS score_f,
        NTILE(5) OVER (ORDER BY SUM(sales)) AS score_m
    FROM fact_order_item
    JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
    GROUP BY fact_order_item.customer_id, customer_name
)
SELECT 
    customer_id,
    customer_name,
    recence,
    frequence,
    montant,
    score_r,
    score_f,
    score_m,
    CASE
        WHEN score_r >= 4 AND score_f >= 4 AND score_m >= 4 THEN 'Meilleurs clients'
        WHEN score_f >= 3 AND score_m >= 3 THEN 'Clients fideles'
        WHEN score_r >= 4 THEN 'Nouveaux clients'
        WHEN score_r <= 2 THEN 'Clients inactifs'
        ELSE 'Clients occasionnels'
    END AS segment
FROM scores
ORDER BY montant DESC;

--  4 : Analyse par segment
WITH scores AS (
    SELECT 
        fact_order_item.customer_id,
        customer_name,
        DATEDIFF(DAY, MAX(order_date), '2018-12-30') AS recence,
        COUNT(DISTINCT order_id) AS frequence,
        SUM(sales) AS montant,
        NTILE(5) OVER (ORDER BY DATEDIFF(DAY, MAX(order_date), '2018-12-30') DESC) AS score_r,
        NTILE(5) OVER (ORDER BY COUNT(DISTINCT order_id)) AS score_f,
        NTILE(5) OVER (ORDER BY SUM(sales)) AS score_m
    FROM fact_order_item
    JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
    GROUP BY fact_order_item.customer_id, customer_name
),
segments_clients AS (
    SELECT 
        customer_id,
        customer_name,
        recence,
        frequence,
        montant,
        score_r,
        score_f,
        score_m,
        CASE
            WHEN score_r >= 4 AND score_f >= 4 AND score_m >= 4 THEN 'Meilleurs clients'
            WHEN score_f >= 3 AND score_m >= 3 THEN 'Clients fideles'
            WHEN score_r >= 4 THEN 'Nouveaux clients'
            WHEN score_r <= 2 THEN 'Clients inactifs'
            ELSE 'Clients occasionnels'
        END AS segment
    FROM scores
)
SELECT 
    segment,
    COUNT(*) AS nb_clients,
    SUM(montant) AS ca_total,
    AVG(montant) AS ca_moyen_client,
    AVG(frequence) AS commandes_moyennes,
    AVG(recence) AS recence_moyenne
FROM segments_clients
GROUP BY segment
ORDER BY ca_total DESC;

/*
RESULTATS GLOBAUX (insights cles):
Clients fideles = segment dominant : 274 clients (35%) | 1,075,601$ (48% du CA) | CA moyen 3,926$
Meilleurs clients : 94 clients (12%) | 497,743$ (22% du CA) | CA moyen 5,295$ (le plus eleve)
Clients inactifs : 225 clients (28%) | 354,912$ | Recence 345 jours (en danger !)
Nouveaux clients : 131 clients (17%) | 219,841$ | Recence : 24 jours (recents)
Clients occasionnels : 69 clients (9%) | 104,930$ | Faible engagement

OBSERVATIONS DES SEGMENTS :
    1. Concentration du CA sur deux segments cles ("fideles et meilleurs")
    Les clients fideles et meilleurs clients representent 47% de la base mais generent 70% du CA.
    Cette concentration montre une base client solide avec un noyau de clients a forte valeur.

    2. Segment "inactif" representant un risque important
    28% de la base client (225 personnes) n'a pas commande depuis environ un an.
    Ces clients ont genere 355k$ par le passe, leur reactivation pourrait avoir un impact significatif.

    3. "Nouveaux clients" avec potentiel de croissance
    131 clients recents montrent un bon niveau d'activite initial (5 commandes en moyenne).
    Leur CA moyen reste faible (1,678$) compare aux clients fideles (3,926$).
    L'enjeu est de les faire evoluer vers le segment fidele.

ACTIONS PRIORITAIRES :
- Meilleurs : Creer des avantages exclusifs pour les meilleurs clients (livraison gratuite, support prioritaire)
- Fidèles + meilleurs clients : programme de fidélisation / avantages (objectif : rétention et panier).
- Inactifs : campagne de réactivation segmentée (offre promotionnelle ciblee)
- Nouveaux : onboarding (stratégie de relance) pour augmenter la fréquence et le CA par client.
*/