class CinematicPanel {
  const CinematicPanel({required this.panelIndex, required this.caption,
    required this.assetPath});
  final int panelIndex;
  final String caption;
  final String assetPath;
}

class CinematicScene {
  CinematicScene({required this.sceneId, required this.title,
    required List<CinematicPanel> panels, required List<String> decisionChoices})
      : panels = List.unmodifiable(panels),
        decisionChoices = List.unmodifiable(decisionChoices) {
    if (panels.length != 4 ||
        panels.map((p) => p.panelIndex).toSet().length != 4 ||
        decisionChoices.length != 5 ||
        decisionChoices.any((choice) => choice.trim().isEmpty)) {
      throw ArgumentError('Moonveil scenes require four distinct panels and five choices');
    }
  }
  final String sceneId;
  final String title;
  final List<CinematicPanel> panels;
  final List<String> decisionChoices;
}
