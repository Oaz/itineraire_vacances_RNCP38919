import os
import unittest
from testcontainers.postgres import PostgresContainer
import utils.database_helper as dh
from sqlalchemy import text
from sqlalchemy.orm import sessionmaker


class TestDatabase(unittest.TestCase):

  def setUp(self):
    self.postgres_container = PostgresContainer("postgres:latest")
    self.postgres_container.start()
    os.environ["POSTGRES_USER"] = self.postgres_container.username
    os.environ["POSTGRES_PASSWORD"] = self.postgres_container.password
    os.environ["POSTGRES_DB"] = self.postgres_container.dbname
    os.environ["POSTGRES_PORT"] = self.postgres_container.get_exposed_port(5432)
    os.environ["POSTGRES_HOST"] = self.postgres_container.get_container_host_ip()
    self.engine = dh.connect_to_db()

  def tearDown(self):
    self.postgres_container.stop()

  def test_database_connection(self):
    factory = sessionmaker(bind=self.engine)
    with factory() as session:
      result = session.execute(text("SELECT 1")).scalar()
      self.assertEqual(result, 1)

if __name__ == '__main__':
  unittest.main()
