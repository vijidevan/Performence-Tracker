import 'package:flutter_test/flutter_test.dart';

import 'package:team_performance/services/stumps_match_parser.dart';

void main() {
  test('parses STUMPS match information', () {
    const text = '''
Match
ID
gcuk7979

Date
&
Time
26
Sep
2026
07:19
AM

ROCKERS
ROCK4381

THUNDERS
11

Toss
THUNDERS
11
Opted
To
Bowl

Match
Format
T20

Overs
16

Organiser
Surendar
R

Scorer
Vijay

Venue

Result
THUNDERS
11
won
by
1
wicket
''';

    final parser = StumpsMatchParser();

    final result = parser.parseMatchInfo(text);

    expect(result['stumpsMatchId'], 'gcuk7979');
    expect(result['team1'], 'ROCKERS ROCK4381');
    expect(result['team2'], 'THUNDERS 11');
    expect(result['format'], 'T20');
    expect(result['overs'], '16');
    expect(result['tossWinner'], 'THUNDERS 11');
    expect(result['tossDecision'], 'Opted To Bowl');
    expect(result['organiser'], 'Surendar');
    expect(result['scorer'], 'Vijay');
    expect(
      result['result'],
      contains('THUNDERS 11 won by 1 wicket'),
    );
  });
}