import re
import shutil
import fireducks.pandas as pd
from dt_utils import download_datatourisme_categories, connect_to_db, save_dataframe_to_postgres


def extract_categories() -> pd.DataFrame:
    """
    Permet d'extraire les catégories du fichier ontology pour les mettre dans un Dataframe
    :return: df : Dataframe avec toutes les catégories de datatourisme
    """
    download_datatourisme_categories()
    
    categories = []
    pattern = r"###  https://www\.datatourisme\.fr/ontology/core#(\w+)"
    
    with open("../temporary_categories/ontology.TTL", "r", encoding="utf-8") as file:
        for line in file:
            match = re.match(pattern, line)
            if match:
                categories.append(match.group(1))
    shutil.rmtree("../temporary_categories")
    categories = set(categories)
    df = pd.DataFrame(categories, columns=["name"])
    return df

if __name__ == "__main__":

    # Insérer les catégories dans la table category*
    print("Début de l'insertion dans la table category")
    save_dataframe_to_postgres(extract_categories(), "category", connect_to_db(), 'append')
    print("Insertion terminée dans la table category.")
