= Définition du MVP <mvp>

== Introduction

Le MVP (Minimum Viable Product) constitue la première version fonctionnelle de notre système de génération d'itinéraires touristiques.
Cette implémentation minimale mais complète permet de valider les concepts techniques fondamentaux et d'obtenir rapidement des retours utilisateurs.

Ce chapitre détaille les différents composants techniques du MVP :
- La structure de la base de données relationnelle PostgreSQL stockant les points d'intérêt
- L'utilisation d'une base de données orientée graphe Neo4j pour le routage
- Les algorithmes de clustering pour regrouper les POIs
- Le système de génération d'itinéraires entre clusters

L'objectif est de présenter une architecture technique robuste permettant l'implémentation des fonctionnalités essentielles, tout en restant évolutive pour les développements futurs.

== Données et relations

La base de données relationnelle constitue le socle de stockage principal des données touristiques de notre application. Nous utilisons PostgreSQL pour implémenter un schéma relationnel optimisé pour la recherche de points d'intérêt.

=== Structure du schéma relationnel

#figure(image("../img/schema_rdbms.svg"),caption:"Structure du schéma relationnel")

Le schéma relationnel comprend six tables principales interconnectées :

- *Point_Of_Interest* : Table centrale stockant les informations essentielles sur chaque point d'intérêt touristique, incluant son identifiant unique provenant de DATAtourisme (`dt_poi_id`), ses coordonnées géographiques (`latitude`, `longitude`), son nom, et d'autres attributs descriptifs.
- *Category* : Référentiel des catégories touristiques issues de l'ontologie DATAtourisme (musées, sites naturels, lieux culturels, etc.).
- *Category_Point_Of_Interest* : Table de relation many-to-many permettant d'associer plusieurs catégories à chaque point d'intérêt.
- *City* : Informations sur les communes où se situent les points d'intérêt, incluant les codes postaux.
- *Departement* : Regroupement administratif des communes au niveau départemental.
- *Region* : Niveau supérieur de l'organisation territoriale, regroupant les départements.

Cette structure hiérarchique géographique (Région > Département > Ville) permet d'optimiser les requêtes spatiales et de filtrer les résultats par zones géographiques.

=== Processus d'importation depuis DATAtourisme

L'importation des données depuis DATAtourisme vers notre base PostgreSQL suit plusieurs étapes :

1. *Extraction des fichiers JSON* : Les archives ZIP de DATAtourisme sont téléchargées via les feeds configurés, puis décompressées pour accéder aux fichiers JSON individuels.
2. *Parsing et transformation* : Chaque fichier JSON est analysé pour extraire les informations pertinentes selon la structure suivante :
   - L'identifiant unique (`@id`) devient `dt_poi_id`
   - Les coordonnées géographiques sont extraites de `isLocatedAt > schema:geo`
   - Le nom est récupéré depuis `rdfs:label`
   - Les catégories sont identifiées à partir du champ `@type`
   - Les informations de localisation administrative (ville, département, région) sont extraites de `isLocatedAt > schema:address`
3. *Normalisation des données* : Les données sont nettoyées et normalisées pour assurer leur cohérence (uniformisation des formats de dates, gestion des caractères spéciaux, etc.).
4. *Chargement dans la base* : Les données transformées sont insérées dans les tables correspondantes du schéma PostgreSQL, en respectant les contraintes d'intégrité référentielle.
5. *Indexation* : Des index sont créés sur les colonnes fréquemment utilisées pour les recherches et les jointures, notamment les identifiants et les noms.

Cette structure de base de données relationnelle permet d'effectuer efficacement des requêtes complexes pour trouver des points d'intérêt selon des critères géographiques, des catégories spécifiques, ou des combinaisons de filtres, tout en maintenant l'intégrité et la cohérence des données.

== Données spatiales

=== Base de données orientée graphe

==== Objectif et principes
La base de données orientée graphe constitue un élément architectural fondamental pour notre système d'itinéraires touristiques. Contrairement aux bases de données relationnelles traditionnelles qui structurent les données en tables et relations, une base de données orientée graphe (Neo4j dans notre implémentation) modélise directement les entités comme des nœuds et leurs interconnexions comme des relations, offrant ainsi une représentation naturelle des réseaux d'intérêts touristiques.

==== Architecture de données
Notre modèle de graphe s'articule autour de deux types principaux de nœuds :
- *Nœuds POI* : Représentent des points d'intérêt touristiques individuels avec leurs attributs (identifiant, nom, coordonnées géographiques, catégories, etc.)
- *Nœuds Cluster* : Représentent des regroupements de POIs thématiquement et géographiquement cohérents

Ces nœuds sont connectés par différents types de relations :
- *Relation VICINITY* : Connecte un POI au cluster auquel il appartient
- *Relation ROUTE* : Connecte deux clusters pour indiquer un itinéraire possible entre eux

Chaque relation peut porter des propriétés comme la distance, le temps estimé de parcours, ou d'autres métadonnées pertinentes pour le calcul d'itinéraires.

==== Avantages techniques
L'utilisation d'une base de données orientée graphe présente plusieurs avantages déterminants pour notre application :

1. *Performance des requêtes de traversée* : Le calcul d'itinéraires implique de nombreuses traversées de relations, opération pour laquelle les bases graphe sont optimisées, contrairement aux bases relationnelles qui nécessiteraient de multiples jointures coûteuses.
2. *Flexibilité du modèle* : L'ajout de nouveaux types de relations ou de propriétés aux nœuds existants ne nécessite pas de modifications de schéma, facilitant l'évolution du système.
3. *Requêtes expressives* : Le langage de requête Cypher de Neo4j permet d'exprimer des parcours complexes de manière intuitive. Par exemple, pour trouver tous les itinéraires possibles entre deux clusters :
```
MATCH path = (start:Cluster)-[:ROUTE*]->(end:Cluster)
WHERE start.id = $startId AND end.id = $endId
RETURN path
```
4. *Visualisation native* : Les bases graphe offrent des capacités de visualisation qui facilitent la compréhension des données et des relations entre POIs et clusters.



==== Implémentation technique
L'importation des données dans Neo4j :
- Transforme les POIs et clusters en format compatible avec Neo4j
- Crée les nœuds et relations nécessaires
- Attribue les propriétés appropriées aux nœuds et relations

Cette structure de graphe sert ensuite de base pour toutes les opérations de routage et de calcul d'itinéraires thématiques dans l'application.

=== Regroupement (Clustering)

==== Concept et objectif
Le regroupement (clustering) des points d'intérêt touristiques constitue une étape fondamentale dans notre système. Il permet de :
- Simplifier la représentation spatiale d'un grand nombre de POIs
- Créer des zones d'intérêt thématiques cohérentes
- Optimiser les calculs d'itinéraires en réduisant la complexité du graphe

==== Méthodologie technique
Notre approche de clustering repose sur plusieurs étapes techniques précises :

1. *Préparation des données spatiales* :
   - Conversion des coordonnées géographiques (latitude/longitude WGS84) en système de coordonnées métriques Lambert-93 adapté au territoire français
   - Cette transformation est essentielle pour calculer des distances euclidiennes significatives entre les points
2. *Application de l'algorithme HDBSCAN* :
   - Utilisation de l'algorithme HDBSCAN (Hierarchical Density-Based Spatial Clustering of Applications with Noise)
   - Paramètres configurables :
     - `min_cluster_size` : définit la taille minimale d'un cluster (valeur par défaut : 15)
     - `min_samples` : contrôle la sensibilité de la détection des clusters (valeur par défaut : 1)

```python
clusterize = hdbscan.HDBSCAN(min_cluster_size=min_cluster_size, min_samples=min_samples, metric='euclidean')
labels = clusterize.fit_predict(self.lambert)
```

3. *Traitement des points isolés* :
   - Identification des POIs non affectés à un cluster (étiquetés comme -1 par HDBSCAN)
   - Stratégies de gestion des points isolés :
     - Rattachement au cluster le plus proche si la distance est inférieure à un seuil paramétrable
     - Création de clusters individuels pour les POIs isolés restants

4. *Caractérisation des clusters* :
   - Calcul des centroïdes (centre géométrique de tous les POIs du cluster)
   - Détermination du rayon (distance maximale entre le centroïde et les POIs du cluster)
   - Évaluation de la densité (nombre de POIs par unité de surface)

#figure(image("../img/vicinities.png"), caption:"Regroupement de POIs en clusters")

==== Propriétés des clusters
Chaque cluster généré possède les propriétés suivantes :
- *Identifiant unique* : Label numérique attribué par l'algorithme
- *Catégorie thématique* : Catégorie dominante des POIs du cluster
- *Centroïde* : Coordonnées (x,y) du centre géométrique
- *Rayon* : Distance maximale entre le centroïde et les POIs du cluster
- *Nombre de POIs* : Quantité de points d'intérêt regroupés dans le cluster
- *Densité* : Rapport entre le nombre de POIs et la surface du cluster

Ces propriétés sont essentielles pour la phase suivante de routage, permettant de calculer des itinéraires optimisés entre clusters thématiques.

=== Routage entre clusters

==== Principe et objectif
Le routage entre clusters constitue le cœur fonctionnel de notre système d'itinéraires thématiques. Son objectif est de :
- Générer des connexions optimisées entre les clusters de même catégorie
- Permettre le calcul d'itinéraires complets entre points d'intérêt distants
- Garantir une expérience utilisateur fluide en proposant des parcours thématiques cohérents

==== Méthodologie de génération des routes
Notre approche de routage s'appuie sur des algorithmes de théorie des graphes pour créer un réseau de routes entre clusters :

1. *Génération de graphes par catégorie thématique* :
   - Pour chaque catégorie (musées, sites naturels, monuments historiques, etc.), un graphe distinct est généré
   - Cette approche garantit que les itinéraires proposés restent thématiquement cohérents

2. *Construction de l'arbre couvrant minimal* :
   - Utilisation de l'algorithme MST (Minimum Spanning Tree) pour établir une connectivité minimale entre tous les clusters
   - Calcul basé sur la distance euclidienne entre les centroïdes des clusters

```python
# Extrait de l'implémentation de l'arbre couvrant minimal
distances = pdist(self.points, metric='euclidean')
self.dist_matrix = squareform(distances)
mst = minimum_spanning_tree(self.dist_matrix)
edges = np.transpose(mst.nonzero())
```
3. *Enrichissement du graphe par triangulation de Delaunay* :
   - La triangulation de Delaunay est appliquée pour identifier des connexions potentiellement pertinentes entre clusters
   - Filtrage des arêtes supplémentaires selon deux critères précis :
     - Distance inférieure à un seuil paramétrable (`threshold_in_meters`)
     - Rapport entre distance directe et distance via le chemin existant supérieur à un facteur défini (`shortcut_factor`)

```python
# Extrait de l'enrichissement du graphe
tri = Delaunay(self.points)
for i, node in enumerate(self.points):
    neighbors_indices = np.unique(tri.simplices[tri.vertex_to_simplex[i]])
    # Filtrage et ajout conditionnel des arêtes
    if dist * shortcut_factor > mst_distance:
        continue
    if not self.graph.has_edge(i, neighbor):
        self.graph.add_edge(i, neighbor, weight=dist)
```

#figure(image("../img/routes.png"), caption:"Routes thématiques entre clusters")

==== Intégration avec Neo4j
Les routes calculées sont ensuite intégrées dans la base de données Neo4j :

1. *Création des relations de type ROUTE* :
   - Chaque arête du graphe généré devient une relation ROUTE entre les nœuds Cluster correspondants
   - Attribution de propriétés comme la distance, le temps estimé ou le moyen de transport recommandé
2. *Optimisation des requêtes de routage* :
   - Création d'index sur les propriétés fréquemment utilisées dans les requêtes de routage
   - Configuration de contraintes pour garantir l'unicité des identifiants de clusters

==== Calcul d'itinéraires complets
Le calcul d'un itinéraire thématique entre deux POIs suit un processus en plusieurs étapes :

1. *Identification des clusters d'origine et de destination* :
   - Détermination des clusters auxquels appartiennent les POIs de départ et d'arrivée

2. *Calcul du chemin optimal entre clusters* :
   - Utilisation de l'algorithme de plus court chemin de Neo4j pour déterminer la séquence optimale de clusters à traverser
   - Prise en compte des poids des relations (distance, temps) pour optimiser l'itinéraire

3. *Génération de l'itinéraire détaillé* :
   - Pour chaque segment entre clusters, sélection des POIs intermédiaires les plus pertinents
   - Construction de l'itinéraire complet sous forme de séquence ordonnée de POIs

Cette approche en trois niveaux (base de données graphe, clustering thématique, et routage entre clusters) permet de générer efficacement des itinéraires touristiques thématiquement cohérents, même sur de grandes distances géographiques, tout en optimisant les performances de calcul et l'expérience utilisateur.
