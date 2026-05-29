import 'dart:async';

enum AppDataRefreshScope {
  all,
  dashboard,
  portfolio,
  catalog,
  balcao,
  perfilWallet,
}

class AppDataRefreshEvent {
  AppDataRefreshEvent({required this.scopes, this.reason, DateTime? emittedAt})
    : emittedAt = emittedAt ?? DateTime.now();

  final Set<AppDataRefreshScope> scopes;
  final String? reason;
  final DateTime emittedAt;

  bool affects(AppDataRefreshScope scope) {
    return scopes.contains(AppDataRefreshScope.all) || scopes.contains(scope);
  }
}

class AppDataRefreshBus {
  AppDataRefreshBus._();

  static final AppDataRefreshBus instance = AppDataRefreshBus._();

  final StreamController<AppDataRefreshEvent> _controller =
      StreamController<AppDataRefreshEvent>.broadcast();

  Stream<AppDataRefreshEvent> get stream => _controller.stream;

  void refresh({
    Set<AppDataRefreshScope> scopes = const {AppDataRefreshScope.all},
    String? reason,
  }) {
    if (_controller.isClosed) return;

    _controller.add(
      AppDataRefreshEvent(
        scopes: scopes.isEmpty ? const {AppDataRefreshScope.all} : scopes,
        reason: reason,
      ),
    );
  }
}
