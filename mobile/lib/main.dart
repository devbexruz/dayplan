import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/home/presentation/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: DayPlanApp()));
}

class DayPlanApp extends StatelessWidget {
  const DayPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DayPlan',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
