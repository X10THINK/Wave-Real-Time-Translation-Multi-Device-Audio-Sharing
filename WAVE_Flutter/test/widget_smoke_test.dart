import 'package:flutter/services.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave_flutter/core/navigation/main_shell.dart';
import 'package:wave_flutter/core/theme/wave_theme.dart';
import 'package:wave_flutter/core/ui/wave_widgets.dart';
import 'package:wave_flutter/data/repositories/in_memory_session_repository.dart';
import 'package:wave_flutter/state/wave_controller.dart';
import 'package:wave_flutter/state/wave_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('wave.native/commands'),
          (call) async =>
              call.method == 'permissions'
                  ? true
                  : <String, dynamic>{'running': false, 'connected': 0},
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('wave.native/events'),
          (call) async => null,
        );
  });
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('Home displays only two core features with three glass tabs', (
    tester,
  ) async {
    final controller = WaveController(InMemorySessionRepository());
    await tester.pumpWidget(
      WaveScope(
        controller: controller,
        child: MaterialApp(theme: waveTheme(), home: const WaveMainShell()),
      ),
    );
    expect(find.text('Live Translate'), findsWidgets);
    expect(find.byType(WaveGlassBottomNav), findsOneWidget);
    await tester.tap(find.byIcon(Icons.headphones_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('No Active Audio Session'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('new audio session requests method before role', (tester) async {
    final controller = WaveController(InMemorySessionRepository());
    await tester.pumpWidget(
      WaveScope(
        controller: controller,
        child: MaterialApp(theme: waveTheme(), home: const WaveMainShell()),
      ),
    );
    await tester.tap(find.byIcon(Icons.headphones_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Audio Share'));
    await tester.pumpAndSettle();
    expect(find.text('Transfer Method'), findsOneWidget);
    expect(find.text('Select Your Role'), findsNothing);
    await tester.tap(find.text('Wi-Fi'));
    await tester.pumpAndSettle();
    expect(find.text('Select Your Role'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
