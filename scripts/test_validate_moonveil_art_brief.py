import unittest
from scripts.validate_moonveil_art_brief import validate_brief

class StyleTests(unittest.TestCase):
    def test_approved_vesper_brief(self):
        brief = ("Photorealistic Vesper Vane portrait, Nordic facial features, "
                 "Victorian London tailoring, Parisian couture, Transylvanian "
                 "gothic vampire aristocracy, no anime, no emoji")
        self.assertEqual(validate_brief(brief), [])

    def test_missing_identity_is_flagged(self):
        problems = validate_brief("photorealistic female dhampir")
        self.assertEqual(len(problems), 4)

    def test_cartoon_prompt_rejected(self):
        problems = validate_brief("cartoon fantasy character", subject="other")
        self.assertIn("Disallowed style: cartoon", problems)
        self.assertIn("Missing photorealism requirement", problems)

if __name__ == "__main__":
    unittest.main()
