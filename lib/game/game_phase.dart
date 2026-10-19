import '../config/constants.dart';

enum GamePhase { playing, ended }

enum PhaseOverride { auto, playing, ended }

GamePhase gamePhase(
  DateTime nowUtc, {
  PhaseOverride override = PhaseOverride.auto,
}) => switch (override) {
  PhaseOverride.playing => GamePhase.playing,
  PhaseOverride.ended => GamePhase.ended,
  PhaseOverride.auto =>
    nowUtc.isAfter(eventEnd) ? GamePhase.ended : GamePhase.playing,
};
