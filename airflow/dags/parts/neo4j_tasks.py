import os
from airflow.decorators import task
from parts.helpers import inject_vars_into_env


@task
@inject_vars_into_env("NEO4J_USER", "NEO4J_PASSWORD", "NEO4J_URL")
def neo4j_placeholder():
  print('NEO4J_USER=', os.environ.get("NEO4J_USER"))
  print('NEO4J_PASSWORD=', os.environ.get("NEO4J_PASSWORD"))
  print('NEO4J_URL=', os.environ.get("NEO4J_URL"))

