import 'package:flutter/widgets.dart';
import 'package:tuna/services/app_controller.dart';

class TunaScope extends InheritedNotifier<AppController> {
  const TunaScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TunaScope>();
    assert(scope != null, 'TunaScope is missing above this widget');
    return scope!.notifier!;
  }
}
