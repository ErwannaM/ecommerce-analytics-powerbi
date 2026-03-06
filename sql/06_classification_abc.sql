-- Classification ABC produits  (Pareto)

USE PortfolioSQL_Superstore;
GO

-- PARTIE 1 : Liste detaillee des produits

-- 1 : CA par produit
SELECT 
    dim_product.product_id,
    product_name,
    category,
    SUM(sales) AS ca_produit
FROM fact_order_item
JOIN dim_product ON fact_order_item.product_id = dim_product.product_id
GROUP BY dim_product.product_id, product_name, category
ORDER BY ca_produit DESC;

-- 2 : CA par produit + Pourcentage cumule
WITH ca_produits AS (
    SELECT 
        dim_product.product_id,
        product_name,
        category,
        SUM(sales) AS ca_produit
    FROM fact_order_item
    JOIN dim_product ON fact_order_item.product_id = dim_product.product_id
    GROUP BY dim_product.product_id, product_name, category
),
ca_total AS (
    SELECT SUM(ca_produit) AS ca_total_global
    FROM ca_produits
)
SELECT 
    product_id,
    product_name,
    category,
    ca_produit,
    
    --2.a Pourcentage du produit (pct = porcentage)
    ca_produit * 100.0 / (SELECT ca_total_global FROM ca_total) AS pct_ca,
    
    --2.b Pourcentage cumule (pct = porcentage)
    SUM(ca_produit * 100.0 / (SELECT ca_total_global FROM ca_total)) 
        OVER (ORDER BY ca_produit DESC) AS pct_cumule

FROM ca_produits
ORDER BY ca_produit DESC;

-- 3. Classification ABC avec pourcentage cumule
WITH ca_produits AS (
    SELECT 
        dim_product.product_id,
        product_name,
        category,
        SUM(sales) AS ca_produit
    FROM fact_order_item
    JOIN dim_product ON fact_order_item.product_id = dim_product.product_id
    GROUP BY dim_product.product_id, product_name, category
),
ca_total AS (
    SELECT SUM(ca_produit) AS ca_total_global
    FROM ca_produits
),
produits_pct AS (
    SELECT 
        product_id,
        product_name,
        category,
        ca_produit,
        ca_produit * 100.0 / (SELECT ca_total_global FROM ca_total) AS pct_ca,
        SUM(ca_produit * 100.0 / (SELECT ca_total_global FROM ca_total)) 
            OVER (ORDER BY ca_produit DESC) AS pct_cumule
    FROM ca_produits
)
SELECT 
    product_id,
    product_name,
    category,
    ca_produit,
    pct_ca,
    pct_cumule,
    
    -- Classification ABC
    CASE
        WHEN pct_cumule <= 80 THEN 'A'
        WHEN pct_cumule <= 95 THEN 'B'
        ELSE 'C'
    END AS classe_abc

FROM produits_pct
ORDER BY ca_produit DESC;



-- PARTIE 2 : Analyse globale par categorie


-- Analyse par categorie ABC
WITH ca_produits AS (
    SELECT 
        dim_product.product_id,
        product_name,
        category,
        SUM(sales) AS ca_produit
    FROM fact_order_item
    JOIN dim_product ON fact_order_item.product_id = dim_product.product_id
    GROUP BY dim_product.product_id, product_name, category
),
ca_total AS (
    SELECT SUM(ca_produit) AS ca_total_global
    FROM ca_produits
),
produits_pct AS (
    SELECT 
        product_id,
        product_name,
        category,
        ca_produit,
        ca_produit * 100.0 / (SELECT ca_total_global FROM ca_total) AS pct_ca,
        SUM(ca_produit * 100.0 / (SELECT ca_total_global FROM ca_total)) 
            OVER (ORDER BY ca_produit DESC) AS pct_cumule
    FROM ca_produits
),
produits_classes AS (
    SELECT 
        product_id,
        product_name,
        category,
        ca_produit,
        pct_ca,
        pct_cumule,
        CASE
            WHEN pct_cumule <= 80 THEN 'A'
            WHEN pct_cumule <= 95 THEN 'B'
            ELSE 'C'
        END AS classe_abc
    FROM produits_pct
)
SELECT 
    classe_abc,
    COUNT(*) AS nb_produits,
    SUM(ca_produit) AS ca_total,
    AVG(ca_produit) AS ca_moyen_produit,
    MIN(ca_produit) AS ca_min,
    MAX(ca_produit) AS ca_max
FROM produits_classes
GROUP BY classe_abc
ORDER BY classe_abc;

/*
RESULTATS :

Categorie A : 412 produits (22%) | CA : 1,801,105$ (80% du total) | CA moyen : 4,372$
Categorie B : 489 produits (26%) | CA : 338,734$ (15% du total)   | CA moyen : 693$
Categorie C : 959 produits (52%) | CA : 112,767$ (5% du total)    | CA moyen : 118$

OBSERVATIONS :

1. Loi Pareto verifiee
22% des produits generent 80% du CA, confirmant la regle classique 20/80.
Cette forte concentration montre une dependance importante sur un nombre limite de references produit.

2. Produits A : representent un risque strategique
412 produits concentrent 1.8M$ de CA (80% du CA). Toute rupture de stock ou probleme fournisseur sur ces references aurait un impact majeur sur le chiffre d'affaires.

3. Catalogue produit tres voire trop large en categorie C
Plus de la moitie du catalogue (959 produits) ne genere que 5% du CA.Ces produits representent potentiellement des couts de stockage superflus.

RECOMMANDATIONS :
- Renforcer suivi et stocks de securite sur produits categorie A, eviter toute perte de CA produit non négligeable
- Analyser opportunite de reduction du catalogue en supprimant produits C a faible rotation/peu achete par les clients
- Developper actions marketing sur produits B a fort potentiel pour les faire evoluer vers A
*/