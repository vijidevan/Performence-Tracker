class StumpsBowlingParser {
  List<Map<String, dynamic>> parseBowling(String text) {
    final tokens = _normalizeTokens(text);
    final results = <Map<String, dynamic>>[];

    int index = 0;
    int innings = 0;

    while (index < tokens.length) {
      if (!_isBowlingHeader(tokens, index)) {
        index++;
        continue;
      }

      innings++;

      final parsed = _parseBowlingSection(
        tokens,
        index,
        innings,
      );

      results.addAll(parsed.players);

      if (parsed.nextIndex > index) {
        index = parsed.nextIndex;
      } else {
        index++;
      }
    }

    return results;
  }

  List<String> _normalizeTokens(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  bool _isBowlingHeader(
    List<String> tokens,
    int index,
  ) {
    if (index + 10 >= tokens.length) {
      return false;
    }

    final expected = [
      'Bowler',
      'O',
      'M',
      'R',
      'W',
      'Eco',
      '0s',
      '4s',
      '6s',
      'Wd',
      'NB',
    ];

    for (int i = 0; i < expected.length; i++) {
      if (tokens[index + i].toLowerCase() !=
          expected[i].toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  _ParsedBowlingSection _parseBowlingSection(
    List<String> tokens,
    int headerIndex,
    int innings,
  ) {
    final results = <Map<String, dynamic>>[];

    int index = headerIndex + 11;

    while (index < tokens.length) {
      if (_isSectionEnd(tokens[index])) {
        break;
      }

      final row = _parseBowlerRow(
        tokens,
        index,
        innings,
      );

      if (row == null) {
        index++;
        continue;
      }

      results.add(row.player);
      index = row.nextIndex;
    }

    return _ParsedBowlingSection(
      players: results,
      nextIndex: index,
    );
  }

  _ParsedBowlerRow? _parseBowlerRow(
    List<String> tokens,
    int startIndex,
    int innings,
  ) {
    final numericStart = _findBowlingNumbers(
      tokens,
      startIndex,
    );

    if (numericStart == -1) {
      return null;
    }

    if (numericStart + 9 >= tokens.length) {
      return null;
    }

    final overs = double.tryParse(
      tokens[numericStart],
    );

    final maidens = int.tryParse(
      tokens[numericStart + 1],
    );

    final runsConceded = int.tryParse(
      tokens[numericStart + 2],
    );

    final wickets = int.tryParse(
      tokens[numericStart + 3],
    );

    final economy = double.tryParse(
      tokens[numericStart + 4],
    );

    final dotBalls = int.tryParse(
      tokens[numericStart + 5],
    );

    final fours = int.tryParse(
      tokens[numericStart + 6],
    );

    final sixes = int.tryParse(
      tokens[numericStart + 7],
    );

    final wides = int.tryParse(
      tokens[numericStart + 8],
    );

    final noBalls = int.tryParse(
      tokens[numericStart + 9],
    );

    if (overs == null ||
        maidens == null ||
        runsConceded == null ||
        wickets == null ||
        economy == null ||
        dotBalls == null ||
        fours == null ||
        sixes == null ||
        wides == null ||
        noBalls == null) {
      return null;
    }

    final name = tokens
        .sublist(startIndex, numericStart)
        .join(' ')
        .trim();

    if (name.isEmpty) {
      return null;
    }

    return _ParsedBowlerRow(
      player: {
        'playerName': name,
        'innings': innings,
        'overs': overs,
        'maidens': maidens,
        'runsConceded': runsConceded,
        'wickets': wickets,
        'economy': economy,
        'dotBalls': dotBalls,
        'fours': fours,
        'sixes': sixes,
        'wides': wides,
        'noBalls': noBalls,
      },
      nextIndex: numericStart + 10,
    );
  }

  int _findBowlingNumbers(
    List<String> tokens,
    int startIndex,
  ) {
    for (
      int i = startIndex;
      i + 9 < tokens.length;
      i++
    ) {
      final overs = double.tryParse(tokens[i]);
      final maidens = int.tryParse(tokens[i + 1]);
      final runs = int.tryParse(tokens[i + 2]);
      final wickets = int.tryParse(tokens[i + 3]);
      final economy = double.tryParse(tokens[i + 4]);
      final dots = int.tryParse(tokens[i + 5]);
      final fours = int.tryParse(tokens[i + 6]);
      final sixes = int.tryParse(tokens[i + 7]);
      final wides = int.tryParse(tokens[i + 8]);
      final noBalls = int.tryParse(tokens[i + 9]);

      if (overs != null &&
          maidens != null &&
          runs != null &&
          wickets != null &&
          economy != null &&
          dots != null &&
          fours != null &&
          sixes != null &&
          wides != null &&
          noBalls != null) {
        return i;
      }

      if (_isSectionEnd(tokens[i])) {
        return -1;
      }
    }

    return -1;
  }

  bool _isSectionEnd(String value) {
    final normalized = value.toLowerCase();

    return normalized == 'download' ||
        normalized == 'over' ||
        normalized == 'bowler';
  }
}

class _ParsedBowlerRow {
  final Map<String, dynamic> player;
  final int nextIndex;

  const _ParsedBowlerRow({
    required this.player,
    required this.nextIndex,
  });
}

class _ParsedBowlingSection {
  final List<Map<String, dynamic>> players;
  final int nextIndex;

  const _ParsedBowlingSection({
    required this.players,
    required this.nextIndex,
  });
}