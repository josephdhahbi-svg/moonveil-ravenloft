/// Narrative-only outcomes for the five established Forgotten Archive choices.
/// These never grant equipment, change stats, or overwrite character snapshots.
class ForgottenArchiveConsequences {
  static const Map<String, String> outcomes = {
    'Lawful Good': 'Vesper traces a protective silver ward around the threshold. The archive remains open while she searches for anyone endangered by the failing seal.',
    'Neutral Good': 'Vesper calls softly into the dark, offering aid. A distant answering knock suggests someone may still be trapped beyond the lunar conduit.',
    'Chaotic Good': 'Vesper challenges the corrupted Netherese command glyph. Its red light falters, revealing an older Selunite inscription beneath.',
    'Utility': 'Vesper studies the harmonic pattern. The Sight of Vaelthara identifies a junction between the lunar mechanism and a damaged Weave conduit.',
    'Action': 'Vesper advances behind the stone pillars. Clockwork teeth turn overhead, and the guardian chamber becomes visible beyond the arch.',
  };

  static String? describe(String? choice) => outcomes[choice];
}
