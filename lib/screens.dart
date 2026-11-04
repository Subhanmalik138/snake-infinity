import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engine.dart';
import 'models.dart';
import 'painter.dart';
import 'sound.dart';
import 'storage.dart';

const Color kBg = Color(0xFF0B1026);

// ---------------- HOME ----------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SaveData? save;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.load();
    SoundService.instance.musicEnabled = s.musicOn;
    SoundService.instance.sfxEnabled = s.sfxOn;
    await SoundService.instance.init();
    await SoundService.instance.startMusic();
    if (mounted) setState(() { save = s; loading = false; });
  }

  Future<void> _update() async {
    if (save != null) await StorageService.save(save!);
    if (mounted) setState(() {});
  }

  void _play(GameMode mode, {int level = 1}) async {
    await SoundService.instance.click();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => GameScreen(mode: mode, level: level, save: save!)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading || save == null) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    final s = save!;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('🐍 SNAKE INFINITY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
              const Text('3D Adventure',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF30D158),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4)),
              const SizedBox(height: 6),
              const Text(
                  'Unlimited levels • Power-ups • 4 game modes • Offline',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard('Best Classic', '${s.bestClassic}'),
                  const SizedBox(width: 8),
                  _statCard('Best Endless', '${s.bestEndless}'),
                  const SizedBox(width: 8),
                  _statCard('Best Time', '${s.bestTimeAttack}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statCard('Level reached', '${s.unlockedLevel}'),
                  const SizedBox(width: 8),
                  _statCard('Foods eaten', '${s.totalFoods}'),
                  const SizedBox(width: 8),
                  _statCard('Games', '${s.totalGames}'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _play(GameMode.adventure,
                    level: s.unlockedLevel),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF30D158),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: Text('▶  CONTINUE ADVENTURE — LEVEL ${s.unlockedLevel}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              _modeButton(GameMode.classic, '🟢', const Color(0xFF30D158)),
              _modeButton(GameMode.adventure, '🗺️', const Color(0xFFAF52DE)),
              _modeButton(GameMode.endless, '♾️', const Color(0xFF64D2FF)),
              _modeButton(GameMode.timeAttack, '⏱️', const Color(0xFFFF9500)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LevelsScreen(save: s)),
                  );
                  await _load();
                },
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Level Selection & Progression'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 20),
              const Text('SETTINGS',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _toggle('🎵  Background music', s.musicOn, (v) async {
                s.musicOn = v;
                await SoundService.instance.setMusicEnabled(v);
                await _update();
              }),
              _toggle('🔊  Sound effects', s.sfxOn, (v) async {
                s.sfxOn = v;
                SoundService.instance.sfxEnabled = v;
                await _update();
              }),
              _toggle('📳  Vibration', s.vibrationOn, (v) async {
                s.vibrationOn = v;
                await _update();
              }),
              const SizedBox(height: 12),
              const Text('CONTROLS',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ControlMode.values.map((c) {
                  final selected = s.control == c;
                  return ChoiceChip(
                    label: Text(
                        c == ControlMode.swipe
                            ? '👆 Swipe'
                            : c == ControlMode.dpad
                                ? '🎮 D-Pad'
                                : '🕹️ Joystick',
                        style: TextStyle(
                            color: selected ? Colors.black : Colors.white)),
                    selected: selected,
                    selectedColor: const Color(0xFF30D158),
                    backgroundColor: Colors.white12,
                    onSelected: (_) async {
                      s.control = c;
                      await _update();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'How to play: eat food to grow, avoid walls, obstacles and your own tail. '
                'Grab power-ups: ⚡ speed, 🐢 slow, 🛡️ shield, 🧲 magnet, ✖2 double score, 👻 ghost. '
                'A Content ID-style claim is not a thing here — this game is 100% offline, no ads, no internet needed.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
            color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(GameMode mode, String emoji, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _play(mode),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              border: Border.all(color: color.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    Text(mode.tagline,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(color: Colors.white)),
        value: value,
        activeColor: const Color(0xFF30D158),
        onChanged: onChanged,
      ),
    );
  }
}

// ---------------- LEVELS ----------------

class LevelsScreen extends StatelessWidget {
  final SaveData save;
  const LevelsScreen({super.key, required this.save});

  @override
  Widget build(BuildContext context) {
    final count = (save.unlockedLevel + 9).clamp(10, 200);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
          title: const Text('Level Selection'),
          backgroundColor: kBg,
          foregroundColor: Colors.white),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: count,
        itemBuilder: (context, i) {
          final level = i + 1;
          final unlocked = level <= save.unlockedLevel;
          final spec = LevelSpec.forLevel(level);
          return InkWell(
            onTap: unlocked
                ? () async {
                    await SoundService.instance.click();
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GameScreen(
                              mode: GameMode.adventure,
                              level: level,
                              save: save)),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: unlocked
                      ? spec.theme.accent.withOpacity(0.18)
                      : Colors.white10,
                  border: Border.all(
                      color: unlocked
                          ? spec.theme.accent
                          : Colors.white12),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(unlocked ? '⭐' : '🔒',
                      style: const TextStyle(fontSize: 20)),
                  Text('Level $level',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(spec.theme.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                  Text(spec.objectiveText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- GAME ----------------

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int level;
  final SaveData save;
  const GameScreen(
      {super.key, required this.mode, this.level = 1, required this.save});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SnakeGame game;
  Timer? _timer;
  double _acc = 0;
  double _interp = 0;
  double _timeSeconds = 0;
  bool _saved = false;
  Offset _joyKnob = Offset.zero;
  bool _joyActive = false;

  @override
  void initState() {
    super.initState();
    game = SnakeGame(mode: widget.mode, level: widget.level);
    _timer = Timer.periodic(const Duration(milliseconds: 33), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (!mounted) return;
    _timeSeconds += 0.033;
    game.updateParticles(0.033);
    if (game.status == GameStatus.playing) {
      _acc += 33;
      final interval = game.intervalMs;
      _interp = (_acc / interval).clamp(0.0, 1.0);
      while (_acc >= interval) {
        _acc -= interval;
        final event = game.step();
        if (event != null) _onEvent(event);
        if (game.status != GameStatus.playing) {
          _interp = 1;
          _onFinished();
          break;
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _onEvent(String event) {
    switch (event) {
      case 'eat':
        SoundService.instance.eat();
        break;
      case 'bonus':
        SoundService.instance.bonus();
        _vibrate();
        break;
      case 'power':
        SoundService.instance.power();
        _vibrate();
        break;
      case 'level':
        SoundService.instance.level();
        break;
      case 'die':
        SoundService.instance.gameOver();
        _vibrate();
        break;
      case 'shield':
        SoundService.instance.power();
        break;
    }
  }

  void _vibrate() {
    if (widget.save.vibrationOn) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _onFinished() async {
    if (_saved) return;
    _saved = true;
    final s = widget.save;
    s.totalGames += 1;
    s.totalFoods += game.foodsEaten;
    s.totalScore += game.score;
    if (game.snake.length > s.longestSnake) {
      s.longestSnake = game.snake.length;
    }
    if (widget.mode == GameMode.classic && game.score > s.bestClassic) {
      s.bestClassic = game.score;
    }
    if (widget.mode == GameMode.endless && game.score > s.bestEndless) {
      s.bestEndless = game.score;
    }
    if (widget.mode == GameMode.timeAttack && game.score > s.bestTimeAttack) {
      s.bestTimeAttack = game.score;
    }
    if (game.status == GameStatus.levelComplete &&
        widget.level >= s.unlockedLevel) {
      s.unlockedLevel = widget.level + 1;
    }
    await StorageService.save(s);
  }

  void _pause() {
    if (game.status == GameStatus.playing) {
      setState(() => game.status = GameStatus.paused);
    }
  }

  void _resume() {
    if (game.status == GameStatus.paused) {
      setState(() => game.status = GameStatus.playing);
    }
  }

  void _restart() {
    setState(() {
      _saved = false;
      _acc = 0;
      game = SnakeGame(mode: widget.mode, level: widget.level);
    });
  }

  void _steerFromDelta(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx > 10) {
        game.setDirection(Direction.right);
      } else if (delta.dx < -10) {
        game.setDirection(Direction.left);
      }
    } else {
      if (delta.dy > 10) {
        game.setDirection(Direction.down);
      } else if (delta.dy < -10) {
        game.setDirection(Direction.up);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = game.theme;
    final width = MediaQuery.of(context).size.width - 24;
    final arenaHeight = width * SnakeGame.rows / SnakeGame.cols;
    final best = widget.mode == GameMode.classic
        ? widget.save.bestClassic
        : widget.mode == GameMode.endless
            ? widget.save.bestEndless
            : widget.mode == GameMode.timeAttack
                ? widget.save.bestTimeAttack
                : 0;
    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
            // HUD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${widget.mode.label}${widget.mode == GameMode.adventure ? ' • Level ${widget.level} • ${theme.name}' : ''}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(
                            widget.mode == GameMode.timeAttack
                                ? 'Time left: ${(game.timeLeftMs / 1000).ceil()}s'
                                : widget.mode == GameMode.adventure
                                    ? '${game.spec!.objectiveText} — ${game.foodsEaten} foods'
                                    : 'Length: ${game.snake.length}',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('⭐ ${game.score}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Best: $best',
                          style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                  IconButton(
                      onPressed: _restart,
                      icon: const Icon(Icons.refresh, color: Colors.white)),
                  IconButton(
                      onPressed: game.status == GameStatus.paused
                          ? _resume
                          : _pause,
                      icon: Icon(
                          game.status == GameStatus.paused
                              ? Icons.play_arrow
                              : Icons.pause,
                          color: Colors.white)),
                ],
              ),
            ),
            if (widget.mode == GameMode.adventure)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: game.objectiveProgress(),
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                  ),
                ),
              ),
            if (game.activePowers.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Wrap(
                  spacing: 6,
                  children: game.activePowers.map((p) {
                    return Chip(
                      label: Text(
                          '${p.type.icon} ${p.type.label}${p.type == PowerUpType.shield ? '' : ' ${(p.remainingMs / 1000).ceil()}s'}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      backgroundColor: p.type.color.withOpacity(0.35),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 8),
            // Arena with swipe
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onPanUpdate: (d) => _steerFromDelta(d.delta),
                child: Container(
                  width: width,
                  height: arenaHeight,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                        painter: SnakePainter(game, _interp, _timeSeconds)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Controls
            Expanded(
              child: _controlsArea(),
            ),
              ],
            ),
          ),
          // Overlays on top of everything
          if (game.status == GameStatus.paused) Positioned.fill(child: _overlay(
            '⏸️ Paused',
            'Take a breath. Your snake is waiting.',
            [
              _overlayButton('Resume', _resume, const Color(0xFF30D158)),
              _overlayButton('Restart', _restart, Colors.white24),
              _overlayButton('Home', () => Navigator.pop(context),
                  Colors.white24),
            ],
          )),
          if (game.status == GameStatus.gameOver) Positioned.fill(child: _overlay(
            '💥 Game Over',
            '${game.deathReason ?? ''}\nScore: ${game.score} • Foods: ${game.foodsEaten} • Length: ${game.snake.length}',
            [
              _overlayButton('Play Again', _restart, const Color(0xFF30D158)),
              _overlayButton('Home', () => Navigator.pop(context),
                  Colors.white24),
            ],
          )),
          if (game.status == GameStatus.levelComplete) Positioned.fill(child: _overlay(
            '🎉 Level ${widget.level} Complete!',
            'Score: ${game.score} • Foods: ${game.foodsEaten}\nNext up: Level ${widget.level + 1} — ${LevelSpec.forLevel(widget.level + 1).theme.name}',
            [
              _overlayButton(
                  'Next Level',
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GameScreen(
                              mode: GameMode.adventure,
                              level: widget.level + 1,
                              save: widget.save)),
                    );
                  },
                  const Color(0xFF30D158)),
              _overlayButton('Replay', _restart, Colors.white24),
              _overlayButton('Home', () => Navigator.pop(context),
                  Colors.white24),
            ],
          )),
        ],
      ),
    );
  }

  Widget _overlay(String title, String body, List<Widget> buttons) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF1C1E2E),
              borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ...buttons,
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayButton(String label, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12)),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _controlsArea() {
    final control = widget.save.control;
    // Control switcher row
    final switcher = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ControlMode.values.map((c) {
          final sel = widget.save.control == c;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(c == ControlMode.swipe
                  ? 'Swipe'
                  : c == ControlMode.dpad
                      ? 'D-Pad'
                      : 'Joystick'),
              selected: sel,
              selectedColor: const Color(0xFF30D158),
              onSelected: (_) async {
                widget.save.control = c;
                await StorageService.save(widget.save);
                setState(() {});
              },
            ),
          );
        }).toList(),
      ),
    );

    if (control == ControlMode.dpad) {
      return Column(
        children: [
          switcher,
          const Spacer(),
          _dpadButton(Icons.arrow_upward, () => game.setDirection(Direction.up)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dpadButton(Icons.arrow_back,
                  () => game.setDirection(Direction.left)),
              const SizedBox(width: 64),
              _dpadButton(Icons.arrow_forward,
                  () => game.setDirection(Direction.right)),
            ],
          ),
          _dpadButton(
              Icons.arrow_downward, () => game.setDirection(Direction.down)),
          const Spacer(),
        ],
      );
    }

    if (control == ControlMode.joystick) {
      return Column(
        children: [
          switcher,
          const Spacer(),
          GestureDetector(
            onPanStart: (d) {
              setState(() {
                _joyKnob = d.localPosition;
                _joyActive = true;
              });
            },
            onPanUpdate: (d) {
              setState(() => _joyKnob = d.localPosition);
              _steerFromDelta(d.delta);
            },
            onPanEnd: (_) => setState(() => _joyActive = false),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                  color: Colors.white10, shape: BoxShape.circle),
              child: Stack(
                children: [
                  if (_joyActive)
                    Positioned(
                      left: _joyKnob.dx - 30,
                      top: _joyKnob.dy - 30,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                            color: Color(0xFF30D158), shape: BoxShape.circle),
                      ),
                    )
                  else
                    const Center(
                      child: Text('🕹️',
                          style: TextStyle(fontSize: 44)),
                    ),
                ],
              ),
            ),
          ),
          const Text('Drag the joystick to steer',
              style: TextStyle(color: Colors.white60)),
          const Spacer(),
        ],
      );
    }

    return Column(
      children: [
        switcher,
        const Spacer(),
        const Text('👆 Swipe anywhere on the arena to steer',
            style: TextStyle(color: Colors.white70, fontSize: 15)),
        const Text('The snake can never reverse into itself —\nopposite swipes are ignored.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54)),
        const Spacer(),
      ],
    );
  }

  Widget _dpadButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          height: 56,
          decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
