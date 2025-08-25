#import "../lib.typ": *

= Exploration des sources de données <exploration>

== Introduction

En amont de la définition de l'application cible, nous explorons de manière approfondie les principales sources de données touristiques
que nous allons utiliser pour notre application d'itinéraires personnalisés.
Notre objectif est d'identifier et d'analyser les sources les plus pertinentes pour obtenir des informations fiables et complètes sur les points d'intérêt (POI).

L'exploration se concentre sur quatre sources majeures :
1. *DataTourisme* : une plateforme nationale française d'open data dédiée au tourisme, qui fournit des données structurées et standardisées sur les points d'intérêt touristiques.
2. *Google Places* : une API commerciale offrant des informations détaillées sur les établissements, attractions et lieux publics, enrichies par les contributions et évaluations des utilisateurs.
3. *OpenStreetMap* : une base de données géographique collaborative mondiale, qui contient une multitude d'informations sur les points d'intérêt touristiques et historiques.
4. *TripAdvisor* : une plateforme riche en avis et évaluations d'utilisateurs, permettant d'identifier les attractions les plus populaires et appréciées.

Pour chaque source, nous examinons :
- La structure et le format des données disponibles
- Les méthodes d'accès et d'extraction
- La richesse et la pertinence des informations pour notre application
- Les avantages et limitations spécifiques

Cette exploration nous permet de déterminer la stratégie optimale pour constituer notre base de données de POI, en combinant potentiellement plusieurs sources pour maximiser la qualité et la couverture des informations.

== Exploration de DataTourisme

==== Description

DATAtourisme est un dispositif national porté par la Direction Générale des Entreprises,
en partenariat avec le réseau Tourisme & Territoires, et co-construit avec les réseaux des offices
de tourisme de France et des comités régionaux du tourisme, visant à faciliter l’accès aux
données publiques d’information touristique, au moyen d’une plateforme Open Data et
de l’animation d’une communauté d’utilisateurs.

==== Accès aux données

- le moyen principal pour récupérer des données est de créer des "feeds" spécialisés sur les données qui nous intéressent
- un nouveau zip de données correspondant à un feed est généré chaque jour par la plateforme et peut être téléchargé
- pour automatiser ce téléchargement, il faut créer une "application"
- Chaque feed correspond à une requête SPARQL
- Cette requête peut être créée visuellement. Dans ce cas, elle se limite à un filtrage
  - par type de POI
  - par entité géographique contenant les POI

#figure(image("../img/datatourisme.png"),caption:"Interface utilisateur DATAtourisme")

Exemple de requête avec filtre sur les types de POI et les zones géographiques :
```
CONSTRUCT {
    ?res <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <urn:resource>.
} WHERE {
    ?res <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.datatourisme.fr/ontology/core#PointOfInterest>.
    ?res <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type.
    ?res <https://www.datatourisme.fr/ontology/core#isLocatedAt> ?61f14e39.
    ?61f14e39 <http://schema.org/address> ?e2dc5ce6.
    ?e2dc5ce6 <https://www.datatourisme.fr/ontology/core#hasAddressCity> ?2b7e3a94.
    ?2b7e3a94 <https://www.datatourisme.fr/ontology/core#isPartOfDepartment> ?41508c7e.
    VALUES ?type {
        <https://www.datatourisme.fr/ontology/core#Store>
        <https://www.datatourisme.fr/ontology/core#NaturalHeritage>
        <https://www.datatourisme.fr/ontology/core#SportsAndLeisurePlace>
    }
    VALUES ?41508c7e {
        <https://www.datatourisme.fr/resource/core#France7611>
        <https://www.datatourisme.fr/resource/core#France7631>
    }
}
```

- on peut passer à une édition avancée où on écrit du SPARQL. Cela permet de ne récupérer que les champs qui nus intéressent.

Exemple:
```
SELECT ?resource ?type ?location ?address ?city ?department
WHERE {
  ?resource <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.datatourisme.fr/ontology/core#PointOfInterest>.
  ?resource <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type.
  FILTER(?type IN(<https://www.datatourisme.fr/ontology/core#Store>, <https://www.datatourisme.fr/ontology/core#NaturalHeritage>, <https://www.datatourisme.fr/ontology/core#SportsAndLeisurePlace>))
  ?resource <https://www.datatourisme.fr/ontology/core#isLocatedAt> ?location.
  ?location <http://schema.org/address> ?address.
  ?address <https://www.datatourisme.fr/ontology/core#hasAddressCity> ?city.
  ?city <https://www.datatourisme.fr/ontology/core#isPartOfDepartment> ?department.
  FILTER(?department IN(<https://www.datatourisme.fr/resource/core#France7611>, <https://www.datatourisme.fr/resource/core#France7631>))
}
```

- Un feed qui prend tous les POI de France métropolitaine avec la totalité de leurs données pèse 2.2GB zippé et ~12GB dezippé
- le format est _très_ verbeux. Par exemple le json complet pour #inline-link("ce POI","https://data.datatourisme.fr/23/ff534eae-b544-3018-8ea0-9dfbc0c0ba63") fait 206kb dont 150kb ne servent qu'à donner les urls d'une soixantaine d'images jpeg

==== Fichiers JSON

Un feed DATAtourisme génère une archive ZIP contenant plusieurs fichiers JSON :

1. Un fichier d'index, listant les points d'intérêt contenus dans l'archive, avec leur dernière date de modification dans la plateforme et le chemin depuis le dossier objects pour atteindre le fichier JSON du point d'intérêt.
2. Un dossier objects contenant, au sein d'une hiérarchie itérative de dossiers, un fichier JSON pour chaque point d'intérêt.
3. Un fichier de contexte, permettant de transformer chaque fichier en #inline-link("JSON-LD","https://json-ld.org/"), si besoin.

La documentation complète du contenu est dans #inline-link("l'ontologie de DATAtourisme","https://gitlab.adullact.net/adntourisme/datatourisme/ontology/-/blob/develop/Documentation/Doc-ontologie-3.1.0-FR.pdf").

Les champs de ces fichiers JSON qui nous intéressent plus particulièrement sont :
- *\@id* : l'unique id exemple `https://data.datatourisme.fr/3/00da4750-e592-3538-aa49-876f0b0f4f18`
- *\@type* : les catégories exemple `["schema:LocalBusiness", "PlaceOfInterest", "PointOfInterest", "Store"]`
- *rdfs:comment* : une description avec toutes ses traductions
- *rdfs:label* : le nom il peut être écrit avec plusieurs traductions exemple `{"fr": ["Nemesis Pâtisserie"]}`
- *hasContact* : avec les emails *schema:email*, les téléphones *schema:telephone* et les sites web *foaf:homepage*
- *isLocatedAt* : La localisation avec "schema:address" où l'on retrouve la commune, le code postal, le département, la région et l'adresse, mais aussi avec "schema:geo" nous avons la latitude et la longitude et pour finir avec "openingHoursSpecification" nous obtenons les horaires d'ouverture.
- *lastUpdate* et *lastUpdateDatatourisme* : la date de dernière mise à jour ce qui nous permettra de savoir si nous sommes à jour.
- *offers*": les tarifs si il y en a.

L'ontologie de DATAtourisme, comprenant notamment l'ensemble des catégories avec leurs traductions est également disponible #inline-link("sous forme structurée","https://www.datatourisme.fr/ontology/core/").

Exemple de catégorie dans l'ontologie :
```
###  https://www.datatourisme.fr/ontology/core#CulturalEvent
:CulturalEvent
  rdf:type owl:Class ;
  rdfs:subClassOf :EntertainmentAndEvent ;
  rdfs:label "Acto cultural"@es ,
    "Cultural event"@en ,
    "Cultureel evenement"@nl ,
    "Evento cultural"@pt ,
    "Evento culturale"@it ,
    "Kulturelle Veranstaltung"@de ,
    "Évènement culturel"@fr .
```

Ces informations peuvent être croisées avec le champ *\@type* d'un POI.

Exemple de champ *\@type* d'un POI :
 ```
 "@type": [
    "schema:Event",
    "schema:ExhibitionEvent",
    "schema:SaleEvent",
    "schema:SocialEvent",
    "CulturalEvent",
    "EntertainmentAndEvent",
    "Exhibition",
    "LocalAnimation",
    "Market",
    "PointOfInterest",
    "SaleEvent",
    "SocialEvent"
  ],
```

==== Fichiers CSV pré-définis

L'ensemble des données est aussi disponible directement sur #inline-link("data.gouv.fr","https://www.data.gouv.fr/fr/datasets/datatourisme-la-base-nationale-des-donnees-publiques-dinformation-touristique-en-open-data/#/resources") sous forme de fichiers CSV.

Les fichiers CSV ont les colonnes suivantes :
- *Nom_du_POI* : Le nom.
- *Categories_de_POI* : Les catégories, chaque catégorie est séparé par des "|" exemple : `https://www.datatourisme.fr/ontology/core#PlaceOfInterest|https://www.datatourisme.fr/ontology/core#PointOfInterest|https://www.datatourisme.fr/ontology/core#Accommodation|https://www.datatourisme.fr/ontology/core#RentalAccommodation|https://www.datatourisme.fr/ontology/core#SelfCateringAccommodation|http://schema.org/Accommodation|http://schema.org/LodgingBusiness`
- *Latitude* : La latitude.
- *Longitude* : La longitude.
- *Adresse_postale* : L'adresse postale.
- *Code_postal_et_commune* : Le code postal et la commune, le code postal et la commune sont séparé par un "\#" exemple: `84580#Oppède`
- *Periodes_regroupees* : Les dates de débuts et de fin d'évènement, elles sont composé d'une date de début (YYYY_MM-DD), la date de début est de fin est séparé par "<->", suivi de la date de fin et séparé par "|" exemple `2024-11-02<->2024-11-02|2024-12-07<->2024-12-07|2024-10-27<->2024-10-27|2024-11-17<->2024-11-17|2024-12-22<->2024-12-22`
- *Covid19_mesures_specifiques* : La listes des mesures Covid19, c'est un texte détaillant les différentes mesures.
- *Createur_de_la_donnee* : Le créateur de la donnée.
- *SIT_diffuseur* : Le Système d'Information Touristique diffuseur.
- *Date_de_mise_a_jour* : La date de la dernière mise à jour.
- *Contacts_du_POI* : Les contacts, ils sont séparés par des "\#" si il n'y a que "\#" dans le champ c'est une valuer null, exemple `#https://www.aixenprovencetourism.com/|Office de Tourisme d'Aix-en-Provence#https://reservation.aixenprovencetourism.com/musee-regards-de-provence-visite-libre.html`
- *Classements_du_POI* : Classements suivant différente catégories, on retrouve des classements avec une valeur et une catégorie séparé par "\#" qui sont séparés par "|" exemple `Tourisme & Handicap auditif#Marque Tourisme et Handicap|Tourisme & Handicap visuel#Marque Tourisme et Handicap|Tourisme & Handicap mental#Marque Tourisme et Handicap|Tourisme & Handicap moteur#Marque Tourisme et Handicap`
- *Description* : La description.
- *URI_ID_du_POI* : L'ID unique


== Exploration de Google Places

Google propose la #inline-link("Places API","https://developers.google.com/maps/documentation/places/")  pour récupérer des informations sur les POI

=== Prise en main basique

- Connexion sur la #inline-link("console Google Cloud","https://console.cloud.google.com/")
- Création d'un projet, et sur ce projet :
  - Aller dans "API et services" / "Bibliothèque"
  - rechercher "Places API" et l'activer
  - Aller dans "Clés et identifiants" / "Créer des identifiants" / "Clé API"
  - Modifier la clé API obtenue par sécurité
    - restreindre à sa propre adresse IP
    - restreindre à l'API "Places"
- Revenir à l'accueil du projet et aller dans "Facturation"
- Associer un compte de facturation au projet - c'est obligatoire pour utiliser la clef API

=== Exemple de code pour utiliser la route "text search" de Places API

Les text search coutent \$32 pour 1000 appels sachant qu'une recherche peut utiliser plusieurs appels avec la pagination.

```py
import os
import requests
import time
import json

API_KEY = "XXXXXXXXXXXXXXXXXXXXX"

def save_place_data(place_data, directory):
  place_id = place_data.get("place_id")
  if place_id:
    filename = f"{place_id}.json"
    file_path = os.path.join(directory, filename)
    with open(file_path, 'w') as file:
      json.dump(place_data, file, indent=4)
    print(f"Saved place data to {file_path}")
  else:
    print("Place data does not contain a place_id, skipping.")

def get_places(query, api_key, save_directory):
  places = []
  next_page_token = None

  while True:
    params = {
      "query": query,
      "key": api_key
    }
    if next_page_token:
      params["pagetoken"] = next_page_token

    response = requests.get(
      "https://maps.googleapis.com/maps/api/place/textsearch/json",
      params=params
    )

    if response.status_code == 200:
      data = response.json()
      for place in data.get("results", []):
        save_place_data(place, save_directory)
        places.append(place)

      next_page_token = data.get("next_page_token")

      if not next_page_token:
        break

      time.sleep(2)
    else:
      print(f"Error: {response.status_code}")
      break

  return places

folder = "places_data"

if not os.path.exists(folder):
  os.makedirs(folder)

for p in get_places("activities in Carcassonne, France", API_KEY, folder):
  print(f"Name: {p['name']}, Rating: {p.get('rating', 'N/A')}")
```

Exemple de "place" renvoyée par l'API :

```json
{
    "business_status": "OPERATIONAL",
    "formatted_address": "1 Rue Viollet le Duc, 11000 Carcassonne, France",
    "geometry": {
        "location": {
            "lat": 43.2060816,
            "lng": 2.3641961
        },
        "viewport": {
            "northeast": {
                "lat": 43.20763622989273,
                "lng": 2.366772349999999
            },
            "southwest": {
                "lat": 43.20493657010728,
                "lng": 2.363337350000001
            }
        }
    },
    "icon": "https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/generic_business-71.png",
    "icon_background_color": "#7B9EB0",
    "icon_mask_base_uri": "https://maps.gstatic.com/mapfiles/place_api/icons/v2/generic_pinlet",
    "name": "Cit\u00e9 de Carcassonne",
    "opening_hours": {
        "open_now": true
    },
    "photos": [
        {
            "height": 4000,
            "html_attributions": [
                "<a href=\"https://maps.google.com/maps/contrib/103693207243911837951\">A Google User</a>"
            ],
            "photo_reference": "AdDdOWol5kMeaYziE-UZYB9AAqiHoNbqANXnxNg0F3xM-0PisZEC7BS_bB6Dh3W9w69OaJjRaeQAUFyFh-imYWeDYQos8tDMwxs531tJAhp9VrWEFPkmLdepcFqp490moYv7XyVtlkJa1oD8JaNwrrlGHXE-w91dCya6p9a6cxLSPZkdFfUn",
            "width": 6000
        }
    ],
    "place_id": "ChIJtzSv52osrhIRdMhoy9K25VI",
    "plus_code": {
        "compound_code": "6947+CM Carcassonne",
        "global_code": "8FM46947+CM"
    },
    "rating": 4.7,
    "reference": "ChIJtzSv52osrhIRdMhoy9K25VI",
    "types": [
        "tourist_attraction",
        "point_of_interest",
        "establishment"
    ],
    "user_ratings_total": 85126
}
```

== Exploration de Open Street Map

Les données dans Open Street Map peuvent être
- un noeud (node) = un point avec une paire de coordonnées latitude/longitude
- une voie (way) = une succession de noeuds
- une relation = ensemble de noeuds et voies auquel on associe une sémantique

Voir #inline-link("la documentation associée","https://wiki.openstreetmap.org/wiki/FR:%C3%89l%C3%A9ments") pour plus d'informations.

Chacun de ces éléments, noeud, voie ou relation possède un dictionnaire d'attributs (tags). Chaque attribut est composé d'une clef et d'une valeur.

Les règles qui définissent les attributs sont mouvantes et #inline-link("décrites dans le wiki","https://wiki.openstreetmap.org/wiki/Category:FR:Attributs").

Pour tout ce qui est relatif au toursime, on peut s'intéresser aux clefs d'attribut :
- 'historic' : qui présente un aspect historique. Exemples: historic=castle, historic=tomb, historic=monument, etc.
- 'attraction' : qui est une attraction. Exemple: attraction=carousel, attraction=animal, attraction=water_slide, etc.
- 'tourism' : qui présente un aspect touristique.
  - Exemple : tourism=museum, tourism=picnic_site, etc.
  - Idéalement, tous les éléments avec un attribut 'attraction=xxxx' ont aussi un 'tourism=attraction'. C'est parfois le cas.
  - Les éléments avec un attribut 'historic=xxxx' ont parfois un 'tourism=historic' ou un 'tourism=attraction'.
  - Les règles ont pu évoluer il ne semble pas y avoir de consistence.
- 'heritage' : les monuments historiques [classés ou inscrits](https://wiki.openstreetmap.org/wiki/Key:heritage#France)

Ces attributs relatifs au tourisme
- portent le plus souvent sur des noeuds
- mais parfois aussi sur des voies. Exemple : contour d'un site, rue touristique, oeuvre d'art...
- et plus rarement sur des relations pour les grands ensembles architecturaux

Il existe 2 façons de récupérer les données :
- via une Web API nommée #inline-link("Overpass","https://wiki.openstreetmap.org/wiki/Overpass_API")
  - L'API peut être testée sur #inline-link("https://overpass-turbo.eu/","https://overpass-turbo.eu/")
- En téléchargeant l'ensemble des données pour une zone extraites dans un format binaire '.pbf'
  - La #inline-link("totalité des données pour la France","https://download.openstreetmap.fr/extracts/europe/france.osm.pbf") dans ce format fait ~5Gb
  - Il existe aussi #inline-link("des extractions par région et par département","https://download.openstreetmap.fr/extracts/europe/france/")

Pour les gros volumes de données, le format binaire sur une grande zone est préférable.
Il existe des bibliothèques Python pour lire ces fichiers.

Exemple de données extraites : #inline-link("aude.poi.json.zip","https://github.com/user-attachments/files/17792891/aude.poi.json.zip")

Exemple de code d'extraction de données à partir d'un fichier pbf

```py
import json
import osmium

zone = 'aude'


class OSMHandler(osmium.SimpleHandler):
  def __init__(self):
    super(OSMHandler, self).__init__()
    self.items_by_kind = {}
    self.node_locations = {}

  def node(self, n):
    kind = self.get_kind(n)
    if kind is None:
      return
    node_info = {
      "class": "node",
      "id": n.id,
      "lat": n.location.lat,
      "lon": n.location.lon,
      "tags": dict(n.tags)
    }
    self.node_locations[n.id] = (n.location.lat, n.location.lon)
    self.add_by_kind(kind, node_info)

  def way(self, w):
    kind = self.get_kind(w)
    if kind is None:
      return
    way_info = {
      "class": "way",
      "id": w.id,
      "tags": dict(w.tags)
    }
    self.add_by_kind(kind, way_info)

  def relation(self, r):
    kind = self.get_kind(r)
    if kind is None:
      return
    relation_info = {
      "class": "relation",
      "id": r.id,
      "tags": dict(r.tags)
    }
    self.add_by_kind(kind, relation_info)

  def add_by_kind(self, kind, item):
    if kind not in self.items_by_kind:
      self.items_by_kind[kind] = []
    self.items_by_kind[kind].append(item)

  @staticmethod
  def get_kind(item):
    if 'historic' in item.tags:
      kind = item.tags['historic']
    elif 'attraction' in item.tags:
      kind = item.tags['attraction']
    elif 'tourism' in item.tags:
      kind = item.tags['tourism']
    elif 'heritage' in item.tags:
      kind = 'heritage'
    else:
      kind = None
    return kind


def read_pbf(file_path):
  handler = OSMHandler()
  handler.apply_file(file_path)

  output = handler.items_by_kind

  with open(f'{zone}.poi.json', 'w') as json_file:
    json.dump(output, json_file, indent=4)


if __name__ == "__main__":
  pbf_file_path = f'{zone}.osm.pbf'
  read_pbf(pbf_file_path)
```

Une information intéressante présente dans les tags : le lien vers wikipedia et/ou wikidata
La présence de cette information pourrait permettre de filtrer les POIs qui ont le plus d'intérêt.

Exemple:
```
{
    "id": 249434910,
    "lat": 43.3523294,
    "lon": 1.8269694,
    "tags": {
        "historic": "monument",
        "man_made": "obelisk",
        "name": "Ob\u00e9lisque de Riquet",
        "tourism": "attraction",
        "website": "https://www.canal-du-midi.com/decouvrir/fil-eau/toulouse-a-naurouze/seuil-naurouze/",
        "wheelchair": "yes",
        "wikidata": "Q7335778",
        "wikipedia": "fr:Ob\u00e9lisque de Riquet"
    }
}
```

- Lien vers wikidata: #inline-link("Q7335778","https://www.wikidata.org/wiki/Q7335778")
- Lien vers wikipedia: #inline-link("fr:Ob\u00e9lisque de Riquet","https://www.wikipedia.org/wiki/fr:Obélisque%20de%20Riquet")

== Exploration de TripAdvisor

#inline-link("Cette discussion en ligne","https://www.growthhacking.fr/t/scraping-tripadvisor-code-sans-code/12971?page=2") donne une approche systématique pour parcourir TripAdvisor :
- récupérer le #inline-link("robots.txt","https://www.tripadvisor.fr/robots.txt")
- on y trouve l'adresse de plusieurs sitemaps. 6 me semblent intéressants a priori :
  - le #inline-link("sitemap global","https://www.tripadvisor.fr/sitemap/2/fr/sitemap_fr_index.xml")
  - le #inline-link([sitemap _user reviews_],"https://www.tripadvisor.fr/sitemap/2/fr/sitemap_fr_show_user_reviews_index.xml")
  - les sitemaps "attractions"
    - #inline-link([les attractions],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attractions_index.xml")
    - #inline-link([leurs reviews],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attraction_review_index.xml")
    - #inline-link([une autre sorte de reviews],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attraction_product_review_index.xml")
    - #inline-link([les voisinages des attractions],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attractions_near_index.xml")

=== Le sitemap general

C'est un xml qui contient lui même des liste d'urls d'xml.
Exemples :
- https://www.tripadvisor.fr/sitemap/2/fr/sitemap-1950859-fr-hotel_review-1723744682.xml.gz
- https://www.tripadvisor.fr/sitemap/2/fr/sitemap-1950860-fr-hotel_review-1723744685.xml.gz
- https://www.tripadvisor.fr/sitemap/2/fr/sitemap-1964721-fr-hotels_near-1727654737.xml.gz
- https://www.tripadvisor.fr/sitemap/2/fr/sitemap-1976625-fr-restaurants-1730779650.xml.gz
- https://www.tripadvisor.fr/sitemap/2/fr/sitemap-1686471-fr-flights-1628787201.xml.gz
- etc. il y en a 422

Ce sont en grande majorité des sitemaps "hotels" et "restaurants".
En récupérant la totalité de ces fichiers, on obtient les urls de tous les hotels et restaurants sur TripAdvisor.
Par exemple chaque fichier hotel_review-xxxxxx.xml.gz contient 50000 urls d'hotels.

Les fichiers "tourism" peuvent également être intéressants. Ils donnent les listes de lieux avec l'url "Vacations" pour chacun d'entre eux.
#inline-link([Exemple],"https://www.tripadvisor.fr/Tourism-g13320446-Carcassonne_Aude_Occitanie-Vacations.html").

Ces pages vacations pourraient peut être permettre d'identifier les POI les plus intéressants en ne récupérant qu'une seule page par ville/village.

=== Le sitemap user reviews

C'est une liste d'environ 900 fichiers xml "user reviews"
Chacun d'entre eux contient 50000 urls, soit au total plus de 45 millions d'urls (!!!)
Ce sont les pages "reviews" de tous les hotels/restaurants/activités/etc.
#inline-link([Exemple],"https://www.tripadvisor.fr/ShowUserReviews-g187175-d241435-r610823357-Theatre_Du_Capitole_Toulouse-Toulouse_Haute_Garonne_Occitanie.html")

=== Les sitemaps attractions

Dans le #inline-link([map principal des attractions],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attractions_index.xml"), on trouve la liste des fichiers attractions-xxxxxxx.xml.gz dans lesquels on va retrouver les urls des activités pour chaque lieu.
Problème : il y a plusieurs pages par lieu.
Exemple :
- #inline-link([Sites et monuments à Carcassonne],"https://www.tripadvisor.fr/Attractions-g13320446-Activities-c47-t163-Carcassonne_Aude_Occitanie.html")
- #inline-link([Taxis et navettes à Carcassonne],"https://www.tripadvisor.fr/Attractions-g13320446-Activities-c59-t182-Carcassonne_Aude_Occitanie.html")
- #inline-link([Cours de cuisine à Carcassonne],"https://www.tripadvisor.fr/Attractions-g13320446-Activities-c36-t203-Carcassonne_Aude_Occitanie.html")
- etc.

Les _meilleures activités_ pour un lieu donné y sont aussi mais il faut les filtrer par rapport à la structure de l'url.
#inline-link([Exemple],"https://www.tripadvisor.fr/Attractions-g13320446-Activities-Carcassonne_Aude_Occitanie.html")

Dans #inline-link([le map des attractions reviews],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attraction_review_index.xml"),
on a des fichiers attraction_review-xxxxxxxx.xml qui listent les pages des reviews avec 1 page par activité.
#inline-link([Exemple],"https://www.tripadvisor.fr/Attraction_Review-g187151-d5502593-Reviews-Eglise_Saint_Gimer-Carcassonne_Center_Carcassonne_Aude_Occitanie.html")

Dans #inline-link([l'autre map des attractions reviews],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attraction_product_review_index.xml"),
qui s'appelle "attractions_product_review", on trouve plutôt des visites ou des trajets.
#inline-link([Exemple],"https://www.tripadvisor.fr/AttractionProductReview-g187151-d13830944-Carcassonne_walking_tour-Carcassonne_Center_Carcassonne_Aude_Occitanie.html")

Mais on trouve aussi des visites dans le "attractions reviews"...
#inline-link([Exemple],"https://www.tripadvisor.fr/Attraction_Review-g13320446-d20295971-Reviews-Carcassonne_During_World_War_2-Carcassonne_Aude_Occitanie.html")

Dans le #inline-link([map des voisinages des attractions],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attractions_near_index.xml"),
on trouve les activités près d'une autre activité.

En première approche, les pages "attractions" qui regroupent l'ensemble des "meilleures" activités d'un lieu
(#inline-link([Exemple],"https://www.tripadvisor.fr/Attractions-g13320446-Activities-Carcassonne_Aude_Occitanie.html")) semblent être les plus intéressantes parmi tout ce que peut offrir TripAdvisor :
- on récupère beaucoup d'information sur une seule url (donc moins à Scraper, moins de risque de se faire bloquer)
- on repère, potentiellement, les POI les plus "intéressants" d'un lieu (ce que n'a pas DataTourisme qui est "neutre")
- on a les notes des diverses activités mentionnées ce qui évite de prendre les notes basses même si les activités sont listées
- on peut facilement se focaliser sur une zone géographique pour tester l'idée

L'ensemble de ces pages sont référencées dans les fichiers "attractions-xxxxxxx.xml.gz", eux mêmes listés dans
le #inline-link([map des attractions],"https://www.tripadvisor.fr/sitemap/att/fr/sitemap_fr_attractions_index.xml")

