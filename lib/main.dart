import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'services/storage/storage_service.dart';
import 'services/feedback/feedback_service.dart';
import 'services/analytics/analytics_service.dart';
import 'services/ai_coach/gemini_coach_service.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final localStorage = await LocalStorageService.init();
  await StorageService().init();

  final analyticsService = AnalyticsService(localStorage);
  await analyticsService.syncCollectionEnabled();

  runApp(MyApp(localStorage: localStorage, analyticsService: analyticsService));
}

class MyApp extends StatelessWidget {
  final LocalStorageService localStorage;
  final AnalyticsService analyticsService;

  const MyApp({
    super.key,
    required this.localStorage,
    required this.analyticsService,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService(firestoreService);
    final matchmakingService = MatchmakingService();
    final realtimeService = RealtimeService();
    final partyService = PartyService();
    final notificationService = NotificationService();
    final feedbackService = FeedbackService(localStorage);
    final geminiCoachService = GeminiCoachService(analyticsService);

    return MultiProvider(
      providers: [
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<AuthService>.value(value: authService),
        Provider<FeedbackService>.value(value: feedbackService),
        Provider<AnalyticsService>.value(value: analyticsService),
        Provider<GeminiCoachService>.value(value: geminiCoachService),

        ChangeNotifierProvider(
          create: (_) => SettingsProvider(localStorage, analyticsService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, analyticsService),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider(firestoreService)),
        ChangeNotifierProvider(
          create: (_) => GameProvider(
            localStorage,
            firestoreService,
            feedbackService,
            analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MultiplayerProvider(
            matchmakingService,
            realtimeService,
            analyticsService,
            firestoreService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PartyProvider(
            partyService,
            firestoreService,
            analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ShopProvider(firestoreService, analyticsService),
        ),
        ChangeNotifierProvider(
          create: (_) => LeaderboardProvider(firestoreService, analyticsService),
        ),
        ChangeNotifierProvider(
          create: (_) => FriendsProvider(firestoreService, analyticsService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService, matchmakingService),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
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
          final analytics = context.read<AnalyticsService>();
          analytics.setUserId(snapshot.data!.uid);

          return Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              if (profileProvider.isLoading) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (profileProvider.userProfile == null && !profileProvider.isNewUser) {
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<ProfileProvider>().clearProfile();
          context.read<NotificationProvider>().stopListening();
        });

        return const LoginScreen();
      },
    );
  }
}
