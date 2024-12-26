import shutil
import dotenv
import os
import requests
import zipfile
import kagglehub


def check_file_exists(directory: str, filename: str) -> bool:
    file_path = os.path.join(directory, filename)
    return os.path.isfile(file_path)


def download_datatourisme_archive() -> bool:
    # Récupération des variables d'environnement définit dans le fichier .env
    dotenv.load_dotenv()
    # Répertoire de stockage de l'archive ZIP brute
    download_path = "./raw_archive"
    os.makedirs(download_path, exist_ok=True)
    file_path = os.path.join(download_path, "archive.zip")

    # Téléchargement du fichier ZIP depuis datatourisme
    url = os.getenv("DATATOURISME_URL_FLUX") + os.getenv("DATATOURISME_API_KEY")

    if not check_file_exists("./raw_archive", "archive.zip"):

        try:
            response = requests.get(url, stream=True)
            response.raise_for_status()  # Renvoi une exception si le code de statut de la réponse HTTP n'est pas 200

            # Sauvegarde du fichier ZIP
            with open(file_path, "wb") as file:
                for chunk in response.iter_content(chunk_size=8192):
                    file.write(chunk)

            return True
        except requests.exceptions.RequestException as e:
            return False
    else:
        pass


def extract_data() -> bool:
    try:
        with zipfile.ZipFile("./raw_archive/archive.zip", "r") as zip_ref:
            zip_ref.extractall("./data")
            # Destruction de l'archive téléchargée
            shutil.rmtree("./raw_archive")
        return True
    except zipfile.BadZipFile:
        return False

def download_datatourisme_categories() -> bool:
    """
    Permet de télécharger le fichier ontology.TTL de datatourisme
    """
    # Répertoire de stockage temporaire du fichier ontology.TTL
    download_path = "./temporary_categories"
    os.makedirs(download_path, exist_ok=True)
    file_path = os.path.join(download_path, "ontology.TTL")

    # Téléchargement du fichier ontology.TTL depuis datatourisme
    url = "https://www.datatourisme.fr/ontology/core/ontology.ttl"

    if not check_file_exists("../temporary_categories", "ontology.TTL"):

        try:
            response = requests.get(url, stream=True)
            response.raise_for_status()  # Renvoi une exception si le code de statut de la réponse HTTP n'est pas 200

            # Sauvegarde du fichier ontology.TTL
            with open(file_path, "wb") as file:
                for chunk in response.iter_content(chunk_size=8192):
                    file.write(chunk)

            return True
        except requests.exceptions.RequestException as e:
            return False
    else:
        pass

def download_and_get_shapefile() -> str:
    """
    Télécharge les données géographiques (Shapefile) via KaggleHub.

    :return
        str : Chemin vers le fichier Shapefile.
    """
    print("Téléchargement des données géographiques...")
    path = kagglehub.dataset_download("abdulkerimnee/ne-110m-admin-0-countries")
    path_to_delete = path
    shp_path = os.path.join(path, "ne_110m_admin_0_countries", "ne_110m_admin_0_countries.shp")

    if not os.path.exists(shp_path):
        raise FileNotFoundError(f"Fichier Shapefile non trouvé : {shp_path}")
    return shp_path, path_to_delete

def cleanup_downloaded_data(path: str) -> None:
    """
    Supprime les fichiers temporaires.

    :param
        path (str): Chemin du répertoire à supprimer.
    """
    print("Nettoyage des fichiers temporaires...")
    if os.path.exists(path):
        shutil.rmtree(path)
        print(f"Supprimé : {path}")