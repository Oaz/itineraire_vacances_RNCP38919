#import "../lib.typ": *

= Qualité des données <qualite>

== Outil de visualisation des données

=== Visualisation des réseaux de clusters thématiques

Le projet propose un outil interactif de visualisation des données permettant d'analyser la qualité des données en explorant les réseaux de clusters thématiques des points d'intérêt touristiques.

=== Fonctionnalités principales :

- *Sélection par catégorie* : L'utilisateur peut choisir parmi différentes catégories de clusters (sites culturels, événements, châteaux, etc.) via un menu déroulant qui affiche également le nombre de clusters et de routes pour chaque catégorie.

- *Visualisation graphique* : Les données sont présentées sous forme de graphe interactif où :
  - Les *nœuds* représentent les clusters avec une taille proportionnelle à leur rayon
  - La *couleur* des nœuds indique leur densité (échelle Viridis)
  - Les *arêtes* montrent les routes entre les clusters
  - Les coordonnées sont affichées en projection Lambert

- *Informations détaillées* : Au survol des clusters, l'utilisateur peut consulter les informations détaillées :
  - Coordonnées géographiques
  - Identifiant du cluster
  - Liste des points d'intérêt (POIs) associés au cluster

=== Architecture technique :

- Application web développée avec *Dash* (framework Python basé sur Flask)
- Interface interactive construite avec des composants *HTML* et *dcc* (Dash Core Components)
- Visualisation graphique via *Plotly*
- Données extraites de la base de données *Neo4j* contenant les clusters thématiques et leurs relations

Cette visualisation permet d'analyser la distribution spatiale des points d'intérêt touristiques, d'identifier les zones de concentration et d'explorer les connexions entre différents clusters thématiques, offrant ainsi un outil précieux pour l'analyse de la qualité et de la cohérence des données touristiques.

#page()[
== Analyse de quelques catégories

=== Sites culturels

L'analyse des clusters de sites culturels révèle une couverture particulièrement dense et uniforme sur l'ensemble du territoire français. Cette catégorie, qui regroupe une grande majorité des points d'intérêt touristiques, présente une distribution remarquablement homogène.

Si cette couverture exhaustive témoigne d'un bon référencement national, elle souligne également le caractère trop générique de cette classification. En effet, la prédominance du tag "site culturel" en fait une catégorie fourre-tout qui, bien qu'utile pour obtenir une vue d'ensemble du patrimoine culturel français, manque de précision pour des recherches thématiques spécifiques.

Cette catégorie offre donc une excellente base de données, mais son utilité est limitée pour les utilisateurs recherchant des expériences touristiques ciblées, à moins d'accepter une approche généraliste de la découverte culturelle.

#figure(image("../img/qualite_CulturalSite.png"), caption:[Clusters de la catégorie _sites culturels_])
]

#page()[
=== Événements culturels

La visualisation des clusters d'événements culturels met en évidence une distribution géographique très hétérogène, avec des concentrations importantes dans certaines régions et des zones quasiment dépourvues de référencement.

Cette répartition inégale s'explique principalement par la nature dynamique et temporaire de ces données, qui nécessitent des mises à jour constantes. La qualité et la quantité des informations dépendent fortement de l'implication des offices de tourisme locaux et de leur capacité à alimenter régulièrement la base de données. Les disparités observées révèlent ainsi les différences d'investissement des acteurs touristiques selon les territoires, certains départements comme le Lot se distinguant par une activité de référencement particulièrement intense (18% des événements culturels nationaux), tandis que d'autres régions comme l'Ardèche ou le Pas-de-Calais présentent des lacunes importantes.

Cette catégorie, bien que précieuse pour découvrir l'actualité culturelle, reflète davantage l'efficacité des systèmes d'information touristique locaux que la réalité de l'offre événementielle française.

#figure(image("../img/qualite_CulturalEvent.png"), caption:[Clusters de la catégorie _événements culturels_])
]

#page()[
=== Châteaux

L'analyse des clusters de châteaux révèle une couverture particulièrement problématique et incomplète. Contrairement à ce que la richesse du patrimoine castral français pourrait laisser supposer, très peu de points d'intérêt sont directement taggés "château".

Cette sous-représentation s'explique par un problème de catégorisation : la plupart des châteaux existants sont référencés sous d'autres classifications correspondant à un usage plutôt qu'à leur nature architecturale. On les retrouve ainsi dispersés dans diverses catégories comme "parcs et jardins", "musée" ou "location de salle", ce qui complique leur identification. Cette situation crée des anomalies frappantes, comme l'apparente absence totale de châteaux en Aquitaine, région pourtant riche de ce patrimoine. Les données révèlent également des incohérences territoriales, avec une concentration artificielle de châteaux dans le Bas-Rhin et la Haute-Marne, probablement due à des pratiques de référencement différentes selon les départements.

Cette fragmentation des données limite grandement l'utilité de cette catégorie pour une exploration thématique du patrimoine castral français.

#figure(image("../img/qualite_Castle.png"), caption:[Clusters de la catégorie _châteaux_])
]

== Billet de blog : _Il n'y a pas de château en Aquitaine_

Le billet #inline-link([_Il n'y a pas de château en Aquitaine_],"https://contretemps.azeau.com/post/pas-de-chateau-en-aquitaine/") du blog _Contretemps_ relate cette découverte de la qualité variable des données DATAtourisme.

En voici le texte intégral.

#show quote.where(block: true): block.with(stroke: (left:2pt + gray, rest: none))

#quote(block:true, [

La popularisation des #inline-link("données ouvertes","https://fr.wikipedia.org/wiki/Donn%C3%A9es_ouvertes") est une grande avancée de ces dernières années en informatique. La plateforme nationale #inline-link("data.gouv.fr","https://www.data.gouv.fr/") recense plus de 60000 jeux de données.

Je ne m'y étais jusqu'alors intéressé que sporadiquement mais mon activité récente m'a amené à plonger dans l'un de ces jeux de données. Et j'y ai (re)découvert quelques problèmes habituels des projets informatiques.

#inline-link("DATAtourisme","https://www.data.gouv.fr/fr/datasets/datatourisme-la-base-nationale-des-donnees-publiques-dinformation-touristique-en-open-data/") est présentée comme étant *la* base nationale des données publiques d'information touristique en Open Data. La description fait envie : mise à jour quotidienne de plusieurs dizaines de jeux de *données qualifiées*. Une *ontologie nationale* pour formaliser les données touristiques dans *un vocabulaire et un format uniformisé*.

Le principal principal problème de #inline-link("cette ontologie","https://www.datatourisme.fr/ontology/core/") ? Personne, ou presque, n'arrive à l'utiliser correctement. C'est super d'avoir défini 500 thèmes pour classer les points d'intérêt touristiques mais ça n'a d'intérêt que s'ils sont utilisés.

En pratique, on constate que les divers producteurs de données ont des usages très différents. L'agence de développement touristique du département du Lot est, par exemple, très active. Le nombre d'événements culturels y est impressionant. Si on se limite aux informations de cette base de données, 18% des #inline-link("événements culturels","https://www.datatourisme.fr/ontology/core/#CulturalEvent") et 15% de tous les #inline-link("événements sportifs","https://www.datatourisme.fr/ontology/core/#SportsEvent") en France se déroulent dans le Lot.

Par contre, si vous habitez en Ardèche ou dans le Pas de Calais, pas de bol : aucun événement culturel ou sportif à l'horizon.

Et les châteaux ?

Le bon plan pour voir beaucoup de #inline-link("châteaux","https://www.datatourisme.fr/ontology/core/#Castle"), c'est le Bas-Rhin ou la Haute-Marne. Et le mauvais plan, c'est l'Aquitaine. Aucun château dans les 5 départements de l'ancienne région.

Correction : aucun château connu comme étant un château.

Le #inline-link("château des Milandes","https://data.datatourisme.fr/23/9fbfcf59-2877-3dc0-af51-0cf24819af36") dans le Périgord, surtout connu pour avoir appartenu à Joséphine Baker, et référencé comme #inline-link("parc et jardin","https://www.datatourisme.fr/ontology/core/#ParkAndGarden"). Son voisin le #inline-link("château de Castelnaud","https://data.datatourisme.fr/23/b832283b-d56c-3e18-a2d1-056a7ba39d86") est lui un musée. Quant à l'étonnant #inline-link("château d'Abbadia","https://data.datatourisme.fr/23/d167ec03-81ff-3cda-87b8-c39da253fdff"), à Hendaye, on le trouvera comme #inline-link("location de salle","https://www.datatourisme.fr/ontology/core/#NonHousingRealEstateRental").

Rien n'empêche de tagger un point d'intérêt avec plusieurs thèmes, mais c'est rarement le cas.

Et c'est parfois le cas, mais ce n'est pas forcément mieux. Le château de Roquetaillade a 2 entrées : #inline-link("une comme musée et parc/jardin","https://data.datatourisme.fr/23/7562470c-834a-3653-8e53-a258b7e7da6a") et #inline-link("une autre comme location de salle","https://data.datatourisme.fr/23/fe269fcf-7d2a-3e8a-ba42-47fb1f9cd692").

Et ça se passe souvent comme ça. Dans les logiciels, tout ce qui n'est pas fortement contraint est, en général, utilisé de manière minimaliste. Les modèles métier très détaillés ne sont utiles que lorsque des mécanismes garantissent leur usage. Soit par remplissage automatisé via divers systèmes qui ont les données ou savent les acquérir automatiquement, soit par coercition des utilisateurs.

Les utilisateurs ne sont pas de mauvaise volonté. C'est juste un phénomène incontournable dans les systèmes d'information.

])





