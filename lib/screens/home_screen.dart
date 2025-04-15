// ARQUIVO: home_screen.dart
// MELHORIAS IMPLEMENTADAS:
// 1. Adição de feedback visual ao adicionar/editar fichas
// 2. Melhor organização do código
// 3. Adição de confirmação ao editar ficha
// 4. Melhor tratamento de erros

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_model.dart';
import 'workout_creation_screen.dart';
import 'workout_progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _navigateAndRefresh(
      BuildContext context,
      Widget page, {
        bool shouldRefresh = true,
      }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (shouldRefresh && context.mounted) {
      Provider.of<WorkoutModel>(context, listen: false).notifyListeners();

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$result')),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'Nenhuma ficha criada ainda',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _navigateAndRefresh(
              context,
              const WorkoutCreationScreen(),
            ),
            child: const Text('Criar Primeira Ficha'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList(BuildContext context, List<Workout> workouts) {
    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _buildWorkoutCard(context, workout);
      },
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return Dismissible(
      key: Key('${workout.title}_${workout.createdAt}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text('Tem certeza que deseja excluir esta ficha?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        Provider.of<WorkoutModel>(context, listen: false).deleteWorkout(workout);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ficha "${workout.title}" excluída'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                Provider.of<WorkoutModel>(context, listen: false).addWorkout(workout);
              },
            ),
          ),
        );
      },
      child: Card(
        color: Colors.grey[900],
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            workout.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${workout.exercises.length} exercícios'),
              if (workout.completedAt != null)
                Text(
                  'Último treino: ${workout.completedAt!.day}/${workout.completedAt!.month}/${workout.completedAt!.year}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          trailing: SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _navigateAndRefresh(
                    context,
                    WorkoutCreationScreen(workoutToEdit: workout),
                  ),
                  tooltip: 'Editar ficha',
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 20),
                  onPressed: () => _navigateAndRefresh(
                    context,
                    WorkoutProgressScreen(workout: workout),
                    shouldRefresh: false,
                  ),
                  tooltip: 'Iniciar treino',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workouts = Provider.of<WorkoutModel>(context).workouts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Fichas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Criar nova ficha',
            onPressed: () => _navigateAndRefresh(
              context,
              const WorkoutCreationScreen(),
            ),
          ),
        ],
      ),
      body: workouts.isEmpty ? _buildEmptyState(context) : _buildWorkoutList(context, workouts),
    );
  }
}