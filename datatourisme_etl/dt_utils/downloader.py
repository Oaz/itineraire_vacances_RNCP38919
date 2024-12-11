import shutil
import dotenv
import os
import requests
import zipfile


def check_file_exists(directory: str, filename: str) -> bool:
    file_path = os.path.join(directory, filename)
    return os.path.isfile(file_path)


def download_datatourisme_archive() -> bool:
    # Récupération des variables d'environnement définit dans le fichier .env
    dotenv.load_dotenv()
    # Répertoire de stockage de l'archive ZIP brute
    download_path = "../raw_archive"
    os.makedirs(download_path, exist_ok=True)
    file_path = os.path.join(download_path, "archive.zip")

    # Téléchargement du fichier ZIP depuis datatourisme
    url = os.getenv("DATATOURISME_URL_FLUX") + os.getenv("DATATOURISME_API_KEY")

    if not check_file_exists("../raw_archive", "archive.zip"):

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


def extract_data():
    try:
        with zipfile.ZipFile("../raw_archive/archive.zip", "r") as zip_ref:
            zip_ref.extractall("../data")
            # Destruction de l'archive téléchargée
            shutil.rmtree("../raw_archive")
        return True
    except zipfile.BadZipFile:
        return False

def download_datatourisme_categories() -> bool:
    """
    Permet de télécharger le fichier ontology.TTL de datatourisme
    """
    # Répertoire de stockage temporaire du fichier ontology.TTL
    download_path = "../temporary_categories"
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

if __name__ == "__main__":
    # Pour tester le script en appel direct
    # Affiche True si le téléchargement s'est bien passé, False sinon
    if download_datatourisme_archive():
        extract_data()
