import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/firebase/matchmaking_service.dart';
import '../../../services/firebase/realtime_service.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/analytics/analytics_constants.dart';

enum MatchState { idle, searching, playing, finished }

class MultiplayerProvider extends ChangeNotifier {
  MultiplayerProvider(
    this._matchmakingService,
    this._realtimeService,
    this._analytics,
  );

  final MatchmakingService _matchmakingService;
  final RealtimeService _realtimeService;
  final AnalyticsService _analytics;

  MatchState _state = MatchState.idle;
  String? _currentMatchId;
  String? _localPlayerPrefix;

  List<int> _opponentBoard = List.filled(16, 0);
  int _opponentScore = 0;
  String? _opponentEmote;
  int? _opponentEmoteTime;

  StreamSubscription<DatabaseEvent>? _queueSubscription;
  StreamSubscription<DatabaseEvent>? _matchSubscription;

  DateTime? _matchStartedAt;
  bool _matchStartLogged = false;
  bool _matchEndLogged = false;
  int _localScore = 0;
  int _opponentScoreAtEnd = 0;

  MatchState get state => _state;
  List<int> get opponentBoard => _opponentBoard;
  int get opponentScore => _opponentScore;
  bool get isPlaying => _state == MatchState.playing;
  String? get opponentEmote => _opponentEmote;

  Future<void> findMatch(String userId) async {
    _state = MatchState.searching;
    _matchStartLogged = false;
    _matchEndLogged = false;
    notifyListeners();

    final matchId = await _matchmakingService.joinQueue(userId);

    if (matchId != null) {
      _currentMatchId = matchId;
      _state = MatchState.playing;
      _listenToMatch(matchId, userId);
      await _logMatchStarted();
    } else {
      _queueSubscription = _matchmakingService.matchmakingQueue
          .orderByChild('userId')
          .equalTo(userId)
          .onChildRemoved
          .listen((event) {
        _checkIfMatched(userId);
      });
    }
    notifyListeners();
  }

  Future<void> _checkIfMatched(String userId) async {
    final snapshot = await _realtimeService.onlineMatches
        .orderByChild('player2Id')
        .equalTo(userId)
        .limitToLast(1)
        .get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final matchId = data.keys.first;
      _currentMatchId = matchId;
      _state = MatchState.playing;
      _listenToMatch(matchId, userId);

      _queueSubscription?.cancel();
      await _logMatchStarted();
      notifyListeners();
    }
  }

  Future<void> _logMatchStarted() async {
    if (_matchStartLogged) return;
    _matchStartLogged = true;
    _matchStartedAt = DateTime.now();
    await _analytics.logQuickMatchUsed();
    await _analytics.logMultiplayerMatchStarted(
      mode: AnalyticsModes.quickMatch,
      opponentType: 'online_random',
    );
  }

  Future<void> _logMatchFinished(String winOrLoss) async {
    if (_matchEndLogged) return;
    _matchEndLogged = true;
    final duration = _matchStartedAt == null
        ? 0
        : DateTime.now().difference(_matchStartedAt!).inSeconds;
    await _analytics.logMultiplayerMatchFinished(
      mode: AnalyticsModes.quickMatch,
      winOrLoss: winOrLoss,
      matchDurationSeconds: duration,
      opponentType: 'online_random',
    );
  }

  void _listenToMatch(String matchId, String localUserId) {
    _matchSubscription = _realtimeService.streamMatchState(matchId).listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        final p1Id = data['player1Id'];
        final p2Id = data['player2Id'];

        _localPlayerPrefix = (localUserId == p1Id) ? 'player1' : 'player2';
        final opponentPrefix = (localUserId == p1Id) ? 'player2' : 'player1';

        if (data['${_localPlayerPrefix}_score'] != null) {
          _localScore = (data['${_localPlayerPrefix}_score'] as num).toInt();
        }
        if (data['${opponentPrefix}_board'] != null) {
          _opponentBoard = List<int>.from(data['${opponentPrefix}_board']);
        }
        if (data['${opponentPrefix}_score'] != null) {
          _opponentScore = (data['${opponentPrefix}_score'] as num).toInt();
          _opponentScoreAtEnd = _opponentScore;
        }

        if (data['${opponentPrefix}_emote'] != null && data['${opponentPrefix}_emoteTime'] != null) {
          final emoteTime = data['${opponentPrefix}_emoteTime'] as int;
          if (_opponentEmoteTime == null || emoteTime > _opponentEmoteTime!) {
            _opponentEmoteTime = emoteTime;
            _opponentEmote = data['${opponentPrefix}_emote'];
            Future.delayed(const Duration(seconds: 3), () {
              if (_opponentEmoteTime == emoteTime) {
                _opponentEmote = null;
                notifyListeners();
              }
            });
          }
        }

        if (data['gameState'] == 'finished') {
          _state = MatchState.finished;
          final winOrLoss = _localScore >= _opponentScoreAtEnd ? 'win' : 'loss';
          if (_localScore == _opponentScoreAtEnd) {
            _logMatchFinished('draw');
          } else {
            _logMatchFinished(winOrLoss);
          }
        }

        notifyListeners();
      }
    });
  }

  void syncLocalBoard(String userId, List<int> board, int score, {bool force = false}) {
    _localScore = score;
    if (_currentMatchId != null && _state == MatchState.playing) {
      final playerPrefix = _localPlayerPrefix ?? 'player1';

      _realtimeService.syncBoardState(
        matchId: _currentMatchId!,
        playerId: playerPrefix,
        board: board,
        score: score,
        forceSync: force,
      );
    }
  }

  Future<void> sendEmote(String emote, String userId) async {
    if (_currentMatchId != null && _state == MatchState.playing) {
      final playerPrefix = _localPlayerPrefix ?? 'player1';
      await _realtimeService.sendEmote(
        matchId: _currentMatchId!,
        playerId: playerPrefix,
        emote: emote,
      );
    }
  }

  Future<void> cancelSearch(String userId) async {
    await _matchmakingService.leaveQueue(userId);
    _queueSubscription?.cancel();
    _state = MatchState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }
}
