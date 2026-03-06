/*
Analyse du CA et comportement par région
 * Tables : fact_order_item + dim_location
 * Objectif général : Comparer WEST, EAST, CENTRAL et SOUTH
 */
USE PortfolioSQL_Superstore;
GO
SELECT 
    region,
    COUNT(DISTINCT order_id) AS nb_commandes,
    COUNT(DISTINCT customer_id) AS nb_clients,
    SUM(sales) AS ca_total,
    SUM(sales) / COUNT(DISTINCT order_id) AS panier_moyen
FROM fact_order_item
JOIN dim_location ON fact_order_item.location_id = dim_location.location_id
GROUP BY region
ORDER BY ca_total DESC;

/*
RESULTATS OBENTUS :
 * Les insights clés
 * WEST = Région dominante, marché  moteur et mature a ne pas négliger
 * EAST = Bon PM (484.65), stratégie pour augmenter la fréquence d'achat
 * SOUTH = Sous-performant mais potentiel de développement avec campagne d'acquisition (moins de commandes, moins de CA)
 * CENTRAL = PM plus faible, comprendre pourquoi
  */