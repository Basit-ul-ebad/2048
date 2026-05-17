import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../analytics/analytics_service.dart';
import 'coach_prompt_builder.dart';

/// Gemini API — used only for post-game review (hints are local & instant).
class GeminiCoachService {
  GeminiCoachService(this._analytics);

  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const List<String> _fallbackModelNames = [
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-1.5-flash-8b',
  ];

  static List<String>? _cachedModelNames;
  static String? _provenModel;
  static final Map<String, GenerativeModel> _modelCache = {};

  final AnalyticsService _analytics;

  bool get isConfigured => apiKey.isNotEmpty;

  Future<void> warmUp() async {
    if (!isConfigured) return;
    await _resolveModelNames();
  }

  Future<String> getPostGameReview({
    required List<int> board,
    required int score,
    required String mode,
    required bool won,
  }) async {
    if (!isConfigured) {
      throw CoachException(
        'Gemini API key missing.\n\n'
        'Add your key to keys/dart_defines.json, then fully restart the app '
        '(stop + flutter run).',
      );
    }

    final analyticsFuture =
        _analytics.logAiCoachRequested(mode: mode, type: 'post_game_review');

    try {
      final text = await _generateText(
        CoachPromptBuilder.postGameReviewPrompt(
          board: board,
          score: score,
          mode: mode,
          won: won,
        ),
      );

      if (text.isEmpty) {
        throw CoachException('Empty review from Gemini.');
      }

      await analyticsFuture;
      await _analytics.logAiCoachSuccess(mode: mode, type: 'post_game_review');
      return text;
    } catch (e, st) {
      await analyticsFuture;
      await _analytics.logAiCoachFailed(
        mode: mode,
        type: 'post_game_review',
        error: e.toString(),
      );
      if (e is! CoachException) {
        await _analytics.logNonFatalError(e, st, reason: 'ai_coach_review');
      }
      if (e is CoachException) rethrow;
      throw CoachException(_friendlyMessage(e));
    }
  }

  Future<String> _generateText(String prompt) async {
    if (_provenModel != null) {
      final fast = await _tryModel(_provenModel!, prompt);
      if (fast != null) return fast;
      _provenModel = null;
    }

    final models = await _resolveModelNames();
    Object? lastError;

    for (final modelName in models) {
      try {
        final text = await _tryModel(modelName, prompt);
        if (text != null) {
          _provenModel = modelName;
          return text;
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('No Gemini model responded.');
  }

  Future<String?> _tryModel(String modelName, String prompt) async {
    final model = _modelFor(modelName);
    final response = await model
        .generateContent([Content.text(prompt)])
        .timeout(const Duration(seconds: 20));
    final text = response.text?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  GenerativeModel _modelFor(String name) {
    return _modelCache.putIfAbsent(
      name,
      () => GenerativeModel(
        model: name,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 120,
          temperature: 0.3,
        ),
      ),
    );
  }

  Future<List<String>> _resolveModelNames() async {
    if (_cachedModelNames != null && _cachedModelNames!.isNotEmpty) {
      return _cachedModelNames!;
    }

    final fromApi = await _fetchModelsFromGoogle();
    if (fromApi.isNotEmpty) {
      _cachedModelNames = fromApi;
      return fromApi;
    }

    return _fallbackModelNames;
  }

  Future<List<String>> _fetchModelsFromGoogle() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final models = decoded['models'] as List<dynamic>? ?? [];
      final names = <String>[];

      for (final entry in models) {
        final map = entry as Map<String, dynamic>;
        final methods =
            (map['supportedGenerationMethods'] as List<dynamic>?)?.cast<String>() ?? [];
        if (!methods.contains('generateContent')) continue;

        final fullName = map['name'] as String? ?? '';
        final shortName = fullName.replaceFirst('models/', '');
        if (!shortName.startsWith('gemini')) continue;
        if (shortName.contains('embedding') || shortName.contains('aqa')) continue;

        names.add(shortName);
      }

      names.sort(_modelPriority);
      return names;
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }

  static int _modelPriority(String a, String b) {
    int score(String name) {
      var s = 10;
      if (name.contains('flash-lite')) s -= 5;
      if (name.contains('8b')) s -= 2;
      if (name.contains('preview')) s += 3;
      return s;
    }

    return score(a).compareTo(score(b));
  }

  String _friendlyMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('api_key_invalid') || msg.contains('api key not valid')) {
      return 'Invalid API key — update keys/dart_defines.json';
    }
    if (msg.contains('quota') || msg.contains('resource_exhausted')) {
      return 'Gemini quota used up. Try again later.';
    }
    return 'Review error: $error';
  }
}

class CoachException implements Exception {
  final String message;
  CoachException(this.message);

  @override
  String toString() => message;
}
