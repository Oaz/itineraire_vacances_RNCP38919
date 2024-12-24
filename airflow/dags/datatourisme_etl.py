import datetime
import logging
import os

import psycopg2
from airflow import DAG
from airflow.exceptions import AirflowException
from airflow.models import Variable
from airflow.operators.dummy import DummyOperator
from airflow.operators.python import PythonOperator, BranchPythonOperator

# Récupération du répertoire courant dans le conteneur Docker
CUR_DIR = os.path.abspath(os.path.dirname(__file__))

# TODO : Créer un Dockerfile pour le projet (copier les fichiers nécessaires : utils, sql, ...)
# TODO : Voir pour passer les variables Airflow en variables d'environnement dans le Dockerfile


# Récupération des variables Airflow

POSTGRES_HOST = Variable.get("POSTGRES_HOST")
POSTGRES_PORT = Variable.get("POSTGRES_PORT")
POSTGRES_USER = Variable.get("POSTGRES_USER")
POSTGRES_PASSWORD = Variable.get("POSTGRES_PASSWORD")
POSTGRES_DATATOURISME_DB = Variable.get("POSTGRES_DATATOURISME_DB")
POSTGRES_DB = Variable.get("POSTGRES_DB")


def check_postgres_service(host=POSTGRES_HOST, port=POSTGRES_PORT, user=POSTGRES_USER, password=POSTGRES_PASSWORD,
                           dbname=POSTGRES_DB, **kwargs) -> None:
    """
    Vérifie si le service PostgreSQL est accessible
    :param host:
    :param port:
    :param user:
    :param password:
    :param dbname:
    :param kwargs:
    :return: None
    Pousse une valeur XCom dans Airflow pour indiquer si le service est accessible ou non
    """
    try:
        connection = psycopg2.connect(
            host=host, port=port, user=user, password=password, dbname=dbname
        )
        connection.close()
        kwargs["ti"].xcom_push(key="postgres_service_status", value=True)

    except AirflowException as e:
        logging.error(f"Error connecting to PostgreSQL: {e}")
        kwargs["ti"].xcom_push(key="postgres_service_status", value=False)


def check_database(host=POSTGRES_HOST, port=POSTGRES_PORT, user=POSTGRES_USER, password=POSTGRES_PASSWORD,
                   dbname=POSTGRES_DATATOURISME_DB, **kwargs) -> None:
    """
    Vérifie si la base de données DataTourisme existe
    :param host:
    :param port:
    :param user:
    :param password:
    :param dbname:
    :param kwargs:
    :return: None
    Pousse une valeur XCom dans Airflow pour indiquer si la base de données est créée ou non
    """
    try:
        connection = psycopg2.connect(
            host=host, port=port, user=user, password=password, dbname="postgres"
        )
        connection.autocommit = True
        cursor = connection.cursor()
        cursor.execute(f"SELECT 1 FROM pg_database WHERE datname = '{dbname}'")
        exists = cursor.fetchone()
        if not exists:
            kwargs["ti"].xcom_push(key="database_created", value=False)
        else:
            kwargs["ti"].xcom_push(key="database_created", value=True)
        cursor.close()
        connection.close()
    except AirflowException as e:
        logging.error(f"Error checking/creating database: {e}")
        kwargs["ti"].xcom_push(key="database_created", value=False)


def should_create_database(**kwargs):
    """
    Détermine si la base de données doit être créée
    :param kwargs:
    :return: str
    """
    database_created = kwargs["ti"].xcom_pull(key="database_created")
    if not database_created:
        return "create_database_datatourisme"
    else:
        return "check_tables"


def create_database_datatourisme(host=POSTGRES_HOST, port=POSTGRES_PORT, user=POSTGRES_USER, password=POSTGRES_PASSWORD,
                                 **kwargs):
    """
    Crée la base de données DataTourisme
    :param host:
    :param port:
    :param user:
    :param password:
    :param dbname:
    :param kwargs:
    :return:

    En fonction de la valeur de Xcom['database_created'], on créé ou non la base de données

    """

    database_created = kwargs["ti"].xcom_pull(key="database_created")
    if not database_created:

        try:
            connection = psycopg2.connect(
                host=host, port=port, user=user, password=password, dbname="postgres"
            )
            connection.autocommit = True
            cursor = connection.cursor()
            cursor.execute(f"CREATE DATABASE {POSTGRES_DATATOURISME_DB}")
            cursor.close()
            connection.close()
            logging.info("Base de données créée avec succès ! On va vérifier les tables")
        except AirflowException as e:
            logging.error(f"Error creating database: {e}")
    else:
        logging.info("Base de données déjà créée, on va vérifier les tables")


def check_tables(host=POSTGRES_HOST, port=POSTGRES_PORT, user=POSTGRES_USER, password=POSTGRES_PASSWORD,
                 dbname=POSTGRES_DATATOURISME_DB, **kwargs):
    """
    Vérifie si les tables nécessaires sont créées
    :param host:
    :param port:
    :param user:
    :param password:
    :param dbname:
    :param kwargs:
    :return: None
    Pousse une valeur XCom dans Airflow pour indiquer si les tables sont créées ou non
    """
    try:
        connection = psycopg2.connect(
            host=host, port=port, user=user, password=password, dbname=dbname
        )
        connection.autocommit = True
        cursor = connection.cursor()

        # Liste des tables de la base de données
        tables = ["point_of_interest", "category_point_of_interest", "category", "city", "departement", "region"]

        # Vérification de l'existence de chaque table
        counter = 0
        for table in tables:
            cursor.execute(f"SELECT 1 FROM information_schema.tables WHERE table_name = '{table}'")
            exists = cursor.fetchone()
            if exists:
                counter += 1

        kwargs["ti"].xcom_push(key="tables", value=counter)
    except AirflowException as e:
        logging.error(f"Erreur dans la vérification des tables: {e}")
        kwargs["ti"].xcom_push(key="tables", value=0)


def should_create_tables(**kwargs):
    """
    Détermine si les tables doivent être créées
    :param kwargs:
    :return: str
    """
    tables = kwargs["ti"].xcom_pull(key="tables")
    if tables != 5:
        return "create_tables"
    else:
        return "null_task"


def create_tables(**kwargs):
    """
    Détermine si les tables doivent être créées
    :param kwargs:
    :return: str
    """
    try:
        connection = psycopg2.connect(
            host=POSTGRES_HOST, port=POSTGRES_PORT, user=POSTGRES_USER, password=POSTGRES_PASSWORD,
            dbname=POSTGRES_DATATOURISME_DB
        )
        connection.autocommit = True
        cursor = connection.cursor()

        # Recupération du nombre de tables créées
        tables = kwargs["ti"].xcom_pull(key="tables")
        if tables != 5 and tables != 0:
            # Il y a inconsistance dans les tables, on les recrée toutes
            # Liste des tables présentes en théorie dans la base de données
            tables = ["point_of_interest", "category_point_of_interest", "category", "city", "departement", "region"]
            for table in tables:
                cursor.execute(f"DROP TABLE IF EXISTS {table} CASCADE")
            logging.info("Tables supprimées avec succès ! On va recréer le schéma")

        # Chargement du script de création des tables
        with open(f"{CUR_DIR}/sql/create_tables.sql", "r") as file:
            logging.info("Chargement et execution du script de création des tables")
            cursor.execute(file.read())

        logging.info("Tables créées avec succès !")


    except AirflowException as e:
        logging.error(f"Erreur dans la vérification des tables: {e}")

def count_poi_in_db(**kwargs):
    """
    Compte le nombre de points d'intérêt dans la base de données renvoie la branche suivante à executer
    :return: None
    """
    try:
        connection = psycopg2.connect(
            host=POSTGRES_HOST, port=POSTGRES_PORT, user=POSTGRES_USER, password=POSTGRES_PASSWORD,
            dbname=POSTGRES_DATATOURISME_DB
        )
        connection.autocommit = True
        cursor = connection.cursor()
        cursor.execute("SELECT COUNT(*) FROM point_of_interest")
        count = cursor.fetchone()[0]
        cursor.close()
        connection.close()
        if count != 0:
            logging.info(f"Nombre de points d'intérêt dans la base de données: {count}")
            logging.info("On va mettre à jour les données avec les nouvelles données de datatourisme")
            return "update_task"
        else:
            logging.info("Aucun point d'intérêt dans la base de données, on va lancer l'import initial")
            return "initial_ingestion_task"
    except AirflowException as e:
        logging.error(f"Erreur dans le comptage des points d'intérêt: {e}")


# Création du DAG

with DAG(
        "datatourisme_etl",
        description="Collecte des données DataTourisme et chargement dans une base de données PostgreSQL",
        schedule_interval=None,
        start_date=datetime.datetime(2024, 12, 8),
        catchup=False,
) as dag:
    check_postgres_up = PythonOperator(
        task_id="check_postgres_service",
        python_callable=check_postgres_service,
        op_args=[POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB],
        dag=dag
    )

    check_database = PythonOperator(
        task_id="check_database",
        python_callable=check_database,
        op_args=[POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DATATOURISME_DB],
        dag=dag
    )

    should_create_database = BranchPythonOperator(
        task_id="should_create_database",
        python_callable=should_create_database,
        provide_context=True,
        dag=dag
    )

    create_database = PythonOperator(
        task_id="create_database_datatourisme",
        python_callable=create_database_datatourisme,
        op_args=[POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD],
        provide_context=True,
        dag=dag
    )

    check_tables = PythonOperator(
        task_id="check_tables",
        python_callable=check_tables,
        op_args=[POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DATATOURISME_DB],
        trigger_rule="all_done",
        dag=dag
    )

    should_create_tables = BranchPythonOperator(
        task_id="should_create_tables",
        python_callable=should_create_tables,
        provide_context=True,
        dag=dag
    )

    create_tables = PythonOperator(
        task_id="create_tables",
        python_callable=create_tables,
        provide_context=True,
        dag=dag
    )

    count_poi_in_db = BranchPythonOperator(
        task_id="count_poi_in_db",
        python_callable=count_poi_in_db,
        provide_context=True,
        dag=dag
    )

    update_task = DummyOperator(task_id="update_task", dag=dag)
    initial_ingestion_task = DummyOperator(task_id="initial_ingestion_task", dag=dag)

    # Définition du DAG
    check_postgres_up >> check_database >> should_create_database
    should_create_database >> [create_database, check_tables]
    create_database >> check_tables
    check_tables >> should_create_tables
    should_create_tables >> [create_tables, count_poi_in_db]
    create_tables >> count_poi_in_db
    count_poi_in_db >> [update_task, initial_ingestion_task]
