// ARQUIVO: main.dart
// MELHORIAS SUGERIDAS:
// 1. Organização mais clara dos temas
// 2. Adição de constantes para cores reutilizáveis
// 3. Melhor documentação do código

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/workout_model.dart';
import 'screens/home_screen.dart';
import 'screens/workout_history_screen.dart';

// Cores customizadas para fácil manutenção
class AppColors {
  static const Color primary = Colors.white;
  static const Color secondary = Colors.grey;
  static const Color background = Colors.black;
  static const Color accent = Colors.grey;
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => WorkoutModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Progressão de Carga',
      theme: _buildAppTheme(),
      home: const MainScreen(),
    );
  }

  // Método separado para organização do tema
  ThemeData _buildAppTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.primary),
        displayMedium: TextStyle(color: AppColors.primary),
        displaySmall: TextStyle(color: AppColors.primary),
        bodyLarge: TextStyle(color: AppColors.primary),
        bodyMedium: TextStyle(color: AppColors.primary),
        titleMedium: TextStyle(color: AppColors.primary),
        titleSmall: TextStyle(color: AppColors.primary),
        labelLarge: TextStyle(color: AppColors.primary),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: AppColors.primary),
        hintStyle: TextStyle(color: AppColors.secondary),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.black87,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: AppColors.primary),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: AppColors.primary),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.secondary,
        selectionHandleColor: AppColors.primary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.background,
        onSurface: AppColors.primary,
        background: AppColors.background,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondary,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    WorkoutHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.secondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Histórico',
        ),
      ],
    );
  }
}