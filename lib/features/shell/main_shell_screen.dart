import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home/presentation/mode_selection_screen.dart';
import '../history/presentation/game_history_screen.dart';
import '../profile/presentation/screens/profile_screen.dart';
import '../../services/firebase/firestore_service.dart';

/// Root navigation after sign-in: home, Firestore run history, profile.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncProfile());
  }

  Future<void> _syncProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirestoreService().syncUserProfile(user);
    } catch (e) {
      debugPrint('FirestoreService.syncUserProfile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          ModeSelectionScreen(),
          GameHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
