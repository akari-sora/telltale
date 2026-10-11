import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/obd_session.dart';
import 'generated/car_projection_session.g.dart';

final class CarProjectionLeaseOrder {
  int _releasedGeneration = -1;
  int _highestGeneration = -1;

  bool admit(CarProjectionLeaseMessage lease) {
    if (lease.generation < _highestGeneration) return false;
    if (lease.generation > _highestGeneration) {
      _highestGeneration = lease.generation;
    }
    if (!lease.active) {
      if (lease.generation > _releasedGeneration) {
        _releasedGeneration = lease.generation;
      }
      return true;
    }
    return lease.generation > _releasedGeneration;
  }
}

final carProjectionSessionRuntimeProvider =
    Provider<CarProjectionSessionRuntime?>((ref) {
      final runtime = CarProjectionSessionRuntime(ref);
      ref.onDispose(runtime.dispose);
      return runtime;
    });

/// Joins the native projected-session lease to the exact Dart OBD generation.
final class CarProjectionSessionRuntime extends CarProjectionSessionFlutterApi {
  CarProjectionSessionRuntime(this.ref) {
    CarProjectionSessionFlutterApi.setUp(this);
    ref.listen(obdSessionProvider, (_, _) => _scheduleReconcile());
    _foregroundSubscription = ref
        .read(obdSessionProvider.notifier)
        .foregroundChanges
        .listen((_) => _scheduleReconcile());
    unawaited(_initialize());
  }

  final Ref ref;
  final CarProjectionSessionHostApi _host = CarProjectionSessionHostApi();
  CarProjectionLeaseMessage? _lease;
  bool _disposed = false;
  bool _arming = false;
  int _leaseRevision = 0;
  final CarProjectionLeaseOrder _leaseOrder = CarProjectionLeaseOrder();
  Future<void> _reducer = Future<void>.value();
  late final StreamSubscription<bool> _foregroundSubscription;

  Future<void> _initialize() async {
    try {
      _enqueue(await _host.currentLease());
    } on Object {
      // Native absence is an inert non-car host, never background authority.
    }
  }

  @override
  void onLeaseChanged(CarProjectionLeaseMessage lease) {
    _enqueue(lease);
  }

  void _enqueue(CarProjectionLeaseMessage lease) {
    if (!_leaseOrder.admit(lease)) return;
    final revision = ++_leaseRevision;
    _append(() => _accept(lease, revision));
  }

  void _scheduleReconcile() {
    _append(_reconcile);
  }

  void _append(Future<void> Function() action) {
    _reducer = _reducer.then((_) async {
      try {
        await action();
      } on Object {
        await _failClosed();
      }
    });
  }

  Future<void> _failClosed() async {
    final lease = _lease;
    if (lease == null) return;
    final session = ref.read(obdSessionProvider.notifier);
    try {
      await session.retireProjectionContinuity(lease.generation);
    } on Object {
      // The reducer must recover even when local teardown also fails.
    }
    final connectionGeneration = lease.connectionGeneration;
    if (lease.armed && connectionGeneration != null) {
      try {
        await _host.retireContinuity(lease.generation, connectionGeneration);
        await _host.acknowledgeRelease(lease.generation);
      } on Object {
        // Native owns a bounded exact-generation watchdog for this path.
      }
    }
  }

  Future<void> _accept(CarProjectionLeaseMessage lease, int revision) async {
    if (_disposed) return;
    final previous = _lease;
    _lease = lease;
    final session = ref.read(obdSessionProvider.notifier);
    if (!lease.active) {
      if (previous?.generation == lease.generation ||
          session.hasArmedProjectionContinuity) {
        await session.retireProjectionContinuity(lease.generation);
      }
      if (!_disposed) await _host.acknowledgeRelease(lease.generation);
      return;
    }
    if (!lease.armed) {
      if (previous?.armed == true || session.hasArmedProjectionContinuity) {
        await session.retireProjectionContinuity(
          previous?.generation ?? lease.generation,
        );
      }
      await _host.acknowledgeRelease(lease.generation);
      if (!_disposed && revision == _leaseRevision) await _tryArm();
      return;
    }
    if (lease.armed) {
      await _confirmAndAcceptArmed(lease, revision);
      return;
    }
  }

  Future<void> _confirmAndAcceptArmed(
    CarProjectionLeaseMessage lease,
    int revision,
  ) async {
    final session = ref.read(obdSessionProvider.notifier);
    final confirmed = await _host.currentLease();
    if (_disposed || revision != _leaseRevision) return;
    if (!confirmed.active ||
        !confirmed.armed ||
        confirmed.generation != lease.generation ||
        confirmed.connectionGeneration != lease.connectionGeneration) {
      _enqueue(confirmed);
      return;
    }
    final connectionGeneration = confirmed.connectionGeneration;
    final accepted =
        connectionGeneration != null &&
        await session.acceptProjectionContinuity(
          projectionGeneration: confirmed.generation,
          connectionGeneration: connectionGeneration,
        );
    if (!accepted && !_disposed && connectionGeneration != null) {
      await _host.retireContinuity(confirmed.generation, connectionGeneration);
      await _host.acknowledgeRelease(confirmed.generation);
    }
  }

  Future<void> _tryArm() async {
    if (_disposed || _arming) return;
    final lease = _lease;
    if (lease == null || !lease.active || lease.armed) return;
    final state = ref.read(obdSessionProvider);
    final session = ref.read(obdSessionProvider.notifier);
    if (!state.isConnected || !session.isForeground) return;
    _arming = true;
    try {
      final revision = _leaseRevision;
      final response = await _host.armContinuity(
        lease.generation,
        session.connectionGeneration,
      );
      if (revision == _leaseRevision && response.armed) _enqueue(response);
    } on Object {
      // Fail closed. A later state or native lease edge retries while visible.
    } finally {
      _arming = false;
    }
  }

  Future<void> _reconcile() async {
    if (_disposed) return;
    final lease = _lease;
    if (lease?.armed == true) {
      final state = ref.read(obdSessionProvider);
      final session = ref.read(obdSessionProvider.notifier);
      final connectionGeneration = lease!.connectionGeneration;
      if (!state.isConnected ||
          connectionGeneration == null ||
          connectionGeneration != session.connectionGeneration) {
        await session.retireProjectionContinuity(lease.generation);
        if (connectionGeneration != null) {
          await _host.retireContinuity(lease.generation, connectionGeneration);
          await _host.acknowledgeRelease(lease.generation);
        }
        return;
      }
      if (!session.hasArmedProjectionContinuity) {
        await _confirmAndAcceptArmed(lease, _leaseRevision);
      }
      return;
    }
    await _tryArm();
  }

  void dispose() {
    _disposed = true;
    unawaited(_foregroundSubscription.cancel());
    CarProjectionSessionFlutterApi.setUp(null);
  }
}
