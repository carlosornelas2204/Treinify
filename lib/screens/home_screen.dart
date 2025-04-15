import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_model.dart';
import 'workout_creation_screen.dart';
import 'workout_progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alturaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _idadeController = TextEditingController();
  String _sexo = 'Masculino';
  int _diasSemana = 3;
  String _objetivo = 'Ganho de massa';

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

  Widget _buildAIForm(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(12),
      child: ExpansionTile(
        title: const Text('Gerar ficha com IA'),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _alturaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Altura (cm)'),
                  validator: (value) => value == null || value.isEmpty ? 'Informe sua altura' : null,
                ),
                TextFormField(
                  controller: _pesoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  validator: (value) => value == null || value.isEmpty ? 'Informe seu peso' : null,
                ),
                TextFormField(
                  controller: _idadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Idade'),
                  validator: (value) => value == null || value.isEmpty ? 'Informe sua idade' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _sexo,
                  items: ['Masculino', 'Feminino'].map((sexo) {
                    return DropdownMenuItem(value: sexo, child: Text(sexo));
                  }).toList(),
                  onChanged: (value) => setState(() => _sexo = value!),
                  decoration: const InputDecoration(labelText: 'Sexo'),
                ),
                DropdownButtonFormField<int>(
                  value: _diasSemana,
                  items: List.generate(7, (index) => index + 1).map((dias) {
                    return DropdownMenuItem(value: dias, child: Text('$dias dias/semana'));
                  }).toList(),
                  onChanged: (value) => setState(() => _diasSemana = value!),
                  decoration: const InputDecoration(labelText: 'Dias disponíveis por semana'),
                ),
                DropdownButtonFormField<String>(
                  value: _objetivo,
                  items: ['Ganho de massa', 'Emagrecimento', 'Condicionamento'].map((obj) {
                    return DropdownMenuItem(value: obj, child: Text(obj));
                  }).toList(),
                  onChanged: (value) => setState(() => _objetivo = value!),
                  decoration: const InputDecoration(labelText: 'Objetivo'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Gerar Ficha com IA'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Aqui vai a chamada para a IA
                      print('Altura: ${_alturaController.text}');
                      print('Peso: ${_pesoController.text}');
                      print('Idade: ${_idadeController.text}');
                      print('Sexo: $_sexo');
                      print('Dias: $_diasSemana');
                      print('Objetivo: $_objetivo');
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
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

  Widget _buildWorkoutList(BuildContext context, List<Workout> workouts) {
    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        return _buildWorkoutCard(context, workouts[index]);
      },
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
      body: Column(
        children: [
          _buildAIForm(context),
          const SizedBox(height: 10),
          Expanded(
            child: workouts.isEmpty
                ? _buildEmptyState(context)
                : _buildWorkoutList(context, workouts),
          ),
        ],
      ),
    );
  }
}
