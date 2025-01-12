from fastapi import FastAPI
from utils import connect_to_db_from_env, connect_to_neo4j
import psycopg2

app = FastAPI(
  title="API Itinéraire de vacances",
  description="API pour le calcul d'un itinéraire entre POI selon une catégorie et une localisation donnée",
  version="1.0.0"
)


@app.get("/db_health")
def db_service_health():
  try:
    conn = connect_to_db_from_env()
    return {"message": "PostgreSQL is UP", "code": 200}
  except(Exception, psycopg2.Error) as error:
    return {"status": error, "code": 500}


@app.get("/count_poi")
def count_point_of_interest():
  conn = connect_to_db_from_env()
  cursor = conn.cursor()
  cursor.execute("SELECT COUNT(*) FROM point_of_interest")
  record = cursor.fetchone()
  conn.close()
  return {"count": record[0], "code": 200}


@app.get("/clustered_categories")
def list_categories_with_associated_clusters():
  with connect_to_neo4j() as driver:
    with driver.session() as session:
      result = session.run('''
        MATCH (c:Cluster)
        WITH c.category AS category, COUNT(c) AS clusterCount
        MATCH (c)-[r:ROUTE]->(c2)
        WHERE c.category = c2.category AND c.category = category
        RETURN category, clusterCount, COUNT(r) AS routeCount
        ''')
      categories = [(r['category'], r['clusterCount'], r['routeCount']) for r in result]
      return [
        {'category': category, 'clusterCount': clusterCount, 'routeCount': routeCount}
        for category, clusterCount, routeCount in sorted(categories)
      ]
