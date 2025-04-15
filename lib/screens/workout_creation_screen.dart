import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_model.dart';

class WorkoutCreationScreen extends StatefulWidget {
  final Workout? workoutToEdit;

  const WorkoutCreationScreen({
    super.key,
    this.workoutToEdit,
  });

  @override
  State<WorkoutCreationScreen> createState() => _WorkoutCreationScreenState();
}

class _WorkoutCreationScreenState extends State<WorkoutCreationScreen> {
  late final TextEditingController _titleController;
  late List<Exercise> _selectedExercises;
  String? _selectedMuscleGroup;
  String? _selectedExercise;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedExercises = widget.workoutToEdit?.exercises
        .map((e) => e.exercise)
        .toList() ?? [];
    _titleController = TextEditingController(
      text: widget.workoutToEdit?.title ?? '',
    );
  }

  List<Exercise> _getFilteredExercises(WorkoutModel workoutModel) {
    if (_selectedMuscleGroup == null) return [];
    return workoutModel.availableExercises
        .where((e) => e.muscleGroup == _selectedMuscleGroup)
        .toList();
  }

  void _saveWorkout(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um exercício')),
      );
      return;
    }

    final workoutModel = Provider.of<WorkoutModel>(context, listen: false);
    final newWorkout = Workout(
      title: _titleController.text.trim(),
      exercises: _selectedExercises
          .map((e) => WorkoutExercise(
        exercise: e,
        sets: e.muscleGroup == 'Cardio'
            ? [CardioSet(distance: 0, duration: Duration.zero, calories: 0)]
            : [WorkoutSet(value: 0, reps: 0, restTime: 60)],
      ))
          .toList(),
      createdAt: widget.workoutToEdit?.createdAt ?? DateTime.now(),
    );

    if (widget.workoutToEdit != null) {
      workoutModel.updateWorkout(widget.workoutToEdit!, newWorkout);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficha atualizada com sucesso!')),
      );
    } else {
      workoutModel.addWorkout(newWorkout);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficha criada com sucesso!')),
      );
    }

    Navigator.pop(context, 'Ficha salva com sucesso');
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Título da Ficha*',
        labelStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, insira um título';
        }
        return null;
      },
    );
  }

  Widget _buildMuscleGroupDropdown(WorkoutModel workoutModel) {
    return DropdownButtonFormField<String>(
      value: _selectedMuscleGroup,
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Grupo Muscular*',
        labelStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(),
      ),
      items: workoutModel.availableExercises
          .map((e) => e.muscleGroup)
          .toSet()
          .map((group) => DropdownMenuItem(
        value: group,
        child: Text(group),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedMuscleGroup = value;
          _selectedExercise = null;
        });
      },
      //validator: (value) =>
      //value == null ? 'Selecione um grupo muscular' : null,
    );
  }

  Widget _buildExerciseDropdown(List<Exercise> filteredExercises) {
    return DropdownButtonFormField<String>(
      value: _selectedExercise,
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Exercício*',
        labelStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(),
      ),
      items: filteredExercises
          .map((exercise) => DropdownMenuItem(
        value: exercise.name,
        child: Text(exercise.name),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedExercise = value;
        });
      },
      //validator: (value) => value == null ? 'Selecione um exercício' : null,
    );
  }

  Widget _buildSelectedExercisesList() {
    return Expanded(
      child: _selectedExercises.isEmpty
          ? const Center(
        child: Text(
          'Nenhum exercício adicionado',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        itemCount: _selectedExercises.length,
        itemBuilder: (context, index) {
          final exercise = _selectedExercises[index];
          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(
                exercise.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                exercise.muscleGroup,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _selectedExercises.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${exercise.name} removido'),
                      action: SnackBarAction(
                        label: 'Desfazer',
                        onPressed: () {
                          setState(() {
                            _selectedExercises.insert(index, exercise);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutModel = Provider.of<WorkoutModel>(context);
    final filteredExercises = _getFilteredExercises(workoutModel);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutToEdit == null
            ? 'Criar Nova Ficha'
            : 'Editar Ficha'),
        actions: [
          if (_selectedExercises.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Salvar ficha',
              onPressed: () => _saveWorkout(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTitleField(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildMuscleGroupDropdown(workoutModel)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildExerciseDropdown(filteredExercises)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Adicionar exercício',
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      final exercise = filteredExercises
                          .firstWhere((e) => e.name == _selectedExercise);
                      if (!_selectedExercises.any((e) => e.name == exercise.name)) {
                        setState(() {
                          _selectedExercises.add(exercise);
                          _selectedExercise = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSelectedExercisesList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}