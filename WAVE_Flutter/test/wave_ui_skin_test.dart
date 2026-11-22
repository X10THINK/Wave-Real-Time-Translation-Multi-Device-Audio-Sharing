import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave_flutter/core/theme/wave_theme.dart';
import 'package:wave_flutter/core/ui/wave_widgets.dart';

void main() {
  testWidgets('Approved pill CTA retains original callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: waveTheme(),
      home: Scaffold(body: Center(child: WavePrimaryButton(
        title: 'Start Audio Share', icon: Icons.headphones,
        onPressed: () => taps++,
      ))),
    ));
    await tester.tap(find.text('Start Audio Share'));
    expect(taps, 1);
  });

  testWidgets('Disabled CTA cannot trigger a callback', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: waveTheme(),
      home: const Scaffold(body: WavePrimaryButton(
        title: 'Not Ready', onPressed: null,
      )),
    ));

    final button = find.byType(WavePrimaryButton);

    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: button,
        matching: find.byType(InkWell),
      ),
    );

    expect(find.text('Not Ready'), findsOneWidget);
    expect(inkWell.onTap, isNull);

    final semantics = tester.widget<Semantics>(
      find.descendant(
        of: button,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics &&
              widget.properties.button == true,
        ),
      ),
    );

    expect(semantics.properties.enabled, isFalse);

    await tester.tap(find.text('Not Ready'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Floating capsule option keeps selection and tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: waveTheme(),
      home: Scaffold(body: Center(child: WaveOptionTile(
        title: 'Wi-Fi', subtitle: 'Local network',
        icon: Icons.wifi, selected: true, onTap: () => taps++,
      ))),
    ));
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.tap(find.text('Wi-Fi'));
    expect(taps, 1);
  });

  testWidgets('Original bottom navigation stays original', (tester) async {
    var selected = -1;
    await tester.pumpWidget(MaterialApp(
      theme: waveTheme(),
      home: Scaffold(bottomNavigationBar: WaveGlassBottomNav(
        selectedIndex: 1, onSelected: (i) => selected = i,
      )),
    ));
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Sessions'));
    expect(selected, 2);
  });
}
