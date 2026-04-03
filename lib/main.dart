import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/constants/colors.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/mode_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the snapshot has user data, then they're already signed in.
          if (snapshot.hasData) {
            return const ModeSelectionScreen();
          }
          // Otherwise, they're not signed in.
          return const LoginScreen();
        },
      ),
    );
  }
}
