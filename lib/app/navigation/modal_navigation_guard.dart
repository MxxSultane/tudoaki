import 'package:flutter/material.dart';

/// Branch-local popup routes must also block the shell's outer navigation.
class ModalNavigationGuard {
  final active = ValueNotifier(false);
  final _routes = <Route<dynamic>>{};
  bool _disposed = false;
  void update(Route<dynamic>? route, bool add) {
    if (_disposed || route is! PopupRoute) return;
    if (add) {
      _routes.add(route);
    } else {
      _routes.remove(route);
    }
    active.value = _routes.isNotEmpty;
  }

  void dispose() {
    _disposed = true;
    active.dispose();
  }
}

class ShellPopupObserver extends NavigatorObserver {
  ShellPopupObserver(this.guard);
  final ModalNavigationGuard guard;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      guard.update(route, true);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      guard.update(route, false);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      guard.update(route, false);
}
