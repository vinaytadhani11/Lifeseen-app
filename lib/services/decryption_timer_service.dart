import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tableflow_plus/services/app_prefs_service.dart';

enum DecryptionStage {
  /// Not premium yet.
  none,

  /// First countdown after buying (`start_time` hours).
  initial,

  /// Replaces the initial countdown after Speed Up.
  boost,

  /// Additional countdown (`extended_time` hours).
  extra,

  /// Initial/boost finished, waiting for "Start Additional Time".
  awaitingExtra,

  /// Extra countdown finished.
  completed,
}

/// Local decryption countdown shown after a (local) purchase.
///
/// Only counts down while the app is in the foreground. When the app is
/// restarted a running countdown is [isPaused] until [resume] is called.
class DecryptionTimerService extends ChangeNotifier
    with WidgetsBindingObserver {
  DecryptionTimerService(this._prefs) {
    _load();
    WidgetsBinding.instance.addObserver(this);
  }

  final AppPrefsService _prefs;

  DecryptionStage _stage = DecryptionStage.none;
  int _remaining = 0;
  int _total = 0;
  String _status = 'NOT_STARTED';
  String _type = '';
  int _anchorMillis = 0;
  bool _paused = false;
  Timer? _timer;
  int _ticksSincePersist = 0;

  DecryptionStage get stage => _stage;
  int get totalSeconds => _total;
  bool get isPaused => _paused;

  /// Premium user with a timer phase after purchase.
  bool get isActive =>
      _prefs.isUserPremium && _stage != DecryptionStage.none;

  bool get needsInitialStart =>
      _prefs.isUserPremium &&
      (_status == 'NOT_STARTED' || _stage == DecryptionStage.none);

  int get remainingSeconds {
    if (_status != 'RUNNING') return _remaining < 0 ? 0 : _remaining;
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - _anchorMillis) ~/ 1000;
    final left = _remaining - elapsed;
    return left < 0 ? 0 : left;
  }

  bool get isCounting =>
      !_paused &&
      (_stage == DecryptionStage.initial ||
          _stage == DecryptionStage.boost ||
          _stage == DecryptionStage.extra);

  /// 0..1 progress of the current countdown.
  double get progress {
    switch (_stage) {
      case DecryptionStage.none:
        return 0;
      case DecryptionStage.awaitingExtra:
      case DecryptionStage.completed:
        return 1;
      case DecryptionStage.initial:
      case DecryptionStage.boost:
      case DecryptionStage.extra:
        if (_total <= 0) return 0;
        return (1 - _remaining / _total).clamp(0.0, 1.0);
    }
  }

  void _load() {
    final saved = _prefs.decryptionStage;
    _stage = DecryptionStage.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => DecryptionStage.none,
    );
    _remaining = _prefs.decryptionRemainingSeconds;
    _total = _prefs.decryptionTotalSeconds;
    _status = _prefs.timerStatus;
    _type = _prefs.timerType;
    _anchorMillis = _prefs.timerAnchorMillis;
    _paused = _status == 'PAUSED';

    if (_status == 'RUNNING') {
      _applyWallClock();
      return;
    }
    if (_paused &&
        _prefs.isUserPremium &&
        _prefs.continueWhereYouLeftOff) {
      _paused = false;
      _status = 'RUNNING';
      _anchorMillis = DateTime.now().millisecondsSinceEpoch;
      unawaited(_prefs.setContinueWhereYouLeftOff(false));
      _persist();
      _startTimer();
    }
  }

  /// Case C: remaining minus time spent since the last anchor.
  void _applyWallClock() {
    final left = remainingSeconds;
    _remaining = left;
    _anchorMillis = DateTime.now().millisecondsSinceEpoch;
    if (left <= 0) {
      _finishPhase();
      return;
    }
    _paused = false;
    _persist();
    _startTimer();
  }

  /// Starts the first countdown right after a purchase.
  void startInitial(int hours) {
    _begin(DecryptionStage.initial, hours);
  }

  /// Speed Up: the boost countdown replaces the initial one.
  void startBoost(int hours) => _begin(DecryptionStage.boost, hours);

  /// Start Additional Time.
  void startExtra(int hours) => _begin(DecryptionStage.extra, hours);

  /// Premium expired: keep the saved phase but do not keep counting.
  void pauseBecausePremiumEnded() {
    _timer?.cancel();
    if (_status != 'RUNNING') return;
    _remaining = remainingSeconds;
    _anchorMillis = DateTime.now().millisecondsSinceEpoch;
    _status = 'PAUSED';
    _paused = true;
    _persist();
    notifyListeners();
  }

  /// Test: end the running INITIAL, BOOST or EXTRA countdown immediately.
  void completeCurrentPhase() {
    if (!isCounting && !_paused) return;
    if (_stage != DecryptionStage.initial &&
        _stage != DecryptionStage.boost &&
        _stage != DecryptionStage.extra) {
      return;
    }
    _finishPhase();
  }

  /// Test: end only the `start_time` countdown that begins after Weekly/Monthly.
  void completeInitialPhase() {
    if (_stage != DecryptionStage.initial) return;
    if (!isCounting && !_paused) return;
    _finishPhase();
  }

  /// Test: clear the countdown so premium UI is gone.
  void resetForTest() {
    _timer?.cancel();
    _stage = DecryptionStage.none;
    _remaining = 0;
    _total = 0;
    _status = 'NOT_STARTED';
    _type = '';
    _anchorMillis = 0;
    _paused = false;
    _persist();
    notifyListeners();
  }

  /// Continue after the app was reopened on a paused timer.
  void resume() {
    if (!_paused) return;
    _paused = false;
    _status = 'RUNNING';
    _anchorMillis = DateTime.now().millisecondsSinceEpoch;
    unawaited(_prefs.setContinueWhereYouLeftOff(false));
    _persist();
    _startTimer();
    notifyListeners();
  }

  void _begin(DecryptionStage stage, int hours) {
    final safeHours = hours < 0 ? 0 : hours;
    _paused = false;
    _stage = stage;
    _type = switch (stage) {
      DecryptionStage.boost => 'BOOST',
      DecryptionStage.extra => 'EXTRA',
      _ => 'INITIAL',
    };
    if (safeHours == 0) {
      _total = 0;
      _remaining = 0;
      _status = 'COMPLETED';
      _timer?.cancel();
      _stage = stage == DecryptionStage.extra
          ? DecryptionStage.completed
          : DecryptionStage.awaitingExtra;
      _persist();
      notifyListeners();
      return;
    }
    _total = safeHours * 3600;
    _remaining = _total;
    _status = 'RUNNING';
    _anchorMillis = DateTime.now().millisecondsSinceEpoch;
    _persist();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!isCounting) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!isCounting) {
      _timer?.cancel();
      return;
    }
    if (remainingSeconds <= 0) {
      _finishPhase();
      return;
    }
    if (++_ticksSincePersist >= 5) {
      _snapshot();
    }
    notifyListeners();
  }

  void _finishPhase() {
    _timer?.cancel();
    _remaining = 0;
    _status = 'COMPLETED';
    _stage = _type == 'EXTRA' || _stage == DecryptionStage.extra
        ? DecryptionStage.completed
        : DecryptionStage.awaitingExtra;
    _persist();
    notifyListeners();
  }

  void _snapshot() {
    _remaining = remainingSeconds;
    _anchorMillis = DateTime.now().millisecondsSinceEpoch;
    _persist();
  }

  void _persist() {
    _ticksSincePersist = 0;
    unawaited(
      _prefs.saveDecryption(
        stage: _stage.name,
        remainingSeconds: _remaining,
        totalSeconds: _total,
        type: _type,
        status: _status,
        anchorMillis: _anchorMillis,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isActive) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_status == 'RUNNING' && remainingSeconds <= 0) {
          _finishPhase();
        } else {
          _startTimer();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_status == 'RUNNING') _snapshot();
        _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
