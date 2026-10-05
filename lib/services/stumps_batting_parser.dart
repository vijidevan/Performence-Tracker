class StumpsBattingParser {
  List<Map<String, dynamic>> parseBatting(String text) {
    final tokens = _normalizeTokens(text);
    final results = <Map<String, dynamic>>[];

    int index = 0;

    while (index < tokens.length) {
      final innings = _detectInnings(tokens, index);

      if (innings == null) {
        index++;
        continue;
      }

      final parsed = _parseInnings(
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

  int? _detectInnings(
    List<String> tokens,
    int index,
  ) {
    if (index + 2 >= tokens.length) {
      return null;
    }

    final first = tokens[index].toLowerCase();
    final second = tokens[index + 1].toLowerCase();
    final third = tokens[index + 2].toLowerCase();

    if (first == '1st' &&
        second == 'innings' &&
        third == 'scorecard') {
      return 1;
    }

    if (first == '2nd' &&
        second == 'innings' &&
        third == 'scorecard') {
      return 2;
    }

    return null;
  }

  _ParsedInnings _parseInnings(
    List<String> tokens,
    int scorecardIndex,
    int inningsNumber,
  ) {
    final headerIndex = _findBattingHeader(
      tokens,
      scorecardIndex,
    );

    if (headerIndex == -1) {
      return _ParsedInnings(
        players: const [],
        nextIndex: scorecardIndex + 1,
      );
    }

    final teamName = _extractTeamName(
      tokens,
      headerIndex,
    );

    final players = <Map<String, dynamic>>[];

    int index = headerIndex + 7;

    while (index < tokens.length) {
      if (_isBattingSectionEnd(tokens, index)) {
        break;
      }

      final row = _parsePlayerRow(
        tokens,
        index,
        teamName,
        inningsNumber,
      );

      if (row == null) {
        index++;
        continue;
      }

      players.add(row.player);

      index = row.nextIndex;
    }

    return _ParsedInnings(
      players: players,
      nextIndex: index,
    );
  }

  int _findBattingHeader(
    List<String> tokens,
    int scorecardIndex,
  ) {
    for (
      int i = scorecardIndex + 3;
      i + 5 < tokens.length;
      i++
    ) {
      if (tokens[i].toUpperCase() == 'R' &&
          tokens[i + 1].toUpperCase() == 'B' &&
          tokens[i + 2].toLowerCase() == '4s' &&
          tokens[i + 3].toLowerCase() == '6s' &&
          tokens[i + 4].toUpperCase() == 'SR') {
        return i - 2;
      }

      if (_isNextMajorSection(tokens, i)) {
        break;
      }
    }

    return -1;
  }

  String _extractTeamName(
    List<String> tokens,
    int headerIndex,
  ) {
    final nameParts = <String>[];

    for (
      int i = headerIndex;
      i < headerIndex + 2 && i < tokens.length;
      i++
    ) {
      nameParts.add(tokens[i]);
    }

    return nameParts.join(' ').trim();
  }

  _ParsedPlayerRow? _parsePlayerRow(
    List<String> tokens,
    int startIndex,
    String teamName,
    int inningsNumber,
  ) {
    final numericStart = _findNumericStatsStart(
      tokens,
      startIndex,
    );

    if (numericStart == -1) {
      return null;
    }

    if (numericStart + 4 >= tokens.length) {
      return null;
    }

    final runs = int.tryParse(
      tokens[numericStart],
    );

    final ballsFaced = int.tryParse(
      tokens[numericStart + 1],
    );

    final fours = int.tryParse(
      tokens[numericStart + 2],
    );

    final sixes = int.tryParse(
      tokens[numericStart + 3],
    );

    final strikeRate = double.tryParse(
      tokens[numericStart + 4],
    );

    if (runs == null ||
        ballsFaced == null ||
        fours == null ||
        sixes == null ||
        strikeRate == null) {
      return null;
    }

    final prefixTokens = tokens.sublist(
      startIndex,
      numericStart,
    );

    if (prefixTokens.isEmpty) {
      return null;
    }

    final dismissal = _extractDismissal(
      prefixTokens,
    );

    final playerName = _extractPlayerName(
      prefixTokens,
      dismissal,
    );

    if (playerName.isEmpty) {
      return null;
    }

    return _ParsedPlayerRow(
      player: {
        'playerName': playerName,
        'teamName': teamName,
        'innings': inningsNumber,
        'runs': runs,
        'ballsFaced': ballsFaced,
        'fours': fours,
        'sixes': sixes,
        'strikeRate': strikeRate,
        'dismissal': dismissal,
      },
      nextIndex: numericStart + 5,
    );
  }

  int _findNumericStatsStart(
    List<String> tokens,
    int startIndex,
  ) {
    for (
      int i = startIndex;
      i + 4 < tokens.length;
      i++
    ) {
      final runs = int.tryParse(tokens[i]);
      final balls = int.tryParse(tokens[i + 1]);
      final fours = int.tryParse(tokens[i + 2]);
      final sixes = int.tryParse(tokens[i + 3]);
      final strikeRate = double.tryParse(tokens[i + 4]);

      if (runs != null &&
          balls != null &&
          fours != null &&
          sixes != null &&
          strikeRate != null) {
        return i;
      }

      if (_isBattingSectionEnd(tokens, i)) {
        return -1;
      }
    }

    return -1;
  }

  String _extractDismissal(
    List<String> prefixTokens,
  ) {
    if (prefixTokens.isEmpty) {
      return '';
    }

    final lower = prefixTokens
        .map((value) => value.toLowerCase())
        .toList();

    final notOutIndex = _findSequence(
      lower,
      const ['not', 'out'],
    );

    if (notOutIndex != -1) {
      return 'not out';
    }

    final runOutIndex = lower.indexOf('runout');

    if (runOutIndex != -1) {
      return prefixTokens
          .sublist(runOutIndex)
          .join(' ')
          .trim();
    }

    final caughtAndBowledIndex = _findSequence(
      lower,
      const ['c', '&', 'b'],
    );

    if (caughtAndBowledIndex != -1) {
      return prefixTokens
          .sublist(caughtAndBowledIndex)
          .join(' ')
          .trim();
    }

    final caughtIndex = lower.indexOf('c');

    if (caughtIndex != -1 &&
        caughtIndex + 1 < prefixTokens.length) {
      final bowledIndex = lower.indexOf(
        'b',
        caughtIndex + 1,
      );

      if (bowledIndex != -1) {
        return prefixTokens
            .sublist(caughtIndex)
            .join(' ')
            .trim();
      }
    }

    final bowledIndex = lower.indexOf('b');

    if (bowledIndex != -1 &&
        bowledIndex > 0) {
      return prefixTokens
          .sublist(bowledIndex)
          .join(' ')
          .trim();
    }

    return '';
  }

  String _extractPlayerName(
    List<String> prefixTokens,
    String dismissal,
  ) {
    if (prefixTokens.isEmpty) {
      return '';
    }

    if (dismissal == 'not out') {
      final lower = prefixTokens
          .map((value) => value.toLowerCase())
          .toList();

      final notOutIndex = _findSequence(
        lower,
        const ['not', 'out'],
      );

      if (notOutIndex > 0) {
        return prefixTokens
            .sublist(0, notOutIndex)
            .join(' ')
            .trim();
      }
    }

    if (dismissal.isNotEmpty) {
      final dismissalTokens = dismissal
          .split(' ')
          .map((value) => value.toLowerCase())
          .toList();

      final lowerPrefix = prefixTokens
          .map((value) => value.toLowerCase())
          .toList();

      final dismissalIndex = _findSequence(
        lowerPrefix,
        dismissalTokens,
      );

      if (dismissalIndex > 0) {
        return prefixTokens
            .sublist(0, dismissalIndex)
            .join(' ')
            .trim();
      }
    }

    return prefixTokens.join(' ').trim();
  }

  int _findSequence(
    List<String> values,
    List<String> sequence,
  ) {
    if (sequence.isEmpty ||
        values.length < sequence.length) {
      return -1;
    }

    for (
      int i = 0;
      i <= values.length - sequence.length;
      i++
    ) {
      bool matches = true;

      for (
        int j = 0;
        j < sequence.length;
        j++
      ) {
        if (values[i + j] != sequence[j]) {
          matches = false;
          break;
        }
      }

      if (matches) {
        return i;
      }
    }

    return -1;
  }

  bool _isBattingSectionEnd(
    List<String> tokens,
    int index,
  ) {
    if (index >= tokens.length) {
      return true;
    }

    final value = tokens[index].toLowerCase();

    return value == 'extras' ||
        value == 'bowler' ||
        value == 'download' ||
        value == 'over';
  }

  bool _isNextMajorSection(
    List<String> tokens,
    int index,
  ) {
    if (index >= tokens.length) {
      return true;
    }

    final value = tokens[index].toLowerCase();

    return value == 'extras' ||
        value == 'bowler' ||
        value == 'download' ||
        value == 'over';
  }
}

class _ParsedPlayerRow {
  final Map<String, dynamic> player;
  final int nextIndex;

  const _ParsedPlayerRow({
    required this.player,
    required this.nextIndex,
  });
}

class _ParsedInnings {
  final List<Map<String, dynamic>> players;
  final int nextIndex;

  const _ParsedInnings({
    required this.players,
    required this.nextIndex,
  });
}
