import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Exercise {
  final String name;
  final String muscleGroup;

  const Exercise({required this.name, required this.muscleGroup});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      muscleGroup: json['muscleGroup'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'muscleGroup': muscleGroup,
  };
}

class WorkoutSet {
  final double value;
  final int reps;
  final int restTime;

  const WorkoutSet({
    required this.value,
    required this.reps,
    required this.restTime,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    value: json['value'],
    reps: json['reps'],
    restTime: json['restTime'],
  );

  Map<String, dynamic> toJson() => {
    'value': value,
    'reps': reps,
    'restTime': restTime,
  };
}

class CardioSet {
  final double distance;
  final Duration duration;
  final int calories;

  const CardioSet({
    required this.distance,
    required this.duration,
    required this.calories,
  });

  factory CardioSet.fromJson(Map<String, dynamic> json) => CardioSet(
    distance: json['distance'],
    duration: Duration(seconds: json['duration']),
    calories: json['calories'],
  );

  Map<String, dynamic> toJson() => {
    'distance': distance,
    'duration': duration.inSeconds,
    'calories': calories,
  };
}

class WorkoutExercise {
  final Exercise exercise;
  final List<dynamic> sets;

  WorkoutExercise({
    required this.exercise,
    required this.sets,
  });

  bool get isCardio => exercise.muscleGroup == 'Cardio';

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final exercise = Exercise.fromJson(json['exercise']);
    final sets = exercise.muscleGroup == 'Cardio'
        ? (json['sets'] as List).map((e) => CardioSet.fromJson(e)).toList()
        : (json['sets'] as List).map((e) => WorkoutSet.fromJson(e)).toList();

    return WorkoutExercise(
      exercise: exercise,
      sets: sets,
    );
  }

  Map<String, dynamic> toJson() => {
    'exercise': exercise.toJson(),
    'sets': sets.map((e) => e.toJson()).toList(),
  };

  WorkoutExercise copyWith({
    Exercise? exercise,
    List<dynamic>? sets,
  }) {
    return WorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
    );
  }
}

class Workout {
  final String title;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Duration? duration;

  const Workout({
    required this.title,
    required this.exercises,
    required this.createdAt,
    this.completedAt,
    this.duration,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    title: json['title'],
    exercises: (json['exercises'] as List)
        .map((e) => WorkoutExercise.fromJson(e))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
    duration: json['duration'] != null
        ? Duration(seconds: json['duration'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'duration': duration?.inSeconds,
  };

  Workout copyWith({
    String? title,
    List<WorkoutExercise>? exercises,
    DateTime? createdAt,
    DateTime? completedAt,
    Duration? duration,
  }) {
    return Workout(
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
    );
  }
}

class WorkoutModel extends ChangeNotifier {
  List<Workout> _workouts = [];
  List<WorkoutHistory> _workoutHistory = [];

  final List<Exercise> _availableExercises = const [
    Exercise(name: "Puxada alta", muscleGroup: "Costas"),
    Exercise(name: "Puxada alta com triângulo", muscleGroup: "Costas"),
    Exercise(name: "Puxada frontal", muscleGroup: "Costas"),
    Exercise(name: "Puxada neutra", muscleGroup: "Costas"),
    Exercise(name: "Remada curvada", muscleGroup: "Costas"),
    Exercise(name: "Remada cavalinho", muscleGroup: "Costas"),
    Exercise(name: "Remada serrote", muscleGroup: "Costas"),
    Exercise(name: "Remada máquina", muscleGroup: "Costas"),
    Exercise(name: "Remada unilateral", muscleGroup: "Costas"),
    Exercise(name: "Pull-down", muscleGroup: "Costas"),
    Exercise(name: "Barra fixa", muscleGroup: "Costas"),
    Exercise(name: "Hiperextensão lombar", muscleGroup: "Costas"),
    Exercise(name: "Deadlift", muscleGroup: "Costas"),

    // PEITO
    Exercise(name: "Supino com halteres", muscleGroup: "Peito"),
    Exercise(name: "Supino reto máquina", muscleGroup: "Peito"),
    Exercise(name: "Supino inclinado", muscleGroup: "Peito"),
    Exercise(name: "Supino declinado", muscleGroup: "Peito"),
    Exercise(name: "Crucifixo", muscleGroup: "Peito"),
    Exercise(name: "Peck deck", muscleGroup: "Peito"),
    Exercise(name: "Flexão de braço", muscleGroup: "Peito"),
    Exercise(name: "Cross-over Alto", muscleGroup: "Peito"),
    Exercise(name: "Cross-over Médio", muscleGroup: "Peito"),
    Exercise(name: "Cross-over Baixo", muscleGroup: "Peito"),
    Exercise(name: "Pullover", muscleGroup: "Peito"),
    Exercise(name: "Supino Arnold", muscleGroup: "Peito"),
    Exercise(name: "Dips", muscleGroup: "Peito"),

    // OMBROS
    Exercise(name: "Desenvolvimento militar", muscleGroup: "Ombros"),
    Exercise(name: "Elevação lateral", muscleGroup: "Ombros"),
    Exercise(name: "Elevação frontal", muscleGroup: "Ombros"),
    Exercise(name: "Crucifixo inverso", muscleGroup: "Ombros"),
    Exercise(name: "Desenvolvimento Arnold", muscleGroup: "Ombros"),
    Exercise(name: "Desenvolvimento máquina", muscleGroup: "Ombros"),
    Exercise(name: "Elevação lateral inclinada", muscleGroup: "Ombros"),
    Exercise(name: "Remada alta", muscleGroup: "Ombros"),
    Exercise(name: "Encolhimento com halteres", muscleGroup: "Ombros"),
    Exercise(name: "Face pull", muscleGroup: "Ombros"),
    Exercise(name: "Desenvolvimento por trás", muscleGroup: "Ombros"),

    // PERNAS
    Exercise(name: "Agachamento livre", muscleGroup: "Pernas"),
    Exercise(name: "Leg press", muscleGroup: "Pernas"),
    Exercise(name: "Cadeira extensora", muscleGroup: "Pernas"),
    Exercise(name: "Mesa flexora", muscleGroup: "Pernas"),
    Exercise(name: "Stiff", muscleGroup: "Pernas"),
    Exercise(name: "Agachamento búlgaro", muscleGroup: "Pernas"),
    Exercise(name: "Cadeira adutora", muscleGroup: "Pernas"),
    Exercise(name: "Cadeira abdutora", muscleGroup: "Pernas"),
    Exercise(name: "Hack machine", muscleGroup: "Pernas"),
    Exercise(name: "Afundo", muscleGroup: "Pernas"),
    Exercise(name: "Panturrilha em pé", muscleGroup: "Pernas"),
    Exercise(name: "Panturrilha sentado", muscleGroup: "Pernas"),
    Exercise(name: "Agachamento sumô", muscleGroup: "Pernas"),
    Exercise(name: "Leg curl", muscleGroup: "Pernas"),

    // BÍCEPS
    Exercise(name: "Rosca direta", muscleGroup: "Bíceps"),
    Exercise(name: "Rosca alternada", muscleGroup: "Bíceps"),
    Exercise(name: "Rosca martelo", muscleGroup: "Bíceps"),
    Exercise(name: "Rosca concentrada", muscleGroup: "Bíceps"),
    Exercise(name: "Rosca scott", muscleGroup: "Bíceps"),
    Exercise(name: "Rosca inversa", muscleGroup: "Bíceps"),
    Exercise(name: "Rosca 21", muscleGroup: "Bíceps"),
    Exercise(name: "Rosca corda", muscleGroup: "Bíceps"),
    Exercise(name: "Rosca simultânea", muscleGroup: "Bíceps"),

    // TRÍCEPS
    Exercise(name: "Tríceps corda", muscleGroup: "Tríceps"),
    Exercise(name: "Tríceps testa", muscleGroup: "Tríceps"),
    Exercise(name: "Tríceps francês", muscleGroup: "Tríceps"),
    Exercise(name: "Tríceps pulley", muscleGroup: "Tríceps"),
    Exercise(name: "Tríceps banco", muscleGroup: "Tríceps"),
    Exercise(name: "Tríceps coice", muscleGroup: "Tríceps"),
    Exercise(name: "Mergulho", muscleGroup: "Tríceps"),
    Exercise(name: "Kickback", muscleGroup: "Tríceps"),
    Exercise(name: "Tríceps unilateral", muscleGroup: "Tríceps"),

    // ABDOMÊN
    Exercise(name: "Abdominal crunch", muscleGroup: "Abdômen"),
    Exercise(name: "Prancha", muscleGroup: "Abdômen"),
    Exercise(name: "Elevação de pernas", muscleGroup: "Abdômen"),
    Exercise(name: "Russian twist", muscleGroup: "Abdômen"),
    Exercise(name: "Abdominal infra", muscleGroup: "Abdômen"),
    Exercise(name: "Abdominal oblíquo", muscleGroup: "Abdômen"),
    Exercise(name: "Abdominal canivete", muscleGroup: "Abdômen"),
    Exercise(name: "Abdominal máquina", muscleGroup: "Abdômen"),
    Exercise(name: "Mountain climber", muscleGroup: "Abdômen"),

    // ANTEBRAÇO
    Exercise(name: "Rosca punho", muscleGroup: "Antebraço"),
    Exercise(name: "Extensão punho", muscleGroup: "Antebraço"),
    Exercise(name: "Rotação de punho", muscleGroup: "Antebraço"),

    // CARDIO
    Exercise(name: "Esteira", muscleGroup: "Cardio"),
    Exercise(name: "Bicicleta ergométrica", muscleGroup: "Cardio"),
    Exercise(name: "Elíptico", muscleGroup: "Cardio"),
    Exercise(name: "Transport", muscleGroup: "Cardio"),
    Exercise(name: "Escada", muscleGroup: "Cardio"),
  ];

  WorkoutModel() {
    _loadWorkouts();
  }

  List<Workout> get workouts => List.unmodifiable(_workouts);
  List<Exercise> get availableExercises => List.unmodifiable(_availableExercises);

  Future<void> _loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getStringList('workouts') ?? [];
    final historyJson = prefs.getStringList('workout_history') ?? [];

    _workouts = workoutsJson
        .map((json) => Workout.fromJson(jsonDecode(json)))
        .toList();

    _workoutHistory = historyJson
        .map((json) => WorkoutHistory.fromJson(jsonDecode(json)))
        .toList();

    notifyListeners();
  }

  Future<void> _saveWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = _workouts
        .map((workout) => jsonEncode(workout.toJson()))
        .toList();
    final historyJson = _workoutHistory
        .map((history) => jsonEncode(history.toJson()))
        .toList();

    await prefs.setStringList('workouts', workoutsJson);
    await prefs.setStringList('workout_history', historyJson);
    notifyListeners();
  }

  void addWorkout(Workout workout) {
    _workouts.add(workout);
    _saveWorkouts();
  }

  void deleteWorkout(Workout workout) {
    _workouts.removeWhere((w) =>
    w.title == workout.title &&
        w.createdAt == workout.createdAt
    );
    _saveWorkouts();
  }

  void completeWorkout(Workout workout, Duration duration) {
    final index = _workouts.indexWhere((w) =>
    w.title == workout.title &&
        w.createdAt == workout.createdAt
    );

    if (index != -1) {
      _workouts[index] = workout.copyWith(
        completedAt: DateTime.now(),
        duration: duration,
      );

      // Adiciona ao histórico sem remover da lista de workouts
      _workoutHistory.add(WorkoutHistory(
        workout: workout,
        completedAt: DateTime.now(),
        duration: duration,
      ));

      _saveWorkouts();
    }
  }

  void updateWorkout(Workout oldWorkout, Workout newWorkout) {
    final index = _workouts.indexWhere((w) =>
    w.title == oldWorkout.title &&
        w.createdAt == oldWorkout.createdAt
    );

    if (index != -1) {
      _workouts[index] = newWorkout;
      _saveWorkouts();
    }
  }

  Map<String, double> getLastWeights() {
    final lastWeights = <String, double>{};

    for (final workout in _workouts.where((w) => w.completedAt != null)) {
      for (final exercise in workout.exercises) {
        if (exercise.sets.isNotEmpty && !exercise.isCardio) {
          final lastSet = exercise.sets.last as WorkoutSet;
          lastWeights[exercise.exercise.name] = lastSet.value;
        }
      }
    }

    return lastWeights;
  }

  Map<String, int> getLastReps() {
    final lastReps = <String, int>{};

    for (final workout in _workouts.where((w) => w.completedAt != null)) {
      for (final exercise in workout.exercises) {
        if (exercise.sets.isNotEmpty && !exercise.isCardio) {
          final lastSet = exercise.sets.last as WorkoutSet;
          lastReps[exercise.exercise.name] = lastSet.reps;
        }
      }
    }

    return lastReps;
  }

  // Novo método para obter dados de cardio
  Map<String, CardioSet> getLastCardioData() {
    final lastCardio = <String, CardioSet>{};

    for (final workout in _workouts.where((w) => w.completedAt != null)) {
      for (final exercise in workout.exercises) {
        if (exercise.sets.isNotEmpty && exercise.isCardio) {
          lastCardio[exercise.exercise.name] = exercise.sets.last as CardioSet;
        }
      }
    }

    return lastCardio;
  }
}

class WorkoutHistory {
  final Workout workout;
  final DateTime completedAt;
  final Duration duration;

  WorkoutHistory({
    required this.workout,
    required this.completedAt,
    required this.duration,
  });

  factory WorkoutHistory.fromJson(Map<String, dynamic> json) => WorkoutHistory(
    workout: Workout.fromJson(json['workout']),
    completedAt: DateTime.parse(json['completedAt']),
    duration: Duration(seconds: json['duration']),
  );

  Map<String, dynamic> toJson() => {
    'workout': workout.toJson(),
    'completedAt': completedAt.toIso8601String(),
    'duration': duration.inSeconds,
  };
}