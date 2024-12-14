import os
import unittest
import pandas as pd
from testcontainers.neo4j import Neo4jContainer
import dt_utils.neo4j_helper as nh


class TestNeo4jIntegration(unittest.TestCase):
  @classmethod
  def setUpClass(cls):
    user = "neo4j"
    password = "password"
    cls.neo4j_container = Neo4jContainer("neo4j:5")
    cls.neo4j_container.with_env("NEO4J_AUTH", f"{user}/{password}")
    cls.neo4j_container.start()
    print(cls.neo4j_container.get_connection_url())
    os.environ["NEO4J_URL"] = cls.neo4j_container.get_connection_url()
    os.environ["NEO4J_USER"] = user
    os.environ["NEO4J_PASSWORD"] = password
    cls.driver = nh.connect_to_neo4j()

  @classmethod
  def tearDownClass(cls):
    cls.driver.close()
    cls.neo4j_container.stop()

  def test_neo4j_connection(self):
    with self.driver.session() as session:
      session.run("CREATE (a:Greeting {message: 'Hello, World'}) RETURN a")
      result = session.run("MATCH (a:Greeting) RETURN a.message AS message")
      record = result.single()
      self.assertEqual(record["message"], "Hello, World")

  def test_import_pois_from_dataframe(self):
    self.util_import_pois()
    with self.driver.session() as session:
      self.assertEqual(
        {'id': 'ABC', 'name': 'Lorem ipsum', 'x': 1000, 'y': 666},
        session.run("MATCH (poi:POI) WHERE poi.id='ABC' RETURN poi").single().data()['poi']
      )
      self.assertEqual(
        {'id': 'GHI', 'name': 'doctus eripuit probatus', 'x': 3000, 'y': 888},
        session.run("MATCH (poi:POI) WHERE poi.id='GHI' RETURN poi").single().data()['poi']
      )

  def test_update_pois_from_dataframe(self):
    self.util_import_pois()
    nh.import_pois(self.driver, pd.DataFrame({
      'id': ['DEF', 'GHI'],
      'name': ['Hello', 'World'],
      'x': [5000, 3000],
      'y': [777, 888],
    }))
    with self.driver.session() as session:
      self.assertEqual(
        {'id': 'ABC', 'name': 'Lorem ipsum', 'x': 1000, 'y': 666},
        session.run("MATCH (poi:POI) WHERE poi.id='ABC' RETURN poi").single().data()['poi']
      )
      self.assertEqual(
        {'id': 'DEF', 'name': 'Hello', 'x': 5000, 'y': 777},
        session.run("MATCH (poi:POI) WHERE poi.id='DEF' RETURN poi").single().data()['poi']
      )
      self.assertEqual(
        {'id': 'GHI', 'name': 'World', 'x': 3000, 'y': 888},
        session.run("MATCH (poi:POI) WHERE poi.id='GHI' RETURN poi").single().data()['poi']
      )

  def test_import_clusters_from_dataframe(self):
    self.util_import_pois()
    self.util_import_clusters()
    with self.driver.session() as session:
      self.assertEqual([
        {
          'id': 0, 'x': 1000, 'y': 666, 'category': 'Culture',
          'radius': 5666, 'count': 6, 'density': 2,
        }, {
          'id': 1, 'x': 2000, 'y': 777, 'category': 'Culture',
          'radius': 9777, 'count': 17, 'density': 5,
        }
      ], [
        record.data()['c'] for record
        in session.run("MATCH (c:Cluster) WHERE c.category='Culture' RETURN c ORDER BY c.id").fetch(2)
      ])
      self.assertEqual([
        {'id': 'ABC', 'name': 'Lorem ipsum', 'x': 1000, 'y': 666},
        {'id': 'GHI', 'name': 'doctus eripuit probatus', 'x': 3000, 'y': 888}
      ], [
        record.data()['p'] for record
        in session.run("MATCH (c:Cluster)-[v:VICINITY]-(p:POI) WHERE c.id=1 RETURN p ORDER BY p.id").fetch(2)
      ])

  def test_import_routes(self):
    self.util_import_pois()
    self.util_import_clusters()
    nh.import_routes(
      self.driver, {
        (0, 1): 954
      }
    )
    with self.driver.session() as session:
      self.assertEqual([{'c.id': 0, 'r.distance': 954}, {'c.id': 1, 'r.distance': 954}], [
        record.data() for record
        in session.run("MATCH (c:Cluster)-[r:ROUTE]->(:Cluster) RETURN c.id, r.distance ORDER BY c.id").fetch(5)
      ])

  def util_import_pois(self):
    nh.import_pois(self.driver, pd.DataFrame({
      'id': ['ABC', 'DEF', 'GHI'],
      'name': ['Lorem ipsum', 'dolor sit amet', 'doctus eripuit probatus'],
      'x': [1000, 2000, 3000],
      'y': [666, 777, 888],
    }))

  def util_import_clusters(self):
    nh.import_clusters(
      self.driver, "Culture",
      pd.DataFrame(index=[0, 1], data={
        'x': [1000, 2000],
        'y': [666, 777],
        'radius': [5666, 9777],
        'count': [6, 17],
        'density': [2, 5],
      }), pd.DataFrame({
        'id': ['ABC', 'DEF', 'GHI'],
        'cluster': [1, 0, 1],
      })
    )


if __name__ == "__main__":
  unittest.main()
