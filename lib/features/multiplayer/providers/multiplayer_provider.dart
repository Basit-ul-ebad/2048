import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/constants/match_constants.dart';
import '../../../services/firebase/matchmaking_service.dart';
import '../../../services/firebase/realtime_service.dart';
import '../../../services/firebase/firestore_service.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/analytics/analytics_constants.dart';

enum MatchState { idle, searching, playing, finished }

class MultiplayerProvider extends ChangeNotifier {
  MultiplayerProvider(
    this._matchmakingService,
    this._realtimeService,
    this._analytics,
    this._firestoreService,
  );

  final MatchmakingService _matchmakingService;
  final RealtimeService _realtimeService;
  final AnalyticsService _analytics;
  final FirestoreService _firestoreService;

  MatchState _state = MatchState.idle;
  String? _currentMatchId;
  String? _localUserId;
  String? _localPlayerPrefix;
  int _matchDurationSeconds = MatchDurations.short;
  int? _matchEndTimeMs;
  int _secondsRemaining = 0;

  List<int> _opponentBoard = List.filled(16, 0);
  int _opponentScore = 0;
  String? _opponentEmote;
  int? _opponentEmoteTime;

  StreamSubscription<DatabaseEvent>? _queueSubscription;
  StreamSubscription<DatabaseEvent>? _matchSubscription;
  Timer? _countdownTimer;
  Timer? _matchEndTimer;

  DateTime? _matchStartedAt;
  bool _matchStartLogged = false;
  bool _matchEndLogged = false;
  int _localScore = 0;
  String? _matchResultMessage;

  MatchState get state => _state;
  List<int> get opponentBoard => _opponentBoard;
  int get opponentScore => _opponentScore;
  bool get isPlaying => _state == MatchState.playing;
  String? get opponentEmote => _opponentEmote;
  int get secondsRemaining => _secondsRemaining;
  int get matchDurationSeconds => _matchDurationSeconds;
  String? get matchResultMessage => _matchResultMessage;
  String? get currentMatchId => _currentMatchId;

  Future<void> findMatch(String userId, {int matchDurationSeconds = MatchDurations.short}) async {
    await cancelSearch(userId);

    _localUserId = userId;
    _matchDurationSeconds = matchDurationSeconds;
    _state = MatchState.searching;
    _matchStartLogged = false;
    _matchEndLogged = false;
    _matchResultMessage = null;
    notifyListeners();

    final matchId = await _matchmakingService.joinQueue(
      userId,
      matchDurationSeconds: matchDurationSeconds,
    );

    if (matchId != null) {
      _enterMatch(matchId, userId);
    } else {
      _queueSubscription = _matchmakingService.matchmakingQueue
          .child(userId)
          .onChildRemoved
          .listen((_) => _checkIfMatched(userId));
    }
    notifyListeners();
  }

  /// Join an existing match (friend challenge accept).
  Future<void> joinExistingMatch(String matchId, String userId) async {
    await cancelSearch(userId);
    _localUserId = userId;
    _enterMatch(matchId, userId);
  }

  Future<void> _checkIfMatched(String userId) async {
    if (_state != MatchState.searching) return;

    final asP2 = await _realtimeService.onlineMatches
        .orderByChild('player2Id')
        .equalTo(userId)
        .limitToLast(1)
        .get();

    if (asP2.exists && asP2.value is Map) {
      final data = Map<dynamic, dynamic>.from(asP2.value as Map);
      final matchId = data.keys.first.toString();
      _enterMatch(matchId, userId);
      return;
    }

    final asP1 = await _realtimeService.onlineMatches
        .orderByChild('player1Id')
        .equalTo(userId)
        .limitToLast(1)
        .get();

    if (asP1.exists && asP1.value is Map) {
      final data = Map<dynamic, dynamic>.from(asP1.value as Map);
      final matchId = data.keys.first.toString();
      _enterMatch(matchId, userId);
    }
  }

  void _enterMatch(String matchId, String userId) {
    _currentMatchId = matchId;
    _state = MatchState.playing;
    _queueSubscription?.cancel();
    _queueSubscription = null;
    _listenToMatch(matchId, userId);
    _logMatchStarted();
    notifyListeners();
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

  void _listenToMatch(String matchId, String localUserId) {
    _matchSubscription?.cancel();
    _matchSubscription = _realtimeService.streamMatchState(matchId).listen((event) {
      if (event.snapshot.value == null) return;

      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final p1Id = data['player1Id']?.toString();
      final p2Id = data['player2Id']?.toString();

      if (p1Id == p2Id) return;

      _localPlayerPrefix = (localUserId == p1Id) ? 'player1' : 'player2';
      final opponentPrefix = (localUserId == p1Id) ? 'player2' : 'player1';

      if (data['duration'] != null) {
        _matchDurationSeconds = (data['duration'] as num).toInt();
      }
      if (data['endTime'] != null) {
        _matchEndTimeMs = (data['endTime'] as num).toInt();
        _scheduleMatchEnd();
        _startCountdownTicker();
      }

      final newOppScore = RealtimeService.readScore(data, opponentPrefix) ?? _opponentScore;
      final newOppBoard = RealtimeService.readBoard(data, opponentPrefix);
      final scoreChanged = newOppScore != _opponentScore;
      final boardChanged = !_boardsEqual(newOppBoard, _opponentBoard);

      _localScore = RealtimeService.readScore(data, _localPlayerPrefix!) ?? _localScore;
      _opponentScore = newOppScore;
      _opponentBoard = newOppBoard;

      _handleOpponentEmote(data, opponentPrefix);

      if (data['gameState'] == 'finished') {
        _onMatchFinished();
      } else if (scoreChanged || boardChanged || _opponentEmote != null) {
        notifyListeners();
      }
    });
  }

  bool _boardsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleOpponentEmote(Map<dynamic, dynamic> data, String opponentPrefix) {
    final emote = data['${opponentPrefix}_emote'];
    final emoteTime = data['${opponentPrefix}_emoteTime'];
    if (emote == null || emoteTime == null) return;

    final t = (emoteTime as num).toInt();
    if (_opponentEmoteTime == null || t > _opponentEmoteTime!) {
      _opponentEmoteTime = t;
      _opponentEmote = emote.toString();
      Future.delayed(const Duration(seconds: 3), () {
        if (_opponentEmoteTime == t) {
          _opponentEmote = null;
          notifyListeners();
        }
      });
    }
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _updateSecondsRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSecondsRemaining();
      if (_secondsRemaining <= 0) {
        _countdownTimer?.cancel();
      }
      notifyListeners();
    });
  }

  void _updateSecondsRemaining() {
    if (_matchEndTimeMs == null) {
      _secondsRemaining = _matchDurationSeconds;
      return;
    }
    final left = ((_matchEndTimeMs! - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    _secondsRemaining = left.clamp(0, _matchDurationSeconds);
  }

  void _scheduleMatchEnd() {
    _matchEndTimer?.cancel();
    if (_matchEndTimeMs == null) return;
    final delay = _matchEndTimeMs! - DateTime.now().millisecondsSinceEpoch;
    if (delay <= 0) {
      _finishMatchOnServer();
      return;
    }
    _matchEndTimer = Timer(Duration(milliseconds: delay), _finishMatchOnServer);
  }

  Future<void> _finishMatchOnServer() async {
    if (_currentMatchId == null || _state != MatchState.playing) return;
    final winnerId = _localScore >= _opponentScore ? _localUserId : null;
    await _realtimeService.updateGameState(
      _currentMatchId!,
      'finished',
      winnerId: winnerId,
    );
  }

  void _onMatchFinished() {
    if (_state == MatchState.finished) return;
    _state = MatchState.finished;
    _matchEndTimer?.cancel();
    _countdownTimer?.cancel();

    final won = _localScore > _opponentScore;
    final draw = _localScore == _opponentScore;
    _matchResultMessage = draw
        ? 'Draw — $_localScore pts each'
        : won
            ? 'You win — $_localScore vs $_opponentScore'
            : 'You lose — $_localScore vs $_opponentScore';

    if (draw) {
      _logMatchFinished('draw');
    } else {
      _logMatchFinished(won ? 'win' : 'loss');
    }

    _awardExp(won: won && !draw);
    notifyListeners();
  }

  Future<void> _awardExp({required bool won}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.addMultiplayerExp(
      uid,
      durationSeconds: _matchDurationSeconds,
      won: won,
    );
  }

  Future<void> _logMatchFinished(String winOrLoss) async {
    if (_matchEndLogged) return;
    _matchEndLogged = true;
    final duration = _matchStartedAt == null
        ? _matchDurationSeconds
        : DateTime.now().difference(_matchStartedAt!).inSeconds;
    await _analytics.logMultiplayerMatchFinished(
      mode: AnalyticsModes.quickMatch,
      winOrLoss: winOrLoss,
      matchDurationSeconds: duration,
      opponentType: 'online_random',
    );
  }

  void syncLocalBoard(String userId, List<int> board, int score, {bool force = false}) {
    _localScore = score;
    if (_currentMatchId == null || _state != MatchState.playing) return;

    final prefix = _localPlayerPrefix ??
        ((_localUserId == userId) ? _localPlayerPrefix : null) ??
        'player1';

    _realtimeService.syncBoardState(
      matchId: _currentMatchId!,
      playerId: prefix,
      board: board,
      score: score,
      forceSync: force,
    );
  }

  Future<void> sendEmote(String emote, String userId) async {
    if (_currentMatchId == null || _state != MatchState.playing) return;
    final prefix = _localPlayerPrefix ?? 'player1';
    await _realtimeService.sendEmote(
      matchId: _currentMatchId!,
      playerId: prefix,
      emote: emote,
    );
  }

  Future<void> cancelSearch(String userId) async {
    await _matchmakingService.cancelMatchmaking(userId);
    _queueSubscription?.cancel();
    _queueSubscription = null;
    if (_state == MatchState.searching) {
      _state = MatchState.idle;
      notifyListeners();
    }
  }

  Future<void> leaveMatch(String userId) async {
    await cancelSearch(userId);
    if (_currentMatchId != null && _state == MatchState.playing) {
      await _finishMatchOnServer();
    }
    _resetMatch();
    notifyListeners();
  }

  void _resetMatch() {
    _matchSubscription?.cancel();
    _matchEndTimer?.cancel();
    _countdownTimer?.cancel();
    _currentMatchId = null;
    _localPlayerPrefix = null;
    _state = MatchState.idle;
    _opponentBoard = List.filled(16, 0);
    _opponentScore = 0;
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _queueSubscription?.cancel();
    _matchEndTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
