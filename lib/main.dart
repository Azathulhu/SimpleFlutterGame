import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart'; // <-- important
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: TapGame()));
}

class TapGame extends FlameGame with TapDetector {
  int score = 0;
  late TextComponent scoreText;

  @override
  Future<void> onLoad() async {
    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(100, 100),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 32, color: Colors.white),
      ),
    );
    add(scoreText);
  }

  @override
  void onTapDown(TapDownInfo info) {
    score++;
    scoreText.text = 'Score: $score';
  }
}
