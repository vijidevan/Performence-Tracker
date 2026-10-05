import 'package:flutter/material.dart';

import 'models/match_model.dart';
import 'models/player_match_performance_model.dart';
import 'models/team_model.dart';
import 'repositories/player_match_performance_repository.dart';

class MatchDetailsPage extends StatefulWidget {
  final MatchModel match;
  final TeamModel? team1;
  final TeamModel? team2;
  final Map<String, String> playerNames;
  final Map<String, String> teamNames;

  const MatchDetailsPage({
    super.key,
    required this.match,
    required this.team1,
    required this.team2,
    required this.playerNames,
    required this.teamNames,
  });

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  final PlayerMatchPerformanceRepository _performanceRepository =
      PlayerMatchPerformanceRepository();

  bool _isLoading = true;
  String? _error;
  List<PlayerMatchPerformanceModel> _performances = [];

  @override
  void initState() {
    super.initState();
    _loadPerformances();
  }

  Future<void> _loadPerformances() async {
    try {
      final performances =
          await _performanceRepository.getPerformancesForMatch(
        widget.match.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _performances = performances;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _playerName(String playerId) {
    return widget.playerNames[playerId] ?? playerId;
  }

  String _teamName(String teamId) {
    final name = widget.teamNames[teamId];

    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (teamId == widget.match.team1Id) {
      return widget.team1?.name.isNotEmpty == true
          ? widget.team1!.name
          : teamId;
    }

    if (teamId == widget.match.team2Id) {
      return widget.team2?.name.isNotEmpty == true
          ? widget.team2!.name
          : teamId;
    }

    return teamId;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} ${date.year} • '
        '$hour:$minute $period';
  }

  List<PlayerMatchPerformanceModel> _teamPerformances(
    String teamId,
  ) {
    return _performances
        .where((performance) => performance.teamId == teamId)
        .toList();
  }

  List<PlayerMatchPerformanceModel> _battingForTeam(
    String teamId,
  ) {
    final rows = _teamPerformances(teamId)
        .where(
          (performance) =>
              performance.ballsFaced > 0 ||
              performance.runs > 0 ||
              performance.dismissal.isNotEmpty,
        )
        .toList();

    rows.sort((a, b) {
      if (a.runs != b.runs) {
        return b.runs.compareTo(a.runs);
      }

      return a.ballsFaced.compareTo(b.ballsFaced);
    });

    return rows;
  }

  List<PlayerMatchPerformanceModel> _bowlingForTeam(
    String teamId,
  ) {
    final rows = _teamPerformances(teamId)
        .where(
          (performance) =>
              performance.overs > 0 ||
              performance.wickets > 0 ||
              performance.runsConceded > 0 ||
              performance.wides > 0 ||
              performance.noBalls > 0,
        )
        .toList();

    rows.sort((a, b) {
      if (a.wickets != b.wickets) {
        return b.wickets.compareTo(a.wickets);
      }

      return a.runsConceded.compareTo(b.runsConceded);
    });

    return rows;
  }

  List<PlayerMatchPerformanceModel> _fieldingForMatch() {
    final rows = _performances
        .where(
          (performance) =>
              performance.catches > 0 ||
              performance.caughtAndBowled > 0 ||
              performance.runOuts > 0 ||
              performance.stumpings > 0,
        )
        .toList();

    rows.sort((a, b) {
      final aTotal = a.catches +
          a.caughtAndBowled +
          a.runOuts +
          a.stumpings;

      final bTotal = b.catches +
          b.caughtAndBowled +
          b.runOuts +
          b.stumpings;

      return bTotal.compareTo(aTotal);
    });

    return rows;
  }

  Widget _sectionTitle(
    String title, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17202A),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7B8794),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E8ED),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoItem(
    String label,
    String value,
  ) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Color(0xFF9AA5B1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '--' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchHeader() {
    final team1Name = _teamName(widget.match.team1Id);
    final team2Name = _teamName(widget.match.team2Id);

    return _card(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            _formatDate(widget.match.matchDate),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B8794),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;

              if (compact) {
                return Column(
                  children: [
                    Text(
                      team1Name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9AA5B1),
                        ),
                      ),
                    ),
                    Text(
                      team2Name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      team1Name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9AA5B1),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      team2Name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (widget.match.result.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                widget.match.result,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _headerChip(
                Icons.sports_cricket_rounded,
                widget.match.format.isEmpty
                    ? 'Format N/A'
                    : widget.match.format,
              ),
              _headerChip(
                Icons.timelapse_rounded,
                '${widget.match.overs} overs',
              ),
              if (widget.match.venue.isNotEmpty)
                _headerChip(
                  Icons.location_on_outlined,
                  widget.match.venue,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE4E8ED),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF455A64),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchInformation() {
    return _card(
      child: Wrap(
        spacing: 28,
        runSpacing: 20,
        children: [
          _infoItem(
            'STUMPS ID',
            widget.match.stumpsMatchId,
          ),
          _infoItem(
            'Organiser',
            widget.match.organiser,
          ),
          _infoItem(
            'Scorer',
            widget.match.scorer,
          ),
          _infoItem(
            'Toss',
            widget.match.tossWinnerTeamId.isEmpty
                ? widget.match.tossDecision
                : '${_teamName(widget.match.tossWinnerTeamId)} • '
                    '${widget.match.tossDecision}',
          ),
          _infoItem(
            'Status',
            widget.match.completed ? 'Completed' : 'Incomplete',
          ),
        ],
      ),
    );
  }

  Widget _battingTable(
    String teamId,
  ) {
    final rows = _battingForTeam(teamId);

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _tableHeader([
            'BATTER',
            'R',
            'B',
            '4s',
            '6s',
            'SR',
            'DISMISSAL',
          ]),
          if (rows.isEmpty)
            _emptyTableMessage('No batting data available.')
          else
            ...rows.map(_battingRow),
        ],
      ),
    );
  }

  Widget _battingRow(
    PlayerMatchPerformanceModel performance,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFEEF1F4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _tablePlayerName(
              _playerName(performance.playerId),
            ),
          ),
          _tableValue('${performance.runs}'),
          _tableValue('${performance.ballsFaced}'),
          _tableValue('${performance.fours}'),
          _tableValue('${performance.sixes}'),
          _tableValue(performance.strikeRate.toStringAsFixed(1)),
          Expanded(
            flex: 3,
            child: Text(
              performance.dismissal.isEmpty
                  ? 'Not out'
                  : performance.dismissal,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF607D8B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bowlingTable(
    String teamId,
  ) {
    final rows = _bowlingForTeam(teamId);

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _tableHeader([
            'BOWLER',
            'O',
            'M',
            'R',
            'W',
            'ECO',
            'WD',
            'NB',
          ]),
          if (rows.isEmpty)
            _emptyTableMessage('No bowling data available.')
          else
            ...rows.map(_bowlingRow),
        ],
      ),
    );
  }

  Widget _bowlingRow(
    PlayerMatchPerformanceModel performance,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFEEF1F4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _tablePlayerName(
              _playerName(performance.playerId),
            ),
          ),
          _tableValue(_formatOvers(performance.overs)),
          _tableValue('${performance.maidens}'),
          _tableValue('${performance.runsConceded}'),
          _tableValue('${performance.wickets}'),
          _tableValue(performance.economy.toStringAsFixed(2)),
          _tableValue('${performance.wides}'),
          _tableValue('${performance.noBalls}'),
        ],
      ),
    );
  }

  Widget _fieldingTable() {
    final rows = _fieldingForMatch();

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _tableHeader([
            'PLAYER',
            'C',
            'C&B',
            'RO',
            'ST',
          ]),
          if (rows.isEmpty)
            _emptyTableMessage('No fielding data available.')
          else
            ...rows.map(_fieldingRow),
        ],
      ),
    );
  }

  Widget _fieldingRow(
    PlayerMatchPerformanceModel performance,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFEEF1F4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _tablePlayerName(
              _playerName(performance.playerId),
            ),
          ),
          _tableValue('${performance.catches}'),
          _tableValue('${performance.caughtAndBowled}'),
          _tableValue('${performance.runOuts}'),
          _tableValue('${performance.stumpings}'),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> labels) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      color: const Color(0xFFF5F7FA),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              flex: i == 0 || labels[i] == 'DISMISSAL' ? 3 : 1,
              child: Text(
                labels[i],
                textAlign: i == 0 || labels[i] == 'DISMISSAL'
                    ? TextAlign.left
                    : TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF7B8794),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tablePlayerName(String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF263238),
        ),
      ),
    );
  }

  Widget _tableValue(String value) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF455A64),
        ),
      ),
    );
  }

  Widget _emptyTableMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF7B8794),
        ),
      ),
    );
  }

  String _formatOvers(double overs) {
    final wholeOvers = overs.floor();
    final fractionalPart = ((overs - wholeOvers) * 10).round();

    return '$wholeOvers.$fractionalPart';
  }

  Widget _teamSection({
    required String title,
    required String teamId,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        child,
      ],
    );
  }

  Widget _content() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to load match performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB71C1C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7B8794),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadPerformances();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _matchHeader(),
        const SizedBox(height: 18),
        _sectionTitle('Match Information'),
        _matchInformation(),
        const SizedBox(height: 28),
        _teamSection(
          title: '${_teamName(widget.match.team1Id)} — Batting',
          teamId: widget.match.team1Id,
          child: _battingTable(widget.match.team1Id),
        ),
        const SizedBox(height: 24),
        _teamSection(
          title: '${_teamName(widget.match.team2Id)} — Batting',
          teamId: widget.match.team2Id,
          child: _battingTable(widget.match.team2Id),
        ),
        const SizedBox(height: 28),
        _teamSection(
          title: '${_teamName(widget.match.team1Id)} — Bowling',
          teamId: widget.match.team1Id,
          child: _bowlingTable(widget.match.team1Id),
        ),
        const SizedBox(height: 24),
        _teamSection(
          title: '${_teamName(widget.match.team2Id)} — Bowling',
          teamId: widget.match.team2Id,
          child: _bowlingTable(widget.match.team2Id),
        ),
        const SizedBox(height: 28),
        _sectionTitle(
          'Fielding',
          subtitle: 'All fielding contributions recorded in this match.',
        ),
        _fieldingTable(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Match Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF17202A),
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF263238),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding =
              constraints.maxWidth < 700 ? 16.0 : 30.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: _content(),
              ),
            ),
          );
        },
      ),
    );
  }
}
