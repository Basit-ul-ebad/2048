import 'package:flutter/material.dart';
import 'core/constants/colors.dart';
import 'features/auth/presentation/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048 Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', // Try to use a clean modern font if available
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.getTileColor(2048)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
