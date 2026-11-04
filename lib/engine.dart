import 'dart:math';
import 'dart:ui' show Color;
import 'models.dart';

enum GameStatus { playing, paused, gameOver, levelComplete }

class ActivePower {
  final PowerUpType type;
  int remainingMs;
  ActivePower(this.type, this.remainingMs);
}

class SnakeGame {
  static const int cols = 17;
  static const int rows = 29;

  final GameMode mode;
  final int level;
  final LevelSpec? spec;
  final Random _rnd;

  List<Cell> snake = [];
  List<Cell> prevSnake = [];
  Direction direction = Direction.right;
  final List<Direction> _queue = [];
  Set<Cell> obstacles = {};
  List<FoodItem> foods = [];
  PowerUpItem? powerUp;
  List<Particle> particles = [];
  List<ActivePower> activePowers = [];

  int score = 0;
  int foodsEaten = 0;
  int elapsedMs = 0;
  int timeLeftMs = 90000;
  int powerUpSpawnTimerMs = 0;
  GameStatus status = GameStatus.playing;
  String? deathReason;
  String? lastEvent;

  SnakeGame({required this.mode, this.level = 1})
      : spec = mode == GameMode.adventure ? LevelSpec.forLevel(level) : null,
        _rnd = Random(mode == GameMode.adventure
            ? level * 7919 + 13
            : DateTime.now().millisecondsSinceEpoch) {
    _reset();
  }

  LevelTheme get theme {
    if (spec != null) return spec!.theme;
    if (mode == GameMode.endless) {
      return themes[(score ~/ 300) % themes.length];
    }
    if (mode == GameMode.timeAttack) return themes[4];
    return themes[0];
  }

  int get intervalMs {
    int base;
    if (spec != null) {
      base = spec!.baseIntervalMs;
    } else if (mode == GameMode.classic) {
      base = 170;
    } else if (mode == GameMode.timeAttack) {
      base = 150;
    } else {
      base = (175 - (score ~/ 200) * 6).clamp(95, 175);
    }
    if (hasPower(PowerUpType.speed)) base = (base * 0.62).round();
    if (hasPower(PowerUpType.slow)) base = (base * 1.65).round();
    return base;
  }

  bool hasPower(PowerUpType t) =>
      activePowers.any((p) => p.type == t && p.remainingMs > 0);
  bool get shieldOn => hasPower(PowerUpType.shield);
  bool get ghostOn => hasPower(PowerUpType.ghost);
  bool get magnetOn => hasPower(PowerUpType.magnet);
  bool get doubleOn => hasPower(PowerUpType.doubleScore);

  void _reset() {
    final cx = cols ~/ 2;
    final cy = rows ~/ 2;
    snake = [Cell(cx, cy), Cell(cx - 1, cy), Cell(cx - 2, cy), Cell(cx - 3, cy)];
    prevSnake = List.of(snake);
    direction = Direction.right;
    _queue.clear();
    score = 0;
    foodsEaten = 0;
    elapsedMs = 0;
    timeLeftMs = 90000;
    activePowers.clear();
    particles.clear();
    powerUp = null;
    status = GameStatus.playing;
    deathReason = null;
    lastEvent = null;
    obstacles = {};
    if (mode == GameMode.adventure && spec != null) {
      obstacles = _generateObstacles(spec!.obstacleCount, Cell(cx, cy));
    } else if (mode == GameMode.endless) {
      obstacles = _generateObstacles(6, Cell(cx, cy));
    }
    foods = [];
    for (var i = 0; i < 3; i++) {
      _spawnFood();
    }
    powerUpSpawnTimerMs = 9000;
  }

  void restart() => _reset();

  void setDirection(Direction d) {
    final last = _queue.isEmpty ? direction : _queue.last;
    if (_isOpposite(last, d) || last == d) return;
    if (_queue.length < 3) _queue.add(d);
  }

  bool _isOpposite(Direction a, Direction b) {
    return (a == Direction.up && b == Direction.down) ||
        (a == Direction.down && b == Direction.up) ||
        (a == Direction.left && b == Direction.right) ||
        (a == Direction.right && b == Direction.left);
  }

  bool _isFree(Cell c, {bool allowFood = false}) {
    if (c.x < 0 || c.x >= cols || c.y < 0 || c.y >= rows) return false;
    if (obstacles.contains(c)) return false;
    if (snake.contains(c)) return false;
    if (!allowFood && foods.any((f) => f.cell == c)) return false;
    if (powerUp != null && powerUp!.cell == c) return false;
    return true;
  }

  Set<Cell> _generateObstacles(int count, Cell start) {
    if (count <= 0) return {};
    for (var attempt = 0; attempt < 6; attempt++) {
      final set = <Cell>{};
      final pattern = (spec?.level ?? 1) % 4;
      var guard = 0;
      while (set.length < count && guard < 500) {
        guard++;
        Cell c;
        if (pattern == 1) {
          // horizontal / vertical bars
          final horizontal = _rnd.nextBool();
          final bx = _rnd.nextInt(cols - 4) + 2;
          final by = _rnd.nextInt(rows - 4) + 2;
          for (var i = 0; i < 3 && set.length < count; i++) {
            c = horizontal ? Cell(bx + i, by) : Cell(bx, by + i);
            if ((c.x - start.x).abs() + (c.y - start.y).abs() > 4) set.add(c);
          }
          continue;
        } else if (pattern == 2) {
          // 2x2 blocks
          final bx = _rnd.nextInt(cols - 2);
          final by = _rnd.nextInt(rows - 2);
          for (var dx = 0; dx < 2; dx++) {
            for (var dy = 0; dy < 2; dy++) {
              if (set.length >= count) break;
              final c2 = Cell(bx + dx, by + dy);
              if ((c2.x - start.x).abs() + (c2.y - start.y).abs() > 4) {
                set.add(c2);
              }
            }
          }
          continue;
        } else {
          c = Cell(_rnd.nextInt(cols), _rnd.nextInt(rows));
          if ((c.x - start.x).abs() + (c.y - start.y).abs() > 4) set.add(c);
        }
      }
      // Fairness: at least 55% of the board must stay reachable from start.
      if (_reachableCount(start, set) >= (cols * rows * 0.55).round()) {
        return set;
      }
    }
    return {};
  }

  int _reachableCount(Cell start, Set<Cell> obs) {
    final seen = <Cell>{start};
    final queue = <Cell>[start];
    var idx = 0;
    while (idx < queue.length) {
      final cur = queue[idx++];
      for (final d in Direction.values) {
        final n = cur.offset(d);
        if (n.x < 0 || n.x >= cols || n.y < 0 || n.y >= rows) continue;
        if (obs.contains(n) || seen.contains(n)) continue;
        seen.add(n);
        queue.add(n);
      }
    }
    return seen.length;
  }

  void _spawnFood() {
    FoodType type;
    final roll = _rnd.nextInt(100);
    if (roll < 45) {
      type = FoodType.apple;
    } else if (roll < 65) {
      type = FoodType.banana;
    } else if (roll < 82) {
      type = FoodType.cherry;
    } else if (roll < 94) {
      type = FoodType.grape;
    } else if (roll < 98) {
      type = FoodType.coin;
    } else {
      type = FoodType.star;
    }
    for (var i = 0; i < 200; i++) {
      final c = Cell(_rnd.nextInt(cols), _rnd.nextInt(rows));
      if (_isFree(c)) {
        final timed = type == FoodType.coin || type == FoodType.star;
        foods.add(FoodItem(c, type, elapsedMs,
            timed ? elapsedMs + 9000 : null));
        return;
      }
    }
  }

  void _spawnPowerUp() {
    final types = PowerUpType.values;
    final type = types[_rnd.nextInt(types.length)];
    for (var i = 0; i < 200; i++) {
      final c = Cell(_rnd.nextInt(cols), _rnd.nextInt(rows));
      if (_isFree(c)) {
        powerUp = PowerUpItem(c, type, elapsedMs);
        return;
      }
    }
  }

  void _burst(Cell c, Color color) {
    for (var i = 0; i < 14; i++) {
      final a = _rnd.nextDouble() * 6.283;
      final speed = 0.6 + _rnd.nextDouble() * 1.6;
      particles.add(Particle(c.x + 0.5, c.y + 0.5, cos(a) * speed,
          sin(a) * speed, 0.5 + _rnd.nextDouble() * 0.4, color));
    }
  }

  void updateParticles(double dtSeconds) {
    for (final p in particles) {
      p.x += p.vx * dtSeconds * 8;
      p.y += p.vy * dtSeconds * 8;
      p.life -= dtSeconds;
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  /// One grid step. Returns an event name for sound: eat, power, die, level, bonus.
  String? step() {
    if (status != GameStatus.playing) return null;
    lastEvent = null;
    final interval = intervalMs;
    elapsedMs += interval;
    if (mode == GameMode.timeAttack) {
      timeLeftMs -= interval;
      if (timeLeftMs <= 0) {
        timeLeftMs = 0;
        _die('Time up!');
        return 'die';
      }
    }

    if (_queue.isNotEmpty) direction = _queue.removeAt(0);
    prevSnake = List.of(snake);
    var head = snake.first.offset(direction);

    // Ghost: wrap through walls.
    if (ghostOn) {
      head = Cell((head.x + cols) % cols, (head.y + rows) % rows);
    } else if (head.x < 0 || head.x >= cols || head.y < 0 || head.y >= rows) {
      _die('Hit the wall');
      return 'die';
    }

    final hitsObstacle = obstacles.contains(head);
    if (hitsObstacle && !ghostOn) {
      if (shieldOn) {
        activePowers.removeWhere((p) => p.type == PowerUpType.shield);
        obstacles.remove(head);
        _burst(head, theme.obstacle);
        lastEvent = 'shield';
      } else {
        _die('Hit an obstacle');
        return 'die';
      }
    }

    final willGrow = foods.any((f) => f.cell == head);
    final bodyToCheck =
        willGrow ? snake : snake.sublist(0, snake.length - 1);
    if (!ghostOn && bodyToCheck.contains(head)) {
      _die('Bit your own tail');
      return 'die';
    }

    snake.insert(0, head);

    // Food
    FoodItem? eaten;
    for (final f in foods) {
      if (f.cell == head) {
        eaten = f;
        break;
      }
    }
    if (eaten != null) {
      foods.remove(eaten);
      foodsEaten++;
      var pts = eaten.type.points;
      if (doubleOn) pts *= 2;
      score += pts;
      _burst(head, eaten.type.color);
      lastEvent =
          (eaten.type == FoodType.coin || eaten.type == FoodType.star)
              ? 'bonus'
              : 'eat';
      _spawnFood();
      // Endless gets harder: add an obstacle every 300 points.
      if (mode == GameMode.endless && score % 300 < pts) {
        _addOneObstacle();
      }
    } else {
      snake.removeLast();
    }

    // Power-up pickup
    if (powerUp != null && powerUp!.cell == head) {
      final t = powerUp!.type;
      powerUp = null;
      _burst(head, t.color);
      if (t == PowerUpType.shield) {
        activePowers.add(ActivePower(t, 60000));
      } else {
        activePowers.add(ActivePower(t, 8000));
      }
      score += 20;
      lastEvent = 'power';
    }

    // Timers
    for (final p in activePowers) {
      p.remainingMs -= interval;
    }
    activePowers.removeWhere((p) =>
        p.remainingMs <= 0 && p.type != PowerUpType.shield);
    // Shield without a hit stays until used, but cap it at 60s via its timer:
    activePowers.removeWhere(
        (p) => p.type == PowerUpType.shield && p.remainingMs <= 0);

    // Bonus food expiry
    foods.removeWhere(
        (f) => f.expiresMs != null && elapsedMs > f.expiresMs!);
    while (foods.length < 3) {
      _spawnFood();
    }

    // Magnet: pull nearby foods one cell closer.
    if (magnetOn) {
      for (final f in foods) {
        final dx = snake.first.x - f.cell.x;
        final dy = snake.first.y - f.cell.y;
        if (dx.abs() + dy.abs() <= 3 && dx.abs() + dy.abs() > 1) {
          Cell next = f.cell;
          if (dx.abs() >= dy.abs()) {
            next = Cell(f.cell.x + dx.sign, f.cell.y);
          } else {
            next = Cell(f.cell.x, f.cell.y + dy.sign);
          }
          if (_isFree(next, allowFood: true) && !snake.contains(next)) {
            f.cell = next;
          }
        }
      }
    }

    // Power-up spawning
    if (mode != GameMode.classic) {
      powerUpSpawnTimerMs -= interval;
      if (powerUpSpawnTimerMs <= 0) {
        powerUpSpawnTimerMs = 11000 + _rnd.nextInt(6000);
        if (powerUp == null) _spawnPowerUp();
      }
      if (powerUp != null && elapsedMs - powerUp!.bornMs > 12000) {
        powerUp = null;
      }
    }

    // Adventure objective
    if (mode == GameMode.adventure && spec != null) {
      var done = false;
      switch (spec!.objective) {
        case ObjectiveKind.foods:
          done = foodsEaten >= spec!.targetFoods;
          break;
        case ObjectiveKind.score:
          done = score >= spec!.targetScore;
          break;
        case ObjectiveKind.survive:
          done = elapsedMs >= spec!.targetSeconds * 1000;
          break;
      }
      if (done) {
        status = GameStatus.levelComplete;
        lastEvent = 'level';
        return 'level';
      }
    }
    return lastEvent;
  }

  void _addOneObstacle() {
    for (var i = 0; i < 100; i++) {
      final c = Cell(_rnd.nextInt(cols), _rnd.nextInt(rows));
      if (_isFree(c)) {
        obstacles.add(c);
        return;
      }
    }
  }

  void _die(String reason) {
    status = GameStatus.gameOver;
    deathReason = reason;
    if (snake.isNotEmpty) _burst(snake.first, theme.snakeHead);
  }

  double objectiveProgress() {
    if (spec == null) return 0;
    switch (spec!.objective) {
      case ObjectiveKind.foods:
        return (foodsEaten / spec!.targetFoods).clamp(0.0, 1.0);
      case ObjectiveKind.score:
        return (score / spec!.targetScore).clamp(0.0, 1.0);
      case ObjectiveKind.survive:
        return (elapsedMs / (spec!.targetSeconds * 1000)).clamp(0.0, 1.0);
    }
  }
}
