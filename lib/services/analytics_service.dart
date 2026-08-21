import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  bool get isReady => _analytics != null;

  Future<void> start() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
    } catch (error) {
      debugPrint('Analytics unavailable: $error');
    }
  }

  FirebaseAnalyticsObserver? get observer {
    final analytics = _analytics;
    return analytics == null ? null : FirebaseAnalyticsObserver(analytics: analytics);
  }

  Future<void> screen(String name) async {
    await _analytics?.logScreenView(screenName: name);
  }

  Future<void> documentAdded(String source, int pages) async {
    await _log('document_added', {'source': source, 'pages': pages});
  }

  Future<void> toolUsed(String tool) async {
    await _log('tool_used', {'tool': tool});
  }

  Future<void> exported(String format) async {
    await _log('document_exported', {'format': format});
  }

  Future<void> onboardingFinished(int page) async {
    await _log('onboarding_finished', {'last_page': page});
  }

  Future<void> permissionAnswered(String kind, bool granted) async {
    await _log('permission_answered', {'kind': kind, 'granted': granted});
  }

  Future<void> _log(String name, Map<String, Object> params) async {
    await _analytics?.logEvent(name: name, parameters: params);
  }
}
