import json


def get_poi_identifier(filename: str) -> str | None:
    """
    Récupère l'identifiant du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si l'identifiant n'est pas trouvé
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_id = content["dc:identifier"]
        return _poi_id
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None

def get_poi_name(filename: str) -> str | None:
    """
    Récupère le nom du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si le nom n'est pas trouvé
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_name = content["rdfs:label"]["fr"][0]
        return _poi_name
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None

def get_poi_creation_date(filename: str) -> str | None:
    """
    Récupère la date de création du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si la date de création n'est pas trouvée
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_created_date = content["creationDate"]
        return _poi_created_date
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None

def find_last_update_by_label(label: str) -> str | None:
    """
    Trouve la valeur de `lastUpdateDatatourisme` pour un label donné dans le fichier index.json
    :param label: str
    :return: str | None si le label n'est pas trouvé
    """
    with open("../data/index.json", "r", encoding="utf-8") as file:
        data = json.load(file)

    for item in data:
        if item.get("label") == label:
            return item.get("lastUpdateDatatourisme")
    return None

def get_poi_category(filename: str) -> list | None:
    """
    Récupère la catégorie du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si la catégorie n'est pas trouvée
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_category = content["@type"]
        return _poi_category
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None

def category_cleanup(category_list: list) -> list:
    """
    Nettoie la liste des catégories en supprimant celles qui sont uniquement utiles au schéma
    Les catégories suivantes sont supprimées:
    - schema:*

    :param category_list: list
    :return: list
    """

    return [
        category for category in category_list if not category.startswith("schema:")
    ]

def get_poi_region(filename: str) -> tuple[str, str] | tuple[None, None]:
    """
    Récupère la région du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si la région n'est pas trouvée
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_region_id = content["isLocatedAt"][0]["schema:address"][0][
            "hasAddressCity"
        ]["isPartOfDepartment"]["isPartOfRegion"]["@id"]
        _poi_region_name = content["isLocatedAt"][0]["schema:address"][0][
            "hasAddressCity"
        ]["isPartOfDepartment"]["isPartOfRegion"]["rdfs:label"]["fr"][0]
        return _poi_region_id, _poi_region_name
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None, None

def get_poi_department(filename: str) -> tuple[str, str] | tuple[None, None]:
    """
    Récupère le département du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si le département n'est pas trouvé
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_department_id = content["isLocatedAt"][0]["schema:address"][0]["hasAddressCity"]["isPartOfDepartment"]["@id"]
        _poi_department_name = content["isLocatedAt"][0]["schema:address"][0]["hasAddressCity"]["isPartOfDepartment"]["rdfs:label"]["fr"][0]
        return _poi_department_id, _poi_department_name
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None, None

def get_poi_city(filename: str) -> tuple[str, str] | tuple[None, None]:
    """
    Récupère la ville du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si la ville n'est pas trouvée
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_city_id = content["isLocatedAt"][0]["schema:address"][0]["hasAddressCity"]["@id"]
        _poi_city = content["isLocatedAt"][0]["schema:address"][0]["hasAddressCity"]["rdfs:label"]["fr"][0]
        #_poi_postcode = content["isLocatedAt"][0]["schema:address"][0]["schema:postalCode"]
        return _poi_city_id, _poi_city
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None, None

def get_poi_coordinates(filename: str) -> tuple[float, float] | tuple[None, None]:
    """
    Récupère les coordonnées du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: Tuple[float, float] | None si les coordonnées ne sont pas trouvées
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_lat = float(content["isLocatedAt"][0]["schema:geo"]["schema:latitude"])
        _poi_long = float(content["isLocatedAt"][0]["schema:geo"]["schema:longitude"])
        return _poi_lat, _poi_long
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None, None

if __name__ == "__main__":
    try:
        # Essai sur un fichier JSON
        # Pensez à modifier le chemin du fichier si nécessaire
        file_path = "../data/objects/0/0a/49-0a1a7c7e-b2b1-3bb8-b4a2-0be8c160333a.json"

        poi_identifier = get_poi_identifier(file_path)
        poi_name = get_poi_name(file_path)
        poi_creation_date = get_poi_creation_date(file_path)
        poi_category = get_poi_category(file_path)
        poi_category_cleaned = category_cleanup(poi_category)
        poi_region_id, poi_region_name = get_poi_region(file_path)
        poi_department_id, poi_department_name = get_poi_department(file_path)
        poi_city_id, poi_city_name, poi_post_code = get_poi_city(file_path)
        poi_latitude, poi_longitude = get_poi_coordinates(file_path)

        print(f"Identifiant du point d'intérêt: {poi_identifier}")
        print(f"Nom du point d'intérêt: {poi_name}")
        print(f"Catégories *cleaned* du point d'intérêt: {poi_category_cleaned}")
        print(f"Région du point d'intérêt: {poi_region_id} - {poi_region_name}")
        print(f"Département du point d'intérêt: {poi_department_id} - {poi_department_name}")
        print(f"Ville du point d'intérêt: {poi_city_id} - {poi_city_name} - {poi_post_code}")
        print(f"Coordonnées du point d'intérêt: {poi_latitude}, {poi_longitude}")

        # Récupération du last update pour un label donné
        label_a_verifier = "Savonnerie Martin de Candre"
        poi_last_update = find_last_update_by_label(label_a_verifier)
        print(f"Dernière mise à jour du POI '{label_a_verifier}': {poi_last_update}")

    except FileNotFoundError as e:
        print(f"FileNotFoundError: {e}. Vérifier le chemin du fichier et recommencer.")