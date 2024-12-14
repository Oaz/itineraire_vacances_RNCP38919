import os
import json
import pandas as pd
import dt_utils.json_helper_functions as jh
import dt_utils.neo4j_helper as nh
from geo_utils.geo_clustering import GeoClustering
from geo_utils.geo_routing import GeoRouting

#########################
# Exemple de script ETL pour les clusters
# - Extraction des POIs
# - Transformation en clusters
# - Chargement du résultat dans neo4j
#########################

# 1 - Choix d'une catégorie
# Les clusters sont des regroupements de POIs voisins géographiques et de même catégorie
category = 'CulturalSite'

# 2 - Extraction des données
# Dans ce script, c'est la fonction 'create_pois_dataframe' qui lit les données dans les fichiers
# json Datatourisme. Au final, ces données devraient plutôt venir de postgres,
# surtout quand on voudra le faire pour de nombreuses catégories

def create_pois_dataframe():
  data_folder = '../../../datatourisme/metropole'
  data = []
  n = 0
  with open(os.path.join(data_folder, 'index.json'), 'r') as file:
    index_data = json.load(file)
  for entry in index_data:
    name: str = entry['label']
    file_path = entry['file']
    full_file_path = os.path.join(data_folder, 'objects', file_path)
    categories = jh.get_poi_category(full_file_path)
    n += 1
    if n % 1000 == 0:
      print(n)
    if category not in categories:
      continue
    id = jh.get_poi_identifier(full_file_path)
    lat, lon = jh.get_poi_coordinates(full_file_path)
    data.append({'id': id, 'name': name, 'lat': lat, 'lon': lon})
  return pd.DataFrame(data)


cache_file = 'pois.csv'
if os.path.exists(cache_file):
  df_pois = pd.read_csv(cache_file)
else:
  df_pois = create_pois_dataframe()
  df_pois.to_csv(cache_file, index=False)

# 3 - Regroupement des POIs en clusters
# Pour du fine-tuning, les paramètres de clustering pourraient être spécifiques à chaque catégorie ?
# - 'min_custer_size' : nombre minimal de POIs dans un cluster
# - 'threshold_in_meters' : post-traitement des POIs non clusterisés pour les rattacher à un cluster
#                           si leur distance au cluster est inférieure au seuil
print('CLUSTERING')
clustering = GeoClustering(df_pois)
clustering.create_clusters(min_cluster_size=5)
clustering.increase_clusters(threshold_in_meters=15000)
clustering.transform_unclustered_into_clusters()
df_clusters = clustering.clusters
df_vicinities = clustering.pois

# 4 - Création des routes entre les clusters
print('ROUTING')
routing = GeoRouting(df_clusters)
routing.increase(threshold_in_meters=15000)
routes = routing.edges

# 5 - Chargement des pois et des clusters dans neo4j
print('NEO4J IMPORT')
os.environ["NEO4J_URL"] = 'bolt://localhost:7687'
os.environ["NEO4J_USER"] = 'neo4j'
os.environ["NEO4J_PASSWORD"] = 'my_password'
with nh.connect_to_neo4j() as driver:
  print('  POIS')
  nh.import_pois(driver, df_pois)
  print('  CLUSTERS')
  nh.import_clusters(driver, category, df_clusters, df_vicinities)
  print('  ROUTES')
  nh.import_routes(driver, routes)

print('DONE')

