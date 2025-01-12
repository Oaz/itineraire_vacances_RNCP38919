from fastapi import FastAPI
import psycopg2

def get_connection():
    return psycopg2.connect(
        host="postgres",
        database="datatourisme",
        user="airflow",
        password="airflow",
        port="5432")



app = FastAPI(title="API Itinéraire de vacances", description="API pour le calcul d'un itinéraire entre POI selon une catégorie et une localisation donnée", version="1.0.0")


@app.get("/db_health")
def db_service_health():
    try:
        conn = get_connection()
        return {"message": "PostgreSQL is UP", "code": 200}
    except(Exception, psycopg2.Error) as error:
        return {"status": error, "code": 500}

@app.get("/count_poi")
def count_point_of_interest():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM point_of_interest")
    record = cursor.fetchone()
    conn.close()
    return {"count": record[0], "code": 200}
