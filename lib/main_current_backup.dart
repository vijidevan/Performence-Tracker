import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'repositories/team_repository.dart';
import 'repositories/match_repository.dart';
import 'repositories/player_repository.dart';
import 'repositories/player_team_repository.dart';
import 'models/team_model.dart';
import 'models/match_model.dart';
import 'models/player_model.dart';
import 'services/stumps_import_service.dart';
import 'package:file_picker/file_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TeamPerformanceApp());
}

class TeamPerformanceApp extends StatelessWidget {
  const TeamPerformanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Performance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const AuthGate(),
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return UserRoleLoader(user: user);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSigningIn = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Sign-in failed. Please check your credentials.';

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Invalid email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many sign-in attempts. Please try again later.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
      }

      if (mounted) {
        setState(() {
          _isSigningIn = false;
          _errorMessage = message;
        });
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
          _errorMessage = 'Sign-in failed: $e';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 34, 30, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.sports_cricket_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Team Performance',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17202A),
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7B8794),
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username, AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _signIn(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: const Color(0xFFF0C2C2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFC62828),
                                size: 20,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF8B1E1E),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSigningIn ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSigningIn
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserRoleLoader extends StatelessWidget {
  final User user;

  const UserRoleLoader({super.key, required this.user});

  Future<bool> _isAdmin() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = snapshot.data();
    return data?['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 52,
                      color: Color(0xFFC62828),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Unable to load your access role.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Return to Sign In'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return DashboardPage(isAdmin: snapshot.data ?? false);
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  final bool isAdmin;

  const DashboardPage({super.key, required this.isAdmin});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  late final bool isAdmin;

  String selectedTeam = 'All Teams';

  String selectedAnalysisMonth = 'All Months';

  String selectedTopPerformersMonth = 'All Time';

  List<TeamModel> firestoreTeams = [];

  bool isLoadingTeams = true;

  String? teamLoadError;

  bool isImportingStumps = false;
  String? stumpsImportMessage;
  bool stumpsImportSuccess = false;

  bool isLoadingMatches = false;
  String? matchLoadError;
  List<MatchModel> firestoreMatches = [];
  Map<String, TeamModel> matchTeamLookup = {};

  bool isLoadingPlayers = false;
  bool isLoadingBatting = false;
  String? battingLoadError;
  List<Map<String, dynamic>> battingPerformanceRecords = [];
  Map<String, String> battingPlayerNames = {};
  String battingSearchQuery = '';

  bool isLoadingBowling = false;
  String? bowlingLoadError;
  List<Map<String, dynamic>> bowlingPerformanceRecords = [];
  Map<String, String> bowlingPlayerNames = {};
  String bowlingSearchQuery = '';

  bool isLoadingFielding = false;
  String? fieldingLoadError;
  List<Map<String, dynamic>> fieldingPerformanceRecords = [];
  Map<String, String> fieldingPlayerNames = {};
  String fieldingSearchQuery = '';

  String? playerLoadError;
  List<PlayerModel> firestorePlayers = [];
  Map<String, List<String>> playerTeamIds = {};
  Map<String, List<String>> playerTeamNames = {};
  String playerSearchQuery = '';

  final TeamRepository _teamRepository = TeamRepository();
  final MatchRepository _matchRepository = MatchRepository();
  final PlayerRepository _playerRepository = PlayerRepository();
  final PlayerTeamRepository _playerTeamRepository =
      PlayerTeamRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<_NavigationItem> get navigationItems => [
    const _NavigationItem(Icons.dashboard_rounded, 'Dashboard'),
    const _NavigationItem(Icons.people_alt_rounded, 'Players'),
    const _NavigationItem(Icons.sports_cricket_rounded, 'Matches'),
    const _NavigationItem(Icons.sports_score_rounded, 'Batting'),
    const _NavigationItem(Icons.sports_baseball_rounded, 'Bowling'),
    const _NavigationItem(Icons.back_hand_rounded, 'Fielding'),
    const _NavigationItem(Icons.emoji_events_rounded, 'Top Performers'),
    const _NavigationItem(Icons.calendar_month_rounded, 'Monthly Analysis'),
    if (isAdmin)
      const _NavigationItem(Icons.picture_as_pdf_rounded, 'STUMPS Import'),
    const _NavigationItem(Icons.settings_rounded, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    isAdmin = widget.isAdmin;
    _loadTeams();
    _loadMatches();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    if (mounted) {
      setState(() {
        isLoadingPlayers = true;
        playerLoadError = null;
      });
    }

    try {
      final players = await _playerRepository.getAllPlayers();

      final idsByPlayer = <String, List<String>>{};
      final namesByPlayer = <String, List<String>>{};
      final allTeamIds = <String>{};

      // Only expose relationships belonging to active/registered teams.
      // STUMPS opponents are intentionally created as inactive teams, so
      // their players must not appear in the Players module.
      for (final player in players) {
        final relationships =
            await _playerTeamRepository.getTeamsForPlayer(player.id);

        final teamIds = relationships
            .map((relationship) => relationship.teamId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        idsByPlayer[player.id] = teamIds;
        allTeamIds.addAll(teamIds);
      }

      final teamLookup = <String, TeamModel>{};

      for (final teamId in allTeamIds) {
        final team = await _teamRepository.getTeam(teamId);

        if (team != null && team.active) {
          teamLookup[teamId] = team;
        }
      }

      final activePlayerIds = <String>{};

      for (final player in players) {
        final activeIds = (idsByPlayer[player.id] ?? <String>[])
            .where(teamLookup.containsKey)
            .toList();

        idsByPlayer[player.id] = activeIds;

        namesByPlayer[player.id] = activeIds
            .map((teamId) => teamLookup[teamId]!.name)
            .where((name) => name.isNotEmpty)
            .toList();

        if (activeIds.isNotEmpty) {
          activePlayerIds.add(player.id);
        }
      }

      final filteredPlayers = players
          .where((player) => activePlayerIds.contains(player.id))
          .toList();

      filteredPlayers.sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        firestorePlayers = filteredPlayers;
        playerTeamIds = idsByPlayer;
        playerTeamNames = namesByPlayer;
        isLoadingPlayers = false;
        playerLoadError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingPlayers = false;
        playerLoadError = e.toString();
      });
    }
  }

  Future<void> _loadBattingPerformance() async {
    if (mounted) {
      setState(() {
        isLoadingBatting = true;
        battingLoadError = null;
      });
    }

    try {
      final snapshot = await _firestore
          .collection('player_match_performances')
          .get();

      final records = snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .where((record) => (record['playerId'] ?? '').toString().isNotEmpty)
          .toList();

      final activeTeamIds = firestoreTeams
          .where((team) => team.active)
          .map((team) => team.id)
          .toSet();

      final filteredRecords = records.where((record) {
        final teamId = (record['teamId'] ?? '').toString();
        return activeTeamIds.contains(teamId);
      }).toList();

      final players = await _playerRepository.getAllPlayers();
      final names = <String, String>{
        for (final player in players) player.id: player.name,
      };

      if (!mounted) {
        return;
      }

      setState(() {
        battingPerformanceRecords = filteredRecords;
        battingPlayerNames = names;
        isLoadingBatting = false;
        battingLoadError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingBatting = false;
        battingLoadError = e.toString();
      });
    }
  }

  Future<void> _loadBowlingPerformance() async {
    if (mounted) {
      setState(() {
        isLoadingBowling = true;
        bowlingLoadError = null;
      });
    }

    try {
      final snapshot = await _firestore
          .collection('player_match_performances')
          .get();

      final activeTeamIds = firestoreTeams
          .where((team) => team.active)
          .map((team) => team.id)
          .toSet();

      final records = snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .where((record) {
            final playerId = (record['playerId'] ?? '').toString();
            final teamId = (record['teamId'] ?? '').toString();
            return playerId.isNotEmpty && activeTeamIds.contains(teamId);
          })
          .toList();

      final players = await _playerRepository.getAllPlayers();
      final names = <String, String>{
        for (final player in players) player.id: player.name,
      };

      if (!mounted) return;

      setState(() {
        bowlingPerformanceRecords = records;
        bowlingPlayerNames = names;
        isLoadingBowling = false;
        bowlingLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingBowling = false;
        bowlingLoadError = e.toString();
      });
    }
  }

  Future<void> _loadMatches() async {
    if (mounted) {
      setState(() {
        isLoadingMatches = true;
        matchLoadError = null;
      });
    }

    try {
      final matches = await _matchRepository.getAllMatches();

      matches.sort(
        (a, b) => b.matchDate.compareTo(a.matchDate),
      );

      final teamIds = <String>{
        for (final match in matches) ...[
          match.team1Id,
          match.team2Id,
        ],
      };

      final lookup = <String, TeamModel>{};

      for (final teamId in teamIds) {
        if (teamId.isEmpty) {
          continue;
        }

        final team = await _teamRepository.getTeam(teamId);

        if (team != null) {
          lookup[teamId] = team;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        firestoreMatches = matches;
        matchTeamLookup = lookup;
        isLoadingMatches = false;
        matchLoadError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingMatches = false;
        matchLoadError = e.toString();
      });
    }
  }

  Future<void> _loadTeams() async {
    debugPrint('');
    debugPrint('==========================================');
    debugPrint('TEAM FIRESTORE LOAD START');
    debugPrint('==========================================');
    debugPrint('Project: team-performance-2026');
    debugPrint('Collection: teams');
    debugPrint('Calling TeamRepository.getAllTeams()...');

    try {
      final teams = await _teamRepository.getAllTeams();

      debugPrint('------------------------------------------');
      debugPrint('TEAM FIRESTORE LOAD SUCCESS');
      debugPrint('Teams returned: ${teams.length}');

      for (final team in teams) {
        debugPrint(
          'TEAM -> id: ${team.id}, name: ${team.name}, active: ${team.active}',
        );
      }

      debugPrint('==========================================');
      debugPrint('');

      teams.sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        firestoreTeams = teams;
        isLoadingTeams = false;
        teamLoadError = null;
      });

      await _loadBattingPerformance();
      await _loadBowlingPerformance();
      await _loadFieldingPerformance();
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('==========================================');
      debugPrint('TEAM FIRESTORE LOAD ERROR');
      debugPrint('==========================================');
      debugPrint('ERROR TYPE: ${e.runtimeType}');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE:');
      debugPrint('$stackTrace');
      debugPrint('==========================================');
      debugPrint('');

      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingTeams = false;
        teamLoadError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = navigationItems[selectedIndex];

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(selectedItem.title),
                Expanded(
                  child: _buildPageContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0D1B2A),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_cricket_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEAM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'PERFORMANCE',
                        style: TextStyle(
                          color: Color(0xFF90CAF9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navigationItems.length,
              itemBuilder: (context, index) {
                final item = navigationItems[index];
                final selected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1565C0)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF9EADBC),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFFB8C4D0),
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF172A3A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Team Performance',
                        style: TextStyle(
                          color: Color(0xFF8798A8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String pageTitle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        return Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFE5E9EF),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  pageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17202A),
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 20),
                Container(
                  width: 230,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: const Color(0xFFE1E6EC),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 12),
                      Icon(
                        Icons.search_rounded,
                        size: 19,
                        color: Color(0xFF8995A3),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Search players...',
                        style: TextStyle(
                          color: Color(0xFF9AA5B1),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF536170),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 1,
                  height: 30,
                  color: const Color(0xFFE1E6EC),
                ),
                const SizedBox(width: 15),
                const CircleAvatar(
                  radius: 19,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF1565C0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isAdmin ? 'Admin' : 'Read Only',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF536170),
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageContent() {
    final title = navigationItems[selectedIndex].title;

    switch (title) {
      case 'Dashboard':
        return _buildDashboard();
      case 'Players':
        return _buildPlayersPage();
      case 'Matches':
        return _buildMatchesPage();
      case 'Batting':
        return _buildBattingPage();
      case 'Bowling':
        return _buildBowlingPage();
      case 'Fielding':
        return _buildFieldingPage();
      case 'Top Performers':
        return _buildTopPerformersPage();
      case 'Monthly Analysis':
        return _buildMonthlyAnalysisPage();
      case 'STUMPS Import':
        return _buildStumpsImportPage();
      case 'Settings':
        return _buildSettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSettingsPage() {
    final activeTeams = firestoreTeams.where((team) => team.active).toList();
    final inactiveTeams = firestoreTeams.where((team) => !team.active).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17202A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Signed in as Administrator — PDF import and data management are enabled.'
                : 'Signed in as Read Only — analytics and data viewing are enabled.',
            style: const TextStyle(
              color: Color(0xFF7B8794),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage application configuration and view the current data setup.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7B8794),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 900;
              final cards = [
                _settingsSection(
                  icon: Icons.groups_rounded,
                  title: 'Team Management',
                  subtitle: 'Registered teams used by analytics and filters.',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _settingsStat(
                            icon: Icons.verified_rounded,
                            label: 'Active Teams',
                            value: activeTeams.length.toString(),
                          ),
                          const SizedBox(width: 12),
                          _settingsStat(
                            icon: Icons.visibility_off_rounded,
                            label: 'Inactive Teams',
                            value: inactiveTeams.length.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isLoadingTeams)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (firestoreTeams.isEmpty)
                        _settingsEmpty('No teams found in Firestore.')
                      else
                        ...firestoreTeams.map(
                          (team) => _settingsTeamRow(team),
                        ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: isLoadingTeams ? null : _loadTeams,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh Teams'),
                        ),
                      ),
                    ],
                  ),
                ),
                _settingsSection(
                  icon: Icons.cloud_done_rounded,
                  title: 'Data & Storage',
                  subtitle: 'Current data sources used by Team Performance.',
                  child: Column(
                    children: [
                      _settingsInfoRow(
                        Icons.cloud_rounded,
                        'Primary Database',
                        'Firebase Firestore',
                      ),
                      _settingsInfoRow(
                        Icons.picture_as_pdf_rounded,
                        'Match Data Source',
                        'STUMPS PDF reports',
                      ),
                      _settingsInfoRow(
                        Icons.sync_rounded,
                        'Analytics',
                        'Calculated from imported match performances',
                      ),
                      _settingsInfoRow(
                        Icons.security_rounded,
                        'Data Scope',
                        'Active teams for analytics; opponents remain inactive',
                      ),
                    ],
                  ),
                ),
                _settingsSection(
                  icon: Icons.tune_rounded,
                  title: 'Application',
                  subtitle: 'General application information.',
                  child: Column(
                    children: [
                      _settingsInfoRow(
                        Icons.sports_cricket_rounded,
                        'Application',
                        'Team Performance',
                      ),
                      _settingsInfoRow(
                        Icons.language_rounded,
                        'Platform',
                        'Flutter Web',
                      ),
                      _settingsInfoRow(
                        Icons.analytics_rounded,
                        'Analytics Modules',
                        'Batting, Bowling, Fielding, Top Performers, Monthly Analysis',
                      ),
                      _settingsInfoRow(
                        Icons.picture_as_pdf_rounded,
                        'Import Protection',
                        'STUMPS Match ID prevents duplicate imports',
                      ),
                    ],
                  ),
                ),
                _settingsSection(
                  icon: Icons.info_outline_rounded,
                  title: 'System Information',
                  subtitle: 'Current Firebase environment.',
                  child: Column(
                    children: [
                      _settingsInfoRow(
                        Icons.folder_special_rounded,
                        'Firebase Project',
                        'team-performance-2026',
                      ),
                      _settingsInfoRow(
                        Icons.storage_rounded,
                        'Firestore Database',
                        '(default)',
                      ),
                      _settingsInfoRow(
                        Icons.public_rounded,
                        'Region',
                        'asia-south1',
                      ),
                    ],
                  ),
                ),
              ];

              if (!twoColumns) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: (constraints.maxWidth - 18) / 2,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1565C0),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Color(0xFF8A96A3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _settingsStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE7EBF0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: const Color(0xFF1565C0)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8A96A3),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF263238),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTeamRow(TeamModel team) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Row(
          children: [
            Icon(
              team.active
                  ? Icons.check_circle_rounded
                  : Icons.remove_circle_outline_rounded,
              size: 19,
              color: team.active
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF9AA5B1),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                team.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: team.active
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                team.active ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: team.active
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF7B8794),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7C8F)),
          const SizedBox(width: 10),
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7B8794),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF7B8794),
        ),
      ),
    );
  }

  Future<void> _loadFieldingPerformance() async {
    if (mounted) {
      setState(() {
        isLoadingFielding = true;
        fieldingLoadError = null;
      });
    }

    try {
      final snapshot = await _firestore
          .collection('player_match_performances')
          .get();

      final activeTeamIds = firestoreTeams
          .where((team) => team.active)
          .map((team) => team.id)
          .toSet();

      final records = snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .where((record) {
            final playerId = (record['playerId'] ?? '').toString();
            final teamId = (record['teamId'] ?? '').toString();
            return playerId.isNotEmpty && activeTeamIds.contains(teamId);
          })
          .toList();

      final players = await _playerRepository.getAllPlayers();
      final names = <String, String>{
        for (final player in players) player.id: player.name,
      };

      if (!mounted) return;

      setState(() {
        fieldingPerformanceRecords = records;
        fieldingPlayerNames = names;
        isLoadingFielding = false;
        fieldingLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingFielding = false;
        fieldingLoadError = e.toString();
      });
    }
  }


  Widget _buildTopPerformersPage() {
    if (isLoadingBatting || isLoadingBowling || isLoadingFielding) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeTeamNames = firestoreTeams
        .where((team) => team.active)
        .map((team) => team.name)
        .toList();

    final teamOptions = ['All Teams', ...activeTeamNames];
    final currentTeam =
        teamOptions.contains(selectedTeam) ? selectedTeam : 'All Teams';

    final monthOptions = _topPerformersMonthOptions();
    final currentMonth = monthOptions.contains(selectedTopPerformersMonth)
        ? selectedTopPerformersMonth
        : 'All Time';

    final batting = _topBattingPerformers(currentTeam, currentMonth);
    final bowling = _topBowlingPerformers(currentTeam, currentMonth);
    final fielding = _topFieldingPerformers(currentTeam, currentMonth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final heading = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Performers',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17202A),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Top 3 performers from the imported match performance data.',
                    style: TextStyle(
                      color: Color(0xFF7B8794),
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTopPerformersPeriodFilter(currentMonth, monthOptions),
                        const SizedBox(width: 10),
                        _buildTopPerformersTeamFilter(currentTeam, teamOptions),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 20),
                  _buildTopPerformersPeriodFilter(currentMonth, monthOptions),
                  const SizedBox(width: 10),
                  _buildTopPerformersTeamFilter(currentTeam, teamOptions),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _buildTopPerformersCategory(
                      title: 'Batting',
                      subtitle: 'Highest run scorers',
                      icon: Icons.sports_cricket_rounded,
                      rows: batting,
                      primaryLabel: 'Runs',
                      secondaryLabel: 'SR',
                    ),
                    const SizedBox(height: 18),
                    _buildTopPerformersCategory(
                      title: 'Bowling',
                      subtitle: 'Highest wicket takers',
                      icon: Icons.sports_baseball_rounded,
                      rows: bowling,
                      primaryLabel: 'Wickets',
                      secondaryLabel: 'Economy',
                    ),
                    const SizedBox(height: 18),
                    _buildTopPerformersCategory(
                      title: 'Fielding',
                      subtitle: 'Most dismissals',
                      icon: Icons.back_hand_rounded,
                      rows: fielding,
                      primaryLabel: 'Dismissals',
                      secondaryLabel: 'Catches',
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTopPerformersCategory(
                      title: 'Batting',
                      subtitle: 'Highest run scorers',
                      icon: Icons.sports_cricket_rounded,
                      rows: batting,
                      primaryLabel: 'Runs',
                      secondaryLabel: 'SR',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTopPerformersCategory(
                      title: 'Bowling',
                      subtitle: 'Highest wicket takers',
                      icon: Icons.sports_baseball_rounded,
                      rows: bowling,
                      primaryLabel: 'Wickets',
                      secondaryLabel: 'Economy',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTopPerformersCategory(
                      title: 'Fielding',
                      subtitle: 'Most dismissals',
                      icon: Icons.back_hand_rounded,
                      rows: fielding,
                      primaryLabel: 'Dismissals',
                      secondaryLabel: 'Catches',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersTeamFilter(
    String currentTeam,
    List<String> teamOptions,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE1E6EC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentTeam,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: teamOptions
              .map(
                (team) => DropdownMenuItem<String>(
                  value: team,
                  child: Text(
                    team,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedTeam = value);
          },
        ),
      ),
    );
  }

  List<String> _topPerformersMonthOptions() {
    final months = <DateTime>{};

    for (final match in firestoreMatches) {
      months.add(DateTime(match.matchDate.year, match.matchDate.month));
    }

    final sortedMonths = months.toList()
      ..sort((a, b) => b.compareTo(a));

    return [
      'All Time',
      ...sortedMonths.map(_formatTopPerformersMonth),
    ];
  }

  String _formatTopPerformersMonth(DateTime month) {
    const monthNames = [
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

    return '${monthNames[month.month - 1]} ${month.year}';
  }

  bool _topRecordMatchesMonth(
    Map<String, dynamic> record,
    String month,
  ) {
    if (month == 'All Time') return true;

    final matchId = (record['matchId'] ?? '').toString();
    if (matchId.isEmpty) return false;

    MatchModel? match;
    for (final item in firestoreMatches) {
      if (item.id == matchId) {
        match = item;
        break;
      }
    }

    if (match == null) return false;

    return _formatTopPerformersMonth(match.matchDate) == month;
  }

  Widget _buildTopPerformersPeriodFilter(
    String currentMonth,
    List<String> monthOptions,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE1E6EC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentMonth,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: monthOptions
              .map(
                (month) => DropdownMenuItem<String>(
                  value: month,
                  child: Text(
                    month == 'All Time' ? 'All' : month,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedTopPerformersMonth = value);
          },
        ),
      ),
    );
  }

  List<_TopPerformerRowData> _topBattingPerformers(
    String teamName,
    String month,
  ) {
    final rows = <String, _TopPerformerRowData>{};

    for (final record in battingPerformanceRecords) {
      final teamId = (record['teamId'] ?? '').toString();
      final team = _activeTeamById(teamId);
      if (team == null) continue;
      if (teamName != 'All Teams' && team.name != teamName) continue;
      if (!_topRecordMatchesMonth(record, month)) continue;

      final playerId = (record['playerId'] ?? '').toString();
      if (playerId.isEmpty) continue;

      final playerName = battingPlayerNames[playerId] ?? playerId;

      // Aggregate by player, not by player + team.
      // This keeps Top Performers consistent with the Batting screen,
      // where a player's performances across active teams are combined
      // when "All Teams" is selected.
      final row = rows.putIfAbsent(
        playerId,
        () => _TopPerformerRowData(
          playerName: playerName,
          teamName: team.name,
        ),
      );

      if (teamName == 'All Teams' &&
          !row.teamName
              .split(', ')
              .contains(team.name)) {
        row.teamName = '${row.teamName}, ${team.name}';
      }

      row.innings++;
      row.primaryValue += _topInt(record['runs']);
      row.balls += _topInt(record['ballsFaced']);
    }

    final result = rows.values.toList();

    for (final row in result) {
      row.secondaryValue =
          row.balls == 0 ? 0 : row.primaryValue * 100 / row.balls;
    }

    result.sort((a, b) {
      final primary = b.primaryValue.compareTo(a.primaryValue);
      if (primary != 0) return primary;
      return b.secondaryValue.compareTo(a.secondaryValue);
    });

    return result.take(3).toList();
  }

  List<_TopPerformerRowData> _topBowlingPerformers(
    String teamName,
    String month,
  ) {
    final rows = <String, _TopPerformerRowData>{};

    for (final record in bowlingPerformanceRecords) {
      final teamId = (record['teamId'] ?? '').toString();
      final team = _activeTeamById(teamId);
      if (team == null) continue;
      if (teamName != 'All Teams' && team.name != teamName) continue;
      if (!_topRecordMatchesMonth(record, month)) continue;

      final playerId = (record['playerId'] ?? '').toString();
      if (playerId.isEmpty) continue;

      final playerName = bowlingPlayerNames[playerId] ?? playerId;

      // Aggregate by player, not by player + team.
      final row = rows.putIfAbsent(
        playerId,
        () => _TopPerformerRowData(
          playerName: playerName,
          teamName: team.name,
        ),
      );

      if (teamName == 'All Teams' &&
          !row.teamName
              .split(', ')
              .contains(team.name)) {
        row.teamName = '${row.teamName}, ${team.name}';
      }

      row.innings++;
      row.primaryValue += _topInt(record['wickets']);
      row.secondaryRuns += _topInt(record['runsConceded']);
      row.secondaryBalls += _topBowlingBalls(record['overs']);
    }

    final result = rows.values.toList();

    for (final row in result) {
      row.secondaryValue = row.secondaryBalls == 0
          ? 0
          : row.secondaryRuns * 6 / row.secondaryBalls;
    }

    result.sort((a, b) {
      final wickets = b.primaryValue.compareTo(a.primaryValue);
      if (wickets != 0) return wickets;

      final economy = a.secondaryValue.compareTo(b.secondaryValue);
      if (economy != 0) return economy;

      return b.secondaryBalls.compareTo(a.secondaryBalls);
    });

    return result.take(3).toList();
  }

  List<_TopPerformerRowData> _topFieldingPerformers(
    String teamName,
    String month,
  ) {
    final rows = <String, _TopPerformerRowData>{};

    for (final record in fieldingPerformanceRecords) {
      final teamId = (record['teamId'] ?? '').toString();
      final team = _activeTeamById(teamId);
      if (team == null) continue;
      if (teamName != 'All Teams' && team.name != teamName) continue;
      if (!_topRecordMatchesMonth(record, month)) continue;

      final playerId = (record['playerId'] ?? '').toString();
      if (playerId.isEmpty) continue;

      final playerName = fieldingPlayerNames[playerId] ?? playerId;

      // Aggregate by player, not by player + team.
      final row = rows.putIfAbsent(
        playerId,
        () => _TopPerformerRowData(
          playerName: playerName,
          teamName: team.name,
        ),
      );

      if (teamName == 'All Teams' &&
          !row.teamName
              .split(', ')
              .contains(team.name)) {
        row.teamName = '${row.teamName}, ${team.name}';
      }

      row.innings++;
      row.primaryValue +=
          _topInt(record['catches']) +
          _topInt(record['caughtAndBowled']) +
          _topInt(record['runOuts']) +
          _topInt(record['stumpings']);
      row.secondaryRuns += _topInt(record['catches']);
    }

    final result = rows.values.toList();

    result.sort((a, b) {
      final dismissals = b.primaryValue.compareTo(a.primaryValue);
      if (dismissals != 0) return dismissals;

      return b.secondaryRuns.compareTo(a.secondaryRuns);
    });

    return result.take(3).toList();
  }

  TeamModel? _activeTeamById(String teamId) {
    for (final team in firestoreTeams) {
      if (team.id == teamId && team.active) return team;
    }
    return null;
  }

  int _topInt(dynamic value) => (value as num?)?.toInt() ?? 0;

  int _topBowlingBalls(dynamic value) {
    final overs = (value as num?)?.toDouble() ?? 0;
    final completed = overs.floor();
    final partial = ((overs - completed) * 10).round();
    return completed * 6 + partial;
  }

  Widget _buildTopPerformersCategory({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_TopPerformerRowData> rows,
    required String primaryLabel,
    required String secondaryLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FB),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFF1565C0), size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A96A3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No performance data yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A96A3),
                  ),
                ),
              ),
            )
          else
            ...rows.asMap().entries.map(
              (entry) => _buildTopPerformerRow(
                entry.value,
                entry.key + 1,
                primaryLabel,
                secondaryLabel,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopPerformerRow(
    _TopPerformerRowData row,
    int position,
    String primaryLabel,
    String secondaryLabel,
  ) {
    final secondaryText = secondaryLabel == 'SR'
        ? row.secondaryValue.toStringAsFixed(1)
        : secondaryLabel == 'Economy'
            ? row.secondaryValue.toStringAsFixed(2)
            : '${row.secondaryRuns}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Row(
        children: [
          _rankBadge(position),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A96A3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$primaryLabel: ${row.primaryValue}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$secondaryLabel: $secondaryText',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF7B8794),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildPlayersPage() {
    if (isLoadingPlayers) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (playerLoadError != null) {
      return _buildPlayersErrorState();
    }

    final selectedTeamId = _selectedActiveTeamId();

    final activeTeamIds = firestoreTeams
        .where((team) => team.active)
        .map((team) => team.id)
        .toSet();

    final filteredPlayers = firestorePlayers.where((player) {
      final query = playerSearchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          player.name.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      final playerActiveTeamIds =
          (playerTeamIds[player.id] ?? <String>[])
              .where(activeTeamIds.contains)
              .toSet();

      if (playerActiveTeamIds.isEmpty) {
        return false;
      }

      if (selectedTeamId == null) {
        return true;
      }

      return playerActiveTeamIds.contains(selectedTeamId);
    }).toList();

    final teamCount = filteredPlayers
        .expand(
          (player) => playerTeamIds[player.id] ?? <String>[],
        )
        .toSet()
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 800;

              final titleBlock = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Players',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17202A),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'View players imported from STUMPS reports and their team relationships.',
                    style: TextStyle(
                      color: Color(0xFF7B8794),
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 18),
                    _buildPlayersControls(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 20),
                  _buildPlayersControls(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    _playerSummaryCard(
                      icon: Icons.people_alt_rounded,
                      title: 'Players',
                      value: '${filteredPlayers.length}',
                      subtitle: 'Matching players',
                    ),
                    const SizedBox(height: 14),
                    _playerSummaryCard(
                      icon: Icons.groups_rounded,
                      title: 'Teams',
                      value: '$teamCount',
                      subtitle: 'Teams represented',
                    ),
                    const SizedBox(height: 14),
                    _playerSummaryCard(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Active',
                      value: '${filteredPlayers.where((p) => p.active).length}',
                      subtitle: 'Active players',
                    ),
                  ],
                );
              }

              final cardWidth = (constraints.maxWidth - 32) / 3;

              return Row(
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _playerSummaryCard(
                      icon: Icons.people_alt_rounded,
                      title: 'Players',
                      value: '${filteredPlayers.length}',
                      subtitle: 'Matching players',
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: cardWidth,
                    child: _playerSummaryCard(
                      icon: Icons.groups_rounded,
                      title: 'Teams',
                      value: '$teamCount',
                      subtitle: 'Teams represented',
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: cardWidth,
                    child: _playerSummaryCard(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Active',
                      value: '${filteredPlayers.where((p) => p.active).length}',
                      subtitle: 'Active players',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (filteredPlayers.isEmpty)
            _buildEmptyPlayersState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 700
                        ? 2
                        : 1;

                if (columns == 1) {
                  return Column(
                    children: filteredPlayers
                        .map(_buildPlayerCard)
                        .toList(),
                  );
                }

                final rows = <Widget>[];

                for (var i = 0;
                    i < filteredPlayers.length;
                    i += columns) {
                  final rowPlayers = filteredPlayers
                      .skip(i)
                      .take(columns)
                      .toList();

                  rows.add(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var index = 0;
                            index < columns;
                            index++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < columns - 1 ? 8 : 0,
                                left: index > 0 ? 8 : 0,
                              ),
                              child: index < rowPlayers.length
                                  ? _buildPlayerCard(
                                      rowPlayers[index],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                      ],
                    ),
                  );

                  if (i + columns < filteredPlayers.length) {
                    rows.add(const SizedBox(height: 16));
                  }
                }

                return Column(children: rows);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlayersControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        final search = SizedBox(
          width: compact ? double.infinity : 230,
          height: 42,
          child: TextField(
            onChanged: (value) {
              setState(() {
                playerSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search players...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 19,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFFE1E6EC),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFFE1E6EC),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ),
        );

        final filter = _buildPlayersTeamFilter();

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              search,
              const SizedBox(height: 12),
              filter,
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            search,
            const SizedBox(width: 12),
            filter,
          ],
        );
      },
    );
  }

  Widget _buildPlayersTeamFilter() {
    final teamNames = [
      'All Teams',
      ...firestoreTeams
          .where((team) => team.active)
          .map((team) => team.name),
    ];

    if (!teamNames.contains(selectedTeam)) {
      selectedTeam = 'All Teams';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE1E6EC),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTeam,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
          ),
          items: teamNames.map((team) {
            return DropdownMenuItem<String>(
              value: team,
              child: Text(
                team,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              selectedTeam = value;
            });
          },
        ),
      ),
    );
  }

  String? _selectedActiveTeamId() {
    if (selectedTeam == 'All Teams') {
      return null;
    }

    for (final team in firestoreTeams) {
      if (team.active && team.name == selectedTeam) {
        return team.id;
      }
    }

    return null;
  }

  Widget _playerSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E8ED),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7B8794),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17202A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9AA5B1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerModel player) {
    final teams = playerTeamNames[player.id] ?? <String>[];

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _PlayerDetailsPage(
              player: player,
              teamNames: teams,
              firestore: _firestore,
              teamRepository: _teamRepository,
              matchRepository: _matchRepository,
              activeTeamIds: firestoreTeams
                  .where((team) => team.active)
                  .map((team) => team.id)
                  .toSet(),
            ),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8F1FB),
                child: Text(
                  _playerInitials(player.name),
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.active ? 'Active player' : 'Inactive player',
                      style: TextStyle(
                        fontSize: 11,
                        color: player.active
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF8A96A3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'TEAMS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Color(0xFF9AA5B1),
            ),
          ),
          const SizedBox(height: 8),
          if (teams.isEmpty)
            const Text(
              'No team relationship found',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9AA5B1),
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: teams.map((team) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: const Color(0xFFE1E6EC),
                    ),
                  ),
                  child: Text(
                    team,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF596775),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFEEF1F4),
                ),
              ),
            ),
            child: Text(
              'Added ${_formatPlayerDate(player.createdAt)}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _playerInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(
        0,
        parts.first.length >= 2 ? 2 : 1,
      ).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatPlayerDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Widget _buildEmptyPlayersState() {
    return _whiteCard(
      title: 'No players found',
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 35),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_alt_rounded,
                size: 52,
                color: Color(0xFFB0BAC5),
              ),
              SizedBox(height: 14),
              Text(
                'No players match the current filters.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7B8794),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: _whiteCard(
          title: 'Unable to load players',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerLoadError ?? 'Unknown error',
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPlayers,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFieldingPage() {
    if (isLoadingFielding) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fieldingLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: _whiteCard(
            title: 'Unable to load fielding statistics',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fieldingLoadError!,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadFieldingPerformance,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rows = _fieldingRows();
    final totalCatches = rows.fold<int>(0, (sum, row) => sum + row.catches);
    final totalCaughtAndBowled = rows.fold<int>(
      0,
      (sum, row) => sum + row.caughtAndBowled,
    );
    final totalRunOuts = rows.fold<int>(0, (sum, row) => sum + row.runOuts);
    final totalStumpings = rows.fold<int>(0, (sum, row) => sum + row.stumpings);
    final totalDismissals = rows.fold<int>(0, (sum, row) => sum + row.totalDismissals);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 800;
              const titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fielding Statistics',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17202A),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Analyse catches, run-outs, stumpings and caught-and-bowled dismissals from your active teams only.',
                    style: TextStyle(
                      color: Color(0xFF7B8794),
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 18),
                    _buildFieldingControls(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 20),
                  _buildFieldingControls(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _battingSummaryCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Players',
                  value: '${rows.length}',
                  subtitle: 'Players with fielding records',
                ),
                _battingSummaryCard(
                  icon: Icons.back_hand_rounded,
                  title: 'Catches',
                  value: '$totalCatches',
                  subtitle: 'Catches taken',
                ),
                _battingSummaryCard(
                  icon: Icons.sports_cricket_rounded,
                  title: 'Run Outs',
                  value: '$totalRunOuts',
                  subtitle: 'Run-outs completed',
                ),
                _battingSummaryCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'Dismissals',
                  value: '$totalDismissals',
                  subtitle: 'Total fielding dismissals',
                ),
              ];

              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i < cards.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              final width = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    SizedBox(width: width, child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _whiteCard(
            title: 'Player Fielding Performance',
            trailing: Text(
              '${rows.length} player${rows.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7B8794),
              ),
            ),
            child: rows.isEmpty
                ? _buildEmptyFieldingState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 850) {
                        return Column(
                          children: [
                            for (var i = 0; i < rows.length; i++)
                              _buildFieldingCompactRow(rows[i], i + 1),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _buildFieldingTableHeader(),
                          const Divider(height: 1, color: Color(0xFFEEF1F4)),
                          for (var i = 0; i < rows.length; i++) ...[
                            _buildFieldingTableRow(rows[i], i + 1),
                            if (i < rows.length - 1)
                              const Divider(height: 1, color: Color(0xFFEEF1F4)),
                          ],
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            'Caught & Bowled: $totalCaughtAndBowled • Stumpings: $totalStumpings • Statistics are limited to active teams.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A96A3)),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldingControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final search = SizedBox(
          width: compact ? double.infinity : 230,
          height: 42,
          child: TextField(
            onChanged: (value) => setState(() => fieldingSearchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search fielders...',
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFE1E6EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFE1E6EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF1565C0)),
              ),
            ),
          ),
        );

        final filter = _buildFieldingTeamFilter();
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [search, const SizedBox(height: 12), filter],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [search, const SizedBox(width: 12), filter],
        );
      },
    );
  }

  Widget _buildFieldingTeamFilter() {
    final teamNames = [
      'All Teams',
      ...firestoreTeams.where((team) => team.active).map((team) => team.name),
    ];

    final currentValue = teamNames.contains(selectedTeam)
        ? selectedTeam
        : 'All Teams';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE1E6EC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: teamNames
              .map(
                (team) => DropdownMenuItem<String>(
                  value: team,
                  child: Text(
                    team,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedTeam = value);
          },
        ),
      ),
    );
  }

  List<_FieldingRowData> _fieldingRows() {
    final selectedTeamId = _selectedActiveTeamId();
    final query = fieldingSearchQuery.trim().toLowerCase();
    final grouped = <String, _FieldingRowData>{};

    for (final record in fieldingPerformanceRecords) {
      final playerId = (record['playerId'] ?? '').toString();
      final teamId = (record['teamId'] ?? '').toString();
      if (playerId.isEmpty || teamId.isEmpty) continue;

      final teamMatches = firestoreTeams.where((item) => item.id == teamId);
      if (teamMatches.isEmpty) continue;
      final team = teamMatches.first;
      if (!team.active) continue;
      if (selectedTeamId != null && teamId != selectedTeamId) continue;

      final playerName = fieldingPlayerNames[playerId] ?? playerId;
      if (query.isNotEmpty && !playerName.toLowerCase().contains(query)) {
        continue;
      }

      final key = selectedTeamId == null ? playerId : '$playerId|$teamId';
      final existing = grouped[key];

      if (existing == null) {
        grouped[key] = _FieldingRowData(
          playerId: playerId,
          playerName: playerName,
          teamNames: {team.name},
          innings: 1,
          catches: _fieldingInt(record['catches']),
          caughtAndBowled: _fieldingInt(record['caughtAndBowled']),
          runOuts: _fieldingInt(record['runOuts']),
          stumpings: _fieldingInt(record['stumpings']),
        );
      } else {
        existing.innings++;
        existing.catches += _fieldingInt(record['catches']);
        existing.caughtAndBowled += _fieldingInt(record['caughtAndBowled']);
        existing.runOuts += _fieldingInt(record['runOuts']);
        existing.stumpings += _fieldingInt(record['stumpings']);
        existing.teamNames.add(team.name);
      }
    }

    final rows = grouped.values.toList();
    rows.sort((a, b) {
      final dismissals = b.totalDismissals.compareTo(a.totalDismissals);
      if (dismissals != 0) return dismissals;
      final catches = b.catches.compareTo(a.catches);
      if (catches != 0) return catches;
      return a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase());
    });

    return rows;
  }

  int _fieldingInt(dynamic value) => (value as num?)?.toInt() ?? 0;

  Widget _buildEmptyFieldingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.back_hand_outlined,
            size: 42,
            color: Color(0xFF9AA5B1),
          ),
          const SizedBox(height: 12),
          const Text(
            'No fielding data found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Import a completed STUMPS match report to populate fielding statistics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8995A3),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankBadge(int position) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: position <= 3
            ? const Color(0xFFEAF2FF)
            : const Color(0xFFF1F4F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$position',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: position <= 3
              ? const Color(0xFF1565C0)
              : const Color(0xFF7B8794),
        ),
      ),
    );
  }

  Widget _buildFieldingTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Player / Team', style: _FieldingHeaderStyle.textStyle)),
          Expanded(child: Text('Innings', style: _FieldingHeaderStyle.textStyle)),
          Expanded(child: Text('Catches', style: _FieldingHeaderStyle.textStyle)),
          Expanded(child: Text('C&B', style: _FieldingHeaderStyle.textStyle)),
          Expanded(child: Text('Run Outs', style: _FieldingHeaderStyle.textStyle)),
          Expanded(child: Text('Stumpings', style: _FieldingHeaderStyle.textStyle)),
          Expanded(child: Text('Total', style: _FieldingHeaderStyle.textStyle)),
        ],
      ),
    );
  }

  Widget _buildFieldingTableRow(_FieldingRowData row, int position) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _rankBadge(position),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        row.teamNames.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8A96A3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _fieldingValue('${row.innings}')),
          Expanded(child: _fieldingValue('${row.catches}')),
          Expanded(child: _fieldingValue('${row.caughtAndBowled}')),
          Expanded(child: _fieldingValue('${row.runOuts}')),
          Expanded(child: _fieldingValue('${row.stumpings}')),
          Expanded(
            child: Text(
              '${row.totalDismissals}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldingCompactRow(_FieldingRowData row, int position) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _rankBadge(position),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.playerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      row.teamNames.join(', '),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A96A3),
                      ),
                    ),
                  ],
                ),
              ),
              _fieldingTotalBadge(row.totalDismissals),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _fieldingMiniMetric('Innings', '${row.innings}'),
              _fieldingMiniMetric('Catches', '${row.catches}'),
              _fieldingMiniMetric('C&B', '${row.caughtAndBowled}'),
              _fieldingMiniMetric('Run Outs', '${row.runOuts}'),
              _fieldingMiniMetric('Stumpings', '${row.stumpings}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldingValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _fieldingMiniMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E6EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF8A96A3)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldingTotalBadge(int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        'Total $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }


  Widget _buildBowlingPage() {
    if (isLoadingBowling) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bowlingLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: _whiteCard(
            title: 'Unable to load bowling statistics',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bowlingLoadError!,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadBowlingPerformance,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rows = _bowlingRows();
    final totalWickets = rows.fold<int>(0, (sum, row) => sum + row.wickets);
    final totalRuns = rows.fold<int>(0, (sum, row) => sum + row.runsConceded);
    final totalMaidens = rows.fold<int>(0, (sum, row) => sum + row.maidens);
    final totalDots = rows.fold<int>(0, (sum, row) => sum + row.dotBalls);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 800;
              final titleBlock = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bowling Statistics',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17202A),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Analyse bowling performance from your active teams only.',
                    style: TextStyle(
                      color: Color(0xFF7B8794),
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 18),
                    _buildBowlingControls(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bowling Statistics',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17202A),
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Analyse bowling performance from your active teams only.',
                        style: TextStyle(
                          color: Color(0xFF7B8794),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(width: 20),
                  _buildBowlingControls(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _battingSummaryCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Players',
                  value: '${rows.length}',
                  subtitle: 'Bowlers with records',
                ),
                _battingSummaryCard(
                  icon: Icons.sports_baseball_rounded,
                  title: 'Wickets',
                  value: '$totalWickets',
                  subtitle: 'Total wickets',
                ),
                _battingSummaryCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Runs Conceded',
                  value: '$totalRuns',
                  subtitle: 'Runs conceded',
                ),
                _battingSummaryCard(
                  icon: Icons.circle_rounded,
                  title: 'Dot Balls',
                  value: '$totalDots',
                  subtitle: 'Dot balls bowled',
                ),
              ];

              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i < cards.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              final width = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    SizedBox(width: width, child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _whiteCard(
            title: 'Player Bowling Performance',
            trailing: Text(
              '${rows.length} player${rows.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7B8794),
              ),
            ),
            child: rows.isEmpty
                ? _buildEmptyBowlingState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            for (var i = 0; i < rows.length; i++)
                              _buildBowlingCompactRow(rows[i], i + 1),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _buildBowlingTableHeader(),
                          const Divider(height: 1, color: Color(0xFFEEF1F4)),
                          for (var i = 0; i < rows.length; i++) ...[
                            _buildBowlingTableRow(rows[i], i + 1),
                            if (i < rows.length - 1)
                              const Divider(height: 1, color: Color(0xFFEEF1F4)),
                          ],
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            'Maidens: $totalMaidens • Statistics are limited to active teams.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A96A3)),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlingControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final search = SizedBox(
          width: compact ? double.infinity : 230,
          height: 42,
          child: TextField(
            onChanged: (value) => setState(() => bowlingSearchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search bowlers...',
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFE1E6EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFE1E6EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF1565C0)),
              ),
            ),
          ),
        );

        final filter = _buildBowlingTeamFilter();
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [search, const SizedBox(height: 12), filter],
          );
        }
        return Row(mainAxisSize: MainAxisSize.min, children: [
          search,
          const SizedBox(width: 12),
          filter,
        ]);
      },
    );
  }

  Widget _buildBowlingTeamFilter() {
    final teamNames = [
      'All Teams',
      ...firestoreTeams.where((team) => team.active).map((team) => team.name),
    ];

    if (!teamNames.contains(selectedTeam)) {
      selectedTeam = 'All Teams';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE1E6EC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTeam,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: teamNames.map((team) => DropdownMenuItem<String>(
            value: team,
            child: Text(team, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          )).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedTeam = value);
          },
        ),
      ),
    );
  }

  List<_BowlingRowData> _bowlingRows() {
    final selectedTeamId = _selectedActiveTeamId();
    final query = bowlingSearchQuery.trim().toLowerCase();
    final grouped = <String, _BowlingRowData>{};

    for (final record in bowlingPerformanceRecords) {
      final playerId = (record['playerId'] ?? '').toString();
      final teamId = (record['teamId'] ?? '').toString();
      final team = firestoreTeams.where((item) => item.id == teamId).isNotEmpty
          ? firestoreTeams.firstWhere((item) => item.id == teamId)
          : null;
      if (playerId.isEmpty || team == null || !team.active) continue;
      if (selectedTeamId != null && teamId != selectedTeamId) continue;

      final playerName = bowlingPlayerNames[playerId] ?? playerId;
      if (query.isNotEmpty && !playerName.toLowerCase().contains(query)) continue;

      final key = selectedTeamId == null ? playerId : '$playerId|$teamId';
      final existing = grouped[key];
      final balls = _bowlingBallsFromOvers(record['overs']);
      final teamName = team.name;

      if (existing == null) {
        grouped[key] = _BowlingRowData(
          playerId: playerId,
          playerName: playerName,
          teamNames: {teamName},
          innings: 1,
          balls: balls,
          maidens: _bowlingInt(record['maidens']),
          runsConceded: _bowlingInt(record['runsConceded']),
          wickets: _bowlingInt(record['wickets']),
          dotBalls: _bowlingInt(record['dotBalls']),
          wides: _bowlingInt(record['wides']),
          noBalls: _bowlingInt(record['noBalls']),
        );
      } else {
        existing.innings++;
        existing.balls += balls;
        existing.maidens += _bowlingInt(record['maidens']);
        existing.runsConceded += _bowlingInt(record['runsConceded']);
        existing.wickets += _bowlingInt(record['wickets']);
        existing.dotBalls += _bowlingInt(record['dotBalls']);
        existing.wides += _bowlingInt(record['wides']);
        existing.noBalls += _bowlingInt(record['noBalls']);
        existing.teamNames.add(teamName);
      }
    }

    final rows = grouped.values.toList();
    rows.sort((a, b) {
      final wickets = b.wickets.compareTo(a.wickets);
      if (wickets != 0) return wickets;
      final economy = a.economy.compareTo(b.economy);
      if (economy != 0) return economy;
      return a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase());
    });
    return rows;
  }

  int _bowlingInt(dynamic value) => (value as num?)?.toInt() ?? 0;

  int _bowlingBallsFromOvers(dynamic value) {
    final overs = (value as num?)?.toDouble() ?? 0;
    final completed = overs.floor();
    final partial = ((overs - completed) * 10).round();
    return completed * 6 + partial;
  }

  Widget _buildBowlingTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(children: [
        SizedBox(width: 38, child: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8A96A3)))),
        Expanded(flex: 3, child: Text('PLAYER / TEAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8A96A3)))),
        Expanded(child: Text('INN', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8A96A3)))),
        Expanded(child: Text('OVERS', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8A96A3)))),
        Expanded(child: Text('WKTS', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8A96A3)))),
        Expanded(child: Text('RUNS', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8A96A3)))),
        Expanded(child: Text('ECON', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8A96A3)))),
        Expanded(child: Text('DOTS', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8A96A3)))),
      ]),
    );
  }

  Widget _buildBowlingTableRow(_BowlingRowData row, int position) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(children: [
        SizedBox(width: 38, child: Text('$position', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9AA5B1)))),
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(row.playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF263238))),
          const SizedBox(height: 3),
          Text(row.teamNames.join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF8A96A3))),
        ])),
        Expanded(child: Text('${row.innings}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)))),
        Expanded(child: Text(row.overs, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)))),
        Expanded(child: Text('${row.wickets}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF263238)))),
        Expanded(child: Text('${row.runsConceded}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)))),
        Expanded(child: Text(row.economy.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)))),
        Expanded(child: Text('${row.dotBalls}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)))),
      ]),
    );
  }

  Widget _battingMini(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7ED)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A96A3),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlingCompactRow(_BowlingRowData row, int position) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('$position', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9AA5B1))),
          const SizedBox(width: 10),
          Expanded(child: Text(row.playerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF263238)))),
          Text('${row.wickets} wkts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
        ]),
        const SizedBox(height: 5),
        Text(row.teamNames.join(' • '), style: const TextStyle(fontSize: 10, color: Color(0xFF8A96A3))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _battingMini('Inn', '${row.innings}'),
          _battingMini('Overs', row.overs),
          _battingMini('Runs', '${row.runsConceded}'),
          _battingMini('Economy', row.economy.toStringAsFixed(2)),
          _battingMini('Dots', '${row.dotBalls}'),
          _battingMini('M', '${row.maidens}'),
        ]),
      ]),
    );
  }

  Widget _buildEmptyBowlingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 35),
      child: Center(
        child: Column(children: [
          Icon(Icons.sports_baseball_rounded, size: 52, color: Color(0xFFB0BAC5)),
          SizedBox(height: 14),
          Text('No bowling records found for your active teams.', style: TextStyle(fontSize: 14, color: Color(0xFF7B8794))),
        ]),
      ),
    );
  }

  Widget _buildBattingPage() {
    if (isLoadingBatting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (battingLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: _whiteCard(
            title: 'Unable to load batting statistics',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  battingLoadError!,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadBattingPerformance,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rows = _battingRows();
    final totalRuns = rows.fold<int>(0, (sum, row) => sum + row.runs);
    final totalFours = rows.fold<int>(0, (sum, row) => sum + row.fours);
    final totalSixes = rows.fold<int>(0, (sum, row) => sum + row.sixes);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 800;

              final titleBlock = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batting Statistics',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17202A),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Analyse player batting performance from all imported STUMPS matches.',
                    style: TextStyle(
                      color: Color(0xFF7B8794),
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 18),
                    _buildBattingControls(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batting Statistics',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17202A),
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Analyse player batting performance from all imported STUMPS matches.',
                          style: TextStyle(
                            color: Color(0xFF7B8794),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildBattingControls(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _battingSummaryCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Players',
                  value: '${rows.length}',
                  subtitle: 'Players with records',
                ),
                _battingSummaryCard(
                  icon: Icons.sports_score_rounded,
                  title: 'Runs',
                  value: '$totalRuns',
                  subtitle: 'Total runs scored',
                ),
                _battingSummaryCard(
                  icon: Icons.looks_4_rounded,
                  title: 'Fours',
                  value: '$totalFours',
                  subtitle: 'Boundary fours',
                ),
                _battingSummaryCard(
                  icon: Icons.looks_6_rounded,
                  title: 'Sixes',
                  value: '$totalSixes',
                  subtitle: 'Boundary sixes',
                ),
              ];

              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i < cards.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              final width = (constraints.maxWidth - 48) / 4;

              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    SizedBox(width: width, child: cards[i]),
                    if (i < cards.length - 1)
                      const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _whiteCard(
            title: 'Player Batting Performance',
            trailing: Text(
              '${rows.length} player${rows.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7B8794),
              ),
            ),
            child: rows.isEmpty
                ? _buildEmptyBattingState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            for (var i = 0; i < rows.length; i++)
                              _buildBattingCompactRow(
                                rows[i],
                                i + 1,
                              ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _buildBattingTableHeader(),
                          const Divider(
                            height: 1,
                            color: Color(0xFFEEF1F4),
                          ),
                          for (var i = 0; i < rows.length; i++) ...[
                            _buildBattingTableRow(
                              rows[i],
                              i + 1,
                            ),
                            if (i < rows.length - 1)
                              const Divider(
                                height: 1,
                                color: Color(0xFFEEF1F4),
                              ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattingControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        final search = SizedBox(
          width: compact ? double.infinity : 230,
          height: 42,
          child: TextField(
            onChanged: (value) {
              setState(() {
                battingSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search players...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 19,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFFE1E6EC),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFFE1E6EC),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ),
        );

        final teamFilter = _buildBattingTeamFilter();

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              search,
              const SizedBox(height: 12),
              teamFilter,
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            search,
            const SizedBox(width: 12),
            teamFilter,
          ],
        );
      },
    );
  }

  Widget _buildBattingTeamFilter() {
    final teamNames = [
      'All Teams',
      ...firestoreTeams
          .where((team) => team.active)
          .map((team) => team.name),
    ];

    if (!teamNames.contains(selectedTeam)) {
      selectedTeam = 'All Teams';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE1E6EC),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTeam,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
          ),
          items: teamNames.map((team) {
            return DropdownMenuItem<String>(
              value: team,
              child: Text(
                team,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              selectedTeam = value;
            });
          },
        ),
      ),
    );
  }

  List<_BattingRowData> _battingRows() {
    final selectedTeamId = _selectedActiveTeamId();
    final query = battingSearchQuery.trim().toLowerCase();

    final filtered = battingPerformanceRecords.where((record) {
      final teamId = (record['teamId'] ?? '').toString();

      // Batting statistics are for our registered active teams only.
      // Opponent teams imported from STUMPS are created as inactive and
      // must never appear in this module.
      final team = firestoreTeams.where((item) => item.id == teamId).isNotEmpty
          ? firestoreTeams.firstWhere((item) => item.id == teamId)
          : null;

      if (team == null || !team.active) {
        return false;
      }

      if (selectedTeamId != null && teamId != selectedTeamId) {
        return false;
      }

      final playerId = (record['playerId'] ?? '').toString();
      final playerName = battingPlayerNames[playerId] ?? playerId;

      return query.isEmpty ||
          playerName.toLowerCase().contains(query);
    });

    final grouped = <String, _BattingRowData>{};

    for (final record in filtered) {
      final playerId = (record['playerId'] ?? '').toString();

      if (playerId.isEmpty) {
        continue;
      }

      final playerName =
          battingPlayerNames[playerId] ?? playerId;

      final teamId = (record['teamId'] ?? '').toString();
      final firestoreTeamName = firestoreTeams
          .where((team) => team.id == teamId)
          .map((team) => team.name)
          .isNotEmpty
          ? firestoreTeams
              .firstWhere((team) => team.id == teamId)
              .name
          : '';

      final teamName =
          matchTeamLookup[teamId]?.name ??
          (firestoreTeamName.isNotEmpty
              ? firestoreTeamName
              : teamId);

      final key = selectedTeamId == null
          ? playerId
          : '$playerId|$teamId';

      final existing = grouped[key];

      if (existing == null) {
        grouped[key] = _BattingRowData(
          playerId: playerId,
          playerName: playerName,
          teamNames: teamName.isEmpty ? <String>{} : {teamName},
          innings: 1,
          runs: _battingInt(record['runs']),
          balls: _battingInt(record['ballsFaced']),
          fours: _battingInt(record['fours']),
          sixes: _battingInt(record['sixes']),
        );
      } else {
        existing.innings += 1;
        existing.runs += _battingInt(record['runs']);
        existing.balls += _battingInt(record['ballsFaced']);
        existing.fours += _battingInt(record['fours']);
        existing.sixes += _battingInt(record['sixes']);
        if (teamName.isNotEmpty) {
          existing.teamNames.add(teamName);
        }
      }
    }

    final rows = grouped.values.toList();

    rows.sort((a, b) {
      final runsCompare = b.runs.compareTo(a.runs);
      if (runsCompare != 0) {
        return runsCompare;
      }

      final strikeCompare =
          b.strikeRate.compareTo(a.strikeRate);
      if (strikeCompare != 0) {
        return strikeCompare;
      }

      return a.playerName
          .toLowerCase()
          .compareTo(b.playerName.toLowerCase());
    });

    return rows;
  }

  int _battingInt(dynamic value) {
    return (value as num?)?.toInt() ?? 0;
  }

  Widget _battingSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E8ED),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7B8794),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17202A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9AA5B1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattingTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 42,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
          const Expanded(
            flex: 4,
            child: Text(
              'PLAYER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'INNS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'RUNS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'BALLS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              '4s',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              '6s',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'SR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattingTableRow(
    _BattingRowData row,
    int rank,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9AA5B1),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE8F1FB),
                  child: Text(
                    _playerInitials(row.playerName),
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        row.teamNames.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9AA5B1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _battingValue('${row.innings}'),
          ),
          Expanded(
            flex: 2,
            child: _battingValue('${row.runs}', bold: true),
          ),
          Expanded(
            flex: 2,
            child: _battingValue('${row.balls}'),
          ),
          Expanded(
            flex: 2,
            child: _battingValue('${row.fours}'),
          ),
          Expanded(
            flex: 2,
            child: _battingValue('${row.sixes}'),
          ),
          Expanded(
            flex: 2,
            child: _battingValue(
              row.strikeRate.toStringAsFixed(2),
              bold: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _battingValue(
    String value, {
    bool bold = false,
  }) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight:
            bold ? FontWeight.w700 : FontWeight.w500,
        color: const Color(0xFF4B5563),
      ),
    );
  }

  Widget _buildBattingCompactRow(
    _BattingRowData row,
    int rank,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE7EBF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE8F1FB),
                child: Text(
                  _playerInitials(row.playerName),
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      row.teamNames.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9AA5B1),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${row.runs} runs',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniBattingStat('Inns', '${row.innings}'),
              _miniBattingStat('Runs', '${row.runs}'),
              _miniBattingStat('Balls', '${row.balls}'),
              _miniBattingStat('4s', '${row.fours}'),
              _miniBattingStat('6s', '${row.sixes}'),
              _miniBattingStat(
                'SR',
                row.strikeRate.toStringAsFixed(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBattingStat(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFE1E6EC),
        ),
      ),
      child: Text(
        '$title $value',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF596775),
        ),
      ),
    );
  }

  Widget _buildEmptyBattingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.sports_score_rounded,
              size: 52,
              color: Color(0xFFB0BAC5),
            ),
            SizedBox(height: 14),
            Text(
              'No batting data found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF596775),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Import a completed STUMPS match report to populate batting statistics.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8995A3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesPage() {
    if (isLoadingMatches) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (matchLoadError != null) {
      return _buildMatchesErrorState();
    }

    final activeTeamIds = firestoreTeams
        .where((team) => team.active)
        .map((team) => team.id)
        .toSet();

    final selectedTeamId = _selectedActiveTeamId();

    final filteredMatches = firestoreMatches.where((match) {
      final involvesActiveTeam =
          activeTeamIds.contains(match.team1Id) ||
          activeTeamIds.contains(match.team2Id);

      if (!involvesActiveTeam) {
        return false;
      }

      if (selectedTeamId == null) {
        return true;
      }

      return match.team1Id == selectedTeamId ||
          match.team2Id == selectedTeamId;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 750;

              final titleBlock = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Matches',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17202A),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'View completed matches imported from STUMPS reports.',
                    style: TextStyle(
                      color: Color(0xFF7B8794),
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 18),
                    _buildMatchesTeamFilter(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 20),
                  _buildMatchesTeamFilter(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _matchSummaryCard(
                  icon: Icons.sports_cricket_rounded,
                  title: 'Total Matches',
                  value: '${filteredMatches.length}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _matchSummaryCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Completed',
                  value: '${filteredMatches.where((match) => match.completed).length}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _matchSummaryCard(
                  icon: Icons.picture_as_pdf_rounded,
                  title: 'STUMPS Imports',
                  value: '${filteredMatches.where((match) => match.stumpsMatchId.isNotEmpty).length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (filteredMatches.isEmpty)
            _buildEmptyMatchesState()
          else
            ...filteredMatches.map(_buildMatchCard),
        ],
      ),
    );
  }

  Widget _buildMatchesTeamFilter() {
    final teamNames = [
      'All Teams',
      ...firestoreTeams
          .where((team) => team.active)
          .map((team) => team.name),
    ];

    if (!teamNames.contains(selectedTeam)) {
      selectedTeam = 'All Teams';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE1E6EC),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTeam,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
          ),
          items: teamNames.map((team) {
            return DropdownMenuItem<String>(
              value: team,
              child: Text(
                team,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              selectedTeam = value;
            });
          },
        ),
      ),
    );
  }

  Widget _matchSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E8ED),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7B8794),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17202A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    final team1 = matchTeamLookup[match.team1Id];
    final team2 = matchTeamLookup[match.team2Id];

    final team1Name =
        team1?.name.isNotEmpty == true ? team1!.name : match.team1Id;
    final team2Name =
        team2?.name.isNotEmpty == true ? team2!.name : match.team2Id;

    final dateText = _formatMatchDate(match.matchDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final teamsBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      team1Name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'vs',
                      style: TextStyle(
                        color: Color(0xFF9AA5B1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      team2Name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                match.result.isNotEmpty
                    ? match.result
                    : 'Result not available',
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final metadata = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _matchChip(
                Icons.calendar_today_rounded,
                dateText,
              ),
              _matchChip(
                Icons.sports_cricket_rounded,
                match.format.isEmpty ? 'Format N/A' : match.format,
              ),
              _matchChip(
                Icons.timelapse_rounded,
                '${match.overs} overs',
              ),
              if (match.venue.isNotEmpty)
                _matchChip(
                  Icons.location_on_outlined,
                  match.venue,
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                teamsBlock,
                const SizedBox(height: 18),
                metadata,
                const SizedBox(height: 16),
                _matchDetailsRow(match),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: teamsBlock),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 320,
                    child: metadata,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _matchDetailsRow(match),
            ],
          );
        },
      ),
    );
  }

  Widget _matchDetailsRow(MatchModel match) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFEEF1F4),
          ),
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: [
          _detailText('STUMPS ID', match.stumpsMatchId),
          _detailText('Organiser', match.organiser),
          _detailText('Scorer', match.scorer),
          _detailText(
            'Toss',
            '${_teamName(match.tossWinnerTeamId)} • ${match.tossDecision}',
          ),
        ],
      ),
    );
  }

  Widget _detailText(String label, String value) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Color(0xFF9AA5B1),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '--' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFE5E9EF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFF73808D),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF596775),
            ),
          ),
        ],
      ),
    );
  }

  String _teamName(String teamId) {
    if (teamId.isEmpty) {
      return '--';
    }

    return matchTeamLookup[teamId]?.name ?? teamId;
  }

  String _formatMatchDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Widget _buildEmptyMatchesState() {
    return _whiteCard(
      title: 'No matches found',
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 35),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.sports_cricket_rounded,
                size: 52,
                color: Color(0xFFB0BAC5),
              ),
              SizedBox(height: 14),
              Text(
                'No completed matches have been imported yet.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7B8794),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: _whiteCard(
          title: 'Unable to load matches',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                matchLoadError ?? 'Unknown error',
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMatches,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyAnalysisPage() {
    final activeTeamIds = firestoreTeams
        .where((team) => team.active)
        .map((team) => team.id)
        .toSet();

    final matchDates = <String, DateTime>{};
    for (final match in firestoreMatches) {
      matchDates[match.id] = match.matchDate;
    }

    final months = <String, DateTime>{};
    for (final date in matchDates.values) {
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      months[key] = DateTime(date.year, date.month);
    }

    final sortedMonths = months.values.toList()
      ..sort((a, b) => b.compareTo(a));

    final monthLabels = <String>['All Months'];
    monthLabels.addAll(sortedMonths.map(_formatMonth));
    if (!monthLabels.contains(selectedAnalysisMonth)) {
      selectedAnalysisMonth = 'All Months';
    }

    bool matchesMonth(Map<String, dynamic> record) {
      final matchId = (record['matchId'] ?? '').toString();
      final date = matchDates[matchId];
      if (date == null) return false;
      if (selectedAnalysisMonth == 'All Months') return true;
      return _formatMonth(date) == selectedAnalysisMonth;
    }

    final records = <Map<String, dynamic>>[];
    for (final record in [
      ...battingPerformanceRecords,
      ...bowlingPerformanceRecords,
      ...fieldingPerformanceRecords,
    ]) {
      final teamId = (record['teamId'] ?? '').toString();
      if (activeTeamIds.contains(teamId) &&
          (selectedTeam == 'All Teams' ||
              firestoreTeams.any((team) => team.id == teamId && team.name == selectedTeam)) &&
          matchesMonth(record)) {
        records.add(record);
      }
    }

    int value(Map<String, dynamic> r, String key) =>
        (r[key] as num?)?.toInt() ?? int.tryParse('${r[key] ?? 0}') ?? 0;

    var battingRuns = 0;
    var battingBalls = 0;
    var bowlingWickets = 0;
    var bowlingRuns = 0;
    var bowlingBalls = 0;
    var catches = 0;
    var caughtAndBowled = 0;
    var runOuts = 0;
    var stumpings = 0;
    final playerIds = <String>{};

    final seenMatchPlayerBatting = <String>{};
    final seenMatchPlayerBowling = <String>{};
    final seenMatchPlayerFielding = <String>{};

    for (final r in records) {
      final playerId = (r['playerId'] ?? '').toString();
      final matchId = (r['matchId'] ?? '').toString();
      if (playerId.isEmpty) continue;
      playerIds.add(playerId);

      final battingKey = '$matchId|$playerId|batting';
      final bowlingKey = '$matchId|$playerId|bowling';
      final fieldingKey = '$matchId|$playerId|fielding';

      if (r.containsKey('runs') && !seenMatchPlayerBatting.contains(battingKey)) {
        seenMatchPlayerBatting.add(battingKey);
        battingRuns += value(r, 'runs');
        battingBalls += value(r, 'ballsFaced');
      }
      if ((r['wickets'] != null || r['runsConceded'] != null) &&
          !seenMatchPlayerBowling.contains(bowlingKey)) {
        seenMatchPlayerBowling.add(bowlingKey);
        bowlingWickets += value(r, 'wickets');
        bowlingRuns += value(r, 'runsConceded');
        final overs = (r['overs'] as num?)?.toDouble() ?? 0;
        final completed = overs.floor();
        final partial = ((overs - completed) * 10).round();
        bowlingBalls += completed * 6 + partial;
      }
      if ((r['catches'] != null || r['runOuts'] != null) &&
          !seenMatchPlayerFielding.contains(fieldingKey)) {
        seenMatchPlayerFielding.add(fieldingKey);
        catches += value(r, 'catches');
        caughtAndBowled += value(r, 'caughtAndBowled');
        runOuts += value(r, 'runOuts');
        stumpings += value(r, 'stumpings');
      }
    }

    final battingStrikeRate = battingBalls == 0 ? 0.0 : battingRuns * 100 / battingBalls;
    final bowlingEconomy = bowlingBalls == 0 ? 0.0 : bowlingRuns * 6 / bowlingBalls;
    final totalFielding = catches + caughtAndBowled + runOuts + stumpings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 800;
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMonthlyMonthFilter(monthLabels),
                  const SizedBox(width: 12),
                  _buildMonthlyTeamFilter(),
                ],
              );
              final title = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Analysis', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700, color: Color(0xFF17202A))),
                  SizedBox(height: 7),
                  Text('Analyze batting, bowling and fielding performance by month.', style: TextStyle(color: Color(0xFF7B8794), fontSize: 14)),
                ],
              );
              if (compact) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 18), SingleChildScrollView(scrollDirection: Axis.horizontal, child: controls)]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: title), const SizedBox(width: 20), controls]);
            },
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 700 ? constraints.maxWidth : (constraints.maxWidth - 48) / 4;
              final cards = [
                _monthlyStatCard('Runs', '$battingRuns', 'Batting runs', Icons.sports_score_rounded),
                _monthlyStatCard('Wickets', '$bowlingWickets', 'Bowling wickets', Icons.sports_baseball_rounded),
                _monthlyStatCard('Fielding', '$totalFielding', 'Dismissals', Icons.back_hand_rounded),
                _monthlyStatCard('Players', '${playerIds.length}', 'Active players', Icons.people_alt_rounded),
              ];
              if (constraints.maxWidth < 700) return Column(children: [for (var i=0;i<cards.length;i++) Padding(padding: EdgeInsets.only(bottom: i==cards.length-1?0:14), child: cards[i])]);
              return Row(children: [for (var i=0;i<cards.length;i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i<3?16:0), child: SizedBox(width: cardWidth, child: cards[i]))) ]);
            },
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _monthlyMetricCard('Batting', 'Runs', '$battingRuns', 'Strike Rate', battingStrikeRate.toStringAsFixed(2)),
                _monthlyMetricCard('Bowling', 'Wickets', '$bowlingWickets', 'Economy', bowlingEconomy.toStringAsFixed(2)),
                _monthlyMetricCard('Fielding', 'Catches', '$catches', 'Run Outs', '$runOuts'),
              ];
              if (constraints.maxWidth < 900) return Column(children: [for (var i=0;i<cards.length;i++) Padding(padding: EdgeInsets.only(bottom: i==cards.length-1?0:16), child: cards[i])]);
              return Row(children: [for (var i=0;i<cards.length;i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i<2?16:0), child: cards[i]))]);
            },
          ),
          const SizedBox(height: 22),
          _whiteCard(
            title: 'Fielding Breakdown',
            child: LayoutBuilder(builder: (context, constraints) {
              final items = [
                ['Catches', '$catches'],
                ['Caught & Bowled', '$caughtAndBowled'],
                ['Run Outs', '$runOuts'],
                ['Stumpings', '$stumpings'],
              ];
              if (constraints.maxWidth < 650) return Column(children: [for (var i=0;i<items.length;i++) _monthlyBreakdownRow(items[i][0], items[i][1], i == items.length-1)]);
              return Row(children: [for (var i=0;i<items.length;i++) Expanded(child: _monthlyBreakdownRow(items[i][0], items[i][1], i == items.length-1))]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyMonthFilter(List<String> months) {
    return _monthlyDropdown('Month', selectedAnalysisMonth, months, (value) {
      if (value == null) return;
      setState(() => selectedAnalysisMonth = value);
    });
  }

  Widget _buildMonthlyTeamFilter() {
    final activeTeams = firestoreTeams.where((team) => team.active).map((team) => team.name).toList();
    final options = ['All Teams', ...activeTeams];
    if (!options.contains(selectedTeam)) selectedTeam = 'All Teams';
    return _monthlyDropdown('Team', selectedTeam, options, (value) {
      if (value == null) return;
      setState(() => selectedTeam = value);
    });
  }

  Widget _monthlyDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFE1E6EC))),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, hint: Text(label), icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18), items: options.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(), onChanged: onChanged)),
    );
  }

  Widget _monthlyStatCard(String title, String value, String subtitle, IconData icon) {
    return _whiteCard(title: title, child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFE8F1FB), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: const Color(0xFF1565C0))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF17202A))), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF8995A3)))]))]));
  }

  Widget _monthlyMetricCard(String title, String leftLabel, String leftValue, String rightLabel, String rightValue) {
    return _whiteCard(title: title, child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(leftLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF8995A3))), const SizedBox(height: 4), Text(leftValue, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: Color(0xFF17202A)))])), Container(width: 1, height: 45, color: const Color(0xFFE8ECF0)), const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rightLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF8995A3))), const SizedBox(height: 4), Text(rightValue, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: Color(0xFF17202A)))]))]));
  }

  Widget _monthlyBreakdownRow(String label, String value, bool last) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15), decoration: BoxDecoration(border: Border(right: last ? BorderSide.none : const BorderSide(color: Color(0xFFE8ECF0)))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF17202A)))]));
  }

  String _formatMonth(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStumpsImportPage() {
    if (!isAdmin) {
      return const Center(
        child: Text(
          'STUMPS Import is available only to administrators.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF667085),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _whiteCard(
                title: 'Import STUMPS Match Report',
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 42,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Upload a completed STUMPS PDF',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The report will be parsed automatically and the match, players, team relationships and performance records will be saved to Firebase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7B8794),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: isImportingStumps ? null : _pickAndImportStumpsPdf,
                      icon: isImportingStumps
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded, size: 19),
                      label: Text(
                        isImportingStumps ? 'Importing...' : 'Choose STUMPS PDF',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    if (stumpsImportMessage != null) ...[
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: stumpsImportSuccess
                              ? const Color(0xFFEAF7EE)
                              : const Color(0xFFFFF1F1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: stumpsImportSuccess
                                ? const Color(0xFFB8E0C2)
                                : const Color(0xFFF0C2C2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              stumpsImportSuccess
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: stumpsImportSuccess
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stumpsImportMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndImportStumpsPdf() async {
    if (!isAdmin) {
      return;
    }

    setState(() {
      isImportingStumps = true;
      stumpsImportMessage = null;
      stumpsImportSuccess = false;
    });

    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pickedFile == null) {
        if (!mounted) return;
        setState(() {
          isImportingStumps = false;
        });
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      if (bytes.isEmpty) {
        throw StateError('The selected PDF could not be read.');
      }

      final importResult = await StumpsImportService().importPdf(bytes);

      if (!mounted) return;

      if (importResult.wasDuplicate) {
        setState(() {
          isImportingStumps = false;
          stumpsImportSuccess = true;
          stumpsImportMessage =
              'This STUMPS match is already imported. Match ID: ${importResult.match.stumpsMatchId}. Existing performance records: ${importResult.performanceCount}.';
        });
        return;
      }

      setState(() {
        isImportingStumps = false;
        stumpsImportSuccess = true;
        stumpsImportMessage =
            'Match imported successfully. STUMPS Match ID: ${importResult.match.stumpsMatchId}. Performance records saved: ${importResult.performanceCount}.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isImportingStumps = false;
        stumpsImportSuccess = false;
        stumpsImportMessage = 'Import failed: $e';
      });
    }
  }

  Widget _buildDashboard() {
    final activeTeamIds = firestoreTeams
        .where((team) => team.active)
        .map((team) => team.id)
        .toSet();
    final selectedTeamId = _selectedActiveTeamId();

    final dashboardMatches = firestoreMatches.where((match) {
      final involvesActiveTeam =
          activeTeamIds.contains(match.team1Id) ||
          activeTeamIds.contains(match.team2Id);
      if (!involvesActiveTeam) return false;
      if (selectedTeamId == null) return true;
      return match.team1Id == selectedTeamId ||
          match.team2Id == selectedTeamId;
    }).toList();

    final dashboardPlayers = firestorePlayers.where((player) {
      final teamIds = playerTeamIds[player.id] ?? <String>[];
      if (selectedTeamId != null) {
        return teamIds.contains(selectedTeamId);
      }
      return teamIds.any(activeTeamIds.contains);
    }).toList();

    final dashboardBatting = battingPerformanceRecords.where((record) {
      final teamId = (record['teamId'] ?? '').toString();
      return activeTeamIds.contains(teamId) &&
          (selectedTeamId == null || teamId == selectedTeamId);
    }).toList();

    final dashboardBowling = bowlingPerformanceRecords.where((record) {
      final teamId = (record['teamId'] ?? '').toString();
      return activeTeamIds.contains(teamId) &&
          (selectedTeamId == null || teamId == selectedTeamId);
    }).toList();

    final totalRuns = dashboardBatting.fold<int>(
      0,
      (sum, record) => sum + _topInt(record['runs']),
    );
    final totalWickets = dashboardBowling.fold<int>(
      0,
      (sum, record) => sum + _topInt(record['wickets']),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;
              final titleBlock = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Overview',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17202A),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Track batting, bowling and fielding performance across all matches.',
                    style: TextStyle(
                      color: Color(0xFF7B8794),
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 16),
                    _buildTeamSelector(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 20),
                  _buildTeamSelector(),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _statCard(
                  title: 'Matches',
                  value: '${dashboardMatches.where((m) => m.completed).length}',
                  subtitle: 'Completed matches',
                  icon: Icons.sports_cricket_rounded,
                ),
                _statCard(
                  title: 'Players',
                  value: '${dashboardPlayers.length}',
                  subtitle: 'Registered players',
                  icon: Icons.people_alt_rounded,
                ),
                _statCard(
                  title: 'Runs',
                  value: '$totalRuns',
                  subtitle: 'Total runs scored',
                  icon: Icons.sports_score_rounded,
                ),
                _statCard(
                  title: 'Wickets',
                  value: '$totalWickets',
                  subtitle: 'Total wickets',
                  icon: Icons.sports_baseball_rounded,
                ),
              ];

              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i < cards.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                );
              }

              final cardWidth = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    SizedBox(width: cardWidth, child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildTopBattersCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildImportCard()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildTopBattersCard(),
                  const SizedBox(height: 20),
                  _buildImportCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildTopPerformersOverview(),
        ],
      ),
    );
  }

  Widget _buildTeamSelector() {
    if (isLoadingTeams) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(0xFFE1E6EC),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 9),
            Text(
              'Loading teams...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF596775),
              ),
            ),
          ],
        ),
      );
    }

    final teamNames = [
      'All Teams',
      ...firestoreTeams.map((team) => team.name),
    ];

    if (!teamNames.contains(selectedTeam)) {
      selectedTeam = 'All Teams';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE1E6EC),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTeam,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
          ),
          items: teamNames.map((team) {
            return DropdownMenuItem<String>(
              value: team,
              child: Text(
                team,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              selectedTeam = value;
            });
          },
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B8794),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17202A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9AA5B1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBattersCard() {
    final rows = _topBattingPerformers(selectedTeam, 'All Time');

    return _whiteCard(
      title: 'Top Batters',
      trailing: _filterButton('Overall'),
      child: rows.isEmpty
          ? Column(
              children: [
                const SizedBox(height: 6),
                _emptyPerformanceRow(
                  position: '1',
                  icon: Icons.looks_one_rounded,
                  message: 'No batting data yet',
                ),
                _divider(),
                _emptyPerformanceRow(
                  position: '2',
                  icon: Icons.looks_two_rounded,
                  message: 'No batting data yet',
                ),
                _divider(),
                _emptyPerformanceRow(
                  position: '3',
                  icon: Icons.looks_3_rounded,
                  message: 'No batting data yet',
                ),
              ],
            )
          : Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _dashboardPerformanceRow(
                    position: '${i + 1}',
                    playerName: rows[i].playerName,
                    teamName: rows[i].teamName,
                    value: '${rows[i].primaryValue}',
                    label: 'Runs',
                  ),
                  if (i < rows.length - 1) _divider(),
                ],
              ],
            ),
    );
  }

  Widget _dashboardPerformanceRow({
    required String position,
    required String playerName,
    required String teamName,
    required String value,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              position,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF263238),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  teamName,
                  style: const TextStyle(
                    color: Color(0xFF8995A3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    final hasImportedMatches = firestoreMatches.isNotEmpty;

    return _whiteCard(
      title: 'STUMPS Match Data',
      child: Column(
        children: [
          const SizedBox(height: 5),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 34,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            hasImportedMatches
                ? '${firestoreMatches.length} match${firestoreMatches.length == 1 ? '' : 'es'} imported'
                : 'No matches imported',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasImportedMatches
                ? 'STUMPS match data is available for performance analysis.'
                : 'Import a completed STUMPS match report to update player performance.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8995A3),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                selectedIndex = 8;
              });
            },
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Import STUMPS PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersOverview() {
    final batting = _topBattingPerformers(selectedTeam, 'All Time');
    final bowling = _topBowlingPerformers(selectedTeam, 'All Time');
    final fielding = _topFieldingPerformers(selectedTeam, 'All Time');

    return _whiteCard(
      title: 'Top 3 Performers',
      trailing: _filterButton('Overall'),
      child: Column(
        children: [
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _categoryCard(
                  icon: Icons.sports_cricket_rounded,
                  title: 'Batting',
                  subtitle: batting.isEmpty
                      ? 'No batting data'
                      : '${batting.first.playerName} · ${batting.first.primaryValue} runs',
                ),
                _categoryCard(
                  icon: Icons.sports_baseball_rounded,
                  title: 'Bowling',
                  subtitle: bowling.isEmpty
                      ? 'No bowling data'
                      : '${bowling.first.playerName} · ${bowling.first.primaryValue} wickets',
                ),
                _categoryCard(
                  icon: Icons.back_hand_rounded,
                  title: 'Fielding',
                  subtitle: fielding.isEmpty
                      ? 'No fielding data'
                      : '${fielding.first.playerName} · ${fielding.first.primaryValue} dismissals',
                ),
              ];

              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 12),
                    cards[1],
                    const SizedBox(height: 12),
                    cards[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE7EBF0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A96A3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPerformanceRow({
    required String position,
    required IconData icon,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 19,
              color: const Color(0xFF9AA5B1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9AA5B1),
                fontSize: 13,
              ),
            ),
          ),
          const Text(
            '--',
            style: TextStyle(
              color: Color(0xFF9AA5B1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263238),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _filterButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFE1E6EC),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF596775),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFF778492),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: Color(0xFFEEF1F4),
    );
  }
}

class _PlayerDetailsPage extends StatefulWidget {
  final PlayerModel player;
  final List<String> teamNames;
  final FirebaseFirestore firestore;
  final TeamRepository teamRepository;
  final MatchRepository matchRepository;
  final Set<String> activeTeamIds;

  const _PlayerDetailsPage({
    required this.player,
    required this.teamNames,
    required this.firestore,
    required this.teamRepository,
    required this.matchRepository,
    required this.activeTeamIds,
  });

  @override
  State<_PlayerDetailsPage> createState() => _PlayerDetailsPageState();
}

class _PlayerDetailsPageState extends State<_PlayerDetailsPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> performances = [];
  final Map<String, TeamModel> teams = {};
  final Map<String, MatchModel> matches = {};

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  Future<void> _loadPerformance() async {
    try {
      final snapshot = await widget.firestore
          .collection('player_match_performances')
          .where('playerId', isEqualTo: widget.player.id)
          .get();

      final records = snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .where((record) => widget.activeTeamIds
              .contains((record['teamId'] ?? '').toString()))
          .toList();

      final teamIds = records
          .map((record) => (record['teamId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final teamId in teamIds) {
        final team = await widget.teamRepository.getTeam(teamId);
        if (team != null) teams[teamId] = team;
      }

      final matchIds = records
          .map((record) => (record['matchId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final matchId in matchIds) {
        final match = await widget.matchRepository.getMatch(matchId);
        if (match != null) matches[matchId] = match;
      }

      if (!mounted) return;
      setState(() {
        performances = records;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  int _int(dynamic value) => (value as num?)?.toInt() ?? 0;
  double _double(dynamic value) => (value as num?)?.toDouble() ?? 0;
  int _total(String key) => performances.fold(0, (sum, r) => sum + _int(r[key]));

  int _bowlingBalls() {
    var balls = 0;
    for (final record in performances) {
      final overs = _double(record['overs']);
      final completed = overs.floor();
      final partial = ((overs - completed) * 10).round();
      balls += completed * 6 + partial;
    }
    return balls;
  }

  String _overs(int balls) => '${balls ~/ 6}.${balls % 6}';

  double get strikeRate {
    final balls = _total('ballsFaced');
    return balls == 0 ? 0 : _total('runs') * 100 / balls;
  }

  double get economy {
    final balls = _bowlingBalls();
    return balls == 0 ? 0 : _total('runsConceded') * 6 / balls;
  }

  String _date(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Player Statistics', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF17202A))),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _error()
              : _body(),
    );
  }

  Widget _error() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFC62828)),
            const SizedBox(height: 12),
            const Text('Unable to load player statistics.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { setState(() { loading = true; error = null; }); _loadPerformance(); }, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final fielding = _total('catches') + _total('caughtAndBowled') + _total('runOuts') + _total('stumpings');
    return RefreshIndicator(
      onRefresh: _loadPerformance,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 20),
                _title('Batting'),
                const SizedBox(height: 10),
                _grid([
                  _metric('Runs', '${_total('runs')}', Icons.sports_score_rounded),
                  _metric('Balls', '${_total('ballsFaced')}', Icons.circle_outlined),
                  _metric('4s', '${_total('fours')}', Icons.looks_4_rounded),
                  _metric('6s', '${_total('sixes')}', Icons.looks_6_rounded),
                  _metric('Strike Rate', strikeRate.toStringAsFixed(2), Icons.speed_rounded),
                ]),
                const SizedBox(height: 20),
                _title('Bowling'),
                const SizedBox(height: 10),
                _grid([
                  _metric('Overs', _overs(_bowlingBalls()), Icons.sports_cricket_rounded),
                  _metric('Wickets', '${_total('wickets')}', Icons.sports_baseball_rounded),
                  _metric('Runs Conceded', '${_total('runsConceded')}', Icons.trending_up_rounded),
                  _metric('Maidens', '${_total('maidens')}', Icons.block_rounded),
                  _metric('Economy', economy.toStringAsFixed(2), Icons.speed_rounded),
                  _metric('Dot Balls', '${_total('dotBalls')}', Icons.circle_rounded),
                ]),
                const SizedBox(height: 20),
                _title('Fielding'),
                const SizedBox(height: 10),
                _grid([
                  _metric('Catches', '${_total('catches')}', Icons.back_hand_rounded),
                  _metric('Caught & Bowled', '${_total('caughtAndBowled')}', Icons.sports_handball_rounded),
                  _metric('Run Outs', '${_total('runOuts')}', Icons.directions_run_rounded),
                  _metric('Stumpings', '${_total('stumpings')}', Icons.pan_tool_alt_rounded),
                  _metric('Total Dismissals', '$fielding', Icons.emoji_events_rounded),
                ]),
                const SizedBox(height: 20),
                _title('Match History'),
                const SizedBox(height: 10),
                if (performances.isEmpty) _empty() else ...performances.map(_matchCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E8ED))),
      child: Row(
        children: [
          CircleAvatar(radius: 31, backgroundColor: const Color(0xFFE8F1FB), child: Text(_initials(widget.player.name), style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w800, fontSize: 16))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.player.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF17202A))),
            const SizedBox(height: 5),
            Text(widget.teamNames.isEmpty ? 'No team relationship' : widget.teamNames.join(' • '), style: const TextStyle(color: Color(0xFF718096), fontSize: 13)),
            const SizedBox(height: 5),
            Text('${performances.length} match${performances.length == 1 ? '' : 'es'} • ${widget.player.active ? 'Active player' : 'Inactive player'}', style: const TextStyle(color: Color(0xFF9AA5B1), fontSize: 11)),
          ])),
        ],
      ),
    );
  }

  Widget _title(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF263238)));

  Widget _grid(List<Widget> items) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 850 ? 5 : constraints.maxWidth >= 560 ? 3 : 2;
      final rows = <Widget>[];
      for (var i = 0; i < items.length; i += columns) {
        final row = items.skip(i).take(columns).toList();
        rows.add(Row(children: [for (var j = 0; j < columns; j++) Expanded(child: Padding(padding: EdgeInsets.only(right: j < columns - 1 ? 7 : 0, left: j > 0 ? 7 : 0), child: j < row.length ? row[j] : const SizedBox.shrink()))]));
        if (i + columns < items.length) rows.add(const SizedBox(height: 10));
      }
      return Column(children: rows);
    });
  }

  Widget _metric(String title, String value, IconData icon) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE4E8ED))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: const Color(0xFF1565C0)), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF17202A))), const SizedBox(height: 3), Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF7B8794)))]));
  }

  Widget _matchCard(Map<String, dynamic> record) {
    final matchId = (record['matchId'] ?? '').toString();
    final match = matches[matchId];
    final team = teams[(record['teamId'] ?? '').toString()]?.name ?? (record['teamId'] ?? 'Unknown team').toString();
    final fielding = _int(record['catches']) + _int(record['caughtAndBowled']) + _int(record['runOuts']) + _int(record['stumpings']);
    return Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4E8ED))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(match == null ? matchId : '${teams[match.team1Id]?.name ?? match.team1Id} vs ${teams[match.team2Id]?.name ?? match.team2Id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF263238)))), Text(team, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)))]),
      const SizedBox(height: 5),
      if (match != null) Text('${_date(match.matchDate)} • ${match.format} • ${match.result}', style: const TextStyle(fontSize: 11, color: Color(0xFF8A96A3))),
      const SizedBox(height: 13),
      Wrap(spacing: 8, runSpacing: 8, children: [_mini('Runs', '${_int(record['runs'])}'), _mini('Balls', '${_int(record['ballsFaced'])}'), _mini('Wkts', '${_int(record['wickets'])}'), _mini('Fielding', '$fielding')]),
    ]));
  }

  Widget _mini(String title, String value) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(8)), child: Text('$title $value', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF596775))));

  Widget _empty() => Container(width: double.infinity, padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4E8ED))), child: const Center(child: Text('No match performance records found for this player.', style: TextStyle(color: Color(0xFF7B8794)))));
}



class _FieldingHeaderStyle {
  static const textStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Color(0xFF8A96A3),
  );
}

class _FieldingRowData {
  final String playerId;
  final String playerName;
  final Set<String> teamNames;
  int innings;
  int catches;
  int caughtAndBowled;
  int runOuts;
  int stumpings;

  _FieldingRowData({
    required this.playerId,
    required this.playerName,
    required this.teamNames,
    required this.innings,
    required this.catches,
    required this.caughtAndBowled,
    required this.runOuts,
    required this.stumpings,
  });

  int get totalDismissals =>
      catches + caughtAndBowled + runOuts + stumpings;
}

class _BowlingRowData {
  final String playerId;
  final String playerName;
  final Set<String> teamNames;
  int innings;
  int balls;
  int maidens;
  int runsConceded;
  int wickets;
  int dotBalls;
  int wides;
  int noBalls;

  _BowlingRowData({
    required this.playerId,
    required this.playerName,
    required this.teamNames,
    required this.innings,
    required this.balls,
    required this.maidens,
    required this.runsConceded,
    required this.wickets,
    required this.dotBalls,
    required this.wides,
    required this.noBalls,
  });

  String get overs => '${balls ~/ 6}.${balls % 6}';

  double get economy => balls == 0 ? 0 : runsConceded * 6 / balls;
}

class _BattingRowData {
  final String playerId;
  final String playerName;
  final Set<String> teamNames;
  int innings;
  int runs;
  int balls;
  int fours;
  int sixes;

  _BattingRowData({
    required this.playerId,
    required this.playerName,
    required this.teamNames,
    required this.innings,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
  });

  double get strikeRate {
    return balls == 0 ? 0 : runs * 100 / balls;
  }
}

class _TopPerformerRowData {
  final String playerName;
  String teamName;
  int innings = 0;
  int primaryValue = 0;
  int balls = 0;
  int secondaryRuns = 0;
  int secondaryBalls = 0;
  double secondaryValue = 0;

  _TopPerformerRowData({
    required this.playerName,
    required this.teamName,
  });
}

class _NavigationItem {
  final IconData icon;
  final String title;

  const _NavigationItem(this.icon, this.title);
}
