from dt_utils import get_poi_coordinates, download_datatourisme_archive, extract_data
import os
import shutil
import geopandas as gpd
import kagglehub
from shapely.geometry import Point


class POI:
    """
    Classe représentant un Point d'Intérêt (POI).

    Attributs :
        file_path (str): Chemin du fichier JSON contenant les informations du POI.
        latitude (float): Latitude du POI.
        longitude (float): Longitude du POI.
    """
    def __init__(self, file_path: str, latitude: float, longitude: float):
        self.file_path = file_path
        self.latitude = latitude
        self.longitude = longitude

    def to_point(self) -> Point:
        """
        Convertit les coordonnées en un objet Point Shapely.

        Retourne :
            Point : Objet Shapely Point.
        """
        return Point(self.longitude, self.latitude)

    def __repr__(self) -> str:
        return f"POI(file_path={self.file_path}, latitude={self.latitude}, longitude={self.longitude})"


def download_and_get_shapefile() -> str:
    """
    Télécharge les données géographiques (Shapefile) via KaggleHub.

    Retourne :
        str : Chemin vers le fichier Shapefile.
    """
    print("Téléchargement des données géographiques...")
    path = kagglehub.dataset_download("abdulkerimnee/ne-110m-admin-0-countries")
    shp_path = os.path.join(path, "ne_110m_admin_0_countries", "ne_110m_admin_0_countries.shp")

    if not os.path.exists(shp_path):
        raise FileNotFoundError(f"Fichier Shapefile non trouvé : {shp_path}")
    return shp_path


def get_france_geometry(shp_path: str) -> gpd.GeoDataFrame:
    """
    Charge les données géographiques et extrait la géométrie de la France.

    Args:
        shp_path (str): Chemin vers le fichier Shapefile.

    Retourne :
        gpd.GeoDataFrame : Géométrie de la France.
    """
    print("Lecture du fichier Shapefile...")
    world = gpd.read_file(shp_path)
    return world[world['name'] == 'France']


def get_all_poi() -> list[POI]:
    """
    Parcourt les fichiers JSON pour extraire les POI et leurs coordonnées.

    Retourne :
        list[POI] : Liste des objets POI contenant le chemin et les coordonnées.
    """
    poi_files = explore_directory()
    pois = []

    for file in poi_files:
        try:
            raw_coords = get_poi_coordinates(file)
            latitude, longitude = map(float, raw_coords)
            pois.append(POI(file_path=file, latitude=latitude, longitude=longitude))
        except (ValueError, TypeError) as e:
            print(f"Erreur dans le fichier {file} : {e}")
    return pois


def explore_directory() -> list[str]:
    """
    Explore un dossier pour trouver tous les fichiers JSON contenant des POI.

    Retourne :
        list[str] : Liste des chemins des fichiers JSON.
    """
    base_path = "../data"
    all_json_files = []

    for root, _, files in os.walk(base_path):
        for file in files:
            if file.endswith(".json") and file != "index.json":
                full_path = os.path.join(root, file)
                all_json_files.append(full_path)
    return all_json_files


def filter_poi_in_france(pois: list[POI], france_geometry: gpd.GeoDataFrame) -> list[str]:
    """
    Filtre les POI pour ne garder que ceux situés en France.

    Args:
        pois (list[POI]): Liste des objets POI.
        france_geometry (gpd.GeoDataFrame): Géométrie de la France.

    Retourne :
        list[str] : Liste des chemins des fichiers JSON des POI en France.
    """
    poi_in_france_files = []

    for poi in pois:
        try:
            point = poi.to_point()
            if france_geometry.geometry.contains(point).any():
                poi_in_france_files.append(poi.file_path)
        except Exception as e:
            print(f"Erreur lors du traitement de {poi} : {e}")
    return poi_in_france_files


def cleanup_downloaded_data(path: str) -> None:
    """
    Supprime les fichiers temporaires.

    Args:
        path (str): Chemin du répertoire à supprimer.
    """
    print("Nettoyage des fichiers temporaires...")
    if os.path.exists(path):
        shutil.rmtree(path)
        print(f"Supprimé : {path}")


def main() -> list[str]:
    """
    Fonction principale :
    - Télécharge et extrait les données.
    - Récupère et filtre les POI situés en France.
    - Nettoie les fichiers temporaires.

    Retourne :
        list[str] : Liste des chemins des fichiers JSON des POI en France.
    """
    # Étape 1 : Télécharger et extraire les données
    print("Étape 1 : Téléchargement des données touristiques")
    download_datatourisme_archive()
    extract_data()
    print("Extraction terminée.")

    # Étape 2 : Récupérer le fichier Shapefile et la géométrie de la France
    shapefile_path = download_and_get_shapefile()
    france_geometry = get_france_geometry(shapefile_path)

    # Étape 3 : Obtenir les POI et filtrer ceux en France
    pois = get_all_poi()
    poi_in_france_files = filter_poi_in_france(pois, france_geometry)

    # Étape 4 : Nettoyage des fichiers temporaires
    cleanup_downloaded_data(os.path.dirname(shapefile_path))

    # Afficher les résultats
    print(f"\nNombre de POI en France : {len(poi_in_france_files)}")

    return poi_in_france_files


if __name__ == "__main__":
    poi_files_in_france = main()
