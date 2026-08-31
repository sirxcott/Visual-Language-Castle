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

  void dispose() => _player.dispose();
}
