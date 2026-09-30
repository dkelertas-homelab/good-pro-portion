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
    this.mirror = false,
  });

  final String moveId;
  final String? label;
  final int? workSeconds;
  final String? note;

  /// Overrides the move's cue, e.g. for one side of a one-sided move.
  final String? cue;

  /// Flip the figure horizontally (left side of a one-sided move).
  final bool mirror;

  factory RoutineStep.fromJson(Map<String, dynamic> j) => RoutineStep(
        moveId: j['moveId'] as String,
        label: j['label'] as String?,
        workSeconds: j['workSeconds'] as int?,
        note: j['note'] as String?,
        cue: j['cue'] as String?,
        mirror: j['mirror'] == true,
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

class AppContent {
  AppContent({
    required this.appName,
    required this.moves,
    required this.routines,
    required this.meals,
  });

  final String appName;
  final List<Move> moves;
  final List<Routine> routines;
  final List<MealIdea> meals;

  Move moveById(String id) => moves.firstWhere((m) => m.id == id);

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
      );
}
