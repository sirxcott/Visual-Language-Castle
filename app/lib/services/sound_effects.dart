import 'package:audioplayers/audioplayers.dart';

/// Plays short, tactile placement feedback for the Working Wall.
///
/// No dedicated Settings screen exists yet in the app, so the on/off flag is
/// exposed here (defaulting to on) for a future Settings toggle rather than
/// building new Settings UI as part of this milestone.
class SoundEffects {
  SoundEffects._();

  static final SoundEffects instance = SoundEffects._();

  bool enabled = true;

  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  AudioPlayer? _gatePlayer;

  /// Plays the sticky-note placement/settle tap. Safe to call frequently;
  /// failures (e.g. an unsupported platform) are swallowed since this is
  /// non-critical tactile feedback.
  Future<void> playPlacement() async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/sticky_tap.wav'), volume: 0.55);
    } on Object {
      // Ignore playback failures.
    }
  }

  /// Plays the castle gate cue: mechanism and chains, then hinge creak, then
  /// the settling thud. The asset's internal timing matches the entrance door
  /// animation, so it only needs to be started at the same moment.
  ///
  /// Never throws and never blocks: if audio is disabled or unavailable the
  /// entrance still opens and navigates normally.
  Future<void> playCastleGate() async {
    if (!enabled) return;
    try {
      final player = _gatePlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(AssetSource('audio/castle_gate.wav'), volume: 0.5);
    } on Object {
      // Ignore playback failures.
    }
  }

  void dispose() {
    _player.dispose();
    _gatePlayer?.dispose();
    _gatePlayer = null;
  }
}
