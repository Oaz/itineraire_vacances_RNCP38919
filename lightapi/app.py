import pickle
from typing import List
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from pathlib import Path
import mysql.connector
import os
import uvicorn
from contextlib import contextmanager
from graphs import  load_categories

categories = load_categories()

@contextmanager
def connect_to_db_from_env():
  conn = mysql.connector.connect(
    host=os.environ.get('DB_HOST', 'localhost'),
    user=os.environ.get('DB_USER', 'azeau_itineraire_vacances'),
    password=os.environ.get('DB_PASSWORD', ''),
    database=os.environ.get('DB_NAME', 'azeau_itineraire_vacances_RNCP38919'),
    port=int(os.environ.get('DB_PORT', '3306'))
  )
  try:
    yield conn
  finally:
    conn.close()

app = FastAPI(
  title="API Itinéraire de vacances",
  description="API pour le calcul d'un itinéraire entre POI selon une catégorie et une localisation donnée",
  version="1.0.0"
)

@app.get("/")
def read_root():
  return {"message": "API Itineraire de Vacances", "code": "200"}

demo_dir = Path(__file__).parent / "demo"
app.mount("/demo", StaticFiles(directory=demo_dir, html=True), name="demo")

@app.get("/db_health")
def db_service_health():
  try:
    conn = connect_to_db_from_env()
    return {"message": "MySQL is UP", "code": 200}
  except(Exception, mysql.connector.Error) as error:
    return {"status": error, "code": 500}



@app.get("/count_poi")
def count_point_of_interest():
  conn = connect_to_db_from_env()
  cursor = conn.cursor()
  cursor.execute("SELECT COUNT(*) FROM point_of_interest")
  record = cursor.fetchone()
  conn.close()
  return {"count": record[0], "code": 200}


@app.get(
  "/clustered_categories",
  summary="List Categories with Associated Clusters",
  description="This endpoint returns a list of categories with their associated clusters and route counts."
)
def list_categories_with_associated_clusters():
  """
  Returns a list of categories with their associated clusters and route counts.
  - **category**: The category name.
  - **clusterCount**: The number of clusters associated with the category.
  - **routeCount**: The number of routes associated with the category.
  """
  return [categories[name].data() for name in categories]

class RouteRequest(BaseModel):
  start_poi_id: str
  end_poi_id: str
  category: str


@app.post(
  "/route",
  response_model=List[List[str]],
  summary="Get Route Between Points of Interest",
  description="This endpoint calculates and returns a route between two points of interest based on a given category.")
async def get_route(request: RouteRequest):
  """
  Calculates and returns a route between two points of interest (POI) based on a given category.
  - **start_poi_id**: The ID of the starting POI.
  - **end_poi_id**: The ID of the destination POI.
  - **category**: The category of the POIs.
  - **response**: A list of routes, where each route is a list of POI IDs.
  """
  return categories[request.category].graph().route(request.start_poi_id, request.end_poi_id)

class FindCityRequest(BaseModel):
  category: str
  query: str


@app.post("/find_cities")
async def find_cities(request: FindCityRequest):
  with connect_to_db_from_env() as conn:
    cursor = conn.cursor()
    cursor.execute("""
    SELECT DISTINCT city.name FROM point_of_interest AS poi
    LEFT JOIN category_point_of_interest cpoi on poi.dt_poi_id = cpoi.dt_poi_id
    LEFT JOIN category on cpoi.dt_category_id = category.dt_category_id
    LEFT JOIN city on poi.dt_city_id = city.dt_city_id
    WHERE city.name LIKE %s and category.name=%s
""", (f'{request.query}%', request.category))
    return [city for row in cursor.fetchall() for city in row]



class FindPoiRequest(BaseModel):
  city: str
  category: str


@app.post("/find_poi")
async def find_poi(request: FindPoiRequest):
  with connect_to_db_from_env() as conn:
    cursor = conn.cursor()
    cursor.execute("""
    SELECT poi.* FROM point_of_interest AS poi
    LEFT JOIN category_point_of_interest cpoi on poi.dt_poi_id = cpoi.dt_poi_id
    LEFT JOIN category on cpoi.dt_category_id = category.dt_category_id
    LEFT JOIN city on poi.dt_city_id = city.dt_city_id
    WHERE city.name=%s and category.name=%s
""", (request.city, request.category))
    record = cursor.fetchone()
    return record[0]



@app.get("/poi")
async def get_poi(id: str):
  with connect_to_db_from_env() as conn:
    cursor = conn.cursor()
    cursor.execute("""
    SELECT poi.dt_poi_id, poi.name, poi.postal_code, city.name, poi.latitude, poi.longitude FROM point_of_interest AS poi
    LEFT JOIN city on poi.dt_city_id = city.dt_city_id
    WHERE poi.dt_poi_id = %s
""", (id,))
    record = cursor.fetchone()
    if not record:
      raise HTTPException(status_code=404, detail="POI not found")
    return {
      "id": record[0],
      "name": record[1],
      "postal_code": record[2],
      "city": record[3],
      "latitude": record[4],
      "longitude": record[5]
    }

if __name__ == "__main__":
  uvicorn.run("app:app", host="0.0.0.0", port=5000, reload=True)
