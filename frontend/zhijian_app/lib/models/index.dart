/// Data models for 智健 App.

class UserModel {
  final String id;
  final String nickname;
  final String currentPersonality;
  final int streakDays;
  final int totalDays;
  final String fitnessGoal;
  final String fitnessLevel;
  final String subscriptionTier;

  UserModel({
    required this.id,
    required this.nickname,
    this.currentPersonality = 'gym_bro',
    this.streakDays = 0,
    this.totalDays = 0,
    this.fitnessGoal = 'build_muscle',
    this.fitnessLevel = 'beginner',
    this.subscriptionTier = 'free',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        nickname: json['nickname'] ?? '',
        currentPersonality: json['current_personality'] ?? 'gym_bro',
        streakDays: json['streak_days'] ?? 0,
        totalDays: json['total_days'] ?? 0,
        fitnessGoal: json['fitness_goal'] ?? 'build_muscle',
        fitnessLevel: json['fitness_level'] ?? 'beginner',
        subscriptionTier: json['subscription_tier'] ?? 'free',
      );
}

class AnalysisItem {
  final String bodyPart;
  final String label;
  final double changePct;
  final double confidence;
  final String direction; // "improved" | "declined" | "stable"

  AnalysisItem({
    required this.bodyPart,
    required this.label,
    this.changePct = 0,
    this.confidence = 0,
    this.direction = 'stable',
  });

  factory AnalysisItem.fromJson(Map<String, dynamic> json) => AnalysisItem(
        bodyPart: json['body_part'] ?? '',
        label: json['label'] ?? '',
        changePct: (json['change_pct'] ?? 0).toDouble(),
        confidence: (json['confidence'] ?? 0).toDouble(),
        direction: json['direction'] ?? 'stable',
      );
}

class SymmetryAlert {
  final String bodyPart;
  final String label;
  final double diffCm;
  final String severity;

  SymmetryAlert({
    required this.bodyPart,
    required this.label,
    this.diffCm = 0,
    this.severity = 'mild',
  });

  factory SymmetryAlert.fromJson(Map<String, dynamic> json) => SymmetryAlert(
        bodyPart: json['body_part'] ?? '',
        label: json['label'] ?? '',
        diffCm: (json['diff_cm'] ?? 0).toDouble(),
        severity: json['severity'] ?? 'mild',
      );
}

class PostureAlert {
  final String label;
  final double angle;
  final String severity;
  final String recommendation;

  PostureAlert({
    required this.label,
    this.angle = 0,
    this.severity = 'normal',
    this.recommendation = '',
  });

  factory PostureAlert.fromJson(Map<String, dynamic> json) => PostureAlert(
        label: json['label'] ?? '',
        angle: (json['angle'] ?? 0).toDouble(),
        severity: json['severity'] ?? 'normal',
        recommendation: json['recommendation'] ?? '',
      );
}

class ReportModel {
  final String reportId;
  final int overallScore;
  final String personality;
  final String reportText;
  final Map<String, String> altCache;
  final List<AnalysisItem> progressItems;
  final List<AnalysisItem> weaknessItems;
  final List<SymmetryAlert> symmetryAlerts;
  final List<PostureAlert> postureAlerts;

  ReportModel({
    required this.reportId,
    this.overallScore = 70,
    this.personality = 'gym_bro',
    this.reportText = '',
    this.altCache = const {},
    this.progressItems = const [],
    this.weaknessItems = const [],
    this.symmetryAlerts = const [],
    this.postureAlerts = const [],
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        reportId: json['report_id'] ?? '',
        overallScore: json['overall_score'] ?? 70,
        personality: json['personality'] ?? 'gym_bro',
        reportText: json['report_text'] ?? '',
        altCache: Map<String, String>.from(json['alt_cache'] ?? {}),
        progressItems: (json['progress_items'] as List? ?? [])
            .map((e) => AnalysisItem.fromJson(e))
            .toList(),
        weaknessItems: (json['weakness_items'] as List? ?? [])
            .map((e) => AnalysisItem.fromJson(e))
            .toList(),
        symmetryAlerts: (json['symmetry_alerts'] as List? ?? [])
            .map((e) => SymmetryAlert.fromJson(e))
            .toList(),
        postureAlerts: (json['posture_alerts'] as List? ?? [])
            .map((e) => PostureAlert.fromJson(e))
            .toList(),
      );
}

class ExerciseModel {
  final String name;
  final String targetMuscle;
  final int sets;
  final String reps;
  final String notes;
  final int sortOrder;
  final int restSeconds;
  bool isCompleted;
  int? actualSets;
  double? actualWeightKg;

  ExerciseModel({
    required this.name,
    this.targetMuscle = '',
    this.sets = 4,
    this.reps = '8-12',
    this.notes = '',
    this.sortOrder = 0,
    this.restSeconds = 60,
    this.isCompleted = false,
    this.actualSets,
    this.actualWeightKg,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        name: json['name'] ?? json['exercise_name'] ?? '',
        targetMuscle: json['target_muscle'] ?? '',
        sets: json['sets'] ?? 4,
        reps: json['reps'] ?? '8-12',
        notes: json['notes'] ?? '',
        sortOrder: json['sort_order'] ?? 0,
        restSeconds: json['rest_seconds'] ?? 60,
        isCompleted: json['is_completed'] ?? false,
        actualSets: json['actual_sets'],
        actualWeightKg: json['actual_weight_kg']?.toDouble(),
      );
}

class PlanModel {
  final String planId;
  final String planDate;
  final List<ExerciseModel> exercises;
  final String notes;

  PlanModel({
    required this.planId,
    required this.planDate,
    this.exercises = const [],
    this.notes = '',
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
        planId: json['plan_id'] ?? '',
        planDate: json['plan_date'] ?? '',
        exercises: (json['exercises'] as List? ?? [])
            .map((e) => ExerciseModel.fromJson(e))
            .toList(),
        notes: json['notes'] ?? '',
      );
}

class CalendarDay {
  final String date;
  final bool hasPhoto;
  final String? thumbnailUrl;
  final double? weightKg;
  final String? mood;
  final bool streakDay;

  CalendarDay({
    required this.date,
    this.hasPhoto = false,
    this.thumbnailUrl,
    this.weightKg,
    this.mood,
    this.streakDay = false,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        date: json['date'] ?? '',
        hasPhoto: json['has_photo'] ?? false,
        thumbnailUrl: json['thumbnail_url'],
        weightKg: json['body_weight_kg']?.toDouble(),
        mood: json['mood'],
        streakDay: json['streak_day'] ?? false,
      );
}

class PersonalityMeta {
  final String key;
  final String name;
  final String displayName;
  final String avatarEmoji;
  final String description;

  PersonalityMeta({
    required this.key,
    required this.name,
    required this.displayName,
    required this.avatarEmoji,
    required this.description,
  });

  factory PersonalityMeta.fromJson(Map<String, dynamic> json) => PersonalityMeta(
        key: json['key'] ?? '',
        name: json['name'] ?? '',
        displayName: json['display_name'] ?? '',
        avatarEmoji: json['avatar_emoji'] ?? '🔥',
        description: json['description'] ?? '',
      );
}
