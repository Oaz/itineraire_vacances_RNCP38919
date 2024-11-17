# Datascientest / Projet itinéraire de vacances

## Étape 1 / Découverte des sources de données disponibles  

### A - Contexte et périmètre du projet

- Objectifs :  

Développer un outil de recommandation d'itinéraires de vacances, basé sur les préférences des utilisateurs permettant de découvrir des lieux touristiques et des activités à proximité

- Contraintes :
  - Les données doivent être collectées de manière automatisée
  - Les données doivent être actualisées régulièrement
  - Les données doivent être exploitables via une API

### B - Sources de données identifiées

- Datatourisme : 
  - Base de données de l'offre touristique française 
  - Segmentée par région et par type d'activité (hébergement, restauration, loisirs, culture, etc.)
  - Neutre et sans avis de consommateurs

- Tripadvisor.fr : 
  - Avis de voyageurs sur les lieux touristiques
- Google Places API : 
  - Informations sur les lieux touristiques

### C - Fonctionnement et extrait des différentes sources de données
- **DataTourisme** : 
  - Il faut créer un flux sur le portail datatourisme.gouv.fr contenant les éléments souhaités.
  - Le flux se génère automatiquement tous les jours à un horaire *indéterminé* sous
  - Il faut ensuite créer une "application" pour recevoir une clé afin de consommer l'API via une URL donnée
    - Par exemple : https://diffuseur.datatourisme.fr/webservice/a92d9021ef870f512dd7c4146b94f0a2/{app_key}  

  - le fichier ZIP contient 5 fichiers:
    - Un fichier d'index, listant les points d'intérêt contenus dans l'archive, avec leur dernière date de modication et le fichier json correspondant.
    - Un dossier objects contenant, au sein d'une hiérarchie itérative de dossiers, **un fichier pour chaque point d'intérêt**
    - Un fichier de contexte, permettant de transformer chaque fichier en JSON-LD (si besoin)

Exemple de fichier d'index :
```
index.json
[
  {
    "label": "JARDIN BOTANIQUE JEAN MARIE PELT",
    "lastUpdateDatatourisme": "2020-04-01T04:14:11.23Z",
    "file": "0/00/10-0037c361-4662-3bde-b1b3-6ac17d4e404d.json"
  },
  {
    "label": "MUSÉE DES ILLUSIONS",
    "lastUpdateDatatourisme": "2020-05-06T04:06:26.155Z",
    "file": "0/00/10-00f8d302-76a9-3691-a870-6b3a29e1bc6a.json"
  },
  {
    "label": "LA VIEILLE PORTE",
    "lastUpdateDatatourisme": "2020-05-06T04:06:26.154Z",
    "file": "0/02/10-0260d366-c31b-393b-aa0c-cfde4f067d30.json"
  }
]
```
Exemple de fichier pour un POI (tronqué pour lisibilité) :
```
objects/0/00/10-0037c361-4662-3bde-b1b3-6ac17d4e404d.json
{
  "@id": "https://data.datatourisme.fr/10/0037c361-4662-3bde-b1b3-6ac17d4e404d",
  "dc:identifier": "737000233",
  "@type": [
    "schema:Park",
    "CulturalSite",
    "ParkAndGarden",
    "PlaceOfInterest",
    "PointOfInterest"
  ],

 [...]

   "schema:geo": {
        "@id": "https://data.datatourisme.fr/caf751a5-191a-32bc-936f-4223eeb9986c",
        "schema:latitude": "48.66289762",
        "schema:longitude": "6.1553688",
        "@type": [
          "schema:GeoCoordinates"
        ]
      },
[...]
 ```
- Les données de DataTourisme sont grosses mais la totalité de la base peut être récupérée sans problème.
- Un feed qui prend tous les POI de France métropolitaine avec la totalité de leurs données fait 2.2GB zippé et ~12GB dezippé
- Le format est très verbeux. Par exemple le json complet pour ce [POI](https://data.datatourisme.fr/23/ff534eae-b544-3018-8ea0-9dfbc0c0ba63) fait 206kb dont 150kb ne servent qu'à donner les urls d'une soixantaine d'images jpeg

Pour la phase d'ingestion des données et compte tenu du fait que le rafraichissement du flux intervient toutes les 24H à un horaire inconnu, 
il semblerait utile de créer un flux sur un critère précis (région, type de POI...) et créer autant de flux que nécéssaire 
pour récupérer toutes les Informations "lissées" dans le temps.

Sur ce sujet, il semble q'une extraction des données par région soit effectuée et publiée sur [data.gouv.fr](https://data.datatourisme.fr/23/ff534eae-b544-3018-8ea0-9dfbc0c0ba63)
sous forme d'un fichier CSV.  


Ces fichiers possèdent la structure suivante :
```
Nom_du_POI,Categories_de_POI,Latitude,Longitude,Adresse_postale,Code_postal_et_commune,Periodes_regroupees,Covid19_mesures_specifiques,Createur_de_la_donnee,SIT_diffuseur,Date_de_mise_a_jour,Contacts_du_POI,Classements_du_POI,Description,URI_ID_du_POI
```
Bien que semblant attrayant au premier abord, les fichiers CSV ne sont pas propres et leur traitement implique de gérer un trop grand nombre de cas particulier.
--> Nous ne les utiliserons donc pas.  

- **Tripadvisor**  
Suite à rédiger pour décrire les datas Tripadvisor et la façon des les consommer (scrapper et/ou analyse des fichiers robots.txt) + exemple de données récupérées

- **Google Places**  
Suite à rédiger pour décrire les datas Google Places + consommation / Interet de la recherche  full text + exemple de données récupérée

## D - Remarques et Evolutions
  - Notes sur les évolutions possible de l'outils (ajout de filtres en plus du rating....)et les contraintes sur l'utilisation de certaines API (coût sur GCP, risque de bannissement d'IP pour le scraping..)  
  A rédiger