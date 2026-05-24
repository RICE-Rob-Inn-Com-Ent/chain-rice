import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart';

/// Bridges Rive state machines and an optional Lottie [AnimationController] behind one API.
final class RiceMotionManager {
  StateMachineController? _rive;
  AnimationController? _lottie;
  LottieComposition? _lottieComposition;
  bool _ownsLottieController = false;

  /// Binds the first state machine named [stateMachineName] on [artboard].
  void bindRive(Artboard artboard, String stateMachineName) {
    _rive?.isActive = false;
    _rive = StateMachineController.fromArtboard(artboard, stateMachineName);
  }

  void clearRive() {
    _rive?.isActive = false;
    _rive = null;
  }

  /// Uses a caller-owned [AnimationController] plus a loaded [LottieComposition].
  void attachLottie(AnimationController controller, LottieComposition composition) {
    if (_ownsLottieController) {
      _lottie?.dispose();
    }
    _ownsLottieController = false;
    _lottie = controller;
    _lottieComposition = composition;
  }

  /// Creates and owns an [AnimationController]; dispose via [dispose].
  void bindLottie({
    required TickerProvider vsync,
    required Duration duration,
    required LottieComposition composition,
  }) {
    if (_ownsLottieController) {
      _lottie?.dispose();
    }
    _lottie = AnimationController(vsync: vsync, duration: duration);
    _lottieComposition = composition;
    _ownsLottieController = true;
  }

  void clearLottie() {
    if (_ownsLottieController) {
      _lottie?.dispose();
    }
    _ownsLottieController = false;
    _lottie = null;
    _lottieComposition = null;
  }

  /// Drives Rive inputs named like [state] (trigger, bool, or number) and restarts Lottie when bound.
  ///
  /// Name Rive inputs to match telemetry you forward from inventory (for example `fan_fast`).
  void triggerState(String state) {
    final sm = _rive;
    if (sm != null) {
      final trigger = sm.getTriggerInput(state);
      if (trigger != null) {
        trigger.fire();
      } else {
        sm.getBoolInput(state)?.value = true;
      }
    }

    final lottie = _lottie;
    final comp = _lottieComposition;
    if (lottie != null && comp != null) {
      lottie
        ..reset()
        ..forward();
    }
  }

  LottieComposition? get lottieComposition => _lottieComposition;

  AnimationController? get lottieController => _lottie;

  void dispose() {
    _rive?.isActive = false;
    _rive = null;
    if (_ownsLottieController) {
      _lottie?.dispose();
    }
    _ownsLottieController = false;
    _lottie = null;
    _lottieComposition = null;
  }
}
