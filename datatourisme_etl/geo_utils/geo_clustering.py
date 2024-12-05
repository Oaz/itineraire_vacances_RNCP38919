import pandas as pd
import numpy as np
import hdbscan
from sklearn.metrics import pairwise_distances
from pyproj import Transformer


class GeoClustering:
  def __init__(self, pois: pd.DataFrame, longitude_column: str = "lon", latitude_column: str = "lat"):
    """
    Initialisation d'un geo-clustering
    :param pois: pd.DataFrame - Les POIs à regrouper
    :param longitude_column: str - nom de la colonne des longitudes dans le dataframe
    :param latitude_column: str - nom de la colonne des latitudes dans le dataframe
    """
    self.pois = pois
    self.__add_lambert_metric_coordinates(longitude_column, latitude_column)
    self.__clusters = pd.DataFrame()

  def __add_lambert_metric_coordinates(self, longitude_column: str, latitude_column: str):
    # EPSG:9794 est le code EPSG pour la projection "RGF93 v2b / Lambert-93" utilisée en France
    # cf https://fr.wikipedia.org/wiki/Projection_conique_conforme_de_Lambert#Lambert_93
    transformer = Transformer.from_crs("EPSG:4326", "EPSG:9794", always_xy=True)
    self.lambert = self.pois.apply(
      lambda poi: tuple(map(int, transformer.transform(poi[longitude_column], poi[latitude_column]))),
      axis=1, result_type='expand'
    )
    self.pois[['x', 'y']] = self.lambert

  def create_clusters(self, min_cluster_size: int = 15, min_samples: int = 1):
    """
    Identifie des clusters avec HDBSCAN sur les coordonnées projetées Lambert
    :param min_cluster_size: int - HDBSCAN min_cluster_size
    :param min_samples: int - HDBSCAN min_samples
    """
    clusterize = hdbscan.HDBSCAN(min_cluster_size=min_cluster_size, min_samples=min_samples, metric='euclidean')
    labels = clusterize.fit_predict(self.lambert)
    self.pois['cluster'] = labels
    unique_labels = np.unique(labels[labels != -1])
    centroids = np.array([self.lambert[labels == label].mean(axis=0).astype(int) for label in unique_labels])
    self.__clusters = pd.DataFrame(data=centroids, index=unique_labels, columns=['x', 'y'])

  def increase_clusters(self, threshold_in_meters: int):
    """
    Associe à un cluster existant les POIs non clusterisés dont la distance au centre
    du cluster est inférieure au seuil
    :param threshold_in_meters: int - seuil de rattachement d'un POI à un cluster
    """
    unclustered = self.unclustered_pois
    if unclustered.empty:
      return
    distances = pairwise_distances(unclustered[['x', 'y']], self.__clusters[['x', 'y']])
    min_distances = distances.min(axis=1)
    nearest_cluster_indices = distances.argmin(axis=1)
    for i, (distance, cluster_index) in enumerate(zip(min_distances, nearest_cluster_indices)):
      if distance <= threshold_in_meters:
        self.pois.at[unclustered.index[i], 'cluster'] = self.__clusters.index[cluster_index]

  @property
  def unclustered_pois(self) -> pd.DataFrame:
    """
    Renvoie un DataFrame des POIs qui ne sont pas dans un cluster
    """
    return self.pois[self.pois['cluster'] == -1]

  @property
  def clusters(self) -> pd.DataFrame:
    """
    Renvoie un DataFrame avec 1 cluster par ligne et les colonnes:
    - index : label du cluster
    - x | coordonnées du centre du cluster
    - y |
    - radius : distance maximale entre le centre du cluster et les POIs du cluster
    - count : nombre de POIs dans le cluster
    - density : count / radius²
    """
    if self.__clusters.empty:
      return self.__clusters

    def compute_details(cluster_label, centroid):
      cluster_members = self.pois[self.pois['cluster'] == cluster_label][['x', 'y']]
      distances = np.linalg.norm(cluster_members - centroid.values, axis=1)
      radius = distances.max()
      count = len(cluster_members)
      return int(radius), count, (1000 ** 2) * count / (radius ** 2)

    clusters_details = [compute_details(label, centroid) for label, centroid in self.__clusters.iterrows()]
    self.__clusters['radius'], self.__clusters['count'], self.__clusters['density'] = list(zip(*clusters_details))
    return self.__clusters
