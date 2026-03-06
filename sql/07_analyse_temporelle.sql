-- Analyse temporelle

USE PortfolioSQL_Superstore;
GO

--1. CA mensuel avec croissance (Month-over-Month MoM et Year-over-Year YoY)
WITH ca_mensuel AS (
    SELECT 
        YEAR(order_date) AS annee,
        MONTH(order_date) AS mois,
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS date_mois,
        CAST(SUM(sales) AS DECIMAL(12,2)) AS ca_mensuel,
        COUNT(DISTINCT order_id) AS nb_commandes
    FROM fact_order_item
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT 
    annee,
    mois,
    date_mois,
    ca_mensuel,
    nb_commandes,
    
    --1.a CA mois precedent (arrondi APRES le OVER)
    CAST(LAG(ca_mensuel, 1) OVER (ORDER BY date_mois) AS DECIMAL(12,2)) AS ca_mois_precedent,
    
    --1.b Croissance MoM (2 decimales)
    CASE 
        WHEN LAG(ca_mensuel, 1) OVER (ORDER BY date_mois) IS NOT NULL
        THEN CAST((ca_mensuel - LAG(ca_mensuel, 1) OVER (ORDER BY date_mois)) * 100.0 / LAG(ca_mensuel, 1) OVER (ORDER BY date_mois) AS DECIMAL(10,2))
        ELSE NULL
    END AS croissance_mom_pct,
    
    --1.c CA annee precedente
    CAST(LAG(ca_mensuel, 12) OVER (ORDER BY date_mois) AS DECIMAL(12,2)) AS ca_annee_precedente,
    
    --1.d Croissance YoY
CASE 
        WHEN LAG(ca_mensuel, 12) OVER (ORDER BY date_mois) IS NOT NULL
        THEN CAST((ca_mensuel - LAG(ca_mensuel, 12) OVER (ORDER BY date_mois)) * 100.0 / LAG(ca_mensuel, 12) OVER (ORDER BY date_mois) AS DECIMAL(10,2))
        ELSE NULL
    END AS croissance_yoy_pct

FROM ca_mensuel
ORDER BY date_mois;


--2. Analyse saisonnalite : CA moyen par mois

SELECT 
    mois,
    CASE mois
        WHEN 1 THEN 'Janvier'
        WHEN 2 THEN 'Fevrier'
        WHEN 3 THEN 'Mars'
        WHEN 4 THEN 'Avril'
        WHEN 5 THEN 'Mai'
        WHEN 6 THEN 'Juin'
        WHEN 7 THEN 'Juillet'
        WHEN 8 THEN 'Aout'
        WHEN 9 THEN 'Septembre'
        WHEN 10 THEN 'Octobre'
        WHEN 11 THEN 'Novembre'
        WHEN 12 THEN 'Decembre'
    END AS nom_mois,
    
    COUNT(DISTINCT annee) AS nb_annees,
    CAST(AVG(ca_mensuel) AS DECIMAL(12,2)) AS ca_moyen,
    CAST(MIN(ca_mensuel) AS DECIMAL(12,2)) AS ca_min,
    CAST(MAX(ca_mensuel) AS DECIMAL(12,2)) AS ca_max
    
FROM (
    SELECT 
        YEAR(order_date) AS annee,
        MONTH(order_date) AS mois,
        SUM(sales) AS ca_mensuel
    FROM fact_order_item
    GROUP BY YEAR(order_date), MONTH(order_date)
) AS ca_mensuel_brut

GROUP BY mois
ORDER BY mois;

/*
RESULTATS OBTENUS SUR LA SAISONNALITE :

Mois le plus fort : Novembre (86,260$ en moyenne)
Mois le plus faible : Fevrier (14,842$ en moyenne)
Ecart : 5.8x (environ 580% de difference)

OBSERVATIONS :

1. Saisonnalite tres marquee en fin d'annee
Novembre concentre le pic d'activite (Black Friday, achats anticipés Noel, clotures budgets entreprises...).
Ce mois seul peut representer environ 15% du CA annuel, pas négligeable.

2. Creux post-fetes en fevrier
Le mois le plus faible suit directement la periode de forte consommation de fin d'annee.
Fevrier : mois court (28 jours) + potentielle fatigue budgetaire des clients.

3. Forte dependance au dernier trimestre
L'ecart de 580% entre novembre et fevrier montre une concentration importante du CA sur le 4eme trimestre.
Dependance qui represente un risque en cas de difficulte sur cette periode.

RECOMMANDATIONS D'ACTION :

- Renforcer preparation logistique et stock avant novembre (maximiser le pic saisonnier)
- Lancer campagne reactivation fevrier pour limiter le creux (promotions Saint-Valentin, packages promotionnels..)
- Developper offres specifiques trimestre 1-2 pour lisser la saisonnalite
- Anticiper les variations de tresorerie liees aux pics et creux saisonniers
*/