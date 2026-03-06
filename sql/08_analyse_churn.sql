-- Analyse churn et clients inactifs

USE PortfolioSQL_Superstore;
GO

--  1 : Clients avec leur derniere commande
SELECT 
    fact_order_item.customer_id,
    customer_name,
    segment,
    MAX(order_date) AS derniere_commande,
    DATEDIFF(DAY, MAX(order_date), '2018-12-30') AS jours_inactivite,
    COUNT(DISTINCT order_id) AS nb_commandes_total,
    SUM(sales) AS ca_total,
    
    -- Statut inactif defini (6 mois = 180 jours)
    CASE 
        WHEN DATEDIFF(DAY, MAX(order_date), '2018-12-30') > 180 THEN 'Inactif'
        ELSE 'Actif'
    END AS statut

FROM fact_order_item
JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
GROUP BY fact_order_item.customer_id, customer_name, segment
ORDER BY jours_inactivite DESC;



--  2 : Taux de churn global
WITH clients_statut AS (
    SELECT 
        fact_order_item.customer_id,
        customer_name,
        segment,
        MAX(order_date) AS derniere_commande,
        DATEDIFF(DAY, MAX(order_date), '2018-12-30') AS jours_inactivite,
        COUNT(DISTINCT order_id) AS nb_commandes_total,
        SUM(sales) AS ca_total,
        CASE 
            WHEN DATEDIFF(DAY, MAX(order_date), '2018-12-30') > 180 THEN 'Inactif'
            ELSE 'Actif'
        END AS statut
    FROM fact_order_item
    JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
    GROUP BY fact_order_item.customer_id, customer_name, segment
)
SELECT 
    statut,
    COUNT(*) AS nb_clients,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clients_statut) AS DECIMAL(5,2)) AS pct_clients,
    CAST(SUM(ca_total) AS DECIMAL(12,2)) AS ca_total,
    CAST(AVG(ca_total) AS DECIMAL(10,2)) AS ca_moyen_client,
    CAST(AVG(jours_inactivite) AS DECIMAL(10,2)) AS jours_inactivite_moyen
FROM clients_statut
GROUP BY statut
ORDER BY statut;


--  3 : Churn par segment
WITH clients_statut AS (
    SELECT 
        fact_order_item.customer_id,
        customer_name,
        segment,
        MAX(order_date) AS derniere_commande,
        DATEDIFF(DAY, MAX(order_date), '2018-12-30') AS jours_inactivite,
        COUNT(DISTINCT order_id) AS nb_commandes_total,
        SUM(sales) AS ca_total,
        CASE 
            WHEN DATEDIFF(DAY, MAX(order_date), '2018-12-30') > 180 THEN 'Inactif'
            ELSE 'Actif'
        END AS statut
    FROM fact_order_item
    JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
    GROUP BY fact_order_item.customer_id, customer_name, segment
)
SELECT 
    segment,
    statut,
    COUNT(*) AS nb_clients,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY segment) AS DECIMAL(5,2)) AS pct_segment,
    CAST(SUM(ca_total) AS DECIMAL(12,2)) AS ca_total
FROM clients_statut
GROUP BY segment, statut
ORDER BY segment, statut;


/*
RESULTATS OBTENUS :

-Taux de churn global : 26% (203 clients inactifs depuis + de 6 mois)
-CA des clients inactifs : 457,195$ (20% du CA total)
-Inactivite moyenne des clients inactifs : 406 jours (13+ mois)

CHURN PAR SEGMENT :
Consumer : 26% de churn (106 clients inactifs)
Corporate : 25% de churn (60 clients inactifs)
Home Office : 25% de churn (37 clients inactifs)

OBSERVATIONS :

1. Taux de churn eleve et uniforme
26% de la base client est inactive depuis plus de 6 mois, avec un taux similaire 
sur les trois segments (25-26%). Cela indique un probleme structurel plutot qu'un 
probleme specifique a un type de client.

2. CA historique significatif en jeu
Les 203 clients inactifs ont genere 457k$ de CA (20% du total). Leur reactivation 
represente une opportunite de recuperation de revenus importante.

3. Inactivite prolongee
Les clients inactifs n'ont pas achete depuis 406 jours en moyenne (13+ mois). 
Au-dela de ce seuil, la probabilite de reactivation devient faible sans action ciblée.

PISTES D'ACTION :

- Lancer campagne de reactivation immediate sur les 203 clients inactifs (offre -20%)
- Mettre en place alertes automatiques a 120 jours sans achat (prevention churn)
- Creer programme de fidelisation pour maintenir engagement clients actifs
- Objectif chiffre : reduire taux de churn de 26% a 15% d'ici 12 mois
*/