import unittest
import dt_utils.json_helper_functions as jhf


class TestsJsonHelperFunctions(unittest.TestCase):
  def setUp(self):
    self.file_path = "./dt_feed_example/data/objects/0/0a/49-0a1a7c7e-b2b1-3bb8-b4a2-0be8c160333a.json"

  def test_poi_identifier(self):
    self.assertEqual("FMAPDL049V50HL4Q", jhf.get_poi_identifier(self.file_path))

  def test_poi_name(self):
    self.assertEqual("Le chat, la goutte d'eau et le frigo (titre provisoire)", jhf.get_poi_name(self.file_path))

  def test_poi_creation_date(self):
    self.assertEqual("2024-09-25", jhf.get_poi_creation_date(self.file_path))

  def test_poi_category(self):
    self.assertEqual(['A', 'B', 'C'], jhf.category_cleanup(['schema:xyz', 'A', 'B', 'C']))
    self.assertEqual([
      'CulturalEvent',
      'EntertainmentAndEvent',
      'PointOfInterest',
      'ShowEvent'
    ], jhf.category_cleanup(jhf.get_poi_category(self.file_path))
    )

  def test_poi_region(self):
    self.assertEqual(('kb:France52', 'Pays de la Loire'), jhf.get_poi_region(self.file_path))

  def test_poi_department(self):
    self.assertEqual(('kb:France5249', 'Maine-et-Loire'), jhf.get_poi_department(self.file_path))

  def test_poi_city(self):
    self.assertEqual(('kb:49328', 'Saumur', '49400'), jhf.get_poi_city(self.file_path))

  def test_poi_coordinates(self):
    self.assertEqual((47.260621, -0.076107), jhf.get_poi_coordinates(self.file_path))


if __name__ == '__main__':
  unittest.main()
