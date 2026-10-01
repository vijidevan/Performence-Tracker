class StumpsMatchParser {
  Map<String, String> parseMatchInfo(String text) {
    final lines = _normalizeLines(text);

    final teams = _extractTeams(lines);
    final toss = _extractToss(lines);

    return {
      'stumpsMatchId': _extractMatchId(lines),
      'team1': teams.isNotEmpty ? teams[0] : '',
      'team2': teams.length > 1 ? teams[1] : '',
      'format': _extractFormat(lines),
      'overs': _extractOvers(lines),
      'tossWinner': toss['winner'] ?? '',
      'tossDecision': toss['decision'] ?? '',
      'organiser': _extractOrganiser(lines),
      'scorer': _extractScorer(lines),
      'venue': _extractVenue(lines),
      'result': _extractResult(lines),
    };
  }

  List<String> _normalizeLines(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _extractMatchId(List<String> lines) {
    for (int i = 0; i < lines.length - 1; i++) {
      if (_equals(lines[i], 'Match') &&
          _equals(lines[i + 1], 'ID')) {
        if (i + 2 < lines.length) {
          return lines[i + 2].trim();
        }
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.toLowerCase().startsWith('match id')) {
        final value = line
            .replaceFirst(
              RegExp(
                r'^match\s*id\s*[:\-]?\s*',
                caseSensitive: false,
              ),
              '',
            )
            .trim();

        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    return '';
  }

  List<String> _extractTeams(List<String> lines) {
    final teams = <String>[];

    final compactScorePattern = RegExp(
      r'^(.+?)\s+(\d+)\s*[-/]\s*(\d+)\s+in\s+(\d+(?:\.\d+)?)\s+overs$',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = compactScorePattern.firstMatch(line);

      if (match == null) {
        continue;
      }

      final team = match.group(1)?.trim() ?? '';

      if (_isPlausibleTeamName(team) &&
          !teams.contains(team)) {
        teams.add(team);
      }

      if (teams.length == 2) {
        return teams;
      }
    }

    final scorePattern = RegExp(
      r'^\d+\s*[-/]\s*\d+$',
    );

    for (int i = 0; i < lines.length; i++) {
      if (!scorePattern.hasMatch(lines[i])) {
        continue;
      }

      bool validScoreBlock = false;

      if (i + 3 < lines.length &&
          _equals(lines[i + 1], 'in') &&
          RegExp(r'^\d+(?:\.\d+)?$')
              .hasMatch(lines[i + 2]) &&
          _equals(lines[i + 3], 'overs')) {
        validScoreBlock = true;
      } else if (i + 2 < lines.length &&
          _equals(lines[i + 1], 'in') &&
          _equals(lines[i + 2], 'overs')) {
        validScoreBlock = true;
      }

      if (!validScoreBlock) {
        continue;
      }

      final team = _teamNameBeforeScore(lines, i);

      if (_isPlausibleTeamName(team) &&
          !teams.contains(team)) {
        teams.add(team);
      }

      if (teams.length == 2) {
        return teams;
      }
    }

    final fallbackTeams =
        _extractTeamsFromMatchInfo(lines);

    if (fallbackTeams.length == 2) {
      return fallbackTeams;
    }

    return teams;
  }

  List<String> _extractTeamsFromMatchInfo(
    List<String> lines,
  ) {
    final tossIndex = lines.indexWhere(
      (line) => _equals(line, 'Toss'),
    );

    if (tossIndex <= 0) {
      return [];
    }

    int timeIndex = -1;

    for (int i = 0; i < tossIndex; i++) {
      if (_equals(lines[i], 'Time')) {
        timeIndex = i;
        break;
      }
    }

    if (timeIndex == -1) {
      return [];
    }

    int dateTimeEndIndex = -1;

    for (int i = timeIndex + 1; i < tossIndex; i++) {
      if (_equals(lines[i], 'AM') ||
          _equals(lines[i], 'PM')) {
        dateTimeEndIndex = i;
        break;
      }
    }

    if (dateTimeEndIndex == -1) {
      return [];
    }

    final candidateLines = <String>[];

    for (int i = dateTimeEndIndex + 1;
        i < tossIndex;
        i++) {
      final value = lines[i].trim();

      if (value.isEmpty) {
        continue;
      }

      if (_equals(value, '&')) {
        continue;
      }

      if (_isHeader(value)) {
        continue;
      }

      candidateLines.add(value);
    }

    if (candidateLines.length < 2) {
      return [];
    }

    final toss = _extractToss(lines);
    final tossWinner = toss['winner']?.trim() ?? '';

    if (tossWinner.isNotEmpty) {
      final tossTokens = tossWinner
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();

      if (tossTokens.isNotEmpty &&
          tossTokens.length <= candidateLines.length) {
        for (int start = 0;
            start <=
                candidateLines.length - tossTokens.length;
            start++) {
          bool matches = true;

          for (int j = 0;
              j < tossTokens.length;
              j++) {
            if (!_equals(
              candidateLines[start + j],
              tossTokens[j],
            )) {
              matches = false;
              break;
            }
          }

          if (!matches) {
            continue;
          }

          final team1Parts =
              candidateLines.sublist(0, start);

          final team2Parts = candidateLines.sublist(
            start,
            start + tossTokens.length,
          );

          if (team1Parts.isNotEmpty &&
              team2Parts.isNotEmpty) {
            final team1 =
                team1Parts.join(' ').trim();

            final team2 =
                team2Parts.join(' ').trim();

            if (_isPlausibleTeamName(team1) &&
                _isPlausibleTeamName(team2)) {
              return [team1, team2];
            }
          }
        }
      }
    }

    if (candidateLines.length >= 4) {
      final team1 =
          '${candidateLines[0]} ${candidateLines[1]}'
              .trim();

      final team2 =
          '${candidateLines[2]} ${candidateLines[3]}'
              .trim();

      if (_isPlausibleTeamName(team1) &&
          _isPlausibleTeamName(team2)) {
        return [team1, team2];
      }
    }

    return [];
  }

  String _teamNameBeforeScore(
    List<String> lines,
    int scoreIndex,
  ) {
    final parts = <String>[];

    for (int i = scoreIndex - 1; i >= 0; i--) {
      final value = lines[i];

      if (_isHeader(value)) {
        break;
      }

      if (_isScoreRelatedToken(value)) {
        break;
      }

      if (_isLikelyMetadata(value)) {
        break;
      }

      parts.insert(0, value);

      if (parts.length >= 6) {
        break;
      }
    }

    return parts.join(' ').trim();
  }

  bool _isScoreRelatedToken(String value) {
    final lower = value.toLowerCase();

    return lower == 'in' ||
        lower == 'overs' ||
        RegExp(r'^\d+\s*[-/]\s*\d+$')
            .hasMatch(value) ||
        RegExp(r'^\d+(?:\.\d+)?$')
            .hasMatch(value);
  }

  bool _isLikelyMetadata(String value) {
    return _equals(value, 'Date') ||
        _equals(value, 'Time') ||
        _equals(value, 'Match') ||
        _equals(value, 'ID') ||
        _equals(value, 'Toss') ||
        _equals(value, 'Venue') ||
        _equals(value, 'Result') ||
        _equals(value, 'Organiser') ||
        _equals(value, 'Scorer') ||
        _equals(value, 'Format') ||
        _equals(value, 'Match Format') ||
        _equals(value, 'Overs');
  }

  bool _isPlausibleTeamName(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return false;
    }

    if (_isHeader(cleaned)) {
      return false;
    }

    if (_equals(cleaned, 'in') ||
        _equals(cleaned, 'overs') ||
        _equals(cleaned, 'Opted') ||
        _equals(cleaned, 'To') ||
        _equals(cleaned, 'Bat') ||
        _equals(cleaned, 'Bowl')) {
      return false;
    }

    return RegExp(r'[A-Za-z]').hasMatch(cleaned);
  }

  bool _isDateToken(String value) {
    final cleaned = value.trim();

    return RegExp(
          r'^\d{1,2}$',
        ).hasMatch(cleaned) ||
        RegExp(
          r'^\d{4}$',
        ).hasMatch(cleaned) ||
        _equals(cleaned, 'Jan') ||
        _equals(cleaned, 'Feb') ||
        _equals(cleaned, 'Mar') ||
        _equals(cleaned, 'Apr') ||
        _equals(cleaned, 'May') ||
        _equals(cleaned, 'Jun') ||
        _equals(cleaned, 'Jul') ||
        _equals(cleaned, 'Aug') ||
        _equals(cleaned, 'Sep') ||
        _equals(cleaned, 'Oct') ||
        _equals(cleaned, 'Nov') ||
        _equals(cleaned, 'Dec') ||
        RegExp(
          r'^\d{1,2}:\d{2}$',
        ).hasMatch(cleaned);
  }

  Map<String, String> _extractToss(
    List<String> lines,
  ) {
    final tossIndex = lines.indexWhere(
      (line) => _equals(line, 'Toss'),
    );

    if (tossIndex == -1) {
      return {
        'winner': '',
        'decision': '',
      };
    }

    final values = <String>[];

    for (int i = tossIndex + 1;
        i < lines.length;
        i++) {
      final value = lines[i];

      // The next metadata section begins here.
      if (_equals(value, 'Match') ||
          _equals(value, 'Match Format') ||
          _equals(value, 'Format') ||
          _equals(value, 'Overs') ||
          _equals(value, 'Organiser') ||
          _equals(value, 'Scorer') ||
          _equals(value, 'Venue') ||
          _equals(value, 'Result')) {
        break;
      }

      values.add(value);
    }

    if (values.isEmpty) {
      return {
        'winner': '',
        'decision': '',
      };
    }

    final optedIndex = values.indexWhere(
      (value) =>
          _equals(value, 'Opted') ||
          _equals(value, 'Opted To'),
    );

    if (optedIndex == -1) {
      return {
        'winner': values.join(' '),
        'decision': '',
      };
    }

    final winner = values
        .sublist(0, optedIndex)
        .join(' ')
        .trim();

    final decision = values
        .sublist(optedIndex)
        .join(' ')
        .trim();

    return {
      'winner': winner,
      'decision': decision,
    };
  }

  String _extractFormat(List<String> lines) {
    for (int i = 0; i < lines.length - 1; i++) {
      if (_equals(lines[i], 'Match Format') ||
          _equals(lines[i], 'Format')) {
        return lines[i + 1].trim();
      }
    }

    return '';
  }

  String _extractOvers(List<String> lines) {
    for (int i = 0; i < lines.length - 1; i++) {
      if (_equals(lines[i], 'Overs')) {
        return lines[i + 1].trim();
      }
    }

    return '';
  }

  String _extractOrganiser(List<String> lines) {
    for (int i = 0; i < lines.length - 1; i++) {
      if (_equals(lines[i], 'Organiser')) {
        return lines[i + 1].trim();
      }
    }

    return '';
  }

  String _extractScorer(List<String> lines) {
    for (int i = 0; i < lines.length - 1; i++) {
      if (_equals(lines[i], 'Scorer')) {
        return lines[i + 1].trim();
      }
    }

    return '';
  }

  String _extractVenue(List<String> lines) {
    for (int i = 0; i < lines.length - 1; i++) {
      if (_equals(lines[i], 'Venue')) {
        final value = lines[i + 1].trim();

        if (!_isHeader(value)) {
          return value;
        }

        return '';
      }
    }

    return '';
  }

  String _extractResult(List<String> lines) {
    final resultIndex = lines.indexWhere(
      (line) => _equals(line, 'Result'),
    );

    if (resultIndex == -1) {
      return '';
    }

    final parts = <String>[];

    for (int i = resultIndex + 1;
        i < lines.length;
        i++) {
      final value = lines[i];

      if (_equals(value, 'Match') ||
          _equals(value, 'Date') ||
          _equals(value, 'Toss') ||
          _equals(value, 'Match Format') ||
          _equals(value, 'Format') ||
          _equals(value, 'Overs') ||
          _equals(value, 'Organiser') ||
          _equals(value, 'Scorer') ||
          _equals(value, 'Venue')) {
        break;
      }

      parts.add(value);
    }

    return parts.join(' ').trim();
  }

  bool _isHeader(String value) {
    final lower = value.trim().toLowerCase();

    const headers = {
      'match',
      'id',
      'date',
      '&',
      'time',
      'toss',
      'match format',
      'format',
      'overs',
      'organiser',
      'scorer',
      'venue',
      'result',
      'in',
    };

    return headers.contains(lower);
  }

  bool _equals(String a, String b) {
    return a.trim().toLowerCase() ==
        b.trim().toLowerCase();
  }
}