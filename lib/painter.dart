import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'engine.dart';
import 'models.dart';

class SnakePainter extends CustomPainter {
  final SnakeGame game;
  final double t; // interpolation 0..1 between prev and current snake
  final double timeSeconds;

  SnakePainter(this.game, this.t, this.timeSeconds);

  @override
  void paint(Canvas canvas, Size size) {
    final theme = game.theme;
    final cellW = size.width / SnakeGame.cols;
    final cellH = size.height / SnakeGame.rows;
    final cell = math.min(cellW, cellH);
    final ox = (size.width - cell * SnakeGame.cols) / 2;
    final oy = (size.height - cell * SnakeGame.rows) / 2;

    // Background
    final bgPaint = Paint()..color = theme.bg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Checkerboard arena
    for (var y = 0; y < SnakeGame.rows; y++) {
      for (var x = 0; x < SnakeGame.cols; x++) {
        final paint = Paint()
          ..color = (x + y) % 2 == 0 ? theme.gridA : theme.gridB;
        canvas.drawRect(
            Rect.fromLTWH(ox + x * cell, oy + y * cell, cell, cell), paint);
      }
    }

    // Soft floating glows in background
    final glowPaint = Paint()..color = theme.accent.withOpacity(0.06);
    canvas.drawCircle(
        Offset(ox + size.width * 0.2, oy + size.height * 0.25),
        cell * 3.2,
        glowPaint);
    canvas.drawCircle(
        Offset(ox + size.width * 0.85, oy + size.height * 0.7),
        cell * 2.6,
        glowPaint);

    Offset cellCenter(double cx, double cy) =>
        Offset(ox + cx * cell, oy + cy * cell);

    // Obstacles with 3D bevel
    for (final o in game.obstacles) {
      final rect = Rect.fromLTWH(
          ox + o.x * cell + 1, oy + o.y * cell + 1, cell - 2, cell - 2);
      final rrect =
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18));
      canvas.drawRRect(
          rrect, Paint()..color = theme.obstacle.withOpacity(0.55));
      final inner = Rect.fromLTWH(rect.left + 2, rect.top + 2,
          rect.width - 4, rect.height - 6);
      canvas.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(6)),
          Paint()..color = theme.obstacle);
      canvas.drawRect(
          Rect.fromLTWH(rect.left + 3, rect.top + 3, rect.width - 6, 3),
          Paint()..color = Colors.white.withOpacity(0.25));
    }

    // Foods: pulsing glow + emoji drawn as text
    for (final f in game.foods) {
      final pulse = 1 + 0.12 * math.sin(timeSeconds * 4 + f.cell.x + f.cell.y);
      final c = cellCenter(f.cell.x + 0.5, f.cell.y + 0.5);
      final glow = Paint()..color = f.type.color.withOpacity(0.28);
      canvas.drawCircle(c, cell * 0.62 * pulse, glow);
      final tp = TextPainter(
        text: TextSpan(
            text: f.type.emoji, style: TextStyle(fontSize: cell * 0.62 * pulse)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      if (f.expiresMs != null) {
        final remain = (f.expiresMs! - game.elapsedMs) / 9000.0;
        final ringPaint = Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawArc(
            Rect.fromCircle(center: c, radius: cell * 0.55),
            -math.pi / 2,
            math.pi * 2 * remain.clamp(0.0, 1.0),
            false,
            ringPaint);
      }
    }

    // Power-up: glowing halo + icon
    final pu = game.powerUp;
    if (pu != null) {
      final blink = (timeSeconds * 2).floor() % 2 == 0;
      final c = cellCenter(pu.cell.x + 0.5, pu.cell.y + 0.5);
      canvas.drawCircle(
          c, cell * 0.7, Paint()..color = pu.type.color.withOpacity(0.30));
      if (blink) {
        canvas.drawCircle(c, cell * 0.55,
            Paint()..color = pu.type.color.withOpacity(0.20));
      }
      final tp = TextPainter(
        text: TextSpan(
            text: pu.type.icon,
            style: TextStyle(fontSize: cell * 0.58, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }

    // Particles
    for (final p in game.particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life.clamp(0.0, 1.0));
      canvas.drawCircle(cellCenter(p.x, p.y), cell * 0.14, paint);
    }

    // Snake: interpolated positions, glowing rounded body, 3D head
    final snake = game.snake;
    final prev = game.prevSnake;
    List<Offset> points = [];
    for (var i = 0; i < snake.length; i++) {
      double px, py;
      if (i < prev.length) {
        // Ghost wrap: if jump is huge, don't interpolate across the board.
        final dx = snake[i].x - prev[i].x;
        final dy = snake[i].y - prev[i].y;
        if (dx.abs() > 2 || dy.abs() > 2) {
          px = snake[i].x + 0.5;
          py = snake[i].y + 0.5;
        } else {
          px = prev[i].x + dx * t + 0.5;
          py = prev[i].y + dy * t + 0.5;
        }
      } else {
        px = snake[i].x + 0.5;
        py = snake[i].y + 0.5;
      }
      points.add(cellCenter(px, py));
    }
    if (points.isEmpty) return;

    // Glow under body
    final ghost = game.ghostOn;
    final bodyPaint = Paint()
      ..color = (ghost
          ? theme.snakeBody.withOpacity(0.45)
          : theme.snakeBody)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.78;
    final glowPaint2 = Paint()
      ..color = theme.snakeBody.withOpacity(0.22)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 1.05;
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, glowPaint2);
      canvas.drawPath(path, bodyPaint);
    }

    // Body segments: highlight dots for a 3D feel
    for (var i = 1; i < points.length; i++) {
      canvas.drawCircle(
          points[i] - const Offset(0, 0), cell * 0.10,
          Paint()..color = Colors.white.withOpacity(0.18));
    }

    // Shield ring around head
    final head = points.first;
    if (game.shieldOn) {
      canvas.drawCircle(
          head,
          cell * 0.72,
          Paint()
            ..color = const Color(0xFF30D158).withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }

    // Head: rounded, with eyes looking in movement direction
    final headPaint = Paint()..color = theme.snakeHead;
    canvas.drawCircle(head, cell * 0.52, headPaint);
    canvas.drawCircle(
        head + Offset(-cell * 0.12, -cell * 0.18),
        cell * 0.13,
        Paint()..color = Colors.white.withOpacity(0.35));
    Offset eyeOff1, eyeOff2;
    switch (game.direction) {
      case Direction.up:
        eyeOff1 = Offset(-cell * 0.20, -cell * 0.22);
        eyeOff2 = Offset(cell * 0.20, -cell * 0.22);
        break;
      case Direction.down:
        eyeOff1 = Offset(-cell * 0.20, cell * 0.22);
        eyeOff2 = Offset(cell * 0.20, cell * 0.22);
        break;
      case Direction.left:
        eyeOff1 = Offset(-cell * 0.22, -cell * 0.20);
        eyeOff2 = Offset(-cell * 0.22, cell * 0.20);
        break;
      case Direction.right:
        eyeOff1 = Offset(cell * 0.22, -cell * 0.20);
        eyeOff2 = Offset(cell * 0.22, cell * 0.20);
        break;
    }
    for (final e in [eyeOff1, eyeOff2]) {
      canvas.drawCircle(head + e, cell * 0.13, Paint()..color = Colors.white);
      canvas.drawCircle(head + e, cell * 0.07, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(covariant SnakePainter old) => true;
}
