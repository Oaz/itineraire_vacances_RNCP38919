import pandas as pd
import numpy as np
from scipy.spatial.distance import pdist, squareform
from scipy.sparse.csgraph import minimum_spanning_tree


class GeoRouting:
  def __init__(self, nodes: pd.DataFrame, x_column: str = "x", y_column: str = "y"):
    """
    Initialise un geo-routing en calculant les arêtes formant un arbre couvrant minimal selon la distance euclienne
    :param nodes: pd.DataFrame - Les noeuds à relier
    :param x_column: str - nom de la colonne des x dans le dataframe
    :param y_column: str - nom de la colonne des y dans le dataframe
    """
    self.count = len(nodes)
    distances = pdist(nodes[[x_column, y_column]], metric='euclidean')
    self.dist_matrix = squareform(distances)
    mst = minimum_spanning_tree(self.dist_matrix)
    edges = np.transpose(mst.nonzero())
    self.edges = {(int(a) + 1, int(b) + 1): int(self.dist_matrix[a, b]) for a, b in edges}

  def increase(self, threshold_in_meters: int):
    """
    Rajoute des arêtes entre les paires de noeuds dont la distance est inférieure au seuil
    :param threshold_in_meters: seuil en mètres
    :return:
    """
    for i in range(self.count):
      for j in range(i + 1, self.count):
        if self.dist_matrix[i, j] <= threshold_in_meters and (i, j) not in self.edges:
          self.edges[(i + 1, j + 1)] = int(self.dist_matrix[i, j])
