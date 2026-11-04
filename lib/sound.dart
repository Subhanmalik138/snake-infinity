import 'package:just_audio/just_audio.dart';

class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._();

  AudioPlayer? _music;
  AudioPlayer? _sfx;
  bool musicEnabled = true;
  bool sfxEnabled = true;
  bool _musicStarted = false;

  Future<void> init() async {
    try {
      _music ??= AudioPlayer();
      _sfx ??= AudioPlayer();
    } catch (_) {
      // Audio is optional: game must never crash because of sound.
    }
  }

  Future<void> startMusic() async {
    if (!musicEnabled || _musicStarted) return;
    try {
      await _music?.setAsset('assets/sounds/music.wav');
      await _music?.setLoopMode(LoopMode.all);
      await _music?.setVolume(0.35);
      await _music?.play();
      _musicStarted = true;
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
    } catch (_) {}
    _musicStarted = false;
  }

  Future<void> setMusicEnabled(bool on) async {
    musicEnabled = on;
    if (on) {
      _musicStarted = false;
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> play(String name) async {
    if (!sfxEnabled) return;
    try {
      await _sfx?.setAsset('assets/sounds/$name.wav');
      await _sfx?.setVolume(0.8);
      await _sfx?.play();
    } catch (_) {}
  }

  Future<void> eat() => play('eat');
  Future<void> bonus() => play('bonus');
  Future<void> power() => play('power');
  Future<void> level() => play('level');
  Future<void> gameOver() => play('gameover');
  Future<void> click() => play('click');
}
