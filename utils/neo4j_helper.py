from typing import Tuple, Dict
import os
import re
import neo4j as neo4j
import pandas as pd


def connect_to_neo4j() -> neo4j.Driver:
  """
  Connexion à Neo4j
  :return: driver : driver de connexion à Neo4j
  """
  return neo4j.GraphDatabase.driver(
    os.environ['NEO4J_URL'],
    auth=(os.environ['NEO4J_USER'], os.environ['NEO4J_PASSWORD'])
  )


def import_pois(driver: neo4j.Driver, df: pd.DataFrame):
  '''
  Importe un DataFrame de POIS dans neo4j
  Si le POI n'existe pas, il est créé. S'il existe déjà avec le même identifiant, il est modifié.

  :param driver:
  :param df: Le DataFrame à importer
  :return:
  '''
  pois = df.to_dict(orient="records")
  with driver.session() as session:
    session.run("CREATE INDEX IF NOT EXISTS FOR (poi:POI) ON (poi.id)")
    session.run("""
            UNWIND $pois AS poi
            MERGE (p:POI {id: poi.id})
            SET p = poi
        """, pois=pois)


def sanitize(text: str) -> str:
  """
  Sanitize to prevent injection.
  """
  if re.match(r"^[A-Za-z0-9_]+$", text):
    return text
  raise ValueError("Invalid text: must be alphanumeric and underscores only.")


def import_clusters(driver: neo4j.Driver, category: str, df_clusters: pd.DataFrame, df_vicinities: pd.DataFrame):
  """
  Importe un DataFrame de clusters dans neo4j et connecte chaque cluster à ses POIs
  Tous les clusters de la catégorie concernée sont effacés avant l'import.

  :param driver:
  :param category: La catégorie associé à tous les clusters importés
  :param df_clusters: Le dataframe des clusters
  :param df_vicinities: Les rattachements cluster-POI
  :return:
  """
  category = sanitize(category)
  clusters = [
    {
      "id": index, "x": row["x"], "y": row["y"], "category": category,
      "radius": row["radius"], "count": row["count"], "density": row["density"]
    }
    for index, row in df_clusters.iterrows()
  ]
  vicinities = df_vicinities.to_dict(orient="records")
  with driver.session() as session:
    session.run("CREATE INDEX IF NOT EXISTS FOR (cluster:Cluster) ON (cluster.category)")
    session.run("MATCH (cluster:Cluster {category: $category}) DETACH DELETE cluster", category=category)
    session.run("UNWIND $clusters AS cluster CREATE (c:Cluster) SET c = cluster", clusters=clusters)
    session.run("""
        UNWIND $vicinities AS v
        MATCH (c:Cluster {id: v.cluster}), (p:POI {id: v.id})
        CREATE (c)-[:VICINITY]->(p)
    """, vicinities=vicinities)


def import_routes(driver: neo4j.Driver, routes: Dict[Tuple[int, int], int]):
  """
  Importe des routes entre les clusters
  :param driver:
  :param routes: dictionnaire des distances pour chaque route entre 2 clusters
  :return:
  """
  with driver.session() as session:
    session.run("""
        UNWIND $routes AS r
        MATCH (c1:Cluster {id: r.a}), (c2:Cluster {id: r.b})
        CREATE (c1)-[:ROUTE {distance: r.distance}]->(c2)
        CREATE (c2)-[:ROUTE {distance: r.distance}]->(c1)
    """, routes=[{"a": a, "b": b, "distance": distance} for ((a, b), distance) in routes.items()])
