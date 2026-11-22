import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:wave_flutter/features/intro/presentation/intro_screens.dart';
import 'package:wave_flutter/features/home/presentation/home_screen.dart';
import 'package:wave_flutter/core/theme/wave_theme.dart';
import 'package:wave_flutter/state/wave_scope.dart';
import 'package:wave_flutter/state/wave_controller.dart';
import 'package:wave_flutter/data/repositories/in_memory_session_repository.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(800, 360)]) {
    testWidgets('onboarding fits ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: waveTheme(),
          home: WaveOnboardingScreen(onContinue: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('home fits 320px width at default text size', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final controller = WaveController(InMemorySessionRepository());
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      WaveScope(
        controller: controller,
        child: MaterialApp(
          theme: waveTheme(),
          home: Scaffold(
            body: WaveHomeScreen(
              onAudio: () {},
              onTranslate: () {},
              onMusic: () {},
              onSessions: () {},
              onCreate: () {},
              onProfile: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
