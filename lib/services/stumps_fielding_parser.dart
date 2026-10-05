class StumpsFieldingParser {
  List<Map<String, dynamic>> parseFielding(
    List<Map<String, dynamic>> battingRecords,
  ) {
    final results = <Map<String, dynamic>>[];

    for (final batting in battingRecords) {
      final dismissal = (
        batting['dismissal'] as String? ??
        ''
      ).trim();

      if (dismissal.isEmpty ||
          dismissal.toLowerCase() == 'not out') {
        continue;
      }

      final fielding = _parseDismissal(
        dismissal,
      );

      for (final event in fielding) {
        results.add({
          'playerName': event['playerName'],
          'eventType': event['eventType'],
          'dismissedPlayer':
              batting['playerName'],
          'teamName': batting['teamName'],
          'innings': batting['innings'],
        });
      }
    }

    return results;
  }

  List<Map<String, String>> _parseDismissal(
    String dismissal,
  ) {
    final normalized = dismissal.trim();

    if (normalized.toLowerCase().startsWith('runout')) {
      return _parseRunOut(normalized);
    }

    if (normalized.toLowerCase().startsWith('c & b ')) {
      final player = normalized
          .substring(6)
          .trim();

      if (player.isEmpty) {
        return const [];
      }

      return [
        {
          'playerName': player,
          'eventType': 'caught_and_bowled',
        },
      ];
    }

    if (normalized.toLowerCase().startsWith('c ')) {
      return _parseCatch(normalized);
    }

    return const [];
  }

  List<Map<String, String>> _parseCatch(
    String dismissal,
  ) {
    final lower = dismissal.toLowerCase();

    final bowledIndex = lower.indexOf(' b ');

    if (bowledIndex == -1) {
      return const [];
    }

    final catcher = dismissal
        .substring(2, bowledIndex)
        .trim();

    if (catcher.isEmpty) {
      return const [];
    }

    return [
      {
        'playerName': catcher,
        'eventType': 'catch',
      },
    ];
  }

  List<Map<String, String>> _parseRunOut(
    String dismissal,
  ) {
    final openParen = dismissal.indexOf('(');
    final closeParen = dismissal.lastIndexOf(')');

    if (openParen == -1 ||
        closeParen == -1 ||
        closeParen <= openParen) {
      return const [];
    }

    final names = dismissal
        .substring(
          openParen + 1,
          closeParen,
        )
        .split('/');

    final results = <Map<String, String>>[];

    for (final rawName in names) {
      final player = rawName.trim();

      if (player.isEmpty) {
        continue;
      }

      results.add({
        'playerName': player,
        'eventType': 'run_out',
      });
    }

    return results;
  }
}
