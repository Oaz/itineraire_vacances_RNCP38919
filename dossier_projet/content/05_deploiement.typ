#import "../lib.typ": *

= Déploiement du MVP <deploiement>

== Introduction

Ce chapitre détaille l'architecture et le déploiement du MVP de l'application d'itinéraires de vacances.
Il couvre l'ensemble de la chaîne de traitement des données, depuis leur extraction jusqu'à leur exposition via une API, ainsi que les aspects de conteneurisation et de monitoring qui garantissent la robustesse et la maintenabilité du système.

L'architecture globale, illustrée ci-dessous, s'articule autour de plusieurs composants clés : un pipeline ETL pour le traitement des données, une API REST pour leur exposition, et une infrastructure de monitoring pour la supervision du système.

#figure(image("../img/flux_applicatif.png"), caption:"Flux de données applicatives et de monitoring")

== Gestion des codes sources

Le projet est géré via Git et hébergé sur GitHub à l'adresse #inline-link("https://github.com/Oaz/itineraire_vacances_RNCP38919","https://github.com/Oaz/itineraire_vacances_RNCP38919").
Cette plateforme permet une gestion collaborative et une traçabilité complète des modifications.

=== Structure du dépôt

Le dépôt est organisé avec des dossiers qui reflètent les différents composants de l'application:

- *airflow* : Scripts et DAGs du pipeline ETL Airflow
- *api* : Code source de l'API REST développée avec FastAPI
- *dataviz* : Code de l'application de visualisation de la qualité des données
- *monitoring* : Configuration des outils de monitoring (Prometheus, Grafana)
- *utils* : Utilitaires communs et scripts de test

=== Pipeline de build

Le projet utilise GitHub Actions comme pipeline de build. Le workflow principal est configuré pour s'exécuter automatiquement à chaque push sur la branche de développement :
- Exécution des tests unitaires Python
- Vérification de la qualité du code
- Construction et validation des images Docker

Ce processus permet de détecter rapidement les problèmes et d'assurer la stabilité du code à chaque étape du développement.

=== Gestion des branches

Le workflow de développement s'articule autour de deux branches principales:

- *main* : Branche stable contenant le code en production
- *dev* : Branche de développement où sont intégrées les nouvelles fonctionnalités

Les développements spécifiques sont réalisés sur des branches de fonctionnalités qui sont ensuite fusionnées dans la branche de développement via des pull requests après revue de code.

=== Documentation

Le code est documenté à plusieurs niveaux :
- Documentation inline des fonctions et classes
- Documentation des API (via OpenAPI/Swagger)
- Documentation du projet (le présent document)

Cette documentation complète facilite la maintenance et l'évolution du projet sur le long terme.

== Pipeline ETL

Le pipeline ETL (Extract, Transform, Load) est orchestré par Apache Airflow, un outil de planification et de supervision des flux de travail.
Le DAG (Directed Acyclic Graph) principal assure l'extraction quotidienne des données DATAtourisme, leur transformation et leur chargement dans les bases de données.

Le workflow commence par la vérification et, si nécessaire, la création de la base de données PostgreSQL.
En parallèle, il télécharge et extrait les données DATAtourisme, effectue un filtrage géographique pour ne conserver que les POIs situés en France, puis il procède au nettoyage et à l'enrichissement des données.
Les données traitées sont ensuite stockées dans PostgreSQL pour les requêtes relationnelles classiques et dans Neo4j pour les analyses basées sur les graphes.

Le pipeline termine avec une phase de clustering qui regroupe les points d'intérêt similaires par catégorie (musées, sites culturels, événements sportifs, etc.)
avec des paramètres de distance et de densité spécifiques à chaque type, facilitant ainsi la découverte de circuits thématiques.
Les partitionnements des catégories sont effectués en parallèle.

#figure(image("../img/airflow.png"), caption:"Pipeline ETL")

== API

=== Description

L'API REST est développée avec FastAPI, un framework web Python.
Elle offre un ensemble d'endpoints permettant aux applications clientes d'interagir avec les données du système d'itinéraires de vacances.

Les principales fonctionnalités de l'API incluent :

- Vérification de l'état des services avec des endpoints de santé (`/db_health`)
- Récupération d'informations sur les points d'intérêt (`/poi`) et recherche par ville et catégorie (`/find_poi`)
- Recherche de villes disponibles par catégorie et terme de recherche (`/find_cities`)
- Listage des catégories avec statistiques sur les clusters et routes associés (`/clustered_categories`)
- Calcul d'itinéraires thématiques entre deux points d'intérêt (`/route`)

L'algorithme de calcul d'itinéraire utilise Neo4j pour déterminer le chemin le plus court entre les clusters contenant les points d'intérêt de départ et d'arrivée.
Il exploite la structure de graphe pour naviguer efficacement à travers les clusters reliés par des relations `ROUTE`, en tenant compte de la catégorie thématique demandée.

La documentation OpenAPI est automatiquement générée et enrichie avec des descriptions détaillées, des exemples de paramètres et des modèles de réponses pour faciliter l'intégration par les développeurs.

Une interface de démonstration web est également disponible via l'endpoint `/demo`.

Une instance statique (sans renouvellement des données) est utilisable en ligne
à l'adresse #inline-link("https://itineraire-vacances.mnt.space/","https://itineraire-vacances.mnt.space/")

=== Exemple d'utilisation

- Catégorie : NaturalHeritage
- Ville de départ : Béziers
- Ville d'arrivée : Mazamet

*Détails de l'itinéraire*

- Étape 1 (red):
    - PNALAR034V50OON6: NEUF ECLUSES DE FONSERANES, 34500 Béziers (43.3306239,3.19968028)
    - PNALAR034V51NVDC: ETANG DE LA MATTE, 34710 Lespignan (43.2649522,3.15389015)
    - PNALAR0340000039: ETANG ASSECHE DE MONTADY, 34440 Colombiers (43.3148346,3.1383661)
    - PNALAR034V50OOP2: LE CANAL DU MIDI, 34500 Béziers (43.332294,3.20388599)
- Étape 2 (blue):
    - PNALAR034V51IUKK: ETANG DE CAPESTANG, 34310 Capestang (43.33165,3.043002)
- Étape 3 (green):
    - PNALAR034V50M733: GORGES DE REALS, 34460 Cessenon-sur-Orb (43.436953,3.10152641)
- Étape 4 (orange):
    - PNALAR034V505P62: FORET DES EUCALYPTUS, 34460 Cessenon-sur-Orb (43.4576356,3.0173091)
    - PNALAR034V51IUK0: LES BARRES ROCHEUSES DE CAZEDARNES, 34460 Cazedarnes (43.420492,3.0215679)
    - PNALAR034V51IUKB: RESERVE NATURELLE REGIONALE DE COUMIAC, 34460 Cessenon-sur-Orb (43.4688389,3.05826742)
- Étape 5 (purple):
    - PNALAR034V505PDW: LA MARE NATURA 2000, 34360 Assignan (43.401243,2.886565)
- Étape 6 (darkred):
    - PNALAR034V51C4HN: Gorges de La Cesse et du Brian, 34210 Minerve (43.354066,2.74659999)
    - PNALAR0340000037: LE LAC DE JOUARRES, 34210 Olonzac (43.2750794,2.70910517)
    - PNALAR0340000022: LES PONTS NATURELS DE MINERVE, 34210 Minerve (43.3547807,2.7457039)
- Étape 7 (cadetblue):
    - PNALAR034V52C2SZ: SOURCE DE LA CESSE, 34210 Ferrals-les-Montagnes (43.4037434,2.62763261)
    - 7027835: Lac d'Albine, 81240 Albine (43.454928,2.52806)
- Étape 8 (pink):
    - 4675389: Fauteuil de mise à l'eau PMR, 81200 Mazamet (43.463401,2.345725)
    - 844917: Base de Loisirs du Lac des Montagnès, 81200 Mazamet (43.462109,2.341805)

#figure(image("../img/itineraire.png"), caption:"Visualisation de l'itinéraire")

== Monitoring

Le monitoring de l'application est assuré par une pile d'observabilité complète composée de Prometheus, Grafana et plusieurs exporters spécialisés. Cette infrastructure permet de surveiller en temps réel l'état des différents services ainsi que le contenu de la base de données.

Le tableau de bord principal, illustré ci-dessous, est divisé en deux sections principales:
- La section "Monitoring Contenu BDD" affiche des métriques relatives aux données stockées, notamment le nombre de régions, départements, villes, catégories et points d'intérêt (POI).
- La section "Monitoring Services" présente l'état de santé de tous les composants de l'infrastructure: Airflow, Neo4j, PostgreSQL, Redis et l'API publique. Pour chaque service, un indicateur visuel (vert/rouge) signale son état opérationnel, complété par des métriques spécifiques comme la taille de la base de données PostgreSQL ou la mémoire utilisée par Redis.

Cette surveillance proactive permet d'identifier rapidement les problèmes potentiels et d'assurer la disponibilité continue du service.

#figure(image("../img/monitoring.png"), caption:"Écran de monitoring")

== Conteneurisation

L'application est entièrement conteneurisée via Docker, ce qui facilite son déploiement et sa maintenance. L'infrastructure complète est orchestrée par Docker Compose et comprend plusieurs services interdépendants :

=== Services de stockage
- *PostgreSQL* : Base de données relationnelle stockant les données structurées des points d'intérêt et autres informations géographiques.
- *Neo4j* : Base de données orientée graphe utilisée pour modéliser et interroger les relations entre les clusters de points d'intérêt.
- *Redis* : Stockage en mémoire utilisé comme broker de messages pour Airflow.

=== Services d'orchestration et ETL
- *Airflow* : Composé de plusieurs services (webserver, scheduler, worker, flower) pour l'orchestration des pipelines de données.
- *Airflow Init* : Service d'initialisation configurant les variables d'environnement nécessaires à Airflow.

=== Services applicatifs
- *API* : Service FastAPI exposant les endpoints REST pour les applications clientes.
- *DataViz* : Interface de visualisation basée sur Dash permettant d'explorer les données.

=== Services de monitoring
- *Prometheus* : Système de collecte et de stockage de métriques.
- *Grafana* : Outil de visualisation des métriques de monitoring.
- *Exporters* : Plusieurs exporters (PostgreSQL, Redis, Airflow, Blackbox) collectent des métriques spécifiques à chaque service.

L'ensemble des services est configuré avec des healthchecks appropriés pour assurer la résilience du système, et les volumes Docker garantissent la persistance des données entre les redémarrages. L'architecture modulaire permet également d'ajouter ou de remplacer des composants facilement.

#figure(
  image("../img/conteneurs.png"),
  caption: "Architecture des conteneurs Docker"
)