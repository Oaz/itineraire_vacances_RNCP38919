import os
from collections import defaultdict
import pandas as pd
import dt_utils.neo4j_helper as nh
import plotly.graph_objects as go

category = 'CulturalSite'
os.environ["NEO4J_URL"] = 'bolt://localhost:7687'
os.environ["NEO4J_USER"] = 'neo4j'
os.environ["NEO4J_PASSWORD"] = 'my_password'
with nh.connect_to_neo4j() as driver:
  with driver.session() as session:
    result = session.run(
      "MATCH (c:Cluster {category:$category}) RETURN c",
      category=category
    )
    clusters = [dict(r["c"].items()) for r in result]
    result = session.run(
      """
      MATCH (c:Cluster {category:$category})-[:VICINITY]->(p:POI)
      RETURN c.id AS cluster, p.name AS name
      """,
      category=category
    )
    names = defaultdict(list)
    for r in result:
      names[r['cluster']].append(r["name"])
    result = session.run(
      """
      MATCH (c1:Cluster {category:$category})-[r:ROUTE]->(c2:Cluster)
      RETURN c1.x AS x1, c1.y AS y1, c2.x AS x2, c2.y AS y2
      """,
      category=category
    )
    routes = {tuple(sorted(((r['x1'], r['y1']), (r['x2'], r['y2'])))) for r in result}

df_clusters = pd.DataFrame(clusters)

for cluster in clusters:
  cluster.update({'pois': '<br>'.join(names[cluster['id']])})

fig = go.Figure()
fig.add_trace(
  go.Scatter(
    x=df_clusters["x"],
    y=df_clusters["y"],
    mode="markers",
    customdata=clusters,
    hovertemplate=(
      "<b>Cluster Info</b><br>"
      "X: %{customdata.x}<br>"
      "Y: %{customdata.y}<br>"
      "ID: %{customdata.id}<br>"
      "POIs:<br>%{customdata.pois}<br>"
      "<extra></extra>"
    ),
    marker=dict(
      size=df_clusters["radius"] / 1000,
      color=df_clusters["density"],
      colorscale="Viridis_r",
      cmin=0,
      cmax=2,
      line=dict(color="black", width=1),
    )
  )
)

edge_x = []
edge_y = []
for (x1, y1), (x2, y2) in routes:
  edge_x.extend([x1, x2, None])
  edge_y.extend([y1, y2, None])

fig.add_trace(go.Scatter(
  x=edge_x,
  y=edge_y,
  mode='lines',
  line=dict(color='gray', width=2)
))

fig.update_layout(
  title=f"Clusters {category}",
  xaxis_title="Lambert X",
  yaxis_title="Lambert Y",
  showlegend=False,
)

fig.show()
