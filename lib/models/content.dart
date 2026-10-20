class Move {
  Move({
    required this.id,
    required this.name,
    required this.figure,
    required this.howTo,
    required this.mistakes,
    required this.easier,
    required this.harder,
    this.textOnly = false,
    this.cue = '',
  });

  final String id;
  final String name;
  final String figure;
  final String howTo;
  final String mistakes;
  final String easier;
  final String harder;
  final bool textOnly;

  /// One short line shown under the name during the exercise.
  final String cue;

  factory Move.fromJson(Map<String, dynamic> j) => Move(
    id: j['id'] as String,
    name: j['name'] as String,
    figure: j['figure'] as String,
    howTo: j['howTo'] as String,
    mistakes: j['mistakes'] as String,
    easier: j['easier'] as String,
    harder: j['harder'] as String,
    textOnly: j['textOnly'] == true,
    cue: j['cue'] as String? ?? '',
  );
}

class RoutineStep {
  RoutineStep({
    required this.moveId,
    this.label,
    this.workSeconds,
    this.note,
    this.cue,
    this.swapSides = false,
  });

  final String moveId;
  final String? label;
  final int? workSeconds;
  final String? note;

  /// Overrides the move's cue, e.g. for one side of a one-sided move.
  final String? cue;

  /// Second side of a one-sided move. Figures are drawn for the right side
  /// only, so the app says "Swap sides" here instead of mirroring.
  final bool swapSides;

  factory RoutineStep.fromJson(Map<String, dynamic> j) => RoutineStep(
    moveId: j['moveId'] as String,
    label: j['label'] as String?,
    workSeconds: j['workSeconds'] as int?,
    note: j['note'] as String?,
    cue: j['cue'] as String?,
    swapSides: j['swapSides'] == true,
  );
}

class Routine {
  Routine({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.approxMinutes,
    required this.warmupSeconds,
    required this.workSeconds,
    required this.restSeconds,
    required this.warmup,
    required this.work,
  });

  final String id;
  final String name;
  final String subtitle;
  final int approxMinutes;
  final int warmupSeconds;
  final int workSeconds;
  final int restSeconds;
  final List<RoutineStep> warmup;
  final List<RoutineStep> work;

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
    id: j['id'] as String,
    name: j['name'] as String,
    subtitle: j['subtitle'] as String,
    approxMinutes: j['approxMinutes'] as int,
    warmupSeconds: j['warmupSeconds'] as int,
    workSeconds: j['workSeconds'] as int,
    restSeconds: j['restSeconds'] as int,
    warmup: (j['warmup'] as List)
        .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
        .toList(),
    work: (j['work'] as List)
        .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class MealIdea {
  MealIdea({
    required this.id,
    required this.emoji,
    required this.title,
    required this.portionGuide,
  });

  final String id;
  final String emoji;
  final String title;
  final String portionGuide;

  factory MealIdea.fromJson(Map<String, dynamic> j) => MealIdea(
    id: j['id'] as String,
    emoji: j['emoji'] as String,
    title: j['title'] as String,
    portionGuide: j['portionGuide'] as String,
  );
}

enum BreathMotion { breatheIn, breatheOut, hold }

/// One step of a breathing pattern. [label] says what to do, e.g.
/// "Breathe in". The circle grows on in, shrinks on out, holds on hold.
class BreathStep {
  BreathStep({
    required this.label,
    required this.seconds,
    required this.motion,
  });

  final String label;
  final int seconds;
  final BreathMotion motion;

  factory BreathStep.fromJson(Map<String, dynamic> j) => BreathStep(
    label: j['label'] as String,
    seconds: j['seconds'] as int,
    motion: switch (j['motion'] as String) {
      'in' => BreathMotion.breatheIn,
      'out' => BreathMotion.breatheOut,
      'hold' => BreathMotion.hold,
      final m => throw FormatException('Unknown breath motion: $m'),
    },
  );
}

/// A post-workout cooldown: a slow breathing pattern, a short mindfulness
/// cue and a positive prompt.
class CooldownSet {
  CooldownSet({
    required this.id,
    required this.title,
    required this.steps,
    required this.rounds,
    required this.cue,
    required this.prompt,
  });

  final String id;
  final String title;
  final List<BreathStep> steps;
  final int rounds;
  final String cue;
  final String prompt;

  int get breathingSeconds =>
      rounds * steps.fold(0, (sum, s) => sum + s.seconds);

  factory CooldownSet.fromJson(Map<String, dynamic> j) => CooldownSet(
    id: j['id'] as String,
    title: j['title'] as String,
    steps: (j['steps'] as List)
        .map((e) => BreathStep.fromJson(e as Map<String, dynamic>))
        .toList(),
    rounds: j['rounds'] as int,
    cue: j['cue'] as String,
    prompt: j['prompt'] as String,
  );
}

class AppContent {
  AppContent({
    required this.appName,
    required this.moves,
    required this.routines,
    required this.meals,
    this.cooldowns = const [],
  });

  final String appName;
  final List<Move> moves;
  final List<Routine> routines;
  final List<MealIdea> meals;
  final List<CooldownSet> cooldowns;

  Move moveById(String id) => moves.firstWhere((m) => m.id == id);

  /// The other half of an A/B pair ("Quiet morning A" <-> "Quiet morning B"),
  /// or null if the routine isn't part of one.
  Routine? partnerOf(Routine r) {
    final m = RegExp(r'^(.*) ([AB])$').firstMatch(r.name);
    if (m == null) return null;
    final other = '${m[1]} ${m[2] == 'A' ? 'B' : 'A'}';
    for (final x in routines) {
      if (x.name == other) return x;
    }
    return null;
  }

  factory AppContent.fromJson(Map<String, dynamic> j) => AppContent(
    appName: j['appName'] as String,
    moves: (j['moves'] as List)
        .map((e) => Move.fromJson(e as Map<String, dynamic>))
        .toList(),
    routines: (j['routines'] as List)
        .map((e) => Routine.fromJson(e as Map<String, dynamic>))
        .toList(),
    meals: (j['meals'] as List)
        .map((e) => MealIdea.fromJson(e as Map<String, dynamic>))
        .toList(),
    cooldowns: ((j['cooldowns'] as List?) ?? const [])
        .map((e) => CooldownSet.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
