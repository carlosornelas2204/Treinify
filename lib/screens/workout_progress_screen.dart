import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../models/workout_model.dart';

class WorkoutProgressScreen extends StatefulWidget {
  final Workout workout;
  const WorkoutProgressScreen({super.key, required this.workout});

  @override
  State<WorkoutProgressScreen> createState() => _WorkoutProgressScreenState();
}

class _WorkoutProgressScreenState extends State<WorkoutProgressScreen> {
  late DateTime _workoutStartTime;
  late Workout _currentWorkout;
  final Map<String, TextEditingController> _controllers = {};
  int? _activeRestTimerIndex;
  Timer? _restTimer;
  int _remainingRestSeconds = 0;

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now();
    _currentWorkout = widget.workout;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSet(WorkoutExercise exercise) {
    final workoutModel = Provider.of<WorkoutModel>(context, listen: false);
    final newSetNumber = exercise.sets.length + 1;

    // Busca os dados históricos para este número de série
    final historicalSet = workoutModel.getLastSetData(exercise.exercise.name, newSetNumber);

    setState(() {
      final newSet = historicalSet ?? WorkoutSet(
        value: 0,
        reps: 0,
        restTime: 0,
      );

      _currentWorkout = _currentWorkout.copyWith(
        exercises: _currentWorkout.exercises.map((e) {
          if (e.exercise.name == exercise.exercise.name) {
            return e.copyWith(sets: [...e.sets, newSet]);
          }
          return e;
        }).toList(),
      );

      // Inicia o timer se for uma série subsequente
      if (exercise.sets.isNotEmpty) {
        _startRestTimer(exercise.sets.length, newSet.restTime);
      }
    });
  }

  void _startRestTimer(int setIndex, int restTime) {
    _restTimer?.cancel();
    setState(() {
      _activeRestTimerIndex = setIndex;
      _remainingRestSeconds = restTime;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 0) {
        setState(() => _remainingRestSeconds--);
      } else {
        timer.cancel();
        _onRestComplete();
      }
    });
  }

  void _removeSet(WorkoutExercise exercise, int index) {
    setState(() {
      _currentWorkout = _currentWorkout.copyWith(
        exercises: _currentWorkout.exercises.map((e) {
          if (e.exercise.name == exercise.exercise.name) {
            final newSets = List<dynamic>.from(e.sets);
            newSets.removeAt(index);
            return e.copyWith(sets: newSets);
          }
          return e;
        }).toList(),
      );
    });
  }

  void _onRestComplete() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 500);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Descanso concluído!'),
        duration: Duration(seconds: 2),
      ),
    );
    setState(() => _activeRestTimerIndex = null);
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    final isCardio = exercise.exercise.muscleGroup == 'Cardio';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[900],
      child: ExpansionTile(
        title: Text(
          exercise.exercise.name,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        subtitle: Text(
          isCardio ? 'Cardio' : '${exercise.sets.length} séries',
          style: const TextStyle(color: Colors.white70),
        ),
        children: [
          if (isCardio)
            _CardioSetForm(
              initialSet: exercise.sets.isNotEmpty ? exercise.sets.last as CardioSet : null,
              onSave: (distance, duration, calories) =>
                  _updateCardioSet(exercise, distance, duration, calories),
            )
          else
            Column(
              children: [
                ..._buildWorkoutSets(exercise),
                const SizedBox(height: 8),
                _buildAddSeriesButton(exercise),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildWorkoutSets(WorkoutExercise exercise) {
    return exercise.sets.asMap().entries.map((entry) {
      final index = entry.key;
      final set = entry.value as WorkoutSet;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Série ${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _removeSet(exercise, index),
                    tooltip: 'Remover série',
                  ),
                  if (_activeRestTimerIndex == index)
                    _buildRestTimerChip(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildValueField('Peso (kg)', set.value.toString(), (value) {
                    _updateSetValue(exercise, index, double.parse(value), set.reps, set.restTime);
                  }),
                  const SizedBox(width: 10),
                  _buildValueField('Reps', set.reps.toString(), (value) {
                    _updateSetValue(exercise, index, set.value, int.parse(value), set.restTime);
                  }),
                  const SizedBox(width: 10),
                  _buildValueField('Descanso (s)', set.restTime.toString(), (value) {
                    _updateSetValue(exercise, index, set.value, set.reps, int.parse(value));
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildValueField(String label, String value, Function(String) onChanged) {
    return Expanded(
      child: TextFormField(
        initialValue: value,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          filled: true,
          fillColor: Colors.grey[700],
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAddSeriesButton(WorkoutExercise exercise) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_circle_outline, size: 24),
        label: const Text('ADICIONAR SÉRIE', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.green[800],
        ),
        onPressed: () => _addSet(exercise),
      ),
    );
  }

  Widget _buildRestTimerChip() {
    final minutes = (_remainingRestSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingRestSeconds % 60).toString().padLeft(2, '0');

    return Chip(
      backgroundColor: Colors.red[800],
      label: Text(
        '$minutes:$seconds',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      avatar: const Icon(Icons.timer, color: Colors.white, size: 18),
    );
  }

  void _updateCardioSet(WorkoutExercise exercise, double distance, Duration duration, int calories) {
    setState(() {
      final newSet = CardioSet(
        distance: distance,
        duration: duration,
        calories: calories,
      );

      _currentWorkout = _currentWorkout.copyWith(
        exercises: _currentWorkout.exercises.map((e) {
          if (e.exercise.name == exercise.exercise.name &&
              e.exercise.muscleGroup == exercise.exercise.muscleGroup) {
            return e.copyWith(sets: [newSet]);
          }
          return e;
        }).toList(),
      );
    });
  }

  void _updateSetValue(WorkoutExercise exercise, int index, double value, int reps, int restTime) {
    setState(() {
      _currentWorkout = _currentWorkout.copyWith(
        exercises: _currentWorkout.exercises.map((e) {
          if (e.exercise.name == exercise.exercise.name) {
            final newSets = List<dynamic>.from(e.sets);
            newSets[index] = WorkoutSet(
              value: value,
              reps: reps,
              restTime: restTime,
            );
            return e.copyWith(sets: newSets);
          }
          return e;
        }).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutModel = Provider.of<WorkoutModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentWorkout.title,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            tooltip: 'Tempo decorrido',
            onPressed: () {
              final duration = DateTime.now().difference(_workoutStartTime);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tempo: ${duration.inMinutes} minutos',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: _currentWorkout.exercises.length,
              itemBuilder: (context, index) {
                return _buildExerciseCard(_currentWorkout.exercises[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final duration = DateTime.now().difference(_workoutStartTime);
                workoutModel.completeWorkout(_currentWorkout, duration);
                Navigator.pop(context);
              },
              child: const Text(
                'FINALIZAR TREINO',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardioSetForm extends StatefulWidget {
  final CardioSet? initialSet;
  final Function(double, Duration, int) onSave;

  const _CardioSetForm({
    required this.initialSet,
    required this.onSave,
  });

  @override
  State<_CardioSetForm> createState() => __CardioSetFormState();
}

class __CardioSetFormState extends State<_CardioSetForm> {
  late final TextEditingController _distanceController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  late final TextEditingController _caloriesController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _distanceController = TextEditingController(
      text: widget.initialSet?.distance.toString() ?? '',
    );
    _minutesController = TextEditingController(
      text: widget.initialSet?.duration.inMinutes.toString() ?? '0',
    );
    _secondsController = TextEditingController(
      text: (widget.initialSet?.duration.inSeconds.remainder(60) ?? 0).toString(),
    );
    _caloriesController = TextEditingController(
      text: widget.initialSet?.calories.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _saveData() {
    if (!_formKey.currentState!.validate()) return;

    final distance = double.tryParse(_distanceController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final calories = int.tryParse(_caloriesController.text) ?? 0;

    widget.onSave(
      distance,
      Duration(minutes: minutes, seconds: seconds),
      calories,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _distanceController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Distância (km)',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                suffixText: 'km',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _saveData(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minutesController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Minutos',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _saveData(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _secondsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Segundos',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _saveData(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _caloriesController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Calorias',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _saveData(),
            ),
          ],
        ),
      ),
    );
  }
}