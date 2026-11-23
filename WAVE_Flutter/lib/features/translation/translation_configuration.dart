import 'package:flutter/foundation.dart';
import 'engine/gateway_provider.dart';
import 'engine/translation_provider.dart';

/// OpenAI credentials stay on the Python gateway. A debug session token is NOT
/// a production login/entitlement and must never be a permanent API secret.
abstract final class WaveTranslationConfiguration {
  static const endpoint = String.fromEnvironment('WAVE_AI_GATEWAY_URL');
  static const devToken = String.fromEnvironment('WAVE_AI_DEV_SESSION_TOKEN');
  static const allowPrivateDevWs = bool.fromEnvironment(
    'WAVE_AI_ALLOW_PRIVATE_DEV_WS', defaultValue: false);
  static const provider = String.fromEnvironment(
    'WAVE_AI_PROVIDER', defaultValue: 'gateway');

  static bool get isDevelopmentMock => kDebugMode && provider == 'mock';
  static bool get configured => isDevelopmentMock ||
      (endpoint.isNotEmpty && Uri.tryParse(endpoint)?.hasAuthority == true);

  static TranslationProvider create() {
    if (isDevelopmentMock) return MockTranslationProvider();
    if (provider != 'gateway' || !configured) {
      throw const TranslationProviderFailure(
        'Translation gateway unavailable. Configure WAVE_AI_GATEWAY_URL.');
    }
    return GatewayTranslationProvider(
      endpoint: Uri.parse(endpoint),
      ephemeralSessionToken: kDebugMode ? devToken : '',
      allowInsecureDevLan: kDebugMode && allowPrivateDevWs,
    );
  }
}
