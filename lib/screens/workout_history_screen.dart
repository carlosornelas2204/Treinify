import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_model.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  List<Workout> _filteredWorkouts = [];
  late WorkoutModel _workoutModel;

  @override
  void initState() {
    super.initState();
    _workoutModel = Provider.of<WorkoutModel>(context, listen: false);
    _searchController.addListener(_filterWorkouts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filteredWorkouts = _workoutModel.workouts
          .where((w) => w.completedAt != null)
          .toList();
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filterWorkouts(); // Atualiza quando as dependências mudam
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterWorkouts() {
    // 1. Garanta que está acessando os dados corretamente
    final allCompletedWorkouts = _workoutModel.workoutHistory
        .map((history) => history.workout)
        .toList();

    // 2. Aplique os filtros corretamente
    setState(() {
      _filteredWorkouts = allCompletedWorkouts.where((workout) {
        // Verifica se o workout foi completado (só por segurança)
        if (workout.completedAt == null) return false;

        // Filtro de texto
        final matchesSearch = _searchController.text.isEmpty ||
            workout.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        // Filtro de data
        final matchesDate = _selectedDate == null ||
            (workout.completedAt!.year == _selectedDate!.year &&
                workout.completedAt!.month == _selectedDate!.month &&
                workout.completedAt!.day == _selectedDate!.day);

        return matchesSearch && matchesDate;
      }).toList()
      // 3. Ordena do mais recente para o mais antigo
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterWorkouts(); // Chamada ESSENCIAL para aplicar o filtro
      });
    }
  }

  Widget _buildDateFilterChip() {
    if (_selectedDate == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Chip(
        label: Text(
          '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () {
          setState(() {
            _selectedDate = null;
            _filterWorkouts();
          });
        },
        backgroundColor: Colors.grey[800],
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Pesquisar fichas',
          labelStyle: const TextStyle(color: Colors.white),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectDate(context),
            tooltip: 'Filtrar por data',
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    if (_filteredWorkouts.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum treino encontrado',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _filteredWorkouts[index];
        return _buildWorkoutCard(workout);
      },
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      child: InkWell(
        onTap: () => _showWorkoutDetails(workout),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${workout.duration?.inMinutes ?? 0} min',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${workout.exercises.length} exercícios',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDetailedDate(workout.completedAt!),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDetailedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showWorkoutDetails(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => WorkoutDetailsDialog(workout: workout),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Treinos'),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildDateFilterChip(),
          const SizedBox(height: 8),
          Expanded(child: _buildWorkoutList()),
        ],
      ),
    );
  }
}

class WorkoutDetailsDialog extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailsDialog({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workout.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Duração: ${workout.duration?.inMinutes ?? 0} minutos',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Data: ${_formatDate(workout.completedAt!)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Exercícios realizados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: workout.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = workout.exercises[index];
                  return _buildExerciseCard(exercise);
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(exercise.exercise.name),
        subtitle: Text(
          '${exercise.sets.length} ${exercise.sets.length == 1 ? 'série' : 'séries'}',
        ),
        children: exercise.sets.map((set) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                if (set is WorkoutSet) ...[
                  _buildSetRow('Peso', '${set.value} kg'),
                  _buildSetRow('Repetições', '${set.reps} reps'),
                  _buildSetRow('Descanso', '${set.restTime} seg'),
                ] else if (set is CardioSet) ...[
                  _buildSetRow('Distância', '${set.distance} km'),
                  _buildSetRow('Duração', '${set.duration.inMinutes} min'),
                  _buildSetRow('Calorias', '${set.calories} kcal'),
                ],
                const Divider(height: 16),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}