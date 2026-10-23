import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/models/cinematic_storyboard_model.dart';

void main() {
  final panels = List.generate(4, (i) => CinematicPanel(
    panelIndex: i + 1, caption: 'Panel ${i + 1}',
    assetPath: 'assets/images/panels/p${i + 1}.png'));
  test('Requires exactly four panels and five decisions', () {
    expect(() => CinematicScene(sceneId: 'archive', title: 'Archive',
      panels: panels, decisionChoices: ['Lawful Good', 'Neutral Good',
        'Chaotic Good', 'Utility', 'Action']), returnsNormally);
    expect(() => CinematicScene(sceneId: 'bad', title: 'Bad',
      panels: panels, decisionChoices: ['A', 'B', 'C']), throwsArgumentError);
  });
}
