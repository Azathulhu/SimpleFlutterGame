Future<void> _finishDueToTimeout() async {
  _tickTimer?.cancel();
  _stopwatch.stop();
  final elapsedMs = _stopwatch.elapsedMilliseconds;

  final user = auth.currentUser;
  if (user != null) {
    await quizService.submitTime(
      userId: user.id,
      level: widget.level,
      score: score,
      timeMs: elapsedMs,
    );
  }

  latestLeaderboard = await quizService.fetchLeaderboard(level: widget.level, limit: 50);

  if (!mounted) return;
  _showCompletionDialog(recordedPerfect: false);
}

Future<void> _completeQuizEarly() async {
  _tickTimer?.cancel();
  _stopwatch.stop();
  final elapsedMs = _stopwatch.elapsedMilliseconds;
  final isPerfect = score == questions.length;

  final user = auth.currentUser;
  if (user != null) {
    await quizService.submitTime(
      userId: user.id,
      level: widget.level,
      score: score,
      timeMs: elapsedMs,
    );

    if (isPerfect) {
      // Unlock next level
      final currentIndex = levelOrder.indexOf(widget.level);
      if (currentIndex != -1 && currentIndex < levelOrder.length - 1) {
        final nextLevel = levelOrder[currentIndex + 1];
        await auth.unlockLevel(nextLevel);
      }
      await auth.unlockLevel(widget.level);
    }
  }

  latestLeaderboard = await quizService.fetchLeaderboard(level: widget.level, limit: 50);

  if (!mounted) return;
  _showCompletionDialog(recordedPerfect: isPerfect);
}
