/*
-- Analyse par categorie produit
*/
USE PortfolioSQL_Superstore;
GO
-- CA par categorie produit
SELECT 
    category,
    COUNT(DISTINCT order_id) AS nb_commandes,
    COUNT(DISTINCT dim_product.product_id) AS nb_produits,
    SUM(sales) AS ca_total,
    SUM(sales) / COUNT(DISTINCT order_id) AS panier_moyen
FROM fact_order_item
JOIN dim_product ON fact_order_item.product_id = dim_product.product_id
GROUP BY category
ORDER BY ca_total DESC;

/*
RESULTATS OBTENUS :
Technology : 825,856$ (37% du CA) - 1,516 commandes - PM 545$
Furniture : 723,539$ (32% du CA) - 1,725 commandes - PM 420$
Office Supplies : 703,213$ (31% du CA) - 3,674 commandes - PM 191$

OBSERVATIONS :
- Technology genere le plus de CA avec le panier le plus eleve (545$)
- Office Supplies represente environ 75% des commandes mais PM faible (191$)
- Furniture a une performance equilibree

RECOMMANDATIONS :
- Developper ventes Technology (produits a forte valeur 545$ de PM)
- Proposer des lots dans la categorie Office Supplies pour augmenter PM des clients
- Offrir livraison gratuite a partir de 200$ d'achat pourrait être envisagé pour augmenter le PM de Office Supplies
*/