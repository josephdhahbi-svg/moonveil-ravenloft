/// A deterministic, replayable puzzle with no inventory or character mutations.
class ArchiveConduitPuzzle {
  static const symbols = ['Moon', 'Star', 'Weave'];
  static const solution = ['Moon', 'Weave', 'Star'];

  static bool isValid(List<String> sequence) =>
      sequence.length <= 3 && sequence.every(symbols.contains);

  static bool isSolved(List<String> sequence) =>
      sequence.length == 3 &&
      List.generate(3, (i) => sequence[i] == solution[i]).every((v) => v);

  static String feedback(List<String> sequence) {
    if (!isValid(sequence)) return 'Unknown inscription.';
    if (sequence.length < 3) return 'The lunar mechanism awaits another glyph.';
    if (isSolved(sequence)) {
      return 'The moonstone conduit aligns. A hidden passage opens toward the archive observatory.';
    }
    return 'The gears reverse without harm. The mechanism resets; try another sequence.';
  }
}
