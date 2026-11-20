import 'package:flutter/widgets.dart';
import 'wave_controller.dart';

class WaveScope extends InheritedNotifier<WaveController> {
  const WaveScope({
    super.key,
    required WaveController controller,
    required super.child,
  }) : super(notifier: controller);

  static WaveController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WaveScope>();
    assert(scope != null, 'Missing WaveScope ancestor');
    return scope!.notifier!;
  }
}
