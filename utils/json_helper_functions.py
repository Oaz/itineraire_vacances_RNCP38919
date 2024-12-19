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
        print(f"Erreur de clé: {e}. Clé introuvable.")
        print("Renvoi d'une valeur par défaut")
        default_timestamp = "1970-01-01T00:00:00Z"
        return default_timestamp


def get_poi_update_date(filename: str) -> str | None:
    """
    Récupère la date de mise à jour du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si la date de mise à jour n'est pas trouvée
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_updated_date = content["lastUpdateDatatourisme"]
        return _poi_updated_date
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
        _poi_department_id = content["isLocatedAt"][0]["schema:address"][0][
            "hasAddressCity"
        ]["isPartOfDepartment"]["@id"]
        _poi_department_name = content["isLocatedAt"][0]["schema:address"][0][
            "hasAddressCity"
        ]["isPartOfDepartment"]["rdfs:label"]["fr"][0]
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
        _poi_city_id = content["isLocatedAt"][0]["schema:address"][0]["hasAddressCity"][
            "@id"
        ]
        _poi_city = content["isLocatedAt"][0]["schema:address"][0]["hasAddressCity"][
            "rdfs:label"
        ]["fr"][0]
        # _poi_postcode = content["isLocatedAt"][0]["schema:address"][0]["schema:postalCode"]
        return _poi_city_id, _poi_city
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None, None


def get_poi_postal_code(filename: str) -> str | None:
    """
    Récupère le code postal du point d'intérêt dans le fichier JSON
    :param filename: str
    :return: str | None si le code postal n'est pas trouvé
    """
    with open(filename, "r", encoding="utf-8") as file:
        content = json.load(file)
    try:
        _poi_postcode = content["isLocatedAt"][0]["schema:address"][0][
            "schema:postalCode"
        ]
        return _poi_postcode
    except KeyError as e:
        print(f"Erreur de clé: {e}. Vérifier la structure et recommencer.")
        return None


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
