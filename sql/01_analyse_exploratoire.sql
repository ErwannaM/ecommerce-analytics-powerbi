/*
-- Analyse exploratoire : Vue d'ensemble du dataset
 * Description : Statistiques descriptives du dataset
 * Objectif : Comprendre les volumes, période, CA et indicateurs clés
 */

USE PortfolioSQL_Superstore;
GO

-- Vue d'ensemble du dataset
SELECT 
    -- Volumes
    COUNT(DISTINCT order_id) AS nb_commandes,
    COUNT(DISTINCT customer_id) AS nb_clients,
    COUNT(DISTINCT product_id) AS nb_produits,
    COUNT(*) AS nb_lignes_vente,
    
    -- Periode couverte
    MIN(order_date) AS premiere_commande,
    MAX(order_date) AS derniere_commande,
    DATEDIFF(DAY, MIN(order_date), MAX(order_date)) AS nb_jours_couvert,
    
    -- Chiffre d'affaires
    SUM(sales) AS ca_total,
    AVG(sales) AS ca_moyen_ligne,
    
    -- Indicateurs metier
    SUM(sales) / COUNT(DISTINCT order_id) AS panier_moyen,
    SUM(sales) / COUNT(DISTINCT customer_id) AS ca_moyen_client,
    COUNT(DISTINCT order_id) * 1.0 / COUNT(DISTINCT customer_id) AS commandes_par_client
    
FROM fact_order_item;

/*
 * RÉSULTATS OBTENUS :

 * Commandes : 4916
 * Clients : 793
 * Produits : 1860
 * Période : 2015-2018 (1457 jours)
 * CA total : 2 252607.60
 * Panier moyen : 458.22
 * CA moyen/client : 2,840.61
 * Commandes/client : 6.2
 * 
 * Insights clés :

 * - Clients fidèles (6.2 commandes en moyenne)
 * - Panier moyen élevé (458.21) (achats B2B probables ?)
 * - CA moyen par client intéressant (2840 /client sur 4 ans en moyenne)
 */