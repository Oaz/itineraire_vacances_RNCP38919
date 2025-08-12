import pickle
from pathlib import Path
import networkx as nx

categories_dir = Path(__file__).parent / "categories"
graphs_dir = Path(__file__).parent / "graphs"


class Cluster:
    id: int
    x: int
    y: int
    radius: float
    density: float
    pois: list

class Route:
    source_id: int
    target_id: int
    distance: int


class CategoryData:
    category: str
    clustersCount: int
    routesCount: int


class CategoryGraph:
    name: str
    clusters: list[Cluster]
    routes: list[Route]
    nxg: nx.Graph
    poi_to_cluster: dict[str, int]

    def route(self, start_poi: str, end_poi: str) -> list[list[str]]:
        start_cluster = self.poi_to_cluster.get(start_poi)
        end_cluster = self.poi_to_cluster.get(end_poi)
        if start_cluster is None or end_cluster is None:
            return []
        try:
            cluster_path = nx.shortest_path(self.nxg, start_cluster, end_cluster, weight='distance')
        except nx.NetworkXNoPath:
            return []
        route = []
        for i in range(len(cluster_path)):
            cluster_id = cluster_path[i]
            cluster = next(c for c in self.clusters if c.id == cluster_id)
            if i == 0:
                route.append([start_poi] + [p for p in cluster.pois if p != start_poi])
            elif i == len(cluster_path) - 1:
                route.append([p for p in cluster.pois if p != end_poi] + [end_poi])
            else:
                route.append(cluster.pois)
        return route

class Category:
    def __init__(self, filename):
        self.filename = filename
        self.name = ''

    def data(self) -> CategoryData:
        g = self.graph()
        data = CategoryData()
        data.category = g.name
        data.clustersCount = len(g.clusters)
        data.routesCount = len(g.routes)
        return data

    def graph(self) -> CategoryGraph:
        with open(self.filename, 'rb') as f:
            return pickle.load(f)

def create_graphs():
        """
        Create graph pickle files for each category found in clusters.csv.
        1. Load clusters.csv and identify unique categories
        2. For each category:
           - Filter clusters belonging to that category
           - Load relevant routes from routes.csv
           - Create a CategoryGraph and save it to disk
        """
        import pandas as pd
        categories_dir.mkdir(exist_ok=True)
        clusters_path = graphs_dir / "clusters.csv"
        if not clusters_path.exists():
            raise FileNotFoundError(f"Clusters file not found: {clusters_path}")
        clusters_df = pd.read_csv(clusters_path)
        if "category" not in clusters_df.columns:
            raise ValueError("Category column not found in clusters.csv")
        routes_path = graphs_dir / "routes.csv"
        if not routes_path.exists():
            raise FileNotFoundError(f"Routes file not found: {routes_path}")
        routes_df = pd.read_csv(routes_path)
        vicinities_path = graphs_dir / "vicinities.csv"
        if not vicinities_path.exists():
            raise FileNotFoundError(f"Vicinities file not found: {vicinities_path}")
        vicinities_df = pd.read_csv(vicinities_path)
        categories = clusters_df["category"].unique()
        print(f"Found {len(categories)} categories: {categories}")
        for category in categories:
            category_clusters = clusters_df[clusters_df["category"] == category]
            cluster_ids = category_clusters["id"].tolist()
            category_routes = routes_df[
                (routes_df["source_id"].isin(cluster_ids)) &
                (routes_df["target_id"].isin(cluster_ids)) &
                (routes_df["category"] == category)
            ]
            category_vicinities = vicinities_df[
                (vicinities_df["cluster_id"].isin(cluster_ids)) &
                (vicinities_df["category"] == category)
                ]
            clusters = []
            for _, row in category_clusters.iterrows():
                cluster = Cluster()
                cluster.id = row["id"]
                cluster.x = row["x"]
                cluster.y = row["y"]
                cluster.radius = row["radius"]
                cluster.density = row["density"]
                cluster.pois = category_vicinities[category_vicinities["cluster_id"] == cluster.id]["poi_id"].tolist()
                clusters.append(cluster)
            routes = []
            for _, row in category_routes.iterrows():
                route = Route()
                route.source_id = row["source_id"]
                route.target_id = row["target_id"]
                route.distance = row["distance"]
                routes.append(route)
            graph = CategoryGraph()
            graph.name = category
            graph.clusters = clusters
            graph.routes = routes
            graph.poi_to_cluster = {
                poi_id: cluster_id
                for _, row in category_vicinities.iterrows()
                for poi_id in [row["poi_id"]]
                for cluster_id in [row["cluster_id"]]
            }
            # Create networkx graph
            nx_graph = nx.Graph()
            for cluster in clusters:
                nx_graph.add_node(cluster.id, x=cluster.x, y=cluster.y,
                                  radius=cluster.radius, density=cluster.density)
            for route in routes:
                nx_graph.add_edge(route.source_id, route.target_id,
                                  distance=route.distance)
            graph.nxg = nx_graph
            category_filename = categories_dir / f"{category}.pkl"
            with open(category_filename, 'wb') as f:
                pickle.dump(graph, f)
            print(f"Created graph for category {category} with {len(clusters)} clusters and {len(routes)} routes")

def load_categories() -> dict[str, Category]:
    """
    Load categories from pickle files in the categories folder.
    If no categories are found, create them from CSV files in the graphs folder.
    """
    categories = {}
    categories_dir.mkdir(exist_ok=True)
    category_files = list(categories_dir.glob("*.pkl"))
    if len(category_files) == 0:
        create_graphs()
    category_files = list(categories_dir.glob("*.pkl"))
    for category_file in category_files:
        try:
            category = Category(category_file)
            data = category.data()
            categories[data.category] = category
            print(f"Loaded category: {data.category}")
        except Exception as e:
            print(f"Error loading category {category_file}: {e}")
    return categories