import 'dart:ui';

enum Direction { up, down, left, right }

enum GameMode { classic, adventure, endless, timeAttack }

extension GameModeLabel on GameMode {
  String get label {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.adventure:
        return 'Adventure';
      case GameMode.endless:
        return 'Endless';
      case GameMode.timeAttack:
        return 'Time Attack';
    }
  }

  String get tagline {
    switch (this) {
      case GameMode.classic:
        return 'Pure snake. No obstacles, just grow.';
      case GameMode.adventure:
        return 'Unlimited levels, obstacles & objectives.';
      case GameMode.endless:
        return 'Survive as long as you can. Top score wins.';
      case GameMode.timeAttack:
        return '90 seconds. Grab every point you can.';
    }
  }
}

enum FoodType { apple, banana, cherry, grape, coin, star }

extension FoodInfo on FoodType {
  int get points {
    switch (this) {
      case FoodType.apple:
        return 10;
      case FoodType.banana:
        return 15;
      case FoodType.cherry:
        return 20;
      case FoodType.grape:
        return 25;
      case FoodType.coin:
        return 50;
      case FoodType.star:
        return 100;
    }
  }

  Color get color {
    switch (this) {
      case FoodType.apple:
        return const Color(0xFFFF3B30);
      case FoodType.banana:
        return const Color(0xFFFFCC00);
      case FoodType.cherry:
        return const Color(0xFFFF2D78);
      case FoodType.grape:
        return const Color(0xFFAF52DE);
      case FoodType.coin:
        return const Color(0xFFFFD60A);
      case FoodType.star:
        return const Color(0xFF64D2FF);
    }
  }

  String get emoji {
    switch (this) {
      case FoodType.apple:
        return '🍎';
      case FoodType.banana:
        return '🍌';
      case FoodType.cherry:
        return '🍒';
      case FoodType.grape:
        return '🍇';
      case FoodType.coin:
        return '🪙';
      case FoodType.star:
        return '⭐';
    }
  }
}

enum PowerUpType { speed, slow, shield, magnet, doubleScore, ghost }

extension PowerUpInfo on PowerUpType {
  String get label {
    switch (this) {
      case PowerUpType.speed:
        return 'Speed Boost';
      case PowerUpType.slow:
        return 'Slow Motion';
      case PowerUpType.shield:
        return 'Shield';
      case PowerUpType.magnet:
        return 'Magnet';
      case PowerUpType.doubleScore:
        return 'Double Score';
      case PowerUpType.ghost:
        return 'Ghost Mode';
    }
  }

  String get icon {
    switch (this) {
      case PowerUpType.speed:
        return '⚡';
      case PowerUpType.slow:
        return '🐢';
      case PowerUpType.shield:
        return '🛡️';
      case PowerUpType.magnet:
        return '🧲';
      case PowerUpType.doubleScore:
        return '✖2';
      case PowerUpType.ghost:
        return '👻';
    }
  }

  Color get color {
    switch (this) {
      case PowerUpType.speed:
        return const Color(0xFFFF9500);
      case PowerUpType.slow:
        return const Color(0xFF64D2FF);
      case PowerUpType.shield:
        return const Color(0xFF30D158);
      case PowerUpType.magnet:
        return const Color(0xFFFF375F);
      case PowerUpType.doubleScore:
        return const Color(0xFFFFD60A);
      case PowerUpType.ghost:
        return const Color(0xFFE5E5EA);
    }
  }
}

class Cell {
  final int x;
  final int y;
  const Cell(this.x, this.y);
  @override
  bool operator ==(Object other) =>
      other is Cell && other.x == x && other.y == y;
  @override
  int get hashCode => x * 1000 + y;
  Cell offset(Direction d) {
    switch (d) {
      case Direction.up:
        return Cell(x, y - 1);
      case Direction.down:
        return Cell(x, y + 1);
      case Direction.left:
        return Cell(x - 1, y);
      case Direction.right:
        return Cell(x + 1, y);
    }
  }
}

class FoodItem {
  Cell cell;
  FoodType type;
  int bornMs;
  int? expiresMs;
  FoodItem(this.cell, this.type, this.bornMs, [this.expiresMs]);
}

class PowerUpItem {
  Cell cell;
  PowerUpType type;
  int bornMs;
  PowerUpItem(this.cell, this.type, this.bornMs);
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  Color color;
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.color);
}

class LevelTheme {
  final String name;
  final Color bg;
  final Color gridA;
  final Color gridB;
  final Color snakeHead;
  final Color snakeBody;
  final Color obstacle;
  final Color accent;
  const LevelTheme(this.name, this.bg, this.gridA, this.gridB, this.snakeHead,
      this.snakeBody, this.obstacle, this.accent);
}

const List<LevelTheme> themes = [
  LevelTheme('Neon Night', Color(0xFF0B1026), Color(0xFF121A3D),
      Color(0xFF0E1430), Color(0xFF30D158), Color(0xFF64D2FF),
      Color(0xFF5856D6), Color(0xFFFF9F0A)),
  LevelTheme('Sunset Desert', Color(0xFF2B1408), Color(0xFF3A1E0E),
      Color(0xFF331A0B), Color(0xFFFF9F0A), Color(0xFFFFD60A),
      Color(0xFF8E4A1F), Color(0xFFFF375F)),
  LevelTheme('Ocean Deep', Color(0xFF062A33), Color(0xFF0A3642),
      Color(0xFF08303B), Color(0xFF64D2FF), Color(0xFF30D158),
      Color(0xFF0A84FF), Color(0xFFFFD60A)),
  LevelTheme('Mystic Forest', Color(0xFF0B2416), Color(0xFF12301F),
      Color(0xFF0E2A1A), Color(0xFF7DFF6B), Color(0xFF30D158),
      Color(0xFF2E5B3A), Color(0xFFFFCC00)),
  LevelTheme('Candy Pop', Color(0xFF2A0A2E), Color(0xFF38123E),
      Color(0xFF310E35), Color(0xFFFF6EC7), Color(0xFFAF52DE),
      Color(0xFFFF375F), Color(0xFF64D2FF)),
  LevelTheme('Volcano', Color(0xFF26090A), Color(0xFF331012),
      Color(0xFF2C0D0E), Color(0xFFFF453A), Color(0xFFFF9500),
      Color(0xFF5C1A1A), Color(0xFFFFD60A)),
  LevelTheme('Frozen Ice', Color(0xFF0E2233), Color(0xFF162F45),
      Color(0xFF122A3D), Color(0xFFA6E7FF), Color(0xFF64D2FF),
      Color(0xFF7FA8C9), Color(0xFFFF9F0A)),
  LevelTheme('Galaxy', Color(0xFF12082B), Color(0xFF1B0F3D),
      Color(0xFF160B34), Color(0xFFBF5AF2), Color(0xFF64D2FF),
      Color(0xFF5E5CE6), Color(0xFFFFD60A)),
];

enum ObjectiveKind { foods, score, survive }

class LevelSpec {
  final int level;
  final LevelTheme theme;
  final ObjectiveKind objective;
  final int targetFoods;
  final int targetScore;
  final int targetSeconds;
  final int obstacleCount;
  final int baseIntervalMs;
  LevelSpec(this.level, this.theme, this.objective, this.targetFoods,
      this.targetScore, this.targetSeconds, this.obstacleCount,
      this.baseIntervalMs);

  static LevelSpec forLevel(int level) {
    final theme = themes[(level - 1) % themes.length];
    final objective = ObjectiveKind.values[(level - 1) % 3];
    final foods = 5 + level * 2;
    final score = 100 + level * 60;
    final survive = 30 + level * 10;
    final obstacles = level <= 1 ? 0 : (4 + level * 2).clamp(0, 42);
    final interval = (185 - level * 5).clamp(95, 185);
    return LevelSpec(level, theme, objective, foods, score, survive, obstacles,
        interval);
  }

  String get objectiveText {
    switch (objective) {
      case ObjectiveKind.foods:
        return 'Eat $targetFoods foods';
      case ObjectiveKind.score:
        return 'Reach $targetScore points';
      case ObjectiveKind.survive:
        return 'Survive ${targetSeconds}s';
    }
  }
}
