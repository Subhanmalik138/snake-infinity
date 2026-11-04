import 'package:flutter_test/flutter_test.dart';
import 'package:snake_infinity/engine.dart';
import 'package:snake_infinity/models.dart';

void main() {
  test('reverse direction is ignored', () {
    final g = SnakeGame(mode: GameMode.classic);
    g.setDirection(Direction.left); // opposite of right
    g.step();
    expect(g.snake.first.x, greaterThan(8));
  });
  test('wall hit ends classic game', () {
    final g = SnakeGame(mode: GameMode.classic);
    // drive right until wall
    for (var i = 0; i < 30 && g.status == GameStatus.playing; i++) {
      g.step();
    }
    expect(g.status, GameStatus.gameOver);
  });
  test('adventure levels are procedural and fair', () {
    for (var lvl = 1; lvl <= 20; lvl++) {
      final spec = LevelSpec.forLevel(lvl);
      expect(spec.obstacleCount, greaterThanOrEqualTo(0));
      final g = SnakeGame(mode: GameMode.adventure, level: lvl);
      expect(g.obstacles.length, lessThanOrEqualTo(spec.obstacleCount));
      // start cell must be free
      expect(g.obstacles.contains(g.snake.first), isFalse);
    }
  });
  test('eating grows snake and scores', () {
    final g = SnakeGame(mode: GameMode.classic);
    final head = g.snake.first;
    final next = head.offset(Direction.right);
    g.foods = [FoodItem(next, FoodType.apple, 0)];
    final len = g.snake.length;
    g.step();
    expect(g.snake.length, len + 1);
    expect(g.score, 10);
  });
  test('ghost passes through wall by wrapping', () {
    final g = SnakeGame(mode: GameMode.classic);
    g.activePowers.add(ActivePower(PowerUpType.ghost, 8000));
    for (var i = 0; i < 30 && g.status == GameStatus.playing; i++) {
      g.step();
    }
    // with ghost, hitting right wall wraps instead of dying immediately
    expect(g.status, isNot(GameStatus.gameOver));
  });
}
