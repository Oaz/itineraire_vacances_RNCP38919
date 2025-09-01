//#import "@preview/minimal-presentation:0.7.0": *
#import "slides_lib.typ": *

//#set text(font: "Lato")
//#show math.equation: set text(font: "Lato Math")
//#show raw: set text(font: "Fira Code")

#set figure(numbering: none)
#show figure: set figure.caption(position: top)

#let image-with-background(path) = box(fill: luma(220), inset: (x: 10pt, y: 10pt))[
  #image(path)
]

#show: project.with(
  title: "Itinéraires de vacances",
  sub-title: [Projet "fil rouge" - Data Engineer - RNCP 38919],
  author: "Olivier Azeau",
  date: "02/09/2025",
  index-title: "Sommaire",
  logo: image("./img/logo.svg"),
  logo-light: image("./img/logo_light.svg"),
  cover: image("./img/routes.png"),
  main-color: rgb("#E30512"),
  lang: "fr",
)

= Objectifs

== Vision Produit

- Problématique : Optimisation des séjours touristiques
- Solution : Génération automatique d’itinéraires personnalisés
- Public cible : Voyageurs autonomes, curieux, en quête d’expériences thématiques

#section-without-page()[Personas]

#let persona(id, content) = columns-content(colwidths: (4fr, 1fr))[
  #content
  #image("./img/gen/persona" + id + "_xpmap.png")
][
  #image("./img/persona" + id + ".jpg")
]

=== Claire, l’Enthousiaste Culturelle

#persona("01")[
  - Profil : 26 ans, responsable communication
  - Frustrations : Guides génériques, perte de temps
  - Attentes : Itinéraires thématiques hyper-spécifiques (ex: Art Déco)
]

=== Julien, le Road-Tripper Curieux

#persona("02")[
  - Profil : 46 ans, consultant
  - Frustrations : GPS standards sans détours culturels
  - Attentes : Contrôle des détours, découvertes spontanées
]

= Explorations

== DATAtourisme

#columns-content(colwidths: (1fr, 2fr))[
  - Base de données "opendata" de POIs
  - Alimentée par divers acteurs locaux liés au tourisme
  - Possibilités de ciblage du flux
    - Zone géographique
    - Types de POI
  - Update toutes les 24h
][
  #image("./img/datatourisme.png")
]

== OpenStreetMap

#columns-content(colwidths: (1fr, 2fr))[
  - Données collaboratives (similaire à Wikipedia)
  - Tags variés (historic, tourism...)
  - Web API ou téléchargement par zones
][
  #image("./img/osm.png")
]

== Google Places

#columns-content(colwidths: (1fr, 2fr))[
  - Web API payante (\~\$32 pour 1000 appels)
  - Utilisé dans Google Maps
  - Nombreuses données (avis, horaires, photos...)
][
  #image("./img/google_places.png")
]

== TripAdvisor

#columns-content(colwidths: (1fr, 2fr))[
  - Accès via sitemaps et scraping
  - Utile pour la réputation et le classement
  - Risque juridique
][
  #image("./img/tripadvisor.png")
]

= MVP

== Un premier scénario simple

- Un modèle relationnel
  - pour décrire les POIs
  - pour les rattacher à un découpage administratif
- Un modèle de graphe pour structurer les POIs dans des réseaux thématiques
- Une fonctionnalité de recherche d'itinéraire thématique entre 2 communes

== Modèle relationnel

#image-with-background("./img/schema_rdbms.svg")

== Modèle de Graphe

#columns-content(colwidths: (1fr, 1fr))[
  Stockage de l’ensemble des POIs dans neo4j
  pour le calcul d’itinéraires thématiques par catégorie
][
  #image-with-background("./img/poi_nodes.png")
]

=== Clustering Thématique

#columns-content(colwidths: (1fr, 1fr))[
  Dans chaque catégorie, les POIs sont regroupés par densité géographique.
  - HDBSCAN / scikit-learn
  - VICINITY entre POIs et clusters dans neo4j
][
  #image-with-background("./img/vicinities.png")
]

=== Routage entre Clusters

#columns-content(colwidths: (1fr, 1fr))[
  Dans chaque catégorie, génération d’un graphe entre les clusters
  - arbre couvrant de poids minimal
  - augmentation du graphe par sélection d’arêtes sur la triangulation de Delaunay
  - ROUTE entre clusters dans neo4j
][
  #image-with-background("./img/routes.png")
]

= Mise en oeuvre

== Gestion du Code

#columns-content(
  colwidths: (1fr, 1fr),
)[
  - Tout le code qui a de la logique _métier_ dans des modules élementaires indépendants
  - Tous ces modules élémentaires ont des tests automatisés
  - Utilisation de "test-containers" pour les modules qui font de l'intégration avec les systèmes tiers (bases de données)
][
  #image-with-background("./img/unit_tests.png")
]

=== Automatisation des tests

#columns-content(colwidths: (1fr, 1fr))[
  - Code hébergé sur _github_
  - Deux branches
    - *main* pour la version de référence
    - *dev* pour les fonctionnalités en cours de développement
  - Trigger _github actions_ sur la branche de dev
][
  #image-with-background("./img/github_actions.png")
]

== Conteneurisation

#image("./img/flux_applicatif.png")

== ETL Pipeline

#image("./img/gen/airflow_details.png")

== Web API

#columns-content(colwidths: (5fr, 4fr))[
  #table(
    columns: (1fr, 1fr),
    table.header([Point d'entrée], [Description]),
    [_/clustered_categories_],[Liste des catégories disponibles],
    [_/find_cities_],[Recherche d'une ville sur un nom partiel],
    [_/find_poi_],[Recherche d'un POI dans un lieu],
    [_/route_],[Recherche d'un itinéraire thématique entre 2 POIs],
    [_/poi_],[Détails d'un POI],
  )
][
  #image-with-background("./img/api.png")
]

== Monitoring

#columns-content(colwidths: (1fr, 1fr))[
  - _Prometheus_ pour la collecte des données
  - _Grafana_ pour le dashboard
  - Métriques
    - Volumes de données
    - État des services
][
  #image("./img/monitoring.png")
]

= Qualité

== Sites Culturels

#columns-content(colwidths: (1fr, 2fr))[
  Les catégories les plus utilisées offrent
  - Une très bonne couverture du territoire français
  - Peu d’intérêt thématique.
][
  #image("./img/qualite_CulturalSite.png")
]

== Événements Culturels

#columns-content(colwidths: (1fr, 2fr))[
  Certaines catégories sont sur-utilisées dans certaines régions.

  Exemple : CulturalEvent dans le département du Lot.
][
  #image("./img/qualite_CulturalEvent.png")
]

== Châteaux

#columns-content(
  colwidths: (1fr, 2fr),
)[
  Certaines catégories sont très ciblées mais ne sont pas utilisées de manière uniforme sur l’ensemble du territoire.

  _Il n'y a pas de chateaux en Aquitaine_
][
  #image("./img/qualite_Castle.png")
]

= Conclusion

== Bilan du MVP

#columns-content(colwidths: (1fr, 2fr))[
  - Potentiel technique confirmé
  - Limitation majeure : qualité des données
  - Itinéraires cohérents mais incomplets
][
  #figure(image("./img/itineraire.png"), caption: [Itinéraire _Sites naturels_ de Béziers à Mazamet])
]

#section-without-page()[Feuille de Route]

=== Enrichissement OpenStreetMap

#columns-content(colwidths: (1fr, 1fr))[
- Ingestion OSM dans l'ETL
- Matching géo-textuel DATAtourisme/OSM
- Correction des catégories
][
  #image-with-background("./img/abbadia_osm.png")
]

=== Popularité et Réputation


#columns-content(colwidths: (1fr, 1fr))[
- Exploitation d'un rating
- Éléments OSM
  - Présence dans Wikipedia/Wikidata
  - Quantité d'informations annexes
- Intégration Google Places et/ou TripAdvisor
][
  #image-with-background("./img/rating.svg")
]

#set-main-color(green)
#interlude("MERCI")