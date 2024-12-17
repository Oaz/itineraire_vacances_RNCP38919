import fireducks.pandas as pd
import json
import dt_utils.json_helper_functions as helper
import dotenv
import os
from sqlalchemy import create_engine, inspect, Engine

# Chargement des variables d'environnement
dotenv.load_dotenv()


def connect_to_db() -> Engine:
    """
    Connexion à la BDD
    :return: engine : moteur de connexion à la BDD
    """
    engine = create_engine(f"postgresql://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@{os.getenv('POSTGRES_HOST')}:{os.getenv('POSTGRES_PORT')}/{os.getenv('POSTGRES_DB')}")
    return engine


def show_tables(engine: create_engine) -> list:
    """
    Permet d'interroger la BDD pour obtenir la liste des tables à fin de tests
    :param engine:
    :return: tables : liste des tables présentes dans la BDD
    """
    db_inspection = inspect(engine)
    tables = db_inspection.get_table_names()
    return tables

def save_dataframe_to_postgres(df: pd.DataFrame, table_name: str, engine: create_engine, if_exists: str='replace'):
    """
    Sauvegarde un DataFrame pandas dans une table PostgreSQL.

    ATTENTION : Le Dataframe doit être formaté avec le même nombre et noms de colonnes

    :param df: pd.DataFrame - Le DataFrame à sauvegarder
    :param table_name: str - Le nom de la table dans laquelle sauvegarder le DataFrame
    :param engine:
    :param if_exists: str - L'action si la table existe {"fail", "replace", "append"}(default: "replace")
    """
    df.to_sql(table_name, engine, if_exists=if_exists, index=False)

def parse_index_datatourisme(index_path:str = "./data/index.json") -> list:
    """
    Parse le fichier index.json pour récupérer les URL des fichiers JSON.

    :param index_path:str - Le chemin du fichier d'index (default: "../data/index.json")
    :return: list - La liste des URL des fichiers JSON
    """
    with open(index_path, "r", encoding="utf-8") as file:
        data = json.load(file)

    urls = []
    for item in data:
        urls.append("data/objects/"+item["file"])
    return urls

def collect_region_information_from_files(urls: list) -> pd.DataFrame:
    """
    Collecte les informations des points d'intérêt à partir des fichiers JSON.

    :param urls: list - La liste des URL des fichiers JSON
    :return: pd.DataFrame - Le DataFrame contenant les informations des points d'intérêt
    """
    data = []
    for url in urls:
        poi_region_id, poi_region_name = helper.get_poi_region(url)
        data.append([poi_region_id, poi_region_name])
    # On crée un dataframe pour stocker les résultats
    region_df = pd.DataFrame(data, columns=["dt_region_id", "name"])
    return region_df

def collect_department_information_from_files(urls: list) -> pd.DataFrame:
    """
    Collecte les informations concernant les département des points d'intérêt à partir des fichiers JSON.

    :param urls: list - La liste des URL des fichiers JSON
    :return: pd.DataFrame - Le DataFrame contenant les informations des points d'intérêt
    """
    data = []
    for url in urls:
        poi_departement_id, poi_departement_name = helper.get_poi_department(url)
        poi_region_id, poi_region_name = helper.get_poi_region(url)
        data.append([poi_departement_id, poi_region_id, poi_departement_name])
    # On crée un dataframe pour stocker les résultats
    department_df = pd.DataFrame(data, columns=["dt_departement_id", "dt_region_id", "name"])

    return department_df

def collect_city_information_from_files(urls: list) -> pd.DataFrame:
    """
    Collecte les informations des points d'intérêt à partir des fichiers JSON.

    :param urls: list - La liste des URL des fichiers JSON
    :return: pd.DataFrame - Le DataFrame contenant les informations des points d'intérêt
    """
    data = []
    for url in urls:
        # Récuperation de l'ID de la ville et de son nom
        poi_city_id, poi_city_name = helper.get_poi_city(url)
        # Récupération du département de la ville
        poi_departement_id, poi_department_name = helper.get_poi_department(url)
        data.append([poi_city_id, poi_departement_id, poi_city_name])
    # On crée un dataframe pour stocker les résultats
    city_df = pd.DataFrame(data, columns=["dt_city_id","dt_departement_id","name"])
    # Et on supprime les doublons
    city_df = city_df.drop_duplicates()
    return city_df

def collect_all_categories(urls: list) -> pd.DataFrame:
    """
    Remplissage de la table Category à partir du fichier ontology.TTL
    :param urls: list - La liste des URL des fichiers JSON
    :return: pd.DataFrame - Le DataFrame contenant la liste des catégories à insérer dans la table Category
    """
    # On récupère les catégories de POI et on les ajoute à un set
    # pour s'assurer de leur unicité
    # Si on récupère une liste, on l'eclate et on ajoute chaque élément un à un dans le set

    categories = set()
    for url in urls:
        poi_category = helper.get_poi_category(url)
        if isinstance(poi_category, list):
            for category in poi_category:
                categories.add(category)
        else:
            categories.add(poi_category)

    # Transformation du set en DataFrame
    category_df = pd.DataFrame(categories, columns=["name"])
    return category_df