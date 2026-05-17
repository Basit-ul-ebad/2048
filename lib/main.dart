import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

// Services
import 'services/firebase/firestore_service.dart';
import 'services/firebase/auth_service.dart';
import 'services/firebase/matchmaking_service.dart';
import 'services/firebase/realtime_service.dart';
import 'services/firebase/party_service.dart';
import 'services/firebase/notification_service.dart';
import 'services/storage/local_storage_service.dart';

// Providers
import 'features/settings/providers/settings_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/game/providers/game_provider.dart';
import 'features/multiplayer/providers/multiplayer_provider.dart';
import 'features/multiplayer/providers/party_provider.dart';
import 'features/shop/providers/shop_provider.dart';
import 'features/leaderboard/providers/leaderboard_provider.dart';
import 'features/friends/providers/friends_provider.dart';
import 'features/notifications/providers/notification_provider.dart';

// Core
import 'core/theme/app_theme.dart';

// Screens
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/set_nickname_screen.dart';
import 'features/home/presentation/mode_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Local Storage synchronously before app start
  final localStorage = await LocalStorageService.init();

  runApp(MyApp(localStorage: localStorage));
}

class MyApp extends StatelessWidget {
  final LocalStorageService localStorage;

  const MyApp({super.key, required this.localStorage});

  @override
  Widget build(BuildContext context) {
    // 1. Initialize Services
    final firestoreService = FirestoreService();
    final authService = AuthService(firestoreService);
    final matchmakingService = MatchmakingService();
    final realtimeService = RealtimeService();
    final partyService = PartyService();
    final notificationService = NotificationService();

    return MultiProvider(
      providers: [
        // Services via Provider (optional, but good for dependency injection)
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<AuthService>.value(value: authService),

        // State Providers
        ChangeNotifierProvider(create: (_) => SettingsProvider(localStorage)),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ProfileProvider(firestoreService)),
        ChangeNotifierProvider(create: (_) => GameProvider(localStorage, firestoreService)),
        ChangeNotifierProvider(create: (_) => MultiplayerProvider(matchmakingService, realtimeService)),
        ChangeNotifierProvider(create: (_) => PartyProvider(partyService, firestoreService)),
        ChangeNotifierProvider(create: (_) => ShopProvider(firestoreService)),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider(firestoreService)),
        ChangeNotifierProvider(create: (_) => FriendsProvider(firestoreService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notificationService)),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          // Dynamic theme could be tied to settings here later
          return MaterialApp(
            title: '2048 Multiplayer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          return Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              if (profileProvider.isLoading) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (profileProvider.userProfile == null && !profileProvider.isNewUser) {
                // Initial fetch trigger
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  profileProvider.fetchProfile(snapshot.data!.uid);
                });
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (profileProvider.isNewUser) {
                return const SetNicknameScreen();
              }

              return const ModeSelectionScreen();
            },
          );
        }
        
        // Clean up when logged out
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<ProfileProvider>().clearProfile();
          context.read<NotificationProvider>().stopListening();
        });
        
        return const LoginScreen(); // We will need to update this to match new UI
      },
    );
  }
}
