/*
Analyse du CA et comportement par segment
 * Tables : fact_order_item + dim_customer
 * Objectif général : Comparer Consumer, Corporate, Home Office
 */

USE PortfolioSQL_Superstore;
GO

-- Objectif 1 : Vérifier que le JOIN fonctionne (TOP 10 ventes avec segment°

SELECT TOP 10
    order_id,
    sales,
    customer_name,
    segment
FROM fact_order_item
JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
ORDER BY sales DESC;

/*
 * Résultat :
 * - Vente la plus élevée : 22,638$ (Sean Miller, segment : Home Office)
 * - Verification que les segments s'affichent correctement
 */


-- Objectif 2 : Comparer la performance des 3 segments (CA)


SELECT 
    segment,
    COUNT(DISTINCT order_id) AS nb_commandes,
    SUM(sales) AS ca_total,
    SUM(sales) / COUNT(DISTINCT order_id) AS panier_moyen
FROM fact_order_item
JOIN dim_customer ON fact_order_item.customer_id = dim_customer.customer_id
GROUP BY segment
ORDER BY ca_total DESC;

/*
RESULTATS OBENTUS :
 * Consumer :
 * - CA total : 1146708.13
 * - Nb clients : 409
 * - Panier moyen (PM) : 452.35
 * 
 * Corporate :
 * - CA total : 682211.90
 * - Nb clients : 236
 * - Panier moyen (PM) : 458.48
 * 
 * Home Office :
 * - CA total : 423687.57
 * - Nb clients : 148
 * - Panier moyen (PM) : 474.45
 
 * Les insights clés
 * 
 * 1. Segment dominant : Consumer, base solide
   2. Segment stable : Corporate (stable mais pas différenciant : PM intermédiaire, représente environ 30% des ventes et 30% des clients)
 * 2. Segment à fort potentiel : meilleur panier moyen (474.00), potentiel croissance
 * 3. Recommandations : Maintenir Consumer : programme fidélité pour les 409 clients
                        Développer Home Office : avec campagne ciblée acquisition  (environ 19% clients = 474.00 de PM)
                        Optimiser Corporate : stratégie pour identifier pourquoi le PM est intermédiaire et est moins que Home Office
*/