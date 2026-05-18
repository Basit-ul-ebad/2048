import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../services/firebase/firestore_service.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/analytics/analytics_constants.dart';
import '../../profile/providers/profile_provider.dart';

class SetNicknameScreen extends StatefulWidget {
  const SetNicknameScreen({super.key});

  @override
  State<SetNicknameScreen> createState() => _SetNicknameScreenState();
}

class _SetNicknameScreenState extends State<SetNicknameScreen> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _error = 'Please enter a nickname');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final firestoreService = context.read<FirestoreService>();
      
      // Check nickname availability
      final isAvailable = await firestoreService.isNicknameAvailable(nickname);
      if (!isAvailable) {
        throw Exception('Nickname is already taken. Try adding numbers.');
      }

      // Create Profile
      await firestoreService.createUserProfile(
        uid: user.uid,
        email: user.email ?? 'unknown@email.com',
        nickname: nickname,
      );

      final analytics = context.read<AnalyticsService>();
      final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
      await analytics.logSignupSuccess(
        loginMethod: isGoogle ? AnalyticsLoginMethods.google : AnalyticsLoginMethods.email,
      );

      // Re-fetch profile to update state and trigger navigation to ModeSelection
      if (mounted) {
        await context.read<ProfileProvider>().fetchProfile(user.uid);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.account_circle, size: 100, color: AppColors.textDark),
                const SizedBox(height: 24),
                const Text(
                  'Set Your Nickname',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You need a nickname before you can join multiplayer matches or appear on the leaderboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: 'Enter Nickname',
                    filled: true,
                    fillColor: AppColors.getTileColor(2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getTileColor(2048),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
