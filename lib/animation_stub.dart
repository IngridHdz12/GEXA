import 'package:flutter/material.dart';

class AnimationInfo {
  final AnimationTrigger trigger;
  final List<Function> Function() effectsBuilder;

  AnimationInfo({required this.trigger, required this.effectsBuilder});
}

enum AnimationTrigger {
  onPageLoad,
}

class VisibilityEffect {
  final Duration duration;
  VisibilityEffect({required this.duration});
}

class FadeEffect {
  final Curve curve;
  final Duration delay;
  final Duration duration;
  final double begin;
  final double end;

  FadeEffect({
    required this.curve,
    required this.delay,
    required this.duration,
    required this.begin,
    required this.end,
  });
}

class ScaleEffect {
  final Curve curve;
  final Duration delay;
  final Duration duration;
  final Offset begin;
  final Offset end;

  ScaleEffect({
    required this.curve,
    required this.delay,
    required this.duration,
    required this.begin,
    required this.end,
  });
}

class MoveEffect {
  final Curve curve;
  final Duration delay;
  final Duration duration;
  final Offset begin;
  final Offset end;

  MoveEffect({
    required this.curve,
    required this.delay,
    required this.duration,
    required this.begin,
    required this.end,
  });
}

class TiltEffect {
  final Curve curve;
  final Duration delay;
  final Duration duration;
  final Offset begin;
  final Offset end;

  TiltEffect({
    required this.curve,
    required this.delay,
    required this.duration,
    required this.begin,
    required this.end,
  });
}

// Extensión para .ms (milisegundos)
extension IntExtension on num {
  Duration get ms => Duration(milliseconds: this.toInt());
}
